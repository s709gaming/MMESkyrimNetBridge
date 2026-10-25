using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Plugins.Records;
using Mutagen.Bethesda.Skyrim;

if(args.Length == 4 && args[0] == "--dialogue-gate") {
    DialogueGate.Build(args[1], args[2], args[3]);
    return;
}
if(args.Length == 3 && args[0] == "--check-dialogue") {
    DialogueGate.Check(args[1],args[2]);
    return;
}

if(args.Length != 2) throw new ArgumentException("Usage: ostim-only-builder <original MilkModNEW.esp> <output MilkModNEW.esp>");
if(Path.GetFullPath(args[0]) == Path.GetFullPath(args[1])) throw new InvalidDataException("Refusing to edit original plugin");
var manifestPath = Path.Combine(AppContext.BaseDirectory, "input.json");
var manifest = System.Text.Json.JsonDocument.Parse(File.ReadAllText(manifestPath));
var inputHash=Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(File.ReadAllBytes(args[0])));
if(!inputHash.Equals(manifest.RootElement.GetProperty("sha256").GetString(),StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Original MME plugin revision differs from audited baseline");
var mod = SkyrimMod.CreateFromBinary(args[0], SkyrimRelease.SkyrimSE);
if(mod.ModKey.FileName.String != "MilkModNEW.esp" || Path.GetFileName(args[1]) != "MilkModNEW.esp") throw new InvalidDataException("Must preserve original plugin filename");
var sexlab = ModKey.FromNameAndExtension("SexLab.esm");
var noStrip = new FormKey(sexlab, 0x02F16E);
var framework = new FormKey(sexlab, 0x000D62);
var originalLinks = mod.EnumerateMajorRecords().ToDictionary(r=>r.FormKey,r=>r.EnumerateFormLinks().Select(l=>l.FormKey).Where(k=>!k.IsNull).ToHashSet());
var originalKeys = mod.EnumerateMajorRecords().Select(r=>r.FormKey).ToHashSet();
var affected = mod.EnumerateMajorRecords().Where(r=>r.EnumerateFormLinks().Any(l=>l.FormKey.ModKey == sexlab)).ToArray();
if(affected.Length != 6 || affected.Count(r=>r is Armor) != 5 || affected.Count(r=>r is Quest) != 1) throw new InvalidDataException("Unsupported original MME: direct dependency audit changed");
foreach(var record in affected) {
    foreach(var link in record.EnumerateFormLinks().Where(l=>l.FormKey.ModKey == sexlab))
        if(link.FormKey != noStrip && link.FormKey != framework) throw new InvalidDataException("Unexpected SexLab link: " + link.FormKey);
}
var quest = mod.Quests.Single(q=>q.FormKey.ID == 0xE209);
var script = quest.VirtualMachineAdapter!.Scripts.Single(s=>s.Name.Equals("MilkQUEST", StringComparison.OrdinalIgnoreCase));
var prop = script.Properties.Single(p=>p.Name.Equals("SexLab",StringComparison.OrdinalIgnoreCase));
if(prop is not ScriptObjectProperty obj || obj.Object.FormKey != framework) throw new InvalidDataException("Unexpected quest binding");
script.Properties.Remove(prop);
var localKey = new FormKey(mod.ModKey, 0x0F0000);
if(originalKeys.Contains(localKey)) throw new InvalidDataException("Local keyword ID is occupied");
mod.Keywords.Add(new Keyword(localKey, SkyrimRelease.SkyrimSE) { EditorID="MMEExtNoStrip" });
mod.RemapLinks(new Dictionary<FormKey,FormKey>{{noStrip,localKey}});
if(mod.EnumerateFormLinks().Any(l=>l.FormKey.ModKey == sexlab)) throw new InvalidDataException("SexLab links survive");
mod.ModHeader.MasterReferences.RemoveAll(m=>m.Master == sexlab);
Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(args[1]))!);
mod.WriteToBinary(args[1]);
var result=SkyrimMod.CreateFromBinary(args[1],SkyrimRelease.SkyrimSE);
if(result.ModHeader.MasterReferences.Any(m=>m.Master == sexlab) || result.EnumerateFormLinks().Any(l=>l.FormKey.ModKey==sexlab)) throw new InvalidDataException("Round-trip SexLab dependency survives");
var resultKeys=result.EnumerateMajorRecords().Select(r=>r.FormKey).ToHashSet();
if(!originalKeys.IsSubsetOf(resultKeys) || resultKeys.Count != originalKeys.Count+1) throw new InvalidDataException("Existing FormKeys changed");
if(result.Armors.Count(a=>a.Keywords?.Any(k=>k.FormKey==localKey)==true)!=5) throw new InvalidDataException("Protection not preserved");
foreach(var record in result.EnumerateMajorRecords().Where(r=>originalKeys.Contains(r.FormKey))) {
    var expected=originalLinks[record.FormKey].Where(k=>k!=framework).Select(k=>k==noStrip ? localKey : k).ToHashSet();
    var actual=record.EnumerateFormLinks().Select(l=>l.FormKey).Where(k=>!k.IsNull).ToHashSet();
    if(!expected.SetEquals(actual)) throw new InvalidDataException("Unexpected link change: " + record.FormKey);
}
Console.WriteLine("Verified no-SexLab replacement: all original FormKeys retained, five protected armors, one local keyword, no SexLab master/links.");
