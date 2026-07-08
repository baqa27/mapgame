# Architecture

## Project Shape

Both places share `src/shared/Modules` and `src/shared/Remotes`.

```text
ReplicatedStorage
  Modules
    GameConfig
    NarrativeData
    TeleportDataUtil
    Data
    Net
    Util
  Remotes

ServerScriptService
  LobbyServer or GameServer
    Bootstrap.server.lua
    Services
    Managers
    Systems
    World

StarterPlayer
  StarterPlayerScripts
    LobbyClient or GameClient
      Bootstrap.client.lua
      Controllers
```

## Network Model

`RemoteRegistry` creates remotes on the server from `RemoteDefinitions`. Clients only wait for these remotes. Gameplay interaction is server authoritative:

- Queue joins/leaves are rate-limited.
- ProximityPrompt interactions are validated by distance on the server.
- Clue collection, objective progress, trust changes, checkpoint writes, and accusations are decided server-side.
- Clients only render UI, camera/audio feedback, subtitles, and journal state.

## Lobby Flow

The lobby is a **permanent static 512x512 stud environment** stored directly under `Workspace.Map`. It contains the queue pads, ProximityPrompts, lighting, village props, and dense forest ring boundary around the playable area (~210 stud radius). `Bootstrap` only connects the existing queue prompts to lobby services; it does not generate or rebuild the map at runtime.

`QueueManager` owns:

- Easy/Medium/Hard queues
- min 1 player, max 4 players
- 30 second countdown
- duplicate prevention
- disconnect cleanup
- synchronized state broadcast

`MatchmakingService` listens for ready queues and delegates teleport to `TeleportHandler`.

`TeleportHandler` sends:

- `matchId`
- `difficulty`
- `partyMembers`
- timestamp and version

via `TeleportOptions:SetTeleportData`.

## Gameplay Flow

`GameManager` reads teleport data, sets difficulty, builds the village map, starts services, plays intro cutscene, and resolves endings.

`VillageWorldBuilder` generates the 2048×2048 Bojongsari marker-only denah into `Workspace.Map` (note: Main Game map stays 2048×2048, only the Lobby was shrunk to 512×512):

- `Buildings`: box outlines and labels for houses 01-08, empty house, and other building zones.
- `Foliage`: central forest, banyan tree, bamboo grove, boundary trees.
- `Roads`: circular patrol route and branch roads.
- `Gameplay`: invisible anchors for `JimpitanSpawns`, `Clues`, `NPCs`, `Puzzles`, checkpoint and accusation board interactables.
- `Builder`: grid lines, box outlines, and floating labels that match the supplied denah.
- `Bounds`: invisible map boundaries.

The lobby builder uses the same `Workspace.Map` convention in the lobby place (512×512 studs), with the Easy pad to the west, Medium pad to the north, and Hard pad to the east. A forest ring of procedural trees surrounds the playable area.

Core services:

- `ObjectiveService`: global cooperative objective chain per difficulty.
- `TrustService`: internal numeric reputation, public states only: trusted, neutral, suspicious, feared.
- `InvestigationService`: clue journal, route evidence, false clue tracking.
- `DialogueService`: branching NPC dialogue with clue/trust requirements.
- `PuzzleService`: observation puzzle framework and clue rewards.
- `HorrorService`: subtle psychological events and false perception hooks.
- `EntityAIService`: non-combat observing entity presence.
- `CheckpointService`: checkpoint save/failure return/hint unlock.
- `SaveService`: DataStore profile, ending unlocks, difficulty unlocks, trust reputation.
- `InteractionService`: server validation and routing for ProximityPrompt actions.

## Difficulty Design

Easy:

- human culprit route
- clearer clue path
- lower trust punishment
- light horror events

Medium:

- human or pesugihan route
- false clues and ambiguous witness data
- stronger trust sensitivity
- more active psychological events

Hard:

- full truth route
- human culprit plus ritual layer
- high trust pressure
- heavier entity and hallucination events

## Preserving Interactions When Replacing Map Assets

Final map assets can be built on top of the marker-only guide, but keep these attributes on interactable BaseParts. The current map intentionally includes floating `BuilderLabel` billboards and neon line boxes so the environment team can see which space is a house, tree/vegetation zone, pos ronda, route, central forest, well, empty house, ritual area, clue, NPC, puzzle, or jimpitan object.

- `InteractionType = "jimpitan_can"` with `JimpitanId`
- `InteractionType = "clue"` with `ClueId`
- `InteractionType = "npc"` with `NPCId`
- `InteractionType = "puzzle"` with `PuzzleId`
- `InteractionType = "checkpoint"` with `CheckpointId`
- `InteractionType = "accusation_board"`

Each interactable should have a `ProximityPrompt`. The server will pick it up automatically.
