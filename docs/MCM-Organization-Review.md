# MCM organization review

Reviewed and implemented 2026-10-31 in repository source. Installation and in-game visual acceptance remain pending. Debug controls and all existing gameplay settings/defaults are retained. The notes below include the original review and future-only debug safeguards.

## Findings

- The 12-page menu mixes feature ownership, presentation types and development history.
- Animations contains drinking presentation, fullness reactions and the OStim breastfeeding backend. These belong beside their gameplay settings.
- Debug contains the main Extensions enable switch, many legacy diagnostics and accelerated thought testing. These are not one coherent category.
- Armor currently mixes stripping/refits, service checks, equip reactions and stories. Armor Effects mixes normal tuning with manual effect tests. Milk Armor Thoughts includes general bondage reactions and is too narrowly named.
- Misc contains coherent traps/curses settings plus timed armor mechanics and developer reverse-leveling actions; its name hides its purpose.
- General contains body/fullness features that would be easier to find on Body.
- Troubleshoot mixes safe status/repair actions with state-changing developer tests and many internal bus fields.

## Implemented sidebar: 11 pages (Debug retained)

| Page | Responsibility |
|---|---|
| General | Framework/backend status and scoped OStim breastfeeding toggle, main Extensions switch, original MME quick settings, roster/hotkey, global audio controls |
| Milk Drinking | Drinking behavior, milk gain, cravings, auto self-milking, breastfeeding backend/settings and associated drinking animations |
| Body | Original MME body mirrors, visual growth/morphs, weight/speed effects, fullness reactions/animations, breast-bounce reactions |
| Arousal | Dependency status, milk/arousal effects and their reactions |
| Armor & Stripping | Stripping rules/thresholds/protection, refits, service reminders, armor bond duration |
| Armor Effects | Living/parasite and Dwemer gameplay effects, timing/chance/intensity/duration; each feature's feedback remains nearby |
| Armor Reactions | Ordinary/bound thoughts, restraint drinking reactions, equip animations/moans by armor type, repeat-equipped stories |
| Traps & Curses | Armor chest traps, Milk Maid curse traps, exotic milk traps, reverse-leveling gameplay duration/eligibility |
| Skyrim.Net | Integration status, tracking, AI actions and narration configuration |
| Debug | Existing development controls retained for now |
| Troubleshoot | Logging, installation/integration status, useful repair/reload actions and clearly grouped manual tests |

Keep three armor pages: combining all three would produce a long, crowded page. Make their distinction explicit: rules, periodic effects, and presentation/reactions. The order keeps related pages adjacent. General begins with Framework & Integration opposite the master switch/global audio; original MME quick settings follow, then the roster. Original MME body mirrors remain first on Body.

## Concrete moves

- Animations: player/NPC drink toggles and durations -> Milk Drinking, next to their routes. OStim detection/backend/duration -> Milk Drinking / Breastfeeding. Player/NPC half-full/full presentation and durations -> Body / Fullness Reactions. Remove Animations sidebar entry.
- General: capacity reaction enable/notifications and breast-bounce tuning -> Body. Polling enable/interval -> an Advanced subsection beside fullness, with accurate descriptions; preserve scheduler behavior. Keep global audio enable/volume on General; place feature-specific audio controls beside their features where practical.
- Armor: keep strip rules, thresholds, armor protection and refits together. Move all three armor-type equip-reaction groups and repeat-equipped stories to Armor Thoughts & Reactions.
- Misc: rename Traps & Curses. Move lock duration to Armor & Stripping. Move manual player/NPC armor releases to Troubleshoot / Recovery. Move Apply/Remove Reverse Leveling to developer tests, retaining real reverse-leveling duration/eligibility with curses.
- Armor Effects: preserve the Living/Parasite versus Dwemer grouping and existing tier chance/duration pairing. Move Run Effect Check Now actions and diagnostic controls to developer troubleshooting.
- Milk Drinking: move Test Elsie Auto Breastfeeding to developer tests, retaining Elsie detection/settings beside breastfeeding.
- Debug: retain the page, controls and runtime behavior for now. Move only Enable MME Extensions to General because it is a normal user control. Diagnostic consolidation/retirement is deferred.
- Troubleshoot: keep logging and concise status near the top. Separate recovery/reload actions from tests that start scenes, force drinks, spawn items or apply effects. Group detailed bus reports and specialized tests clearly; adding a new visibility toggle is optional and not required for the first organization pass.

## Debug retained; future retirement only

Current scope: do not retire Debug controls, change diagnostic gates or migrate debug settings. The following notes are safeguards for a future retirement pass.

Do not delete MMEDebug.psc. It owns active OStim/SexLab breastfeeding session state, transaction handling and recovery; its name does not mean it is disposable. UpdateDebugLoop delegates to the shared gameplay scheduler.

