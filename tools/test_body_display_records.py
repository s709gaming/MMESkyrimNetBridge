"""Inspect shipped record bytes, not only the generator text."""
from pathlib import Path
import struct, zlib, unittest
ROOT=Path(__file__).resolve().parents[1]

def records(data):
    pos=0
    while pos<len(data):
        sig=data[pos:pos+4];size=struct.unpack_from('<I',data,pos+4)[0]
        if sig==b'GRUP':
            yield from records(data[pos+24:pos+size]);pos+=size;continue
        flags,formid=struct.unpack_from('<II',data,pos+8)
        body=data[pos+24:pos+24+size]
        if flags&0x40000:
            expected=struct.unpack_from('<I',body)[0];body=zlib.decompress(body[4:]);assert len(body)==expected
        yield sig,formid&0xffffff,body
        pos+=24+size
    assert pos==len(data)

def fields(body):
    pos=0;extended=None
    while pos<len(body):
        sig=body[pos:pos+4];size=struct.unpack_from('<H',body,pos+4)[0];pos+=6
        if sig==b'XXXX':extended=struct.unpack_from('<I',body,pos)[0];pos+=size;continue
        size=extended if extended is not None else size;extended=None
        yield sig,body[pos:pos+size];pos+=size
    assert pos==len(body)

class DisplayRecords(unittest.TestCase):
    def test_shipped_display_records(self):
        data={(sig,id):dict(fields(body)) for sig,id,body in records((ROOT/'MMEAlert.esp').read_bytes()) if id in (0x8c0,0x8c1,0x8c2,0x8c3)}
        self.assertEqual(len(data),4)
        for id,text in [(0x8c0,b'Movement speed reduced by <mag>%.'),(0x8c2,b'Carried milk reduces carry capacity by <mag> points.')]:
            effect=data[b'MGEF',id];spell=data[b'SPEL',id+1]
            self.assertEqual(effect[b'DNAM'].rstrip(b'\0'),text)
            self.assertEqual(struct.unpack_from('<I',effect[b'DATA'])[0],0xa04)
            self.assertNotIn(b'VMAD',effect)
            self.assertEqual(spell.get(b'DESC',b'').strip(b'\0'),b'')
            self.assertEqual(struct.unpack('<I',spell[b'EFID'])[0]&0xffffff,id)
            magnitude,area,duration=struct.unpack('<fII',spell[b'EFIT'])
            self.assertEqual((magnitude,area,duration),(1,0,0))

if __name__=='__main__':unittest.main()
