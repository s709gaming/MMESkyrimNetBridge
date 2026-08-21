#include <SKSE/SKSE.h>

#include <RE/P/PlayerCharacter.h>
#include <RE/P/ProcessLists.h>
#include <RE/P/PackUnpackImpl.h>
#include <RE/A/ActiveEffect.h>
#include <RE/E/EffectSetting.h>
#include <RE/M/MenuTopicManager.h>
#include <RE/N/NativeFunction.h>
#include <RE/S/ScriptEventSourceHolder.h>
#include <RE/T/TESFile.h>
#include <RE/T/TESForm.h>
#include <RE/T/TESActorLocationChangeEvent.h>
#include <RE/T/TESActiveEffectApplyRemoveEvent.h>
#include <RE/T/TESLoadGameEvent.h>
#include <RE/T/TESMagicEffectApplyEvent.h>
#include <RE/T/TESEquipEvent.h>
#include <RE/T/TESTopic.h>
#include <RE/T/TESTopicInfo.h>
#include <RE/T/TESSleepStopEvent.h>
#include <RE/T/TESWaitStopEvent.h>

#include <spdlog/sinks/basic_file_sink.h>

#include <unordered_set>
#include <unordered_map>

namespace
{
    constexpr auto kLifecycleEvent = "MMEExtensions_Lifecycle";
    constexpr auto kMMEEffectEvent = "MMEExtensions_MMEEffectApplied";
    constexpr auto kMMEEffectRemovedEvent = "MMEExtensions_MMEEffectRemoved";
    constexpr auto kDialogueInfoEvent = "MMEExtensions_DialogueInfo";
    constexpr auto kPotionEvent = "MMEExtensions_PotionConsumed";
    constexpr auto kArmorEvent = "MMEExtensions_ArmorEquipped";

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

    RE::TESForm* GetFormByEditorID(RE::StaticFunctionTag*, RE::BSFixedString editorID)
    {
        if (editorID.empty()) {
            return nullptr;
        }
        return RE::TESForm::LookupByEditorID(editorID.data());
    }

    RE::Actor* GetDialogueTarget(RE::StaticFunctionTag*)
    {
        auto* manager = RE::MenuTopicManager::GetSingleton();
        if (!manager) {
            return nullptr;
        }

        auto speaker = manager->speaker.get();
        if (!speaker) {
            speaker = manager->lastSpeaker.get();
        }
        return speaker ? speaker->As<RE::Actor>() : nullptr;
    }

    std::vector<RE::TESForm*> GetActiveDialogueInfos(RE::StaticFunctionTag*)
    {
        std::vector<RE::TESForm*> result;
        auto* manager = RE::MenuTopicManager::GetSingleton();
        if (!manager) {
            return result;
        }

        const auto appendUnique = [&](RE::TESTopicInfo* info) {
            if (info && std::find(result.begin(), result.end(), info) == result.end()) {
                result.push_back(info);
            }
        };
        appendUnique(manager->currentTopicInfo);
        appendUnique(manager->rootTopicInfo);
        if (manager->lastSelectedDialogue) {
            appendUnique(manager->lastSelectedDialogue->parentTopicInfo);
        }
        return result;
    }

    std::vector<RE::TESForm*> GetVisibleDialogueInfos(RE::StaticFunctionTag*)
    {
        std::vector<RE::TESForm*> result;
        auto* manager = RE::MenuTopicManager::GetSingleton();
        if (!manager || !manager->dialogueList) {
            return result;
        }

        for (auto* dialogue : *manager->dialogueList) {
            auto* info = dialogue ? dialogue->parentTopicInfo : nullptr;
            if (info && std::find(result.begin(), result.end(), info) == result.end()) {
                result.push_back(info);
            }
        }
        return result;
    }

