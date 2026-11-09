# One-outfit familiarity

Each actor remembers one slot-32 body armor Form plus a game-day removal timestamp. Boots, jewelry, weapons and effect equipment on other slots never replace this memory. A different body outfit replaces it, even when its display name is identical. No per-outfit history, new timer, polling loop, MCM setting or native code.

While worn the timestamp is -1 and familiarity persists. Removal starts eight in-game hours (one third of a game day). Matching re-equip before expiry suppresses ordinary equip story/moan/animation/narration and cancels expiry. At or after expiry normal presentation may run subject to existing settings, Maid eligibility and safety. Sleeping/waiting count. Duplicate removals do not restart the clock; delayed removal after redress is ignored; stale equip events cannot overwrite the remembered outfit. Clock reversal retains familiarity conservatively.

Current outfits are quietly seeded at startup/load/location observation and existing nearby scans; Skyrim.Net breastfeeding also seeds both participants before framework startup. Incoming equip handlers never call Seed. An initially unobserved removal establishes the removed outfit. Existing introduction markers remain separate; this does not reset lifetime introduction history.

Gameplay tracking, custom armor effects, refitting, timed locks and original equip-time stripping checks still run. Confirmed chest traps bypass ordinary familiarity suppression. Explicit artisan/public story requests remain explicit; this policy gates spontaneous native equip presentations only. No changes to original MME arrays, conversion, production, milking or inventory semantics.

Owner: MMEArmorFamiliarity.psc. Existing controller handles observation/equip/unequip; MMEArmorScript keeps its original two-argument public function and exposes a separate quiet gameplay path. Master-gated [MME Armor Familiarity] traces cover state changes and important skips. Expected skips are not alarms.

Tests execute actual source for identity, expiry, continuous wear, duplicate/delayed events, actor isolation, seeding and gameplay/presentation ordering. Live SexLab/P+/OStim redressing acceptance remains required after authorized installation.
