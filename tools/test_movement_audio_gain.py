"""Verify the immutable, sample-checked 1.75x audio revision and unclipped PCM."""
from pathlib import Path
import array, hashlib, json, wave, math
root = Path(__file__).resolve().parents[1]
reference=json.loads((root/'tools/movement-audio-reference.json').read_text())
for name, expected in reference['sha256'].items():
    path=root/'assets/sounds/Movement Loops'/name
    assert hashlib.sha256(path.read_bytes()).hexdigest()==expected, name
    with wave.open(str(path),'rb') as f:
        assert (f.getnchannels(),f.getsampwidth(),f.getframerate())==(1,2,44100)
        samples=array.array('h',f.readframes(f.getnframes()))
    assert max(samples)<32767 and min(samples)>-32768
    peak=20*math.log10(max(abs(v) for v in samples)/32768)
    print(f'PASS: {name}: verified audio revision, unclipped, peak {peak:.3f} dBFS')
