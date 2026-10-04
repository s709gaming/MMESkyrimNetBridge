#include <SKSE/SKSE.h>

#include <RE/P/PlayerCharacter.h>
#include <RE/P/ProcessLists.h>
#include <RE/P/PackUnpackImpl.h>
#include <RE/A/ActiveEffect.h>
#include <RE/B/BGSKeyword.h>
#include <RE/B/BGSLocation.h>
#include <RE/C/ContainerMenu.h>
#include <RE/E/EffectSetting.h>
#include <RE/M/MenuOpenCloseEvent.h>
#include <RE/M/MenuTopicManager.h>
#include <RE/M/Misc.h>
#include <RE/N/NativeFunction.h>
#include <RE/S/ScriptEventSourceHolder.h>
#include <RE/T/TESFile.h>
#include <RE/T/TESForm.h>
#include <RE/T/TESDataHandler.h>
#include <RE/T/TESActorLocationChangeEvent.h>
#include <RE/T/TESActivateEvent.h>
#include <RE/T/TESActiveEffectApplyRemoveEvent.h>
#include <RE/T/TESLoadGameEvent.h>
#include <RE/T/TESMagicEffectApplyEvent.h>
#include <RE/T/TESObjectCONT.h>
#include <RE/T/TESEquipEvent.h>
#include <RE/T/TESTopic.h>
#include <RE/T/TESTopicInfo.h>
#include <RE/T/TESSleepStopEvent.h>
#include <RE/T/TESWaitStopEvent.h>
#include <RE/U/UI.h>

#include <spdlog/sinks/basic_file_sink.h>

#include <chrono>
#include <unordered_set>
#include <unordered_map>

namespace
{
    // ------------------------------------------------------------------------
    // Native/Papyrus boundary contracts
    // ------------------------------------------------------------------------
    // The DLL observes engine events and publishes load-order-independent form
    // identity (source filename + local FormID). Gameplay decisions stay in
    // Papyrus. These event names are therefore a stable cross-language API.
    constexpr auto kLifecycleEvent = "MMEExtensions_Lifecycle";
    constexpr auto kMMEEffectEvent = "MMEExtensions_MMEEffectApplied";
    constexpr auto kMMEEffectRemovedEvent = "MMEExtensions_MMEEffectRemoved";
    constexpr auto kPotionEvent = "MMEExtensions_PotionConsumed";
    constexpr auto kArmorEvent = "MMEExtensions_ArmorEquipped";
    constexpr auto kArmorUnequippedEvent = "MMEExtensions_ArmorUnequipped";
    constexpr auto kDungeonBossChestEvent = "MMEExtensions_DungeonBossChestActivated";
    constexpr auto kDungeonRegularChestEvent = "MMEExtensions_DungeonRegularChestActivated";
    constexpr auto kInnPalaceEnteredEvent = "MMEExtensions_InnPalaceEntered";
    constexpr auto kInnPalaceExitedEvent = "MMEExtensions_InnPalaceExited";

    enum class SocialVenueKind : std::uint32_t
    {
        kNone = 0,
        kInn = 1,
        kGuildTavern = 2,
        kJarlResidence = 3,
        kTown = 4
    };

    struct SocialVenue
    {
        RE::BGSLocation* location{ nullptr };
        SocialVenueKind kind{ SocialVenueKind::kNone };
    };

    RE::BGSKeyword* g_locTypeInn = nullptr;
    RE::BGSKeyword* g_locTypeCity = nullptr;
    RE::BGSKeyword* g_locSetDwarvenRuin = nullptr;
    std::unordered_map<RE::FormID, SocialVenueKind> g_socialVenueForms;
    std::unordered_map<RE::FormID, std::chrono::steady_clock::time_point> g_chestActivationTimes;

