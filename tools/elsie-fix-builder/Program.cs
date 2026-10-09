using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Plugins.Records;
using Mutagen.Bethesda.Skyrim;

if (args.Length != 2)
{
    Console.Error.WriteLine("Usage: elsie-fix-builder <CP_Elsie.esp> <output patch.esp>");
    return 2;
}

var source = SkyrimMod.CreateFromBinary(args[0], SkyrimRelease.SkyrimSE);
if (!source.ModKey.FileName.String.Equals("CP_Elsie.esp", StringComparison.OrdinalIgnoreCase))
    throw new InvalidDataException("Input must be CP_Elsie.esp.");

var outputKey = ModKey.FromNameAndExtension(Path.GetFileName(args[1]));
var patch = new SkyrimMod(outputKey, SkyrimRelease.SkyrimSE);
patch.ModHeader.Author = "MME Extensions";
patch.ModHeader.Description = "Compatibility fixes for Elsie LaVache 3.4. Requires the original CP_Elsie.esp.";
foreach (var master in source.ModHeader.MasterReferences)
    patch.ModHeader.MasterReferences.Add(master.DeepCopy());
patch.ModHeader.MasterReferences.Add(new MasterReference { Master = source.ModKey });

// An empty, unconditional ninth Hello INFO can win selection and say nothing.
var greeting = source.DialogTopics.Single(t => t.FormKey.ID == 0x0944BC).DeepCopy();
var removedGreeting = greeting.Responses.RemoveAll(i => i.FormKey.ID == 0x12437E);
if (removedGreeting != 1 || greeting.Responses.Count != 8)
    throw new InvalidDataException($"Expected one empty greeting INFO removed and eight retained; removed={removedGreeting}, retained={greeting.Responses.Count}.");
patch.DialogTopics.Add(greeting);

// Elsie ships the same player-alias script with a complete binding set on its
// main quest. Copy only properties missing from ELV_FemalePlayer, preserving
// Elsie's own quest-alias metadata instead of synthesizing FormIDs.
var targetQuest = source.Quests.Single(q => q.FormKey.ID == 0x06302B).DeepCopy();
var donorQuest = source.Quests.Single(q => q.FormKey.ID == 0x005E57);
var targetScript = FindScripts(targetQuest).Single(IsPlayerAliasScript);
var donorScript = FindScripts(donorQuest).Single(IsPlayerAliasScript);
foreach (var property in donorScript.Properties)
    if (!targetScript.Properties.Any(p => p.Name.Equals(property.Name, StringComparison.OrdinalIgnoreCase)))
        targetScript.Properties.Add(property.DeepCopy());

var expectedProperties = new[]
{
    "ELV", "SexLab", "Stats", "QS", "PlayerRef", "CellTracker",
    "MC_PlayerRef", "MC_Elsie", "ELV_MakeCows"
};
AssertProperties(targetScript, expectedProperties, "ELV_FemalePlayer");
patch.Quests.Add(targetQuest);

// The scene record still serializes a property removed from its current script.
var trainingScene = source.Scenes.Single(s => s.FormKey.ID == 0x03F41A).DeepCopy();
var trainingScript = FindScripts(trainingScene).Single(s =>
    s.Name.Equals("ELV_TrainCanPers_milk", StringComparison.OrdinalIgnoreCase));
trainingScript.Properties.RemoveAll(p => p.Name.Equals("Alias_Player", StringComparison.OrdinalIgnoreCase));
patch.Scenes.Add(trainingScene);

Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(args[1]))!);
patch.WriteToBinary(args[1]);

// Binary round-trip verification catches malformed master tables, nested INFO
// loss, and VMAD edits that did not serialize.
var verified = SkyrimMod.CreateFromBinary(args[1], SkyrimRelease.SkyrimSE);
var verifiedGreeting = verified.DialogTopics.Single(t => t.FormKey.ID == 0x0944BC);
if (verifiedGreeting.Responses.Count != 8 || verifiedGreeting.Responses.Any(i => i.FormKey.ID == 0x12437E))
    throw new InvalidDataException("Round-trip greeting verification failed.");

var verifiedTargetScript = FindScripts(verified.Quests.Single(q => q.FormKey.ID == 0x06302B))
    .Single(IsPlayerAliasScript);
AssertProperties(verifiedTargetScript, expectedProperties, "round-trip ELV_FemalePlayer");

var verifiedTrainingScript = FindScripts(verified.Scenes.Single(s => s.FormKey.ID == 0x03F41A))
    .Single(s => s.Name.Equals("ELV_TrainCanPers_milk", StringComparison.OrdinalIgnoreCase));
if (verifiedTrainingScript.Properties.Any(p => p.Name.Equals("Alias_Player", StringComparison.OrdinalIgnoreCase)))
    throw new InvalidDataException("Round-trip stale scene-property verification failed.");

Console.WriteLine("Built and round-trip verified Elsie LaVache 3.4 stability patch.");
return 0;

static bool IsPlayerAliasScript(ScriptEntry script) =>
    script.Name.Equals("ELVPlayerAliasscript", StringComparison.OrdinalIgnoreCase);

static void AssertProperties(ScriptEntry script, IEnumerable<string> expected, string label)
{
    var missing = expected.Where(name =>
        !script.Properties.Any(p => p.Name.Equals(name, StringComparison.OrdinalIgnoreCase))).ToArray();
    if (missing.Length != 0)
        throw new InvalidDataException($"{label} remains missing properties: {string.Join(", ", missing)}");
}

static List<ScriptEntry> FindScripts(object root)
{
    var found = new List<ScriptEntry>();
    var visited = new HashSet<object>(ReferenceEqualityComparer.Instance);
    Walk(root);
    return found;

    void Walk(object? current)
    {
        if (current is null || current is string || !visited.Add(current)) return;
        if (current is ScriptEntry script) found.Add(script);
        foreach (var property in current.GetType().GetProperties().Where(p => p.GetIndexParameters().Length == 0))
        {
            object? child;
            try { child = property.GetValue(current); }
            catch { continue; }
            if (child is System.Collections.IEnumerable items && child is not string)
                foreach (var item in items) Walk(item);
            else if (child is not null && child.GetType().Namespace?.StartsWith("Mutagen.") == true)
                Walk(child);
        }
    }
}

