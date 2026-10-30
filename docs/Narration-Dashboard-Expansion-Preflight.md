# Full narration dashboard expansion: pre-flight

Date: 2026-10-30. Scope: research and implementation plan only.
This follows the general-lore proof; it does not implement or deploy the expansion.

## Decision and verified baseline

Expand the existing second **Narration & Lore** tab. Keep the Milk Maids roster
as tab one and reuse the native worker, external sparse overrides, backup,
revision checks, hexadecimal UTF-8 transport, and session/view validation.
The scrolling dashboard is the next delivery; localhost access remains a later
adapter, not a prerequisite for editing the rest in-game.

The user's live test is verified in Papyrus.0.log on 2026-10-30: load 07:07:51,
save 07:08:26, reload 07:08:28, reset 07:08:30, save 07:08:37, response delivery
for all five requests, then close/focus cleanup at 07:08:40. The personal file
contains the final punctuation edit and its backup contains the preceding reset
state. No editor failure result was logged. This establishes basic UI-to-worker
save/reload/reset and disk persistence in that session.

It does not establish restart persistence in the game, actual Skyrim.Net prompt
injection, NPC/player coverage, Unicode/case-only presentation, maximum message
size, conflict UI, paused completion, or master-toggle-off behavior. The test had
no registered Milk Maids in its roster. A crash at 07:08:43 matches an earlier
SkyrimSE.exe+0199FC3 / invalid-read-0x1F8 signature; cause is not established.
Track the crash separately and do not label the session wholly crash-free or
attribute the crash to this editor without evidence.

Reference artifacts: `Narration-Editor-Proof.md` describes the shipped proof;
`Narration-Editor-Persistence-Preflight.md` remains the broader original plan.
`Narration-Dashboard-Inventory.json` is this pass's source-derived inventory,
including every canonical ID, pool source path, current count, and reader.
Pool IDs in that inventory are proposed IDs, not implemented API guarantees.

## What will be editable

### Canonical Skyrim.Net entries

The current schema has 74 entries across 12 files. One is already exposed by the
proof, leaving 73 additional canonical entries. Some are writing instructions,
wrappers or fallback descriptions rather than standalone spoken lines; label
their purpose so players know where their words appear.

| Section / canonical file | Entries | Includes |
|---|---:|---|
| Lore | 2 | General world lore already tested; actor-specific Milk Maid lore |
| Common | 1 | Private player self-comment writing instructions |
| MilkDrinking | 11 | NPC/player drinking, chest milk, restrained variants and drink context |
| Breastfeeding | 1 | Prompt guidance with actor and source/drinker role |
| MilkMaidCreation | 5 | Normal/forced creation, curse/chest-curse framing and creation context |
| Milking | 2 | Start and completion context messages |
| Fullness | 13 | Half/full, restraints, capacity milestones, status and nearby summaries |
| MilkCravings | 1 | AI framing around the selected craving |
| Thoughts | 2 | Ordinary and bound thought narration framing |
| Armor | 8 | Equip/strip framing and nearby equipment status |
| TentacleArmor | 5 | Injection/effect instructions and confirmed milk/arousal outcomes |
| DwemerArmor | 23 | Effects, suit/attachment profiles, first/re-equip, milking events and fallbacks |

Use `tools/narration-schema.json` as the canonical token contract. Generate the
runtime/UI catalog from it and the authored JSON rather than duplicating the
route list in C++, Papyrus and JavaScript. Keep generated compiled defaults.
Do not alter the prompt's conditional injection logic to expose more text.

### Active story, thought and notification pools

An additional 57 pools contain 269 shipped variants across 12 source files.
Together with canonical entries, this is **131 proposed editor cards**. A card
may contain several editable variants; 131 is not a count of individual lines.

