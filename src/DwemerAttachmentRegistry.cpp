#include <SKSE/SKSE.h>
#include <RE/Skyrim.h>
#include <RE/N/NativeFunction.h>
#include <RE/S/SendUIMessage.h>
#include <nlohmann/json.hpp>
#include <map>
#include <set>
#include <mutex>
#include <sstream>
#include "../include/DwemerAttachmentRegistry.h"
#include "../include/DwemerAttachmentState.h"

namespace MME::DwemerAttachments {
namespace {
using ID=RE::FormID;
struct View { ID armor=0; Key key; bool labelPending=false; };
struct Request { ID actor,armor; int op,level; std::string expected,result; std::uint64_t generation; bool trace; int category; };
std::recursive_mutex mutex;
State state;
auto& records=state.records;
auto& nextSerial=state.nextSerial;
std::map<ID,View> views;
std::set<ID> refreshing;
std::map<int,Request> requests;
std::set<std::string> failures;
std::uint64_t generation=0;
int nextRequest=0;
auto& usable=state.usable;
constexpr std::uint32_t signature=0x44454D4D; // MMED; plugin-specific SKSE serialization signature
void Alarm(const std::string& text) {
 if(failures.insert(text).second) SKSE::log::error("[MME Item Attachments] {}",text);
}
void Trace(bool enabled,const std::string& text) { if(enabled) SKSE::log::info("[MME Item Attachments] {}",text); }
// The engine caches temper text inside displayName. Compare only the custom-name
// prefix, so tempering doesn't look like a player rename or duplicate '(Fine)'.
NameSnapshot ReadName(RE::ExtraDataList* list) {
 NameSnapshot snapshot;
 if(auto* text=list->GetByType<RE::ExtraTextDisplayData>()) {
  snapshot.present=true;snapshot.kind=static_cast<int>(text->ownerInstance.underlying());
  const auto* name=text->displayName.c_str();snapshot.text=name?name:"";snapshot.temper=text->temperFactor;snapshot.length=text->customNameLength;
  if(snapshot.kind==-2) {snapshot.text=snapshot.text.substr(0,snapshot.length);snapshot.temper=1.0F;}
 }
 return snapshot;
}
bool ProtectedName(RE::ExtraDataList* list) {
 auto* local=list->GetByType<RE::ExtraTextDisplayData>();
 // Original dropped-reference and quest/alias names have another owner.
 if(list->GetExtraTextDisplayData()!=local)return true;
 return local && (local->ownerQuest || local->displayNameText ||
  (local->ownerInstance.underlying()!=-1 && local->ownerInstance.underlying()!=-2));
}
void NameChanged(RE::Actor* wearer,RE::TESObjectARMO* armor) {
 if(auto* inventory=wearer->GetInventoryChanges())inventory->changed=true;
 wearer->AddChange(RE::TESObjectREFR::ChangeFlags::kInventory | RE::TESObjectREFR::ChangeFlags::kItemExtraData);
 RE::SendUIMessage::SendInventoryUpdateMessage(wearer,armor);
}
std::string Label(RE::Actor* wearer,RE::TESObjectARMO* armor,RE::ExtraDataList* list,Attachment& record,bool trace) {
 auto& label=record.label;const auto before=ReadName(list);const bool protectedName=ProtectedName(list);
 const auto context=" actor="+std::to_string(wearer->GetFormID())+" armor="+std::to_string(armor->GetFormID())+" serial="+std::to_string(record.serial);
 if(protectedName && label.examined)label.owns=false;
 const auto* baseName=armor->GetName();
 if(!label.Plan(before,protectedName,baseName?baseName:"",record.category)) {
  const std::string reason=protectedName?"protected name":label.Matches(before)?"already labelled":"existing/player name preserved";
  Trace(trace,"label skip"+context+" reason="+reason);return "ok|label skipped: "+reason;
 }
 list->SetOverrideName(label.applied.c_str());
 if(!label.Matches(ReadName(list))) {
  // Do not roll back a valid gameplay attachment for a cosmetic failure.
  label=LabelState{};Alarm("label apply readback failed"+context);return "error|label apply readback failed";
 }
 NameChanged(wearer,armor);Trace(trace,"label applied"+context);return "ok|label applied";
}
bool RestoreName(RE::Actor* wearer,RE::TESObjectARMO* armor,RE::ExtraDataList* list,const Attachment& record,bool trace) {
 const auto& label=record.label;
 const auto context=" actor="+std::to_string(wearer->GetFormID())+" armor="+std::to_string(armor->GetFormID())+" serial="+std::to_string(record.serial);
 if(ProtectedName(list) || !label.Matches(ReadName(list))) {Trace(trace,"label removal preserves external/unowned name"+context);return true;}
 if(label.previous.present) {
  auto* text=list->GetByType<RE::ExtraTextDisplayData>();
  text->displayName=label.previous.text;text->ownerInstance=static_cast<RE::ExtraTextDisplayData::DisplayDataType>(label.previous.kind);
  text->temperFactor=label.previous.temper;text->customNameLength=label.previous.length;
 } else if(!list->RemoveByType(RE::ExtraDataType::kTextDisplayData)) {
  Alarm("label restore removal failed"+context);return false;
 }
 NameChanged(wearer,armor);Trace(trace,"label restored"+context);return true;
}
// Only called on the game thread. Never retain inventory pointers across tasks.
View Inspect(RE::Actor* actor,bool assign,RE::ExtraDataList** selectedOut=nullptr) {
 if(selectedOut)*selectedOut=nullptr;
 if(!actor || actor->IsDeleted()) return {};
 auto* armor=actor->GetWornArmor(RE::BIPED_MODEL::BipedObjectSlot::kBody);
 if(!armor) return {};
 auto* inv=actor->GetInventoryChanges();
 if(!inv || !inv->entryList) return {};
 RE::ExtraDataList* selected=nullptr;
 for(auto* entry:*inv->entryList) {
  if(!entry || entry->object!=armor || !entry->extraLists) continue;
  for(auto* list:*entry->extraLists) if(list && list->HasType<RE::ExtraWorn>()) {
   if(selected) return {}; selected=list;
  }
 }
 if(!selected || selected->GetCount()!=1) return {}; // never modify an ambiguous stack
 if(selectedOut)*selectedOut=selected;
 auto* unique=selected->GetByType<RE::ExtraUniqueID>();
 if(!unique && assign) {
  for(std::uint32_t n=0;n<65535;++n) {
   const auto uid=inv->GetNextUniqueID();
   if(!uid || records.contains(Key{actor->GetFormID(),armor->GetFormID(),uid})) continue;
   unique=new RE::ExtraUniqueID(actor->GetFormID(),uid);
   selected->Add(unique);
   inv->changed=true;
   actor->AddChange(RE::TESObjectREFR::ChangeFlags::kInventory | RE::TESObjectREFR::ChangeFlags::kItemExtraData);
   break;
  }
 }
 View view; view.armor=armor->GetFormID();
 if(unique) view.key={unique->baseID,armor->GetFormID(),unique->uniqueID};
 if(const auto r=records.find(view.key);r!=records.end()) {
  const auto& label=r->second.label;
  view.labelPending=!label.examined || (label.owns && (ProtectedName(selected) || !label.Matches(ReadName(selected))));
 }
 return view;
}
void Refresh(ID actorID) {
 const auto epoch=generation;
 if(!refreshing.insert(actorID).second) return;
 SKSE::GetTaskInterface()->AddTask([actorID,epoch]{
  std::scoped_lock lock(mutex);
  if(epoch!=generation) return;
  refreshing.erase(actorID);
  views[actorID]=Inspect(RE::TESForm::LookupByID<RE::Actor>(actorID),false);
 });
}
std::string Identity(RE::StaticFunctionTag*,RE::Actor* actor,RE::TESObjectARMO* armor) {
 if(!actor || !armor) return "";
 std::scoped_lock lock(mutex);
 auto it=views.find(actor->GetFormID());
 if(it==views.end()) { Refresh(actor->GetFormID()); return "?"; }
 if(it->second.armor!=armor->GetFormID()) {views.erase(it);Refresh(actor->GetFormID());return "?";}
 return it->second.key.Valid()?std::to_string(generation)+"/"+it->second.key.Text():"ordinary";
}
bool Has(RE::StaticFunctionTag*,RE::Actor* actor,RE::TESObjectARMO* armor) {
 if(!actor || !armor) return false;
 std::scoped_lock lock(mutex);
 auto it=views.find(actor->GetFormID());
 if(it==views.end()) {Refresh(actor->GetFormID());return false;}
 return usable && it->second.armor==armor->GetFormID() && records.contains(it->second.key) && records.at(it->second.key).category==4;
}
int Fitted(RE::StaticFunctionTag*,RE::Actor* actor,RE::TESObjectARMO* armor) {
 if(!actor || !armor) return -1;
 std::scoped_lock lock(mutex);auto v=views.find(actor->GetFormID());
 if(!usable || v==views.end() || v->second.armor!=armor->GetFormID()) return -1;
 auto r=records.find(v->second.key);return r==records.end()?-1:r->second.fitted;
}
std::string Tag(RE::StaticFunctionTag*,RE::Actor* actor,RE::TESObjectARMO* armor) {
 if(!actor || !armor) return "";
 std::scoped_lock lock(mutex);auto v=views.find(actor->GetFormID());
 if(!usable || v==views.end() || v->second.armor!=armor->GetFormID()) return "";
 auto r=records.find(v->second.key);return r==records.end()?"":std::to_string(r->second.serial);
}
bool LabelPending(RE::StaticFunctionTag*,RE::Actor* actor,RE::TESObjectARMO* armor) {
 if(!actor || !armor)return false;
 std::scoped_lock lock(mutex);const auto view=views.find(actor->GetFormID());
 return usable && view!=views.end() && view->second.armor==armor->GetFormID() && view->second.labelPending;
}
int ItemClass(RE::StaticFunctionTag*,RE::Actor* actor,RE::TESObjectARMO* armor) {
 if(!actor || !armor)return 0;
 std::scoped_lock lock(mutex);const auto id=actor->GetFormID();auto view=views.find(id);
 if(view==views.end() || view->second.armor!=armor->GetFormID()){Refresh(id);return 0;}
 auto found=records.find(view->second.key);
 return usable && found!=records.end()?found->second.category:0;
}
int QueueClass(RE::StaticFunctionTag*,RE::Actor* actor,RE::TESObjectARMO* armor,int op,std::string expected,bool trace,int level,int category) {
 if(!actor || !armor || op < -1 || op > 4 || category<1 || category>4) return -1;
 std::scoped_lock lock(mutex);
 if(requests.size()>=128 || nextRequest==INT_MAX) {Alarm("request capacity exhausted");return -1;}
 const int token=++nextRequest;
 requests.emplace(token,Request{actor->GetFormID(),armor->GetFormID(),op,level,std::move(expected),"",generation,trace,category});
 SKSE::GetTaskInterface()->AddTask([token]{
  std::scoped_lock taskLock(mutex);
  auto it=requests.find(token);
  if(it==requests.end() || it->second.generation!=generation) return;
  auto& r=it->second;
  auto* wearer=RE::TESForm::LookupByID<RE::Actor>(r.actor);
  RE::ExtraDataList* selected=nullptr;
  auto view=Inspect(wearer,r.op==0,&selected);
  auto* item=RE::TESForm::LookupByID<RE::TESObjectARMO>(r.armor);
  views[r.actor]=view;
  if(!usable) r.result="error|registry unavailable";
  else if(!wearer || wearer->IsDead() || view.armor!=r.armor) r.result="skip|worn item changed or unavailable";
  else if(r.op==-1) r.result="ok|"+(view.key.Valid()?std::to_string(generation)+"/"+view.key.Text():std::string("ordinary"));
  else if(!view.key.Valid()) r.result="error|individual worn item could not be identified";
  else if(r.op==0) r.result="ok|"+std::to_string(generation)+"/"+view.key.Text();
  else if(r.expected!=std::to_string(generation)+"/"+view.key.Text()) r.result="skip|individual item changed before commit";
  else if(r.op==1) {
   if(records.contains(view.key)) r.result="skip|attachment already installed";
   else if(nextSerial==UINT64_MAX || r.level<0) r.result="error|invalid installation metadata";
   else if(!state.Install(view.key,r.level,r.category)) r.result="error|registry insertion failed or limit reached";
   else {
    Label(wearer,item,selected,records.at(view.key),r.trace);
    r.result="ok|"+std::to_string(generation)+"/"+view.key.Text();
   }
  } else if(records.contains(view.key) && records.at(view.key).category!=r.category) {
   r.result="skip|attachment belongs to another class";
  } else if(r.op==2) {
   auto found=records.find(view.key);
   if(found==records.end())r.result="skip|attachment not installed on this item";
   else if(!RestoreName(wearer,item,selected,found->second,r.trace))r.result="error|label restoration failed; attachment retained";
   else {state.Remove(view.key);r.result="ok|"+std::to_string(generation)+"/"+view.key.Text();}
  } else if(r.op==4) {
   auto found=records.find(view.key);
   r.result=found==records.end()?"skip|attachment not installed on this item":Label(wearer,item,selected,found->second,r.trace);
  } else {
   auto found=records.find(view.key);
   if(found==records.end() || r.level<0) r.result="skip|attachment/refit level unavailable";
   else {state.Refit(view.key,r.level);Label(wearer,item,selected,found->second,r.trace);r.result="ok|"+std::to_string(generation)+"/"+view.key.Text();}
  }
  views[r.actor]=Inspect(wearer,false); // label state and cached identity agree after commit
  if(r.result.starts_with("error|")) Alarm("transaction actor="+std::to_string(r.actor)+" armor="+std::to_string(r.armor)+" "+r.result);
  Trace(r.trace,"request="+std::to_string(token)+" actor="+std::to_string(r.actor)+" armor="+std::to_string(r.armor)+" class="+std::to_string(r.category)+" operation="+std::to_string(r.op)+" "+r.result);
 });
 return token;
}
int Queue(RE::StaticFunctionTag* tag,RE::Actor* actor,RE::TESObjectARMO* armor,int op,std::string expected,bool trace,int level) {
 return QueueClass(tag,actor,armor,op,std::move(expected),trace,level,4);
}
std::string Result(RE::StaticFunctionTag*,int token,bool cancel) {
 std::scoped_lock lock(mutex);
 auto it=requests.find(token);
 if(it==requests.end()) return "skip|request superseded";
 if(it->second.result.empty() && !cancel) return "";
 auto result=it->second.result.empty()?std::string("error|request cancelled before execution"):it->second.result;
 requests.erase(it);return result;
}
void Clear() {
 std::scoped_lock lock(mutex);++generation;records.clear();nextSerial=0;views.clear();refreshing.clear();requests.clear();failures.clear();usable=true;
}
void Save(SKSE::SerializationInterface* io) {
 std::scoped_lock lock(mutex);
 const auto text=state.Encode();
 if(text.size()>4*1024*1024 || !io->WriteRecord(signature,3,text.data(),static_cast<std::uint32_t>(text.size()))) Alarm("save failed for attachment registry");
}
void Load(SKSE::SerializationInterface* io) {
 Clear();std::scoped_lock lock(mutex);
 std::uint32_t type=0,version=0,size=0;
 while(io->GetNextRecordInfo(type,version,size)) {
  if(type!=signature) continue;
  if((version!=1 && version!=2 && version!=3) || size>4*1024*1024) {usable=false;Alarm("unsupported or oversized attachment save record");continue;}
  std::string text(size,'\0');
  if(io->ReadRecordData(text.data(),size)!=size) {usable=false;Alarm("truncated attachment save record");continue;}
  try {
   const auto missing=state.Decode(text,[io](ID oldID,ID& newID){return io->ResolveFormID(oldID,newID);});
   if(missing) Alarm("saved attachments reference unavailable forms; unresolved items skipped");
  } catch(const std::exception& e) {records.clear();usable=false;Alarm(std::string("attachment load failed: ")+e.what());}
 }
}
class Events final:public RE::BSTEventSink<RE::TESFormDeleteEvent>,public RE::BSTEventSink<RE::TESEquipEvent>,public RE::BSTEventSink<RE::TESUniqueIDChangeEvent>,public RE::BSTEventSink<RE::TESContainerChangedEvent> {
 public:
 RE::BSEventNotifyControl ProcessEvent(const RE::TESFormDeleteEvent* e,RE::BSTEventSource<RE::TESFormDeleteEvent>*) override {
  if(e) {std::scoped_lock lock(mutex);std::erase_if(records,[e](const auto& row){return row.first.context==e->formID || row.first.armor==e->formID;});views.erase(e->formID);}
  return RE::BSEventNotifyControl::kContinue;
 }
 RE::BSEventNotifyControl ProcessEvent(const RE::TESEquipEvent* e,RE::BSTEventSource<RE::TESEquipEvent>*) override {
  auto* armor=e?RE::TESForm::LookupByID<RE::TESObjectARMO>(e->baseObject):nullptr;
  if(e && e->actor && armor && armor->GetSlotMask().any(RE::BIPED_MODEL::BipedObjectSlot::kBody)) {std::scoped_lock lock(mutex);const auto id=e->actor->GetFormID();views.erase(id);Refresh(id);}
  return RE::BSEventNotifyControl::kContinue;
 }
 RE::BSEventNotifyControl ProcessEvent(const RE::TESUniqueIDChangeEvent* e,RE::BSTEventSource<RE::TESUniqueIDChangeEvent>*) override {
  if(e) {
   std::scoped_lock lock(mutex);
   const Key oldKey{e->oldBaseID,e->objectID,e->oldUniqueID},newKey{e->newBaseID,e->objectID,e->newUniqueID};
   if(oldKey!=newKey && !records.contains(oldKey) && records.contains(newKey)) {records.erase(newKey);Alarm("untracked item collided with an attachment identity; record retired");}
   const int remap=state.Remap(oldKey,newKey);
   if(remap==2) Alarm("tracked item lost a valid engine identity; attachment retired");
   if(remap==3) Alarm("inventory identity remap collision; conflicting attachments retired");
   views.clear(); // ID changes must never leave a cached attachment on the wrong copy.
  }
  return RE::BSEventNotifyControl::kContinue;
 }
 RE::BSEventNotifyControl ProcessEvent(const RE::TESContainerChangedEvent* e,RE::BSTEventSource<RE::TESContainerChangedEvent>*) override {
  auto* armor=e?RE::TESForm::LookupByID<RE::TESObjectARMO>(e->baseObj):nullptr;
  if(e && armor && armor->GetSlotMask().any(RE::BIPED_MODEL::BipedObjectSlot::kBody)) {
   std::scoped_lock lock(mutex);views.erase(e->oldContainer);views.erase(e->newContainer);
   if(e->oldContainer) Refresh(e->oldContainer);if(e->newContainer) Refresh(e->newContainer);
   // No destination and no dropped reference means the item was consumed/deleted.
   if(!e->newContainer && !e->reference && e->uniqueID) records.erase(Key{e->oldContainer,e->baseObj,e->uniqueID});
  }
  return RE::BSEventNotifyControl::kContinue;
 }
};
Events sink;
}
void Cancel(RE::StaticFunctionTag*) {Invalidate();}
void Register(RE::BSScript::IVirtualMachine* vm) {
 vm->RegisterFunction("GetWornItemAttachmentClass","MMEExtensionsNative",ItemClass);
 vm->RegisterFunction("QueueItemAttachment","MMEExtensionsNative",QueueClass);
 vm->RegisterFunction("CancelDwemerRequests","MMEExtensionsNative",Cancel);
 vm->RegisterFunction("GetDwemerAttachmentTag","MMEExtensionsNative",Tag);
 vm->RegisterFunction("DwemerLabelNeedsUpdate","MMEExtensionsNative",LabelPending);
 vm->RegisterFunction("GetDwemerRefitLevel","MMEExtensionsNative",Fitted);
 vm->RegisterFunction("GetDwemerItemIdentity","MMEExtensionsNative",Identity);
 vm->RegisterFunction("HasWornDwemerAttachment","MMEExtensionsNative",Has);
 vm->RegisterFunction("QueueDwemerAttachment","MMEExtensionsNative",Queue);
 vm->RegisterFunction("GetDwemerAttachmentResult","MMEExtensionsNative",Result);
}
void Initialize() {
 auto* io=SKSE::GetSerializationInterface();io->SetUniqueID(signature);io->SetSaveCallback(Save);io->SetLoadCallback(Load);io->SetRevertCallback([](auto*){Clear();});
 auto* holder=RE::ScriptEventSourceHolder::GetSingleton();
 holder->AddEventSink<RE::TESFormDeleteEvent>(&sink);holder->AddEventSink<RE::TESEquipEvent>(&sink);holder->AddEventSink<RE::TESUniqueIDChangeEvent>(&sink);holder->AddEventSink<RE::TESContainerChangedEvent>(&sink);
}
void Invalidate() {std::scoped_lock lock(mutex);++generation;views.clear();refreshing.clear();requests.clear();}
}
