#include "../include/MovementSoundPlayback.h"
#include "../include/MovementPlaybackPolicy.h"
#include <SKSE/SKSE.h>
#include <algorithm>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <thread>
#include <unordered_map>

#undef min
#undef max

namespace MME::MovementPlayback
{
    namespace
    {
        using Clock = std::chrono::steady_clock;
        double Now() { return std::chrono::duration<double>(Clock::now().time_since_epoch()).count(); }
        struct Slot
        {
            RE::ActorHandle actor;
            std::vector<std::int32_t> choices;
            std::vector<float> gains, sneakGains;
            RE::BSSoundHandle sound;
            RE::NiPoint3 position{};
            double sampled = 0, footstep = -1e20, lease = 0, nextPoll = 0;
            int base = 0, choice = -1;
            bool polling = true, trace = false, playing = false, alarm = false, stepPending = false;
        };
        struct State
        {
            std::mutex mutex;
            std::condition_variable wake;
            std::unordered_map<RE::FormID, Slot> actors;
            std::uint64_t generation = 0;
            bool pending = false;
        };
        State& Data() { static auto* value = new State; return *value; }
        void Trace(RE::FormID id, const Slot& slot, std::string_view action)
        {
            if (!slot.trace) return;
            SKSE::log::info("[MME Movement Native] actor={:08X} | {} | instance={}", id, action, slot.sound.soundID);
            if (auto* source = SKSE::GetModCallbackEventSource()) {
                const SKSE::ModCallbackEvent event{ "MMEExtensions_MovementAudioTrace",
                    std::string(action) + " | actor=" + std::to_string(id), 0.0F, nullptr };
                source->SendEvent(&event);
            }
        }
        void Alarm(RE::FormID id, std::string_view reason)
        {
            SKSE::log::error("[MME Movement Native] actor={:08X} | {}", id, reason);
            if (auto* source = SKSE::GetModCallbackEventSource()) {
                const SKSE::ModCallbackEvent event{ "MMEExtensions_MovementAudioAlarm",
                    std::string(reason) + " | actor=" + std::to_string(id), 0.0F, nullptr };
                source->SendEvent(&event);
            }
        }
        void Stop(RE::FormID id, Slot& slot, std::string_view reason)
        {
            if (!slot.playing) return;
            // Silence before release as well: no residual loop during audio-thread cleanup.
            slot.sound.SetVolume(0.0F);
            slot.sound.Stop();
            Trace(id, slot, reason);
            slot.sound = RE::BSSoundHandle{};
            slot.playing = false;
            slot.choice = -1;
        }
        bool Allowed(RE::Actor* actor)
        {
            auto* ui = RE::UI::GetSingleton();
            auto* player = RE::PlayerCharacter::GetSingleton();
            if (!actor || !player || !ui || ui->GameIsPaused() || ui->IsMenuOpen("Dialogue Menu") ||
                ui->IsMenuOpen("InventoryMenu") || ui->IsMenuOpen("Journal Menu") ||
                actor->IsDead() || actor->IsDisabled() || !actor->Is3DLoaded() || actor->IsOnMount() ||
                actor->IsInMidair() || actor->GetParentCell() != player->GetParentCell()) return false;
            auto delta = actor->GetPosition() - player->GetPosition();
            if (delta.SqrLength() > 2000.0F * 2000.0F) return false;
            const auto* state = actor->AsActorState();
            return state && !state->IsSwimming() && !state->IsUnconscious() &&
                state->GetKnockState() == RE::KNOCK_STATE_ENUM::kNormal &&
                state->GetSitSleepState() == RE::SIT_SLEEP_STATE::kNormal;
        }
        void Reconcile(RE::FormID id, Slot& slot, double now, bool step)
        {
            auto actor = slot.actor.get();
            if (!actor || now >= slot.lease || !Allowed(actor.get())) {
                Stop(id, slot, "stop: lifecycle/eligibility");
                slot.sampled = 0;
                slot.footstep = -1e20;
                return;
            }
            const auto* state = actor->AsActorState();
            const auto& flags = state->actorState1;
            const bool direction = flags.movingForward || flags.movingBack || flags.movingLeft || flags.movingRight;
            auto position = actor->GetPosition();
            const bool motion = slot.sampled > 0 && HasMotion(position.x - slot.position.x,
                position.y - slot.position.y, now - slot.sampled);
            slot.position = position;
            slot.sampled = now;
            if (step && direction) slot.footstep = now;
            if (!WantsSound(true, slot.polling, direction, motion || (step && direction), now, slot.footstep, slot.lease)) {
                Stop(id, slot, "stop: stationary/step expired");
                return;
            }
            const int route = slot.base + (state->IsSprinting() && !state->IsSneaking() ? 1 : 0);
            const int choice = slot.choices[route];
            const float gain = state->IsSneaking() ? slot.sneakGains[route] : slot.gains[route];
            if (choice == 0 || gain <= 0) { Stop(id, slot, "stop: muted"); return; }
            if (slot.playing && slot.choice != choice) Stop(id, slot, "stop: route changed");
            if (!slot.playing) {
                constexpr RE::FormID forms[]{ 0, 0x8D4, 0x8D6, 0x8D8, 0x8C5 };
                auto* handler = RE::TESDataHandler::GetSingleton();
                auto* sound = handler ? handler->LookupForm<RE::TESSound>(forms[choice], "MMEAlert.esp") : nullptr;
                auto* audio = RE::BSAudioManager::GetSingleton();
                bool ok = audio && sound && sound->descriptor &&
                    audio->GetSoundHandle(slot.sound, sound->descriptor);
                if (ok) {
                    slot.sound.SetPosition(position);
                    slot.sound.SetObjectToFollow(actor->Get3D());
                    slot.sound.SetVolume(gain);
                    ok = slot.sound.Play();
                }
                if (!ok) {
                    slot.sound.Stop();
                    if (!slot.alarm) Alarm(id, "start failed: descriptor/handle/play unavailable");
                    slot.alarm = true;
                    return;
                }
                slot.alarm = false;
                slot.playing = true;
                slot.choice = choice;
                Trace(id, slot, "start");
            } else slot.sound.SetVolume(gain);
        }
        // Worker does not touch the engine. At most one timer task is outstanding.
        void Worker()
        {
            auto& data = Data();
            std::unique_lock lock(data.mutex);
            for (;;) {
                double deadline = 1e30;
                const double now = Now();
                for (const auto& [id, slot] : data.actors) {
                    (void)id;
                    deadline = std::min(deadline, slot.lease);
                    if (slot.polling) deadline = std::min(deadline, slot.nextPoll);
                    else if (slot.playing) deadline = std::min(deadline, slot.footstep + FootstepHold);
                }
                if (data.pending || data.actors.empty()) { data.wake.wait(lock); continue; }
                if (data.wake.wait_for(lock, std::chrono::duration<double>(std::max(0.001, deadline - now))) != std::cv_status::timeout) continue;
                data.pending = true;
                const auto epoch = data.generation;
                lock.unlock();
                SKSE::GetTaskInterface()->AddTask([epoch] {
                    auto& state = Data();
                    std::scoped_lock guard(state.mutex);
                    if (epoch != state.generation) return;
                    const double current = Now();
                    for (auto it = state.actors.begin(); it != state.actors.end();) {
                        auto& slot = it->second;
                        if (current >= slot.lease) {
                            Stop(it->first, slot, "stop: permission expired");
                            it = state.actors.erase(it);
                        } else {
                            if (slot.polling && current >= slot.nextPoll) {
                                Reconcile(it->first, slot, current, false);
                                slot.nextPoll = current + 0.05;
                            }
                            else if (slot.playing && current >= slot.footstep + FootstepHold)
                                Stop(it->first, slot, "stop: step timeout");
                            ++it;
                        }
                    }
                    state.pending = false;
                    state.wake.notify_one();
                });
                lock.lock();
            }
        }
        class Footsteps final : public RE::BSTEventSink<RE::BGSFootstepEvent>
        {
            RE::BSEventNotifyControl ProcessEvent(const RE::BGSFootstepEvent* event,
                RE::BSTEventSource<RE::BGSFootstepEvent>*) override
            {
                if (!event) return RE::BSEventNotifyControl::kContinue;
                auto& data = Data();
                std::scoped_lock lock(data.mutex);
                // Match weak handles without resolving actor pointers on this event thread.
                for (auto& [id, slot] : data.actors) {
                    if (slot.actor != event->actor) continue;
                    if (slot.stepPending) break;
                    slot.stepPending = true;
                    const auto epoch = data.generation;
                    SKSE::GetTaskInterface()->AddTask([id, epoch] {
                        auto& state = Data();
                        std::scoped_lock guard(state.mutex);
                        auto it = state.actors.find(id);
                        if (epoch == state.generation && it != state.actors.end()) {
                            it->second.stepPending = false;
                            Reconcile(id, it->second, Now(), true);
                            state.wake.notify_one();
                        }
                    });
                    break;
                }
                return RE::BSEventNotifyControl::kContinue;
            }
        };
    }
    void Initialize()
    {
        static bool initialized = false;
        if (initialized) return;
        initialized = true;
        static auto* sink = new Footsteps;
        if (auto* source = RE::BGSFootstepManager::GetSingleton()) source->AddEventSink(sink);
        else SKSE::log::error("[MME Movement Native] footstep event source unavailable");
        std::thread(Worker).detach();
    }
    void Configure(RE::StaticFunctionTag*, RE::Actor* actor, std::vector<std::int32_t> choices,
        std::vector<float> gains, std::vector<float> sneakGains, std::int32_t base, bool polling, bool trace)
    {
        if (!actor || choices.size() != 4 || gains.size() != 4 || sneakGains.size() != 4 || (base != 0 && base != 2)) return;
        for (std::size_t i = 0; i < 4; ++i) {
            if (choices[i] < 0 || choices[i] > 4 || !std::isfinite(gains[i]) || !std::isfinite(sneakGains[i])) return;
            gains[i] = std::clamp(gains[i], 0.0F, 1.0F);
            sneakGains[i] = std::clamp(sneakGains[i], 0.0F, 1.0F);
        }
        auto handle = actor->GetHandle();
        const auto id = actor->GetFormID();
        auto& data = Data();
        std::scoped_lock lock(data.mutex);
        const auto epoch = data.generation;
        SKSE::GetTaskInterface()->AddTask([handle, id, epoch, choices, gains, sneakGains, base, polling, trace] {
            auto& state = Data();
            std::scoped_lock guard(state.mutex);
            if (epoch != state.generation) return;
            if (!state.actors.contains(id) && state.actors.size() >= MaxActors) return;
            auto& slot = state.actors[id];
            if (slot.polling != polling) {
                Stop(id, slot, "stop: polling mode changed");
                slot.sampled = 0;
                slot.footstep = -1e20;
            }
            slot.actor = handle; slot.choices = choices; slot.gains = gains;
            slot.sneakGains = sneakGains; slot.base = base; slot.polling = polling; slot.trace = trace;
            slot.lease = Now() + LeaseSeconds;
            if (slot.nextPoll <= 0) slot.nextPoll = Now() + 0.05;
            // Configuration renewal does not secretly poll movement in event-only mode.
            state.wake.notify_one();
        });
    }
    void Remove(RE::StaticFunctionTag*, RE::Actor* actor)
    {
        if (!actor) return;
        const auto id = actor->GetFormID();
        auto& data = Data();
        std::scoped_lock lock(data.mutex);
        const auto epoch = data.generation;
        SKSE::GetTaskInterface()->AddTask([id, epoch] {
            auto& state = Data(); std::scoped_lock guard(state.mutex);
            auto it = state.actors.find(id);
            if (epoch != state.generation || it == state.actors.end()) return;
            Stop(id, it->second, "stop: Papyrus eligibility withdrawn");
            state.actors.erase(it); state.wake.notify_one();
        });
    }
    std::int32_t Instance(RE::StaticFunctionTag*, RE::Actor* actor)
    {
        if (!actor) return -1;
        auto& data = Data(); std::scoped_lock lock(data.mutex);
        auto it = data.actors.find(actor->GetFormID());
        return it != data.actors.end() && it->second.playing ? static_cast<std::int32_t>(it->second.sound.soundID) : -1;
    }
    void Pause()
    {
        auto& data = Data(); std::scoped_lock lock(data.mutex);
        for (auto& [id, slot] : data.actors) {
            Stop(id, slot, "stop: menu/lifecycle event"); slot.sampled = 0; slot.footstep = -1e20;
        }
    }
    void Reset()
    {
        Pause();
        auto& data = Data(); std::scoped_lock lock(data.mutex);
        ++data.generation; data.actors.clear(); data.pending = false; data.wake.notify_one();
    }
}
