"""Remove only Give Milk's Milkmaid-faction CTDA for universal adult routing.

The remaining non-slave gate is preserved byte-for-byte. Adult/NPC/sex-toggle
eligibility is revalidated in Papyrus before inventory or gameplay changes.
"""
import argparse
import struct
from datetime import datetime
from pathlib import Path

from add_milk_dialogue_timing_fragment import (
    TARGET_EDITOR_ID,
    TARGET_LOCAL_ID,
    record_editor_id,
    require,
    u16,
)

GET_IN_FACTION = 71
MILKMAID_FACTION = 0x0204D53B
NON_SLAVE_FACTION = 0x02056707


def condition_parameter(value):
    require(len(value) == 32, "Unexpected Give Milk CTDA size")
    return struct.unpack_from("<I", value, 12)[0]


def validate_condition(value, parameter, flags):
    require(struct.unpack_from("<f", value, 4)[0] == 1.0, "Unexpected comparison value")
    require(struct.unpack_from("<H", value, 8)[0] == GET_IN_FACTION, "Unexpected condition function")
    require(condition_parameter(value) == parameter, "Unexpected condition parameter")
    require(value[0] == flags, "Unexpected condition flags")
    require(struct.unpack_from("<I", value, 20)[0] == 0, "Unexpected run-on selector")


def patch_info_payload(payload):
    require(record_editor_id(payload) == TARGET_EDITOR_ID, "Target FormID has an unexpected EditorID")
    output = bytearray()
    pos = 0
    removed = 0
    retained = []
    while pos < len(payload):
        require(pos + 6 <= len(payload), "Truncated INFO subrecord")
        tag = payload[pos:pos + 4]
        size = u16(payload, pos + 4)
        end = pos + 6 + size
        require(end <= len(payload), "Truncated INFO subrecord payload")
        value = payload[pos + 6:end]
        if tag == b"CTDA":
            parameter = condition_parameter(value)
            if parameter == MILKMAID_FACTION:
                validate_condition(value, MILKMAID_FACTION, 0)
                removed += 1
                pos = end
                continue
            retained.append(value)
        output += payload[pos:end]
        pos = end

    require(removed in (0, 1), "Expected at most one Milkmaid condition")
    require(len(retained) == 1, "Expected exactly one retained non-slave condition")
    validate_condition(retained[0], NON_SLAVE_FACTION, 0x20)
    return bytes(output)


def patch_plugin(data):
    seen = 0

    def walk(start, end):
        nonlocal seen
        output = bytearray()
        pos = start
        while pos < end:
            require(pos + 24 <= end, "Truncated record header")
            header = bytearray(data[pos:pos + 24])
            size = struct.unpack_from("<I", header, 4)[0]
            is_group = header[:4] == b"GRUP"
            stop = pos + size if is_group else pos + 24 + size
            require(pos + 24 <= stop <= end, "Invalid record size")
            payload = data[pos + 24:stop]
            if is_group:
                payload = walk(pos + 24, stop)
            elif (struct.unpack_from("<I", header, 12)[0] & 0xFFFFFF) == TARGET_LOCAL_ID:
                require(header[:4] == b"INFO", "Target FormID is not INFO")
                require(not (struct.unpack_from("<I", header, 8)[0] & 0x40000), "Compressed target unsupported")
                seen += 1
                payload = patch_info_payload(payload)
            struct.pack_into("<I", header, 4, len(payload) + (24 if is_group else 0))
            output += header + payload
            pos = stop
        return bytes(output)

    result = walk(0, len(data))
    require(seen == 1, "Expected exactly one Give Milk INFO")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("plugin", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    original = args.plugin.read_bytes()
    updated = patch_plugin(original)
    require(patch_plugin(updated) == updated, "Patch is not idempotent")
    if args.check:
        require(updated == original, "Give Milk still has its Milkmaid-only condition")
    elif updated != original:
        backup = args.plugin.parent / "backups" / ("universal-give-milk-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
        backup.mkdir(parents=True)
        (backup / args.plugin.name).write_bytes(original)
        args.plugin.write_bytes(updated)
        print("Backup:", backup)
    print("Verified Give Milk is universal while retaining its non-slave gate.")
