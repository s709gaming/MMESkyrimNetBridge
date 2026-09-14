"""Remove the copied PreviousDialog (PNAM) from the Give Milk INFO.

MMEExt_DialogueDrinkMilk was cloned from a sequenced MME response and retained
its link to the preceding "Would you like to become Milkmaid?" INFO. A standalone
player choice must not carry that forced-sequence link. The rewrite is surgical,
validated, backed up, and idempotent.
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

EXPECTED_PREVIOUS_DIALOG = 0x0205FE0F


def patch_info_payload(payload):
    require(record_editor_id(payload) == TARGET_EDITOR_ID, "Target FormID has an unexpected EditorID")
    output = bytearray()
    pos = 0
    removed = 0
    while pos < len(payload):
        require(pos + 6 <= len(payload), "Truncated INFO subrecord")
        tag = payload[pos:pos + 4]
        size = u16(payload, pos + 4)
        end = pos + 6 + size
        require(end <= len(payload), "Truncated INFO subrecord payload")
        value = payload[pos + 6:end]
        if tag == b"PNAM":
            require(size == 4, "Unexpected Give Milk PNAM size")
            require(struct.unpack("<I", value)[0] == EXPECTED_PREVIOUS_DIALOG, "Give Milk points at an unexpected PreviousDialog")
            removed += 1
            pos = end
            continue
        output += payload[pos:end]
        pos = end

    require(removed in (0, 1), "Expected at most one Give Milk PreviousDialog")
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
        require(updated == original, "Give Milk still carries its copied PreviousDialog")
    elif updated != original:
        backup = args.plugin.parent / "backups" / ("give-milk-previous-dialog-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
        backup.mkdir(parents=True)
        (backup / args.plugin.name).write_bytes(original)
        args.plugin.write_bytes(updated)
        print("Backup:", backup)
    print("Verified Give Milk is an independent INFO with no PreviousDialog.")
