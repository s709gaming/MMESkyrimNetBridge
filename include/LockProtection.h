#pragma once

namespace RE::BSScript { class IVirtualMachine; }
namespace MME::LockProtection
{
    void Register(RE::BSScript::IVirtualMachine* vm);
    void ResetSession();
}
