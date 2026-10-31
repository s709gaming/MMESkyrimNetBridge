#pragma once

#include <filesystem>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <vector>
#include <map>
#include <chrono>
#include <nlohmann/json.hpp>

// No game/VM dependencies. One store/transaction implementation for future UIs.
namespace MME::Narration
{
    constexpr std::size_t kMaxTextBytes = 8192;
    constexpr std::size_t kMaxDocumentBytes = 262144;
    std::string Encode(std::string_view bytes);
    std::string Decode(std::string_view hex);

    class Store
    {
    public:
        Store(std::filesystem::path root, std::filesystem::path defaults, std::string fallback);
        // Requests/replies are hex-encoded UTF-8 JSON before crossing Papyrus.
        std::string Request(std::string_view encodedRequest, std::string_view client = "test") noexcept;
        std::string Override() noexcept;
        std::vector<std::string> Values(std::string_view id);
        bool HasPools(std::string_view file);
        std::string Revision();
        std::string Failure();
    private:
        nlohmann::json ReadDocument();
        nlohmann::json Bases();
        nlohmann::json Snapshot(const nlohmann::json& document, const nlohmann::json& bases);
        std::string Reply(nlohmann::json reply, const std::string& client);
        void Commit(const nlohmann::json& document);
        nlohmann::json Effective(const nlohmann::json& document, const nlohmann::json& bases, const std::string& id, bool ignoreOwn);
        void Publish(const nlohmann::json& document, const nlohmann::json& bases, std::string revision);
        std::filesystem::path root_, defaults_;
        std::string fallback_, failure_;
        std::string runtimeFailure_;
        nlohmann::json published_ = nlohmann::json::object();
        std::string revision_;
        struct Transfer { std::string data; std::size_t next{}; std::size_t total{}; std::chrono::steady_clock::time_point time; };
        std::map<std::string, Transfer> uploads_, downloads_;
        std::mutex mutex_;
        std::mutex snapshotMutex_;
    };
}
