# Armor lock presentation and Dwemer collection

An active timed armor lock suppresses subsequent equip stories, equip narration,
moans and reaction animations for that wearer, regardless of which item raised
the equip event. Equipment bookkeeping and automatic milking continue normally.
The transaction that first establishes a lock may show its initial story. Chest
origin is consumed before the latent story to prevent restoration events from
reusing it. Existing saves need no migration; expired locks do not suppress stories.

The original `TryAutomatic` (2 arguments), `TryTrapIntroduction` (3 arguments)
and `TryPresentation` (5 arguments) signatures are retained for saved calls.
Initial-lock context uses separately named entry points. Optional Papyrus
parameters are compiled into callers and cannot repair an older saved call's
argument count. Legacy entry points use the same lock guard without granting
an initial-lock exception. Saved calls from the interim incompatible release
with additional arguments cannot also match the original signatures; existing-save
log checks remain necessary after upgrading.

Dwemer milking uses original MME's `MilkingToContainer(actor, 0, 4, 0, destination)`.
The destination is the actor's configured default collection container, falling
back to the wearer's inventory; MME's explicit override destination takes priority.
Original MME performs the single award, chooses milk type and quantity, handles
stored milk totals, and retains its progression and completion events. There is
no additional payout after completion. Living and parasite milk consumption is
unchanged. No additional original MME script override is required.

Routine suppression and destination traces use the master Papyrus logging switch.
Missing collection prerequisites raise a deduplicated alarm and run sequence
cleanup before returning. These changes do not diagnose or fix unrelated stuck
furniture or animation states.
