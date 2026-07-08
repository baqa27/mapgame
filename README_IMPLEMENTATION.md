# Implementation Notes — Main Game Scripting + UI (v3)

This folder is a **working, end-to-end starting point** for every Service and every UI
screen listed in `MAIN_GAME_SYSTEM_RULES.md`. It follows `ARCHITECTURE.md`'s folder shape
exactly, so it should merge into your existing project with **no restructuring** —
only a straight file copy/merge. All 29 `.lua` files pass a Lua syntax check.

## v2 changelog (this pass) — gaps found by re-reading every doc + the reference images

- **`NightTimerService` (new)** — implements `game_mechanics.md` rule #1 ("waktu ronda"
  per level). Counts down per-difficulty duration (`GameConfig.Night.DurationSeconds`),
  broadcasts `Night/TimeUpdated` every 5s, and on expiry checks the objective quota.
- **`CheckpointService.ReturnToLastCheckpoint()` (new)** — the "failure return" half of
  `ARCHITECTURE.md`'s own CheckpointService description was missing entirely. Now
  implemented: teleports the player's `HumanoidRootPart` back to the last checkpoint's
  live `CFrame` (read from the map part itself, never hardcoded). Triggered by:
  - `TrustService` when trust collapses into `"feared"` (rule #2: "kehilangan terlalu
    banyak kepercayaan warga akan menyebabkan pemain kembali ke checkpoint sebelumnya").
  - `NightTimerService` when time runs out and the objective quota isn't met (rule #2:
    "gagal menyelesaikan misi").
  - Deliberately **NOT** triggered on a single wrong accusation — `GAME LAVEL.md`'s
    review explicitly *rejected* stacking extra punishment on top of trust loss
    ("Alasan ditolak: ... sistem hukuman akan terasa terlalu berat"), so wrong
    accusations only cost trust, same as before.
- **Two-phase jimpitan collection** — `GAME LAVEL.md`'s Easy Mode "Main Action" is
  explicitly two steps: "**mengambil** jimpitan" then "**menyimpan** uangnya di pos
  ronda." `ObjectiveService` now tracks `carried` (picked up, not yet counted) separately
  from `progress` (deposited); depositing happens automatically at any checkpoint. This
  is also narratively convenient — it's the natural place for the "money disappears from
  storage" mystery to live later if you want to hook something into the deposit moment.
- **Locked interactables (`RequiresClueId` attribute, new)** — the reference map image
  shows Rumah Kosong with a padlock icon ("LOKASI MISTERI / FALSE CLUE LOC"). Any
  interactable can now carry an optional `RequiresClueId` attribute; `InteractionService`
  gates on it and fires `Interaction/Locked` (new remote) instead of routing through, so
  the environment team can padlock specific locations without any new code.
- **Kentongan / whisper / clue-found sound cues now actually play.** `GameConfig.Audio`
  existed in v1 but was never called anywhere — a real gap, since suara kentongan was an
  **accepted** suggestion in `GAME LAVEL.md`'s review ("Alasan diterima: ... membantu
  memberikan tanda ketika terjadi peristiwa penting"). `UIKit.PlaySound()` (new helper,
  no-ops safely on the `rbxassetid://0` placeholders) is now wired into
  `CheckpointController` (save/return), `AccusationController` (correct outcomes), and
  `JournalController`/`HorrorController` (clue found / whisper).
