#pragma once
#include <nlohmann/json.hpp>
#include <map>
#include <set>
#include <cstdint>
#include <compare>
#include <stdexcept>
#include <string>
#include <limits>
namespace MME::DwemerAttachments {
struct Key {
 std::uint32_t context=0,armor=0;std::uint16_t uid=0;
 auto operator<=>(const Key&) const = default;
 bool Valid() const {return context && armor && uid;}
 std::string Text() const {return std::to_string(context)+":"+std::to_string(armor)+":"+std::to_string(uid);}
};
struct Attachment {std::uint64_t serial=0;int fitted=0;};
struct State {
 std::map<Key,Attachment> records;
 std::uint64_t nextSerial=0;
 bool usable=true;
 bool Install(Key key,int level) {
  if(records.size()>=10000 || !usable || !key.Valid() || level<0 || records.contains(key) || nextSerial==(std::numeric_limits<std::uint64_t>::max)()) return false;
  records.emplace(key,Attachment{++nextSerial,level});return true;
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
  for(const auto& [k,r]:records) rows.push_back({k.context,k.armor,k.uid,r.serial,r.fitted});
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
    if(!row.is_array() || row.size()!=5)throw std::runtime_error("invalid identity");
    Key k;auto context=row[0].get<std::uint32_t>(),armor=row[1].get<std::uint32_t>();const auto uid=row[2].get<std::uint32_t>();
    const auto serial=row[3].get<std::uint64_t>();const auto fitted=row[4].get<int>();
    if(!uid || uid>65535 || !serial || serial>candidate.nextSerial || fitted<0 || !serials.insert(serial).second)throw std::runtime_error("invalid metadata");
    if(!resolve(context,k.context) || !resolve(armor,k.armor)){++missing;continue;}
    k.uid=static_cast<std::uint16_t>(uid);
    if(!k.Valid() || !candidate.records.emplace(k,Attachment{serial,fitted}).second)throw std::runtime_error("duplicate identity");
   }
   *this=std::move(candidate);return missing;
  }catch(...){records.clear();usable=false;throw;}
 }
};
}
