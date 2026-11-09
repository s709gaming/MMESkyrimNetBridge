# Milk Maid world knowledge

General lore ships as one global semantic `KNOWLEDGE` entry in
`SkyrimNet25/s709gaming.mme-extensions/knowledge/Skyrim_Milk_Maid_Lore.sknpack`.
The package installs it under `SKSE/Plugins/SkyrimNet/external/s709gaming.mme-extensions/knowledge/`.
Its stable pack path and entry key must remain unchanged when updating the lore.

Edit **Skyrim Milk Maid Lore** in Skyrim.Net's **World Knowledge** dashboard while
playing. Skyrim.Net supports a playthrough-only personal copy or an overlay edit
for all playthroughs. Reverting restores the supplied pack. MME Extensions does
not write to Skyrim.Net's library, overlay, or save database.

The MME editor's former general-lore entry is an information card. If it contains
old personal text, that text remains available in a read-only box for copying
into Skyrim.Net. It is never silently migrated, deleted, or injected. Old JSON
defaults and override identifiers are retained for preset/API compatibility.

Only general lore moved. Actor identity, current fullness/equipment decorators,
and shared narration instructions retain their existing owners. Private player
requests no longer receive this general lore; player-specific lore is up to the user.

An empty condition makes all NPCs eligible. Semantic retrieval includes the entry
when relevant; it does not guarantee inclusion in every request. Users can change
its injection behavior through Skyrim.Net without MME changing global settings.

Documented hot editing and synchronization are Skyrim.Net features, not a new MME
watcher or polling service. This pack is authored against the published v3 schema;
live import/retrieval, edit/revert, and save/load acceptance remain to be tested.

References:
- https://github.com/MinLL/SkyrimNet-GamePlugin/blob/main/docs/modding/MIGRATING_TO_BETA25.md
- https://github.com/MinLL/SkyrimNet-Plugins/blob/main/schemas/knowledge-pack.schema.json
