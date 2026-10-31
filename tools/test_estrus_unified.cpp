#include "../include/EstrusUnifiedPolicy.h"

#include <iostream>
#include <stdexcept>
#include <vector>

using namespace MME::Estrus;

void Require(bool ok, const char* reason)
{
    if (!ok) throw std::runtime_error(reason);
}

struct FakeAPI
{
    bool actor = true, esp = true, dll = true, contract = true, isReady = true;
    std::int32_t type = 0, readinessFailure = 0, pregnancyFailure = 0;
    std::vector<int> calls;
    bool ValidActor() { calls.push_back(1); return actor; }
    bool Available() { calls.push_back(2); return esp && dll; }
    bool Resolve() { calls.push_back(3); return contract; }
    std::int32_t Ready(bool& result) { calls.push_back(4); result = isReady; return readinessFailure; }
    std::int32_t Pregnancy(std::int32_t& result) { calls.push_back(5); result = type; return pregnancyFailure; }
};

int main()
{
    for (int type = 0; type <= 3; ++type) {
        FakeAPI player, npc;
        player.type = type;
        npc.type = 3 - type;
        Require(Query(player) == type && Query(npc) == 3 - type, "player/NPC query results crossed");
        Require(player.calls == std::vector<int>({1,2,3,4,5}), "ready query order changed");
        player.type = 0;
        Require(Query(player) == 0, "birth/reset reused a positive pregnancy result");
    }
    FakeAPI missingESP; missingESP.esp = false;
    FakeAPI missingDLL; missingDLL.dll = false;
    Require(Query(missingESP) == Absent && Query(missingDLL) == Absent, "optional dependency must fall back");
    Require(missingESP.calls.size() == 2 && missingDLL.calls.size() == 2, "absent dependency touched its API");
    FakeAPI invalid; invalid.actor = false;
    Require(Query(invalid) == InvalidActor && invalid.calls.size() == 1, "invalid actor reached API");
    FakeAPI contract; contract.contract = false;
    Require(Query(contract) == InvalidAPI && contract.calls.size() == 3, "invalid signature dispatched");
    FakeAPI startup; startup.isReady = false;
    Require(Query(startup) == Unready && startup.calls.size() == 4, "unready API queried pregnancy");
    startup.isReady = true; startup.type = 2;
    Require(Query(startup) == 2, "unready status was cached across initialization");
    for (auto failure : {ReadyCallFailed, InvalidReadiness}) {
        FakeAPI api; api.readinessFailure = failure;
        Require(Query(api) == failure && api.calls.size() == 4, "readiness failure did not stop query");
    }
    for (auto failure : {PregnancyCallFailed, InvalidPregnancy}) {
        FakeAPI api; api.pregnancyFailure = failure;
        Require(Query(api) == failure, "pregnancy failure lost fallback status");
    }
    for (auto type : {-1, 4, 2147483647}) {
        FakeAPI api; api.type = type;
        Require(Query(api) == InvalidPregnancy, "invalid pregnancy value accepted");
    }

    Footprints log;
    Require(log.Observe(1, Absent, false) == 0, "master off produced routine footprint");
    Require(log.Observe(1, Absent, true) == 1, "master on omitted first state");
    Require(log.Observe(2, Absent, true) == 0, "absence repeated for each actor");
    Require(log.Observe(1, Unready, true) == 1, "unready transition missing");
    Require(log.Observe(1, 1, true) == 1 && log.Observe(1, 1, true) == 0, "unchanged pregnancy spammed");
    Require(log.Observe(2, 3, true) == 1 && log.Observe(1, 1, true) == 0, "actors shared diagnostic result");
    Require(log.Observe(1, 0, true) == 1, "birth/reset footprint missing");
    Require(log.Observe(1, InvalidAPI, false) == 2, "failure alarm incorrectly master-gated");
    Require(log.Observe(2, InvalidAPI, false) == 0, "failure alarm repeated");
    Require(log.Observe(1, 0, true) == 1, "logging reenabled without state footprint");
    for (std::uint32_t id = 1; id < 1000; ++id) log.Observe(id, 0, true);
    log.Reset();
    Require(log.Observe(1, InvalidAPI, true) == 3, "load/new-game reset retained old suppression");
    std::cout << "PASS: Unified optional query/fallback, actor isolation, birth/reset, errors and bounded logging policy\n";
}
