Scriptname MMEExtensionsAPI Hidden

; =============================================================================
; MME Extensions public Papyrus API (version 5)
; =============================================================================
; This is the stable entry point for other mods. Call these wrappers instead
; of MMEDebug, MMENewMilkMaid, MMEOStimBreastfeeding, or other internal scripts.
;
; IMPORTANT BACKEND LABELING
; - A function containing "OStim" is OStim-only.
; - Functions without a framework name are not promises about any one scene
;   framework. Version 1 intentionally exposes no generic scene-start function.
;
; Async calls return when a request is accepted, not when its scene or gameplay
; transaction finishes. Listen for the documented ModEvents to observe results.

Int Function GetAPIVersion() Global
    Return 5
EndFunction

; Backend-neutral query. Returns true only for a current, authoritative MME
; Milk Maid registration. This does not depend on Skyrim.Net or OStim.
Bool Function IsMilkMaid(Actor target) Global
    Return MMEArmorScript.IsMMEMilkMaid(target)
EndFunction

; OStim-only availability query. True means OStim is detected, supported, and
; the MCM option required by StartOStimBreastfeeding is enabled.
Bool Function IsOStimBreastfeedingAvailable() Global
    Return MMEOStimBreastfeeding.IsBreastfeedingEnabled() && MMEOStimIntegration.IsSupportedVersion()
EndFunction

; OStim-only request. milkSource supplies the breast; drinker receives milk.
; True means the request passed synchronous validation and OStim returned a
; thread ID. It does not mean the scene has started or completed. Observe:
;   MMEExtensions_BreastfeedingRequestAccepted
;   MMEExtensions_BreastfeedingStarted
;   MMEExtensions_BreastfeedingCompleted
;   MMEExtensions_BreastfeedingAborted
Bool Function StartOStimBreastfeeding(Actor milkSource, Actor drinker) Global
    Return MMEOStimBreastfeeding.StartSharedBreastfeeding(milkSource, drinker, "Public API")
EndFunction

; Backend-neutral gameplay request. Uses MME's native Lactacid creation path,
; including MME's original registration, initialization, and reaction animation.
; Completion is asynchronous from the caller's perspective. Listen for the
; existing actor-only MMEExtensions_MilkmaidCreated event to confirm success.
Function RequestMilkMaidCreation(Actor target) Global
    MMENewMilkMaid.MakeTargetNewMilkMaid(target)
EndFunction

; Backend-neutral forced gameplay transaction. This bypasses MME's NPC Yes/No
; confirmation but retains MME's localized assignment message, slot/capacity
; authority, initial Lactacid state, and original ten-second ZaZ reaction.
; True means registration, initialization, animation, and cleanup completed.
; The function is latent and may take roughly ten seconds before returning.
Bool Function TryCreateMilkMaidForcedAnimated(Actor target) Global
    Return MMENewMilkMaid.TryCreateMilkMaidForcedAnimated(target)
EndFunction

; Backend-neutral forced drink transaction introduced in API version 3. The
; supplied item must be a supported MME milk, Lactacid, or HearthFires milk.
; The real item is equipped and consumed so the ordinary MME Extensions drink
; pipeline remains the sole owner of effects and event publication.
Bool Function ForceMilkDrink(Actor drinker, Form milkItem) Global
    Return MMEForcedMilkDrink.ForceMilkDrink(drinker, milkItem)
EndFunction

; Convenience form of ForceMilkDrink for integrations that want an ordinary,
; dependency-stable drink without resolving an item themselves. Uses the
; HearthFires Jug of Milk and otherwise has the same validation and events.
Bool Function DrinkNormalMilk(Actor drinker) Global
    Form normalMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    Return MMEForcedMilkDrink.ForceMilkDrink(drinker, normalMilk)
EndFunction

; Inventory-backed actor-to-actor transaction. Uses the established Give Milk
; priority (normal, racial, supernatural), excludes Lactacid, and honors the
; existing Free Jug for Give Milk fallback when the giver owns no eligible milk.
Bool Function GiveAvailableMilk(Actor giver, Actor drinker) Global
    Return MMEAvailableMilkTransaction.GiveAvailableMilk(giver, drinker)
EndFunction

; Runs the complete configured periodic Milk Armor Thought pipeline for one
; actor: live fullness/armor classification, JSON wording, HUD notification,
; reaction sound, and optional Skyrim.Net narration. It bypasses only nearby
; scanning, random actor selection, and timer scheduling.
Bool Function TryMilkArmorThought(Actor target) Global
    If target == None || !MMEThoughts.IsNormalThoughtsEnabled()
        Return False
    EndIf
    Actor[] targets = new Actor[1]
    targets[0] = target
    Return MMEThoughts.GenerateAndShowThought(targets, True)
