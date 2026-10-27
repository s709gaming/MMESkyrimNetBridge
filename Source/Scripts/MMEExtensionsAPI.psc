Scriptname MMEExtensionsAPI Hidden

; =============================================================================
; MME Extensions public Papyrus API (version 19)
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
    Return 19
EndFunction

; Version 17: commits the gameplay effects for one externally owned,
; successfully completed breastfeeding scene. The caller remains responsible
; for starting, observing, and completing its scene. This call does not consume
; an inventory item or play the cup-drinking animation.
Bool Function CompleteBreastfeedingMilkShare(Actor milkSource, Actor drinker, String backend, Int sceneID) Global
    String prefix = "[MME Extensions BF API] "
    If milkSource == None || drinker == None || milkSource == drinker
        MMELog.Alarm(prefix + "rejected invalid source/drinker pair | backend=" + backend + " | scene=" + sceneID)
        Return False
    EndIf
    If milkSource.IsDead() || drinker.IsDead() || milkSource.IsDisabled() || drinker.IsDisabled() || milkSource.IsDeleted() || drinker.IsDeleted() || milkSource.IsChild() || drinker.IsChild()
        MMELog.MasterDiagnostic(prefix + "rejected unavailable participant | backend=" + backend + " | scene=" + sceneID, 1)
        Return False
    EndIf
    If !IsMilkMaid(milkSource)
        MMELog.MasterDiagnostic(prefix + "rejected non-Milk-Maid source | source=" + milkSource.GetDisplayName() + " | backend=" + backend + " | scene=" + sceneID, 1)
        Return False
    EndIf
    MMEDebug service = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If service == None
        MMELog.Alarm(prefix + "FAILURE: persistent breastfeeding service unavailable | backend=" + backend + " | scene=" + sceneID)
        Return False
    EndIf
    MMELog.MasterDiagnostic(prefix + "accepted completion handoff | source=" + milkSource.GetDisplayName() + " | drinker=" + drinker.GetDisplayName() + " | backend=" + backend + " | scene=" + sceneID)
    Return service.CompleteBreastfeedingDrink(milkSource, drinker, backend, sceneID, "ExternalBreastfeedingAPI")
EndFunction

; Version 15: plays the configured sex-aware arousal clip for tier 1-3 on any
; otherwise safe adult humanoid. This latent call owns and immobilizes the actor
; for three seconds, then restores movement. It honors the Arousal Animations
; MCM toggle and does not alter arousal, display text, or play a sound.
Bool Function TryPlayArousalAnimation(Actor target, Int tier) Global
    Return MMEArousalAnimations.TryPlay(target, tier, "Public API")
EndFunction

; Backend-neutral query. Returns true only for a current, authoritative MME
; Milk Maid registration. This does not depend on Skyrim.Net or OStim.
Bool Function IsMilkMaid(Actor target) Global
    Return MMEArmorScript.IsMMEMilkMaid(target)
EndFunction

; Backend-neutral, player-facing story presentation introduced in API version
; 8. The subject supplies {actor}/{ActorName}; it may be the player or an NPC.
; True means a nonblank message was submitted to Skyrim's game-pausing story
; box. It does not report when the player dismisses that box.
Bool Function ShowStoryPopup(Actor subject, String storyText) Global
    Return MMEStoryPopup.ShowStoryPopup(subject, storyText, "Public API")
EndFunction

; Selects one entry from a PapyrusUtil typed stringList pool, substitutes the
; subject tokens, and displays it through the same story box. fallbackText is
; used when the file or pool cannot provide a valid entry.
Bool Function ShowRandomStoryPopup(Actor subject, String configFile, String poolName, String fallbackText = "") Global
    Return MMEStoryPopup.ShowRandomStoryPopup(subject, configFile, poolName, fallbackText, "Public API")
EndFunction

; Backend-neutral one-time armor presentation introduced in API version 9.
; Supports Milking (1), Living (2), Parasite (3), and Dwemer (4) armor. It displays the
; category story, plays the shared high sound, and runs the safe kneeling
; animation, but does not create a Milk Maid. A successful call is latent and
; returns after the approximately ten-second presentation has been cleaned up.
Bool Function TryFirstArmorIntroduction(Actor target, Armor equippedArmor) Global
    Return MMEArmorIntroduction.TryIntroduction(target, equippedArmor, "Public API")