Legacy controls still have runtime consumers. In particular enableDebugMilkReport arms a five-second report deadline and enableMilkMaidThoughtsDebug arms a fifteen-second thought-test deadline in MMEAlertsController.UpdatePolling. Removing their checkboxes would leave saved test modes running. Retire those modes with an append-only, one-time existing-save migration that disables their keys and refreshes scheduling. Preserve ordinary thoughts, normal feature timers, master logging and smoke alarms. Audit associated visible debug notifications and trace consumers before changing gates.

Retain old JSON key names and compatible script fields/APIs. Do not reset ordinary gameplay choices or delete migration history. Useful targeted diagnostics can remain available internally/under developer tools; they need not occupy a normal gameplay page. Preserve actual failures and event footprints.

## Implementation and verification

1. Inventory each existing option, JSON key, handler, tooltip, dependency flag and destination. Every retained control must have one visible home.
2. Move page builders and controls without changing gameplay defaults, callbacks or dependency guards. Use focused page-drawing functions where useful; no new quest architecture is needed.
3. Preserve all existing debug settings and behavior. Update the internal MCM migration version as needed for page metadata; leave release naming/versioning to the user. Debug retirement migrations are deferred.
4. Recalculate two-column cursor positions, especially General, Body and Armor Effects. Preserve Papyrus/SkyUI page-name capitalization workarounds and option-ID resets. Do not simply paste new controls into fixed positions.
5. Compile affected source scripts and backend variants, rebuild and inspect the package. Check retained-key/handler coverage, duplicate/missing controls and installer options.
6. After separately authorized installation, inspect each page in game for clipping/overlap, disabled dependency states and correct tooltips. Test existing saves and confirm all diagnostic and gameplay choices remain unchanged. Exercise player/NPC feature controls and confirm unrelated settings persist.

## Separate pending installer improvement

Estrus Unified is currently Optional when EstrusUnified.esp is Active and NotUsable otherwise. The proposed change is Recommended when Active, preserving a user choice and existing backend-specific payload selection. It has not been implemented in this review.

## Revised categorization and mastery wording

Capacity/fullness reactions and breast bounce belong on Body. Capacity here is
about the actor being partly/full of milk, not a setting that changes maximum
milk storage. Name its section Milk Fullness Reactions, with separate Player
and NPC animation groups. Keep polling enable/interval in a clearly marked
Advanced subsection without changing their behavior. Group breast-bounce
notifications, sounds, interval, variation and delay together immediately below.
Keep global sound enable/volume on General; feature-specific sound switches
stay with their feature.

Body column plan:
- Left: original MME effects/growth mirrors first, Milk Fullness Reactions,
  player/NPC fullness animations, Breast Bounce Reactions, advanced monitoring.
- Right: maid visual appearance/morphs, then milk weight and movement-speed
  penalties. Recalculate positions and balance the columns during implementation.

Milk Mastery belongs on General under Spells & Progression, near Leveling Speed
and the roster. It controls the global allowance for recruiting/retaining more
Milk Maids, rather than being a body-size setting. Original MME Milklvl0fix()
derives the slot allowance from global mastery (minimum one); AssignSlot and
AssignSlotMaid use that allowance when deciding whether more maids may be added.
Framework array limits remain authoritative. Do not change this calculation.

Implemented label: Milk Mastery (Maid Slots)
Tooltip meaning: Directly sets global MME Milk Mastery. Higher mastery unlocks
more Milk Maid slots, allowing you to have more Milk Maids within MME's limits.
This is global progression, separate from each maid's individual level.

Implementation keeps Debug present and its runtime behavior unchanged. There is no debug retirement migration. All 322 existing option assignments remain exactly once, with one new read-only backend field. Existing settings/action callbacks and EnsureDefaults were checked against the preflight source and are unchanged.

General backend status uses the installed MMESexLabBreastfeedingBackend.GetBackendName facade, including P+ and OStim-only replacements, rather than guessing from plugin presence. The original OStim toggle retains its dependency guard and route callbacks. Its tooltip explicitly says it controls breastfeeding and does not switch the installed backend. Backend installation is still a FOMOD choice. Duration remains under Milk Drinking / Breastfeeding.

Page drawing is split into eleven focused local functions. Legacy page names retain dispatch aliases. Internal MCM metadata version 165 refreshes existing-save registration; no gameplay keys/defaults are renamed or reset. Runtime-capitalized Body/Arousal page names are preserved. No new polling or gameplay instrumentation was introduced.

Repository checks cover unique controls and destination ownership, SkyUI slot positions including tier-loop layouts, callbacks/default preservation and retained Debug controls. Papyrus compilation and package checks remain required; visual fit and live existing-save acceptance require a separately authorized installation.