    std::vector<RE::TESForm*> GetTopicInfos(RE::StaticFunctionTag*, RE::TESForm* form)
    {
        std::vector<RE::TESForm*> result;
        auto* topic = form && form->GetFormType() == RE::FormType::Dialogue ?
                          static_cast<RE::TESTopic*>(form) :
                          nullptr;
        if (!topic || !topic->topicInfos) {
            return result;
        }
        result.reserve(topic->numTopicInfos);
        for (std::uint32_t i = 0; i < topic->numTopicInfos; ++i) {
            if (topic->topicInfos[i]) {
                result.push_back(topic->topicInfos[i]);
            }
        }
        return result;
    }

    RE::TESForm* GetPreviousTopicInfo(RE::StaticFunctionTag*, RE::TESForm* form)
    {
        auto* info = form && form->GetFormType() == RE::FormType::Info ?
                         static_cast<RE::TESTopicInfo*>(form) :
                         nullptr;
        return info ? info->dataInfo : nullptr;
    }

    bool EvaluateTopicInfo(RE::StaticFunctionTag*, RE::TESForm* form, RE::Actor* subject, RE::Actor* target)
    {
        auto* info = form && form->GetFormType() == RE::FormType::Info ?
                         static_cast<RE::TESTopicInfo*>(form) :
                         nullptr;
        return info && subject && target && info->objConditions.IsTrue(subject, target);
    }

    std::vector<std::int32_t> EvaluateTopicInfoConditions(
        RE::StaticFunctionTag*, RE::TESForm* form, RE::Actor* subject, RE::Actor* target)
    {
        std::vector<std::int32_t> result;
        auto* info = form && form->GetFormType() == RE::FormType::Info ?
                         static_cast<RE::TESTopicInfo*>(form) :
                         nullptr;
        if (!info || !subject || !target) {
            return result;
        }

        for (auto* condition = info->objConditions.head; condition; condition = condition->next) {
            RE::ConditionCheckParams params(subject, target);
            result.push_back(condition->IsTrue(params) ? 1 : 0);
        }
        return result;
    }

    std::vector<RE::BSFixedString> DescribeTopicInfoConditions(RE::StaticFunctionTag*, RE::TESForm* form)
    {
        std::vector<RE::BSFixedString> result;
        auto* info = form && form->GetFormType() == RE::FormType::Info ?
                         static_cast<RE::TESTopicInfo*>(form) :
                         nullptr;
        if (!info) {
            return result;
        }

        const auto formLabel = [](RE::TESForm* parameter) {
            if (!parameter) {
                return std::string("<none>");
            }
            const auto* editorID = parameter->GetFormEditorID();
            if (editorID && editorID[0] != '\0') {
                return std::string(editorID);
            }
            auto* file = parameter->GetFile(0);
            return fmt::format(
                "{}:{:06X}", file ? file->GetFilename().data() : "<dynamic>",
                parameter->GetLocalFormID());
        };
        const auto objectLabel = [](RE::CONDITIONITEMOBJECT object) {
            switch (object) {
            case RE::CONDITIONITEMOBJECT::kSelf:
                return "subject";
            case RE::CONDITIONITEMOBJECT::kTarget:
                return "target";
            case RE::CONDITIONITEMOBJECT::kRef:
                return "reference";
            default:
                return "run-on";
            }
        };
        const auto opLabel = [](RE::CONDITION_ITEM_DATA::OpCode op) {
            switch (op) {
            case RE::CONDITION_ITEM_DATA::OpCode::kEqualTo:
                return "==";
            case RE::CONDITION_ITEM_DATA::OpCode::kNotEqualTo:
                return "!=";
            case RE::CONDITION_ITEM_DATA::OpCode::kGreaterThan:
                return ">";
            case RE::CONDITION_ITEM_DATA::OpCode::kGreaterThanOrEqualTo:
                return ">=";
            case RE::CONDITION_ITEM_DATA::OpCode::kLessThan:
                return "<";
            case RE::CONDITION_ITEM_DATA::OpCode::kLessThanOrEqualTo:
                return "<=";
            default:
                return "?";
            }
        };

        for (auto* condition = info->objConditions.head; condition; condition = condition->next) {
            const auto functionID = condition->data.functionData.function.get();
            const char* functionName = "Function";
            bool formParameter = false;
            switch (functionID) {
            case RE::FUNCTION_DATA::FunctionID::kGetItemCount:
                functionName = "GetItemCount";
                formParameter = true;
                break;
            case RE::FUNCTION_DATA::FunctionID::kGetGlobalValue:
                functionName = "GetGlobalValue";
                formParameter = true;
                break;
            case RE::FUNCTION_DATA::FunctionID::kHasSpell:
                functionName = "HasSpell";
                formParameter = true;
                break;
            case RE::FUNCTION_DATA::FunctionID::kGetVMQuestVariable:
                functionName = "GetVMQuestVariable";
                formParameter = true;
                break;
            default:
                break;
            }
            std::string parameter;
            if (formParameter) {
                parameter = " " + formLabel(static_cast<RE::TESForm*>(condition->data.functionData.params[0]));
            } else {
                parameter = fmt::format(" #{}", static_cast<std::uint16_t>(functionID));
            }
            result.emplace_back(fmt::format(
                "{}{} on {} {} {:.2f}{}", functionName, parameter,
                objectLabel(condition->data.object.get()),
                opLabel(condition->data.flags.opCode),
                condition->data.comparisonValue.f,
                condition->data.flags.isOR ? " [OR]" : ""));
        }
        return result;
    }