| File | Pools | Variants | Main readers / special handling |
|---|---:|---:|---|
| Thoughts.json | 9 | 53 | MMEThoughts; fullness/armor and bound selection |
| MilkCravings.json | 2 | 10 | MMEMilkCravings; craving versus give-in wording |
| ArmorIntroductionStories.json | 11 | 27 | MMEArmorIntroduction -> MMEStoryPopup; first/repeat/trap typed lists |
| DwemerArmorStories.json | 2 | 2 | MMEDwemerArmor -> MMEStoryPopup; start/end typed lists |
| ForcedMilkMaidConversion.json | 2 | 10 | MMENewMilkMaid/MMEMilkCurse -> MMETextPool; conversion and chest curse |
| ArmorCheckReminders.json | 7 | 36 | MMEServiceArmorReminder; equipment state and separate reaction pool |
| ArousalEffects.json | 6 | 30 | MMEArousalEffects; sex and low/medium/high tier |
| BreastBounceNotifications.json | 3 | 15 | MMEBreastBounceEffects and MMEAlertsController movement route |
| DwemerEffectNotifications.json | 1 | 5 | MMEDwemerEffects; factual outcome handling remains code-owned |
| Injection.json | 1 | 5 | MMETentacleEffects; tentacle injection flavor |
| NonMilkmaidDrinkNotifications.json | 12 | 72 | MMENPCDrinkDialogue; drink and breastfeeding outcome/sex variants |
| TimedArmorNotifications.json | 1 | 4 | MMETimedArmorLock; resisted removal typed list |

The consumer list includes indirect shared-reader paths. Runtime wiring must
verify each actual caller and dynamically selected key, not just literal strings.
The public `MMEExtensionsAPI.ShowRandomStoryPopup` accepts arbitrary files: only
cataloged first-party pools get overrides; third-party/public callers retain their
existing behavior. Do not scan or rewrite arbitrary files supplied through that API.

### Exclusions and aliases

- TentacleEffectNarration, DwemerEffectNarration, DwemerSuitNarration,
  DwemerAttachmentNarration and the old text fields in SkyrimNet.json are legacy
  migration sources for the canonical entries. Do not create duplicate editor
  controls with competing precedence.
- No current reader was found for ForcedMilkMaidConversion.openingStory or
  closingStory. Keep them out of the active catalog unless a reader is established.
- Exclude Settings.json, cooldowns/chances/TTLs, initialized/enabled flags, armor
  form/name registries, numeric arousal data, actor arrays, action YAML and raw
  prompt logic. This is a text editor, not a new gameplay configuration system.
- Existing route IDs and `Lore.milk_lore` personal files must remain compatible.
  Numeric schema versions describe file formats, not a mod release version.

## UI plan: scroll and drag

Keep the current visual palette and introduce a bounded editor viewport beneath
the tabs. The entries scroll while search/category controls and the Save footer
stay visible. Show a real vertical scrollbar with a wide, draggable thumb; support
wheel, trackpad, Page Up/Down and keyboard navigation. Optional up/down buttons
scroll one viewport. These buttons move the list; they do not replace the scrollbar.
Do not assign the host's reserved PageUp toggle key to a competing page shortcut.

Use collapsible categories, search, and Modified Only. Group AI narration separately
from source thoughts, stories and notifications within the same tab. Explain that
editing a source thought changes the text used inside a narration wrapper; editing
the wrapper changes framing. Clearly identify internal/fallback templates.

Each card shows a friendly name, brief purpose, stable ID in secondary details,
source badge (personal/base/fallback), required tokens and validation state.
Pools show separately editable variants, Add Variant, Remove and keyboard-accessible
Move Up/Down. Optional drag-reordering must have the same accessible alternatives
and must not interfere with selecting text or dragging the main scrollbar.
Preserve duplicate variants and their order; duplicates can intentionally weight
random selection. Reset Entry stages removal of the personal override.

Save Changes commits all dirty entries as one validated transaction. Display the
changed-entry count and document-size budget. Reload/Discard/Reset All use in-page
confirmations. Reset All requires explicit scope and keeps a backup. Existing
immediate proof reset behavior can migrate to staged reset, with clear button/status
wording and a regression test. Never silently persist a partial multi-entry save.

