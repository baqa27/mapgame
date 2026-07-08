# Roblox UI Skill — "Jimpitan dan Malam Ronda"

Use this whenever building or editing any `ScreenGui`, `Frame`, or UI Controller `ModuleScript`
for the Main Game place. This is a practical build standard, not a behavior policy — it exists so
every UI screen in this game is consistent, responsive, and doesn't leak gameplay logic to the
client.

---

## 1. Instance & folder conventions

- One `ScreenGui` per feature area, named `<Feature>Gui` — e.g. `HUDGui`, `JournalGui`,
  `DialogueGui`, `PuzzleGui`, `CheckpointGui`, `AccusationGui`, `HorrorGui`, `EndingGui`.
- Inside each, a root `Frame` named `Root`. Name children by **role**, not by instance type:
  `Title`, `CloseButton`, `ChoiceList` — never `TextLabel1`, `Frame2`.
- One Controller `ModuleScript` per Gui in `StarterPlayerScripts.GameClient.Controllers`
  (`<Feature>Controller`). The Controller owns show/hide state and Remote listening; the Gui
  itself is declarative — build it once, mutate it through the Controller, don't rebuild it from
  scratch every update.

---

## 2. Responsive layout rules

- Root frames use `AnchorPoint` + `Position`/`Size` in **Scale**, not Offset — except small fixed
  icons, which use Offset + `UIAspectRatioConstraint`.
- Test every screen at 16:9 desktop **and** 9:16 mobile portrait. Use `TextScaled = true` with a
  `UITextSizeConstraint` (min/max bounds) so text never overflows or disappears on small screens.
- Respect `GuiInset` (top bar) unless a full-bleed overlay is intentional (e.g. `HorrorGui`).
- Full-screen overlays (`HorrorGui`, `EndingGui`) must **not** set `Modal = true` unless input
  should genuinely be blocked. `HorrorGui` in particular must never intercept clicks or hide a
  `ProximityPrompt` underneath it.

---

## 3. Visual style guide (game-specific)

- Palette: warm lantern orange for HUD/safe accents, cold moonlight blue-grey for panel
  backgrounds, muted red reserved for the "feared" trust state or genuine danger cues. Avoid
  saturated neon — the horror here is psychological, not arcade (per `DESIGN_BRIEF.md`).
- Typography: a slightly rustic/hand-written-style font for narrative and dialogue text (Pak RT,
  journal entries); a clean, highly legible sans for HUD numbers/labels.
- Trust icon must differ by **shape**, not only color (e.g. lit lantern → dim lantern → cracked
  lantern → shattered lantern), since trust is a core mechanic and should stay readable for
  colorblind players.
- Avoid loud "game-y" pop-in animation on horror-adjacent UI. Subtlety over jump-scare chrome —
  the entity "observes, manipulates, and pressures," it does not jump-scare through UI (per
  `DESIGN_BRIEF.md`'s horror rules).

---

## 4. Motion & feedback

- Standard show/hide: `TweenService`, `Enum.EasingStyle.Quad`, `Enum.EasingDirection.Out`,
  0.2–0.35s. Dialogue/journal: slide + fade. `HorrorGui`: slower fade-in (unease), quick fade-out.
- Bind the kentongan sound cue to major event notifications (checkpoint save, accusation confirm,
  ending reveal) — this was an accepted revision in `GAME LAVEL.md`'s review, keep it consistent.
- Trust state changes get a qualitative pulse/glow on the icon only — **never a numeric popup**
  like "+5 trust." That breaks the "no detailed numeric trust" design decision explicitly recorded
  in the mechanics doc.

---

## 5. Performance

- For repeated list items (journal clues, dialogue choices), clone one template `Frame` per entry
  and clear/destroy on refresh — don't hand-place duplicates, don't leak old clones.
- Keep `HorrorGui` and `EndingGui` set `Enabled = false` when inactive rather than only
  transparent, so idle screens cost nothing.
- Drive all UI state from `RemoteEvent` callbacks (or a small `Signal` module), never from
  per-frame `RenderStepped` polling.

---

## 6. Client/server discipline (UI-specific)

- A UI element never computes a gameplay outcome (e.g. whether a clue is correct) — it only
  displays what the server already decided, and sends *intent* Remotes back.
- "Locked" dialogue/puzzle options render using the `locked`/`lockedReason` fields the server
  already sent — never infer lock state client-side.

---

## 7. Pre-ship checklist (run per screen)

- [ ] Works at 16:9 desktop and 9:16 mobile portrait without clipping/overflow
- [ ] Never blocks a `ProximityPrompt` unless genuinely meant to be modal
- [ ] All dynamic text pulled from `NarrativeData`/Remote payload, not hardcoded in the script
- [ ] Show/hide driven by Remote/Signal, not per-frame polling
- [ ] Follows the palette/typography/icon rules in §3
- [ ] No raw numeric trust or puzzle answer is ever rendered client-side
