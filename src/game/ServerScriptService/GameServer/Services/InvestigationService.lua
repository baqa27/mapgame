-- ServerScriptService/GameServer/Services/InvestigationService.lua
-- Owns each player's collected-clue set. `isFalse` is tracked server-side only (used by
-- HorrorService/DialogueService gating later) and is NEVER sent to the client -- the
-- client just sees a clue entry appear in the journal, same as a real one.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local InvestigationService = {}

local cluesByPlayer = {} -- [player] = { [clueId] = { isFalse = bool } }

function InvestigationService.Init(_services) end

function InvestigationService.InitPlayer(player)
	cluesByPlayer[player] = {}
end

function InvestigationService.RemovePlayer(player)
	cluesByPlayer[player] = nil
end

function InvestigationService.CollectClue(player, clueId, clueText, isFalse)
	local clues = cluesByPlayer[player]
	if not clues or not clueId then
		return false
	end
	if clues[clueId] then
		return false -- already collected
	end
	clues[clueId] = { isFalse = isFalse == true }
	RemoteRegistry.Get("Investigation/ClueAdded"):FireClient(player, {
		clueId = clueId,
		text = clueText or "Kamu menemukan sebuah petunjuk.",
	})
	return true
end

function InvestigationService.HasClue(player, clueId)
	local clues = cluesByPlayer[player]
	return clues ~= nil and clues[clueId] ~= nil
end

function InvestigationService.GetClueCount(player)
	local clues = cluesByPlayer[player]
	if not clues then
		return 0
	end
	local count = 0
	for _ in pairs(clues) do
		count = count + 1
	end
	return count
end

return InvestigationService
