"""Add a female-subject CTDA to both Extensions New Milk Maid dialogue INFOs."""
import argparse
import struct
from datetime import datetime
from pathlib import Path

from add_milk_dialogue_timing_fragment import record_editor_id, require, u16

TARGETS = {b"MMEExt_NewMilkMaid", b"MMEExt_SexLabNewMilkMaid"}
GET_IS_SEX = 43
FEMALE = 1


def female_condition(template):
    require(len(template) == 32, "Unexpected CTDA size")
    value = bytearray(template)
    value[0] = 0  # AND with the preceding backend-availability condition.
    struct.pack_into("<f", value, 4, 1.0)
    struct.pack_into("<H", value, 8, GET_IS_SEX)
    struct.pack_into("<I", value, 12, FEMALE)
    struct.pack_into("<I", value, 16, 0)
    struct.pack_into("<I", value, 20, 0)  # Subject
    struct.pack_into("<I", value, 24, 0)
    struct.pack_into("<I", value, 28, 0)
    return bytes(value)


def patch_info(payload):
    editor_id = record_editor_id(payload)
    require(editor_id in TARGETS, "Unexpected target INFO")
    parts = []
    pos = 0
    conditions = []
    insert_at = None
    while pos < len(payload):
        require(pos + 6 <= len(payload), "Truncated INFO subrecord")
        size = u16(payload, pos + 4)
        end = pos + 6 + size
        require(end <= len(payload), "Truncated INFO payload")
        part = payload[pos:end]
        if part[:4] == b"CTDA":
            value = part[6:]
            require(len(value) == 32, "Unexpected CTDA size")
            conditions.append(value)
            insert_at = len(parts) + 1
        parts.append(part)
        pos = end

    matching = [v for v in conditions if struct.unpack_from("<H", v, 8)[0] == GET_IS_SEX]
    if matching:
        require(len(matching) == 1, f"{editor_id} has duplicate GetIsSex conditions")
        require(struct.unpack_from("<I", matching[0], 12)[0] == FEMALE,
                f"{editor_id} GetIsSex does not require female")
        return payload
    require(len(conditions) == 1, f"{editor_id} expected exactly one backend condition")
    value = female_condition(conditions[0])
    parts.insert(insert_at, b"CTDA" + struct.pack("<H", len(value)) + value)
    return b"".join(parts)


def patch_plugin(data):
    seen = set()

    def walk(start, end):
        output = bytearray()
        pos = start
        while pos < end:
            require(pos + 24 <= end, "Truncated record header")
            header = bytearray(data[pos:pos + 24])
            size = struct.unpack_from("<I", header, 4)[0]
            group = header[:4] == b"GRUP"
            stop = pos + size if group else pos + 24 + size
            require(pos + 24 <= stop <= end, "Invalid record size")
            payload = data[pos + 24:stop]
            if group:
                payload = walk(pos + 24, stop)
            elif header[:4] == b"INFO" and not (struct.unpack_from("<I", header, 8)[0] & 0x00040000):
                editor_id = record_editor_id(payload)
                if editor_id in TARGETS:
                    require(editor_id not in seen, f"Duplicate target {editor_id}")
                    seen.add(editor_id)
                    payload = patch_info(payload)
            struct.pack_into("<I", header, 4, len(payload) + (24 if group else 0))
            output += header + payload
            pos = stop
        return bytes(output)

    result = walk(0, len(data))
    require(seen == TARGETS, f"Missing target INFOs: {TARGETS - seen}")
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
        require(updated == original, "New Milk Maid dialogue is not female-only")
    elif updated != original:
        backup = args.plugin.parent / "backups" / ("female-only-new-milkmaid-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
        backup.mkdir(parents=True)
        (backup / args.plugin.name).write_bytes(original)
        args.plugin.write_bytes(updated)
        print("Backup:", backup)
    print("Verified both New Milk Maid INFOs require a female subject.")
