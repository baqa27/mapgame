-- ReplicatedStorage/Modules/Net/RemoteDefinitions.lua
-- Flat list of RemoteEvent names created under ReplicatedStorage.Remotes by RemoteRegistry.
--
-- IMPORTANT: prompt-triggered actions (collecting a clue, starting dialogue, opening a
-- puzzle, reaching a checkpoint) do NOT need a client->server remote. Roblox's
-- ProximityPrompt.Triggered already only fires after the engine validates distance
-- server-side, so InteractionService listens to that event directly. Remotes below only
-- cover: (a) server -> client pushes, and (b) client -> server follow-ups that happen
-- *after* a prompt UI is already open (choosing a dialogue option, submitting a puzzle
-- answer, submitting an accusation).

return {
	-- Server -> Client
	"Objective/StateChanged",
	"Trust/StateChanged",
	"Investigation/ClueAdded",
	"Dialogue/Node",
	"Puzzle/Data",
	"Puzzle/Result",
	"Horror/Event",
	"Entity/Sighted",
	"Checkpoint/Saved",
	"Checkpoint/Returned",
	"Checkpoint/HintUnlocked",
	"Accusation/Open",
	"Accusation/Result",
	"Night/TimeUpdated",
	"Night/TimeUp",
	"Interaction/Locked",
	"Jimpitan/Spawns",

	-- Client -> Server
	"Dialogue/Choose",
	"Puzzle/Submit",
	"Accusation/Submit",
	"Jimpitan/RequestSnapshot", -- fired once by HUDController after it's connected and
	-- ready to receive Jimpitan/Spawns, so the initial minimap snapshot can never be lost
	-- to a race between server push and client listener setup (see JimpitanSpawnerService).
}
