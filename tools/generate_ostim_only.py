"""Generate isolated OStim-only source variants; never modify installed files.

All substitutions are confined to the selected backend. Compilation and dependency
checks are mandatory before this directory can be included in a release.
"""
from pathlib import Path
import argparse
import json
import re
import shutil
import hashlib

ROOT = Path(__file__).resolve().parents[1]
BLOCK = re.compile(r"(?im)^[ \t]*(?:(\w+(?:\[\])?)[ \t]+)?(Function|Event)[ \t]+(\w+)[ \t]*\([^\n]*\).*?^[ \t]*End(?:Function|Event)\b", re.S | re.M)


def replace_body(text, name, body, parameter_types=None):
    found = 0
    def change(match):
        nonlocal found
        if match[3].lower() != name.lower():
            return match[0]
        found += 1
        header = match[0].splitlines()[0]
        if parameter_types:
            for old, new in parameter_types.items():
                header = re.sub(r"\b" + old + r"\b", new, header, flags=re.I)
        return header + "\n" + body + "\nEnd" + match[2]
    text = BLOCK.sub(change, text)
    if found != 1:
        raise ValueError(f"Expected one {name}, found {found}")
    return text


def skip(text, name, result=None, types=None):
    body = '    ; Unavailable in the explicitly selected OStim-only backend.'
    if result is not None:
        body += '\n    Return ' + result
    return replace_body(text, name, body, types)


