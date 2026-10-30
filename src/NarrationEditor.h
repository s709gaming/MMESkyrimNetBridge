#pragma once
#include "NarrationStore.h"
#include "../include/LoreEditorDefaults.h"
#include <SKSE/SKSE.h>
#include <condition_variable>
#include <deque>
#include <thread>
#include <atomic>

namespace MME::NarrationEditor
{
    inline Narration::Store& GetStore()
    {
        static Narration::Store store([] {
            const auto directory = SKSE::log::log_directory();
            if (!directory) throw std::runtime_error("SKSE user directory is unavailable; personal saving disabled.");
            return *directory / "MMEExtensions" / "Narration" / "profiles" / "default";
        }(), "Data/SKSE/Plugins/StorageUtilData/MMEAlerts/Narration/Lore.json", Narration::kGeneralLoreDefault);
        return store;
    }
    inline std::atomic<std::uint64_t> epoch{ 1 };
    struct Job { std::string payload; std::int32_t generation; std::int32_t view; std::uint64_t epoch; };
    class Worker
    {
    public:
        static Worker& Get() { (void)GetStore(); static Worker worker; return worker; }
        bool Queue(Job job)
        {
            std::scoped_lock lock(mutex_);
            if (jobs_.size() >= 4) return false;
            jobs_.push_back(std::move(job)); condition_.notify_one(); return true;
        }
        ~Worker() { thread_.request_stop(); condition_.notify_all(); }
    private:
        Worker() : thread_([this](std::stop_token stop) { Run(stop); }) {}
        void Run(std::stop_token stop)
        {
            while (!stop.stop_requested()) {
                Job job;
                {
                    std::unique_lock lock(mutex_);
                    if (!condition_.wait(lock, stop, [this] { return !jobs_.empty(); })) return;
                    job = std::move(jobs_.front()); jobs_.pop_front();
                }
                if (job.epoch != epoch.load()) continue;
                std::string reply;
                try { reply = GetStore().Request(job.payload, std::to_string(job.epoch) + ":" + std::to_string(job.view) + ":" + std::to_string(job.generation)); }
                catch (const std::exception&) {
                    reply = Narration::Encode(R"({"ok":false,"kind":"failure","message":"Personal save directory is unavailable."})");
                }
                if (job.view > 0 && !stop.stop_requested()) {
                    SKSE::GetTaskInterface()->AddTask([job = std::move(job), reply = std::move(reply)] {
                        if (job.epoch != epoch.load()) return;
                        if (auto* source = SKSE::GetModCallbackEventSource()) {
                            const auto payload = std::to_string(job.generation) + "|" + reply;
                            SKSE::ModCallbackEvent event{ RE::BSFixedString("MMEExtensions_NarrationEditorResult"),
                                RE::BSFixedString(payload), static_cast<float>(job.view), nullptr };
                            source->SendEvent(&event);
                        }
                    });
                }
            }
        }
        std::mutex mutex_;
        std::condition_variable_any condition_;
        std::deque<Job> jobs_;
        std::jthread thread_; // Joined before its queue, condition and mutex are destroyed.
    };
    inline bool Queue(RE::StaticFunctionTag*, std::string payload, std::int32_t generation, std::int32_t view)
    {
        try {
            if (payload.size() > 12288 || view <= 0) return false;
            return Worker::Get().Queue({ std::move(payload), generation, view, epoch.load() });
        } catch (const std::exception&) { return false; }
    }
    inline std::string GeneralLore(RE::StaticFunctionTag*)
    {
        try { return GetStore().Override(); } catch (const std::exception&) { return ""; }
    }
    inline std::vector<std::string> Values(RE::StaticFunctionTag*, std::string id)
    {
        try { return GetStore().Values(id); } catch (const std::exception&) { return {}; }
    }
    inline bool HasPools(RE::StaticFunctionTag*, std::string file)
    {
        try { return GetStore().HasPools(file); } catch (const std::exception&) { return false; }
    }
    inline std::string Revision(RE::StaticFunctionTag*)
    {
        try { return GetStore().Revision(); } catch (const std::exception&) { return ""; }
    }
    inline std::string Failure(RE::StaticFunctionTag*)
    {
        try { return GetStore().Failure(); } catch (const std::exception&) { return "Personal save directory is unavailable."; }
    }
    inline std::string Describe(RE::StaticFunctionTag*, std::string payload)
    {
        try {
            const auto reply = nlohmann::json::parse(Narration::Decode(payload));
            if (reply.contains("transport") && !reply.contains("operation")) return "transport";
            const auto kind = reply.value("ok", false) ? std::string("success") : reply.value("kind", std::string("failure"));
            auto summary = "operation=" + reply.value("operation", std::string("unknown")) +
                " | request=" + reply.value("requestId", std::string("unknown")) +
                " | actor=N/A | result=" + kind;
            if (reply.contains("changedCount")) summary += " | entries=" + std::to_string(reply["changedCount"].get<std::size_t>());
            if (reply.contains("revision")) summary += " | revision=" + reply["revision"].get<std::string>();
            if (kind == "failure") summary += " | reason=" + reply.value("message", std::string("unspecified failure"));
            if (kind == "validation") {
                auto reason = reply.value("message",std::string("invalid template")).substr(0,200);
                for (auto& ch : reason) if (static_cast<unsigned char>(ch) < 32) ch = ' ';
                summary += " | reason=" + reason;
            }
            return summary;
        } catch (const std::exception&) { return "operation=response | actor=N/A | result=failure | invalid response"; }
    }
    inline void Invalidate()
    {
        try {
            Worker::Get().Queue({ Narration::Encode(R"({"operation":"refresh","requestId":"0"})"), 0, 0, epoch.load() });
        } catch (const std::exception&) { /* Papyrus reports an unavailable root. */ }
    }
    inline void Reload(RE::StaticFunctionTag*) { Invalidate(); }
    inline void ResetSession() { epoch.fetch_add(1); Invalidate(); }
}
