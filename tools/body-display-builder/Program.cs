using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins.Records;
using Mutagen.Bethesda.Skyrim;

if (args.Length != 2) throw new ArgumentException("Usage: body-display-builder <input MMEAlert.esp> <output MMEAlert.esp>");
var input = Path.GetFullPath(args[0]);
var output = Path.GetFullPath(args[1]);
if (input == output) throw new InvalidDataException("Use a separate output for verification before replacing repository source.");
var mod = SkyrimMod.CreateFromBinary(input, SkyrimRelease.SkyrimSE);
var descriptions = new Dictionary<uint,string> {
    [0x8C0] = "Movement speed reduced by <mag>%.",
    [0x8C2] = "Carried milk reduces carry capacity by <mag> points."
};
foreach (var (id, description) in descriptions) {
    var effect = mod.MagicEffects.Single(r => r.FormKey.ID == id);
    if (effect.Archetype is not MagicEffectArchetype { Type: MagicEffectArchetype.TypeEnum.Script, ActorValue: ActorValue.None } || effect.VirtualMachineAdapter != null)
        throw new InvalidDataException($"{effect.FormKey} must remain a display-only Script effect, not another modifier");
    effect.Description = description;
    effect.Flags &= ~MagicEffect.Flag.NoMagnitude;
    mod.Spells.Single(r => r.FormKey.ID == id + 1).Description = "";
}
Directory.CreateDirectory(Path.GetDirectoryName(output)!);
mod.WriteToBinary(output, new Mutagen.Bethesda.Plugins.Binary.Parameters.BinaryWriteParameters {
    MastersListContent=Mutagen.Bethesda.Plugins.Binary.Parameters.MastersListContentOption.NoCheck,
    MastersListOrdering=Mutagen.Bethesda.Plugins.Binary.Parameters.MastersListOrderingOption.NoCheck
});
var check = SkyrimMod.CreateFromBinary(output, SkyrimRelease.SkyrimSE);
var expected = mod.EnumerateMajorRecords().ToDictionary(r => r.FormKey);
var actual = check.EnumerateMajorRecords().ToDictionary(r => r.FormKey);
if (!expected.Keys.ToHashSet().SetEquals(actual.Keys)) throw new InvalidDataException("Record identities changed");
foreach (var (key, record) in expected)
    if (!record.Equals(actual[key])) throw new InvalidDataException($"Unexpected round-trip difference in {key}");
if (!mod.ModHeader.Equals(check.ModHeader)) {
    foreach (var p in mod.ModHeader.GetType().GetProperties().Where(p => p.GetIndexParameters().Length == 0)) {
        var a=p.GetValue(mod.ModHeader);var b=p.GetValue(check.ModHeader);
        if (!Equals(a,b)) Console.WriteLine($"Header {p.Name}: {a} => {b}");
    }
    throw new InvalidDataException("Header changed on round-trip");
}
foreach (var id in descriptions.Keys) {
    var effect = check.MagicEffects.Single(r => r.FormKey.ID == id);
    var spell = check.Spells.Single(r => r.FormKey.ID == id + 1);
    if (effect.Flags.HasFlag(MagicEffect.Flag.NoMagnitude) || !string.IsNullOrEmpty(spell.Description.String))
        throw new InvalidDataException("Description inheritance/magnitude check failed");
}
Console.WriteLine($"PASS: {expected.Count} records round-trip unchanged except intended two descriptions/two flags/two cleared spell descriptions; display-only archetypes preserved.");
