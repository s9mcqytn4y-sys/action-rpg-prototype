# Interaction System v0

## Overview
- Interactable objects are tagged with `Interactable` via CollectionService (server/studio owned).
- Client scans nearby tagged objects, shows prompt, and sends request on `E`.
- Server validates distance, tag, cooldown, and line-of-sight before success.

## Tags
- `Interactable` (see `src/Shared/Tags.luau`).

## Config
- `src/Shared/Config/InteractionConfig.luau`
  - Radius, tick rate, cooldown, prompt text, LOS checks, SFX id.

## Flow
1) Client scans tagged instances every tick (`TickRateSec`).
2) Best target within `Radius` and LOS shows prompt.
3) On `E`, client fires `ReplicatedStorage/Remotes/InteractRequest`.
4) Server validates (tag, distance, LOS, cooldown), then acknowledges success.
5) Client plays SFX only on server success.

## Anti-Exploit Rules
- Server authoritative: client request is only a hint.
- Server re-validates tag, range, and LOS.
- Cooldown enforced server-side.

## Studio Test Checklist
1) Ensure a Part `Interact_Pedestal` has Tag `Interactable` and is at (10, 0.5, 10).
2) Play (F5) and approach the pedestal; prompt appears, then disappears when out of range.
3) Press `E` near the target: server accepts, client plays SFX 6895079853.
4) Try behind a wall: interaction is rejected.
5) Respawn multiple times: prompt UI does not duplicate, no double interactions.
