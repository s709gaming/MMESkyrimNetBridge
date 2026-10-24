# MME Extensions — JUGS Compatibility Patch

## Initial compatibility release

- Added guarded SexLab startup to all 39 JUGS scene fragments.
- Missing or unregistered animations now cancel cleanly instead of passing an empty animation to SexLab.
- Invalid, dead, disabled, deleted, busy, or missing actors are rejected before scene startup.
- Failed SexLab requests now leave useful breadcrumbs under MME Extensions' master Papyrus logging toggle.
- Repaired `JugsPlayerAlias` so it validates the animation and participant array before reading actor entries.
- Repaired the Soulgem Oven milk queue so every active pair can be processed.
- Added duplicate-pair rejection, queue-capacity reporting, invalid-entry cleanup, and safe removal logic.
- Direct Soulgem Oven transfers now begin only after SexLab accepts the associated scene.
- Replaced JUGS' hard-coded MME armor-equip conversion with the public animated Milk Maid API.
- Added smoke-alarm logging for contradictory or corrupt JUGS state.
- JUGS-owned breastfeeding scenes now apply MME Extensions milk, arousal,
  reaction, and optional Skyrim.Net effects after successful scene completion.
- Added exact thread-ownership and role markers so unrelated SexLab scenes
  cannot be mistaken for JUGS scenes.

This patch does not change JUGS dialogue or add Soulgem Oven as a requirement. MME Extensions' existing SexLab breastfeeding integration remains responsible for MME milk transactions.
