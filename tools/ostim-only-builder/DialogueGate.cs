using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Plugins.Records;
using Mutagen.Bethesda.Skyrim;

// Repository-only, surgical update. Never supply an installed output path.
static class DialogueGate {
    public static void Check(string input,string mmePath) {
        var mod=SkyrimMod.CreateFromBinary(input,SkyrimRelease.SkyrimSE);
        if(mod.ModKey.FileName.String!="MMEAlert.esp") throw new InvalidDataException("Preserve MMEAlert.esp filename");
        var mme=SkyrimMod.CreateFromBinary(mmePath,SkyrimRelease.SkyrimSE);
        var props=mme.Quests.Single(q=>q.EditorID=="MME_MilkQUEST").VirtualMachineAdapter!.Scripts.Single(s=>s.Name.Equals("MilkQUEST",StringComparison.OrdinalIgnoreCase)).Properties;
        var maid=((ScriptObjectProperty)props.Single(p=>p.Name.Equals("MilkMaidFaction",StringComparison.OrdinalIgnoreCase))).Object.FormKey;
        var slave=((ScriptObjectProperty)props.Single(p=>p.Name.Equals("MilkSlaveFaction",StringComparison.OrdinalIgnoreCase))).Object.FormKey;
        var info=mod.DialogTopics.SelectMany(t=>t.Responses).Single(i=>i.EditorID=="MMEExt_NewMilkMaid");
        if(info.Conditions.Count!=6) throw new InvalidDataException("Expected six conversion conditions");
        foreach(var c in info.Conditions) if(c is not ConditionFloat || c.CompareOperator!=CompareOperator.EqualTo || c.Flags!=0) throw new InvalidDataException("Conversion conditions must be AND/equality constants");
        var gate=(GetGlobalValueConditionData)info.Conditions[0].Data;
        if(gate.Global.Link.FormKey!=new FormKey(mod.ModKey,0x8D0) || ((ConditionFloat)info.Conditions[0]).ComparisonValue!=1) throw new InvalidDataException("Wrong dedicated conversion gate");
        foreach(var name in new[]{"MMEExt_NewMilkMaid","MMEExt_SexLabNewMilkMaid"}) {
            var route=mod.DialogTopics.SelectMany(t=>t.Responses).Single(i=>i.EditorID==name);
            if(route.Conditions[1] is not ConditionFloat c || c.Data is not GetIsSexConditionData sex || sex.MaleFemaleGender!=MaleFemaleGender.Female || sex.RunOnType!=Condition.RunOnType.Subject || c.ComparisonValue!=1) throw new InvalidDataException("Female subject guard changed");
        }
        for(int i=2;i<5;i++) {
            var c=(ConditionFloat)info.Conditions[i]; var d=(GetInFactionConditionData)c.Data;
            if(d.Faction.Link.FormKey!=(i==4?slave:maid) || c.ComparisonValue!=(i==2?1:0) || d.RunOnType!=(i==2?Condition.RunOnType.Reference:Condition.RunOnType.Subject) || (i==2 && d.Reference.FormKey!=FormKey.Factory("000014:Skyrim.esm"))) throw new InvalidDataException("Wrong actor/faction guard");
        }
        if(info.Conditions[5].Data is not IsChildConditionData child || child.RunOnType!=Condition.RunOnType.Subject || ((ConditionFloat)info.Conditions[5]).ComparisonValue!=0) throw new InvalidDataException("Wrong child guard");
        if(!mod.Globals.Any(g=>g.FormKey==gate.Global.Link.FormKey)) throw new InvalidDataException("Missing conversion global");
        if(mod.DialogTopics.SelectMany(t=>t.Responses).Where(i=>i.FormKey!=info.FormKey).Any(i=>i.Conditions.Any(c=>c.Data is GetGlobalValueConditionData g && g.Global.Link.FormKey==gate.Global.Link.FormKey))) throw new InvalidDataException("Dedicated gate leaked into another route");
        Console.WriteLine("PASS: typed conversion gate, player reference, target factions, child exclusion and both female guards.");
    }
    public static void Build(string input, string mmePath, string output) {
        var mod = SkyrimMod.CreateFromBinary(input, SkyrimRelease.SkyrimSE);
        var mme = SkyrimMod.CreateFromBinary(mmePath, SkyrimRelease.SkyrimSE);
        var quest = mme.Quests.Single(q => q.EditorID == "MME_MilkQUEST");
        var script = quest.VirtualMachineAdapter!.Scripts.Single(s => s.Name.Equals("MilkQUEST",StringComparison.OrdinalIgnoreCase));
        FormKey Faction(string name) {
            var prop = (ScriptObjectProperty)script.Properties.Single(p => p.Name.Equals(name,StringComparison.OrdinalIgnoreCase));
            if(!mme.Factions.Any(f => f.FormKey == prop.Object.FormKey)) throw new InvalidDataException("Missing faction: " + name);
            return prop.Object.FormKey;
        }
        var maid = Faction("MilkMaidFaction");
        var slave = Faction("MilkSlaveFaction");
        var key = new FormKey(mod.ModKey, 0x8D0);
        var occupied = mod.EnumerateMajorRecords().SingleOrDefault(r => r.FormKey == key);
        if(occupied != null && occupied.EditorID != "MMEExt_OStimConversionAvailable") throw new InvalidDataException("Gate ID occupied");
        if(occupied == null) mod.Globals.Add(new GlobalFloat(key, SkyrimRelease.SkyrimSE) { EditorID="MMEExt_OStimConversionAvailable", Data=0 });
        var info = mod.DialogTopics.SelectMany(t=>t.Responses).Single(i=>i.FormKey.ID==0x87E && i.EditorID=="MMEExt_NewMilkMaid");
        if(info.Conditions.Count!=2 && info.Conditions.Count!=6) throw new InvalidDataException("Unexpected existing conditions; refusing to discard user edits");
        if(info.Conditions.Count==6) Check(input,mmePath);
        // Retain existing female/backend conditions and every fragment/link.
        var originalGate = info.Conditions.Single(c=>c.Data is GetGlobalValueConditionData);
        var gateData = (GetGlobalValueConditionData)originalGate.Data;
        if(gateData.Global.Link.FormKey.ID != 0x85A && gateData.Global.Link.FormKey != key) throw new InvalidDataException("Unexpected gate");
        gateData.Global.Link.SetTo(key);
        // Idempotent regeneration of only our four eligibility conditions.
        foreach(var c in info.Conditions.Where(c=>c.Data is GetInFactionConditionData || c.Data is IsChildConditionData).ToArray()) info.Conditions.Remove(c);
        void InFaction(FormKey faction, bool player, float expected) {
            var data = new GetInFactionConditionData { RunOnType=player ? Condition.RunOnType.Reference : Condition.RunOnType.Subject };
            data.Faction.Link.SetTo(faction);
            if(player) data.Reference.SetTo(FormKey.Factory("000014:Skyrim.esm"));
            info.Conditions.Add(new ConditionFloat { CompareOperator=CompareOperator.EqualTo, ComparisonValue=expected, Data=data });
        }
        InFaction(maid,true,1);
        InFaction(maid,false,0);
        InFaction(slave,false,0);
        info.Conditions.Add(new ConditionFloat { CompareOperator=CompareOperator.EqualTo, ComparisonValue=0, Data=new IsChildConditionData { RunOnType=Condition.RunOnType.Subject } });
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(output))!);
        mod.WriteToBinary(output, new Mutagen.Bethesda.Plugins.Binary.Parameters.BinaryWriteParameters {
            MastersListContent=Mutagen.Bethesda.Plugins.Binary.Parameters.MastersListContentOption.NoCheck
        });
        var check = SkyrimMod.CreateFromBinary(output,SkyrimRelease.SkyrimSE);
        var result=check.DialogTopics.SelectMany(t=>t.Responses).Single(i=>i.FormKey==info.FormKey);
        if(result.Conditions.Count!=6 || result.Conditions.Count(c=>c.Data is GetIsSexConditionData)!=1 ||
           result.Conditions.Count(c=>c.Data is GetInFactionConditionData)!=3 ||
           !check.Globals.Any(g=>g.FormKey==key)) throw new InvalidDataException("Dialogue roundtrip failed");
        Console.WriteLine($"Verified conversion gate {key}; source faction {maid}; target exclusions {maid}, {slave}; female and child guards retained.");
        Check(output,mmePath);
    }
}

