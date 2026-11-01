# Current MME actor status in Skyrim.Net

Actor prompts now report current milk amount, capacity, percentage and explicit
empty/below-half/half-full/full/over-capacity state. Native Skyrim.Net
`papyrus_util` reads MME's original actor storage when the template renders.
Unknown or invalid values are never treated as known zero.

The focused `MMEActorPromptState` callback validates the actor and feature settings,
and supplies current body-armor classification and confirmed leak facts. It reuses
MME's configured armor arrays and the custom registry through a quiet lookup.
It does not scan nearby actors, initialize MME storage, change equipment, produce
milk or invoke the LLM. It only writes its own diagnostic deduplication keys.

Armor wording identifies living, parasite, milking and Dwemer armor, with the item
name. A hidden Dwemer attachment is not described as a full-body suit. This covers
body armor, not an audit of every worn item. Ordinary armor does not mean naked.

Leak activity is independent of fullness. Only an equipped tracked leak effect
is reported as active; a request or threshold alone is not proof. An absent tracker
or unloaded actor reports unknown. No tracked effect is not a claim that every
third-party shader is absent. Sustained-low behavior and clothing/scene protections
remain governed by the optional Milk Leaks integration.

## Settings and migration

The former nearby milk and armor status toggles now control their actor-prompt
sections. Existing keys and explicit user choices are retained. The old interval
control is retired; its saved value and old milestone TTL key are preserved but
unused. MCM metadata version 171 refreshes labels without resetting these choices.
Master MME, Skyrim.Net availability and the bridge enable setting still gate output.

Periodic `milk_statuses_player`, `nearby_milk_armor_status_player`, and separate
half/full milestone state events are no longer published. Their old public Papyrus
functions remain compatible no-ops. Already active temporary entries expire normally;
older persistent history is not deleted. Lore and meaningful interaction events remain.

Shared gameplay scans, threshold reactions/sounds, auto-milking, body effects,
Thoughts and leak lifecycle scheduling remain active. Fullness narration rechecks
milk state before submission. Existing custom Thought prose and historical memories
are not rewritten by this migration; the current-state prompt explicitly identifies
old descriptions as past experiences.

## Diagnostics and verification

`[MME Actor Prompt]` registration results and changed actor snapshots require master
Papyrus Logging. Repeated unchanged render detail requires master plus verbose.
Invalid stored state and registration failures emit deduplicated smoke alarms
independently. Routine prompt rendering does not create HUD notifications.

The package build checks the actual Inja parser/render against empty/partial/full,
threshold edges, over-capacity, missing values, disabled settings, separate actors,
all armor wordings and independent leak facts, using mocked decorator data. Source
contracts verify event retirement and unchanged gameplay entry points. This is not
a live Skyrim.Net profile/cache acceptance test. Both backend variants and affected
scripts must compile and their source/PEX pairs must match the archive.

Live acceptance still requires speaker/target and NPC prompt capture, callback
freshness/timeout behavior, full-to-empty, armor unequip and Dwemer attachment/suit,
leak onset/end/tracker absence, reload and optional dependencies. The prior read-only
beta28 probe established native float reads for a player; this does not prove all
NPC or full-profile cases. No new native DLL or hard Skyrim.Net requirement is added.
