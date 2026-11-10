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
 for(const auto& bad:{std::string("{}"),std::string("garbage"),std::string(R"({"next":1,"items":[[1,100,0,1,0]]})"),std::string(R"({"next":1,"items":[[1,100,1,1,0],[1,100,2,1,0]]})")}){
  State invalid;try{invalid.Decode(bad,[](auto x,auto& y){y=x;return true;});assert(false);}catch(...){assert(!invalid.usable && invalid.records.empty());}
 }
 std::cout<<"PASS: physical-copy isolation, install/remove/refit, transfer/remap, stable serials, save/load, load-order resolution, missing forms, corrupt data and collision fail-closed\n";
}
