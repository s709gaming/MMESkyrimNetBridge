# SexLab P+ unrelated-animation report: backend investigation

2026-10-28. Another player's report; no reproduction or changes to installed files. The affected interaction and P+ version remain unknown.

## Findings

The reporter can play the breastfeeding animations when only those animations are enabled. That supports successful registration/behavior playback, but does not prove that the initiating mod supplies the intended scene restriction.

Repository P+ MMESexLabBreastfeedingBackend requests a single explicit scene through StartSceneEx: e4j6zbhk (straight) or 6otwp8mm (lesbian). It checks registry presence and ValidateScene before dispatch. The P+ MME_Dialogues override also selects those explicit IDs, although it lacks equivalent validation and useful entry/result logging. The bundled registry source defines these IDs.

Original MME_Dialogues.Init_Milking instead calls AnimSlots.GetbyRegistrar with zjBreastFeedingVar or zjBreastFeeding, constructs a one-item legacy animation array, and passes it to StartSex without checking that the lookup succeeded.

Inspected local, disabled P+ 2.18.1 source:

- sslAnimationSlots.GetbyRegistrar searches _proxyid; SyncBackEnd assigns each proxy's Registry from the backend proxy IDs. The old MME registrar name is not inherently equivalent to the bundled SLSB scene IDs.
- SexLabFramework.StartSex calls thread.SetAnimations(Anims), then StartThread.
- sslThreadModel.SetAnimations applies SetScenes only when the list is nonempty and contains no None. A failed legacy lookup therefore leaves the selected primary list unset rather than restricting it to breastfeeding.
- SetScenes filters supplied IDs through SceneExistA. StartThread passes the lists to native CreateInstance, which validates/selects the scene. Native unrestricted fallback behavior was not inspected here; a broad/default selection is a strong hypothesis consistent with the report, not a proven runtime outcome.

This makes an original/overwritten MME_Dialogues script, a standard backend on P+, or another caller using legacy names the leading diagnosis. Successful playback with a restricted global animation catalogue would mask a missing per-request restriction. It does not establish an animation asset defect.

## Local environment boundary

houseCARL confirmed VortexToMO2 / Default. P+ 2.18.1 is installed but disabled. Current logs identify standard SexLab 16603 and Standard SexLab backend. Original MME wins MME_Dialogues.pex and MilkPlayerLoadGame.pex; MME Extensions wins its backend. This is consistent with this local standard installation and is not evidence of the reporter's deployment. Do not enable P+ or alter this profile to investigate someone else's report.

## Next evidence needed

1. Exact trigger: MME breastfeeding dialogue, new-maid conversion dialogue, Elsie/JUGS, self-milking or furniture/pump. Ordinary self/pump milking is a different route; do not assume every milking interaction enters this backend.
2. P+ version, MME Extensions version and selected FOMOD backend.
3. Effective file winners for Scripts/MME_Dialogues.pex, Scripts/MilkPlayerLoadGame.pex and Scripts/MMESexLabBreastfeedingBackend.pex. The All-in-One P+ FOMOD is intended to install all three overrides.
4. One fresh reproduction with master Papyrus logging and relevant SexLab breastfeeding diagnostics, plus SexLabUtil.log/thread scene-selection logs. Capture initiating route, source/drinker, requested scene ID, validation and initial active scene. Distinguish starting unrelated from changing away after a correct breastfeeding start.

## Conditional fix plan

- First establish that the intended P+ component actually wins; do not rewrite animation assets or ask the reporter to disable unrelated animations as the permanent solution.
- If the native MME dialogue override is implicated, route Init_Milking through the existing P+ facade or equivalent validated explicit-ID path, preserving source/drinker ordering and native MME hooks/milk accounting. Never start a generic scene if registry lookup/validation fails.
- Add sparse master-gated entry/selected scene/validation/thread/result/cleanup footprints to the currently uninstrumented P+ dialogue entry. Genuine missing-scene/start failures need concrete, deduplicated alarms; expected busy/unsupported actor skips are traces.
- If logs prove a correct selected ID changes after startup, investigate P+ scene progression/forced versus primary lists against that exact version. Do not assume SetForcedScenes or changing global P+ settings is needed without that evidence.
- Verify female/female and female/male roles, player/NPC both directions, missing scene/framework, disabled toggles, repeated cleanup, standard SexLab and OStim isolation. Compile every affected override, confirm FOMOD source/PEX pairs and winner instructions, rebuild generic ZIP.

Verdict: strong backend-selection/compatibility hypothesis, not yet a confirmed defect in the explicit-ID P+ backend. No implementation authorized or performed in this investigation.
