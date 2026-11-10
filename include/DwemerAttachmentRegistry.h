#pragma once
namespace RE::BSScript { class IVirtualMachine; }
namespace MME::DwemerAttachments {
 void Register(RE::BSScript::IVirtualMachine* vm);
 void Initialize();
 void Invalidate();
}