Keep drafts when switching tabs, filtering, collapsing sections or refreshing the
roster. Key draft state by stable entry ID, independent of visible DOM nodes.
Preserve focus, caret and scroll position on responses. The roster must never
rerender the editor. Dirty-close confirmation, host-forced close, hibernation,
game exit and page reload need separate tests. Add optional recovery drafts outside
the active overrides file before claiming drafts survive page destruction; recovery
requires a user choice and must not automatically activate text.

Do not use browser-native confirm dialogs. Retain explicit in-page confirmation,
Escape capture, and the host's ability to force exit. Implement modal focus handling
and distinguish normal close from forced host exit. Preview substitutes sample
facts locally; it never scans actors, converts a maid, consumes an item or calls an LLM.

## Service changes required beyond the proof

The current native store has one hard-coded ID, a scalar-only validator and a
single optional string cache. It must be generalized; adding textareas alone
will not make the remaining entries work.

1. Generate a catalog containing IDs, source paths, source format, kind, feature,
   labels, token/blank/selection contracts and fallback ownership. Distinguish
   canonical narration arrays from ordinary pools and legacy `stringList` pools.
2. Publish an immutable map of validated personal overrides. Gameplay reads only
   memory and must not take the transaction I/O lock. Keep existing base readers
   and compiled/hard-coded fallbacks behind a missing personal override.
3. Generalize scalar and pool access behind common facades. Preserve the current
   Utility.RandomInt call and selection/filtering rules. Verify the supported VM
   array length before choosing typed array returns; use bounded snapshots/encoded
   transport where needed, never silently truncate a pool to the VM limit.
4. Pin one snapshot for a pool read so a concurrent Save cannot mix count and
   entries from different revisions. Loading a profile cannot expose a half-updated
   set of scalar/pool values. No per-entry disk reads in gameplay.
5. Generalize Save/Reset to a list of changes/removals, validate the full proposed
   document, preserve unknown IDs/metadata, then commit/publish once. Include expected
   personal and base/catalog revisions. Re-read under the profile lock and reject
   stale writers; do not silently merge conflicting edits.
6. Keep current external profile path, backup and epoch/session rules. Preserve
   malformed/future files and last-good memory; show actionable errors. Explicit
   Save must remain independent of Skyrim/JsonUtil game-save writeback.
7. Rework Import Legacy to create sparse personal overrides, with a preview of
   conflicts and migration aliases. Capture existing base-file customizations only
   on explicit request, using native exact comparison and preserving original files.

The authored canonical files total 32,530 bytes and these additional pool files
total 29,555 bytes in the inspected tree. The largest individual template is 988
UTF-8 bytes; the largest additional serialized pool is about 2 KiB. These are
source measurements, not measured bridge limits. A complete response containing
metadata, defaults and overrides would be substantially larger, doubled by hex.

Use metadata-first catalog paging and lazy per-category/per-entry loads. Do not
send all 131 entries, defaults and drafts in one ModEvent or Magelight Call.
Measure the installed host/VM event boundary with Unicode and large edited pools;
choose conservative frame/chunk limits with request IDs, ordering, acknowledgments,
timeouts and stale-session cancellation. Stage large Save payloads in a bounded
native transaction and commit only after full validation; lost chunks change no
active state. No polling from Papyrus or per-frame traffic.

Retain the proof's 8 KiB per-template and 256 KiB document caps initially, display
limits in the UI, and test aggregate limits. Increase them only after payload,
memory and recovery tests justify it. A large pool may exceed a message even when
every variant is valid. Repeated requests must have distinct IDs and a known
outcome before retrying a possibly committed save.

## Consumer behavior and validation

Canonical entries already have exact required/allowed tokens and aliases. Preserve
the single-pass renderer: actor names and inserted context containing braces must
not be interpreted again. Keep the `milkmaid_lore` actor placeholder and all role,
confirmed outcome and context placeholders in other routes.

The inventory's `tokensObserved` for extra pools is evidence, not a derived required-
token rule. Record the actual consumer renderer before defining each contract.
Examples: stories/cravings use ActorName, most effect/thought pools use actor, and
drink pools use actor/milk. Some factual anchors are constructed separately in code;
do not let an editable flavor entry remove an engine-confirmed outcome.

