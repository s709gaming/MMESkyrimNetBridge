using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Plugins.Assets;
using Mutagen.Bethesda.Skyrim;
using Mutagen.Bethesda.Skyrim.Assets;

if (args.Length != 2)
{
    Console.Error.WriteLine("Usage: sound-record-builder <WAV folder> <output ESP>");
    return 2;
}

var soundFolder = Path.GetFullPath(args[0]);
var path = Path.GetFullPath(args[1]);
var wavFiles = Directory.GetFiles(soundFolder, "*.wav").OrderBy(Path.GetFileName).ToArray();
if (wavFiles.Length == 0)
    throw new InvalidDataException("The breast-slap sound folder contains no WAV files.");
var outputKey = ModKey.FromNameAndExtension(Path.GetFileName(path));
var mod = new SkyrimMod(outputKey, SkyrimRelease.SkyrimSE);
mod.ModHeader.Author = "MME Extensions";
mod.ModHeader.Description = "Randomized sound pool for MME Extensions breast-bounce reactions.";
var descriptorKey = new FormKey(mod.ModKey, 0x000800);
var markerKey = new FormKey(mod.ModKey, 0x000801);

var descriptor = new SoundDescriptor(descriptorKey, SkyrimRelease.SkyrimSE)
{
    EditorID = "MMEAlerts_SNDR_BreastSlap",
    Type = SoundDescriptor.DescriptorType.Standard,
    StaticAttenuation = 0.0f,
    Priority = 128
};
foreach (var wavFile in wavFiles)
    descriptor.SoundFiles.Add(new AssetLink<SkyrimSoundAssetType>($"fx\\MMESkyrimNetBridge\\Tit Slap Sounds\\{Path.GetFileName(wavFile)}"));
mod.SoundDescriptors.Add(descriptor);

var marker = new SoundMarker(markerKey, SkyrimRelease.SkyrimSE)
{
    EditorID = "MMEAlerts_SOUN_BreastSlap"
};
marker.SoundDescriptor.SetTo(descriptorKey);
mod.SoundMarkers.Add(marker);

var temporaryDirectory = Path.Combine(Path.GetDirectoryName(path)!, "build", "sound-record-builder-output");
Directory.CreateDirectory(temporaryDirectory);
var temporary = Path.Combine(temporaryDirectory, Path.GetFileName(path));
mod.WriteToBinary(temporary);
var verified = SkyrimMod.CreateFromBinary(temporary, SkyrimRelease.SkyrimSE);
var verifiedDescriptor = verified.SoundDescriptors.Single(x => x.FormKey == descriptorKey);
var verifiedMarker = verified.SoundMarkers.Single(x => x.FormKey == markerKey);
if (verifiedDescriptor.SoundFiles.Count != wavFiles.Length || verifiedMarker.SoundDescriptor.FormKey != descriptorKey)
    throw new InvalidDataException("Breast-slap sound records failed round-trip verification.");
File.Move(temporary, path, true);
Console.WriteLine($"Built and round-trip verified breast-slap pool with {wavFiles.Length} WAV file(s).");
return 0;
