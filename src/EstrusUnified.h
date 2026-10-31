#pragma once

#include "../include/EstrusUnifiedPolicy.h"
#include <RE/T/TESDataHandler.h>
#include <RE/O/ObjectTypeInfo.h>
#include <RE/RTTI.h>

namespace MME::Estrus
{
    // Forward only verified, non-latent native functions through the VM's own
    // marshaller. Both functions consume a prefix of our (Actor) argument frame:
    // IsReady consumes no arguments; GetPregnancyType consumes exactly that Actor.
    // No exported DLL addresses, C++ callback casts, queued calls or waiting stacks.
    class QueryFunction final : public RE::NativeFunction<std::int32_t(RE::StaticFunctionTag*, RE::Actor*)>
    {
        using NativeBase = RE::BSScript::NF_util::NativeFunctionBase;
        using VM = RE::BSScript::Internal::VirtualMachine;
        using Variable = RE::BSScript::Variable;
        using Frame = RE::BSScript::StackFrame;
        using Type = RE::BSScript::TypeInfo;

        struct API
        {
            VM& vm;
            RE::VMStackID stack;
            Variable& base;
            const Frame& frame;
            RE::Actor* actor;
            RE::BSTSmartPointer<RE::BSScript::ObjectTypeInfo> type;
            NativeBase* ready = nullptr;
            NativeBase* pregnancy = nullptr;

            bool ValidActor() const { return actor != nullptr; }
            bool Available() const
            {
                const auto data = RE::TESDataHandler::GetSingleton();
                return data && data->LookupLoadedModByName("EstrusUnified.esp") && SKSE::GetPluginInfo("EstrusUnified");
            }

            NativeBase* Find(const char* name, std::uint32_t count, Type::RawType result)
            {
                const auto entries = type->GetGlobalFuncIter();
                for (std::uint32_t i = 0; i < type->GetNumGlobalFuncs(); ++i) {
                    const auto& function = entries[i].func;
                    if (!function || function->GetName() != name) continue;
                    if (!function->GetIsNative() || !function->GetIsStatic() ||
                        function->GetParamCount() != count || function->GetStackFrameSize() != count ||
                        function->GetReturnType().GetRawType() != result) return nullptr;
                    auto native = skyrim_cast<NativeBase*>(function.get());
                    if (!native || !native->HasStub() || native->GetIsLatent()) return nullptr;
                    if (count == 1) {
                        RE::BSFixedString parameterName;
                        Type parameterType;
                        native->GetParam(0, parameterName, parameterType);
                        RE::BSTSmartPointer<RE::BSScript::ObjectTypeInfo> actorType;
                        if (!parameterType.IsObject() || !vm.GetScriptObjectType("Actor", actorType) || !actorType ||
                            parameterType.GetTypeInfo() != actorType.get() || parameterType.IsArray()) return nullptr;
                    }
                    return native;
                }
                return nullptr;
            }

            bool Resolve()
            {
                if (!vm.GetScriptObjectType("EstrusUnifiedAPI", type) || !type || !type->IsLinkedValid()) return false;
                ready = Find("IsReady", 0, Type::RawType::kBool);
                pregnancy = Find("GetPregnancyType", 1, Type::RawType::kInt);
                return ready && pregnancy;
            }

            std::int32_t Ready(bool& value)
            {
                Variable result;
                if (!ready->MarshallAndDispatch(base, vm, stack, result, frame)) return ReadyCallFailed;
                if (!result.IsBool()) return InvalidReadiness;
                value = result.GetBool();
                return 0;
            }

            std::int32_t Pregnancy(std::int32_t& value)
            {
                Variable result;
                if (!pregnancy->MarshallAndDispatch(base, vm, stack, result, frame)) return PregnancyCallFailed;
                if (!result.IsInt()) return InvalidPregnancy;
                value = result.GetSInt();
                return 0;
            }
        };

    public:
        QueryFunction() : RE::NativeFunction<std::int32_t(RE::StaticFunctionTag*, RE::Actor*)>(
            "GetEstrusUnifiedPregnancyType", "MMEExtensionsNative",
            [](RE::StaticFunctionTag*, RE::Actor*) -> std::int32_t { return InvalidAPI; }) {}

        bool MarshallAndDispatch(Variable& base, VM& vm, RE::VMStackID stack, Variable& result, const Frame& frame) const override
        {
            const auto page = frame.GetPageForFrame();
            auto actor = frame.GetStackFrameVariable(0, page).Unpack<RE::Actor*>();
            API api{ vm, stack, base, frame, actor, {}, nullptr, nullptr };
            result.SetSInt(Query(api));
            return true; // Every outcome is synchronous and selects a defined Papyrus path.
        }
    };

    inline std::mutex footprintMutex;
    inline Footprints footprints;

    inline std::int32_t Observe(RE::StaticFunctionTag*, RE::Actor* actor, std::int32_t result, bool logging)
    {
        std::scoped_lock lock(footprintMutex);
        return footprints.Observe(actor ? actor->GetFormID() : 0, result, logging);
    }

    inline void Reset()
    {
        std::scoped_lock lock(footprintMutex);
        footprints.Reset();
    }
}
