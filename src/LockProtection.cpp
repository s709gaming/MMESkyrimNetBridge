#include <SKSE/SKSE.h>
#include <RE/A/Actor.h>
#include <RE/B/BGSKeyword.h>
#include <RE/T/TESObjectARMO.h>
#include <RE/T/TESDataHandler.h>
#include <RE/T/TESFile.h>
#include <RE/N/NativeFunction.h>
#include "../include/LockProtection.h"
#include "../include/LockProtectionState.h"
#include <mutex>
#include <limits>

namespace MME::LockProtection
{
    namespace
    {
        std::mutex mutex;
        State state;
        struct Request { std::int32_t token; RE::FormID armor; std::int32_t result; };
        std::unordered_map<RE::FormID, Request> requests;
        std::unordered_set<RE::FormID> failedOwners;
        std::uint64_t generation = 0;
        std::int32_t nextToken = 0;

        RE::TESObjectARMO* Armor(State::ID id) { return RE::TESForm::LookupByID<RE::TESObjectARMO>(id); }
        RE::BGSKeyword* Keyword(State::ID id) { return RE::TESForm::LookupByID<RE::BGSKeyword>(id); }
        const State::Access access{
            [](auto armor, auto keyword) { auto* a = Armor(armor); auto* k = Keyword(keyword); return a && k && a->HasKeyword(k); },
            [](auto armor, auto keyword) { auto* a = Armor(armor); auto* k = Keyword(keyword); return a && k && a->AddKeyword(k); },
            [](auto armor, auto keyword) { auto* a = Armor(armor); auto* k = Keyword(keyword); return a && k && a->RemoveKeyword(k); }
        };

        // Called inside the game-thread task. No optional framework Papyrus dependency.
        bool ResolveKeywords(std::vector<State::ID>& keywords)
        {
            auto* handler = RE::TESDataHandler::GetSingleton();
            if (!handler) return false;
            for (const auto& [plugin, local] : {
                std::pair{ "OStim.esp", 0x000DB1u }, std::pair{ "SexLab.esm", 0x02F16Eu } }) {
                const auto* file = handler->LookupModByName(plugin);
                if (!file || file->GetCompileIndex() == 0xFF) continue;
                auto* keyword = handler->LookupForm<RE::BGSKeyword>(local, plugin);
                if (!keyword) return false;  // loaded plugin with a broken prerequisite
                keywords.push_back(keyword->GetFormID());
            }
            return true;
        }

        std::int32_t Queue(RE::StaticFunctionTag*, RE::Actor* actor, RE::TESObjectARMO* armor)
        {
            if (!actor) return 0;
            const auto owner = actor->GetFormID();
            const auto armorID = armor ? armor->GetFormID() : 0;
            const auto handle = actor->GetHandle();
            std::scoped_lock lock(mutex);
            if (const auto it = requests.find(owner); it != requests.end() &&
                it->second.armor == armorID && it->second.result >= 0) return it->second.token;
            if (nextToken == std::numeric_limits<std::int32_t>::max()) return 0;
            const auto token = ++nextToken;
            const auto session = generation;
            requests[owner] = { token, armorID, 0 };
            SKSE::GetTaskInterface()->AddTask([owner, armorID, handle, token, session]() {
                std::scoped_lock taskLock(mutex);
                const auto it = requests.find(owner);
                if (generation != session || it == requests.end() || it->second.token != token) return;
                bool ok = true;
                if (armorID) {
                    std::vector<State::ID> keywords;
                    ok = handle.get() && Armor(armorID) && ResolveKeywords(keywords) && state.Acquire(owner, armorID, keywords, access);
                } else {
                    ok = state.Release(owner, access);
                }
                it->second.result = ok ? 1 : -1;
                if (ok) failedOwners.erase(owner);
                else if (failedOwners.insert(owner).second) SKSE::log::error("[MME Lock Protection] operation={} actor={:08X} armor={:08X}: loaded framework keyword missing, armor/actor unresolved, or keyword mutation failed", armorID ? "acquire" : "release", owner, armorID);
            });
            return token;
        }

        std::int32_t Result(RE::StaticFunctionTag*, RE::Actor* actor, std::int32_t token)
        {
            if (!actor || token <= 0) return -1;
            std::scoped_lock lock(mutex);
            const auto it = requests.find(actor->GetFormID());
            return it != requests.end() && it->second.token == token ? it->second.result : -2;
        }

        void Reset(RE::StaticFunctionTag*) { ResetSession(); }
    }

    void ResetSession()
    {
        std::scoped_lock lock(mutex);
        const auto session = ++generation;
        requests.clear();
        failedOwners.clear();
        SKSE::GetTaskInterface()->AddTask([session]() {
            std::scoped_lock taskLock(mutex);
            if (generation != session) return;
            if (!state.Reset(access)) SKSE::log::error("[MME Lock Protection] session cleanup failed: owned keyword removal failed");
        });
    }

    void Register(RE::BSScript::IVirtualMachine* vm)
    {
        vm->RegisterFunction("QueueLockProtection", "MMEExtensionsNative", Queue);
        vm->RegisterFunction("GetLockProtectionResult", "MMEExtensionsNative", Result);
        vm->RegisterFunction("ResetLockProtection", "MMEExtensionsNative", Reset);
    }
}
