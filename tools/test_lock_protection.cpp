#include "../include/LockProtectionState.h"
#include <set>
#include <stdexcept>
#include <iostream>

int main()
{
    using MME::LockProtection::State;
    std::set<std::pair<State::ID, State::ID>> tags;
    bool failAdd = false, failRemove = false;
    State::ID failKeyword = 0;
    State::Access access{
        [&](auto a, auto k) { return tags.contains({a, k}); },
        [&](auto a, auto k) { return !failAdd && k != failKeyword && tags.insert({a, k}).second; },
        [&](auto a, auto k) { return !failRemove && tags.erase({a, k}) != 0; }
    };
    const auto require = [](bool ok) { if (!ok) throw std::runtime_error("lock protection regression"); };
    State state;
    // Neither / either / both optional frameworks; no duplicate ownership.
    for (auto keywords : {std::vector<State::ID>{}, {11}, {22}, {11, 22}}) {
        require(state.Acquire(1, 100, keywords, access));
        require(state.Acquire(1, 100, keywords, access));
        require(state.Release(1, access));
        require(tags.empty());
    }
    // One release must not expose the other actor's locked copy of the same form.
    require(state.Acquire(1, 100, {11, 22}, access));
    require(state.Acquire(2, 100, {11, 22}, access));
    require(state.Release(1, access));
    require(tags.size() == 2);
    require(state.Release(2, access));
    require(tags.empty());
    // Existing mod/user tags survive; our additions to other forms are independent.
    tags.insert({100, 11});
    require(state.Acquire(1, 100, {11, 22}, access));
    require(state.Acquire(2, 200, {11, 22}, access));
    require(state.Release(1, access));
    require(tags.contains({100, 11}) && !tags.contains({100, 22}));
    require(tags.contains({200, 11}) && tags.contains({200, 22}));
    require(state.Reset(access));
    require(tags.size() == 1);
    // Owner switches forms; previous owned tags are released.
    require(state.Acquire(1, 100, {11, 22}, access));
    require(state.Acquire(1, 200, {11, 22}, access));
    require(!tags.contains({100, 22}) && tags.contains({200, 22}));
    require(state.Reset(access));
    // Failed acquire never gains an owner; cleanup failure is retained for retry.
    failAdd = true;
    require(!state.Acquire(1, 100, {22}, access));
    require(state.Release(1, access));
    failAdd = false;
    // A failure on the second framework rolls back our first new keyword.
    failKeyword = 33;
    require(!state.Acquire(1, 300, {22, 33}, access));
    require(!tags.contains({300, 22}));
    failKeyword = 0;
    require(state.Acquire(1, 100, {22}, access));
    failRemove = true;
    require(!state.Release(1, access));
    require(!state.Release(1, access));
    require(!state.Reset(access));
    failRemove = false;
    require(state.Release(1, access));
    require(tags.size() == 1 && tags.contains({100, 11}));
    // Reconcile an externally removed owned tag without losing shared ownership.
    require(state.Acquire(1, 100, {22}, access));
    tags.erase({100, 22});
    require(state.Acquire(1, 100, {22}, access));
    require(tags.contains({100, 22}));
    require(state.Release(1, access));
    std::cout << "lock protection ownership matrix passed\n";
}
