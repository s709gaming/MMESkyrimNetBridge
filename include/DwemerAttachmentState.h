#pragma once
#include <nlohmann/json.hpp>
#include <map>
#include <set>
#include <cstdint>
#include <compare>
#include <stdexcept>
#include <string>
#include <limits>
#include <cmath>
namespace MME::DwemerAttachments {
struct Key {
 std::uint32_t context=0,armor=0;std::uint16_t uid=0;
 auto operator<=>(const Key&) const = default;
 bool Valid() const {return context && armor && uid;}
 std::string Text() const {return std::to_string(context)+":"+std::to_string(armor)+":"+std::to_string(uid);}
};
inline std::string Suffix(int category) {
 switch(category){case 1:return " (Milking)";case 2:return " (Living)";case 3:return " (Tentacle)";default:return " (Dwemer)";}
}
// Pointer-free name ownership. Never infer attachment identity from a suffix.
struct NameSnapshot {
 bool present=false;std::string text;int kind=-1;float temper=1.0F;std::uint16_t length=0;
};
struct LabelState {
 bool examined=false,owns=false;
 NameSnapshot previous;
 std::string applied;
 bool Matches(const NameSnapshot& current) const {return owns && current.present && current.kind==-2 && current.text==applied;}
 bool Plan(const NameSnapshot& current,bool protectedName,const std::string& baseName,int category=4) {
  if(examined) {if(owns && !Matches(current))owns=false;return false;}
  examined=true;
  if(protectedName)return false;
  const auto name=current.present && current.kind==-2?current.text:baseName;
  if(name.empty() || name.size()>4000 || name.ends_with(Suffix(category)))return false;
  previous=current;applied=name+Suffix(category);owns=true;return true;
 }
 nlohmann::json Encode() const {
  return {{"examined",examined},{"owns",owns},{"applied",applied},
   {"previous",{{"present",previous.present},{"text",previous.text},{"kind",previous.kind},{"temper",previous.temper},{"length",previous.length}}}};
 }
 static LabelState Decode(const nlohmann::json& data,int category=4) {
  LabelState s;s.examined=data.at("examined").get<bool>();s.owns=data.at("owns").get<bool>();s.applied=data.at("applied").get<std::string>();
  const auto& p=data.at("previous");s.previous.present=p.at("present").get<bool>();s.previous.text=p.at("text").get<std::string>();
  s.previous.kind=p.at("kind").get<int>();s.previous.temper=p.at("temper").get<float>();
  const auto length=p.at("length").get<unsigned>();
  if(length>65535 || s.previous.text.size()>4096 || s.applied.size()>4096 || !std::isfinite(s.previous.temper) || s.previous.temper<0 ||
   (s.previous.kind!=-1 && s.previous.kind!=-2) || (s.owns && (!s.examined || s.applied.empty() || !s.applied.ends_with(Suffix(category)))))throw std::runtime_error("invalid label metadata");
  s.previous.length=static_cast<std::uint16_t>(length);return s;
 }
};
struct Attachment {std::uint64_t serial=0;int fitted=0;LabelState label;int category=4;};
struct State {
 std::map<Key,Attachment> records;
 std::uint64_t nextSerial=0;
 bool usable=true;
 bool Install(Key key,int level,int category=4) {
  if(category<1 || category>4 || records.size()>=10000 || !usable || !key.Valid() || level<0 || records.contains(key) || nextSerial==(std::numeric_limits<std::uint64_t>::max)()) return false;
  Attachment attachment{++nextSerial,level};attachment.category=category;records.emplace(key,std::move(attachment));return true;
 }
 bool Remove(Key key) {return usable && records.erase(key)>0;}
 bool Refit(Key key,int level) {
  auto found=records.find(key);if(!usable || found==records.end() || level<0)return false;
  found->second.fitted=level;return true;
 }
 // None, moved, invalid identity, collision. A collision never grants another copy.
 int Remap(Key oldKey,Key newKey) {
  if(oldKey==newKey || !records.contains(oldKey))return 0;
  auto node=records.extract(oldKey);node.key()=newKey;
  if(!newKey.Valid())return 2;
  if(!records.insert(std::move(node)).inserted){records.erase(newKey);return 3;}
  return 1;
 }
 std::string Encode() const {
  nlohmann::json rows=nlohmann::json::array();
  for(const auto& [k,r]:records) rows.push_back({k.context,k.armor,k.uid,r.serial,r.fitted,r.label.Encode(),r.category});
  return nlohmann::json{{"valid",usable},{"next",nextSerial},{"items",rows}}.dump();
 }
 template<class Resolve> int Decode(const std::string& text,Resolve resolve) {
  State candidate;int missing=0;
  try {
   const auto document=nlohmann::json::parse(text);
   if(!document.value("valid",true))throw std::runtime_error("registry previously failed validation");
   const auto rows=document.at("items");candidate.nextSerial=document.at("next").get<std::uint64_t>();
   if(!rows.is_array() || rows.size()>10000)throw std::runtime_error("invalid record count");
   std::set<std::uint64_t> serials;
   for(const auto& row:rows) {
    if(!row.is_array() || (row.size()!=5 && row.size()!=6 && row.size()!=7))throw std::runtime_error("invalid identity");
    Key k;auto context=row[0].get<std::uint32_t>(),armor=row[1].get<std::uint32_t>();const auto uid=row[2].get<std::uint32_t>();
    const auto serial=row[3].get<std::uint64_t>();const auto fitted=row[4].get<int>();
    if(!uid || uid>65535 || !serial || serial>candidate.nextSerial || fitted<0 || !serials.insert(serial).second)throw std::runtime_error("invalid metadata");
    if(!resolve(context,k.context) || !resolve(armor,k.armor)){++missing;continue;}
    k.uid=static_cast<std::uint16_t>(uid);
    Attachment attachment{serial,fitted};
    if(row.size()==7)attachment.category=row[6].get<int>();
    if(attachment.category<1 || attachment.category>4)throw std::runtime_error("invalid attachment class");
    if(row.size()>=6)attachment.label=LabelState::Decode(row[5],attachment.category); // version-one rows start unlabelled
    if(!k.Valid() || !candidate.records.emplace(k,std::move(attachment)).second)throw std::runtime_error("duplicate identity");
   }
   *this=std::move(candidate);return missing;
  }catch(...){records.clear();usable=false;throw;}
 }
};
}
