using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Skyrim;
using Mutagen.Bethesda.Plugins.Records;

if (args.Length != 2) throw new ArgumentException("Usage: maid-roster-builder <repository MMEAlert.esp> <repository output ESP>");
var source = Path.GetFullPath(args[0]);
var output = Path.GetFullPath(args[1]);
if (source == output || !output.Contains(Path.DirectorySeparatorChar + "fomod" + Path.DirectorySeparatorChar)) throw new InvalidDataException("Output must be the repository optional FOMOD component");
var core = SkyrimMod.CreateFromBinary(source, SkyrimRelease.SkyrimSE);
var controller = core.Quests.Single(q => q.FormKey.ID == 0x800);
var mod = new SkyrimMod(ModKey.FromNameAndExtension(Path.GetFileName(output)), SkyrimRelease.SkyrimSE);
mod.ModHeader.Flags |= SkyrimModHeader.HeaderFlag.Small;
var quest = new Quest(mod.GetNextFormKey(), SkyrimRelease.SkyrimSE) {
    EditorID = "MMEExt_MaidRosterUI", Name = "MME Milk Maid Roster",
    Flags = Quest.Flag.StartGameEnabled, Priority = 10, NextAliasID = 1, QuestFormVersion = 46,
    VirtualMachineAdapter = new QuestAdapter { Version = 5, ObjectFormat = 2, ExtraBindDataVersion = 2 }
};
var script = new ScriptEntry { Name = "MMEMaidRosterUI" };
script.Properties.Add(new ScriptObjectProperty { Name = "ExtensionsController", Flags = ScriptProperty.Flag.Edited, Object = new FormLink<ISkyrimMajorRecordGetter>(controller.FormKey), Alias = -1 });
quest.VirtualMachineAdapter.Scripts.Add(script);
var player = FormKey.Factory("000014:Skyrim.esm");
quest.Aliases.Add(new QuestAlias { ID = 0, Name = "Player", Type = QuestAlias.TypeEnum.Reference, ForcedReference = new FormLinkNullable<IPlacedGetter>(player) });
var alias = new QuestFragmentAlias { Version = 5, ObjectFormat = 2,
    Property = new ScriptObjectProperty { Object = new FormLink<ISkyrimMajorRecordGetter>(quest.FormKey), Alias = 0 }
};
alias.Scripts.Add(new ScriptEntry { Name = "MMEMaidRosterPlayerAlias" });
quest.VirtualMachineAdapter.Aliases.Add(alias);
mod.Quests.Add(quest);
Directory.CreateDirectory(Path.GetDirectoryName(output)!);
mod.WriteToBinary(output);
var check = SkyrimMod.CreateFromBinary(output, SkyrimRelease.SkyrimSE);
var result = check.Quests.Single();
if (!check.ModHeader.Flags.HasFlag(SkyrimModHeader.HeaderFlag.Small) || check.EnumerateMajorRecords().Count() != 1 || result.FormKey.ID > 0xFFF) throw new InvalidDataException("Add-on must be a small, single-quest plugin");
var masters = check.ModHeader.MasterReferences.Select(m => m.Master.FileName.String).ToHashSet(StringComparer.OrdinalIgnoreCase);
if (!masters.SetEquals(new[] { "Skyrim.esm", "MMEAlert.esp" })) throw new InvalidDataException("Unexpected UI add-on masters: " + string.Join(",",masters));
if (result.QuestFormVersion != 46 || result.VirtualMachineAdapter!.ExtraBindDataVersion != 2) throw new InvalidDataException("Quest VMAD metadata must match verified MME player-alias layout");
if (!result.Flags.HasFlag(Quest.Flag.StartGameEnabled) || result.Aliases.Single().ForcedReference!.FormKey != player || result.VirtualMachineAdapter!.Aliases.Single().Property.Alias != 0) throw new InvalidDataException("UI quest/player alias bootstrap mismatch");
if (((ScriptObjectProperty)result.VirtualMachineAdapter.Scripts.Single().Properties.Single()).Object.FormKey != controller.FormKey) throw new InvalidDataException("Core binding mismatch");
Console.WriteLine("PASS: ESL-flagged owned UI quest; player-load alias; only Skyrim.esm + MMEAlert.esp masters; core untouched.");

