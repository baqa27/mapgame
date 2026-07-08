# Main Game System Rules
**Scope: Main Gameplay Place (`game.project.json`) only. Lobby is out of scope — already shipped separately.**

> **A working implementation of everything in this file already exists (v2)** — see
> `README_IMPLEMENTATION.md` and the `src/` folder shipped alongside this document. If
> you're an AI agent picking up this project, merge that `src/` folder into the Rojo
> project first and read the README's "v2 changelog" + "Contract corrections" sections
> before writing any new code — several details below were refined or added while
> implementing (noted inline).

This file is the single source of truth for Remote names, Attribute names, Service contracts, and
required UI screens for the Main Game. It does not repeat what's already explained in the companion
docs (`ARCHITECTURE.md`, `DESIGN_BRIEF.md`, `game_mechanics.md`, `game_naratif.md`,
`MAP_LEVEL_DESIGN_GUIDE.md`, `PUBLISHING.md`) — read those first, this file only adds the missing
implementation contract layer between "design" and "code."

If you add a new Remote, Attribute, or config field while implementing, **add it to the relevant
table in this file in the same change** — this file must never drift from the code.

---

## 1. Non‑negotiable constraints

- Server-authoritative for: objective progress, clue validity, trust value, puzzle results,
  checkpoint writes, accusation outcome, ending resolution, and distance validation for every
  `ProximityPrompt`.
- Client only renders UI/camera/audio/subtitles/journal, and sends *intent* Remotes.
- No runtime mutation of `Workspace.Map` geometry from any script beyond what
  `VillageWorldBuilder` already does for the marker guide. Once final art replaces the markers,
  scripts only add/verify **attributes** and **ProximityPrompts** on existing parts — they never
  move, delete, or recreate visual instances.
- Config values (thresholds, multipliers, ids) live in `GameConfig` / `NarrativeData`
  (`ReplicatedStorage.Modules`) — never hardcoded inline in a Service or a Controller.
- One pattern per concern: every gameplay Remote is owned by exactly one Service (no two systems
  writing to the same Remote).

---

## 2. Folder targets

```text
ReplicatedStorage
  Modules
    GameConfig         -- difficulty tables, thresholds, ids
    NarrativeData       -- endings, hints, entity flavor names (NOT NPCs/Suspects anymore)
    Data
      WorldData          -- real spawn coords: Houses, NPCs, Clues, Puzzles, Checkpoints
      DialogueData        -- full NPC dialogue trees (line/nextNode/choices/trustAction/...)
      InvestigationData   -- suspects, clues, puzzles (content + gating), GetClue/GetChain etc.
      ObjectiveData        -- per-difficulty step chains, GetChain(difficulty)
    Net                 -- RemoteRegistry, RemoteDefinitions
    Util
      AttributeConstants
      MarkerBuilder       -- shared glowing-marker builder used by both spawner Services
      Signal
  Remotes                -- created at runtime by RemoteRegistry

ServerScriptService
  GameServer
    Bootstrap.server.lua
    Services
      ObjectiveService
      TrustService
      InvestigationService
      DialogueService
      PuzzleService
      HorrorService
      EntityAIService
      CheckpointService
      CaseGenerationService
      AccusationService
      SaveService
      NightTimerService
      JimpitanSpawnerService     -- spawns world content (see §4)
      WorldObjectSpawnerService  -- spawns world content (see §4)
      InteractionService         -- always Init'd last

StarterPlayer
  StarterPlayerScripts
    GameClient
      Bootstrap.client.lua
      UI
        UIKit
      Controllers
        HUDController        -- FF-style minimap now lives here (see §9)
        JournalController
        DialogueController
        PuzzleController
        HorrorController
        CheckpointController
        AccusationController
        EndingController
```

---

## 3. Interactable attribute contract

From `ARCHITECTURE.md`, extended with the fields UI/controllers need. As of v4, every row
below is auto-spawned by `JimpitanSpawnerService`/`WorldObjectSpawnerService` from
`WorldData` coordinates on server start — this table is what to match if you ever
hand-place one instead (idempotent: a hand-placed part with the same name is never
touched by the spawners).

