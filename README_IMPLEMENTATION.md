# Implementation Notes — Main Game Scripting + UI (v4)

## v5 changelog — marker overlap, ground-snapping, jimpitan minimap race

Triggered by a Studio playtest screenshot showing a Clue icon overlapping an NPC's
name plate, plus a report that jimpitan pickups never show up on the minimap and that
item placement generally looks wrong (floating / sunken into the ground).

**Root causes found (all three confirmed by reading the actual code, not guessed):**

1. `MarkerBuilder`'s Icon and NameLabel `BillboardGui`s had no `MaxDistance` -- clues are
   deliberately placed close to their witness NPC (by design, ~20-30 studs apart), and
   at any camera distance beyond close-up the two fixed-pixel billboards visually
   collided. Fixed by giving Icon a shorter `MaxDistance` (35 studs) than NameLabel (70
   studs) -- applied on both the create path and the idempotent-update path, so a re-sync
   fixes markers that already exist.
2. **The runtime spawners (`JimpitanSpawnerService`, `WorldObjectSpawnerService`) never
   raycast markers onto real ground** -- they placed every marker at WorldData's raw
   (guessed) Y coordinate. A *separate*, manually-run tool
   (`tools/spawn_markers_studio.lua`) already had the raycasting logic, but nothing forced
   anyone to run it, and the two systems used slightly different map-folder-resolution
   fallbacks. Moved ground-snapping directly into `MarkerBuilder.EnsureMarker` (raycasts
   once, only for newly-created parts, excluding the shared Gameplay folder so it never
   snaps onto a sibling marker) -- this now happens automatically on every server start,
   for every marker type, with no manual step. `spawn_markers_studio.lua` is kept only as
   a one-off bulk re-align tool for markers created *before* this fix (see its header).
3. **Jimpitan markers never appeared on a fresh join's minimap.** `Bootstrap.server.lua`
   pushed the initial snapshot via `task.defer` right after `PlayerAdded`, which can (and
   often does) fire before the client's `HUDController` has connected its
   `Jimpitan/Spawns` listener -- an event fired before anyone's listening is simply lost,
   with no error. After that, the only other broadcast trigger was `Collect()`, so a
   solo/first-time player would never see jimpitan on the minimap at all (they'd have to
   find one blind before the map would show any). Added a new client -> server remote,
   `Jimpitan/RequestSnapshot`: `HUDController` fires it right after connecting its
   listener, guaranteeing correct ordering regardless of how long client scripts take to
   load. The original `task.defer` push is left in place as a harmless first attempt.

**If you already have markers placed in Studio from before this fix:** ground-snapping
only runs when `MarkerBuilder.EnsureMarker` *creates* a part (idempotence means it never
touches an existing one), so already-existing floating/sunken markers won't self-correct.
Delete the stale ones under `Workspace.Map.Gameplay` (or `Workspace.Maps.*.Gameplay`) in
Studio's Explorer, then re-sync + Play -- the spawners will recreate them correctly this
time.

## v4 changelog — integration fix + world spawners + FF-style minimap + UI polish

This pass started from a Studio playtest screenshot: bare UI text boxes, an empty
minimap, and no visible jimpitan pickups anywhere in the world. Investigating the actual
repo (not just the file list, the content) turned up the real cause, which was bigger
than a UI problem:

**What was actually wrong:**
1. Your Antigravity agent had already written much richer content than v1-v3 shipped
   with — `Data/DialogueData.lua` (6 full NPC dialogue trees with real names), `Data/
   InvestigationData.lua` (10 clues, 3 puzzles, suspect profiles), `Data/ObjectiveData.lua`
   (a proper multi-step objective chain per difficulty), and `Data/WorldData.lua` (real
   in-world coordinates for every house, NPC, clue, puzzle, and checkpoint — matching the
   environment team's actual built map).
2. **None of it was wired into any Service.** `ObjectiveService`, `DialogueService`,
   `PuzzleService`, and `AccusationService` were all still running the old v1-v3
   placeholder logic (one generic `pak_rt` NPC, one multiple-choice puzzle, a single
   "collect N jimpitan" counter). Confirmed via `grep -rl "DialogueData\|
   InvestigationData\|ObjectiveData" src/game/` returning nothing.
3. **None of it had even been synced to Studio.** `tools/sync_to_studio.lua` — the
   script you actually run to push code into Studio — only packaged the original v1-v3
   file set. The four `Data/*.lua` files were never in it at all (confirmed by grepping
   the packaged `path = "..."` entries).
4. `Data/ObjectiveData.lua` referenced `GameConfig.Objectives.Types` and `GameConfig.
   Checkpoints`, neither of which existed in `GameConfig.lua` — so even if someone HAD
   required it, it would have errored immediately.
5. **No jimpitan pickups, clue markers, puzzle stations, or NPC stands existed anywhere
   in Workspace.** The environment team's map only has house/terrain geometry (GLTF
   import) — nothing ever created the actual interactable Parts. `InteractionService`
   was correctly waiting for `Workspace.Map.Gameplay`, but nothing was populating it.

