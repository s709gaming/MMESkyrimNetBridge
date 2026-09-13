"""Add an OnBegin timing fragment to the existing Give Milk INFO.

The target already owns MMENPCDialog.Fragment_0 as its sole OnEnd fragment.
This surgical rewrite preserves every other plugin byte and is idempotent.
"""
import argparse
import struct
from datetime import datetime
from pathlib import Path

TARGET_LOCAL_ID = 0x857
TARGET_EDITOR_ID = b"MMEExt_DialogueDrinkMilk"
SCRIPT = b"MMENPCDialog"
BEGIN = b"Fragment_TimingBegin"
END = b"Fragment_0"


def require(condition, detail):
    if not condition:
        raise ValueError(detail)


def u16(data, pos):
    return struct.unpack_from("<H", data, pos)[0]


def packed_string(value):
    return struct.pack("<H", len(value)) + value


def read_string(data, pos):
    end = pos + 2 + u16(data, pos)
    require(end <= len(data), "Truncated VMAD string")
    return data[pos + 2:end], end


def read_fragment(data, pos):
    require(pos < len(data), "Missing INFO fragment entry")
    marker = data[pos:pos + 1]
    script_name, pos = read_string(data, pos + 1)
    function_name, pos = read_string(data, pos)
    return marker, script_name, function_name, pos


def patch_vmad(data):
    require(u16(data, 0) == 5 and u16(data, 2) == 2, "Unexpected VMAD version/format")
    require(u16(data, 4) == 1, "Unexpected VMAD script count")
    script_name, pos = read_string(data, 6)
    require(script_name == SCRIPT, "Unexpected attached script")
    pos += 1
    property_count = u16(data, pos)
    pos += 2
    require(property_count == 0, "Target MMENPCDialog unexpectedly has VMAD properties")
    require(data[pos] == 2 and data[pos + 1] in (2, 3), "Unexpected INFO fragment header")
    flags_pos = pos + 1
    flags = data[flags_pos]
    fragment_file, pos = read_string(data, pos + 2)
    require(fragment_file == SCRIPT, "Unexpected fragment filename")
    fragment_start = pos

    if flags == 3:
        _, begin_script, begin_function, pos = read_fragment(data, pos)
        _, end_script, end_function, pos = read_fragment(data, pos)
        require(begin_script == SCRIPT and begin_function == BEGIN, "Existing OnBegin differs")
        require(end_script == SCRIPT and end_function == END, "Existing OnEnd differs")
        require(pos == len(data), "Trailing VMAD data")
        return data

    marker, end_script, end_function, pos = read_fragment(data, pos)
    require(end_script == SCRIPT and end_function == END, "Existing OnEnd differs")
    require(pos == len(data), "Trailing VMAD data")
    begin_entry = marker + packed_string(SCRIPT) + packed_string(BEGIN)
    return data[:flags_pos] + b"\x03" + data[flags_pos + 1:fragment_start] + begin_entry + data[fragment_start:]


def record_editor_id(payload):
    pos = 0
    while pos < len(payload):
        require(pos + 6 <= len(payload), "Truncated INFO subrecord")
        tag = payload[pos:pos + 4]
        require(tag != b"XXXX", "Extended target subrecord unsupported")
        size = u16(payload, pos + 4)
        end = pos + 6 + size
        require(end <= len(payload), "Truncated INFO subrecord payload")
        if tag == b"EDID":
            return payload[pos + 6:end].rstrip(b"\x00")
        pos = end
    return b""


def patch_info_payload(payload):
    require(record_editor_id(payload) == TARGET_EDITOR_ID, "Target FormID has an unexpected EditorID")
    output = bytearray()
    pos = 0
    vmad_count = 0
    while pos < len(payload):
        tag = payload[pos:pos + 4]
        size = u16(payload, pos + 4)
        end = pos + 6 + size
        value = payload[pos + 6:end]
        if tag == b"VMAD":
            vmad_count += 1
            value = patch_vmad(value)
        output += tag + struct.pack("<H", len(value)) + value
        pos = end
    require(vmad_count == 1, "Expected exactly one target VMAD")
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
        require(updated == original, "Milk dialogue timing fragment needs installation")
    elif updated != original:
        backup = args.plugin.parent / "backups" / ("milk-dialogue-timing-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
        backup.mkdir(parents=True)
        (backup / args.plugin.name).write_bytes(original)
        args.plugin.write_bytes(updated)
        print("Backup:", backup)
    print("Verified Give Milk OnBegin timing fragment.")
