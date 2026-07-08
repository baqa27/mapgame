-- ServerScriptService/GameServer/Services/CaseGenerationService.lua
-- Randomly generates each player's "solution" for the night, once per session, so the
-- guilty suspect(s) are NOT hardcoded and differ between playthroughs. Reads eligibility
-- from InvestigationData.Suspects' `isHumanCulprit` / `isPesugihanActor` flags -- a pool,
-- not a fixed answer.
--
-- IMPORTANT CONTENT NOTE: as of this writing, InvestigationData.Suspects only has ONE
-- suspect (pak_joko) flagged eligible for either role -- every other suspect (mas_agus,
-- mbah_darmo, bu_ani) is explicitly written as innocent, with clues/dialogue that only
-- make narrative sense if Pak Joko is guilty (muddy_sandals is literally "di gang rumah
-- Pak Joko", debt_note is "di warung Pak Joko"). So right now this system will always
-- resolve to Pak Joko -- it's a pool of one, not because randomization is broken, but
-- because only one suspect has guilt-supporting content written. To get real
-- session-to-session variety, add 2-3 more suspects to InvestigationData.Suspects with
-- isHumanCulprit/isPesugihanActor = true AND matching clues/dialogue that point at them
-- specifically -- no code change needed here when you do.
--
-- The generated case is NEVER sent to the client in any form. AccusationService is the
-- only thing that reads it, to compare a player's accusation against the answer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local InvestigationData = require(Modules.Data.InvestigationData)

local CaseGenerationService = {}

-- [player] = { branch = "human"|"pesugihan"|nil, culpritBySuspectId = { [suspectId] = role } }
local caseByPlayer = {}

function CaseGenerationService.Init(_services) end

local function poolFor(role)
	local pool = {}
	local flag = role == "human" and "isHumanCulprit" or "isPesugihanActor"
	for suspectId, suspect in pairs(InvestigationData.Suspects) do
		if suspect[flag] then
			table.insert(pool, suspectId)
		end
	end
	table.sort(pool) -- deterministic ordering before the random pick, for reproducible tests
	return pool
end

local function pickRandom(pool)
	if #pool == 0 then
		warn("[CaseGenerationService] No eligible suspects for this role -- check InvestigationData.Suspects")
		return nil
	end
	return pool[math.random(1, #pool)]
end

-- Called once per player per match (Bootstrap.onPlayerAdded), right after Difficulty is
-- set. Re-calling it (e.g. on a rematch) generates a fresh random solution.
function CaseGenerationService.GenerateCase(player, difficulty)
	local culpritBySuspectId = {}
	local branch = nil

	if difficulty == "Easy" then
		local humanId = pickRandom(poolFor("human"))
		if humanId then
			culpritBySuspectId[humanId] = "human"
		end
	elseif difficulty == "Medium" then
		branch = (math.random() < 0.5) and "human" or "pesugihan"
		local suspectId = pickRandom(poolFor(branch))
		if suspectId then
			culpritBySuspectId[suspectId] = branch
		end
	else -- Hard
		local humanId = pickRandom(poolFor("human"))
		local pesugihanPool = poolFor("pesugihan")

		-- Prefer two DISTINCT suspects when the content pool supports it; fall back to
		-- one suspect covering both roles (today's reality: only pak_joko is eligible
		-- for either) rather than silently making Hard mode unsolvable.
		local pesugihanId
		if humanId and #pesugihanPool > 1 then
			local filtered = {}
			for _, id in ipairs(pesugihanPool) do
				if id ~= humanId then
					table.insert(filtered, id)
				end
			end
			pesugihanId = pickRandom(filtered)
		else
			pesugihanId = pickRandom(pesugihanPool)
		end

		if humanId and humanId == pesugihanId then
			culpritBySuspectId[humanId] = "human_and_pesugihan"
		else
			if humanId then
				culpritBySuspectId[humanId] = "human"
			end
			if pesugihanId then
				culpritBySuspectId[pesugihanId] = "pesugihan"
			end
		end
	end

	caseByPlayer[player] = {
		branch = branch,
		culpritBySuspectId = culpritBySuspectId,
	}
end

function CaseGenerationService.RemovePlayer(player)
	caseByPlayer[player] = nil
end

-- Returns "human" | "pesugihan" | "human_and_pesugihan" | nil (innocent) for the given
-- suspectId, per this player's randomly generated case.
function CaseGenerationService.GetCulpritType(player, suspectId)
	local case = caseByPlayer[player]
	if not case then
		return nil
	end
	return case.culpritBySuspectId[suspectId]
end

-- Medium-only: which branch ("human" | "pesugihan") this session's true story is.
function CaseGenerationService.GetBranch(player)
	local case = caseByPlayer[player]
	return case and case.branch
end

return CaseGenerationService