**What this pass fixes, in order:**

### 1. Wired the existing rich content into the Service layer
- `GameConfig.lua`: added the missing `Objectives.Types`, `Checkpoints`, and a new
  `Trust.Actions` table (named trust deltas like `HELPED_WARGA`/`WRONG_DIALOGUE`, used by
  DialogueData's `trustAction` field instead of raw numbers).
- `ObjectiveService`: fully rewritten around `ObjectiveData.GetChain(difficulty)` — a
  proper step-by-step chain (briefing → collect jimpitan → find clues → talk to
  witnesses → accuse) instead of one flat counter. `ReportProgress(player, stepIdOrType,
  amount)` matches either an exact step id (from dialogue) or a generic type (from
  jimpitan/clue/puzzle pickups), advancing only the currently active step.
- `DialogueService`: fully rewritten to read `DialogueData.Dialogues`' actual schema
  (`line`/`nextNode`/`close`/`requiredTrust`/`requiredClue`/`grantClue`/`trustAction`/
  `objectiveProgress`) instead of the old placeholder schema. Node-level trust gates now
  redirect to an NPC's `locked` node (Mbah Darmo uses this).
- `PuzzleService`: fully rewritten for `InvestigationData.Puzzles`' actual puzzle type —
  sequence-recall ("repeat the pattern"), not multiple-choice. Demo sequence plays once,
  then the player taps it back.
- `AccusationService` + `CaseGenerationService`: now read suspect eligibility from
  `InvestigationData.Suspects` (`isHumanCulprit`/`isPesugihanActor` flags) instead of the
  old `NarrativeData.Suspects` table, which has been trimmed (see below).
- `InteractionService`: clue text/false-flag now resolved server-side from
  `InvestigationData.GetClue(clueId)` — map parts only need a `ClueId` attribute, not
  hand-typed `ClueText`/`FalseClue` attributes anymore.
- `NarrativeData.lua` trimmed to just `Endings`/`Hints`/`EntityNames` — NPCs and
  Suspects are now fully owned by `DialogueData.lua`/`InvestigationData.lua`. No dangling
  references remain (verified via grep).

**Content note on randomization:** `InvestigationData.Suspects` currently only flags
**one** suspect (`pak_joko`) as eligible for either culprit role — everyone else is
explicitly written as innocent, with clues/dialogue that only make sense if Pak Joko is
guilty (`muddy_sandals` is literally "di gang rumah Pak Joko"). So right now
`CaseGenerationService`'s randomization is a pool of one — it'll always resolve to Pak
Joko, not because the system is broken, but because only one suspect has guilt-supporting
content written yet. Add 2-3 more suspects with `isHumanCulprit`/`isPesugihanActor =
true` **and** matching clues/dialogue pointing at them, and real session-to-session
variety kicks in automatically — no code changes needed.

### 2. New: auto-spawned world content (this is what fixes "jimpitan belum ada")
- **`JimpitanSpawnerService` (new)** — spawns one glowing, gently bobbing/spinning
  jimpitan can near each house in `WorldData.Village.Houses`. Owns the full pickup
  lifecycle: collect → hide → respawn after `GameConfig.JimpitanSpawn.
  RespawnDelaySeconds` (25s). Broadcasts the active spawn list to every client (jimpitan
  are shared/global, not per-player) via a new `Jimpitan/Spawns` Remote, which is what
  feeds the minimap.
- **`WorldObjectSpawnerService` (new)** — same idea for everything else: clue markers,
  puzzle stations, NPC stands (with floating nameplates), checkpoint pads, and the
  accusation board — all positioned from `WorldData.Village`'s real coordinates.
- **Both are idempotent** (`Util/MarkerBuilder.lua`'s `EnsureMarker` skips creation if a
  same-named part already exists) — so once your environment team places real hand-built
  models with the same names, these services will never overwrite them. This is meant to
  fill the gap until real art exists, not fight your teammate's work.

### 3. Minimap rebuilt Free-Fire style (top-left, circular, shows jimpitan)
- Moved from an empty bottom-right box to a **circular minimap, top-left**, matching the
  reference you asked for.
- **North-up**, windowed to `GameConfig.Minimap.WorldRadiusStuds` (260 studs) around the
  player — only nearby markers show, keeping it readable instead of the whole 2048-stud
  map squeezed into one circle.
- Only the **player arrow rotates** (facing direction, computed from
  `HumanoidRootPart.CFrame.LookVector`) — simpler and just as readable as rotating the
  whole map texture.
- Shows: jimpitan (gold, live from the `Jimpitan/Spawns` Remote), checkpoints, NPCs, and
  puzzle stations (all static, read straight from the shared `WorldData` module — no new
  Remote needed since none of that is a secret). **Clues are deliberately NOT shown** —
  putting them on the minimap would trivialize the investigation loop the whole game is
  built around.
- Objective tracker moved to sit just under the minimap (was a separate top-left box);
  now shows the current step's title, "Tahap N/M", live progress, and carried-jimpitan
  count in one place.

### 4. General UI polish
- `UIKit.ApplyPanelChrome` (new) — a subtle border (`UIStroke`) + soft gradient, applied
  automatically inside `NewFrame`/`NewButton`. Every panel in the game gets this for
  free without touching each Controller individually — that's the difference between the
  flat boxes in your screenshot and something that reads as a designed UI.
- `AccusationController` rebuilt as suspect profile cards (name + blurb from
  `InvestigationData.Suspects`) instead of plain buttons — reads like an actual case
  board now.
- `PuzzleController` rebuilt for the sequence-recall type: numbered pads, animated demo
  playback, tap-to-repeat input.

## Deploying this (no PowerShell needed)

`tools/sync_to_studio.lua` has been **regenerated already** — it now packages all 37
files (your 4 Data files + everything else), including the 3 new files this pass added.
You don't need to run `generate_sync.ps1` yourself: just take the new
`tools/sync_to_studio.lua` and run/paste it in Roblox Studio's command bar the same way
you always have. Everything — old files that changed, and brand-new files like
`JimpitanSpawnerService` — will be created/updated in one shot.

If you keep editing files locally afterward, `generate_sync.ps1` is untouched and still
works exactly as before for regenerating the sync script yourself. There's also now a
`generate_sync.py` (Python port, same logic) in case it's ever more convenient to
regenerate from this side instead.

## Known limitations / TODO

- **Objective/timer state is still per-player, not server-wide**, even though
  `ARCHITECTURE.md` describes `ObjectiveService` as tracking a "global cooperative
  objective chain" and the lobby supports 1-4 players per match. Right now, if 2 players
  are in the same match, each has their own independent progress bar rather than a truly
  shared party objective. Deliberately deferred — it's a real architecture change (a
  server-wide "session" concept, one difficulty/timer per server instead of per player),
  not a small patch, and wasn't part of what broke this round. Worth doing as its own
  pass if co-op play is a near-term priority.