EndFunction

; Repeatable, backend-neutral presentation for a confirmed trapped-armor equip.
; Supports player or NPC Milking, Living, Parasite, and Dwemer armor. This does not
; equip or lock armor and does not create a Milk Maid. Successful calls are
; latent for roughly ten seconds while the shared animation is owned.
Bool Function TryTrapArmorEquipStory(Actor target, Armor equippedArmor) Global
    Return MMEArmorIntroduction.TryTrapIntroduction(target, equippedArmor, "Public API/Trap Armor Equip Story")
EndFunction

; Repeatable presentation for an ordinary equip or an artisan installation.
; This does not prove who initiated the equip, equip or lock the armor, or
; create a Milk Maid. It supports both the player and NPC wearers.
Bool Function TryRepeatArmorEquipStory(Actor target, Armor equippedArmor) Global
    Return MMEArmorIntroduction.TryRepeatIntroduction(target, equippedArmor, "Public API/Repeat Armor Equip Story")
EndFunction

Bool Function HasSeenArmorIntroduction(Actor target, Int armorClass) Global
    Return MMEArmorIntroduction.HasSeen(target, armorClass)
EndFunction

Bool Function ResetArmorIntroduction(Actor target, Int armorClass) Global
    Return MMEArmorIntroduction.Reset(target, armorClass)
EndFunction

; Standalone timed armor bonds introduced in API version 10. These calls do
; not require Devious Devices. Registered forms must be chest armor using slot
; 32; armorClass uses the same 1-4 values as the custom armor registry.
Bool Function RegisterTimedArmor(String pluginName, Int localFormID, Int armorClass) Global
    Return MMETimedArmorLock.RegisterArmor(pluginName, localFormID, armorClass)
EndFunction

Bool Function UnregisterTimedArmor(String pluginName, Int localFormID) Global
    Return MMETimedArmorLock.UnregisterArmor(pluginName, localFormID)
EndFunction

; durationDays below zero reads the MCM duration (default 3, range 0-30).
; The armor must already be registered; successful locks publish
; MMEExtensions_TimedArmorLocked.
Bool Function TryLockTimedArmor(Actor target, Armor targetArmor, Float durationDays = -1.0) Global
    Return MMETimedArmorLock.TryLock(target, targetArmor, durationDays, "Public API")
EndFunction

; Clears MME Extensions' protection, unequips the armor, and publishes
; MMEExtensions_TimedArmorReleased when successful.
Bool Function ReleaseTimedArmor(Actor target) Global
    Return MMETimedArmorLock.Release(target, "Public API")
EndFunction

Bool Function IsTimedArmorLocked(Actor target) Global
    Return MMETimedArmorLock.IsLocked(target)
EndFunction

Armor Function GetTimedLockedArmor(Actor target) Global
    Return MMETimedArmorLock.GetLockedArmor(target)
EndFunction

Float Function GetTimedArmorDaysRemaining(Actor target) Global
    Return MMETimedArmorLock.GetDaysRemaining(target)
EndFunction

; Version 14: removes the player's currently worn Living, Parasite, or Dwemer
; body armor. True means the asynchronous removal request was accepted; native
; completion is verified separately through the shared controller.
Bool Function ReleasePlayerSpecialArmor() Global
    Return MMEArmorRemoval.ReleasePlayerArmor("Public API/Player Armor Removal")
EndFunction

; Version 14: removes supported armor from every eligible allied NPC near the
; player. Returns the number of accepted asynchronous removal requests.
Int Function ReleaseNearbyNPCSpecialArmor(Float radius = 2000.0) Global
    Return MMEArmorRemoval.ReleaseNearbyNPCArmor(radius, "Public API/NPC Armor Removal")
EndFunction

; Backend-neutral custom armor classification introduced in API version 6.
; Return values: 0 unsupported, 1 Milking Armor, 2 Living Armor,
; 3 Living Parasite, 4 independent Dwemer Armor. MME's original forms/name arrays remain authoritative;
; the unlimited JSON registry is consulted only when they do not classify it.
Int Function GetArmorClass(Armor targetArmor) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Return MMEArmorScript.ClassifyArmor(milkController, targetArmor, "Public API")
EndFunction

