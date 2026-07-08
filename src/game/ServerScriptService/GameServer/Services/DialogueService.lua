-- ServerScriptService/GameServer/Services/DialogueService.lua
-- Branching NPC dialogue driven entirely by NarrativeData. `Dialogue/Start` is called
-- directly by InteractionService when an `npc` ProximityPrompt fires (no remote needed);
-- `Dialogue/Choose` is the one client->server remote, used for follow-up choices once a
-- dialogue box is already open. A choice can optionally carry a `TrustDelta` (see
-- NarrativeData) -- game_mechanics.md's Player Actions table explicitly lists Dialogue
-- Choice as affecting trust, so this Service is where that hook lives.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local NarrativeData = require(Modules.NarrativeData)
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

local function isChoiceLocked(player, choice)
	if not choice.Requires then
		return false, nil
	end
	if choice.Requires.ClueId and not Services.InvestigationService.HasClue(player, choice.Requires.ClueId) then
		return true, "Kamu belum menemukan petunjuk yang cukup."
	end
	if choice.Requires.Trust then
		local currentState = Services.TrustService.GetState(player)
		if (TRUST_ORDER[currentState] or 0) < (TRUST_ORDER[choice.Requires.Trust] or 0) then
			return true, "Warga belum cukup percaya padamu."
		end
	end
	return false, nil
end

local function sendNode(player, npcId, nodeId)
	local npc = NarrativeData.NPCs[npcId]
	if not npc then
		return
	end
	local node = npc.Nodes[nodeId]
	if not node then
		return
	end

	currentNodeByPlayer[player] = { npcId = npcId, nodeId = nodeId }

	local choicesPayload = {}
	for _, choice in ipairs(node.Choices) do
		local locked, reason = isChoiceLocked(player, choice)
		table.insert(choicesPayload, {
			id = choice.Id,
			text = choice.Text,
			locked = locked,
			lockedReason = reason,
		})
	end

	RemoteRegistry.Get("Dialogue/Node"):FireClient(player, {
		nodeId = nodeId,
		npcName = npc.DisplayName,
		text = node.Text,
		choices = choicesPayload,
	})
end

function DialogueService.Start(player, npcId)
	local npc = NarrativeData.NPCs[npcId]
	if not npc then
		warn("[DialogueService] Unknown NPCId:", npcId)
		return
	end
	sendNode(player, npcId, npc.StartNode)
end

function DialogueService.Choose(player, nodeId, choiceId)
	local current = currentNodeByPlayer[player]
	if not current or current.nodeId ~= nodeId then
		return -- stale/forged request; ignore
	end
	local npc = NarrativeData.NPCs[current.npcId]
	local node = npc and npc.Nodes[nodeId]
	if not node then
		return
	end

	for _, choice in ipairs(node.Choices) do
		if choice.Id == choiceId then
			if isChoiceLocked(player, choice) then
				return -- client should already grey this out; server re-validates anyway
			end

			if choice.TrustDelta then
				Services.TrustService.Adjust(player, choice.TrustDelta, player:GetAttribute("Difficulty"))
			end

			if choice.Next then
				sendNode(player, current.npcId, choice.Next)
			else
				currentNodeByPlayer[player] = nil
			end
			return
		end
	end
end

return DialogueService