    void InitializeSocialVenueForms()
    {
        auto* dataHandler = RE::TESDataHandler::GetSingleton();
        if (!dataHandler) {
            SKSE::log::error("social venue forms unavailable: TESDataHandler missing");
            return;
        }

        g_locTypeInn = dataHandler->LookupForm<RE::BGSKeyword>(0x01CB87, "Skyrim.esm");
        g_locTypeCity = dataHandler->LookupForm<RE::BGSKeyword>(0x013168, "Skyrim.esm");
        g_locSetDwarvenRuin = dataHandler->LookupForm<RE::BGSKeyword>(0x0130F0, "Skyrim.esm");
        g_socialVenueForms.clear();
        const auto addVenue = [&](RE::FormID localID, SocialVenueKind kind) {
            if (auto* location = dataHandler->LookupForm<RE::BGSLocation>(localID, "Skyrim.esm")) {
                g_socialVenueForms.insert_or_assign(location->GetFormID(), kind);
            } else {
                SKSE::log::warn("social venue location missing: Skyrim.esm:{:06X}", localID);
            }
        };

        // Public guild/tavern spaces which vanilla does not tag LocTypeInn.
        addVenue(0x01F877, SocialVenueKind::kGuildTavern);  // Jorrvaskr
        addVenue(0x02264A, SocialVenueKind::kGuildTavern);  // Ragged Flagon
        addVenue(0x01F872, SocialVenueKind::kGuildTavern);  // Drunken Huntsman

        // Exact jarl residences avoid the unrelated Castle Dour locations that
        // also carry LocTypeCastle. Parent traversal covers subordinate cells.
        addVenue(0x01F871, SocialVenueKind::kJarlResidence);  // Dragonsreach
        addVenue(0x020086, SocialVenueKind::kJarlResidence);  // Blue Palace
        addVenue(0x0209F2, SocialVenueKind::kJarlResidence);  // Palace of the Kings
        addVenue(0x022646, SocialVenueKind::kJarlResidence);  // Mistveil Keep
        addVenue(0x01F316, SocialVenueKind::kJarlResidence);  // Understone Keep
        addVenue(0x020062, SocialVenueKind::kJarlResidence);  // White Hall
        addVenue(0x01EB9A, SocialVenueKind::kJarlResidence);  // Highmoon Hall
        addVenue(0x0200C9, SocialVenueKind::kJarlResidence);  // Falkreath Jarl's Longhouse
        addVenue(0x01EB7D, SocialVenueKind::kJarlResidence);  // Winterhold Jarl's Longhouse

        SKSE::log::info(
            "social venue forms initialized: LocTypeInn={}, LocTypeCity={}, explicit locations={}",
            g_locTypeInn != nullptr, g_locTypeCity != nullptr, g_socialVenueForms.size());
    }

    bool IsInDwarvenRuin(RE::TESObjectREFR* reference)
    {
        if (!reference || !g_locSetDwarvenRuin) {
            return false;
        }
        auto* location = reference->GetCurrentLocation();
        std::unordered_set<RE::FormID> visited;
        for (std::uint32_t depth = 0; location && depth < 16; ++depth) {
            if (!visited.insert(location->GetFormID()).second) {
                break;
            }
            if (location->HasKeyword(g_locSetDwarvenRuin)) {
                return true;
            }
            location = location->parentLoc;
        }
        return false;
    }

    bool IsChestActivationDebounced(RE::TESObjectREFR* chest)
    {
        if (!chest) {
            return true;
        }
        const auto now = std::chrono::steady_clock::now();
        const auto id = chest->GetFormID();
        if (const auto it = g_chestActivationTimes.find(id); it != g_chestActivationTimes.end() &&
            now - it->second < std::chrono::seconds(30)) {
            SKSE::log::debug("dungeon chest activation suppressed by 30-second debounce: ref {:08X}", id);
            return true;
        }
        g_chestActivationTimes[id] = now;
        if (g_chestActivationTimes.size() > 1024) {
            for (auto it = g_chestActivationTimes.begin(); it != g_chestActivationTimes.end();) {
                if (now - it->second >= std::chrono::seconds(30)) {
                    it = g_chestActivationTimes.erase(it);
                } else {
                    ++it;
                }
            }
        }
        return false;
    }