EndFunction

; Runs the complete configured Devious heavy-restraint Thought pipeline for
; one actor: JSON wording, HUD notification, hot reaction sound, and optional
; Skyrim.Net narration. The explicit API request bypasses the periodic chance,
; but retains the feature gate, Milk Maid validation, and worn-keyword check.
Bool Function TryHeavyRestraintReaction(Actor target) Global
    If target == None || !MMEThoughts.IsBoundThoughtsEnabled()
        Return False
    EndIf
    Actor[] targets = new Actor[1]
    targets[0] = target
    Return MMEThoughts.GenerateAndShowBoundThought(targets, False)
EndFunction

; Runs the complete configured Living/Parasite Armor effect for one actor:
; armor validation, milk/arousal effects, HUD notification, reaction sound,
; and optional Skyrim.Net narration. It bypasses the periodic chance, while
; the Tentacle Effects feature toggle and all output-channel settings remain
; authoritative.
Bool Function TryLivingArmorEffect(Actor target) Global
    If target == None
        Return False
    EndIf
    Actor[] targets = new Actor[1]
    targets[0] = target
    Return MMETentacleEffects.RunInjectionCheck(targets, False, False)
EndFunction

; Runs the configured fullness-based armor-stripping evaluator immediately for
; one actor. On verified removal it reuses the notification, hot reaction
; sound, and optional Skyrim.Net narration. Framework no-strip protections and
; the Armor Stripping MCM master remain authoritative.
Bool Function TryArmorStrippingCheck(Actor target) Global
    If target == None || !MMEAlertsController.IsExtensionsEnabled() || !MMEArmorScript.IsConfigurableArmorStrippingEnabled()
        Return False
    EndIf
    Return MMEArmorScript.EvaluateArmorStrippingForActor(target, MME_Storage.getMilkCurrent(target), "public API")
EndFunction

; =============================================================================
; Internal event publishers
; =============================================================================
; These helpers keep payload order in one place. They are Global because a
; Hidden Papyrus script has no instance, but they are not public request APIs.
; External mods should register for the events, never call these publishers.

Bool Function PublishBreastfeedingStage(String eventName, Actor milkSource, Actor drinker, String backend, Int requestID) Global
    Int handle = ModEvent.Create(eventName)
    If handle == 0
        Return False
    EndIf
    ModEvent.PushForm(handle, milkSource)
    ModEvent.PushForm(handle, drinker)
    ModEvent.PushString(handle, backend)
    ModEvent.PushInt(handle, requestID)
    Return ModEvent.Send(handle)
EndFunction

Bool Function PublishBreastfeedingAborted(Actor milkSource, Actor drinker, String backend, Int requestID, String reason) Global
    Int handle = ModEvent.Create("MMEExtensions_BreastfeedingAborted")
    If handle == 0
        Return False
    EndIf
    ModEvent.PushForm(handle, milkSource)
    ModEvent.PushForm(handle, drinker)
    ModEvent.PushString(handle, backend)
    ModEvent.PushInt(handle, requestID)
    ModEvent.PushString(handle, reason)
    Return ModEvent.Send(handle)
EndFunction

Bool Function PublishForcedMilkDrinkCompleted(Actor drinker, Form milkItem, Int drinkKind) Global
    Int handle = ModEvent.Create("MMEExtensions_ForcedMilkDrinkCompleted")
    If handle == 0
        Return False
    EndIf
    ModEvent.PushForm(handle, drinker)
    ModEvent.PushForm(handle, milkItem)
    ModEvent.PushInt(handle, drinkKind)
    Return ModEvent.Send(handle)
EndFunction

Bool Function PublishAvailableMilkGiven(Actor giver, Actor drinker, Form milkItem, Bool fallbackSupplied) Global
    Int handle = ModEvent.Create("MMEExtensions_AvailableMilkGiven")
    If handle == 0
        Return False
    EndIf
    ModEvent.PushForm(handle, giver)
    ModEvent.PushForm(handle, drinker)
    ModEvent.PushForm(handle, milkItem)
    If fallbackSupplied
        ModEvent.PushInt(handle, 1)
    Else
        ModEvent.PushInt(handle, 0)
    EndIf
    Return ModEvent.Send(handle)
EndFunction
