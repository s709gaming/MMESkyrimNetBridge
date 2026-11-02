#include "../include/Localization.h"
#include "../src/NarrationStore.h"
#include <filesystem>
#include <iostream>

int main(int argc, char** argv) {
    try {
    if (argc != 3) return 2;
    namespace L = MME::Localization;
    namespace fs = std::filesystem;
    const std::string root = std::string(argv[1]) + "/";
    const fs::path fixture = argv[2];
    fs::create_directories(fixture);
    int check = 0;
    auto require = [&](bool ok) { ++check; if (!ok) throw std::runtime_error("Localization test failed at check " + std::to_string(check)); };
    const auto russian = L::Load(root);
    require(russian.language == "ru" && russian.error.empty());
    require(russian.strings.at(L::Fold("General")) == "Общие");
    require(russian.defaults.size() == 185);
    L::Current() = russian;
    MME::Narration::Store store(fixture / "personal", fs::path(root).parent_path().parent_path() / "Narration/Lore.json", "English fallback");
    auto call = [&](nlohmann::json request) {
        request["requestId"] = "1";
        return nlohmann::json::parse(MME::Narration::Decode(store.Request(MME::Narration::Encode(request.dump()))));
    };
    const auto entry = call({{"operation","entry"},{"entryId","Lore.shared_guidance"}});
    if (entry.value("ok",false) != true || entry["baseValue"] != russian.defaults["Lore.shared_guidance"]) std::cerr << entry.dump() << '\n';
    require(entry["ok"] == true && entry["baseValue"] == russian.defaults["Lore.shared_guidance"]);
    const auto saved = call({{"operation","saveBatch"},{"revision",entry["revision"]},{"changes",{{"Lore.shared_guidance","My unchanged personal English text."}}}});
    require(saved["ok"] == true);
    require(call({{"operation","entry"},{"entryId","Lore.shared_guidance"}})["value"] == "My unchanged personal English text.");
    const auto reset = call({{"operation","saveBatch"},{"revision",saved["revision"]},{"changes",{{"Lore.shared_guidance",nullptr}}}});
    require(reset["ok"] == true);
    require(call({{"operation","entry"},{"entryId","Lore.shared_guidance"}})["value"] == russian.defaults["Lore.shared_guidance"]);
    { std::ofstream out(fixture / "Active.json"); out << R"({"schemaVersion":1,"language":"en"})"; }
    const auto english = L::Load(fixture.string() + "/");
    require(english.language == "en" && english.error.empty() && english.strings.empty());
    { std::ofstream out(fixture / "Active.json"); out << R"({"schemaVersion":1,"language":"ru"})"; }
    require(!L::Load(fixture.string() + "/").error.empty());
    fs::copy_file(fs::path(root) / "ru.json", fixture / "ru.json", fs::copy_options::overwrite_existing);
    fs::copy_file(fs::path(root) / "ru.catalog.json", fixture / "ru.catalog.json", fs::copy_options::overwrite_existing);
    auto invalid = L::Read((fixture / "ru.json").string());
    invalid["strings"]["Hello {actor}"] = "Привет";
    { std::ofstream out(fixture / "ru.json"); out << invalid; }
    const auto fallback = L::Load(fixture.string() + "/");
    require(fallback.language == "en" && !fallback.error.empty() && fallback.defaults.empty());
    bool rejected = false;
    try { L::ValidateValue(nlohmann::json::array({"{actor}"}), nlohmann::json::array({"{item}"})); }
    catch (const std::exception&) { rejected = true; }
    require(rejected);
    std::cout << "PASS: Russian load, English option, missing/corrupt data fallback, placeholders and catalog\n";
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
