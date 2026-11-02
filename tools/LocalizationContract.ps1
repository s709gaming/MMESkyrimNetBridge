# Existing gameplay contracts compare the English source literals.
# Remove only the display wrapper; preserve its literal and all surrounding code.
function Remove-MMELocalizationWrappers {
    param([Parameter(ValueFromPipeline=$true)][string]$Source)
    process { [regex]::Replace($Source, 'MMELocalization\.Text\(("(?:\\.|[^"\\])*")\)', '$1') }
}