- **`TrustDelta` on dialogue choices is now actually used.** `game_mechanics.md`'s Player
  Actions table explicitly lists Dialogue Choice as affecting trust; v1 defined the delta
  constants in `GameConfig.Trust.Delta` but never read them. `DialogueService.Choose()`
  now applies `choice.TrustDelta` when present — one example is wired
  (`NarrativeData.NPCs.pak_rt`'s `report_missing` choice).
- **Entity flavor names** — `game_naratif.md`'s "Masukan dari kelompok Desi Fitria"
  section records the team's decision to use "setan gundul" (Medium) and "methek" (Hard)
  instead of a generic tuyul. `EntityAIService` now picks one of these per difficulty
  (`NarrativeData.EntityNames`) and includes it in the `Entity/Sighted` payload;
  `HorrorController` shows it in the whisper subtitle.
- **HUD now has a night clock** — `MAIN_GAME_SYSTEM_RULES.md`'s own UI inventory table
  said the HUD should show one, but v1's `HUDController` never built it. Fixed, plus the
  HUD now also shows carried-vs-deposited jimpitan count.

Everything else from the v1 README below still applies.

## v3 changelog — randomized culprit assignment (not previously in any doc)

None of the source docs (`game_naratif.md`, `GAME LAVEL.md`, `game_mechanics.md`) ever
say the guilty suspect(s) should be **randomly** picked per playthrough — v1/v2 had a
static `culpritType` hardcoded per suspect in `NarrativeData.Suspects` (Warga 05 was
always the Easy/Medium human culprit, Warga 07 was always the pesugihan culprit). That's
now fixed with a new Service:

- **`CaseGenerationService` (new)** — once per player per match
  (`Bootstrap.onPlayerAdded`), randomly generates that session's actual solution:
  - **Easy**: always a human culprit (never pesugihan, per `DESIGN_BRIEF.md`) — WHICH
    suspect is picked at random from the eligible pool.
  - **Medium**: 50/50 which of the two documented story branches is true this session
    (Story ID 1 = human, Story ID 2 = pesugihan), then a random suspect from that
    branch's pool is the actual culprit.
  - **Hard**: needs BOTH a human culprit and a pesugihan culprit, each picked
    independently at random from their own pools (matches `game_naratif.md`: "harus
    mengungkap seluruh pelaku, baik pencuri manusia maupun ... pesugihan").
  - The generated case is stored server-side only and is never sent to the client in any
    form — `AccusationService` is the only thing that reads it.
- **`NarrativeData.Suspects` schema changed**: `culpritType` (a fixed answer) was
  replaced with `eligibleRoles` (a pool of roles a suspect *could* be cast as). One
  suspect (`warga_2`) is a permanent decoy with `eligibleRoles = {}` — always innocent,
  giving the investigation a "false suspect" red herring regardless of which case gets
  generated, matching the "tersangka palsu" beat in `game_naratif.md`'s Medium dialogue.
- **`AccusationService`** now calls `CaseGenerationService.GetCulpritType(player,
  suspectId)` instead of reading a static field — no other logic changed (the
  Easy/Medium/Hard branching rules, trust penalties, and Hard's "both culprits" gate are
  all exactly as before).

If you want Easy to NOT be randomized (always the same single suspect), that's a one-line
change: give only one suspect `eligibleRoles = {"human"}` in `NarrativeData.Suspects`.


## What's actually implemented (not stubs)

- Full Remote plumbing: `RemoteRegistry` + `RemoteDefinitions` (19 remotes, cross-checked
  against every `RemoteRegistry.Get(...)` call in the codebase — no mismatches).
- 12 Services (the original 10 from `ARCHITECTURE.md` + `AccusationService` +
  `NightTimerService`), wired together via a shared registry table in
  `Bootstrap.server.lua` (no `require()` cycles between Services).
- `InteractionService` really scans `Workspace.Map.Gameplay`, wires every
  `ProximityPrompt` it finds under an interactable with an `InteractionType` attribute,
  keeps wiring anything streamed in later, and gates on `DifficultyOnly` /
  `RequiresClueId` before routing.
- `TrustService` really buckets numeric trust into the 4 public states, persists it
  through `SaveService`, and triggers a checkpoint return on collapse into `"feared"`.
- `DialogueService` really evaluates `Requires.ClueId` / `Requires.Trust`, greys out
  locked choices server-side, and applies `TrustDelta`; one full NPC (`pak_rt`) is wired
  end-to-end as a working example — extend `NarrativeData.NPCs`, no code changes needed.
- `PuzzleService` really implements one full puzzle type (multiple-choice "spot the
  anomaly") end-to-end — add more entries to its `Puzzles` table for more PuzzleIds, no
  Controller changes needed.
- `AccusationService` really resolves Easy/Medium/Hard branching per `game_naratif.md`'s
  ending rules, including Hard mode's "must catch both culprits" requirement.
- `NightTimerService` really counts down and returns the player on a failed night.
- `SaveService` really talks to DataStore (with `pcall` + a `PlayerRemoving` safety net).
- Every Controller really builds its `ScreenGui` in code via `UIKit` (palette,
  typography, tween + sound helpers matching `ROBLOX_UI_SKILL.md`) — nothing to build in
  Studio by hand, run the place and the UI exists.

## Contract corrections made while implementing (update your mental model)

`ProximityPrompt.Triggered` on the **server** already only fires after the engine
validates `MaxActivationDistance` — that already *is* the server-authoritative distance
check `ARCHITECTURE.md` asks for. So prompt-triggered actions (collecting a clue,
starting dialogue, opening a puzzle, reaching a checkpoint, opening the accusation board)
do **not** use a Remote — `InteractionService` calls the target Service's function
directly. `Puzzle/Data`, `Accusation/Open`, `Interaction/Locked`, `Checkpoint/Returned`,
`Night/TimeUpdated`, and `Night/TimeUp` were added as server→client pushes; `nodeId` was
added to the `Dialogue/Node` payload. `MAIN_GAME_SYSTEM_RULES.md` has been updated to
match — it's still the single source of truth going forward.

## TODO / placeholders you should know about

- `GameConfig.Audio` asset ids are all `rbxassetid://0` — the playback code is already
  wired everywhere it should be, it just no-ops until real ids are filled in.
- `HUDController`'s minimap is a plain panel + a colored blip mapped from world XZ to UI
  scale, assuming `Workspace.Map` is centered on world origin. Swap the panel for a real
  top-down map `ImageLabel` once the environment team exports one; adjust the offset math
  if `WorldData` places the map off-center.
- `NarrativeData.NPCs`, `.Suspects`, and `PuzzleService`'s `Puzzles` table each currently
  hold **one** fully-working example. Extend them with the rest of `game_naratif.md`'s
  content — no Service or Controller code changes are needed to add more entries.
- Only one dialogue choice has a `TrustDelta` wired as an example — add it to more
  choices as the narrative team decides which ones should move trust.
- `AccusationService`'s `HardPartial` ending isn't auto-recorded on its own — decide
  what "end of night" trigger should call
  `SaveService.RecordEnding(player, GameConfig.Ending.HardPartial)` if the player stops
  after only one culprit. `NightTimerService` expiring is a natural candidate hook if you
  want to wire it.
- False clues (`FalseClue` attribute) are intentionally **never** revealed to the client
  as false — this matches `DESIGN_BRIEF.md`'s Horror Rules ("Was the clue real?" is
  supposed to stay ambiguous). Don't "fix" this into an auto-reveal without checking with
  the narrative team first.
- Fonts: `UIKit.Font.Narrative` uses `Enum.Font.Cartoon` as a placeholder rustic-ish font.
  Swap for a licensed font asset per `ROBLOX_UI_SKILL.md` §3 once one is picked.

## How to move this into your project structure (for the AI agent via MCP)

The folder layout here **is** the target layout — no path translation needed:

```
src/shared/Modules/...                                  -> merge into your src/shared/Modules
src/game/ServerScriptService/GameServer/...              -> merge into your src/game/ServerScriptService
src/game/StarterPlayer/StarterPlayerScripts/GameClient/...-> merge into your src/game/StarterPlayer/StarterPlayerScripts
```

If your repo already has files at any of these paths (e.g. an existing `GameConfig.lua`),
**diff before overwriting** — merge the new fields in rather than blindly replacing, in
case the environment/narrative team already added content.

Nothing here touches `Workspace.Map` or anything under `src/lobby`.