- **Puzzle demo sequence is sent to the client** so it can animate the playback — this
  means a technically-inclined player could read network traffic to skip "watching" the
  pattern. Submission is still validated server-side, so this doesn't expose any core
  game secret (accusation solutions stay server-only), just this one puzzle's answer once
  it's already open. Fine for now; tighten later with server-timed in-world audio/light
  cues instead if you want zero exposure.
- **`CaseGenerationService` is a pool of one** until more suspects get
  `isHumanCulprit`/`isPesugihanActor` flags + supporting clues/dialogue (see the content
  note above) — the system is fully random-capable, the content just isn't there yet.
- Minimap's north/south mapping (`-Z = up on screen`) is a guess at your map's compass
  convention since I don't have the actual Studio scene to check against — flip the sign
  in `HUDController`'s `updateMarker` if it turns out backwards once you test it.

## What's actually implemented (not stubs)

- Full Remote plumbing: `RemoteRegistry` + `RemoteDefinitions` (20 remotes, including
  the new `Jimpitan/Spawns` — cross-checked against every `RemoteRegistry.Get(...)` call
  in the codebase, no mismatches).
- 15 Services wired together via a shared registry table in `Bootstrap.server.lua` (no
  `require()` cycles between Services): the original 10, plus `AccusationService`,
  `NightTimerService`, `CaseGenerationService`, and this pass's `JimpitanSpawnerService`
  + `WorldObjectSpawnerService`.
- `JimpitanSpawnerService`/`WorldObjectSpawnerService` really populate
  `Workspace.Map.Gameplay` from `WorldData`'s real coordinates on server start — this is
  no longer an empty folder InteractionService is hoping something else fills in.
- `InteractionService` really scans `Workspace.Map.Gameplay`, wires every
  `ProximityPrompt` it finds under an interactable with an `InteractionType` attribute,
  keeps wiring anything streamed in later, and gates on `DifficultyOnly` /
  `RequiresClueId` before routing.
- `TrustService` really buckets numeric trust into the 4 public states, persists it
  through `SaveService`, and triggers a checkpoint return on collapse into `"feared"`.
