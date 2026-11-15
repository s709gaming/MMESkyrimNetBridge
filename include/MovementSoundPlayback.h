#pragma once
#include <RE/Skyrim.h>
namespace MME::MovementPlayback
{
    void Initialize();
    void Reset();
    void Pause();
    void Configure(RE::StaticFunctionTag*, RE::Actor*, std::vector<std::int32_t>,
                   std::vector<float>, std::vector<float>, std::int32_t, bool, bool);
    void Remove(RE::StaticFunctionTag*, RE::Actor*);
    std::int32_t Instance(RE::StaticFunctionTag*, RE::Actor*);
}
