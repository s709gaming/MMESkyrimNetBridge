#include <SKSE/SKSE.h>

#include <RE/P/PlayerCharacter.h>
#include <RE/P/ProcessLists.h>
#include <RE/P/PackUnpackImpl.h>
#include <RE/N/NativeFunction.h>
#include <RE/S/ScriptEventSourceHolder.h>
#include <RE/T/TESFile.h>
#include <RE/T/TESForm.h>
#include <RE/T/TESActorLocationChangeEvent.h>
#include <RE/T/TESLoadGameEvent.h>
#include <RE/T/TESMagicEffectApplyEvent.h>
#include <RE/T/TESEquipEvent.h>
#include <RE/T/TESSleepStopEvent.h>
#include <RE/T/TESWaitStopEvent.h>

#include <spdlog/sinks/basic_file_sink.h>

#include <unordered_set>

namespace
{
    constexpr auto kLifecycleEvent = "MMEExtensions_Lifecycle";
    constexpr auto kMMEEffectEvent = "MMEExtensions_MMEEffectApplied";
    constexpr auto kNPCPotionEvent = "MMEExtensions_NPCPotionConsumed";

    std::vector<RE::Actor*> GetNearbyActors(RE::StaticFunctionTag*, float radius)
    {
        std::vector<RE::Actor*> result;
        auto* player = RE::PlayerCharacter::GetSingleton();
        auto* processLists = RE::ProcessLists::GetSingleton();
        if (!player || !processLists) {
            return result;
        }

        result.push_back(player);
        const auto playerPosition = player->GetPosition();
        const auto radiusSquared = radius * radius;
        const auto* playerCell = player->GetParentCell();
        std::unordered_set<RE::FormID> seen{ player->GetFormID() };

        processLists->ForAllActors([&](RE::Actor* actor) {
            if (!actor || actor == player || !actor->Is3DLoaded() || actor->GetParentCell() != playerCell) {
                return RE::BSContainer::ForEachResult::kContinue;
            }
            const auto delta = actor->GetPosition() - playerPosition;
            if (delta.SqrLength() > radiusSquared || !seen.insert(actor->GetFormID()).second) {
                return RE::BSContainer::ForEachResult::kContinue;
            }
            result.push_back(actor);
            return RE::BSContainer::ForEachResult::kContinue;
        });

        SKSE::log::info("Native nearby scan returned {} actors within {:.0f} units", result.size(), radius);
        return result;
    }

    bool RegisterPapyrus(RE::BSScript::IVirtualMachine* vm)
    {
        vm->RegisterFunction("GetNearbyActors", "MMEExtensionsNative", GetNearbyActors);
        SKSE::log::info("Native Papyrus scanner registered");
        return true;
    }

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

    void SendMMEEffectEvent(RE::TESObjectREFR* target, RE::TESForm* effect)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        if (!source || !target || !effect) {
            return;
        }

        SKSE::ModCallbackEvent event{
            RE::BSFixedString(kMMEEffectEvent),
            RE::BSFixedString("MilkModNEW.esp"),
            static_cast<float>(effect->GetLocalFormID()),
            target
        };
        source->SendEvent(&event);
        SKSE::log::info("MME magic effect sent: target {:08X}, effect {:06X}", target->GetFormID(), effect->GetLocalFormID());
    }

    void SendNPCPotionEvent(RE::Actor* actor, RE::TESForm* potion)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        auto* sourceFile = potion ? potion->GetFile(0) : nullptr;
        if (!source || !actor || !potion || !sourceFile) {
            return;
        }
        SKSE::ModCallbackEvent event{
            RE::BSFixedString(kNPCPotionEvent),
            RE::BSFixedString(sourceFile->GetFilename()),
            static_cast<float>(potion->GetLocalFormID()),
            actor
        };
        source->SendEvent(&event);
        SKSE::log::info("NPC potion equip sent: actor {:08X}, {}:{:06X}", actor->GetFormID(), sourceFile->GetFilename(), potion->GetLocalFormID());
    }

    class LifecycleEventSink final :
        public RE::BSTEventSink<RE::TESWaitStopEvent>,
        public RE::BSTEventSink<RE::TESSleepStopEvent>,
        public RE::BSTEventSink<RE::TESActorLocationChangeEvent>,
        public RE::BSTEventSink<RE::TESLoadGameEvent>,
        public RE::BSTEventSink<RE::TESMagicEffectApplyEvent>,
        public RE::BSTEventSink<RE::TESEquipEvent>
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
            holder->AddEventSink<RE::TESMagicEffectApplyEvent>(this);
            holder->AddEventSink<RE::TESEquipEvent>(this);
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

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESMagicEffectApplyEvent* event,
            RE::BSTEventSource<RE::TESMagicEffectApplyEvent>*) override
        {
            if (!event || !event->target) {
                return RE::BSEventNotifyControl::kContinue;
            }

            auto* effect = RE::TESForm::LookupByID(event->magicEffect);
            auto* sourceFile = effect ? effect->GetFile(0) : nullptr;
            if (sourceFile && _stricmp(sourceFile->GetFilename().data(), "MilkModNEW.esp") == 0) {
                SendMMEEffectEvent(event->target.get(), effect);
            }
            return RE::BSEventNotifyControl::kContinue;
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESEquipEvent* event,
            RE::BSTEventSource<RE::TESEquipEvent>*) override
        {
            if (!event || !event->equipped || !event->actor || event->actor.get() == RE::PlayerCharacter::GetSingleton()) {
                return RE::BSEventNotifyControl::kContinue;
            }
            auto* actor = event->actor->As<RE::Actor>();
            auto* item = RE::TESForm::LookupByID(event->baseObject);
            if (actor && item && item->GetFormType() == RE::FormType::AlchemyItem) {
                SendNPCPotionEvent(actor, item);
            }
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
    SKSE::GetPapyrusInterface()->Register(RegisterPapyrus);
    SKSE::log::info("MME Extensions native bridge loaded");
    SKSE::log::info("Runtime version: {}", skse->RuntimeVersion().string());
    return true;
}
