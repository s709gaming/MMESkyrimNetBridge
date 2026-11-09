# Skyrim.Net player breastfeeding confirmation

Both Skyrim.Net breastfeeding actions normalize source/drinker roles into MMESkyrimNetVoiceControls.StartBreastfeedingMilkShare. Before either SexLab/P+ or OStim dispatch, the player receives a vanilla Skyrim MessageBox with Yes/No when participating. NPC-only requests do not prompt. Existing dialogue, Elsie and debug entry points are unchanged.

Message records: MME_BF_PlayerDrinksConfirm (0008D1) and MME_BF_PlayerProvidesConfirm (0008D2), MMEAlert.esp. Button zero is Yes; button one is No. Static role-specific questions avoid unverified actor-name substitution. No framework addon, UIExtensions or custom browser interface dependency.

Only explicit Yes proceeds. Missing messages/UI failure stop safely with a once-per-load alarm. One atomic load-scoped gate prevents stacked prompts; refusal imposes a separate 15-second player request backoff without changing the successful-scene cooldown. Actors, master/action settings, cooldown and backend availability are checked again after Yes. Old-load answers are discarded. No scene locks, animation, stripping or milk rewards begin while awaiting approval. Backend commit guards remain authoritative.

Routine consent footprints use [MME BF Consent] and existing master Papyrus logging. Expected No, invalid actor, busy state, missing optional backend, duplicate pending request and refusal backoff are not alarms. UI failure/missing required records are genuine failures.

Reproduce record authoring using tools/breastfeeding-confirmation-builder with an unmodified input and separate output. It verifies original records and masters, adds exactly two records, and checks buttons. Source changes ship only with matching PEX and updated standard/OStim-only/localized plugin outputs.

Automated tests execute the actual gate with mocked UI/engine boundaries. Live acceptance remains necessary for keyboard/controller navigation, Yes/No behavior in both frameworks and directions, repeated requests, save/load and cleanup. No deployment is implied.