    std::vector<RE::BSFixedString> GetFormSourceFiles(RE::StaticFunctionTag*, RE::TESForm* form)
    {
        std::vector<RE::BSFixedString> result;
        if (!form || !form->sourceFiles.array) {
            return result;
        }
        result.reserve(form->sourceFiles.array->size());
        for (auto* file : *form->sourceFiles.array) {
            if (file) {
                result.emplace_back(file->GetFilename());
            }
        }
        return result;
    }

    RE::TESForm* GetParentTopic(RE::StaticFunctionTag*, RE::TESForm* form)
    {
        auto* info = form && form->GetFormType() == RE::FormType::Info ?
                         static_cast<RE::TESTopicInfo*>(form) : nullptr;
        return info ? info->parentTopic : nullptr;
    }

    bool RegisterPapyrus(RE::BSScript::IVirtualMachine* vm)
    {
        vm->RegisterFunction("GetNearbyActors", "MMEExtensionsNative", GetNearbyActors);
        vm->RegisterFunction("GetFormByEditorID", "MMEExtensionsNative", GetFormByEditorID);
        vm->RegisterFunction("GetDialogueTarget", "MMEExtensionsNative", GetDialogueTarget);
        vm->RegisterFunction("GetActiveDialogueInfos", "MMEExtensionsNative", GetActiveDialogueInfos);
        vm->RegisterFunction("GetVisibleDialogueInfos", "MMEExtensionsNative", GetVisibleDialogueInfos);
        vm->RegisterFunction("GetTopicInfos", "MMEExtensionsNative", GetTopicInfos);
        vm->RegisterFunction("GetPreviousTopicInfo", "MMEExtensionsNative", GetPreviousTopicInfo);
        vm->RegisterFunction("EvaluateTopicInfo", "MMEExtensionsNative", EvaluateTopicInfo);
        vm->RegisterFunction("EvaluateTopicInfoConditions", "MMEExtensionsNative", EvaluateTopicInfoConditions);
        vm->RegisterFunction("DescribeTopicInfoConditions", "MMEExtensionsNative", DescribeTopicInfoConditions);
        vm->RegisterFunction("GetFormSourceFiles", "MMEExtensionsNative", GetFormSourceFiles);
        vm->RegisterFunction("GetParentTopic", "MMEExtensionsNative", GetParentTopic);
        SKSE::log::info("Native scanner and dialogue diagnostics registered");
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

    void SendMMEEffectRemovedEvent(RE::TESObjectREFR* target, RE::TESForm* effect)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        if (!source || !target || !effect) {
            return;
        }

        SKSE::ModCallbackEvent event{
            RE::BSFixedString(kMMEEffectRemovedEvent),
            RE::BSFixedString("MilkModNEW.esp"),
            static_cast<float>(effect->GetLocalFormID()),
            target
        };
        source->SendEvent(&event);
        SKSE::log::info("MME magic effect removed: target {:08X}, effect {:06X}", target->GetFormID(), effect->GetLocalFormID());
    }

