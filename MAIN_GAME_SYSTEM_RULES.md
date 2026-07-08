# Main Game System Rules
**Scope: Main Gameplay Place only. Lobby is out of scope — already shipped separately.**

> **A working implementation of everything in this file already exists (v2)** — see
> `README_IMPLEMENTATION.md` and the `src/` folder shipped alongside this document. If
> you're an AI agent picking up this project, merge that `src/` folder into the
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
    NarrativeData       -- dialogue trees, ending text, hint text
    Data                -- WorldData (spawn coords etc., see MAP_LEVEL_DESIGN_GUIDE.md)
    Net                 -- RemoteRegistry, RemoteDefinitions
    Util
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
      SaveService
      InteractionService
      NightTimerService
    Managers
    Systems
    World               -- VillageWorldBuilder

StarterPlayer
  StarterPlayerScripts
    GameClient
      Bootstrap.client.lua
      Controllers
        HUDController
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

From `ARCHITECTURE.md`, extended with the fields UI/controllers need:

| InteractionType     | Required attributes                 | Notes |
|---|---|---|
| `jimpitan_can`       | `JimpitanId`                        | picked up via `InteractionService` |
| `clue`               | `ClueId`, `FalseClue` (bool, opt.)  | `FalseClue` only meaningful Medium/Hard |
| `npc`                | `NPCId`                              | `DialogueService` loads tree from `NarrativeData[NPCId]` |
| `puzzle`             | `PuzzleId`                          | |
| `checkpoint`         | `CheckpointId`                      | |
| `accusation_board`   | *(none)*                            | single instance |

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
- Tracks the global cooperative objective chain per difficulty (jimpitan quota, checkpoints hit).
  Jimpitan collection is two-phase: `AddCarriedJimpitan` on pickup (not yet counted),
  `DepositCarriedJimpitan` on reaching any checkpoint (converts to real progress) — matches
  GAME LAVEL.md's Easy Mode "Main Action": collect jimpitan, THEN store it at Pos Ronda.
- Out: `Objective/StateChanged` `{ label: string, progress: number, target: number, carried: number }`
- UI: HUD objective tracker.

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
- Branching NPC dialogue gated by clue/trust requirements from `NarrativeData`.
- Started directly by `InteractionService` (no Remote) when an `npc` ProximityPrompt fires.
- In: `Dialogue/Choose` `{ nodeId, choiceId }`
- Out: `Dialogue/Node` `{ nodeId, npcName, text, choices: [{ id, text, locked: bool, lockedReason: string? }] }`
- UI: Dialogue box.

### PuzzleService
- Observation-puzzle framework, hands out clue reward on success. Implemented end-to-end
  for one puzzle type (multiple-choice "spot the anomaly") — see implementation code.
- Opened directly by `InteractionService` (no Remote) when a `puzzle` ProximityPrompt fires.
- Out: `Puzzle/Data` `{ puzzleId, question, options: [{id, text}] }` (pushed on open)
- In: `Puzzle/Submit` `{ puzzleId, answer }`
- Out: `Puzzle/Result` `{ success: bool, rewardClueId: string? }`
- UI: Puzzle overlay.

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
  - Hard: one random human culprit AND one random pesugihan culprit, independently picked.
- Reads `NarrativeData.Suspects[].eligibleRoles` (a pool, NOT an answer) to pick from.
- No Remotes — server-internal only. `AccusationService` is the sole consumer via
  `GetCulpritType(player, suspectId)`.

### AccusationService
*(added during implementation — the `accusation_board` InteractionType needs an owner;
not one of the original 10 Services but follows the same contract pattern.)*
- Resolves an accusation into an ending per §7's rules, checking the suspect against
  `CaseGenerationService`'s randomly generated solution for that player — never a static
  lookup. Tracks Hard-mode's "both culprits caught" requirement per player.
- Opened directly by `InteractionService` (no Remote) when the `accusation_board` prompt fires.
- Out: `Accusation/Open` `{ suspects: [{id, name, eligibleRoles}] }` (pushed on open — the
  eligibility pool is safe to send, it's not the answer)
- In: `Accusation/Submit` `{ suspectId }`
- Out: `Accusation/Result` `{ outcome: string, endingId: string? }`
- UI: Accusation board.

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
| `Objective/StateChanged` | Event | S→C | `{label, progress, target}` | n/a (display only) |
| `Trust/StateChanged` | Event | S→C | `{state}` | never send raw number |
| `Investigation/ClueAdded` | Event | S→C | `{clueId, text}` | n/a |
| `Dialogue/Node` | Event | S→C | `{nodeId, npcName, text, choices[]}` | n/a |
| `Dialogue/Choose` | Event | C→S | `{nodeId, choiceId}` | validate choice exists & unlocked |
| `Puzzle/Data` | Event | S→C | `{puzzleId, question, options[]}` | n/a |
| `Puzzle/Submit` | Event | C→S | `{puzzleId, answer}` | validate against server answer |
| `Puzzle/Result` | Event | S→C | `{success, rewardClueId?}` | n/a |
| `Horror/Event` | Event | S→C | `{eventType, params}` | cosmetic-only params |
| `Entity/Sighted` | Event | S→C | `{hintOnly:true}` | never exact answer-revealing data |
| `Checkpoint/Saved` | Event | S→C | `{checkpointId}` | n/a |
| `Checkpoint/Returned` | Event | S→C | `{reason}` | n/a |
| `Checkpoint/HintUnlocked` | Event | S→C | `{hintText}` | server decides trigger, not client |
| `Accusation/Open` | Event | S→C | `{suspects: [{id, name}]}` | n/a |
| `Accusation/Submit` | Event | C→S | `{suspectId}` | require min. clues gathered |
| `Accusation/Result` | Event | S→C | `{outcome, endingId?}` | n/a |
| `Night/TimeUpdated` | Event | S→C | `{secondsRemaining}` | n/a |
| `Night/TimeUp` | Event | S→C | `{questCompleted}` | n/a |
| `Interaction/Locked` | Event | S→C | `{reason}` | n/a |

---

## 9. UI inventory

| Screen (ScreenGui) | Purpose | Shown when | Data source | Notes |
|---|---|---|---|---|
| `HUDGui` | objective (carried+deposited), trust icon, minimap, night clock | always | Objective/Trust/Night remotes | never blocks prompts |
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
14. QA pass: server validation review, mobile UI scaling, confirm no `ProximityPrompt` is visually
    obstructed by any Gui.

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
