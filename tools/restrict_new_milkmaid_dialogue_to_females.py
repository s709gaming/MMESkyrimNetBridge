"""Fail closed unless both New Milk Maid INFOs contain GetIsSex(Female).

This checker deliberately does not author CTDA bytes. Conditions are repaired by the
typed Mutagen utility in build/mutagen-dialogue-repair, then verified here as a
lightweight packaging regression guard.
"""
import argparse
import struct
from pathlib import Path

from add_milk_dialogue_timing_fragment import record_editor_id, require, u16

TARGETS = {b"MMEExt_NewMilkMaid", b"MMEExt_SexLabNewMilkMaid"}
GET_IS_SEX = 70
SAME_RACE = 43
FEMALE = 1
SUBJECT = 0


def validate_info(payload):
    editor_id = record_editor_id(payload)
    require(editor_id in TARGETS, "Unexpected target INFO")
    conditions = []
    pos = 0
    while pos < len(payload):
        require(pos + 6 <= len(payload), "Truncated INFO subrecord")
        size = u16(payload, pos + 4)
        end = pos + 6 + size
        require(end <= len(payload), "Truncated INFO payload")
        if payload[pos:pos + 4] == b"CTDA":
            value = payload[pos + 6:end]
            require(len(value) == 32, "Unexpected CTDA size")
            conditions.append(value)
        pos = end

    require(len(conditions) == 2, f"{editor_id} expected backend gate plus female gate")
    function_ids = [struct.unpack_from("<H", value, 8)[0] for value in conditions]
    require(SAME_RACE not in function_ids,
            f"{editor_id} contains dangerous SameRace CTDA (43), not GetIsSex")
    require(function_ids[1] == GET_IS_SEX,
            f"{editor_id} second CTDA is {function_ids[1]}, expected GetIsSex (70)")
    female = conditions[1]
    require(abs(struct.unpack_from("<f", female, 4)[0] - 1.0) < 0.0001,
            f"{editor_id} GetIsSex comparison must equal 1")
    require(struct.unpack_from("<I", female, 12)[0] == FEMALE,
            f"{editor_id} GetIsSex parameter must be Female")
    require(struct.unpack_from("<I", female, 20)[0] == SUBJECT,
            f"{editor_id} GetIsSex must run on Subject")


def patch_plugin(data):
    """Compatibility entry point: validate without ever modifying plugin bytes."""
    seen = set()

    def walk(start, end):
        pos = start
        while pos < end:
            require(pos + 24 <= end, "Truncated record header")
            size = struct.unpack_from("<I", data, pos + 4)[0]
            group = data[pos:pos + 4] == b"GRUP"
            stop = pos + size if group else pos + 24 + size
            require(pos + 24 <= stop <= end, "Invalid record size")
            if group:
                walk(pos + 24, stop)
            elif data[pos:pos + 4] == b"INFO" and not (struct.unpack_from("<I", data, pos + 8)[0] & 0x00040000):
                payload = data[pos + 24:stop]
                editor_id = record_editor_id(payload)
                if editor_id in TARGETS:
                    require(editor_id not in seen, f"Duplicate target {editor_id}")
                    seen.add(editor_id)
                    validate_info(payload)
            pos = stop

    walk(0, len(data))
    require(seen == TARGETS, f"Missing target INFOs: {TARGETS - seen}")
    return data


def repair_legacy_same_race(data):
    """Change only the two known-bad SameRace function IDs; preserve all other bytes."""
    updated = bytearray(data)
    repaired = set()

    def walk(start, end):
        pos = start
        while pos < end:
            require(pos + 24 <= end, "Truncated record header")
            size = struct.unpack_from("<I", updated, pos + 4)[0]
            group = updated[pos:pos + 4] == b"GRUP"
            stop = pos + size if group else pos + 24 + size
            require(pos + 24 <= stop <= end, "Invalid record size")
            if group:
                walk(pos + 24, stop)
            elif updated[pos:pos + 4] == b"INFO" and not (struct.unpack_from("<I", updated, pos + 8)[0] & 0x00040000):
                payload_start = pos + 24
                payload = bytes(updated[payload_start:stop])
                editor_id = record_editor_id(payload)
                if editor_id in TARGETS:
                    require(editor_id not in repaired, f"Duplicate target {editor_id}")
                    condition_offsets = []
                    sub_pos = 0
                    while sub_pos < len(payload):
                        require(sub_pos + 6 <= len(payload), "Truncated INFO subrecord")
                        sub_size = u16(payload, sub_pos + 4)
                        sub_end = sub_pos + 6 + sub_size
                        require(sub_end <= len(payload), "Truncated INFO payload")
                        if payload[sub_pos:sub_pos + 4] == b"CTDA":
                            require(sub_size == 32, "Unexpected CTDA size")
                            condition_offsets.append(sub_pos + 6)
                        sub_pos = sub_end
                    require(len(condition_offsets) == 2,
                            f"{editor_id} expected exactly two CTDAs")
                    female_offset = condition_offsets[1]
                    require(struct.unpack_from("<H", payload, female_offset + 8)[0] == SAME_RACE,
                            f"{editor_id} legacy second CTDA is not SameRace (43)")
                    require(abs(struct.unpack_from("<f", payload, female_offset + 4)[0] - 1.0) < 0.0001,
                            f"{editor_id} legacy comparison is not equal to 1")
                    require(struct.unpack_from("<I", payload, female_offset + 12)[0] == FEMALE,
                            f"{editor_id} legacy parameter is not the intended Female value")
                    require(struct.unpack_from("<I", payload, female_offset + 20)[0] == SUBJECT,
                            f"{editor_id} legacy condition does not run on Subject")
                    struct.pack_into("<H", updated, payload_start + female_offset + 8, GET_IS_SEX)
                    repaired.add(editor_id)
            pos = stop

    walk(0, len(updated))
    require(repaired == TARGETS, f"Missing target INFOs: {TARGETS - repaired}")
    result = bytes(updated)
    patch_plugin(result)
    changed = sum(left != right for left, right in zip(data, result))
    require(len(data) == len(result) and changed == 2,
            f"Expected exactly two changed bytes, observed {changed}")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("plugin", type=Path)
    parser.add_argument("--check", action="store_true", help="Retained for build-script compatibility")
    parser.add_argument("--repair-legacy-same-race", action="store_true",
                        help="One-time, byte-preserving repair of the known function-ID defect")
    args = parser.parse_args()
    original = args.plugin.read_bytes()
    if args.repair_legacy_same_race:
        repaired = repair_legacy_same_race(original)
        args.plugin.write_bytes(repaired)
        print("Repaired exactly two SameRace function bytes to GetIsSex.")
        raise SystemExit(0)
    require(patch_plugin(original) == original, "Validator unexpectedly changed the plugin")
    print("Verified both New Milk Maid INFOs require a female subject.")
