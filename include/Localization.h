#pragma once
#include <nlohmann/json.hpp>
#include <algorithm>
#include <cctype>
#include <fstream>
#include <mutex>
#include <string>
#include <stdexcept>
#include <regex>
#include <vector>
#include "NarrationCatalog.h"
#include <unordered_map>

namespace MME::Localization {
    inline std::vector<std::string> Tokens(const std::string& value) {
        static const std::regex pattern(R"(\{[^{}]+\}|<[^>]+>)");
        std::vector<std::string> result;
        for (auto it = std::sregex_iterator(value.begin(), value.end(), pattern); it != std::sregex_iterator(); ++it) result.push_back(it->str());
        std::sort(result.begin(), result.end());
        return result;
    }
    inline void ValidateValue(const nlohmann::json& english, const nlohmann::json& translated) {
        if (english.type() != translated.type()) throw std::runtime_error("Localized default has the wrong type");
        if (english.is_string()) {
            const auto value = translated.get<std::string>();
            if (value.empty() || Tokens(english.get<std::string>()) != Tokens(value)) throw std::runtime_error("Localized translation has missing or changed placeholders");
        } else if (english.is_array()) {
            if (english.size() != translated.size()) throw std::runtime_error("Localized pool has the wrong size");
            for (std::size_t i = 0; i < english.size(); ++i) ValidateValue(english[i], translated[i]);
        }
    }
    struct Data {
        std::string language{ "en" };
        std::string error;
        std::unordered_map<std::string, std::string> strings;
        nlohmann::json defaults = nlohmann::json::object();
    };
    inline std::string Fold(std::string value) {
        std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
        return value;
    }
    inline nlohmann::json Read(const std::string& path) {
        std::ifstream input(path, std::ios::binary);
        if (!input) throw std::runtime_error("Missing localization file: " + path);
        return nlohmann::json::parse(input);
    }
    inline Data Load(const std::string& root = "Data/SKSE/Plugins/StorageUtilData/MMEAlerts/Localization/") {
        Data data;
        try {
            const auto active = Read(root + "Active.json");
            if (active.value("schemaVersion", 0) != 1) throw std::runtime_error("Unsupported language configuration schema");
            const auto language = active.at("language").get<std::string>();
            if (language == "en") return data;
            if (language != "ru" && language != "zh-CN") throw std::runtime_error("Unsupported MME Extensions language: " + language);
            const auto catalog = Read(root + language + ".json");
            if (catalog.value("schemaVersion", 0) != 1 || !catalog.at("strings").is_object()) throw std::runtime_error("Invalid Localized text catalog");
            for (const auto& [key, value] : catalog.at("strings").items()) {
                if (!value.is_string() || value.get_ref<const std::string&>().empty()) throw std::runtime_error("Invalid Localized translation entry");
                ValidateValue(key, value);
                data.strings.insert_or_assign(Fold(key), value.get<std::string>());
            }
            data.defaults = Read(root + language + ".catalog.json");
            if (!data.defaults.is_object()) throw std::runtime_error("Invalid Localized narration defaults");
            std::string bytes;
            for (auto part : MME::Narration::kCatalogParts) bytes += part;
            const auto entries = nlohmann::json::parse(bytes).at("entries");
            if (entries.size() != data.defaults.size()) throw std::runtime_error("Incomplete Localized narration defaults");
            for (const auto& [id, meta] : entries.items()) ValidateValue(meta.at("default"), data.defaults.at(id));
            data.language = language;
        } catch (const std::exception& error) {
            data = Data{};
            data.error = error.what();
        }
        return data;
    }
    inline std::mutex mutex;
    inline Data& Current() { static Data data = Load(); return data; }
    inline void Reload() { std::scoped_lock lock(mutex); Current() = Load(); }
    inline std::string Language() { std::scoped_lock lock(mutex); return Current().language; }
    inline std::string Error() { std::scoped_lock lock(mutex); return Current().error; }
    inline std::string Text(std::string english) {
        std::scoped_lock lock(mutex);
        const auto& data = Current();
        if (data.language == "en") return english;
        const auto found = data.strings.find(Fold(english));
        return found == data.strings.end() ? std::string{} : found->second;
    }
    inline nlohmann::json Defaults() { std::scoped_lock lock(mutex); return Current().defaults; }
}
