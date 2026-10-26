# MME Extensions 1.4.3 - Vortex installer hotfix

Fixes Vortex FOMOD installation failing with `Xml_InvalidCharacter, 1, 39`.

The single-quoted UTF-8 declaration in ModuleConfig.xml survived the Vortex
installer's encoding-removal expression. The installer then rewrote the text as
UTF-16BE while retaining the UTF-8 declaration. Its XML reader encountered a NUL
at line 1, position 39. Normal XML validation alone did not catch this because the
original UTF-8 file itself was valid XML.

Removed the XML declarations from both FOMOD XML files, retaining UTF-8 content.
Updated FOMOD metadata to 1.4.3. Installer choices and dependency conditions are
unchanged. The hotfix archive is derived from the existing 1.4.2 release archive;
all other archive entries remain byte-for-byte identical. No Papyrus, DLL, ESP,
configuration, save, or gameplay change is included.

`tools/Test-FomodXmlEncoding.ps1` reproduces the upstream encoding transformation,
checks that a single-quoted declaration fails at 1:39 as a negative control, and
validates both source XML and optional release-archive XML. The normal build runs
it before compilation and again on the final ZIP. Existing cross-page/backend and
18 legacy patch-condition cases are checked separately.

Validated with normal .NET parsing and the reproduced Vortex encoding path;
interactive Vortex and MO2 installer UI testing remains external verification.
No installed MO2 files or Vortex files were modified. The versioned filename is
explicitly requested for this hotfix; the normal build keeps its generic filename.

Upstream implementation inspected:
https://github.com/Nexus-Mods/fomod-installer/blob/master/src/InstallScripting/XmlScript/XmlScriptType.cs

Short release note:
Fixed a Vortex FOMOD XML encoding error that could prevent installation with an
invalid-character message at line 1, position 39. No gameplay changes.
