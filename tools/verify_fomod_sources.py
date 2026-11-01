"""Reject release archives with missing file/folder references in FOMOD XML."""
import sys
import zipfile
import xml.etree.ElementTree as ET


def verify(path):
    with zipfile.ZipFile(path) as archive:
        names = {name.replace('\\', '/').casefold() for name in archive.namelist()}
        config = next(name for name in archive.namelist()
                      if name.replace('\\', '/').casefold() == 'fomod/moduleconfig.xml')
        root = ET.fromstring(archive.read(config))
        missing = []
        for element in root.iter():
            source = element.get('source')
            if source is None:
                continue
            source = source.replace('\\', '/').strip('/').casefold()
            if element.tag == 'file':
                found = source in names
            elif element.tag == 'folder':
                found = any(name.startswith(source + '/') for name in names)
            else:
                continue
            if not found:
                missing.append(element.get('source'))
        if missing:
            raise ValueError('Missing FOMOD sources: ' + ', '.join(missing))
        print('PASS: every FOMOD file/folder source exists in the release archive')


if __name__ == '__main__':
    verify(sys.argv[1])
