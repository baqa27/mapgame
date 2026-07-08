# Publishing And Roblox Setup

## 1. Create The Experience

1. Open Roblox Studio.
2. Create or open the experience that will become the public game.
3. Make the Lobby Place the start place.
4. Add a second place under the same experience for Main Gameplay.

TeleportService works reliably when both places are in the same Roblox universe.

## 2. Publish The Lobby Place

Open the lobby place in Studio. Publish it, then copy the Lobby Place ID.

## 3. Publish The Main Gameplay Place

Open the gameplay place in Studio. Publish it under the same experience, then copy the Gameplay Place ID.

## 4. Set Place IDs

Open `src/shared/Modules/GameConfig.lua`:

```lua
GameConfig.LOBBY_PLACE_ID = 0000000000
GameConfig.GAME_PLACE_ID = 0000000000
```

Sync or rebuild both places after changing these IDs.

## 5. TeleportService Notes

The lobby uses:

- `TeleportOptions.ShouldReserveServer = true`
- `TeleportOptions:SetTeleportData(...)`
- `TeleportService:TeleportAsync(...)`

If `GAME_PLACE_ID` is still `0`, the lobby runs a safe Studio simulation instead of teleporting.

## 6. DataStore Setup

For live game saves:

1. Publish the experience.
2. In Studio, open Game Settings.
3. Enable API Services for Studio testing if needed.
4. Test persistence in a published/private server, not only local Play Solo.

Current saved fields:

- checkpoint
- unlocked difficulty
- endings seen
- trust reputation
- total games

## 7. Asset Workflow

Recommended pipeline:

1. Keep the current marker-only denah for systems testing.
2. Build optimized final models for houses 01-08, pos ronda, empty house, gate, central forest, well, bamboo zone, and lobby structures inside `Workspace.Map`.
3. Preserve interaction attributes, `Workspace.Map.Gameplay` subfolders, and ProximityPrompts from `docs/ARCHITECTURE.md`.
4. Add final audio IDs in `GameConfig.Audio`.
5. Use StreamingEnabled and low-poly distant silhouettes for performance.
6. Keep horror entity non-combat and perception-driven.

## 8. Monetization Hooks

Add monetization after the core loop feels strong:

- cosmetic ronda outfits
- lantern skins
- journal cover skins
- private server boosts
- chapter unlock bundles
- ending gallery cosmetics

Avoid selling direct clue answers because it weakens the investigation loop.

## References

- Roblox Creator Hub: https://create.roblox.com/docs/projects/teleport
- Roblox Creator Hub TeleportOptions: https://create.roblox.com/docs/reference/engine/classes/TeleportOptions/ShouldReserveServer
- Roblox Creator Hub Data Stores: https://create.roblox.com/docs/cloud-services/data-stores
