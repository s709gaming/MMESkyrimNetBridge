#include "NarrationStore.h"
#include "../include/NarrationCatalog.h"

#include <Windows.h>
#include <bcrypt.h>
#include <fstream>
#include <set>
#include <vector>
#include <algorithm>
#include <cctype>
#include <stdexcept>

namespace MME::Narration
{
    using Json = nlohmann::json;
    namespace
    {
        constexpr auto kEntry = "Lore.milk_lore";
        struct ValidationError : std::runtime_error { using std::runtime_error::runtime_error; };
        struct BusyError : std::runtime_error { using std::runtime_error::runtime_error; };
        struct Handle
        {
            HANDLE value{ INVALID_HANDLE_VALUE };
            ~Handle() { if (value && value != INVALID_HANDLE_VALUE) CloseHandle(value); }
        };
        struct FileLock
        {
            Handle handle;
            explicit FileLock(const std::filesystem::path& path)
            {
                handle.value = CreateFileW(path.c_str(), GENERIC_READ | GENERIC_WRITE, 0,
                    nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
                if (handle.value == INVALID_HANDLE_VALUE) {
                    const auto error = GetLastError();
                    if (error == ERROR_SHARING_VIOLATION) throw BusyError("Another editor owns this profile. Try Reload Saved shortly.");
                    throw std::runtime_error("Profile lock cannot be opened; Windows error " + std::to_string(error) + ".");
                }
            }
        };
        std::string Read(const std::filesystem::path& path)
        {
            const auto size = std::filesystem::file_size(path);
            if (size > kMaxDocumentBytes) throw std::runtime_error("JSON file exceeds 256 KiB.");
            std::ifstream stream(path, std::ios::binary);
            if (!stream) throw std::runtime_error("Cannot open JSON file for reading.");
            std::string bytes(static_cast<std::size_t>(size), '\0');
            stream.read(bytes.data(), static_cast<std::streamsize>(bytes.size()));
            if (!stream || stream.peek() != std::char_traits<char>::eof())
                throw std::runtime_error("JSON changed or could not be read completely.");
            return bytes;
        }
        Json Parse(std::string_view bytes)
        {
            std::vector<std::set<std::string>> keys;
            return Json::parse(bytes, [&](int depth, Json::parse_event_t event, Json& value) {
                if (depth > 32) throw std::runtime_error("JSON nesting is too deep.");
                if (event == Json::parse_event_t::object_start) keys.emplace_back();
                if (keys.size() > 32) throw std::runtime_error("JSON nesting is too deep.");
                if (event == Json::parse_event_t::key && !keys.back().insert(value.get<std::string>()).second)
                    throw std::runtime_error("Duplicate JSON key.");
                if (event == Json::parse_event_t::object_end) keys.pop_back();
                return true;
            });
        }
        const Json& CatalogRoot()
        {
            static const auto catalog = [] { std::string bytes; for (auto part : kCatalogParts) bytes += part; return Json::parse(bytes); }();
            return catalog;
        }
        const Json& Catalog() { return CatalogRoot()["entries"]; }
        void ValidateString(const Json& text, const Json& meta)
        {
            if (!text.is_string()) throw ValidationError("Template must be a string.");
            const auto& value = text.get_ref<const std::string&>();
            if (value.size() > kMaxTextBytes || value.find_first_not_of(" \t\r\n") == std::string::npos)
                throw ValidationError("Enter nonblank text of at most 8192 UTF-8 bytes per variant.");
            for (unsigned char ch : value)
                if (ch < 32 && ch != '\t' && ch != '\r' && ch != '\n')
                    throw ValidationError("Unsupported control character in template.");
            std::set<std::string> seen;
            for (std::size_t i = 0; i < value.size(); ++i) {
                if (value[i] == '}') throw ValidationError("Unmatched closing brace.");
                if (value[i] != '{') continue;
                const auto end = value.find('}', i + 1);
                if (end == std::string::npos) throw ValidationError("Unclosed placeholder.");
                auto token = value.substr(i + 1, end - i - 1);
                if (meta.value("aliases", false) && (token == "ACTOR" || token == "ActorName")) token = "actor";
                const auto& allowed = meta["allowed"];
                if (std::find(allowed.begin(), allowed.end(), token) == allowed.end())
                    throw ValidationError("Unsupported placeholder; use only the documented tokens.");
                seen.insert(token); i = end;
            }
            for (const auto& token : meta["required"])
                if (!seen.contains(token.get<std::string>())) throw ValidationError("Missing required placeholder: " + token.get<std::string>());
        }
        void ValidateValue(const Json& value, const Json& meta)
        {
            if (value.is_array()) {
                if (value.empty() || value.size() > 64) throw ValidationError("Pools need 1 to 64 variants.");
                for (const auto& variant : value) ValidateString(variant, meta);
            } else {
                if (meta.value("poolOnly", false)) throw ValidationError("This entry requires a variant array.");
                ValidateString(value, meta);
            }
        }
        void Validate(const Json& document)
        {
            if (!document.is_object() || document.value("schemaVersion", 0) != 1 ||
                document.value("profileId", std::string{}) != "default" ||
                !document.contains("overrides") || !document["overrides"].is_object())
                throw ValidationError("Unsupported personal override format; original file preserved.");
            for (const auto& [id, entry] : document["overrides"].items()) {
                if (!Catalog().contains(id)) continue; // Preserve future/third-party entries.
                if (!entry.is_object() || !entry.contains("template")) throw ValidationError("Missing template: " + id);
                try { ValidateValue(entry["template"], Catalog()[id]); }
                catch (const ValidationError& error) { throw ValidationError(id + ": " + error.what()); }
            }
        }
        std::string Hash(std::string_view value)
        {
            BCRYPT_ALG_HANDLE algorithm{};
            if (BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_SHA256_ALGORITHM, nullptr, 0) < 0)
                throw std::runtime_error("Cannot initialize revision hashing.");
            unsigned char digest[32]{};
            BCRYPT_HASH_HANDLE hash{};
            auto result = BCryptCreateHash(algorithm, &hash, nullptr, 0, nullptr, 0, 0);
            if (result >= 0) result = BCryptHashData(hash,
                reinterpret_cast<PUCHAR>(const_cast<char*>(value.data())), static_cast<ULONG>(value.size()), 0);
            if (result >= 0) result = BCryptFinishHash(hash, digest, sizeof(digest), 0);
            if (hash) BCryptDestroyHash(hash);
            BCryptCloseAlgorithmProvider(algorithm, 0);
            if (result < 0) throw std::runtime_error("Cannot hash profile revision.");
            return Encode(std::string_view(reinterpret_cast<const char*>(digest), sizeof(digest)));
        }
    }