Preserve important differences: MMETextPool selects among nonblank entries and
supports ordinary/typed storage; MMEStoryPopup randomly selects a typed-list entry
and falls back if the selected entry is blank; MMEThoughts has its own failure/skip
behavior; timed armor has a dedicated built-in fallback. Do not accidentally change
random weighting by filtering a different set of entries or deduplicating strings.
Before release, define a non-destructive policy for historical blank entries,
unsupported tokens and malformed manual overrides, and test each reader's old
behavior with personal overrides absent. Do not rewrite the user's base files as
a normalization step.

No new MilkQUEST operations are planned. Keep actor selection, slots, levels,
capacity, conversion, milk/inventory changes, timers, rolls, animation/scene guards
and cleanup in their current gameplay routes. Any unexpected MilkQUEST integration
requires original-source signature and parallel-array verification first.

## Papyrus footprints under the master toggle

Use `MMELog.MasterDiagnostic` for all new routine traces with prefix
`[MME Narration Editor]`. It checks `enablePapyrusTrace` and requires no verbose
toggle. Do not route ordinary boundaries through `MMELog.Status` or direct
Debug.Trace. Keep existing subsystem prefixes for gameplay outcomes where clearer.

| Boundary | Sparse footprint fields |
|---|---|
| Open/load | operation, profile, session/epoch, catalog revision, counts, load result |
| Edit transaction received | request ID, operation, changed count, expected revision; actor=N/A |
| Validation | accepted/rejected count, entry ID and concrete reason; no template contents |
| Save/reset/import/export | persisted revision, applied revision, result, count, backup/readback result |
| Actual text dispatch | entry/pool ID, source=personal/base/fallback, chosen index/count, selected actor and branch |
| Important skip | disabled/cooldown/no target/optional host absent/stale request/conflict/cancel; concrete reason |
| Cleanup | view/focus released, requests canceled, recovery-draft status, stale completion discarded |

For periodic status/thought/notification paths, trace source changes once per
entry/actor/config revision or use an explicit rate limit. Do not trace every
poll, keystroke, rendered card or individual chunk. Keep worker details aggregated
into one transaction summary. No full prose, prompt, preset payload or future auth
token in logs. No diagnostic text in normal player notifications.

Genuine disk/readback failures, corrupt active files, broken expected catalog/native
prerequisites and impossible states use the existing `MMELog.Alarm` exception.
Deduplicate by subsystem/entry/reason/revision, not request ID; rate-limit retries
where appropriate. Disabled features, active cooldowns, no eligible target, optional
dependency absence, user validation failures and revision conflicts are not alarms.

Mandatory logging tests: master OFF/verbose OFF and master OFF/verbose ON produce
no new routine editor/resolver traces; master ON/verbose OFF produces all useful
boundaries; master ON/verbose ON may add bounded detail only. Inject a genuine
failure to verify alarm deduplication and confirm ordinary skips remain quiet.

## Regression plan

Capture a baseline of route calls, argument order, actor roles, default text,
RandomInt call sites and state writes before changing readers. With no personal
overrides, all relevant results must retain those semantics. Do not replace actual
behavior tests with assertions that merely repeat new implementation code.

