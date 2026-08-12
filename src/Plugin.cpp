#include <SKSE/SKSE.h>

#include <spdlog/sinks/basic_file_sink.h>

namespace
{
    void InitializeLogging()
    {
        const auto logDirectory = SKSE::log::log_directory();
        if (!logDirectory) {
            SKSE::stl::report_and_fail("Unable to locate the SKSE log directory");
        }

        const auto logPath = *logDirectory / "MMEAlertTest.log";
        const auto logger = std::make_shared<spdlog::logger>(
            "global log",
            std::make_shared<spdlog::sinks::basic_file_sink_mt>(logPath.string(), true));

        spdlog::set_default_logger(logger);
        spdlog::set_level(spdlog::level::info);
        spdlog::flush_on(spdlog::level::info);
    }
}

SKSEPluginLoad(const SKSE::LoadInterface* skse)
{
    InitializeLogging();
    SKSE::Init(skse);

    SKSE::log::info("MMEAlertTest loaded successfully through CommonLibSSE-NG");
    SKSE::log::info("Runtime version: {}", skse->RuntimeVersion().string());
    return true;
}
