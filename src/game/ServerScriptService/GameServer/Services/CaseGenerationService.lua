-- ServerScriptService/GameServer/Services/CaseGenerationService.lua
-- Randomly generates each player's "solution" for the night, once per session, so the
-- guilty suspect(s) are NOT hardcoded and differ between playthroughs. This is the
-- system requested for: "Easy = selalu manusia (dipilih acak dari kandidat), Medium =
-- acak antara Story ID 1 (manusia) / Story ID 2 (pesugihan), Hard = butuh menangkap DUA
-- pelaku (satu manusia + satu pesugihan), keduanya dipilih acak dari kandidat masing-
-- masing." None of the source design docs specify random assignment explicitly (they
-- only describe the two Medium story branches and Hard's "must catch every culprit"
-- rule) -- this Service is the concrete system that makes it actually random per match,
-- built on top of those documented rules.
--
-- The generated case is NEVER sent to the client in any form. AccusationService is the
-- only thing that reads it, to compare a player's accusation against the answer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local NarrativeData = require(Modules.NarrativeData)

local CaseGenerationService = {}

-- [player] = { branch = "human"|"pesugihan"|nil, culpritBySuspectId = { [suspectId] = role } }
local caseByPlayer = {}

function CaseGenerationService.Init(_services) end

local function poolFor(role)
	local pool = {}
	for _, suspect in ipairs(NarrativeData.Suspects) do
		for _, eligible in ipairs(suspect.eligibleRoles) do
			if eligible == role then
				table.insert(pool, suspect.id)
				break
			end
		end
	end
	return pool
end

local function pickRandom(pool)
	if #pool == 0 then
		warn("[CaseGenerationService] No eligible suspects for this role -- check NarrativeData.Suspects")
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
		-- Easy is always a normal human thief (per DESIGN_BRIEF.md/GAME LAVEL.md) --
		-- WHICH suspect is picked at random from the eligible pool for replayability.
		local humanId = pickRandom(poolFor("human"))
		if humanId then
			culpritBySuspectId[humanId] = "human"
		end
	elseif difficulty == "Medium" then
		-- 50/50 which story branch is true this session: Story ID 1 (human) or
		-- Story ID 2 (pesugihan), per game_naratif.md's two Medium endings.
		branch = (math.random() < 0.5) and "human" or "pesugihan"
		local suspectId = pickRandom(poolFor(branch))
		if suspectId then
			culpritBySuspectId[suspectId] = branch
		end
	else -- Hard
		-- Hard always needs BOTH a human culprit and a pesugihan culprit caught
		-- (game_naratif.md: "harus mengungkap seluruh pelaku, baik pencuri manusia
		-- maupun pihak yang terlibat dalam praktik pesugihan"). Each is picked
		-- independently at random from its own pool.
		local humanId = pickRandom(poolFor("human"))
		local pesugihanId = pickRandom(poolFor("pesugihan"))
		if humanId then
			culpritBySuspectId[humanId] = "human"
		end
		if pesugihanId then
			culpritBySuspectId[pesugihanId] = "pesugihan"
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

-- Returns "human" | "pesugihan" | nil (innocent) for the given suspectId, per this
-- player's randomly generated case. This is the ONLY place AccusationService should
-- read "who's actually guilty" from -- never read NarrativeData.Suspects directly for
-- that, its eligibleRoles field is a pool, not an answer.
function CaseGenerationService.GetCulpritType(player, suspectId)
	local case = caseByPlayer[player]
	if not case then
		return nil
	end
	return case.culpritBySuspectId[suspectId]
end

-- Medium-only: which branch ("human" | "pesugihan") this session's true story is. Not
-- currently consumed anywhere, but useful if DialogueService/HorrorService later want to
-- bias flavor content toward whichever branch is actually true this session.
function CaseGenerationService.GetBranch(player)
	local case = caseByPlayer[player]
	return case and case.branch
end

return CaseGenerationService