- `DialogueService` really evaluates `DialogueData`'s full schema (6 NPCs, real
  branching, `grantClue`/`trustAction`/`objectiveProgress` hooks) — not a placeholder.
- `PuzzleService` really implements the sequence-recall puzzle type end-to-end (3
  puzzles from `InvestigationData.Puzzles`) — add more entries there for more PuzzleIds,
  no Controller changes needed.
- `ObjectiveService` really drives the full per-difficulty step chain from
  `ObjectiveData.lua`, not a single counter.
- `AccusationService` really resolves Easy/Medium/Hard branching per `game_naratif.md`'s
  ending rules against `CaseGenerationService`'s randomized solution, including Hard
  mode's "must catch both culprits" requirement (with `human_and_pesugihan` combined-
  suspect handling for today's pool-of-one content).
- `NightTimerService` really counts down and returns the player on a failed night.
- `SaveService` really talks to DataStore (with `pcall` + a `PlayerRemoving` safety net).
- Every Controller really builds its `ScreenGui` in code via `UIKit` (palette,
  typography, panel chrome, tween + sound helpers) — nothing to build in Studio by hand,
  run the place and the UI exists, including the minimap and world markers.

## Contract corrections made while implementing (update your mental model)

`ProximityPrompt.Triggered` on the **server** already only fires after the engine
validates `MaxActivationDistance` — that already *is* the server-authoritative distance
check `ARCHITECTURE.md` asks for. So prompt-triggered actions (collecting a clue,
starting dialogue, opening a puzzle, reaching a checkpoint, opening the accusation board)
do **not** use a Remote — `InteractionService` calls the target Service's function
directly. `Puzzle/Data`, `Accusation/Open`, `Interaction/Locked`, `Checkpoint/Returned`,
`Night/TimeUpdated`, `Night/TimeUp`, and `Jimpitan/Spawns` were added as server→client
pushes; `nodeId` was added to the `Dialogue/Node` payload. `MAIN_GAME_SYSTEM_RULES.md`
has been updated to match — it's still the single source of truth going forward.

Map parts only need an id attribute now, not full flavor text: a clue Part just needs
`ClueId` (text/false-flag comes from `InvestigationData` server-side); a puzzle Part just
needs `PuzzleId`; an NPC Part just needs `NPCId`. This matters if your environment team
ever hand-places any of these instead of relying on the auto-spawners — they don't need
to type out clue text into Studio Attributes panels, just the id.

## TODO / placeholders you should know about

- `GameConfig.Audio` asset ids are all `rbxassetid://0` — the playback code is already
  wired everywhere it should be, it just no-ops until real ids are filled in.
- `CaseGenerationService` is currently a pool of one eligible suspect (see the v4
  changelog above) — fully random-capable, just needs more guilt-eligible content.
- Objective/timer state is per-player, not truly shared across a co-op party yet (see v4
  changelog's Known Limitations).
- `AccusationService`'s `HardPartial` ending isn't auto-recorded on its own — decide
  what "end of night" trigger should call
  `SaveService.RecordEnding(player, GameConfig.Ending.HardPartial)` if the player stops
  after only one culprit. `NightTimerService` expiring is a natural candidate hook.
- False clues (`isFalse` in `InvestigationData.Clues`) are intentionally **never**
  revealed to the client as false — matches `DESIGN_BRIEF.md`'s Horror Rules ("Was the
  clue real?" is supposed to stay ambiguous). Don't "fix" this into an auto-reveal
  without checking with the narrative team first.
- Fonts: `UIKit.Font.Narrative` uses `Enum.Font.Cartoon` as a placeholder rustic-ish font.
  Swap for a licensed font asset once one is picked.
- World marker visuals (glowing shapes + emoji billboards) are a functional placeholder,
  not final art — `MarkerBuilder.EnsureMarker` is idempotent specifically so your
  environment team can hand-replace any of them permanently without a code change.

## How to move this into your project structure (for the AI agent via MCP)

The folder layout here **is** the target layout — no path translation needed:

```
src/shared/Modules/...                                  -> merge into your src/shared/Modules
src/game/ServerScriptService/GameServer/...              -> merge into your src/game/ServerScriptService
src/game/StarterPlayer/StarterPlayerScripts/GameClient/...-> merge into your src/game/StarterPlayer/StarterPlayerScripts
```

Then run `tools/sync_to_studio.lua` in Roblox Studio's command bar (already packages
everything, see "Deploying this" above) — that's the one step that actually gets it into
your live Studio session.

Nothing here touches `Workspace.Map`'s geometry or anything under `src/lobby` — the two
new spawner Services only ADD Parts under `Workspace.Map.Gameplay`, and only if
same-named ones don't already exist there.
