using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Skyrim;
using Mutagen.Bethesda.Plugins.Records;

if(args.Length!=2) throw new ArgumentException("milk-leak-builder <authored OninusLactis.esp> <repository output esp>");
var source=SkyrimMod.CreateFromBinary(Path.GetFullPath(args[0]), SkyrimRelease.SkyrimSE);
var output=Path.GetFullPath(args[1]);
if(!output.Contains(Path.DirectorySeparatorChar+"fomod"+Path.DirectorySeparatorChar)) throw new Exception("Repository FOMOD output required");
var mod=new SkyrimMod(ModKey.FromNameAndExtension(Path.GetFileName(output)),SkyrimRelease.SkyrimSE);
mod.ModHeader.Flags |= SkyrimModHeader.HeaderFlag.Small;
var original=source.Armors.Single(a=>a.VirtualMachineAdapter?.Scripts.Any(s=>s.Name=="LactisNippleSquirtArmor")==true);
var effects=new List<Armor>();
for(int level=0;level<3;level++) {
    var armor=original.Duplicate(mod.GetNextFormKey());
    armor.EditorID="MMELeakArmor"+level;
    armor.Name="";
    armor.Armature.Clear();
    armor.VirtualMachineAdapter=new VirtualMachineAdapter {Version=5,ObjectFormat=2};
    armor.VirtualMachineAdapter.Scripts.Add(new ScriptEntry {Name="MMELeakVisual"});
    for(int side=0;side<2;side++) {
        var aa=source.ArmorAddons.Single(a=>a.FormKey==original.Armature[side].FormKey).Duplicate(mod.GetNextFormKey());
        aa.EditorID="MMELeakAddon"+level+"_"+side;
        string mesh="OninusLactis/nipplesquirt-"+(side==0?"left":"right")+"-lvl"+(level+1)+".nif";
        if(aa.WorldModel?.Female==null) throw new Exception("Expected female spray model");
        aa.WorldModel.Female.File=mesh;
        if(aa.WorldModel.Male!=null) aa.WorldModel.Male.File=mesh;
        mod.ArmorAddons.Add(aa);
        armor.Armature.Add(aa);
    }
    mod.Armors.Add(armor); effects.Add(armor);
}
var quest=new Quest(mod.GetNextFormKey(),SkyrimRelease.SkyrimSE) {
    EditorID="MMEExt_MilkLeaks",Name="MME Milk Leaks",Flags=Quest.Flag.StartGameEnabled,Priority=10,
    NextAliasID=1,QuestFormVersion=46,
    VirtualMachineAdapter=new QuestAdapter {Version=5,ObjectFormat=2,ExtraBindDataVersion=2}
};
var main=new ScriptEntry {Name="MMEMilkLeaks"};
foreach(var (name,form) in new[]{("LowArmor",effects[0].FormKey),("MediumArmor",effects[1].FormKey),("HighArmor",effects[2].FormKey),("ExternalArmor",original.FormKey)})
    main.Properties.Add(new ScriptObjectProperty{Name=name,Flags=ScriptProperty.Flag.Edited,Object=new FormLink<ISkyrimMajorRecordGetter>(form),Alias=-1});
quest.VirtualMachineAdapter.Scripts.Add(main);
quest.Aliases.Add(new QuestAlias {ID=0,Name="Player",Type=QuestAlias.TypeEnum.Reference,ForcedReference=new FormLinkNullable<IPlacedGetter>(FormKey.Factory("000014:Skyrim.esm"))});
var alias=new QuestFragmentAlias {Version=5,ObjectFormat=2,Property=new ScriptObjectProperty{Object=new FormLink<ISkyrimMajorRecordGetter>(quest.FormKey),Alias=0}};
alias.Scripts.Add(new ScriptEntry{Name="MMELeakPlayerAlias"});
quest.VirtualMachineAdapter.Aliases.Add(alias); mod.Quests.Add(quest);
Directory.CreateDirectory(Path.GetDirectoryName(output)!); mod.WriteToBinary(output);
var check=SkyrimMod.CreateFromBinary(output,SkyrimRelease.SkyrimSE);
if(check.Quests.Single().FormKey.ID!=0x809) throw new Exception("SEQ quest identity changed");
if(check.EnumerateMajorRecords().Any(r=>r.FormKey.ModKey!=mod.ModKey || r.FormKey.ID>0xFFF) || check.Armors.Count!=3 || check.ArmorAddons.Count!=6 || check.Quests.Count!=1)
    throw new Exception("Owned ESL records verification failed");
if(!check.ModHeader.MasterReferences.Select(m=>m.Master.FileName.String).ToHashSet().SetEquals(new[]{"Skyrim.esm","OninusLactis.esp"})) throw new Exception("Unexpected masters");
foreach(var a in check.Armors) if(a.Armature.Any(link=>link.FormKey.ModKey!=mod.ModKey)) throw new Exception("Shared external addon forbidden");
Console.WriteLine("PASS: 3 isolated armors, 6 fixed-intensity addons, load-safe quest; no overrides; source scripts untouched");
