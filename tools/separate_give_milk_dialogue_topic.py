"""Move Give Milk into its own reachable DIAL without SSEEdit.

The original INFO was copied under MME_Maid_Making_Topic, where Skyrim chooses
one valid INFO for that single menu topic. Ordinary women therefore saw the
original Become Milkmaid prompt while men/Milkmaids fell through to Give Milk.
This creates one sibling Custom DIAL, reparents the existing INFO group, and
links the new topic from MME's Hey there opening INFO.
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

SOURCE_TOPIC = 0x02062E95
OPENING_INFO = 0x0206544B
NEW_TOPIC = 0x0300089C
NEW_TOPIC_LOCAL_ID = NEW_TOPIC & 0xFFFFFF
NEW_TOPIC_EDITOR_ID = b"MMEExt_DialogueDrinkMilkTopic\x00"
NEW_TOPIC_NAME = b"Would you like to drink some milk?\x00"
DIAL_GROUP = b"DIAL"


def iter_subrecords(payload):
    pos = 0
    while pos < len(payload):
        require(pos + 6 <= len(payload), "Truncated subrecord")
        tag = payload[pos:pos + 4]
        size = u16(payload, pos + 4)
        end = pos + 6 + size
        require(end <= len(payload), "Truncated subrecord payload")
        yield pos, end, tag, payload[pos + 6:end]
        pos = end


def replace_text_subrecords(payload):
    output = bytearray()
    for _, _, tag, value in iter_subrecords(payload):
        if tag == b"EDID":
            value = NEW_TOPIC_EDITOR_ID
        elif tag == b"FULL":
            value = NEW_TOPIC_NAME
        output += tag + struct.pack("<H", len(value)) + value
    return bytes(output)


def clone_topic_record(source_record):
    require(source_record[:4] == b"DIAL", "Give Milk source topic is not DIAL")
    header = bytearray(source_record[:24])
    payload = replace_text_subrecords(source_record[24:])
    struct.pack_into("<I", header, 4, len(payload))
    struct.pack_into("<I", header, 12, NEW_TOPIC)
    return bytes(header) + payload


def add_opening_link(payload):
    links = [struct.unpack("<I", value)[0] for _, _, tag, value in iter_subrecords(payload) if tag == b"TCLT"]
    require(NEW_TOPIC not in links, "Give Milk opening link already exists in pre-migration state")
    output = bytearray()
    inserted = False
    for start, end, tag, _ in iter_subrecords(payload):
        if not inserted and tag == b"TRDT":
            output += b"TCLT" + struct.pack("<H", 4) + struct.pack("<I", NEW_TOPIC)
            inserted = True
        output += payload[start:end]
    require(inserted, "Opening INFO has no response block after its choice links")
    return bytes(output)


def scan_state(data):
    state = {
        "source_record": None,
        "new_topics": 0,
        "target_parent": None,
        "opening_links": [],
        "hedr": None,
    }

    def walk(start, end, parent_topic=None):
        pos = start
        while pos < end:
            require(pos + 24 <= end, "Truncated record header")
            signature = data[pos:pos + 4]
            size = struct.unpack_from("<I", data, pos + 4)[0]
            is_group = signature == b"GRUP"
            stop = pos + size if is_group else pos + 24 + size
            require(pos + 24 <= stop <= end, "Invalid record size")
            if is_group:
                group_type = struct.unpack_from("<i", data, pos + 12)[0]
                label = struct.unpack_from("<I", data, pos + 8)[0]
                walk(pos + 24, stop, label if group_type == 7 else parent_topic)
            else:
                form_id = struct.unpack_from("<I", data, pos + 12)[0]
                payload = data[pos + 24:stop]
                if signature == b"TES4":
                    for _, _, tag, value in iter_subrecords(payload):
                        if tag == b"HEDR":
                            state["hedr"] = struct.unpack("<fII", value)
                elif signature == b"DIAL" and form_id == SOURCE_TOPIC:
                    state["source_record"] = data[pos:stop]
                elif signature == b"DIAL" and form_id == NEW_TOPIC:
                    state["new_topics"] += 1
                    require(record_editor_id(payload) == NEW_TOPIC_EDITOR_ID[:-1], "Give Milk DIAL has an unexpected EditorID")
                elif signature == b"INFO" and (form_id & 0xFFFFFF) == TARGET_LOCAL_ID:
                    require(record_editor_id(payload) == TARGET_EDITOR_ID, "Give Milk INFO has an unexpected EditorID")
                    state["target_parent"] = parent_topic
                elif signature == b"INFO" and form_id == OPENING_INFO:
                    state["opening_links"] = [struct.unpack("<I", value)[0] for _, _, tag, value in iter_subrecords(payload) if tag == b"TCLT"]
            pos = stop

    walk(0, len(data))
    return state


def patch_plugin(data):
    state = scan_state(data)
    require(state["source_record"] is not None, "MME_Maid_Making_Topic override is missing")
    require(state["hedr"] is not None, "TES4 HEDR is missing")

    if state["new_topics"] == 1:
        require(state["target_parent"] == NEW_TOPIC, "Give Milk INFO is not parented to its dedicated DIAL")
        require(state["opening_links"].count(NEW_TOPIC) == 1, "Give Milk DIAL must occur exactly once in the opening LinkTo list")
        return data

    require(state["new_topics"] == 0, "Duplicate Give Milk DIAL records")
    require(state["target_parent"] == SOURCE_TOPIC, "Give Milk INFO has an unexpected source parent")
    require(NEW_TOPIC not in state["opening_links"], "Opening INFO links to a missing Give Milk DIAL")
    version, record_count, next_object_id = state["hedr"]
    require(next_object_id == NEW_TOPIC_LOCAL_ID, "Expected Give Milk DIAL to consume the plugin's next object ID")
    new_topic_record = clone_topic_record(state["source_record"])
    moved_group = False

    def walk(start, end):
        nonlocal moved_group
        output = bytearray()
        pos = start
        while pos < end:
            header = bytearray(data[pos:pos + 24])
            signature = header[:4]
            size = struct.unpack_from("<I", header, 4)[0]
            is_group = signature == b"GRUP"
            stop = pos + size if is_group else pos + 24 + size
            payload = data[pos + 24:stop]
            prefix = b""
            if is_group:
                group_type = struct.unpack_from("<i", header, 12)[0]
                label = struct.unpack_from("<I", header, 8)[0]
                payload = walk(pos + 24, stop)
                if group_type == 7 and label == SOURCE_TOPIC and TARGET_EDITOR_ID in payload:
                    require(not moved_group, "Found Give Milk in more than one topic group")
                    struct.pack_into("<I", header, 8, NEW_TOPIC)
                    prefix = new_topic_record
                    moved_group = True
            else:
                form_id = struct.unpack_from("<I", header, 12)[0]
                if signature == b"TES4":
                    rebuilt = bytearray()
                    for sub_start, sub_end, tag, value in iter_subrecords(payload):
                        if tag == b"HEDR":
                            value = struct.pack("<fII", version, record_count + 1, next_object_id + 1)
                            rebuilt += tag + struct.pack("<H", len(value)) + value
                        else:
                            rebuilt += payload[sub_start:sub_end]
                    payload = bytes(rebuilt)
                elif signature == b"INFO" and form_id == OPENING_INFO:
                    payload = add_opening_link(payload)
            struct.pack_into("<I", header, 4, len(payload) + (24 if is_group else 0))
            output += prefix + header + payload
            pos = stop
        return bytes(output)

    result = walk(0, len(data))
    require(moved_group, "Give Milk INFO topic group was not moved")
    final = scan_state(result)
    require(final["new_topics"] == 1, "Give Milk DIAL creation failed")
    require(final["target_parent"] == NEW_TOPIC, "Give Milk INFO reparenting failed")
    require(final["opening_links"].count(NEW_TOPIC) == 1, "Give Milk opening link creation failed")
    require(final["hedr"][1] == record_count + 1 and final["hedr"][2] == next_object_id + 1, "TES4 record metadata update failed")
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
        require(updated == original, "Give Milk still shares MME's Become Milkmaid DIAL")
    elif updated != original:
        backup = args.plugin.parent / "backups" / ("give-milk-separate-topic-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
        backup.mkdir(parents=True)
        (backup / args.plugin.name).write_bytes(original)
        args.plugin.write_bytes(updated)
        print("Backup:", backup)
    print("Verified Give Milk has its own reachable DIAL and one opening choice link.")