def common_calls(text):
    # Class names remain outside strings/comments; no fake SexLab script is shipped.
    text = re.sub(r"\b(?:milkController|MovementSlapMilkController|MilkQ)\.SexLab\.(IsActorActive|IsValidActor|IsStrippable)\(", r"MMEFrameworkBackend.\1(", text, flags=re.I)
    text = re.sub(r"\bSexLab\.(IsActorActive|IsValidActor|IsStrippable|GetGender|ForbidActor|AllowActor|ClearMFG)\(", r"MMEFrameworkBackend.\1(", text, flags=re.I)
    text = re.sub(r"(?im)^.*(?:akActor\.(?:AddToFaction|RemoveFromFaction)\(SexLab\.AnimatingFaction\)).*$", '', text)
    text = re.sub(r"(?im)^[ \t]*SexLab\.PickVoice\(akActor\)\.Moan\([^\n]*", '                        MMEFrameworkBackend.PresentationSkipped(akActor)', text)
    text = re.sub(r"(?im)^.*MilkQ\.SexLab\.PickVoice\(akTarget\)\.Moan\([^\n]*", '    MMEFrameworkBackend.PresentationSkipped(akTarget)', text)
    # Exact availability expressions used by remaining common callers.
    text = re.sub(r"\b(?:milkController|MovementSlapMilkController)\.SexLab != None", 'MMEFrameworkBackend.IsReady()', text, flags=re.I)
    text = re.sub(r"\bmilkController\.SexLab == None", '!MMEFrameworkBackend.IsReady()', text, flags=re.I)
    return text


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mme-source', type=Path, required=True)
    args = parser.parse_args()
    inventory = json.loads((ROOT / 'docs/OStim-Only-Dependency-Audit.json').read_text())['script_inventory']
    expected = {item['script']: item['sha256'] for item in inventory}
    bridge_inputs = json.loads((ROOT / 'tools/ostim-only-builder/bridge-inputs.json').read_text())
    for name, digest in bridge_inputs.items():
        if hashlib.sha256((args.mme_source / name).read_bytes()).hexdigest() != digest:
            raise ValueError('Original bridge source differs from audited baseline: ' + name)
    for name in ['MilkLactacidScr', 'MilkPUMP', 'MilkPUMP_milkbarrel_example', 'MME_StartMilking', 'MME_CheckForSpriggan', 'MilkPlayerLoadGame', 'MME_Dialogues']:
        path = args.mme_source / (name + '.psc')
        if hashlib.sha256(path.read_bytes()).hexdigest() != expected[path.name]:
            raise ValueError('Original MME source differs from audited baseline: ' + path.name)
    output = ROOT / 'fomod/choices/ostim-only/Source/Scripts'
    output.mkdir(parents=True, exist_ok=True)
    variants = {}
    def read(name):
        path = ROOT / 'Source/Scripts' / (name + '.psc')
        return path.read_text()

    s = (ROOT / 'Source/MMECompatibilityOverrides/MilkQUEST.psc').read_text()
    s = re.sub(r'(?im)^SexLabFramework property SexLab auto\s*$', '', s)
    size_blocks = [m for m in BLOCK.finditer(s) if m[3].lower() == 'currentsize']
    if len(size_blocks) != 1:
        raise ValueError('Expected one original CurrentSize boundary')
    size_block = size_blocks[0]
    updated_size = re.sub(r'(?im)^EndFunction\s*$', '''    ; Reconcile the source gate at MME's established milk/size-change boundary.
    ; No new timer, polling or change to MME's stored quantities.
    If akActor != None && akActor == Game.GetPlayer()
        MMEAlertsController gateController = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If gateController != None
            gateController.RefreshNewMilkMaidDialogueAvailability(False)
        EndIf
    EndIf
EndFunction''', size_block[0])
    s = s[:size_block.start()] + updated_size + s[size_block.end():]
    s = replace_body(s, 'MMEExtApplyExpressionSafe', '    MMEFrameworkBackend.PresentationSkipped(akActor)')
    s = s.replace('SLSD.IsMilkingBlocked_Bra_SLSD(akActor)', 'MMEExtSLSDCheck(akActor)')
    s += '''
Bool Function MMEExtSLSDCheck(Actor target)
    If target == None || SLSD == None || Game.GetModByName("SexLab-StoriesDevious.esp") == 255
        Return False
    EndIf
    Return SLSD.IsMilkingBlocked_Bra_SLSD(target)
EndFunction
'''
    variants['MilkQUEST'] = common_calls(s)

    # The experimental no-SexLab branch cannot support the original DD adapter:
    # zadlibs exposes SexLab-typed signatures even with its plugin disabled.
    # Preserve MME's public bridge API, explicitly report integration absent,
    # and keep DD plugins excluded by the FOMOD for this branch.
    s = (args.mme_source / 'MME_DDi.psc').read_text()
    for match in list(BLOCK.finditer(s)):
        result = 'False' if (match[1] or '').lower() == 'bool' else None
        s = skip(s, match[3], result)
    s = replace_body(s, 'OnInit', '''    StorageUtil.SetIntValue(None, "MME.PluginsCheck.ddi", 0)
    MMELog.MasterDiagnostic("[MME Extensions DD Bridge] skipped | original DD integration unsupported in OStim-only choice")''')
    variants['MME_DDi'] = s

    for name in ['MilkLactacidScr', 'MilkPUMP', 'MilkPUMP_milkbarrel_example', 'MME_StartMilking', 'MME_CheckForSpriggan']:
        variants[name] = common_calls((args.mme_source / (name + '.psc')).read_text())

    s = (args.mme_source / 'MilkPlayerLoadGame.psc').read_text()
    for name, result in [('OnSexLabStart', None), ('OnSexLabEnd', None), ('OnSexLabOrgasm', None), ('OnSexLabOrgasmSeparate', None), ('getAnimName', '""')]:
        s = skip(s, name, result)
    # Preserve MME's gameplay calculations, replacing only framework metadata.
    s = re.sub(r'(?im)^.*sslBaseAnimation animation = MilkQ.SexLab.HookAnimation\(_args\).*$', '', s)
    s = s.replace('animation.HasTag(', 'MMEFrameworkBackend.SceneHasTag(_args, ')
    s = re.sub(r'MilkQ\.DDi\.(\w+)\(akActor\)', r'MilkQ.MMEExtDDCheck(akActor, "\1")', s, flags=re.I)
    s = s.replace('MilkQ.SLSD.IsMilkingBlocked_Bra_SLSD(akActor)', 'MilkQ.MMEExtSLSDCheck(akActor)')
    s += '''
Event OnMMEOStimOrgasm(String eventName, String sceneID, Float position, Form sender)
    Actor participant = sender as Actor
    If participant == None || !MMEFrameworkBackend.IsActorActive(participant)
        Return
    EndIf
    Int threadID = OActor.GetThreadID(participant)
    If threadID < 0 || OThread.GetScene(threadID) != sceneID
        MMELog.MasterDiagnostic("[MME Extensions Backend] orgasm ignored | actor=" + participant + " | stale scene=" + sceneID)
        Return
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Float previous = StorageUtil.GetFloatValue(participant, "MMEExtensions.Backend.Orgasm", -1.0)
    If now >= previous && now - previous < 0.05
        Return
    EndIf
    StorageUtil.SetFloatValue(participant, "MMEExtensions.Backend.Orgasm", now)
    MMELog.MasterDiagnostic("[MME Extensions Backend] orgasm entry | actor=" + participant + " | thread=" + threadID + " | scene=" + sceneID)
    Orgasm(participant, sceneID)
    MMELog.MasterDiagnostic("[MME Extensions Backend] orgasm gameplay complete | actor=" + participant + " | thread=" + threadID)
EndEvent
'''
    s = s.replace('Function RegisterEvents()', 'Function RegisterEvents()\n    RegisterForModEvent("ostim_orgasm", "OnMMEOStimOrgasm")')
    s, count = re.subn(r'(?ims)^[ \t]*if SexLabUtil.GetVersion\(\).*?^[ \t]*endif', '    MMEFrameworkBackend.Initialize()', s)
    assert count == 1
    s, count = re.subn(r'(?ims)^[ \t]*if MilkQ.SexLab.AnimSlots.*?^[ \t]*endif', '    MilkQ.MilkQC.MME_BreasfeedingAnimationsCheck = MMEOStimBreastfeeding.IsBreastfeedingEnabled()', s)
    assert count == 1
    s = re.sub(r'(?im)^.*RegisterForModEvent\("(?:OrgasmStart|SexLabOrgasmSeparate|StageStart|AnimationStart|AnimationEnd)".*$', '', s)
    variants['MilkPlayerLoadGame'] = s

    s = (args.mme_source / 'MME_Dialogues.psc').read_text()
    # Keep the original fragment API, but delegate scene ownership and milking
    # to the already established persistent OStim service.
    s = replace_body(s, 'Init_Milking', '    MMEFrameworkBackend.StartBreastfeeding(akActor1, akActor2, "MME dialogue")')
    variants['MME_Dialogues'] = s

    for name in ['MMEAnimationSafety', 'MMEArmorScript', 'MMEDwemerArmor', 'MMENewMilkMaid']:
        variants[name] = common_calls(read(name))

    variants['MMEArmorScript'] = replace_body(variants['MMEArmorScript'], 'IsStripSafeByFramework', '    Return MMEFrameworkBackend.IsStrippable(slotArmor)')

    s = read('MMEAlertsController')
    s = replace_body(s, 'RefreshMMESexLabAnimationGate', '''    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController != None && milkController.MilkQC != None
        milkController.MilkQC.MME_BreasfeedingAnimationsCheck = MMEOStimBreastfeeding.IsBreastfeedingEnabled()
    EndIf
    RefreshNewMilkMaidDialogueAvailability(False)
    Return False''')
    for name in ['BeginSexLabFallbackGrace', 'CheckSexLabFallbackAfterGrace']:
        s = replace_body(s, name, '    NextSexLabFallbackCheck = 0.0\n    SexLabFallbackCheckAttempts = 0')
    variants['MMEAlertsController'] = common_calls(s)

    s = read('MMEDebug')
    for name, value in [('StartSexLabBreastfeeding','False'), ('ClaimMMENewMilkMaidSexLabStartup','False'), ('OnNewMilkMaidSexLabEnding',None), ('ObserveDialogueSexLabBreastfeeding',None), ('SexLabIntentStillOwned','False'), ('SexLabPairFailure','"SexLab route intentionally disabled by OStim-only backend"')]:
        s = skip(s, name, value)
    s = replace_body(s, 'EnsureNewMilkMaidSexLabListeners', '    UnregisterForModEvent("AnimationEnding")\n    UnregisterForModEvent("AnimationEnd")\n    UnregisterForModEvent("MMEExtensionsNewMilkMaidSexLabTimeout")')
    s = replace_body(s, 'RecoverBreastfeedingAnimationAfterLoad', '    ClearPendingSexLabBreastfeedingAnimation()')
    s = replace_body(s, 'ShouldSuppressBreastfeedingDrink', '    Return drinker != None && ActiveSession && ActiveDrinker == drinker')
    # No registration of dormant SexLab listeners in this variant.
    s = re.sub(r'(?im)^.*RegisterForModEvent\("(?:AnimationStart|AnimationEnd|StageStart|OrgasmStart|SexLabOrgasmSeparate)".*$', '', s)
    s = replace_body(s, 'TraceAttempt', '    MMELog.MasterDiagnostic("[MME Extensions Backend] BF #" + attemptID + " | backend=OStim-only | " + traceText)')
    s += '''
String Function GetOStimBreastfeedingRole(Actor participant)
    If participant == None || !ActiveSession || !ActiveStartupConfirmed || !StillOwnsThread()
        Return ""
    EndIf
    If participant == ActiveMilkSource
        Return "source"
    ElseIf participant == ActiveDrinker
        Return "drinker"
    EndIf
    Return ""
EndFunction
'''
    s = replace_body(s, 'BreastfeedingDrinkReport', '    MMELog.MasterDiagnostic("[MME Extensions Backend] drink result | " + result)')
    variants['MMEDebug'] = s
    variants['MMEOStimBreastfeeding'] = replace_body(read('MMEOStimBreastfeeding'), 'Report', '    MMELog.MasterDiagnostic("[MME Extensions Backend] " + reportText)')
    s = skip(read('MMEOStimIntegration'), 'IsActorInSexLab', 'False')
    s = replace_body(s, 'IsActorBusy', '    Return IsActorInScene(target) || MMEFrameworkBackend.IsReserved(target)')
    s = replace_body(s, 'Report', '    MMELog.MasterDiagnostic("[MME Extensions Backend] " + reportText)')
    variants['MMEOStimIntegration'] = s
    variants['MMEAlertsSkyrimNet'] = replace_body(read('MMEAlertsSkyrimNet'), 'BreastfeedingPromptRole', '''    If !IsExtensionsEnabled() || participant == None
        Return ""
    EndIf
    MMEDebug service = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If service == None
        Return ""
    EndIf
    Return service.GetOStimBreastfeedingRole(participant)''')
    variants['MMEDiagnostics'] = replace_body(read('MMEDiagnostics'), 'GetSexLabStatus', '    Return "NOT USED (OStim-only)"')
    s = read('MMEElsieBreastfeeding')
    s = skip(s, 'IsTasteAnimation', 'False', {'sslThreadController':'Form'})
    s = skip(s, 'StartAutonomousFeed', '-1')
    s = skip(s, 'IsAvailable', 'False')
    variants['MMEElsieBreastfeeding'] = s
    s = read('MMESexLabBreastfeedingBackend')
    for name, result in [('GetBackendName','"OStim-only (legacy route disabled)"'), ('IsAvailable','False'), ('StartBreastfeeding','-1'), ('IsBreastfeedingThread','False'), ('EndOwnedScene',None)]:
        s = skip(s, name, result, {'sslThreadController':'Form'})
    variants['MMESexLabBreastfeedingBackend'] = s

    for path in (ROOT / 'Source/OStimOnly').glob('*.psc'):
        variants[path.stem] = path.read_text()
    for name, source in variants.items():
        source = re.sub(r'\bDebug\.Trace\(', 'MMELog.MasterDiagnostic(', source, flags=re.I)
        (output / (name + '.psc')).write_text('; OStim-only FOMOD variant. Generated by tools/generate_ostim_only.py.\n' + source.rstrip() + '\n')
    print(json.dumps({'generated': sorted(variants), 'count':len(variants)}, indent=2))


if __name__ == '__main__':
    main()
