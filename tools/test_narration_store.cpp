#include "../src/NarrationStore.h"
#include <Windows.h>
#include <fstream>
#include <iostream>
#include <stdexcept>

using Json = nlohmann::json;
using MME::Narration::Store;
static void Check(bool value, const char* label) { if (!value) throw std::runtime_error(label); }
static void Write(const std::filesystem::path& path, const std::string& bytes)
{
    std::ofstream output(path, std::ios::binary | std::ios::trunc); output << bytes;
    if (!output) throw std::runtime_error("fixture write failed");
}
static Json Read(const std::filesystem::path& path)
{
    std::ifstream input(path, std::ios::binary); return Json::parse(input);
}
static Json Unpack(Store& store, Json reply, const std::string& client = "test")
{
    if (reply.value("transport", std::string{}) == "download") {
        std::string assembled;
        for (std::size_t index = 0; index < reply["total"].get<std::size_t>(); ++index) {
            const auto part = Json::parse(MME::Narration::Decode(store.Request(MME::Narration::Encode(Json{{"operation","download"},{"requestId",reply["requestId"]},{"index",index}}.dump()),client)));
            Check(part["ok"] == true && part["index"] == index, "ordered download");
            assembled += part["data"].get<std::string>();
        }
        return Json::parse(MME::Narration::Decode(assembled));
    }
    return reply;
}
static Json Call(Store& store, Json request)
{
    request["requestId"] = "1";
    return Unpack(store,Json::parse(MME::Narration::Decode(store.Request(MME::Narration::Encode(request.dump())))));
}
static Json Upload(Store& store, Json request)
{
    request["requestId"] = "42";
    const auto bytes = MME::Narration::Encode(request.dump());
    const auto count = (bytes.size() + 4095) / 4096;
    Json reply;
    for (std::size_t i = 0; i < count; ++i) {
        const auto frame = Json{{"operation","upload"},{"requestId","42"},{"index",i},{"total",count},{"data",bytes.substr(i*4096,4096)}};
        reply = Json::parse(MME::Narration::Decode(store.Request(MME::Narration::Encode(frame.dump()),"large")));
        if (i + 1 < count) Check(reply["transport"] == "ack", "upload chunk acknowledged");
    }
    return Unpack(store,reply,"large");
}
int main(int argc, char** argv)
{
    try {
        if (argc != 2) throw std::runtime_error("pass a new test fixture directory");
        const std::filesystem::path root(argv[1]);
        const auto presetName = "RoundTrip_" + root.filename().string();
        std::filesystem::create_directories(root);
        const auto defaults = root / "MMEAlerts/Narration/Lore.json";
        std::filesystem::create_directories(defaults.parent_path());
        Write(defaults, R"({"schemaVersion":1,"routes":{"milk_lore":{"template":"Default lore."}}})");
        Store store(root / "profile", defaults, "Compiled fallback.");
        auto initial = Call(store, { { "operation", "load" } });
        Check(initial["ok"] == true && initial["text"] == "Default lore.", "initial base");
        Check(!std::filesystem::exists(root / "profile/overrides.json"), "read does not manufacture defaults on disk");
        Check(store.Override().empty(), "no implicit override");
        const std::string custom = "MiLk MAIDS \"snow\" \\ \n\xE9\x9B\xAA \xF0\x9F\x90\xAE";
        auto saved = Call(store, { { "operation", "save" }, { "entryId", "Lore.milk_lore" },
            { "revision", initial["revision"] }, { "text", custom } });
        Check(saved["ok"] == true && store.Override() == custom, "Unicode save/publish");
        Check(Read(root / "profile/overrides.json")["overrides"]["Lore.milk_lore"]["template"] == custom, "disk exact");
        Store restarted(root / "profile", defaults, "Compiled fallback.");
        Check(Call(restarted, { { "operation", "load" } })["ok"] == true, "worker startup reload");
        Check(restarted.Override() == custom, "restart persistence");
        auto conflict = Call(restarted, { { "operation", "save" }, { "entryId", "Lore.milk_lore" },
            { "revision", initial["revision"] }, { "text", "Stale writer" } });
        Check(conflict["kind"] == "conflict" && restarted.Override() == custom, "two-editor conflict");
        auto second = Call(store, { { "operation", "save" }, { "entryId", "Lore.milk_lore" },
            { "revision", saved["revision"] }, { "text", "milk MAIDS" } });
        auto third = Call(store, { { "operation", "save" }, { "entryId", "Lore.milk_lore" },
            { "revision", second["revision"] }, { "text", "MILK maids" } });
        Check(third["ok"] == true && store.Override() == "MILK maids", "case-only edit");
        Check(second["revision"] != third["revision"], "case-sensitive revision");
        Check(Read(root / "profile/overrides.previous.json")["overrides"]["Lore.milk_lore"]["template"] == "milk MAIDS", "backup");
        auto diskBeforeDraft = Read(root / "profile/overrides.json");
        for (const auto& invalid : { Json(""), Json("  "), Json("{unknown}"), Json::array(), Json(std::string(8193, 'x')) }) {
            const auto rejected = Call(store, { { "operation", "save" }, { "entryId", "Lore.milk_lore" },
                { "revision", third["revision"] }, { "text", invalid } });
            Check(rejected["ok"] == false && rejected["kind"] == "validation", "reject invalid user draft");
            Check(store.Failure().empty(), "ordinary validation is not smoke alarm");
            Check(store.Override() == "MILK maids", "validation leaves active unchanged");
            Check(Read(root / "profile/overrides.json") == diskBeforeDraft, "rejected draft never reaches disk");
        }
        // Unknown future dashboard entries must survive an edit to this one field.
        auto document = Read(root / "profile/overrides.json");
        document["overrides"]["Future.entry"]["template"] = "Keep me";
        Write(root / "profile/overrides.json", document.dump());
        auto refreshed = Call(store, { { "operation", "load" } });
        auto reset = Call(store, { { "operation", "reset" }, { "entryId", "Lore.milk_lore" }, { "revision", refreshed["revision"] } });
        Check(reset["ok"] == true && !reset["customized"].get<bool>() && store.Override().empty(), "reset removes override");
        Check(Read(root / "profile/overrides.json")["overrides"].contains("Future.entry"), "unknown entry retained");
        Write(defaults, R"({"schemaVersion":1,"routes":{"milk_lore":{"template":"Updated default."}}})");
        Check(Call(store, { { "operation", "load" } })["text"] == "Updated default.", "base updates apply after reset");
        const auto baseConflict = Call(store, { { "operation", "save" }, { "entryId", "Lore.milk_lore" },
            { "revision", reset["revision"] }, { "text", "Outdated base" } });
        Check(baseConflict["kind"] == "conflict", "default revision conflict");
        auto capture = Call(store,{{"operation","capture"}});
        Check(capture["changes"]["Lore.milk_lore"] == "Updated default.", "capture actual base customizations without writing originals");
        Write(root / "MMEAlerts/TentacleEffectNarration.json",R"({"arousal":["{actor} feels old magic."]})");
        auto legacy = Call(store,{{"operation","legacy"}});
        Check(legacy["changes"].contains("TentacleArmor.effects_arousal"), "explicit legacy capture preview");
        auto catalog = Call(store,{{"operation","catalog"}});
        Check(catalog["entries"].size() == 131, "complete catalog via bounded downloads");
        Json changes = Json::object();
        for (const auto& meta : catalog["entries"]) {
            const auto entry = Call(store,{{"operation","entry"},{"entryId",meta["id"]}});
            Check(entry["ok"] == true, "every entry loads");
            changes[meta["id"].get<std::string>()] = entry["value"];
        }
        auto all = Upload(store,{{"operation","saveBatch"},{"revision",catalog["revision"]},{"changes",changes}});
        Check(all["ok"] == true, "all 131 defaults pass validators and one transaction");
        Check(store.HasPools("Thoughts"), "pool overlay published");
        auto beforeInvalid = Read(root / "profile/overrides.json");
        auto invalidBatch = Call(store,{{"operation","saveBatch"},{"revision",all["revision"]},
            {"changes",Json{{"Lore.milk_lore","Should not be committed"},{"Lore.milkmaid_lore","Missing actor token"}}}});
        Check(invalidBatch["kind"] == "validation" && Read(root / "profile/overrides.json") == beforeInvalid, "all-or-nothing batch validation");
        auto longSave = Upload(store,{{"operation","saveBatch"},{"revision",all["revision"]},
            {"changes",Json{{"Lore.milk_lore",std::string(8000,'x')},{"Pools.Thoughts.armsBound",Json::array({"{actor} first","{actor} first","{actor} last"})}}}});
        Check(longSave["ok"] == true && store.Override().size() == 8000, "long field upload/download roundtrip");
        auto refresh = Json::parse(MME::Narration::Decode(store.Request(MME::Narration::Encode(Json{{"operation","refresh"},{"requestId","0"}}.dump()),"background")));
        Check(refresh["ok"] == true && !refresh.contains("transport"), "background refresh never creates an unconsumed download");
        const auto variants = store.Values("Pools.Thoughts.armsBound");
        Check(variants.size() == 4 && variants[0] == "pool" && variants[1] == variants[2] && variants[3] == "{actor} last", "pool order and duplicate weighting");
        auto exported = Call(store,{{"operation","export"},{"revision",longSave["revision"]},{"name",presetName}});
        Check(exported["ok"] == true, "export committed preset");
        auto preview = Call(store,{{"operation","importPreview"},{"name",presetName}});
        Check(preview["ok"] == true && preview["entries"].get<std::size_t>() >= 131, "preview import including unknown retained entry");
        auto replaced = Call(store,{{"operation","importApply"},{"name",presetName},{"mode","replace"},{"revision",longSave["revision"]},{"presetRevision",preview["presetRevision"]}});
        Check(replaced["ok"] == true && store.Override().size() == 8000, "verified preset replacement");
        auto modified = Call(store,{{"operation","save"},{"entryId","Lore.milk_lore"},{"revision",replaced["revision"]},{"text","Existing personal text"}});
        auto merged = Call(store,{{"operation","importApply"},{"name",presetName},{"mode","merge"},{"revision",modified["revision"]},{"presetRevision",preview["presetRevision"]}});
        Check(merged["ok"] == true && store.Override() == "Existing personal text", "merge retains existing conflicts");
        auto restore = Call(store,{{"operation","importApply"},{"name",presetName},{"mode","replace"},{"revision",merged["revision"]},{"presetRevision",preview["presetRevision"]}});
        Check(restore["ok"] == true && store.Override().size() == 8000, "replace restores committed preset");
        auto invalidName = Call(store,{{"operation","export"},{"revision",restore["revision"]},{"name","NUL"}});
        Check(invalidName["kind"] == "validation", "Windows device names rejected");
        auto lockFrame = Json{{"operation","upload"},{"requestId","51"},{"index",0},{"total",2},{"data","7b"}};
        store.Request(MME::Narration::Encode(lockFrame.dump()),"session-A");
        lockFrame["index"] = 1; lockFrame["data"] = "7d";
        auto crossed = Json::parse(MME::Narration::Decode(store.Request(MME::Narration::Encode(lockFrame.dump()),"session-B")));
        Check(crossed["ok"] == false && store.Override().size() == 8000, "chunk state isolated by game/view/session");
        Write(root / "profile/overrides.json", R"({"schemaVersion":1,"schemaVersion":1,"profileId":"default","overrides":{}})");
        Check(Call(store, { { "operation", "load" } })["ok"] == false, "duplicate key rejected");
        Check(!store.Failure().empty(), "corrupt disk reports failure");
        Write(root / "profile/overrides.json", R"({"schemaVersion":99,"profileId":"default","overrides":{}})");
        Check(Call(store, { { "operation", "load" } })["ok"] == false, "future schema rejected");
        Check(Read(root / "profile/overrides.json")["schemaVersion"] == 99, "future file preserved");
        // Cross-process-style file ownership refuses a concurrent transaction.
        auto lock = CreateFileW((root / "profile/profile.lock").c_str(), GENERIC_READ | GENERIC_WRITE, 0,
            nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        Check(lock != INVALID_HANDLE_VALUE, "fixture profile lock");
        Check(Call(store, { { "operation", "load" } })["ok"] == false, "profile lock respected");
        CloseHandle(lock);
        Write(root / "blocked-root", "not a directory");
        Store blocked(root / "blocked-root", defaults, "Compiled fallback.");
        auto failedWrite = Call(blocked, { { "operation", "load" } });
        Check(failedWrite["ok"] == false && failedWrite["kind"] == "failure", "unwritable root fails safely");
        Store fallback(root / "missing-profile", root / "missing-base.json", "Compiled fallback.");
        Check(Call(fallback, { { "operation", "load" } })["text"] == "Compiled fallback.", "missing-base fallback");
        std::cout << "PASS: native lore store persistence, exact UTF-8/case, conflict, backup/reset, validation, future keys/schema and locking\n";
        return 0;
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