Bool Function IsCustomMilkArmor(Armor targetArmor) Global
    Return MMECustomArmorRegistry.ClassifyCustomArmor(targetArmor) == 1
EndFunction

Bool Function IsCustomLivingArmor(Armor targetArmor) Global
    Return MMECustomArmorRegistry.ClassifyCustomArmor(targetArmor) == 2
EndFunction

Bool Function IsCustomParasiteArmor(Armor targetArmor) Global
    Return MMECustomArmorRegistry.ClassifyCustomArmor(targetArmor) == 3
EndFunction

Bool Function IsCustomDwemerArmor(Armor targetArmor) Global
    Return MMECustomArmorRegistry.ClassifyCustomArmor(targetArmor) == 4
EndFunction

; Persistent exact-form registration. localFormID is the plugin-local ID used
; by Game.GetFormFromFile, not the load-order-prefixed runtime FormID.
; armorClass: 1 Milking, 2 Living, 3 Parasite, 4 Dwemer. Returns false for invalid,
; unresolved, or already registered forms, and for a failed JSON save.
Bool Function RegisterCustomArmor(String pluginName, Int localFormID, Int armorClass) Global
    Return MMECustomArmorRegistry.RegisterArmor(pluginName, localFormID, armorClass)
EndFunction

; Removes one exact-form registration from the requested category and saves it.
Bool Function UnregisterCustomArmor(String pluginName, Int localFormID, Int armorClass) Global
    Return MMECustomArmorRegistry.UnregisterArmor(pluginName, localFormID, armorClass)
EndFunction

; Broad display-name fallbacks are supplied for mods whose forms cannot be
; known ahead of time. Exact-form registration above is safer and preferred.
Bool Function RegisterCustomArmorName(String armorName, Int armorClass) Global
    Return MMECustomArmorRegistry.RegisterArmorName(armorName, armorClass)
EndFunction

Bool Function UnregisterCustomArmorName(String armorName, Int armorClass) Global
    Return MMECustomArmorRegistry.UnregisterArmorName(armorName, armorClass)
EndFunction

; Form-oriented Dwemer attachment helpers introduced in API version 11. These
; use a dedicated display-name list so removal can never delete a built-in or
; third-party exact-form Dwemer registration.
Bool Function InstallDwemerAttachment(Armor targetArmor) Global
    If targetArmor == None || GetArmorClass(targetArmor) != 0
        Return False
    EndIf
    Return MMECustomArmorRegistry.RegisterArtisanDwemerArmor(targetArmor)
EndFunction

Bool Function RemoveDwemerAttachment(Armor targetArmor) Global
    Return MMECustomArmorRegistry.UnregisterArtisanDwemerArmor(targetArmor)
EndFunction

Bool Function HasDwemerAttachment(Armor targetArmor) Global
    Return MMECustomArmorRegistry.IsArtisanDwemerArmor(targetArmor)
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
; priority (owned Lactacid for Milk Maids, then normal/racial/supernatural), and honors the
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
; timer toggle, Milk Maid validation, and worn-keyword check.
Bool Function TryHeavyRestraintReaction(Actor target) Global
    If target == None || !MMEThoughts.IsExtensionsEnabled()
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

; API 18: player own-inventory drink; honors Free Jug fallback, never free Lactacid.
Bool Function DrinkAvailableMilk(Actor drinker) Global
    Return MMEAvailableMilkTransaction.DrinkAvailableMilk(drinker)
EndFunction

; API 18: returns rejection reason or empty string for manual self-milking.
String Function GetSelfMilkBlockReason(Actor target) Global
    Return MMESelfMilking.GetManualBlockReason(target)
EndFunction

; True confirms dispatch only. MME start/end events remain authoritative.
Bool Function TrySelfMilk(Actor target) Global
    Return MMESelfMilking.TryManual(target)
EndFunction

; API 19: presentation only; no conversion, milk, Lactacid or story selection.
Bool Function PlayMilkMaidReaction(Actor target) Global
    Return MMEMilkCurse.PlayReaction(target)
EndFunction

; API 19: established-maid curse, max-based uncapped milk plus presentation.
; True means the milk operation committed; presentation may later be interrupted.
Bool Function TryApplyMilkMaidCurse(Actor target, Float percentage = 50.0) Global
    Return MMEMilkCurse.ApplySurge(target, percentage, "")
EndFunction
