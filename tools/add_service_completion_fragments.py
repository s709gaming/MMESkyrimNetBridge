"""Add only OnEnd bindings to the seven existing service INFOs.

Run after the xEdit service installers, before packaging. Strictly validates the
existing VMAD layout; preserves all other record/subrecord bytes and FormIDs.
INFO fragment format: xEdit dev-4.1.5 wbDefinitionsTES5.pas wbScriptFragmentsInfo.
"""
import argparse
import struct
from datetime import datetime
from pathlib import Path

TARGETS = dict(zip((0x884, 0x885, 0x889, 0x88A, 0x88E, 0x88F, 0x895), (
    'AddMilkArmor', 'RemoveMilkArmor', 'AddLivingArmor', 'RemoveLivingArmor',
    'AddParasiteArmor', 'RemoveParasiteArmor', 'ApplyReverseLeveling')))
SCRIPT = b'MMEBlacksmithDialogue'
END = b'Fragment_ServiceCompleted'


def require(condition, detail):
    if not condition:
        raise ValueError(detail)


def u16(data, pos):
    return struct.unpack_from('<H', data, pos)[0]


def string(data, pos):
    end = pos + 2 + u16(data, pos)
    require(end <= len(data), 'Truncated string')
    return data[pos + 2:end], end


def packed_string(value):
    return struct.pack('<H', len(value)) + value


def patch_vmad(data, action):
    require(u16(data, 0) == 5 and u16(data, 2) == 2, 'Unexpected VMAD version/format')
    require(u16(data, 4) == 1, 'Unexpected script count')
    name, pos = string(data, 6)
    require(name == SCRIPT, 'Unexpected attached script')
    pos += 1  # script flags
    count = u16(data, pos)
    pos += 2
    for _ in range(count):
        _, pos = string(data, pos)
        kind = data[pos]
        pos += 2  # type, flags
        if kind == 2:
            _, pos = string(data, pos)
        else:
            require(kind in (1, 3, 4, 5), 'Unsupported property type')
            pos += {1: 8, 3: 4, 4: 4, 5: 1}[kind]
    require(data[pos] == 2 and data[pos + 1] in (1, 3), 'Unexpected fragment header')
    flags_pos = pos + 1
    flags = data[flags_pos]
    name, pos = string(data, pos + 2)
    require(name == SCRIPT, 'Unexpected fragment filename')
    extra = data[pos:pos + 1]
    name, pos = string(data, pos + 1)
    fragment, pos = string(data, pos)
    require(name == SCRIPT and fragment == ('Fragment_' + action).encode(), 'Unexpected OnBegin')
    if flags == 3:
        name, pos = string(data, pos + 1)
        fragment, pos = string(data, pos)
        require(name == SCRIPT and fragment == END, 'Existing OnEnd differs')
        require(pos == len(data), 'Trailing VMAD data')
        return data
    require(pos == len(data), 'Trailing VMAD data')
    return data[:flags_pos] + b'\x03' + data[flags_pos + 1:] + extra + packed_string(SCRIPT) + packed_string(END)


def patch_plugin(data):
    seen = set()

    def walk(start, end):
        output = bytearray()
        pos = start
        while pos < end:
            require(pos + 24 <= end, 'Truncated record header')
            header = bytearray(data[pos:pos + 24])
            size = struct.unpack_from('<I', header, 4)[0]
            group = header[:4] == b'GRUP'
            stop = pos + size if group else pos + 24 + size
            require(pos + 24 <= stop <= end, 'Invalid record size')
            payload = data[pos + 24:stop]
            if group:
                payload = walk(pos + 24, stop)
            else:
                form = struct.unpack_from('<I', header, 12)[0]
                if form in {0x03000000 | n for n in TARGETS}:
                    require(header[:4] == b'INFO', 'Target is not INFO')
                    require(not (struct.unpack_from('<I', header, 8)[0] & 0x40000), 'Compressed target')
                    require(form not in seen, 'Duplicate target')
                    seen.add(form)
                    subs = bytearray()
                    offset = 0
                    vmads = 0
                    while offset < len(payload):
                        tag = payload[offset:offset + 4]
                        require(tag != b'XXXX', 'Extended target subrecord unsupported')
                        length = u16(payload, offset + 4)
                        sub_end = offset + 6 + length
                        require(sub_end <= len(payload), 'Truncated subrecord')
                        value = payload[offset + 6:sub_end]
                        if tag == b'VMAD':
                            vmads += 1
                            value = patch_vmad(value, TARGETS[form & 0xFFFFFF])
                        subs += tag + struct.pack('<H', len(value)) + value
                        offset = sub_end
                    require(vmads == 1, 'Expected exactly one VMAD')
                    payload = bytes(subs)
            struct.pack_into('<I', header, 4, len(payload) + (24 if group else 0))
            output += header + payload
            pos = stop
        return bytes(output)

    result = walk(0, len(data))
    require(seen == {0x03000000 | n for n in TARGETS}, 'Missing service INFOs / unexpected master layout')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('plugin', type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    original = args.plugin.read_bytes()
    updated = patch_plugin(original)
    require(patch_plugin(updated) == updated, 'Patch is not idempotent')
    if args.check:
        require(updated == original, 'Service OnEnd bindings need installation')
    elif updated != original:
        backup = args.plugin.parent / 'backups' / ('service-gestures-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
        backup.mkdir(parents=True)
        (backup / args.plugin.name).write_bytes(original)
        args.plugin.write_bytes(updated)
        print('Backup:', backup)
    print('Verified all seven service OnEnd bindings.')
