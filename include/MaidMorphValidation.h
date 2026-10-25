#pragma once

#include <array>
#include <cmath>
#include <optional>
#include <algorithm>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace MaidMorphValidation
{
    inline constexpr std::array<std::string_view, 10> Names{
        "Hips", "Butt", "Thighs", "CalfSize", "Waist", "Belly", "BigBelly", "ChubbyArms", "ChubbyLegs", "ChubbyWaist"};

    constexpr char FoldASCII(char value)
    {
        return value >= 'A' && value <= 'Z' ? static_cast<char>(value + ('a' - 'A')) : value;
    }

    constexpr std::optional<std::string_view> CanonicalName(std::string_view input)
    {
        for (auto canonical : Names) {
            if (input.size() != canonical.size()) continue;
            bool equal = true;
            for (std::size_t i = 0; i < input.size(); ++i) {
                if (FoldASCII(input[i]) != FoldASCII(canonical[i])) {
                    equal = false;
                    break;
                }
            }
            if (equal) return canonical;
        }
        return std::nullopt;
    }

    inline bool ValidValue(float value)
    {
        return std::isfinite(value) && value >= 0.0F && value <= 1.0F;
    }

    struct Prepared
    {
        std::vector<std::string_view> canonical;
        std::string normalized;
        std::string error;
    };

    inline Prepared Prepare(std::span<const std::string_view> incoming, std::span<const float> values)
    {
        Prepared result;
        if (incoming.size() != values.size()) {
            result.error = "morph/value array length mismatch";
            return result;
        }
        if (incoming.size() > Names.size()) {
            result.error = "too many morph names; maximum is 10";
            return result;
        }
        for (std::size_t i = 0; i < incoming.size(); ++i) {
            auto canonical = CanonicalName(incoming[i]);
            if (!canonical) {
                result.error = "unsupported or breast morph | name=" + std::string(incoming[i]);
                return result;
            }
            if (std::find(result.canonical.begin(), result.canonical.end(), *canonical) != result.canonical.end()) {
                result.error = "duplicate morph | name=" + std::string(incoming[i]);
                return result;
            }
            if (!ValidValue(values[i])) {
                result.error = "invalid morph value; expected finite 0..1 | name=" + std::string(incoming[i]) + " | value=" + std::to_string(values[i]);
                return result;
            }
            if (incoming[i] != *canonical) result.normalized += " " + std::string(incoming[i]) + " -> " + std::string(*canonical);
            result.canonical.push_back(*canonical);
        }
        return result;
    }
}
