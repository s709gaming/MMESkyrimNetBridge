using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins.Records;
using Mutagen.Bethesda.Skyrim;
if(args.Length!=2) throw new ArgumentException("builder <repository input> <review output>");
var input=Path.GetFullPath(args[0]);var output=Path.GetFullPath(args[1]);
if(input==output) throw new ArgumentException("Separate output required");
var mod=SkyrimMod.CreateFromBinary(input,SkyrimRelease.SkyrimSE);
var original=mod.EnumerateMajorRecords().ToDictionary(r=>r.FormKey,r=>r);
var prompts=new Dictionary<string,string>{
 ["MME_BF_PlayerDrinksConfirm"]="Drink milk directly from this character's breast?",
 ["MME_BF_PlayerProvidesConfirm"]="Allow this character to drink directly from your breast?"
};
foreach(var (id,text) in prompts){
 var message=mod.Messages.SingleOrDefault(m=>m.EditorID==id);
 if(message==null){message=new Message(mod.GetNextFormKey(),SkyrimRelease.SkyrimSE){EditorID=id};mod.Messages.Add(message);}
 message.Description=text;message.Flags=Message.Flag.MessageBox;
 message.MenuButtons.Clear();message.MenuButtons.Add(new MessageButton{Text="Yes"});message.MenuButtons.Add(new MessageButton{Text="No"});
 Console.WriteLine($"{id}={message.FormKey.ID:X6}");
}
Directory.CreateDirectory(Path.GetDirectoryName(output)!);
mod.WriteToBinary(output,new Mutagen.Bethesda.Plugins.Binary.Parameters.BinaryWriteParameters{MastersListContent=Mutagen.Bethesda.Plugins.Binary.Parameters.MastersListContentOption.NoCheck,MastersListOrdering=Mutagen.Bethesda.Plugins.Binary.Parameters.MastersListOrderingOption.NoCheck});
var check=SkyrimMod.CreateFromBinary(output,SkyrimRelease.SkyrimSE);
var records=check.EnumerateMajorRecords().ToDictionary(r=>r.FormKey);
foreach(var (key,value) in original) if(!value.Equals(records[key]))throw new Exception($"Existing record changed: {key}");
if(records.Count!=original.Count+2)throw new Exception("Expected exactly two new records");
if(!mod.ModHeader.MasterReferences.SequenceEqual(check.ModHeader.MasterReferences))throw new Exception("Masters changed");
foreach(var message in check.Messages.Where(m=>prompts.ContainsKey(m.EditorID??""))){
 if(message.Flags!=Message.Flag.MessageBox || message.MenuButtons.Count!=2 || message.MenuButtons[0].Text?.String!="Yes" || message.MenuButtons[1].Text?.String!="No")throw new Exception("Invalid buttons");
}
Console.WriteLine("PASS: original records preserved; two Yes/No messages added; masters unchanged");
