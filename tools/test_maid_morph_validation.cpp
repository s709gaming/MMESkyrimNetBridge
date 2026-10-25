#include "../include/MaidMorphValidation.h"

#include <iostream>
#include <limits>
#include <stdexcept>

namespace
{
    void Require(bool condition, const char* message)
    {
        if (!condition) throw std::runtime_error(message);
    }
}

int main()
{
    using namespace MaidMorphValidation;
    std::size_t variants = 0;
    const std::array<float, 1> one{ 1.0F };
    for (auto canonical : Names) {
        // Exercise the same full request preparation used by the DLL, including
        // every ASCII case combination Papyrus's intern pool could provide.
        for (std::size_t mask = 0; mask < (std::size_t{1} << canonical.size()); ++mask) {
            std::string variant(canonical);
            for (std::size_t i = 0; i < variant.size(); ++i) {
                variant[i] = FoldASCII(variant[i]);
                if ((mask & (std::size_t{1} << i)) != 0) variant[i] = static_cast<char>(variant[i] - ('a' - 'A'));
            }
            std::array<std::string_view, 1> incoming{ variant };
            auto result = Prepare(incoming, one);
            Require(result.error.empty() && result.canonical.size() == 1 && result.canonical[0] == canonical, "case variant rejected or mapped incorrectly");
            ++variants;
        }
    }
    Require(Prepare({}, {}).error.empty(), "empty cleanup rejected");
    Require(!Prepare(Names, one).error.empty(), "array length mismatch accepted");
    for (auto disallowed : { "Breasts", "breastsfantasy", "BreastsNewSH", "NPC L Breast", "", " Hips", "Hips ", "HipsExtra" }) {
        std::array<std::string_view, 1> names{ disallowed };
        Require(!Prepare(names, one).error.empty(), "unsupported/breast morph accepted");
    }
    const std::array<std::string_view, 1> hip{ "hips" };
    for (float invalid : { -0.001F, 1.001F, std::numeric_limits<float>::infinity(), -std::numeric_limits<float>::infinity(), std::numeric_limits<float>::quiet_NaN() }) {
        std::array<float, 1> values{ invalid };
        Require(!Prepare(hip, values).error.empty(), "invalid value accepted");
    }
    for (float valid : { 0.0F, 0.5F, 1.0F }) {
        std::array<float, 1> values{ valid };
        Require(Prepare(hip, values).error.empty(), "valid endpoint/fraction rejected");
    }
    std::array<std::string_view, 2> duplicate{ "Hips", "hIPS" };
    const std::array<float, 2> two{ 0.0F, 1.0F };
    Require(Prepare(duplicate, two).error.find("duplicate") != std::string::npos, "case-insensitive duplicate accepted");
    std::vector<std::string_view> tooMany(11, "Hips");
    std::vector<float> tooManyValues(11, 0.5F);
    Require(Prepare(tooMany, tooManyValues).error.find("too many") != std::string::npos, "oversized request accepted");
    const std::array<std::string_view, 2> observed{ "hips", "waist" };
    auto observedResult = Prepare(observed, two);
    Require(observedResult.error.empty() && observedResult.normalized.find("hips -> Hips") != std::string::npos && observedResult.normalized.find("waist -> Waist") != std::string::npos, "observed runtime regression or diagnostic mapping failed");
    std::vector<float> allValues(Names.size(), 0.5F);
    Require(Prepare(Names, allValues).canonical.size() == Names.size(), "full curated request failed");
    std::cout << "PASS: " << variants << " case variants, runtime regression, invalid names/values, duplicates, array bounds, full request, and empty cleanup\n";
}