| Area | Required acceptance cases |
|---|---|
| Lore and Common | general/maid-specific gating, valid actor, recent drinker, private player speaker, actual generated prompt |
| Drinking/breastfeeding | player and NPC independently, male/female, ordinary/confirmed maid, restrained/chest, source/drinker roles, milk-only/arousal-only/both outcomes |
| Creation/curses | normal/forced/chest branches, repeated use, no accidental conversion, correct actor, confirmed outcomes and cleanup |
| Milking/fullness | start/end, half/full/milestones, restraints, near-zero/overcapacity, periodic nearby summaries and cooldowns |
| Thoughts/cravings | all armor/fullness pools, bound routes, craving/give-in, random variants and existing timing |
| Armor/Dwemer/tentacle | first/repeat/trap, suit/attachment, equip/strip, start/end, confirmed effect variants and fallback profiles |
| Story/HUD pools | every catalog key reachable, correct presentation channel, tokens/anchors, typed versus ordinary arrays, blank/invalid fallback behavior |
| Gameplay guards | combat, busy animation, scenes, movement lock, feature/master disabled; state writes and cleanup unchanged |
| Optional dependencies | Magelight and Skyrim.Net present/absent; applicable animation backend and optional armor/integration absent; core has no new optional script imports/masters |
| UI/roster | scrollbar drag, wheel/keyboard, collapsed/search/modified states, text selection, modal/Escape, dirty drafts, long Unicode, roster actions/arousal and stale row rejection |
| Transactions | multi-entry all-or-nothing save, failed readback/permission/size limit, interrupted temp write, two writers, external changes, queue/chunk limits, close/load during save |
| Persistence | new/existing saves, restart, old-save load, mod update/replacement, personal-file untouched, base update visible after Reset, unknown/future IDs preserved |
| Logging | master/verbose matrix, wrong-actor and stale-state detection, no stack dumps or repeated routine noise, true-failure alarm dedup |

For variant selection, test controlled random indices including first/last and
duplicate entries, rather than relying on statistical randomness. Test Unicode and
case-only text at disk, editor, renderer and actual Skyrim.Net prompt boundaries.
Do not infer the final prompt from the editor preview. Start with the known-tested
general lore entry and confirm it still survives Save/Reload/Reset after expansion.

Every canonical entry and each additional pool needs catalog/validator coverage;
every changed reader needs default and personal-override behavior coverage. Use
representative runtime cases for each distinct renderer/selection path, with separate
player/NPC tests and all material branch combinations. Compile every affected PSC
and its backend variants. Rebuild universal and VR native targets; run existing
narration, text-pool, roster/page, logging, creation/curse and backend suites.

Rebuild `MME Extensions.zip` and compare current source/PEX/DLL/page/catalog hashes.
Inspect FOMOD installation options, legacy migration assets, MO2/Vortex-compatible
paths, licenses and exclusion of tests/logs/caches/personal data. Leave README and
release version numbers unchanged. No installation or profile mutation is authorized
by this planning pass. In-game tests require an authorized matching deployment.

## Delivery sequence and stop conditions

1. **Catalog and transport.** Generate canonical metadata; record pool contracts;
   generalize the store; implement paging/chunking and multi-entry transactions.
   Verify existing personal lore files, exact bytes, fallback precedence and queue
   behavior. Stop if large payloads cannot be delivered reliably; solve transport
   before populating the dashboard.
2. **Scrolling dashboard and 74 canonical entries.** Add the remaining 73 entries
   and pool editors through MMENarrationText, category/search controls, sticky Save
   footer and draft retention. Test actual player/NPC prompt use and preserve the
   already-tested general lore route. This is the first expanded implementation.
3. **57 additional pools, in reader groups.** Start thoughts/cravings, then shared
   story/conversion readers, then effect/drink/reminder/timed pools and the movement
   route. Integrate every direct reader and prove original behavior without overrides
   before moving to the next group. Do not claim all narrations after stage 2 alone.
4. **Migration and portable presets.** Integrate explicit legacy capture, Export,
   Import preview/merge/replace, backups and recovery drafts using the same catalog
   and transaction service. Preserve base and unknown data.
5. **Optional localhost.** Reuse the editor model with a separate transport after
   in-game acceptance. Follow the original pre-flight's loopback/auth/origin/lifecycle
   requirements; do not modify Skyrim.Net's dashboard or make a web server mandatory.

Acceptance gates are evidence-based: stop expansion on wrong actor/state changes,
silent partial persistence, broken defaults, repeated log noise, lost drafts, native
errors or unbounded message/queue behavior. Fix the underlying layer and retest its
affected paths before broadening scope. The earlier crash signature needs a separate
diagnosis before claiming stable shutdown; do not use a successful save test to close it.