    bool IsCuratedDungeonBossChest(RE::TESBoundObject* baseObject);
    bool IsCuratedDungeonRegularChest(RE::TESBoundObject* baseObject);
    void SendDungeonChestEvent(
        const char* eventName, const char* chestKind, RE::TESObjectREFR* chest,
        RE::Actor* activator, RE::TESBoundObject* baseObject);

    void ProcessOpenedDungeonChest(RE::TESObjectREFR* chest, RE::Actor* activator)
    {
        if (!chest || !activator || chest->IsLocked()) {
            return;
        }
        auto* baseObject = chest->GetBaseObject();
        if (IsCuratedDungeonBossChest(baseObject)) {
            if (!IsChestActivationDebounced(chest)) {
                SendDungeonChestEvent(kDungeonBossChestEvent, "boss", chest, activator, baseObject);
            }
        } else if (IsCuratedDungeonRegularChest(baseObject)) {
            if (!IsChestActivationDebounced(chest)) {
                SendDungeonChestEvent(kDungeonRegularChestEvent, "regular", chest, activator, baseObject);
            }
        }
    }

    SocialVenue FindSocialVenue(RE::BGSLocation* location)
    {
        // Location parent chains are shallow in vanilla. Bound traversal so a
        // malformed modded cycle can never trap the event sink.
        std::unordered_set<RE::FormID> visited;
        for (std::uint32_t depth = 0; location && depth < 16; ++depth) {
            if (!visited.insert(location->GetFormID()).second) {
                break;
            }
            if (const auto it = g_socialVenueForms.find(location->GetFormID()); it != g_socialVenueForms.end()) {
                return { location, it->second };
            }
            if (g_locTypeInn && location->HasKeyword(g_locTypeInn)) {
                return { location, SocialVenueKind::kInn };
            }
            if (g_locTypeCity && location->HasKeyword(g_locTypeCity)) {
                return { location, SocialVenueKind::kTown };
            }
            location = location->parentLoc;
        }
        return {};
    }

