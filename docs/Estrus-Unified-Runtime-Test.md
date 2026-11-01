# Agent B Estrus Unified basic runtime test

October 31, 2026, approximately 07:42–07:53 America/Chicago. User explicitly
authorized independent installation and testing of B's Estrus changes before A's
separate test. No source merge or combined release was performed.

## Installation

- Confirmed MO2 instance VortexToMO2, profile Default, Standard SexLab backend.
- Backed up the original installed MME Extensions and profile lists under
  `backups/mo2-before-agent-b-test-20261031-074221` inside B's worktree.
- Used the Windows Computer Use skill and MO2 FOMOD to create the separate
  `MME Extensions - Agent B Test` mod, selecting Standard, roster, existing
  Elsie/JUGS/armor compatibility, and Estrus Unified pregnancy support.
- First install attempt caught a missing compatibility guide. Canceled it,
  corrected the package/build copy step, added a generic archive-source validator,
  and installed successfully on the second attempt.
- Enabled B's test mod and disabled the original through MO2 Agent Control.
  houseCARL and file comparisons confirmed B's direct-call MilkQUEST and DLL win,
  Unified supplies its API, and the retired MMEEstrusUnified helper is absent.

## Live evidence

Launched SKSE through MO2. Game Player MCP supplied vision/control for Continue
and menu handling; SkyLink confirmed connection and safe, unpaused gameplay.
Loaded the existing level-1 Prisoner save and chose Keep History in SkyrimNet's
older-save dialog. Skyrim.Net MCP called the installed quest's read-only query
functions. RPC success alone was not treated as a pregnancy result.

Papyrus traces at 07:50:08 and 07:50:16 show:

| Query | Evidence | Result |
| --- | --- | --- |
| HasEstrusUnified | readiness state=2 | Unified ready |
| Player 00000014, first | type=0, query complete | Original checks continued |
| Player 00000014, repeated | type=0, query complete | Original checks continued |
| Nearby NPC 0004CEF7 | type=0, query complete | Correct actor; original checks continued |

No Estrus API binding errors, Estrus alarms or stack dumps appeared in the
queried session log. Unified's own log reports version 1.1.0, runtime 1.7.104.0,
and original-plugin presence mask 0. Full logs and extracted query lines are in
`build/diagnostics/estrus-runtime-20261031`; these are excluded from the package.

## Restoration and limits

Quit Skyrim with its qqq command after menu input did not switch tabs. No explicit
save, pregnancy creation, conversion, inventory operation or scene trigger was
performed. Re-enabled original MME Extensions and disabled B's test mod. Verified
every original mod file against the backup and restored plugin activation; B's
test mod remains installed but disabled for future testing.

This passes the direct-call API readiness/nonpregnant player+NPC/repeated-query
smoke test on the Standard backend. It does not validate positive pregnancies,
birth/reset, optional-dependency absence, P+/OStim runtime behavior or the combined
A+B build. Those acceptance checks remain outstanding.
