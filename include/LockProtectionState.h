#pragma once

#include <cstdint>
#include <functional>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace MME::LockProtection
{
    // Engine-free ownership policy, exercised by the native regression test.
    // Only the game-thread adapter may invoke this class.
    class State
    {
    public:
        using ID = std::uint32_t;
        struct Access
        {
            std::function<bool(ID, ID)> has;
            std::function<bool(ID, ID)> add;
            std::function<bool(ID, ID)> remove;
        };

        bool Release(ID owner, const Access& access)
        {
            const auto it = owners.find(owner);
            if (it == owners.end()) {
                // A previous release can drop the owner while a keyword removal
                // fails. Retrying must actually retry those orphan additions.
                std::vector<ID> orphans;
                for (const auto& [armor, group] : groups) {
                    if (group.owners.empty()) orphans.push_back(armor);
                }
                bool ok = true;
                for (auto armor : orphans) ok = Cleanup(armor, access) && ok;
                return ok;
            }
            const auto armor = it->second;
            owners.erase(it);
            auto& group = groups.at(armor);
            group.owners.erase(owner);
            return !group.owners.empty() || Cleanup(armor, access);
        }

        bool Acquire(ID owner, ID armor, const std::vector<ID>& keywords, const Access& access)
        {
            if (auto it = owners.find(owner); it != owners.end() && it->second != armor) {
                if (!Release(owner, access)) return false;
            }
            auto& group = groups[armor];
            for (const auto keyword : keywords) {
                if (!access.has(armor, keyword)) {
                    if (!access.add(armor, keyword) || !access.has(armor, keyword)) {
                        // Leave established owners intact; rollback an unowned partial acquire.
                        if (group.owners.empty()) Cleanup(armor, access);
                        return false;
                    }
                    group.added.insert(keyword);
                }
            }
            group.owners.insert(owner);
            owners[owner] = armor;
            return true;
        }

        bool Reset(const Access& access)
        {
            owners.clear();
            std::vector<ID> armors;
            for (auto& [armor, group] : groups) {
                group.owners.clear();
                armors.push_back(armor);
            }
            bool ok = true;
            for (auto armor : armors) ok = Cleanup(armor, access) && ok;
            return ok;
        }

    private:
        struct Group
        {
            std::unordered_set<ID> owners;
            std::unordered_set<ID> added;
        };
        std::unordered_map<ID, ID> owners;
        std::unordered_map<ID, Group> groups;

        bool Cleanup(ID armor, const Access& access)
        {
            auto& group = groups.at(armor);
            for (auto it = group.added.begin(); it != group.added.end();) {
                if (!access.has(armor, *it) || (access.remove(armor, *it) && !access.has(armor, *it))) {
                    it = group.added.erase(it);
                } else {
                    ++it;
                }
            }
            if (!group.added.empty()) return false;  // retain failed cleanup for a later reset
            groups.erase(armor);
            return true;
        }
    };
}
