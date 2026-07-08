-- ServerScriptService/GameServer/Services/DialogueService.lua
-- Branching NPC dialogue driven by DialogueData.lua. `Start` is called directly by
-- InteractionService when an `npc` ProximityPrompt fires (no remote needed);
-- `Dialogue/Choose` is the one client->server remote, used for follow-up choices once a
-- dialogue box is already open.
--
-- DialogueData schema per node: `line` (text), `requiredTrust` (optional node-level
-- gate -- if unmet, the NPC's `locked` node is shown instead, if one exists), and
-- `choices[]` each with: `text`, `nextNode` (or `close = true` to end), `requiredTrust`,
-- `requiredClue`, `grantClue` (auto-collects a clue via InvestigationData), `trustAction`
-- (a named delta from GameConfig.Trust.Actions), and `objectiveProgress` (a step id/type
-- reported to ObjectiveService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local DialogueData = require(Modules.Data.DialogueData)
local InvestigationData = require(Modules.Data.InvestigationData)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local DialogueService = {}

local currentNodeByPlayer = {} -- [player] = { npcId, nodeId }
local Services

local TRUST_ORDER = { feared = 1, suspicious = 2, neutral = 3, trusted = 4 }

function DialogueService.Init(services)
	Services = services

	RemoteRegistry.Get("Dialogue/Choose").OnServerEvent:Connect(function(player, payload)
		if typeof(payload) ~= "table" then
			return
		end
		DialogueService.Choose(player, payload.nodeId, payload.choiceId)
	end)
end

local function meetsTrust(player, requiredTrust)
	if not requiredTrust then
		return true
	end
	local currentState = Services.TrustService.GetState(player)
	return (TRUST_ORDER[currentState] or 0) >= (TRUST_ORDER[requiredTrust] or 0)
end

local function isChoiceLocked(player, choice)
	if choice.requiredClue and not Services.InvestigationService.HasClue(player, choice.requiredClue) then
		return true, "Kamu belum menemukan petunjuk yang cukup."
	end
	if choice.requiredTrust and not meetsTrust(player, choice.requiredTrust) then
		return true, "Warga belum cukup percaya padamu."
	end
	return false, nil
end

local function sendNode(player, npcId, nodeId)
	local dialogue = DialogueData.GetDialogue(npcId)
	if not dialogue then
		return
	end
	local node = dialogue.nodes[nodeId]
	if not node then
		return
	end

	-- Node-level trust gate: redirect to a "locked" node if this NPC defines one.
	if node.requiredTrust and not meetsTrust(player, node.requiredTrust) and dialogue.nodes.locked and nodeId ~= "locked" then
		sendNode(player, npcId, "locked")
		return
	end

	currentNodeByPlayer[player] = { npcId = npcId, nodeId = nodeId }

	local choicesPayload = {}
	for _, choice in ipairs(node.choices) do
		local locked, reason = isChoiceLocked(player, choice)
		table.insert(choicesPayload, {
			id = choice.id,
			text = choice.text,
			locked = locked,
			lockedReason = reason,
		})
	end

	RemoteRegistry.Get("Dialogue/Node"):FireClient(player, {
		nodeId = nodeId,
		npcName = dialogue.displayName or npcId,
		text = node.line,
		choices = choicesPayload,
	})
end

-- Called by InteractionService when an `npc` ProximityPrompt is triggered.
function DialogueService.Start(player, npcId)
	local dialogue = DialogueData.GetDialogue(npcId)
	if not dialogue then
		warn("[DialogueService] Unknown NPCId:", npcId)
		return
	end
	sendNode(player, npcId, dialogue.start)
end

function DialogueService.Choose(player, nodeId, choiceId)
	local current = currentNodeByPlayer[player]
	if not current or current.nodeId ~= nodeId then
		return -- stale/forged request; ignore
	end
	local dialogue = DialogueData.GetDialogue(current.npcId)
	local node = dialogue and dialogue.nodes[nodeId]
	if not node then
		return
	end

	for _, choice in ipairs(node.choices) do
		if choice.id == choiceId then
			if isChoiceLocked(player, choice) then
				return -- client should already grey this out; server re-validates anyway
			end

			if choice.trustAction then
				local delta = GameConfig.Trust.Actions[choice.trustAction]
				if delta then
					Services.TrustService.Adjust(player, delta, player:GetAttribute("Difficulty"))
				else
					warn("[DialogueService] Unknown trustAction:", choice.trustAction)
				end
			end

			if choice.grantClue then
				local clue = InvestigationData.GetClue(choice.grantClue)
				Services.InvestigationService.CollectClue(
					player,
					choice.grantClue,
					clue and clue.description,
					clue and clue.isFalse == true
				)
			end

			if choice.objectiveProgress then
				Services.ObjectiveService.ReportProgress(player, choice.objectiveProgress, 1)
			end

			if choice.close or not choice.nextNode then
				currentNodeByPlayer[player] = nil
				Services.ObjectiveService.ReportProgress(player, GameConfig.Objectives.Types.TALK_NPC, 1)
			else
				sendNode(player, current.npcId, choice.nextNode)
			end
			return
		end
	end
end

return DialogueService