| InteractionType     | Required attributes                 | Notes |
|---|---|---|
| `jimpitan_can`       | `JimpitanId`                        | picked up via `JimpitanSpawnerService.Collect` |
| `clue`               | `ClueId`                            | text/`isFalse`/difficulty-gating resolved server-side from `InvestigationData.Clues[ClueId]` -- don't hand-type flavor text as attributes anymore |
| `npc`                | `NPCId`                              | `DialogueService` loads the tree from `DialogueData.Dialogues[NPCId]` |
| `puzzle`             | `PuzzleId`                          | `DifficultyOnly` auto-set from `InvestigationData.Puzzles[PuzzleId].requiredDifficulty` |
| `checkpoint`         | `CheckpointId`                      | id matches a `WorldData.Village.Checkpoints` key |
| `accusation_board`   | *(none)*                            | single instance, placed near the `ending_choice` checkpoint |

Optional attributes any interactable may carry (add support, don't require):

- `PromptText` (string) — overrides default `ProximityPrompt.ActionText`.
- `DifficultyOnly` (string: `"Easy"|"Medium"|"Hard"`) — interactable only enabled/active in that
  difficulty (e.g. the sumur ritual clue only exists Medium/Hard per the map reference image).
- `RequiresClueId` (string) — soft-locks the interactable until the player has collected the
  named clue; fires `Interaction/Locked` instead of routing through. Matches the padlock icon
  shown on Rumah Kosong in the reference map image.

Every interactable must have a `ProximityPrompt`; `InteractionService` auto-detects it, validates
distance server-side, then routes to the matching Service by `InteractionType`.

---

## 4. Core Services contract

For each Service: **Responsibility / Remotes in (client→server) / Remotes out (server→client) / UI it powers.**

### ObjectiveService
- Tracks the per-difficulty step CHAIN from `ObjectiveData.GetChain(difficulty)` -- one
  step active at a time (briefing -> collect jimpitan -> find clues -> talk to witnesses
  -> accuse). `ReportProgress(player, stepIdOrType, amount)` advances the current step if
  `stepIdOrType` matches its `id` (exact, used by `DialogueData`'s `objectiveProgress`
  field) or its `type` (generic, used by jimpitan/clue/puzzle/NPC-talk flows).
- Jimpitan collection stays two-phase: `AddCarriedJimpitan` on pickup (not yet counted),
  `DepositCarriedJimpitan` on reaching any checkpoint (converts to real progress) --
  matches GAME LAVEL.md's Easy Mode "Main Action": collect jimpitan, THEN store it at Pos
  Ronda.
- On step completion, if the step has a `checkpoint` field, looks up its position in
  `WorldData.Village.Checkpoints` and calls `CheckpointService.Reach` with it -- so
  finishing a step also banks a fail-return position, even without physically walking to
  a checkpoint pad.
- Out: `Objective/StateChanged` `{ title, description, progress, target, stepIndex,
  stepCount, carried, chainComplete }`
- UI: HUD objective tracker (now positioned just under the minimap, see §9).

### TrustService
- Owns internal numeric trust per player; **never exposes the number**. Trust collapsing into
  `"feared"` triggers `CheckpointService.ReturnToLastCheckpoint` — implements
  `game_mechanics.md` rule #2's "kehilangan terlalu banyak kepercayaan warga akan menyebabkan
  pemain kembali ke checkpoint sebelumnya."
- Out: `Trust/StateChanged` `{ state: "trusted"|"neutral"|"suspicious"|"feared" }`
- UI: HUD trust icon, feeds `DialogueService` gating.

### InvestigationService
- Clue journal, route-evidence comparison, false-clue tracking.
- Fed directly by `InteractionService` (no Remote) when a `clue` ProximityPrompt fires,
  or by `PuzzleService` on a correct puzzle answer.
- Out: `Investigation/ClueAdded` `{ clueId, text }` (never reveals `isFalse` to the client)
- UI: Clue Journal.

### DialogueService
- Branching NPC dialogue driven by `DialogueData.Dialogues[npcId]` (6 NPCs, real named
  content). Node schema: `line`, optional node-level `requiredTrust` (redirects to a
  `locked` node if the NPC defines one), `choices[]` each with `text`, `nextNode`/`close`,
  `requiredTrust`, `requiredClue`, `grantClue` (auto-collects via `InvestigationData`),
  `trustAction` (named delta from `GameConfig.Trust.Actions`), `objectiveProgress` (step
  id reported to `ObjectiveService`).
- Started directly by `InteractionService` (no Remote) when an `npc` ProximityPrompt fires.
- In: `Dialogue/Choose` `{ nodeId, choiceId }`
- Out: `Dialogue/Node` `{ nodeId, npcName, text, choices: [{ id, text, locked: bool, lockedReason: string? }] }`
- UI: Dialogue box.

### PuzzleService
- Sequence-recall puzzles ("repeat the pattern") from `InvestigationData.Puzzles` -- each
  has a `sequence` of small integers. Demo sequence is sent to the client for playback
  (acceptable exposure -- submission is still validated server-side, see
  `README_IMPLEMENTATION.md`'s Known Limitations).
- Opened directly by `InteractionService` (no Remote) when a `puzzle` ProximityPrompt fires.
- Out: `Puzzle/Data` `{ puzzleId, displayName, description, symbolCount, sequence }` (pushed on open)
- In: `Puzzle/Submit` `{ puzzleId, answer: number[] }`
- Out: `Puzzle/Result` `{ success: bool, rewardClueId: string? }`
- UI: Puzzle overlay (numbered pads, animated demo playback, tap-to-repeat).

### HorrorService
- Schedules subtle psychological events per difficulty intensity; **cosmetic only, never mutates
  trust/objective/clue state directly**.
- Out: `Horror/Event` `{ eventType: string, params: table }` (no coordinates or data that leak an
  answer)
- UI: Horror overlay (vignette/distortion), whisper subtitles.

### EntityAIService
- Non-combat observing-entity presence; never becomes a chase mechanic (per `DESIGN_BRIEF.md`).
- Out: `Entity/Sighted` `{ hintOnly: true }` — feeds subtitle/vignette hint, never exact position
  data that would trivialize investigation.

### CheckpointService
- Save/return-on-failure; unlocks optional hint after repeated investigation failures
  (`game_mechanics.md` rule #9). `ReportInvestigationFailure(player)` is called by
  `PuzzleService` on a wrong answer.
- Reached directly by `InteractionService` (no Remote) when a `checkpoint` ProximityPrompt fires,
  which also passes the checkpoint part's live `CFrame` so it can be used for teleport-back.
- `ReturnToLastCheckpoint(player, reason)` teleports the player's character back to the last
  reached checkpoint's `CFrame` — implements the "failure return" half of ARCHITECTURE.md's
  CheckpointService description. Called by `TrustService` (trust collapses to `"feared"`) and
  `NightTimerService` (time's up, objective quota not met). No-ops if no checkpoint reached yet.
- Out: `Checkpoint/Saved` `{ checkpointId }`, `Checkpoint/Returned` `{ reason }`,
  `Checkpoint/HintUnlocked` `{ hintText }`
- UI: checkpoint toast, hint badge.

### NightTimerService
*(added during implementation — implements `game_mechanics.md` rule #1's per-level "waktu
ronda" limit, which v1 of this doc didn't yet have a Service for.)*
- Counts down `GameConfig.Night.DurationSeconds[difficulty]`, broadcasting remaining seconds
  periodically. On expiry, checks `ObjectiveService.IsQuotaMet`; if not met, calls
  `CheckpointService.ReturnToLastCheckpoint(player, "time_up")` — implements rule #2's "gagal
  menyelesaikan misi ... akan menyebabkan pemain kembali ke checkpoint sebelumnya."
- Out: `Night/TimeUpdated` `{ secondsRemaining }`, `Night/TimeUp` `{ questCompleted }`
- UI: HUD night clock.

### SaveService
- Owns the DataStore profile (schema in §6). No direct client Remotes — other Services read/write
  through it.

### CaseGenerationService
*(added during implementation — none of the design docs specify random culprit
assignment explicitly, but they clearly imply per-session variety: Medium has two
distinct story branches and Hard requires catching multiple, separately-typed culprits.
This Service is what makes "who's actually guilty" different each playthrough instead of
a hardcoded answer.)*
- Once per player per match, randomly generates that session's solution:
  - Easy: one random human culprit (never pesugihan).
  - Medium: 50/50 which branch is true (human = Story ID 1, pesugihan = Story ID 2),
    then a random culprit from that branch's eligible pool.
  - Hard: one random human culprit AND one random pesugihan culprit, independently picked
    (prefers two distinct suspects when the pool supports it; falls back to a single
    `human_and_pesugihan` suspect otherwise -- see content note in
    `README_IMPLEMENTATION.md`).
- Reads `InvestigationData.Suspects[].isHumanCulprit`/`.isPesugihanActor` (a pool, NOT an
  answer) to pick from. **Currently a pool of one** (`pak_joko`) -- see
  `README_IMPLEMENTATION.md`'s content note.
- No Remotes — server-internal only. `AccusationService` is the sole consumer via
  `GetCulpritType(player, suspectId)`.

### AccusationService
*(added during implementation — the `accusation_board` InteractionType needs an owner;
not one of the original 10 Services but follows the same contract pattern.)*
- Resolves an accusation into an ending per §7's rules, checking the suspect against
  `CaseGenerationService`'s randomly generated solution for that player — never a static
  lookup. Tracks Hard-mode's "both culprits caught" requirement per player; a
  `human_and_pesugihan` culprit type satisfies both from one accusation.
- Opened directly by `InteractionService` (no Remote) when the `accusation_board` prompt fires.
- Out: `Accusation/Open` `{ suspects: [{id, name, profile}] }` (pushed on open -- profile
  is flavor text from `InvestigationData.Suspects`, safe to send, not the answer)
- In: `Accusation/Submit` `{ suspectId }`
- Out: `Accusation/Result` `{ outcome: string, endingId: string? }`
- UI: Accusation board (suspect profile cards).

### JimpitanSpawnerService
*(added during implementation — nothing was creating jimpitan pickups in Workspace at
all; this is what "which jimpitan do I take" actually needed.)*
- On server start, spawns one glowing jimpitan pickup near each `WorldData.Village.House`
  (idempotent via `MarkerBuilder` -- never overwrites a hand-placed/hand-edited part with
  the same name). Owns the full lifecycle: `Collect(player, part)` hides the part, calls
  `ObjectiveService.AddCarriedJimpitan`, and schedules a respawn after
  `GameConfig.JimpitanSpawn.RespawnDelaySeconds`.
- Jimpitan spawns are shared/global (one physical world state for the whole server, not
  per-player) -- `Jimpitan/Spawns` is broadcast via `FireAllClients` on every
  collect/respawn, plus `SendSnapshot(player)` pushes the current list to a newly-joined
  player.
- Out: `Jimpitan/Spawns` `{ spawns: [{ id, x, y, z }] }` -- active (uncollected) spawns only.
- UI: minimap jimpitan blips.

### WorldObjectSpawnerService
*(added during implementation — same gap as above, but for clues/puzzles/NPCs/
checkpoints/the accusation board; the environment team's map only has house/terrain
geometry, nothing else existed in Workspace.)*
- On server start, spawns clue markers, puzzle stations, NPC stands (with floating
  nameplates from `DialogueData`), checkpoint pads, and the accusation board, all from
  `WorldData.Village`'s real coordinates. Idempotent via `MarkerBuilder`, same as above.
- No Remotes -- purely creates world Instances that `InteractionService` then wires like
  any other interactable.

### InteractionService
- Single entry point that validates `ProximityPrompt` distance server-side and routes to the
  correct Service based on `InteractionType`. Also gates on `DifficultyOnly` and
  `RequiresClueId` attributes before routing — if either check fails, fires `Interaction/Locked`
  instead. No Controller ever calls another Service's Remote directly on prompt-trigger; it
  always goes through the prompt → InteractionService → Service path. In practice this means
  `InteractionService` calls the other Services' functions directly (e.g.
  `Services.DialogueService.Start(player, npcId)`) rather than firing a Remote — the
  ProximityPrompt's own server-side `.Triggered` event *is* the validated trigger.

---

## 5. Difficulty config shape

```lua
GameConfig.Difficulty = {
  Easy = {
    TrustPunishmentMultiplier = 1,
    ClueAmbiguity = "clear",
    HorrorFrequency = "low",
    CulpritLayers = 1,
    CheckpointDensity = "normal",
  },
  Medium = {
    TrustPunishmentMultiplier = 1.5,
    ClueAmbiguity = "semi",
    HorrorFrequency = "medium",
    CulpritLayers = 1,       -- branches to human OR pesugihan, not both
    CheckpointDensity = "normal",
  },
  Hard = {
    TrustPunishmentMultiplier = 2,
    ClueAmbiguity = "ambiguous",
    HorrorFrequency = "high",
    CulpritLayers = 2,       -- must resolve both human AND pesugihan
    CheckpointDensity = "high",
  },
}
```
Minimap stays visible in every difficulty — the "hide minimap on Hard" suggestion was explicitly
rejected in `GAME LAVEL.md`'s review section; do not reintroduce it.

---

## 6. SaveService data schema

Base fields (from `PUBLISHING.md`), extended with ending ids the narrative doc requires:

```lua
{
  checkpoint = "string",
  unlockedDifficulty = "Easy" | "Medium" | "Hard",
  endingsSeen = { "EasySolved", "MediumHuman", "MediumPesugihan", "HardFull", "HardPartial" },
  trustReputation = number,   -- internal, never sent raw to client
  totalGames = number,
  freeModeUnlocked = boolean, -- read by the Lobby place to gate Free Mode
}
```

---

## 7. Ending / unlock rules

> Who the actual culprit(s) are is randomized per playthrough by `CaseGenerationService`
> — the rules below describe the *branching logic*, not a fixed suspect identity.

- Easy complete → unlock Medium, reward item, secret dialogue.
- Medium → branches on the player's accusation: `MediumHuman` (Story ID 1) or `MediumPesugihan`
  (Story ID 2).
- Hard, both culprits found → `HardFull` (true ending), unlocks secret archive **and**
  `freeModeUnlocked = true` (Free Mode lives in the Lobby place, so this flag must be readable
  cross-place via DataStore/UserId — see `PUBLISHING.md` §6).
- Hard, only one culprit found → `HardPartial`, game does not count as finished.
- Repeated failure returns the player to the last checkpoint — it is never a hard game over.

---

## 8. Remote contract table

Prompt-triggered actions (collecting a clue, starting dialogue, opening a puzzle,
reaching a checkpoint, opening the accusation board) do **not** use a Remote — Roblox's
`ProximityPrompt.Triggered` fires server-side only after the engine validates distance,
so `InteractionService` calls the target Service's function directly. The table below is
what's actually created under `ReplicatedStorage.Remotes`.

| Remote | Kind | Direction | Payload | Server validation |
|---|---|---|---|---|
| `Objective/StateChanged` | Event | S→C | `{title, description, progress, target, stepIndex, stepCount, carried, chainComplete}` | n/a (display only) |
| `Trust/StateChanged` | Event | S→C | `{state}` | never send raw number |
| `Investigation/ClueAdded` | Event | S→C | `{clueId, text}` | n/a |
| `Dialogue/Node` | Event | S→C | `{nodeId, npcName, text, choices[]}` | n/a |
| `Dialogue/Choose` | Event | C→S | `{nodeId, choiceId}` | validate choice exists & unlocked |
| `Puzzle/Data` | Event | S→C | `{puzzleId, displayName, description, symbolCount, sequence}` | n/a |
| `Puzzle/Submit` | Event | C→S | `{puzzleId, answer: number[]}` | validate against server sequence |
| `Puzzle/Result` | Event | S→C | `{success, rewardClueId?}` | n/a |
| `Horror/Event` | Event | S→C | `{eventType, params}` | cosmetic-only params |
| `Entity/Sighted` | Event | S→C | `{hintOnly:true}` | never exact answer-revealing data |
| `Checkpoint/Saved` | Event | S→C | `{checkpointId}` | n/a |
| `Checkpoint/Returned` | Event | S→C | `{reason}` | n/a |
| `Checkpoint/HintUnlocked` | Event | S→C | `{hintText}` | server decides trigger, not client |
| `Accusation/Open` | Event | S→C | `{suspects: [{id, name, profile}]}` | n/a |
| `Accusation/Submit` | Event | C→S | `{suspectId}` | require min. clues gathered |
| `Accusation/Result` | Event | S→C | `{outcome, endingId?}` | n/a |
| `Night/TimeUpdated` | Event | S→C | `{secondsRemaining}` | n/a |
| `Night/TimeUp` | Event | S→C | `{questCompleted}` | n/a |
| `Interaction/Locked` | Event | S→C | `{reason}` | n/a |
| `Jimpitan/Spawns` | Event | S→C | `{spawns: [{id, x, y, z}]}` | active spawns only, broadcast to all |

---

## 9. UI inventory

| Screen (ScreenGui) | Purpose | Shown when | Data source | Notes |
|---|---|---|---|---|
| `HUDGui` | Free-Fire-style circular minimap (top-left, jimpitan/checkpoint/NPC/puzzle blips, rotating player arrow), objective step tracker below it, night clock top-center, trust icon top-right | always | Objective/Trust/Night/Jimpitan remotes + WorldData (static markers) | never blocks prompts; clues deliberately NOT shown on minimap |
| `JournalGui` | list collected clues, compare routes | toggle key | Investigation remotes | template+clone list items |
| `DialogueGui` | NPC portrait, text, choices | `Dialogue/Start` fires | Dialogue remotes | greyed/locked choices show `lockedReason` |
| `PuzzleGui` | puzzle-specific canvas | `Puzzle/Start` fires | Puzzle remotes | hint icon appears after N fails |
| `CheckpointGui` | small "progress saved" toast | `Checkpoint/Saved` fires | Checkpoint remotes | non-blocking, auto-dismiss |
| `AccusationGui` | suspect picker + confirm modal | player uses accusation board | Accusation remotes | confirm step, no accidental submit |
| `HorrorGui` | vignette/distortion, whisper subtitles | `Horror/Event`/`Entity/Sighted` fire | Horror/Entity remotes | cosmetic layer, must never block input |
| `EndingGui` | per-ending text + unlock notice | `Accusation/Result` resolves an ending | Accusation remotes + NarrativeData | pulls text from `NarrativeData`, never hardcoded |

---

## 10. Build order checklist

1. Confirm/extend `RemoteDefinitions` + `RemoteRegistry` per §8.
2. `GameConfig.Difficulty` + shared attribute constants module.
3. `InteractionService` (prompt validation + routing).
4. `TrustService`.
5. `InvestigationService` + `JournalGui`.
6. `DialogueService` + `DialogueGui`.
7. `PuzzleService` + `PuzzleGui` (build one full puzzle type end-to-end first, then template it).
8. `HorrorService` + `HorrorGui` (verify it never mutates gameplay state, only cosmetics).
9. `CheckpointService` + `CheckpointGui` + hint badge.
10. `NightTimerService` + HUD night clock (needs `CheckpointService.ReturnToLastCheckpoint`
    and `ObjectiveService.IsQuotaMet` from steps above).
11. Accusation flow + `AccusationGui` + ending resolution + `EndingGui`.
12. Finalize `SaveService` schema, wire all services to persist through it.
13. Assemble full `HUDGui` (objective + trust + minimap + clock together).
14. `JimpitanSpawnerService` + `WorldObjectSpawnerService` (populate `Workspace.Map.
    Gameplay` from `WorldData` -- do this AFTER the Services above exist, since
    `InteractionService` needs them registered to route the spawned prompts).
15. QA pass: server validation review, mobile UI scaling, confirm no `ProximityPrompt` is visually
    obstructed by any Gui.
16. Regenerate `tools/sync_to_studio.lua` (via `generate_sync.ps1` or `generate_sync.py`)
    and run/paste it in Roblox Studio -- code changes in `src/` don't exist in Studio
    until this step actually happens.

---

## 11. Don'ts

- Don't send raw numeric trust to the client — only the four bucketed states.
- Don't let `HorrorService` mutate trust/objective/clue state — cosmetic layer only.
- Don't hardcode dialogue/ending text in scripts — pull from `NarrativeData`.
- Don't rebuild, move, or delete `Workspace.Map` geometry from any script.
- Don't create a new Remote or attribute without adding it to the tables in §3/§8 first.
- Don't add a Remote for a prompt-triggered action (clue/dialogue/puzzle/checkpoint/
  accusation-open) — those go through `InteractionService` calling the target Service's
  function directly, since `ProximityPrompt.Triggered` is already the validated trigger.
- Don't add a checkpoint-return (or any other harsh penalty) directly on a single wrong
  accusation — `GAME LAVEL.md`'s review explicitly rejected stacking punishment on top of
  trust loss. Trust degradation is the only sanctioned consequence; a checkpoint return
  should only ever happen as an emergent result of trust collapsing to `"feared"`.
- Don't reveal `FalseClue` status to the client in any form — `DESIGN_BRIEF.md`'s Horror
  Rules deliberately keep "was the clue real?" ambiguous for the player.
