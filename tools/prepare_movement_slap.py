"""Build the movement-only 2x PCM asset and loop records in the repository ESP.

Clones the existing authored slap records, retaining their category/output model.
Only the new records and TES4 record count/next-object metadata are changed.
LNAM byte 1 bit 3 is Loop (CommonLib BGSStandardSoundDef::LengthCharacteristics).
"""
import array
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DESCRIPTOR = 0x8C4
MARKER = 0x8C5
SOUND_PATH = b"fx\\MMESkyrimNetBridge\\Tit Slap Sounds\\movement slap 2x.wav\0"


def subrecords(data):
    pos = 0
    while pos < len(data):
        tag, size = struct.unpack_from("<4sH", data, pos)
        assert tag != b"XXXX" and pos + 6 + size <= len(data)
        yield tag, data[pos + 6:pos + 6 + size]
        pos += 6 + size
    assert pos == len(data)


def sub(tag, data):
    return struct.pack("<4sH", tag, len(data)) + data


def records(data, start=0, end=None):
    end = len(data) if end is None else end
    pos = start
    while pos < end:
        tag, size = struct.unpack_from("<4sI", data, pos)
        if tag == b"GRUP":
            yield from records(data, pos + 24, pos + size)
            pos += size
        else:
            yield data[pos:pos + 24 + size]
            pos += 24 + size
    assert pos == end


def build_plugin(data):
    all_records = list(records(data))
    source = {}
    for record in all_records:
        form = struct.unpack_from("<I", record, 12)[0]
        if form & 0xFFFFFF in (0x8B0, 0x8B1):
            assert not struct.unpack_from("<I", record, 8)[0] & 0x40000
            source[form & 0xFFFFFF] = record
    assert len(source) == 2
    prefix = struct.unpack_from("<I", source[0x8B0], 12)[0] & 0xFF000000
    additions = {}
    for original, local, editor in ((0x8B0, DESCRIPTOR, b"MMEAlerts_SNDR_MovementSlap"),
                                    (0x8B1, MARKER, b"MMEAlerts_SOUN_MovementSlap")):
        template = source[original]
        payload = []
        for tag, value in subrecords(template[24:]):
            if tag == b"EDID":
                value = editor + b"\0"
            elif tag == b"ANAM":
                value = SOUND_PATH
            elif tag == b"LNAM":
                assert len(value) == 4
                value = value[:1] + bytes([(value[1] & ~0x38) | 0x08]) + value[2:]
            elif tag == b"SDSC":
                value = struct.pack("<I", prefix | DESCRIPTOR)
            payload.append(sub(tag, value))
        payload = b"".join(payload)
        header = bytearray(template[:24])
        struct.pack_into("<I", header, 4, len(payload))
        struct.pack_into("<I", header, 12, prefix | local)
        new = bytes(header) + payload
        existing = [r for r in all_records if struct.unpack_from("<I", r, 12)[0] == prefix | local]
        if existing:
            assert existing == [new], f"Movement sound ID collision: {local:06X}"
        else:
            additions[template[:4]] = new
    if not additions:
        return data
    assert len(additions) == 2, "Partial movement sound installation"
    header_size = 24 + struct.unpack_from("<I", data, 4)[0]
    header = data[:24]
    header_payload = []
    for tag, value in subrecords(data[24:header_size]):
        if tag == b"HEDR":
            value = bytearray(value)
            count, next_id = struct.unpack_from("<II", value, 4)
            struct.pack_into("<II", value, 4, count + 2, max(next_id, MARKER + 1))
            value = bytes(value)
        header_payload.append(sub(tag, value))
    result = [header + b"".join(header_payload)]
    pos = header_size
    while pos < len(data):
        assert data[pos:pos + 4] == b"GRUP"
        size = struct.unpack_from("<I", data, pos + 4)[0]
        group = data[pos:pos + size]
        addition = additions.pop(group[8:12], None)
        if addition:
            group_header = bytearray(group[:24])
            struct.pack_into("<I", group_header, 4, size + len(addition))
            group = bytes(group_header) + group[24:] + addition
        result.append(group)
        pos += size
    assert not additions
    return b"".join(result)


def main():
    folder = ROOT / "assets/sounds/Tit Slap Sounds"
    with wave.open(str(folder / "tit slap sound loop.wav"), "rb") as original:
        params = original.getparams()
        assert params.sampwidth == 2 and params.nchannels == 1
        samples = array.array("h", original.readframes(params.nframes))
    assert max(abs(sample) for sample in samples) * 2 <= 32767, "2x gain would clip"
    boosted = array.array("h", (sample * 2 for sample in samples))
    with wave.open(str(folder / "movement slap 2x.wav"), "wb") as output:
        output.setparams(params)
        output.writeframes(boosted.tobytes())
    plugin = ROOT / "MMEAlert.esp"
    before = plugin.read_bytes()
    after = build_plugin(before)
    assert build_plugin(after) == after
    plugin.write_bytes(after)
    print("Prepared movement-only loop SNDR 0008C4 / SOUN 0008C5 and unclipped 2x WAV")


if __name__ == "__main__":
    main()
