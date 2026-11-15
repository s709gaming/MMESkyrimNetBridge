#include "../include/MovementPlaybackPolicy.h"
#include <cassert>
#include <iostream>
using namespace MME::MovementPlayback;
int main()
{
    assert(!HasMotion(0, 0, .05));
    assert(!HasMotion(.001F, 0, .05));
    assert(HasMotion(.1F, 0, .05)); // slow sneak
    assert(HasMotion(0, -20, .05)); // backwards/strafe
    assert(!HasMotion(10000, 0, .05)); // teleport
    assert(!HasMotion(10, 0, 0));
    assert(!HasMotion(10, 0, 1)); // stale sampling baseline
    assert(!HasMotion(NAN, 0, .05));
    assert(WantsSound(true, true, true, true, 10, 0, 11));
    assert(!WantsSound(true, true, true, false, 10, 10, 11)); // stale direction bits
    assert(!WantsSound(true, true, false, true, 10, 10, 11)); // externally pushed actor
    assert(!WantsSound(false, true, true, true, 10, 10, 11)); // lifecycle cleanup
    assert(!WantsSound(true, true, true, true, 11, 11, 11)); // lost Papyrus renewal
    assert(WantsSound(true, false, false, false, 10.8, 10, 11)); // event-only hold
    assert(!WantsSound(true, false, true, true, 10.86, 10, 11)); // missed stop expires
    assert(!WantsSound(true, false, true, true, 10, -1e20, 11)); // no step, no start
    assert(WantsSound(true, false, false, false, 10.9, 10.5, 11)); // renewed step
    std::cout << "PASS: 17 native movement policy cases\n";
}
