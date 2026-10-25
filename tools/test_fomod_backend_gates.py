"""Check cross-page flags and legacy patch gating using MO2's page semantics.

Accept a ModuleConfig.xml or a release ZIP. No installation or UI automation.
"""
from pathlib import Path
from zipfile import ZipFile
import sys
import xml.etree.ElementTree as ET


def check(path):
    if path.suffix.lower() == '.zip':
        with ZipFile(path) as archive:
            name = next(n for n in archive.namelist() if n.lower() == 'fomod/moduleconfig.xml')
            root = ET.fromstring(archive.read(name))
    else:
        root = ET.parse(path).getroot()
    steps = list(root.find('installSteps'))
    plugins = [(page, p) for page, step in enumerate(steps) for p in step.findall('.//plugin')]
    producers = {}
    for page, plugin in plugins:
        for flag in plugin.findall('./conditionFlags/flag'):
            producers.setdefault(flag.get('name'), set()).add(page)
    for page, step in enumerate(steps):
        for dependency in step.findall('.//flagDependency'):
            pages = producers.get(dependency.get('flag'), set())
            assert pages and all(p < page for p in pages), 'Flag consumer must follow its producer: ' + ET.tostring(dependency, encoding='unicode')
    backend = next(g for g in root.findall('.//group') if g.get('name') == 'Animation backend')
    assert backend.get('type') == 'SelectExactlyOne'
    backends = list(backend.find('plugins'))
    assert len(backends) == 3
    compatibility = steps[1].find('optionalFileGroups')
    assert all(g.get('type') == 'SelectAny' for g in compatibility), 'Compatibility options must be independently selectable'
    for patch in compatibility.findall('.//plugin'):
        assert not patch.findall('.//type[@name="Required"]'), 'Optional compatibility choice is locked: ' + patch.get('name')

    def evaluate(node, flags, files):
        if node.tag == 'fileDependency':
            return files.get(node.get('file'), 'Missing') == node.get('state')
        if node.tag == 'flagDependency':
            return flags.get(node.get('flag')) == node.get('value')
        assert node.tag == 'dependencies', 'Unmodeled condition: ' + node.tag
        values = [evaluate(c, flags, files) for c in node]
        return any(values) if node.get('operator', 'And') == 'Or' else all(values)

    def kind(plugin, flags, files):
        desc = plugin.find('typeDescriptor/dependencyType')
        for pattern in desc.findall('patterns/pattern'):
            if evaluate(pattern.find('dependencies'), flags, files):
                return pattern.find('type').get('name')
        return desc.find('defaultType').get('name')

    count = 0
    for prefix, filename in [('JUGS', 'Jugs.esp'), ('Elsie', 'CP_Elsie.esp')]:
        page, patch = next((page, p) for page, p in plugins if p.get('name').startswith(prefix))
        assert page == 1, 'Legacy patches should be on the compatibility page'
        selected_payload = set()
        for backend_plugin in backends:
            flags = {f.get('name'): f.text for f in backend_plugin.findall('conditionFlags/flag')}
            no_sexlab = backend_plugin.get('name').startswith('OStim-only')
            assert flags.get('mmeNoSexLab') == ('true' if no_sexlab else 'false')
            for state in ['Active', 'Inactive', 'Missing']:
                actual = kind(patch, flags, {filename: state})
                expected = 'Recommended' if state == 'Active' and not no_sexlab else 'NotUsable'
                assert actual == expected, (prefix, backend_plugin.get('name'), state, actual)
                count += 1
            # Model MO2's Recommended/NotUsable checkbox update on page revisit.
            actual = kind(patch, flags, {filename: 'Active'})
            selected_payload = {f.get('source') for f in patch.findall('files/*')} if actual == 'Recommended' else set()
            assert bool(selected_payload) != no_sexlab
        # Return from OStim-only to Standard/P+; recommended payload must reappear.
        for backend_plugin in backends[:2]:
            flags = {f.get('name'): f.text for f in backend_plugin.findall('conditionFlags/flag')}
            assert kind(patch, flags, {filename: 'Active'}) == 'Recommended'
    print(f'PASS: {path.name}: producer-page ordering, exclusive backends, {count} legacy patch cases, and backend revisit model. Native UI validation is separate.')


if __name__ == '__main__':
    check(Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / 'fomod/ModuleConfig.xml')
