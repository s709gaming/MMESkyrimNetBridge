#include "inja.hpp"
#include <fstream>
#include <iostream>
#include <stdexcept>
using nlohmann::json;
int main(int argc,char** argv){
 try{
  if(argc!=2)throw std::runtime_error("prompt path required");
  std::ifstream input(argv[1]);std::string source((std::istreambuf_iterator<char>(input)),{});
  inja::Environment env;env.set_line_statement("");json actor;bool maid=true;int reads=0;
  env.add_callback("isValidActor",1,[](inja::Arguments&){return true;});
  env.add_callback("mme_milkmaid_prompt_debug",1,[&](inja::Arguments&){return maid?"true":"";});
  env.add_callback("mme_recent_milk_drinker",1,[](inja::Arguments&){return "";});
  env.add_callback("mme_milk_lore_text",1,[](inja::Arguments&){return "Milk Maid lore.";});
  env.add_callback("mme_actor_milk_state",1,[&](inja::Arguments& a){
   if(a[0]->get<int>()!=actor["id"].get<int>())throw std::runtime_error("wrong actor callback");
   return actor["context"];
  });
  env.add_callback("papyrus_util",4,[&](inja::Arguments& a)->json{
   ++reads;if(a[1]->get<int>()!=actor["id"].get<int>())throw std::runtime_error("wrong actor storage read");
   auto fn=a[0]->get<std::string>(),key=a[2]->get<std::string>();
   bool isMax=key=="MME.MilkMaid.MilkMaximum";
   auto name=isMax?"max":"milk";
   if(fn=="GetFloatValue")return actor.contains(name)?actor[name]:*a[3];
   throw std::runtime_error("unexpected storage function");
  });
  env.add_callback("papyrus_util",3,[&](inja::Arguments& a)->json{
   if(a[1]->get<int>()!=actor["id"].get<int>())throw std::runtime_error("wrong actor knownness read");
   if(a[0]->get<std::string>()!="HasFloatValue")throw std::runtime_error("unexpected has function");
   return actor.contains(a[2]->get<std::string>()=="MME.MilkMaid.MilkMaximum"?"max":"milk");
  });
  auto parsed=env.parse(source);
  auto reset=[&](int id){actor={{"id",id},{"milk",0.0},{"max",8.0},{"context",{{"enabled",true},{"milkEnabled",true},{"armorEnabled",true},{"name","NPC "+std::to_string(id)},{"armor","Wearing living armor."},{"leak","No tracked milk-leak effect is active."}}}};};
  auto render=[&](){return env.render(parsed,{{"actorUUID",actor["id"]},{"render_mode","full"}});};
  auto has=[](const std::string&s,const std::string&t){if(s.find(t)==std::string::npos)throw std::runtime_error("missing: "+t+"\n"+s);};
  auto lacks=[](const std::string&s,const std::string&t){if(s.find(t)!=std::string::npos)throw std::runtime_error("unexpected: "+t);};
  reset(1);has(render(),"Milk state: empty.");has(render(),"0.0/8.0 (0.0%)");
  actor["milk"]=0.25;has(render(),"below half full");
  actor["milk"]=4.0;has(render(),"half full (at least 50%, below full)");
  actor["milk"]=7.99;has(render(),"half full (at least 50%, below full)");
  actor["milk"]=8.0;has(render(),"Milk state: full.");
  actor["milk"]=10.0;has(render(),"full and over capacity");has(render(),"125.0%");
  actor["milk"]=0.0;has(render(),"Milk state: empty.");lacks(render(),"Milk state: full.");
  actor.erase("milk");has(render(),"Milk state: unknown");lacks(render(),"Milk state: empty.");
  actor["milk"]=0.0;actor["max"]=0.0;has(render(),"Milk state: unknown");
  actor["max"]=8.0;actor["milk"]=-1.0;has(render(),"Milk state: unknown");
  actor["context"]["milkEnabled"]=false;reads=0;has(render(),"Wearing living armor.");if(reads!=0)throw std::runtime_error("disabled milk read");lacks(render(),"Milk state:");
  actor["context"]["armorEnabled"]=false;lacks(render(),"Wearing living armor.");
  actor["context"]={{"enabled",false}};lacks(render(),"Current MME Status");
  maid=false;lacks(render(),"Current MME Status");maid=true;
  for(auto name:{"Wearing living armor.","Wearing parasite armor.","Wearing milking armor.","Wearing Dwemer milking armor.","Wearing armor with a Dwemer milking attachment."}){reset(2);actor["context"]["armor"]=name;has(render(),name);has(render(),"NPC 2");lacks(render(),"NPC 1");}
  actor["context"]["leak"]="Currently leaking milk: a tracked milk-leak effect is active.";has(render(),"Currently leaking milk");has(render(),"Milk state: empty.");
  actor["context"]["leak"]="Leaking status unavailable; do not assume leaking from fullness.";has(render(),"Leaking status unavailable");
  auto shortText=env.render(parsed,{{"actorUUID",2},{"render_mode","short_inline"}});if(shortText.find("Current MME Status")!=std::string::npos)throw std::runtime_error("unexpected short render");
  std::cout<<"PASS: actual Inja parser/render: player/NPC isolation, threshold edges, full-to-empty freshness, unknown/disabled, four armor families and independent leak facts\n";
 }catch(const std::exception&e){std::cerr<<e.what()<<'\n';return 1;}return 0;
}