    void SendSocialVenueEvent(const char* eventName, const SocialVenue& venue)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        if (!source || !venue.location || venue.kind == SocialVenueKind::kNone) {
            return;
        }
        SKSE::ModCallbackEvent event{
            RE::BSFixedString(eventName),
            RE::BSFixedString(""),
            static_cast<float>(venue.kind),
            venue.location
        };
        source->SendEvent(&event);
        SKSE::log::info(
            "social venue event sent: {} location {:08X}, kind {}",
            eventName, venue.location->GetFormID(), static_cast<std::uint32_t>(venue.kind));
    }

    bool IsCuratedDungeonBossChest(RE::TESBoundObject* baseObject)
    {
        if (!baseObject || baseObject->GetFormType() != RE::FormType::Container) {
            return false;
        }
        auto* sourceFile = baseObject->GetFile(0);
        if (!sourceFile) {
            return false;
        }

        const auto localID = baseObject->GetLocalFormID();
        const auto filename = sourceFile->GetFilename();
        // Curated from the live vanilla load order. EMPTY templates are omitted;
        // every accepted base is an actual boss/reward container family.
        if (_stricmp(filename.data(), "Skyrim.esm") == 0) {
            switch (localID) {
            case 0x0B1176:  // TreasFalmerChestBossDwarven
            case 0x0774C9:  // TreasOrcChestBoss
            case 0x0774BF:  // TreasGiantChestBoss
            case 0x08EA5D:  // TreasAfflictedChestBoss
            case 0x08B1F1:  // TreasCWSonsChestBossLarge
            case 0x08B1F0:  // TreasCWImperialChestBossLarge
            case 0x08B1E9:  // TreasCWSonsChestBossSmall
            case 0x08B1E8:  // TreasCWImperialChestBossSmall
            case 0x020671:  // TreasDraugrChestBoss
            case 0x020667:  // TreasHagravenChestBoss
            case 0x020664:  // TreasVampireChestBoss
            case 0x020661:  // TreasWerewolfChestBoss
            case 0x02065D:  // TreasWarlockChestBoss
            case 0x02065B:  // TreasFalmerChestBoss
            case 0x020658:  // TreasForswornChestBoss
            case 0x020652:  // TreasDwarvenChestBoss
            case 0x02064F:  // TreasBanditChestBoss
                return true;
            default:
                return false;
            }
        }
        if (_stricmp(filename.data(), "Dawnguard.esm") == 0) {
            return localID == 0x0040A5 ||  // DLC01SC_ChestBoss
                   localID == 0x019DD6;    // DLC01TreasSnowElfChestBoss
        }
        if (_stricmp(filename.data(), "Dragonborn.esm") == 0) {
            switch (localID) {
            case 0x03A2B6:  // DLC2dunKolbjornTreasDraugrChestBoss
            case 0x02C461:  // DLC2TreasApocryphaChestBoss
            case 0x02C45F:  // DLC2TreasWerebearChestBoss
            case 0x02C45A:  // DLC2TreasWerewolfChestBoss
            case 0x02C456:  // DLC2TreasWarlockChestBoss
            case 0x02AAC2:  // DLC2TreasDraugrChestBoss
            case 0x02AABF:  // DLC2TreasBanditChestBoss
            case 0x02AABA:  // DLC2TreasDwarvenChestBoss
            case 0x025E46:  // DLC2TreasRieklingChestBoss
                return true;
            default:
                return false;
            }
        }
        return _stricmp(filename.data(), "_ResourcePack.esl") == 0 && localID == 0x000096;
    }

    bool IsCuratedDungeonRegularChest(RE::TESBoundObject* baseObject)
    {
        if (!baseObject || baseObject->GetFormType() != RE::FormType::Container) {
            return false;
        }
        auto* sourceFile = baseObject->GetFile(0);
        if (!sourceFile) {
            return false;
        }

        const auto localID = baseObject->GetLocalFormID();
        const auto filename = sourceFile->GetFilename();
        // Curated from the live vanilla/DLC load order: ordinary treasure-chest
        // families only. Boss and EMPTY templates are deliberately excluded,
        // as are merchant, evidence, player-storage, barrel, and sack records.
        if (_stricmp(filename.data(), "Skyrim.esm") == 0) {
            switch (localID) {
            case 0x10EE0C:  // TreasCWImperialChestCWMission07
            case 0x10EE0B:  // TreasCWSonsChestCWMission07
            case 0x10E05E:  // dunTreasMapTreasChestSpecial
            case 0x0FCB25:  // TreasExplorerLootChestSnow
            case 0x0F4A01:  // dunTreasMapTreasChest
            case 0x0F1F66:  // TreasBanditChestSnow
            case 0x0EF052:  // TreasExplorerLootChest
            case 0x0D89C6:  // TreasHouseNobleChest
            case 0x0D1259:  // TreasTreashunterChest
            case 0x0774C8:  // TreasOrcChest
            case 0x0774C6:  // TreasGiantChest
            case 0x08EA5E:  // TreasAfflictedChest
            case 0x08A3B6:  // TreasCWSonsChest
            case 0x08A3B4:  // TreasCWImperialChest
            case 0x02069A:  // TreasDwarvenChestLarge
            case 0x021363:  // TreasUpperChest
            case 0x020670:  // TreasDraugrChest
            case 0x020665:  // TreasHagravenChest
            case 0x020662:  // TreasVampireChest
            case 0x02065F:  // TreasWerewolfChest
            case 0x020659:  // TreasFalmerChest
            case 0x020654:  // TreasForswornChest
            case 0x020650:  // TreasDwarvenChestSmall
            case 0x05418E:  // TreasWarlockChest
            case 0x03AC21:  // TreasBanditChest
                return true;
            default:
                return false;
            }
        }
        if (_stricmp(filename.data(), "Dawnguard.esm") == 0) {
            switch (localID) {
            case 0x01692A:  // DLC1TreasSoulCairnChest02
            case 0x015FDD:  // DLC01TreasSnowElfChest
            case 0x015461:  // DLC1TreasSoulCairnChest
            case 0x00DCE7:  // DLC1TreasChestDarkFall01
                return true;
            default:
                return false;
            }
        }
        if (_stricmp(filename.data(), "Dragonborn.esm") == 0) {
            switch (localID) {
            case 0x03D2A1:  // DLC2dunBloodskalTreasChestLure
            case 0x035E25:  // DLC2dunFrostmoonTreasChest
            case 0x034B39:  // DLC2TreasRieklingChestSnow
            case 0x02C463:  // DLC2TreasExplorerLootChestSnow
            case 0x02C462:  // DLC2TreasExplorerLootChest
            case 0x02C460:  // DLC2TreasApocryphaChest
            case 0x02C45E:  // DLC2TreasWerebearChest
            case 0x02C458:  // DLC2TreasWerewolfChest
            case 0x02C455:  // DLC2TreasWarlockChest
            case 0x02AAC1:  // DLC2TreasDraugrChest
            case 0x02AAC0:  // DLC2TreasBanditChestSnow
            case 0x02AABE:  // DLC2TreasBanditChest
            case 0x02AABC:  // DLC2TreasDwarvenChestSmall
            case 0x02AABB:  // DLC2TreasDwarvenChestLarge
            case 0x025E48:  // DLC2TreasRieklingChest
                return true;
            default:
                return false;
            }
        }
        return false;
    }

    void SendDungeonChestEvent(
        const char* eventName, const char* chestKind, RE::TESObjectREFR* chest,
        RE::Actor* activator, RE::TESBoundObject* baseObject)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        auto* sourceFile = baseObject ? baseObject->GetFile(0) : nullptr;
        if (!source || !chest || !activator || !baseObject || !sourceFile) {
            return;
        }
        const auto chestIdentity = fmt::format("{}:{:08X}", sourceFile->GetFilename(), chest->GetFormID());
        SKSE::ModCallbackEvent event{
            RE::BSFixedString(eventName),
            RE::BSFixedString(chestIdentity),
            IsInDwarvenRuin(chest) ? 1.0f : 0.0f,
            activator
        };
        source->SendEvent(&event);
        if (_stricmp(chestKind, "regular") == 0) {
            // Ordinary chests are common. Keep their native breadcrumb below
            // the production info threshold; Papyrus owns MCM-gated tracing.
            SKSE::log::debug(
                "dungeon regular chest activated: ref {:08X}, base {}:{:06X}, actor {:08X}",
                chest->GetFormID(), sourceFile->GetFilename(), baseObject->GetLocalFormID(), activator->GetFormID());
        } else {
            SKSE::log::info(
                "dungeon {} chest activated: ref {:08X}, base {}:{:06X}, actor {:08X}",
                chestKind, chest->GetFormID(), sourceFile->GetFilename(), baseObject->GetLocalFormID(), activator->GetFormID());
        }
    }

    std::vector<RE::Actor*> GetNearbyActors(RE::StaticFunctionTag*, float radius)
    {
        // Build one deduplicated, current-cell snapshot from ProcessLists. The
        // Player is always first so Papyrus can process Player/NPC uniformly.
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
            // Require loaded 3D and the Player's exact cell before measuring
            // squared distance; this avoids handles that Papyrus cannot use.
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
        // Preserve engine role order exactly: dialogue speaker is Subject and
        // Player is Target. Papyrus callers provide both explicitly.
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

        // Return each CTDA result in record order. The aggregate engine result is
        // exposed separately so OR chains retain Skyrim's real semantics.
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

        // Descriptions are diagnostic-only. Prefer EditorID, then source/local ID
        // so overridden and master records remain identifiable in Papyrus logs.
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
        // Keep registration names synchronized with MMEExtensionsNative.psc.
        // Renaming either side is an API break for existing compiled scripts.
        vm->RegisterFunction("GetNearbyActors", "MMEExtensionsNative", GetNearbyActors);
        vm->RegisterFunction("GetFormByEditorID", "MMEExtensionsNative", GetFormByEditorID);
        vm->RegisterFunction("GetTopicInfos", "MMEExtensionsNative", GetTopicInfos);
        vm->RegisterFunction("GetPreviousTopicInfo", "MMEExtensionsNative", GetPreviousTopicInfo);
        vm->RegisterFunction("EvaluateTopicInfo", "MMEExtensionsNative", EvaluateTopicInfo);
        vm->RegisterFunction("EvaluateTopicInfoConditions", "MMEExtensionsNative", EvaluateTopicInfoConditions);
        vm->RegisterFunction("DescribeTopicInfoConditions", "MMEExtensionsNative", DescribeTopicInfoConditions);
        vm->RegisterFunction("GetFormSourceFiles", "MMEExtensionsNative", GetFormSourceFiles);
        vm->RegisterFunction("GetParentTopic", "MMEExtensionsNative", GetParentTopic);
        SKSE::log::info("Native scanner registered");
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

    std::uint64_t ActiveEffectKey(RE::TESObjectREFR* target, std::uint16_t uniqueID)
    {
        return (static_cast<std::uint64_t>(target->GetFormID()) << 16) | uniqueID;
    }

    std::unordered_map<std::uint64_t, RE::FormID> g_mmeActiveEffects;
    std::unordered_map<RE::FormID, RE::FormID> g_pendingMMEEffects;

    // MagicEffectApply identifies the base MGEF; ActiveEffectApplyRemove supplies
    // the unique runtime instance. Pairing both lets removal events name the exact
    // MME effect without unsafe VR ActiveEffect-list traversal.

    void SendPotionEvent(RE::Actor* actor, RE::TESForm* potion)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        auto* sourceFile = potion ? potion->GetFile(0) : nullptr;
        if (!source || !actor || !potion || !sourceFile) {
            return;
        }
        // Source filename + local ID survives arbitrary load order and is safely
        // reconstructed with Game.GetFormFromFile on the Papyrus side.
        SKSE::ModCallbackEvent event{
            RE::BSFixedString(kPotionEvent),
            RE::BSFixedString(sourceFile->GetFilename()),
            static_cast<float>(potion->GetLocalFormID()),
            actor
        };
        source->SendEvent(&event);
        SKSE::log::info("potion equip sent: actor {:08X}, {}:{:06X}", actor->GetFormID(), sourceFile->GetFilename(), potion->GetLocalFormID());
    }

    void SendArmorEvent(RE::Actor* actor, RE::TESForm* armor, bool equipped)
    {
        auto* source = SKSE::GetModCallbackEventSource();
        auto* sourceFile = armor ? armor->GetFile(0) : nullptr;
        if (!source || !actor || !armor || !sourceFile) {
            return;
        }
        SKSE::ModCallbackEvent event{
            RE::BSFixedString(equipped ? kArmorEvent : kArmorUnequippedEvent),
            RE::BSFixedString(sourceFile->GetFilename()),
            static_cast<float>(armor->GetLocalFormID()),
            actor
        };
        source->SendEvent(&event);
        SKSE::log::info("armor {} sent: actor {:08X}, {}:{:06X}", equipped ? "equip" : "unequip", actor->GetFormID(), sourceFile->GetFilename(), armor->GetLocalFormID());
    }

    class LifecycleEventSink final :
        public RE::BSTEventSink<RE::TESWaitStopEvent>,
        public RE::BSTEventSink<RE::TESSleepStopEvent>,
        public RE::BSTEventSink<RE::TESActorLocationChangeEvent>,
        public RE::BSTEventSink<RE::TESLoadGameEvent>,
        public RE::BSTEventSink<RE::TESMagicEffectApplyEvent>,
        public RE::BSTEventSink<RE::TESActiveEffectApplyRemoveEvent>,
        public RE::BSTEventSink<RE::TESEquipEvent>,
        public RE::BSTEventSink<RE::TESActivateEvent>,
        public RE::BSTEventSink<RE::MenuOpenCloseEvent>
    {
    public:
        static LifecycleEventSink* GetSingleton()
        {
            static LifecycleEventSink singleton;
            return std::addressof(singleton);
        }

        void Register()
        {
            // One singleton observes all engine sources. The sink never performs
            // gameplay or calls Papyrus directly; it only emits ModCallbackEvents.
            auto* holder = RE::ScriptEventSourceHolder::GetSingleton();
            holder->AddEventSink<RE::TESWaitStopEvent>(this);
            holder->AddEventSink<RE::TESSleepStopEvent>(this);
            holder->AddEventSink<RE::TESActorLocationChangeEvent>(this);
            holder->AddEventSink<RE::TESLoadGameEvent>(this);
            holder->AddEventSink<RE::TESMagicEffectApplyEvent>(this);
            holder->AddEventSink<RE::TESActiveEffectApplyRemoveEvent>(this);
            holder->AddEventSink<RE::TESEquipEvent>(this);
            holder->AddEventSink<RE::TESActivateEvent>(this);
            RE::UI::GetSingleton()->AddEventSink<RE::MenuOpenCloseEvent>(this);
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
                const auto oldVenue = FindSocialVenue(event->oldLoc);
                const auto newVenue = FindSocialVenue(event->newLoc);
                if (oldVenue.location != newVenue.location) {
                    // Publish the destination first. Papyrus can retain one
                    // shared pending drink across city/inn/palace boundaries,
                    // then safely ignore the following exit for the old venue.
                    SendSocialVenueEvent(kInnPalaceEnteredEvent, newVenue);
                    SendSocialVenueEvent(kInnPalaceExitedEvent, oldVenue);
                }
                SendLifecycleEvent("location");
            }
            return RE::BSEventNotifyControl::kContinue;
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESLoadGameEvent*, RE::BSTEventSource<RE::TESLoadGameEvent>*) override
        {
            // Runtime ActiveEffect unique IDs do not survive load. Clear both
            // pairing maps before asking Papyrus to rebuild controller state.
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

            // Publish immediately and cache per actor. The following active-effect
            // event may need this base form, especially on VR.
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
            const RE::TESEquipEvent* event,
            RE::BSTEventSource<RE::TESEquipEvent>*) override
        {
            if (!event || !event->actor) {
                return RE::BSEventNotifyControl::kContinue;
            }
            // Player potion consumption is owned by the quest alias because the
            // engine does not consistently publish it through TESEquipEvent.
            // This global sink covers NPC consumables plus all armor candidates.
            auto* actor = event->actor->As<RE::Actor>();
            auto* item = RE::TESForm::LookupByID(event->baseObject);
            if (event->equipped && actor && item && item->GetFormType() == RE::FormType::AlchemyItem &&
                actor != RE::PlayerCharacter::GetSingleton()) {
                SendPotionEvent(actor, item);
            } else if (actor && item && item->GetFormType() == RE::FormType::Armor) {
                SendArmorEvent(actor, item, event->equipped);
            }
            return RE::BSEventNotifyControl::kContinue;
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::TESActivateEvent* event,
            RE::BSTEventSource<RE::TESActivateEvent>*) override
        {
            if (!event || !event->objectActivated || !event->actionRef) {
                return RE::BSEventNotifyControl::kContinue;
            }
            auto* activator = event->actionRef->As<RE::Actor>();
            // Player activation fires before lockpicking succeeds. Dispatch the
            // player's trap only when ContainerMenu proves the chest opened.
            if (activator && activator != RE::PlayerCharacter::GetSingleton()) {
                ProcessOpenedDungeonChest(event->objectActivated.get(), activator);
            }
            return RE::BSEventNotifyControl::kContinue;
        }

        RE::BSEventNotifyControl ProcessEvent(
            const RE::MenuOpenCloseEvent* event,
            RE::BSTEventSource<RE::MenuOpenCloseEvent>*) override
        {
            if (!event || !event->opening || event->menuName != RE::ContainerMenu::MENU_NAME) {
                return RE::BSEventNotifyControl::kContinue;
            }
            const auto targetHandle = RE::ContainerMenu::GetTargetRefHandle();
            RE::NiPointer<RE::TESObjectREFR> target;
            RE::LookupReferenceByHandle(targetHandle, target);
            ProcessOpenedDungeonChest(target.get(), RE::PlayerCharacter::GetSingleton());
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
        // Event sources and loaded forms are ready only after DataLoaded.
        if (message->type == SKSE::MessagingInterface::kDataLoaded) {
            InitializeSocialVenueForms();
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
