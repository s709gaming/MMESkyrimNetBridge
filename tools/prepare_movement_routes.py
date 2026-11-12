"""Prepare four movement loop records in the source ESP; no installed files touched.
Retain old movement marker identity, category, output model and loop flags.
"""
from pathlib import Path
import struct
from prepare_movement_slap import records,subrecords,sub
ROOT=Path(__file__).resolve().parents[1]
ROUTES=[(0x8D3,0x8D4,"SlowSlaps","slow slaps loop.wav"),(0x8D5,0x8D6,"FastSlaps","fast slaps loop.wav"),(0x8D7,0x8D8,"SlowFlops","slow flops loop.wav"),(0x8C4,0x8C5,"MovementSlap","fast flops loop.wav")]
def build(data):
 allrecords=list(records(data));local={struct.unpack_from("<I",r,12)[0]&0xffffff:r for r in allrecords};templates={b"SNDR":local[0x8C4],b"SOUN":local[0x8C5]};prefix=struct.unpack_from("<I",templates[b"SOUN"],12)[0]&0xff000000;new={};added=0
 for desc,mark,label,filename in ROUTES:
  for sig,identifier in [(b"SNDR",desc),(b"SOUN",mark)]:
   template=templates[sig];payload=[]
   for tag,value in subrecords(template[24:]):
    if tag==b"EDID" and identifier not in (0x8C4,0x8C5):value=("MMEAlerts_"+sig.decode()+"_"+label).encode()+b"\0"
    elif tag==b"ANAM":value=("fx\\MMESkyrimNetBridge\\Movement Loops\\"+filename).encode()+b"\0"
    elif tag==b"SDSC":value=struct.pack("<I",prefix|desc)
    payload.append(sub(tag,value))
   payload=b"".join(payload);header=bytearray(template[:24]);struct.pack_into("<I",header,4,len(payload));struct.pack_into("<I",header,12,prefix|identifier);record=bytes(header)+payload
   if identifier in local and identifier not in (0x8C4,0x8C5):
    assert local[identifier]==record,f"Movement sound ID collision: {identifier:X}"
   if identifier not in local:added+=1
   new[identifier]=record
 result=[];pos=0
 while pos<len(data):
  sig,size=struct.unpack_from("<4sI",data,pos)
  if sig==b"GRUP":
   group=data[pos:pos+size]
   if group[8:12] not in templates:
    result.append(group);pos+=size;continue
   body=[];seen=set()
   for record in records(group,24,len(group)):
    identifier=struct.unpack_from("<I",record,12)[0]&0xffffff;body.append(new.get(identifier,record));seen.add(identifier)
   body.extend(record for identifier,record in new.items() if record[:4]==group[8:12] and identifier not in local)
   payload=b"".join(body);head=bytearray(group[:24]);struct.pack_into("<I",head,4,len(payload)+24);result.append(bytes(head)+payload);pos+=size
  else:
   record=data[pos:pos+24+size]
   if sig==b"TES4":
    payload=[]
    for tag,value in subrecords(record[24:]):
     if tag==b"HEDR":
      v=bytearray(value);count,nextid=struct.unpack_from("<II",v,4);struct.pack_into("<II",v,4,count+added,max(nextid,0x8D9));value=bytes(v)
     payload.append(sub(tag,value))
    record=record[:24]+b"".join(payload)
   result.append(record);pos+=24+size
 return b"".join(result)
if __name__=="__main__":
 plugin=ROOT/"MMEAlert.esp";result=build(plugin.read_bytes());assert build(result)==result;plugin.write_bytes(result);print("Prepared four movement sound pairs")