    std::string Encode(std::string_view bytes)
    {
        constexpr char digits[] = "0123456789abcdef";
        std::string result; result.reserve(bytes.size() * 2);
        for (unsigned char ch : bytes) { result += digits[ch >> 4]; result += digits[ch & 15]; }
        return result;
    }
    std::string Decode(std::string_view hex)
    {
        if (hex.size() > kMaxDocumentBytes * 2 || hex.size() % 2)
            throw std::runtime_error("Invalid encoded request size.");
        auto nibble = [](char ch) -> unsigned char {
            if (ch >= '0' && ch <= '9') return static_cast<unsigned char>(ch - '0');
            if (ch >= 'a' && ch <= 'f') return static_cast<unsigned char>(ch - 'a' + 10);
            throw std::runtime_error("Invalid encoded request.");
        };
        std::string result; result.reserve(hex.size() / 2);
        for (std::size_t i = 0; i < hex.size(); i += 2)
            result += static_cast<char>((nibble(hex[i]) << 4) | nibble(hex[i + 1]));
        return result;
    }
    Store::Store(std::filesystem::path root, std::filesystem::path defaults, std::string fallback) :
        root_(std::move(root)), defaults_(std::move(defaults)), fallback_(std::move(fallback))
    {
        // Construct the immutable catalog before this store (and its worker) registers a destructor.
        // It must outlive any pending worker shutdown, not be destroyed ahead of it.
        (void)Catalog();
    }

