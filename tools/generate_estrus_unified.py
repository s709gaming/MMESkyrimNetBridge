"""Rebase the author's narrow Unified patch onto each current backend source."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHOICE = ROOT / "fomod/choices/estrus-unified"
ENTRY = "bool Function isPregnant(Actor akActor)\n"

# These saved variables suppress diagnostics only. Never use them for readiness
# or pregnancy answers; every query calls the author's public API afresh.
HELPERS = '''; Estrus Unified compatibility, based on the author's supplied MME patch.
Bool MMEExtUnifiedInvalidActorReported = False
Bool MMEExtUnifiedInvalidResultReported = False
Int MMEExtUnifiedDiagnosticState = -1

Function MMEExtTraceUnifiedAvailability(Int diagnosticState)
    if MMEExtUnifiedDiagnosticState != diagnosticState
        MMEExtUnifiedDiagnosticState = diagnosticState
        MMELog.MasterDiagnostic("[MME Extensions Estrus] readiness state | 0=absent, 1=not ready, 2=ready | state=" + diagnosticState)
    endif
EndFunction

bool Function HasEstrusUnified()
    if Game.GetModByName("EstrusUnified.esp") == 255 || SKSE.GetPluginVersion("EstrusUnified") == -1
        MMEExtTraceUnifiedAvailability(0)
        return false
    endif
    Bool ready = EstrusUnifiedAPI.IsReady()
    if ready
        MMEExtTraceUnifiedAvailability(2)
    else
        MMEExtTraceUnifiedAvailability(1)
    endif
    return ready
EndFunction

'''

QUERY = '''    MMELog.Diagnostic("[MME Extensions Estrus] pregnancy query entry | actor=" + akActor)
    if !akActor
        if !MMEExtUnifiedInvalidActorReported
            MMEExtUnifiedInvalidActorReported = True
            MMELog.Alarm("[MME Extensions Estrus] SMOKE ALARM | operation=pregnancy query | actor=None | invalid actor; query rejected")
        endif
        return false
    endif
    if HasEstrusUnified()
        Int pregnancyType = EstrusUnifiedAPI.GetPregnancyType(akActor)
        MMELog.Diagnostic("[MME Extensions Estrus] pregnancy query result | actor=" + akActor + " | type=" + pregnancyType)
        if pregnancyType < 0 || pregnancyType > 3
            if !MMEExtUnifiedInvalidResultReported
                MMEExtUnifiedInvalidResultReported = True
                MMELog.Alarm("[MME Extensions Estrus] SMOKE ALARM | operation=pregnancy query | actor=" + akActor + " | invalid API result=" + pregnancyType + "; continuing original checks")
            endif
        elseif pregnancyType > 0
            MMELog.Diagnostic("[MME Extensions Estrus] pregnancy query complete | actor=" + akActor + " | recognized=True")
            return true
        endif
    endif
    MMELog.Diagnostic("[MME Extensions Estrus] pregnancy query complete | actor=" + akActor + " | continuing original checks")
'''


def patch(source: str) -> str:
    if source.count(ENTRY) != 1 or "EstrusUnifiedAPI" in source or "MMEEstrusUnified" in source:
        raise ValueError("Expected exactly one unpatched pregnancy entry")
    return source.replace(ENTRY, HELPERS + ENTRY + QUERY, 1)


def main():
    for backend, source in [
        ("standard", ROOT / "Source/MMECompatibilityOverrides/MilkQUEST.psc"),
        ("ostim-only", ROOT / "fomod/choices/ostim-only/Source/Scripts/MilkQUEST.psc"),
    ]:
        destination = CHOICE / backend / "Source/Scripts/MilkQUEST.psc"
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(patch(source.read_text()), encoding="utf-8")
        print(f"Generated author-style Unified patch: {backend}")


if __name__ == "__main__":
    main()
