# Milk Maid Status decorator

Developer metadata — category: Decorators. This is third-person natural-language AI context, not a notification or automatically spoken dialogue.

Two parts: current milk fullness, then recognized milking equipment if any. Below half includes empty; half-or-more excludes full; full includes over capacity. Keep numbers internal. Aim for about 90 characters per sentence before substituting the actor name. Actor names are supplied by the existing actor-local prompt state, not a new editable JSON placeholder.

Equipment descriptions accommodate different outfits. Living attire suggests an intimate pulsing embrace; parasite growths suggest clinging teasing; Dwemer equipment suggests mechanical vibrations. Distinguish a Dwemer suit from an attachment. The broad parasite category does not establish tentacles, so do not invent a specific anatomy. Equipped-only wording promises sensations rather than claiming active teasing or milk extraction. Omit unknown equipment, unknown fullness and leak facts from this two-part description.

Template comments and Papyrus comments are authoring metadata and must never appear in rendered AI context. This change adds no editable catalog entry, localization key, MCM setting, polling or gameplay state. Existing personal lore and titles remain authoritative and untouched.

Owner: Source/Scripts/MMEActorPromptState.psc and both copies of 0260_mme_extensions_milkmaid.prompt. Existing master-gated callback/snapshot traces and invalid-state smoke alarms remain in place.
