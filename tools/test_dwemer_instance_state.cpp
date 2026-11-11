#include "DwemerAttachmentState.h"
#include <iostream>
#include <cassert>
using namespace MME::DwemerAttachments;
int main(){
 State s;Key a{1,100,1},b{1,100,2},moved{2,100,7};
 assert(s.Install(a,3));assert(!s.Install(a,3));assert(!s.records.contains(b));
 const auto serial=s.records.at(a).serial;
 assert(s.Remap(a,moved)==1);assert(!s.records.contains(a));assert(s.records.at(moved).serial==serial);
 assert(s.Refit(moved,9));assert(s.records.at(moved).fitted==9);assert(!s.Refit(b,9));
 State loaded;assert(loaded.Decode(s.Encode(),[](auto x,auto& y){y=x;return true;})==0);
 assert(loaded.records.at(moved).serial==serial && loaded.records.at(moved).fitted==9);
 State changed;assert(changed.Decode(s.Encode(),[](auto x,auto& y){y=x+1000;return true;})==0);
 assert(changed.records.contains(Key{1002,1100,7}));
 State absent;assert(absent.Decode(s.Encode(),[](auto,auto&){return false;})==1);assert(absent.records.empty());
 assert(s.Install(b,2));assert(s.Remap(moved,b)==3);assert(s.records.empty());
 assert(s.Install(a,1));assert(!s.Remove(b));assert(s.Remove(a));assert(!s.Remove(a));assert(s.Install(a,1));assert(s.records.at(a).serial>serial);assert(s.Remap(a,Key{})==2);assert(s.records.empty());
 assert(!s.Install(Key{},2));assert(!s.Install(a,-1));
 // Actual production name planner: ordinary, custom, protected and externally renamed.
 NameSnapshot plain;LabelState label;
 assert(label.Plan(plain,false,"Clothes"));assert(label.applied=="Clothes (Dwemer)" && !label.previous.present);
 NameSnapshot labelled{true,label.applied,-2,1.0F,static_cast<std::uint16_t>(label.applied.size())};
 assert(label.Matches(labelled));assert(!label.Plan(labelled,false,"Clothes"));assert(label.owns);
 auto renamed=labelled;renamed.text="Player's choice";
 assert(!label.Matches(renamed));assert(!label.Plan(renamed,false,"Clothes"));assert(!label.owns);
 LabelState custom;NameSnapshot customName{true,"My favourite outfit",-2,1.0F,19};
 assert(custom.Plan(customName,false,"Clothes"));assert(custom.applied=="My favourite outfit (Dwemer)");assert(custom.previous.text==customName.text);
 LabelState protectedLabel;assert(!protectedLabel.Plan(customName,true,"Clothes"));assert(!protectedLabel.owns);
 LabelState preexisting;assert(!preexisting.Plan(labelled,false,"Clothes"));assert(!preexisting.owns);
 LabelState unicode;assert(unicode.Plan(plain,false,"\xE8\xA1\xA3\xE6\x9C\x8D"));
 assert(s.Install(a,1));s.records.at(a).label=custom;
 State labelledSave;labelledSave.Decode(s.Encode(),[](auto x,auto& y){y=x;return true;});
 assert(labelledSave.records.at(a).label.applied==custom.applied && labelledSave.records.at(a).label.previous.text==customName.text);
 assert(labelledSave.Remap(a,moved)==1);assert(labelledSave.records.at(moved).label.applied==custom.applied);
 State legacy;legacy.Decode(R"({"next":1,"items":[[1,100,1,1,2]]})",[](auto x,auto& y){y=x;return true;});
 assert(!legacy.records.at(a).label.examined && legacy.records.at(a).serial==1);
 auto badLabel=nlohmann::json::parse(s.Encode());badLabel["items"][0][5]["examined"]=false;badLabel["items"][0][5]["owns"]=true;
 State invalidLabel;try{invalidLabel.Decode(badLabel.dump(),[](auto x,auto& y){y=x;return true;});assert(false);}catch(...){assert(!invalidLabel.usable && invalidLabel.records.empty());}
 for(int category=1;category<=4;++category){
  State mixed;assert(mixed.Install(a,2,category));assert(!mixed.records.contains(b));
  auto& fitted=mixed.records.at(a);assert(fitted.label.Plan(NameSnapshot{},false,"Clothes",category));
  assert(fitted.label.applied=="Clothes"+Suffix(category));
  State restored;restored.Decode(mixed.Encode(),[](auto x,auto& y){y=x;return true;});
  assert(restored.records.at(a).category==category && restored.records.at(a).label.applied==fitted.label.applied);
  assert(restored.Remap(a,moved)==1 && restored.records.at(moved).category==category);
 }
 auto oldTwo=nlohmann::json::parse(s.Encode());for(auto& row:oldTwo["items"])row.erase(row.end()-1);
 State upgradedTwo;upgradedTwo.Decode(oldTwo.dump(),[](auto x,auto& y){y=x;return true;});
 assert(upgradedTwo.records.at(a).category==4 && upgradedTwo.records.at(a).label.applied==s.records.at(a).label.applied);
 State invalidClass;assert(!invalidClass.Install(a,1,0));assert(!invalidClass.Install(a,1,5));
 for(const auto& bad:{std::string("{}"),std::string("garbage"),std::string(R"({"next":1,"items":[[1,100,0,1,0]]})"),std::string(R"({"next":1,"items":[[1,100,1,1,0],[1,100,2,1,0]]})")}){
  State invalid;try{invalid.Decode(bad,[](auto x,auto& y){y=x;return true;});assert(false);}catch(...){assert(!invalid.usable && invalid.records.empty());}
 }
 std::cout<<"PASS: item isolation, install/remove/refit, transfer/remap, stable serials, save/load, corrupt data, naming ownership, custom/player/protected/pre-labelled names, Unicode and version-one migration\n";
}