    Json Store::ReadDocument()
    {
        const auto path = root_ / "overrides.json";
        if (!std::filesystem::exists(path))
            return Json{ { "schemaVersion", 1 }, { "profileId", "default" }, { "overrides", Json::object() } };
        try { auto document = Parse(Read(path)); Validate(document); return document; }
        catch (const std::exception&) { throw std::runtime_error("Personal overrides are invalid or unreadable; file preserved. Restore the backup or repair the JSON."); }
    }
    Json Store::Bases()
    {
        Json values = Json::object();
        std::map<std::filesystem::path, Json> files;
        for (const auto& [id, meta] : Catalog().items()) {
            Json value = meta.value("optionalTier", false) ? Json(nullptr) : (id == kEntry ? Json(fallback_) : meta["default"]);
            const auto path = id == kEntry ? defaults_ : defaults_.parent_path().parent_path() / meta["file"].get<std::string>();
            try {
                if (!files.contains(path)) files[path] = Parse(Read(path));
                auto candidate = files[path];
                if (id.rfind("Pools.", 0) != 0 && candidate.value("schemaVersion", 0) != 1)
                    throw ValidationError("Unsupported base schema.");
                for (const auto& key : meta["path"]) candidate = candidate.at(key.get<std::string>());
                ValidateValue(candidate, meta); value = std::move(candidate);
            } catch (const std::exception&) { /* Compiled authored fallback; base files remain read-only. */ }
            values[id] = std::move(value);
        }
        return values;
    }
    Json Store::Snapshot(const Json& document, const Json& bases)
    {
        const bool customized = document["overrides"].contains(kEntry);
        const auto path = (root_ / "overrides.json").u8string();
        return Json{ { "ok", true }, { "protocolVersion", 2 }, { "entryId", kEntry }, { "profileId", "default" },
            { "revision", Hash(document.dump() + "\n" + bases.dump() + "\n" + Catalog().dump()) }, { "customized", customized },
            { "text", customized ? document["overrides"][kEntry]["template"] : bases[kEntry] },
            { "baseText", bases[kEntry] }, { "path", std::string(path.begin(), path.end()) }, { "maxBytes", kMaxTextBytes },
            { "documentBytes", document.dump(2).size() + 1 },
            { "maxDocumentBytes", kMaxDocumentBytes } };
    }
    Json Store::Effective(const Json& document, const Json& bases, const std::string& id, bool ignoreOwn)
    {
        const auto& meta = Catalog().at(id);
        Json result;
        if (!ignoreOwn && document["overrides"].contains(id)) result = document["overrides"][id]["template"];
        else if (!bases[id].is_null()) result = bases[id];
        else if (meta.contains("fallbackEntry")) result = Effective(document,bases,meta["fallbackEntry"].get<std::string>(),false);
        else result = meta["default"];
        if (meta.value("poolOnly",false) && result.is_string()) result = Json::array({result});
        return result;
    }
    void Store::Publish(const Json& document, const Json& bases, std::string revision)
    {
        auto snapshot = document["overrides"];
        for (const auto& [id,meta] : Catalog().items())
            if (meta.value("optionalTier",false)) snapshot[id]["template"] = Effective(document,bases,id,false);
        std::scoped_lock snapshotLock(snapshotMutex_);
        published_ = std::move(snapshot); revision_ = std::move(revision);
        failure_.clear(); runtimeFailure_.clear();
    }
    std::string Store::Reply(Json reply, const std::string& client)
    {
        const auto encoded = Encode(reply.dump());
        if (encoded.size() <= 8192) return encoded;
        const auto id = reply.value("requestId", std::string("0"));
        const auto key = client + ":" + id;
        if (downloads_.size() >= 8 && !downloads_.contains(key)) throw ValidationError("Too many pending responses; reopen the editor.");
        downloads_[key] = { encoded, 0, (encoded.size() + 4095) / 4096, std::chrono::steady_clock::now() };
        Json header{{"ok",true},{"transport","download"},{"requestId",id},{"total",downloads_[key].total}};
        for (const auto* field : {"operation", "changedCount", "revision"}) if (reply.contains(field)) header[field] = reply[field];
        return Encode(header.dump());
    }
    void Store::Commit(const Json& document)
    {
        const auto bytes = document.dump(2) + "\n";
        if (bytes.size() > kMaxDocumentBytes) throw std::runtime_error("Personal override file exceeds 256 KiB.");
        const auto target = root_ / "overrides.json";
        const auto temp = root_ / "overrides.pending.json";
        const auto backup = root_ / "overrides.previous.json";
        {
            Handle file;
            file.value = CreateFileW(temp.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
            if (file.value == INVALID_HANDLE_VALUE) throw std::runtime_error("Cannot create temporary override file; Windows error " + std::to_string(GetLastError()) + ".");
            DWORD written{};
            if (!WriteFile(file.value, bytes.data(), static_cast<DWORD>(bytes.size()), &written, nullptr) ||
                written != bytes.size() || !FlushFileBuffers(file.value))
                throw std::runtime_error("Cannot write/flush personal overrides; Windows error " + std::to_string(GetLastError()) + "; previous committed file retained.");
        }
        const auto readback = Read(temp);
        Validate(Parse(readback));
        if (readback != bytes) throw std::runtime_error("Temporary override readback did not match.");
        if (std::filesystem::exists(target)) {
            // Copy first: ReplaceFile may fail after renaming a file. Keep an independent recovery copy.
            std::filesystem::copy_file(target, backup, std::filesystem::copy_options::overwrite_existing);
            if (!ReplaceFileW(target.c_str(), temp.c_str(), nullptr, 0, nullptr, nullptr))
                throw std::runtime_error("Override replacement failed; Windows error " + std::to_string(GetLastError()) + "; recover from overrides.previous.json.");
        } else if (!MoveFileExW(temp.c_str(), target.c_str(), MOVEFILE_WRITE_THROUGH)) {
            throw std::runtime_error("Cannot commit first personal override file; Windows error " + std::to_string(GetLastError()) + ".");
        }
        if (Read(target) != bytes) throw std::runtime_error("Committed override readback failed; backup retained.");
    }
    std::string Store::Request(std::string_view encodedRequest, std::string_view clientId) noexcept
    {
        std::scoped_lock lock(mutex_);
        const std::string client(clientId);
        std::string requestId;
        std::string operation = "unknown";
        failure_.clear();
        auto errorReply = [&](const char* kind, const std::string& message) {
            return Encode(Json{{"ok",false},{"operation",operation},{"kind",kind},{"requestId",requestId},{"message",message}}.dump());
        };
        try {
            const auto now = std::chrono::steady_clock::now();
            std::erase_if(uploads_, [&](const auto& row) { return now - row.second.time > std::chrono::minutes(2); });
            std::erase_if(downloads_, [&](const auto& row) { return now - row.second.time > std::chrono::minutes(2); });
            auto request = Parse(Decode(encodedRequest));
            requestId = request.value("requestId", std::string{});
            if (requestId.size() > 64 || requestId.find_first_not_of("0123456789") != std::string::npos)
                throw ValidationError("Invalid request ID.");
            operation = request.at("operation").get<std::string>();
            const auto transferKey = client + ":" + requestId;
            if (operation == "download") {
                auto it = downloads_.find(transferKey);
                if (it == downloads_.end()) throw ValidationError("Response expired; reload before retrying.");
                auto& transfer = it->second;
                const auto index = request.at("index").get<std::size_t>();
                if (index != transfer.next || index >= transfer.total) throw ValidationError("Response chunk order mismatch.");
                Json part{{"ok",true},{"transport","part"},{"requestId",requestId},{"index",index},
                    {"total",transfer.total},{"data",transfer.data.substr(index * 4096, 4096)}};
                transfer.time = now; ++transfer.next;
                if (transfer.next == transfer.total) downloads_.erase(it);
                return Encode(part.dump());
            }
            if (operation == "upload") {
                const auto index = request.at("index").get<std::size_t>();
                const auto total = request.at("total").get<std::size_t>();
                const auto part = request.at("data").get<std::string>();
                if (total == 0 || total > 160 || part.empty() || part.size() > 4096 || part.find_first_not_of("0123456789abcdef") != std::string::npos)
                    throw ValidationError("Invalid upload chunk.");
                if (index == 0) {
                    if (uploads_.size() >= 8 && !uploads_.contains(transferKey)) throw ValidationError("Upload queue is full.");
                    uploads_[transferKey] = { "", 0, total, now };
                }
                auto it = uploads_.find(transferKey);
                if (it == uploads_.end() || it->second.next != index || it->second.total != total)
                    throw ValidationError("Upload chunk order mismatch; nothing committed.");
                auto& transfer = it->second;
                transfer.data += part; transfer.time = now; ++transfer.next;
                if (transfer.data.size() > (kMaxDocumentBytes + 65536) * 2) { uploads_.erase(it); throw ValidationError("Upload is too large."); }
                if (transfer.next < total) return Encode(Json{{"ok",true},{"transport","ack"},{"requestId",requestId},{"index",index}}.dump());
                auto assembled = std::move(transfer.data); uploads_.erase(it);
                request = Parse(Decode(assembled));
                if (request.value("requestId", std::string{}) != requestId) throw ValidationError("Upload request ID mismatch.");
                operation = request.at("operation").get<std::string>();
            }
            const std::set<std::string> operations{"load","refresh","catalog","entry","save","reset","saveBatch","export","presets","importPreview","importApply","capture","legacy"};
            if (!operations.contains(operation)) throw ValidationError("Unsupported editor operation.");
            std::filesystem::create_directories(root_);
            FileLock fileLock(root_ / "profile.lock");
            auto document = ReadDocument();
            const auto bases = Bases();
            auto snapshot = Snapshot(document, bases);
            auto requireRevision = [&] {
                if (request.at("revision") != snapshot["revision"]) throw BusyError("Personal overrides or defaults changed. Reload before saving; draft kept.");
            };
            auto apply = [&](const std::string& id, const Json& value) {
                if (!Catalog().contains(id)) throw ValidationError("Unknown editor entry.");
                if (value.is_null()) document["overrides"].erase(id);
                else {
                    try { ValidateValue(value, Catalog()[id]); }
                    catch (const ValidationError& error) { throw ValidationError(id + ": " + error.what()); }
                    document["overrides"][id]["template"] = value;
                }
            };
            if (operation == "save" || operation == "reset" || operation == "saveBatch") {
                requireRevision();
                if (operation == "saveBatch") {
                    const auto& changes = request.at("changes");
                    if (!changes.is_object() || changes.size() > Catalog().size()) throw ValidationError("Invalid change set.");
                    for (const auto& [id,value] : changes.items()) apply(id,value);
                } else apply(request.at("entryId").get<std::string>(), operation == "reset" ? Json(nullptr) : request.at("text"));
                Validate(document); snapshot = Snapshot(document,bases); Commit(document);
            }
            const auto presetDirectory = root_.parent_path().parent_path() / "presets";
            auto presetPath = [&]() {
                const auto name = request.at("name").get<std::string>();
                if (name.empty() || name.size() > 48 || name.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-") != std::string::npos)
                    throw ValidationError("Use a preset name of 1-48 letters, digits, underscore or hyphen.");
                auto upper = name;
                std::transform(upper.begin(),upper.end(),upper.begin(),[](unsigned char ch) { return static_cast<char>(std::toupper(ch)); });
                if (upper == "CON" || upper == "PRN" || upper == "AUX" || upper == "NUL" ||
                    (upper.size() == 4 && (upper.rfind("COM",0) == 0 || upper.rfind("LPT",0) == 0) && upper[3] >= '1' && upper[3] <= '9'))
                    throw ValidationError("Choose a preset name that is not a Windows device name.");
                return presetDirectory / (name + ".json");
            };
            if (operation == "export") {
                requireRevision(); std::filesystem::create_directories(presetDirectory);
                const auto path = presetPath();
                if (std::filesystem::exists(path)) throw ValidationError("Preset already exists. Choose another name.");
                const auto bytes = document.dump(2) + "\n";
                auto temporary = path; temporary += ".pending";
                Handle file; file.value = CreateFileW(temporary.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
                DWORD written{};
                if (file.value == INVALID_HANDLE_VALUE || !WriteFile(file.value, bytes.data(), static_cast<DWORD>(bytes.size()), &written, nullptr) || written != bytes.size() || !FlushFileBuffers(file.value))
                    throw std::runtime_error("Preset export failed; Windows error " + std::to_string(GetLastError()));
                CloseHandle(file.value); file.value = INVALID_HANDLE_VALUE;
                if (Read(temporary) != bytes) throw std::runtime_error("Preset export readback failed.");
                if (!MoveFileExW(temporary.c_str(),path.c_str(),MOVEFILE_WRITE_THROUGH))
                    throw std::runtime_error("Preset export commit failed; Windows error " + std::to_string(GetLastError()));
            }
            if (operation == "importPreview" || operation == "importApply") {
                auto imported = Parse(Read(presetPath())); Validate(imported);
                const auto presetRevision = Hash(imported.dump());
                if (operation == "importApply") {
                    requireRevision();
                    if (request.at("presetRevision") != presetRevision) throw BusyError("Preset changed after preview. Preview again.");
                    const auto mode = request.value("mode", std::string("merge"));
                    if (mode == "replace") document["overrides"] = imported["overrides"];
                    else if (mode == "merge") {
                        for (const auto& [id,entry] : imported["overrides"].items())
                            if (!document["overrides"].contains(id)) document["overrides"][id] = entry;
                    } else throw ValidationError("Choose merge or replace.");
                    Validate(document); snapshot = Snapshot(document,bases); Commit(document);
                } else {
                    std::size_t conflicts = 0;
                    for (const auto& [id,entry] : imported["overrides"].items())
                        if (document["overrides"].contains(id) && document["overrides"][id] != entry) ++conflicts;
                    snapshot["presetRevision"] = presetRevision; snapshot["entries"] = imported["overrides"].size(); snapshot["conflicts"] = conflicts;
                }
            }
            Publish(document, bases, snapshot["revision"].get<std::string>());
            if (operation == "refresh") { snapshot.erase("text"); snapshot.erase("baseText"); }
            if (operation == "catalog") {
                snapshot.erase("text"); snapshot.erase("baseText"); snapshot["entries"] = Json::array();
                for (const auto& [id,meta] : Catalog().items()) {
                    snapshot["entries"].push_back(Json{{"id",id},{"label",meta["label"]},{"group",meta["group"]},{"family",meta["family"]},
                        {"required",meta["required"]},{"allowed",meta["allowed"]},{"poolOnly",meta["poolOnly"]},
                        {"customized",document["overrides"].contains(id)}});
                }
            } else if (operation == "entry") {
                const auto id = request.at("entryId").get<std::string>();
                if (!Catalog().contains(id)) throw ValidationError("Unknown editor entry.");
                snapshot["entryId"] = id; snapshot["baseValue"] = Effective(document,bases,id,true);
                snapshot["customized"] = document["overrides"].contains(id);
                snapshot["inherited"] = Catalog()[id].value("optionalTier",false) && bases[id].is_null() && !document["overrides"].contains(id);
                snapshot["value"] = Effective(document,bases,id,false);
                snapshot.erase("text"); snapshot.erase("baseText");
            } else if (operation == "presets") {
                snapshot["presets"] = Json::array();
                if (std::filesystem::exists(presetDirectory)) for (const auto& entry : std::filesystem::directory_iterator(presetDirectory))
                    if (entry.is_regular_file() && entry.path().extension() == ".json") {
                        if (snapshot["presets"].size() >= 128) throw ValidationError("Preset list exceeds 128 files; archive unused presets before importing.");
                        snapshot["presets"].push_back(entry.path().stem().string());
                    }
            } else if (operation == "capture") {
                snapshot["changes"] = Json::object();
                for (const auto& [id,meta] : Catalog().items())
                    if (!meta.value("optionalTier",false) && !document["overrides"].contains(id) && bases[id] != meta["default"]) snapshot["changes"][id] = bases[id];
            } else if (operation == "legacy") {
                snapshot["changes"] = Json::object();
                std::size_t skipped = 0;
                for (const auto& mapping : CatalogRoot()["legacy"]) {
                    const auto id = mapping["file"].get<std::string>() + "." + mapping["key"].get<std::string>();
                    if (document["overrides"].contains(id)) continue;
                    try {
                        auto old = Parse(Read(defaults_.parent_path().parent_path() / (mapping["legacyFile"].get<std::string>() + ".json")));
                        const auto key = mapping["legacyKey"].get<std::string>();
                        Json value;
                        if (old.contains(key)) value = old[key];
                        else if (old.contains("stringList") && old["stringList"].contains(key)) value = old["stringList"][key];
                        else value = old.at("string").at(key);
                        ValidateValue(value,Catalog()[id]);
                        if (value != Catalog()[id]["default"]) snapshot["changes"][id] = value;
                    } catch (const std::exception&) { ++skipped; }
                }
                snapshot["skipped"] = skipped;
            }
            snapshot["requestId"] = requestId; snapshot["operation"] = operation;
            snapshot["changedCount"] = request.contains("changes") ? request["changes"].size() : 1;
            snapshot["message"] = operation == "load" || operation == "entry" || operation == "catalog" ? "Loaded committed text." : "Operation completed. Changes are active for subsequent text requests.";
            return Reply(std::move(snapshot),client);
        } catch (const BusyError& error) { return errorReply("conflict",error.what()); }
        catch (const ValidationError& error) { return errorReply("validation",error.what()); }
        catch (const Json::exception&) { return errorReply("validation","Invalid JSON or field type; draft kept."); }
        catch (const std::exception& error) {
            failure_ = error.what();
            { std::scoped_lock snapshotLock(snapshotMutex_); runtimeFailure_ = failure_; }
            return errorReply("failure",failure_);
        }
    }
    std::vector<std::string> Store::Values(std::string_view id)
    {
        std::scoped_lock lock(snapshotMutex_);
        auto it = published_.find(std::string(id));
        if (it == published_.end() || !Catalog().contains(std::string(id))) return {};
        const auto& value = (*it)["template"];
        std::vector<std::string> result{ value.is_array() ? "pool" : "string" };
        if (value.is_array()) for (const auto& text : value) result.push_back(text.get<std::string>());
        else result.push_back(value.get<std::string>());
        return result;
    }
    bool Store::HasPools(std::string_view file)
    {
        std::scoped_lock lock(snapshotMutex_);
        const auto prefix = "Pools." + std::string(file) + ".";
        for (const auto& [id,entry] : published_.items()) if (id.rfind(prefix,0) == 0 && Catalog().contains(id)) return true;
        return false;
    }
    std::string Store::Revision() { std::scoped_lock lock(snapshotMutex_); return revision_; }
    std::string Store::Override() noexcept
    {
        const auto values = Values(kEntry);
        return values.size() > 1 ? values[1] : "";
    }
    std::string Store::Failure() { std::scoped_lock lock(snapshotMutex_); return runtimeFailure_; }
}
