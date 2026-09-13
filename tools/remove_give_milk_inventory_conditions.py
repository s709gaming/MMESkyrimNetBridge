"""Remove Give Milk's five inventory CTDAs while retaining eligibility gates.

The INFO becomes available independently of inventory so Papyrus can provide
the default-on Easy Mode Jug. Lactacid is also removed from the record gate.
The rewrite is surgical, validated, backed up, and idempotent.
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

GET_ITEM_COUNT = 47
RUN_ON_TARGET = 1
EXPECTED_ITEMS = {
    0x020343F2,  # Lactacid, MilkModNEW.esp
    0x00003534,  # Jug of Milk, HearthFires.esm
    0x0205E87B,  # MME basic milk list
    0x02071C2B,  # MME racial milk list
    0x02071C2D,  # MME supernatural milk list
}


def is_inventory_condition(value):
    return (
        len(value) == 32
        and struct.unpack_from("<H", value, 8)[0] == GET_ITEM_COUNT
        and struct.unpack_from("<I", value, 20)[0] == RUN_ON_TARGET
        and struct.unpack_from("<I", value, 12)[0] in EXPECTED_ITEMS
    )


def patch_info_payload(payload):
    require(record_editor_id(payload) == TARGET_EDITOR_ID, "Target FormID has an unexpected EditorID")
    output = bytearray()
    pos = 0
    condition_count = 0
    removed_items = set()
    retained_conditions = []
    while pos < len(payload):
        require(pos + 6 <= len(payload), "Truncated INFO subrecord")
        tag = payload[pos:pos + 4]
        size = u16(payload, pos + 4)
        end = pos + 6 + size
        require(end <= len(payload), "Truncated INFO subrecord payload")
        value = payload[pos + 6:end]
        if tag == b"CTDA":
            condition_count += 1
            if is_inventory_condition(value):
                removed_items.add(struct.unpack_from("<I", value, 12)[0])
                pos = end
                continue
            retained_conditions.append(value)
        output += payload[pos:end]
        pos = end

    if condition_count == 7:
        require(removed_items == EXPECTED_ITEMS, "Give Milk inventory conditions differ from the audited set")
        require(len(retained_conditions) == 2, "Expected exactly two retained eligibility conditions")
    elif condition_count == 2:
        require(not removed_items, "Partially patched Give Milk conditions")
        require(len(retained_conditions) == 2, "Expected exactly two retained eligibility conditions")
    else:
        raise ValueError(f"Unexpected Give Milk condition count: {condition_count}")
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
        require(updated == original, "Give Milk inventory conditions still need removal")
    elif updated != original:
        backup = args.plugin.parent / "backups" / ("give-milk-easy-mode-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
        backup.mkdir(parents=True)
        (backup / args.plugin.name).write_bytes(original)
        args.plugin.write_bytes(updated)
        print("Backup:", backup)
    print("Verified Give Milk has no inventory CTDAs and retains two eligibility gates.")
