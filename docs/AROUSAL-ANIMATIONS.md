# Arousal Animations

MME Extensions ships five standalone humanoid animation clips for its three
arousal-reaction tiers. Female actors have a distinct clip at every tier. Male
tier 3 intentionally reuses the male tier-2 clip.

These clips use registered behavior events and do not require Open Animation
Replacer or new ESP records. After installing or updating MME Extensions, run
Pandora, Nemesis, or FNIS so the events in
`FNIS_MMEExtensionsArousal_List.txt` are added to the character behavior graph.
If this step is skipped, Papyrus can dispatch the event but Skyrim cannot play
the clip.

Automatic playback is controlled by **MME Extensions → Arousal → Play Arousal
Animations**. Accepted reactions hold the actor in place for three seconds and
never begin during combat, milking, a SexLab/OStim scene, mounted or seated
states, or another MME Extensions animation.
