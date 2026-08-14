#include <SKSE/SKSE.h>

#include <RE/P/PlayerCharacter.h>
#include <RE/S/ScriptEventSourceHolder.h>
#include <RE/T/TESActorLocationChangeEvent.h>
#include <RE/T/TESLoadGameEvent.h>
#include <RE/T/TESSleepStopEvent.h>
#include <RE/T/TESWaitStopEvent.h>

#include <spdlog/sinks/basic_file_sink.h>

namespace
{
    constexpr auto kLifecycleEvent = "MMEExtensions_Lifecycle";

    void SendLifecycleEvent(const char* reason)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        if (!source) {
            SKSE::log::error("Mod callback source unavailable for {}", reason);
            return;
        }

        SKSE::ModCallbackEvent event{
            RE::BSFixedString(kLifecycleEvent),
            RE::BSFixedString(reason),
            0.0F,
            RE::PlayerCharacter::GetSingleton()
        };
        source->SendEvent(&event);
        SKSE::log::info("Lifecycle event sent: {}", reason);
    }

    class LifecycleEventSink final :
        public RE::BSTEventSink<RE::TESWaitStopEvent>,
        public RE::BSTEventSink<RE::TESSleepStopEvent>,
        public RE::BSTEventSink<RE::TESActorLocationChangeEvent>,
        public RE::BSTEventSink<RE::TESLoadGameEvent>
    {
    public:
        static LifecycleEventSink* GetSingleton()
        {
            static LifecycleEventSink singleton;
            return std::addressof(singleton);
        }

        void Register()
        {
            auto* holder = RE::ScriptEventSourceHolder::GetSingleton();
            holder->AddEventSink<RE::TESWaitStopEvent>(this);
            holder->AddEventSink<RE::TESSleepStopEvent>(this);
            holder->AddEventSink<RE::TESActorLocationChangeEvent>(this);
            holder->AddEventSink<RE::TESLoadGameEvent>(this);
            SKSE::log::info("Lifecycle event sinks registered");
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESWaitStopEvent*, RE::BSTEventSource<RE::TESWaitStopEvent>*) override
        {
            SendLifecycleEvent("wait");
            return RE::BSEventNotifyControl::kContinue;
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESSleepStopEvent*, RE::BSTEventSource<RE::TESSleepStopEvent>*) override
        {
            SendLifecycleEvent("sleep");
            return RE::BSEventNotifyControl::kContinue;
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESActorLocationChangeEvent* event,
            RE::BSTEventSource<RE::TESActorLocationChangeEvent>*) override
        {
            if (event && event->actor.get() == RE::PlayerCharacter::GetSingleton() && event->oldLoc != event->newLoc) {
                SendLifecycleEvent("location");
            }
            return RE::BSEventNotifyControl::kContinue;
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESLoadGameEvent*, RE::BSTEventSource<RE::TESLoadGameEvent>*) override
        {
            SendLifecycleEvent("load");
            return RE::BSEventNotifyControl::kContinue;
        }
    };

    void InitializeLogging()
    {
        const auto logDirectory = SKSE::log::log_directory();
        if (!logDirectory) {
            SKSE::stl::report_and_fail("Unable to locate the SKSE log directory");
        }

        const auto logPath = *logDirectory / "MMEExtensions.log";
        const auto logger = std::make_shared<spdlog::logger>(
            "global log",
            std::make_shared<spdlog::sinks::basic_file_sink_mt>(logPath.string(), true));

        spdlog::set_default_logger(logger);
        spdlog::set_level(spdlog::level::info);
        spdlog::flush_on(spdlog::level::info);
    }

    void OnSKSEMessage(SKSE::MessagingInterface::Message* message)
    {
        if (message->type == SKSE::MessagingInterface::kDataLoaded) {
            LifecycleEventSink::GetSingleton()->Register();
        }
    }
}

SKSEPluginLoad(const SKSE::LoadInterface* skse)
{
    InitializeLogging();
    SKSE::Init(skse);

    SKSE::GetMessagingInterface()->RegisterListener(OnSKSEMessage);
    SKSE::log::info("MME Extensions native bridge loaded");
    SKSE::log::info("Runtime version: {}", skse->RuntimeVersion().string());
    return true;
}
