# Milk Maid roster appearance preflight

Scope: presentation only; implemented on 2026-10-27. Repository inspected and updated, not installed MO2 assets. Baseline and final roster suite: 5 tests passed.

## Implementation

- Preserve the warm dark panel and gold accents. Widen the milk bar where space permits; use a cream-white fill, dark track, and thin border.
- Preserve authoritative percent input and numeric milk/capacity/percentage. Clamp only visual width to 0-100: 50 percent means half a bar; overflow remains visible numerically. Unknown capacity remains N/A.
- Use milk glass for Give Milk / player Drink, cow face for Self Milk, circular arrow for Refresh, and multiplication cross for Close. Preserve accessible action names with aria-label and visible keyboard focus.
- Add in-page tooltips on hover and keyboard focus. Explain Give versus Drink, Milk Maid Lactacid priority, ordinary milk cheat fallback, and Self Milk. Use supplied selfReason for disabled self actions; do not invent backend failure reasons.
- Make disabled action explanations reachable through a focusable wrapper without enabling the action. Tooltips must stay inside the panel, avoid clipping by the scroll container, and disappear on close/refresh.
- Preserve session/revision tokens, captured actor authority, callback names and payloads, duplicate-click suppression, focus cleanup, Escape and native hotkey toggle.

## Diagnostics

Existing MMEMaidRosterUI uses master-gated [MME Maid Roster UI] traces for open, refresh, action entry/actor, eligibility skips, dispatch/results, confirmation and cleanup. Existing page errors report through mmeRosterError and backend alarms. Retain these unchanged. CSS/hover/focus changes need no new gameplay Papyrus route and no polling/hover log spam.

If implementation unexpectedly requires PSC changes, inspect Papyrus reference first, compile all affected scripts, verify source/PEX parity and add gated boundary traces as appropriate. Do not change gameplay APIs merely to style this page.

## Regression and packaging

- Extend actual-page JavaScript checks for 0, 50, 100, overflow, negative and unknown fullness; retain real numeric overflow.
- Check player Drink, NPC Give Milk, Self Milk, unavailable targets, disabled reason, Unicode names as text, stale/session data and duplicate clicks.
- Check keyboard focus/tooltips, Refresh, Close, Escape, hotkey toggle and repeated open/close in Magelight; inspect narrow layout and long actor names/reasons.
- Re-run roster tests and update the page SHA256 in BuildManifest without changing script/plugin hashes or claiming runtime validation prematurely.
- Rebuild MME Extensions.zip and verify HTML/manifest parity, optional component placement, XML compatibility, and no diagnostic artifacts. No README edit or deployment.
- Live smoke test after user installation: player and NPC actions; logging on gives the existing action footprints, logging off suppresses routine traces; no new Papyrus errors or repeat noise.

## Risks / unresolved live checks

- Segoe emoji availability does not prove embedded Magelight renders cow/milk glyphs correctly. Use an explicit emoji-capable font fallback and verify in game. Do not redistribute Windows fonts. If glyphs fail, use a small locally bundled icon alternative instead of shipping unreadable buttons.
- Native title tooltips are insufficient in an embedded UI; use page-rendered tooltips with accessible descriptions.
- Existing tooltip text must accurately describe inventory selection and cheat fallback, without promising free Lactacid.
- Read-only UI values are snapshots, not a continuously polling meter. Refresh/open updates them; this change does not add live polling.

Verdict: low risk, frontend-only implementation is ready. Actual glyph appearance and in-game focus behavior remain runtime acceptance checks.

## Implementation verification

Implemented white proportional bars, milk/cow action icons, Refresh/Close symbols, accessible action names, page-rendered hover/focus tooltips and focusable disabled-action explanations. Existing action payloads, snapshot/session checks and native hotkey routing are unchanged. No PSC, PEX, plugin or gameplay API changes were necessary; existing master-gated action traces and error reporting remain intact.

Extended actual-page JavaScript regression checks cover 0/23/50/67/100/150 percent, negative and unknown values, numeric overflow, icon labels, disabled keyboard explanations, tooltip cleanup and prior callback/duplicate-click contracts. Five roster tests pass. Archive CRC, page/manifest parity, 508 entries, absence of diagnostic artifacts, and normal/Vortex-transformed FOMOD XML parsing pass. MME Extensions.zip was rebuilt by replacing only the two changed component files in the previously verified archive, preserving all other archive content. No installation performed. Magelight glyph appearance and real in-game focus/hotkey smoke testing remain pending user installation.
