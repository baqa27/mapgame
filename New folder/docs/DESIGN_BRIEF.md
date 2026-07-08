# Design Brief

This implementation follows the supplied mechanics and narrative PDFs.

## Core Fantasy

Players are night patrol officers in Desa Bojongsari. Their normal jimpitan route becomes an investigation when money disappears and social trust collapses. Horror is psychological and cultural, not combat-driven.

## Primary Loop

1. Explore the village.
2. Collect jimpitan.
3. Inspect missing money or strange objects.
4. Talk to warga.
5. Solve observation puzzles.
6. Compare clue routes.
7. Make a decision.
8. Trust changes.
9. A new phase of the night begins.

## Secondary Loops

- Investigation: collect, compare, contradict, conclude.
- Horror: whispers, shadows, flickering lights, hallucination clues.
- Social Trust: dialogue tone, clue access, ending risk.
- Exploration: village route, hidden ritual area, sawah, gang, rumah kosong.
- Progression: Easy social case, Medium ambiguity, Hard full truth.

## Trust States

The server keeps numeric trust internally, but players only see:

- trusted
- neutral
- suspicious
- feared

Trust affects dialogue access, clue hints, NPC tone, and failure recovery.

## Ending Rules

Easy:

- Human culprit solved.

Medium:

- Human route.
- Pesugihan route.

Hard:

- Full Truth Ending.
- Partial Truth Ending.
- Failed Investigation return to checkpoint.

## Horror Rules

The game should not become a chase/combat game. Horror events should produce uncertainty:

- Was the clue real?
- Did an NPC lie?
- Did the player misread the environment?
- Is the village reacting to truth or fear?

The entity observes, manipulates, and pressures. It does not become a shooter enemy.
