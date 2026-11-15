#pragma once
#include <cmath>
namespace MME::MovementPlayback
{
    // Pure policy shared by production and the standalone regression executable.
    constexpr double FootstepHold = 0.85;
    constexpr double LeaseSeconds = 8.0;
    constexpr unsigned MaxActors = 32;
    inline bool HasMotion(float dx, float dy, double seconds)
    {
        if (seconds <= 0.0 || seconds > 0.5) return false;
        const auto speed2 = (dx * dx + dy * dy) / (seconds * seconds);
        // Reject numerical drift and teleports; retain very slow sneak movement.
        return std::isfinite(speed2) && speed2 >= 1.0 && speed2 < 4000000.0;
    }
    inline bool WantsSound(bool allowed, bool polling, bool direction, bool displacement,
                           double now, double footstep, double lease)
    {
        return allowed && now < lease && (polling ? direction && displacement : now < footstep + FootstepHold);
    }
}
