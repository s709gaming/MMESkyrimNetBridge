# Individual Dwemer attachments

Scope: blacksmith-installed Dwemer attachments only. Dedicated Dwemer suits/static compatibility remain intrinsic base-form definitions. Other vendor categories retain their existing registrations, with guards preventing services being applied over an individual Dwemer attachment.

## Identity and threading
The native DLL resolves the actual slot-32 worn inventory extra-data list. It requires exactly one worn list with count one, preserves any existing engine ExtraUniqueID, and assigns one using the engine allocator when capture requires it. Ambiguous inventory state fails closed. No item cloning, renaming or enchantment replacement. Engine-owned identity remains after attachment removal; never delete metadata other mods may use.

Engine identity is a context FormID, base armor FormID and 16-bit inventory ID, not SKSE GetWornItemId's display-name hash. A save-specific monotonically allocated attachment serial remains stable through ID remapping and supplies familiarity tags. Refit level belongs to the attachment record and follows it between wearers. The existing refit toggle still governs the feature.

Only game-thread tasks access inventory. Papyrus gets cached snapshots and queues capture/install/remove/refit operations. Requests are bounded; a menu-safe five-second wait returns a completed transaction or cancels queued work atomically. Captured tickets include the native load epoch. Save switching and master-off invalidate pending requests. IDs, not inventory pointers, cross task boundaries.

Install/remove are atomic native commits against the captured item. A later outfit change cannot undo an already successful service or redirect it to an identical copy. Equip presentation is skipped when the captured item is no longer worn. Automatic Dwemer milking rechecks the same physical attachment after the five-second prelude.

## Persistence and lifecycle
Version-one records live in the MMEExtensions section of the selected SKSE co-save, beside the ordinary save. Store serial counter, identity fields, stable attachment serial and fitted level. Load resolves FormIDs, validates bounds/duplicates/versions, and fails closed for corrupt state. Missing referenced forms are skipped with diagnostics. No shared global JSON holds item-instance service state. Keep the .ess and .skse save pair together; absent data is not reconstructed from names or enchantments.

Unique-ID change events remap records; container events invalidate affected snapshots and retire consumed items when identified. Form deletion removes records referring to that deleted context/base. Collision retires conflicting records rather than granting an attachment to an unrelated copy. There is no continuous inventory scan.

## Existing saves and APIs
Old artisan base-form registrations are dormant and cannot classify every copy as modified. Original markers are retained for explicit rebind/removal, never automatically assigned to all items. A one-time notice directs affected users to a blacksmith. Choosing installation on the worn garment binds only that item; the legacy marker is retired only after success. Other copies do not inherit it. Back up the save pair before upgrading; rollback uses the old package and its pre-upgrade save pair, not an assumed in-place downgrade.

Armor-only InstallDwemerAttachment/RegisterArtisanDwemerArmor APIs are deprecated and return false because they cannot identify a physical copy. Legacy Has/Remove inspect/retire broad markers only. Use MMEDwemerAttachment Capture/Install/Remove/Refit with the actor and captured identity. MMEExtensionsAPI.HasWornDwemerAttachment is the actor-aware status query. Public argument contracts remain unchanged for old functions.

## Diagnostics and acceptance
Master-gated [MME Dwemer Instance] Papyrus and native traces correlate request, actor, base armor, operation, captured engine identity, result and cleanup. Native remap/load/collision failures are deduplicated ungated alarms; cancellation, unavailable targets and changed items are expected skips.

Automated verification includes actual native state isolation/remap/serialization and actual Papyrus facade execution with mocked engine boundaries. Full compilation and package verification are required. Live acceptance remains pending until separately authorized installation: two identical copies, transfer to NPC, container/sale/drop/pickup, temper/rename/enchant, stack behavior, save/load/save switching, refitting, removal, SexLab/P+/OStim redressing, legacy rebind, disabled features and dedicated suit regression. Successful compilation does not prove runtime event coverage or VR behavior.
