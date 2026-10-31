#pragma once

#include <cstdint>
#include <unordered_map>

namespace MME::Estrus
{
    // Negative outcomes select MME's existing pregnancy checks, never a cached answer.
    enum Result : std::int32_t {
        Absent = -1, Unready = -2, InvalidActor = -3, InvalidAPI = -4,
        ReadyCallFailed = -5, InvalidReadiness = -6, PregnancyCallFailed = -7,
        InvalidPregnancy = -8
    };

    template <class API>
    std::int32_t Query(API& api)
    {
        if (!api.ValidActor()) return InvalidActor;
        if (!api.Available()) return Absent;
        if (!api.Resolve()) return InvalidAPI;
        bool ready = false;
        const auto readyStatus = api.Ready(ready);
        if (readyStatus != 0) return readyStatus;
        if (!ready) return Unready;
        std::int32_t type = 0;
        const auto pregnancyStatus = api.Pregnancy(type);
        if (pregnancyStatus != 0) return pregnancyStatus;
        return type >= 0 && type <= 3 ? type : InvalidPregnancy;
    }

    // Diagnostic history only: bounded, process-local, reset at game load/new game.
    // It never supplies a gameplay result or retains Actor pointers.
    class Footprints
    {
    public:
        std::int32_t Observe(std::uint32_t actor, std::int32_t result, bool logging)
        {
            std::int32_t flags = 0;
            if (result <= InvalidActor && result >= InvalidPregnancy) {
                const auto bit = 1U << static_cast<unsigned>(-result);
                if (!(alarms_ & bit)) { alarms_ |= bit; flags |= 2; }
            }
            if (!logging) {
                results_.clear();
                availability_ = -100;
                return flags;
            }
            // Absent/unready are integration-wide: do not repeat for every actor.
            const auto state = result >= 0 ? 0 : result;
            if (state != availability_) { availability_ = state; flags |= 1; }
            if (result >= 0) {
                auto found = results_.find(actor);
                if (found == results_.end() || found->second != result) {
                    if (results_.size() >= 128) results_.clear();
                    results_[actor] = result;
                    flags |= 1;
                }
            }
            return flags;
        }

        void Reset() { results_.clear(); availability_ = -100; alarms_ = 0; }

    private:
        std::unordered_map<std::uint32_t, std::int32_t> results_;
        std::int32_t availability_ = -100;
        std::uint32_t alarms_ = 0;
    };
}