    void SendDialogueInfoEvent(RE::TESTopicInfo* info)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        auto* manager = RE::MenuTopicManager::GetSingleton();
        auto* topic = info ? info->parentTopic : nullptr;
        if (!source || !manager) {
            return;
        }

        auto speaker = manager->speaker.get();
        if (!speaker) {
            speaker = manager->lastSpeaker.get();
        }
        SKSE::ModCallbackEvent event{
            RE::BSFixedString(kDialogueInfoEvent),
            RE::BSFixedString(topic ? topic->GetFormEditorID() : "<unresolved>"),
            info ? static_cast<float>(info->GetLocalFormID()) : -1.0F,
            speaker.get()
        };
        source->SendEvent(&event);
        SKSE::log::info("dialogue event: topic {} info {} speaker {}",
            topic ? topic->GetFormEditorID() : "<unresolved>",
            info ? fmt::format("{:06X}", info->GetLocalFormID()) : "<unresolved>",
            speaker ? fmt::format("{:08X}", speaker->GetFormID()) : "<unresolved>");
    }

    std::uint64_t ActiveEffectKey(RE::TESObjectREFR* target, std::uint16_t uniqueID)
    {
        return (static_cast<std::uint64_t>(target->GetFormID()) << 16) | uniqueID;
    }

    std::unordered_map<std::uint64_t, RE::FormID> g_mmeActiveEffects;
    std::unordered_map<RE::FormID, RE::FormID> g_pendingMMEEffects;

    void SendPotionEvent(RE::Actor* actor, RE::TESForm* potion)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        auto* sourceFile = potion ? potion->GetFile(0) : nullptr;
        if (!source || !actor || !potion || !sourceFile) {
            return;
        }
        SKSE::ModCallbackEvent event{
            RE::BSFixedString(kPotionEvent),
            RE::BSFixedString(sourceFile->GetFilename()),
            static_cast<float>(potion->GetLocalFormID()),
            actor
        };
        source->SendEvent(&event);
        SKSE::log::info("potion equip sent: actor {:08X}, {}:{:06X}", actor->GetFormID(), sourceFile->GetFilename(), potion->GetLocalFormID());
    }

    void SendArmorEvent(RE::Actor* actor, RE::TESForm* armor)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        auto* sourceFile = armor ? armor->GetFile(0) : nullptr;
        if (!source || !actor || !armor || !sourceFile) {
            return;
        }
        SKSE::ModCallbackEvent event{
            RE::BSFixedString(kArmorEvent),
            RE::BSFixedString(sourceFile->GetFilename()),
            static_cast<float>(armor->GetLocalFormID()),
            actor
        };
        source->SendEvent(&event);
        SKSE::log::info("armor equip sent: actor {:08X}, {}:{:06X}", actor->GetFormID(), sourceFile->GetFilename(), armor->GetLocalFormID());
    }

    class LifecycleEventSink final :
        public RE::BSTEventSink<RE::TESWaitStopEvent>,
        public RE::BSTEventSink<RE::TESSleepStopEvent>,
        public RE::BSTEventSink<RE::TESActorLocationChangeEvent>,
        public RE::BSTEventSink<RE::TESLoadGameEvent>,
        public RE::BSTEventSink<RE::TESMagicEffectApplyEvent>,
        public RE::BSTEventSink<RE::TESActiveEffectApplyRemoveEvent>,
        public RE::BSTEventSink<RE::TESTopicInfoEvent>,
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
            holder->AddEventSink<RE::TESActiveEffectApplyRemoveEvent>(this);
            holder->AddEventSink<RE::TESTopicInfoEvent>(this);
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
            g_mmeActiveEffects.clear();
            g_pendingMMEEffects.clear();
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
                g_pendingMMEEffects[event->target->GetFormID()] = effect->GetFormID();
                SendMMEEffectEvent(event->target.get(), effect);
            }
            return RE::BSEventNotifyControl::kContinue;
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESActiveEffectApplyRemoveEvent* event,
            RE::BSTEventSource<RE::TESActiveEffectApplyRemoveEvent>*) override
        {
            if (!event || !event->target) {
                return RE::BSEventNotifyControl::kContinue;
            }

            const auto key = ActiveEffectKey(event->target.get(), event->activeEffectUniqueID);
            if (event->isApplied) {
                bool tracked = false;
                // CommonLibSSE-NG documents active-effect traversal as unsafe
                // on VR. TESMagicEffectApplyEvent has already published and
                // cached the exact MME effect, so VR pairs that cache with this
                // unique active-effect ID instead of touching the incompatible
                // ActiveEffect list layout.
                if (!REL::Module::IsVR()) {
                    auto* actor = event->target->As<RE::Actor>();
                    auto* magicTarget = actor ? actor->AsMagicTarget() : nullptr;
                    auto* effects = magicTarget ? magicTarget->GetActiveEffectList() : nullptr;
                    if (effects) {
                        for (auto* activeEffect : *effects) {
                            if (!activeEffect || activeEffect->usUniqueID != event->activeEffectUniqueID) {
                                continue;
                            }
                            auto* effect = activeEffect->GetBaseObject();
                            auto* sourceFile = effect ? effect->GetFile(0) : nullptr;
                            if (sourceFile && _stricmp(sourceFile->GetFilename().data(), "MilkModNEW.esp") == 0) {
                                g_mmeActiveEffects[key] = effect->GetFormID();
                                tracked = true;
                            }
                            break;
                        }
                    }
                }
                const auto pending = g_pendingMMEEffects.find(event->target->GetFormID());
                if (!tracked && pending != g_pendingMMEEffects.end()) {
                    g_mmeActiveEffects[key] = pending->second;
                    tracked = true;
                }
                if (pending != g_pendingMMEEffects.end()) {
                    g_pendingMMEEffects.erase(pending);
                }
                if (REL::Module::IsVR() && !tracked) {
                    SKSE::log::debug(
                        "VR active-effect apply had no paired MME magic-effect event: target {:08X}, unique {}",
                        event->target->GetFormID(), event->activeEffectUniqueID);
                }
            } else {
                const auto found = g_mmeActiveEffects.find(key);
                if (found != g_mmeActiveEffects.end()) {
                    auto* effect = RE::TESForm::LookupByID(found->second);
                    SendMMEEffectRemovedEvent(event->target.get(), effect);
                    g_mmeActiveEffects.erase(found);
                }
            }
            return RE::BSEventNotifyControl::kContinue;
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESTopicInfoEvent*,
            RE::BSTEventSource<RE::TESTopicInfoEvent>*) override
        {
            auto* manager = RE::MenuTopicManager::GetSingleton();
            if (!manager) {
                return RE::BSEventNotifyControl::kContinue;
            }
            auto* info = manager->currentTopicInfo;
            if (!info) {
                info = manager->lastTopicInfo;
            }
            if (!info && manager->lastSelectedDialogue) {
                info = manager->lastSelectedDialogue->parentTopicInfo;
            }
            SendDialogueInfoEvent(info);
            return RE::BSEventNotifyControl::kContinue;
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESEquipEvent* event,
            RE::BSTEventSource<RE::TESEquipEvent>*) override
        {
            if (!event || !event->equipped || !event->actor) {
                return RE::BSEventNotifyControl::kContinue;
            }
            auto* actor = event->actor->As<RE::Actor>();
            auto* item = RE::TESForm::LookupByID(event->baseObject);
            if (actor && item && item->GetFormType() == RE::FormType::AlchemyItem) {
                SendPotionEvent(actor, item);
            } else if (actor && item && item->GetFormType() == RE::FormType::Armor) {
                SendArmorEvent(actor, item);
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
    SKSE::log::info("Runtime family: {}", REL::Module::IsVR() ? "VR" : (REL::Module::IsAE() ? "AE" : "SE"));
    return true;
}
