# SkyrimNet Beta 25 Migration Attempt

## Status

**This migration did not work in game. Do not treat this folder as a working release.**

This folder preserves the first attempt to migrate MME Extensions from the last known working SkyrimNet Beta 24 integration to the Beta 25 content-plugin layout. It exists so the research, packaging work, and exact attempted implementation can be inspected or reapplied without leaving the active project on the broken migration.

No confirmed runtime root cause was captured before rollback. The preservation therefore distinguishes verified packaging facts from unverified runtime assumptions.

## Git reference points

- Last known working SkyrimNet Beta 24 project: `8c6381f`
- Archived first Beta 25 attempt: `dda1ae1`
- Migration comparison: `8c6381f..dda1ae1`
- Preservation prepared: 2026-09-20

The Beta 25 attempt was committed and pushed before this preservation folder was created. Even if this folder is later removed accidentally, commit `dda1ae1` remains the authoritative snapshot of the complete attempt, including generated-file changes.

## Primary documentation

- Official migration guide: <https://github.com/MinLL/SkyrimNet-GamePlugin/blob/main/docs/modding/MIGRATING_TO_BETA25.md>
- SkyrimNet GamePlugin repository: <https://github.com/MinLL/SkyrimNet-GamePlugin>
- Maintained Nexus FOMOD installer: <https://github.com/Nexus-Mods/fomod-installer>
- FOMOD XML 5.0 schema: <https://raw.githubusercontent.com/Nexus-Mods/fomod-installer/master/src/InstallScripting/XmlScript/Schemas/XmlScript5.0.xsd>

## What Beta 25 changed

The official guide says Beta 25 (`0.25.0`) changes content delivery and location, while the action and prompt file formats remain unchanged.

Beta 24 reads loose content beneath:

```text
Data/SKSE/Plugins/SkyrimNet/
├── prompts/
└── config/actions/
```

Beta 25 stops reading those loose directories. Mod-delivered content instead belongs in a manifest-backed external plugin:

```text
Data/SKSE/Plugins/SkyrimNet/external/{author}.{slug}/
├── manifest.json
├── actions/
└── prompts/
```

The guide states that old loose files are ignored rather than deleted. It also requires action filenames to match their in-file `name` value case-insensitively and requires exact lowercase extensions such as `.yaml` and `.prompt`.

Do not ship mod-owned files into SkyrimNet's `library/`, `overlay/`, or `saves/` directories. `external/` is the documented location for content delivered by another mod.

## What this attempt did

The attempted external plugin ID was:

```text
s709gaming.mme-extensions
```

Its complete attempted payload is preserved under [`content-plugin/`](content-plugin/). It contains:

- `manifest.json`, declaring a bundle with `min_skyrimnet_version` set to `0.25.0`
- Three actions renamed to match their internal action names
- The wearer self-comment prompt
- The milkmaid character-bio submodule
- The breastfeeding user-final-instructions submodule

The six action and prompt files were content-identical to their Beta 24 counterparts. The meaningful changes were their source layout, destination layout, action filenames, and the new manifest.

The build-script attempt:

1. Validated the manifest ID, type, semantic version, and minimum SkyrimNet version.
2. Rejected forbidden plugin subdirectories.
3. Validated required action and prompt files.
4. Validated ASCII paths and exact lowercase extensions.
5. Checked that each action filename matched its internal `name`.
6. Packaged the Beta 25 bundle under `SKSE/Plugins/SkyrimNet/external/`.
7. Also generated Beta 24 loose-file copies as a transitional compatibility measure.

The cleanup utility was extended to remove both the Beta 25 external directory and the legacy loose compatibility files. Unit tests were updated to address the new canonical content source and validate the external-plugin contract.

The exact meaningful tracked changes are preserved in [`tracked-changes.patch`](tracked-changes.patch). Apply it from the Beta 24 base with:

```powershell
git switch -c retry-skyrimnet-beta25 8c6381f
git apply --check migration/skyrimnet-beta25-attempt/tracked-changes.patch
git apply migration/skyrimnet-beta25-attempt/tracked-changes.patch
```

If the preservation folder is not present on that branch, copy it in temporarily or extract the patch from the preservation commit first.

## What was deliberately not copied

Commit `dda1ae1` also contains regenerated changes to two packaged `.pex` files and `tools/__pycache__/test_service_fragments.cpython-314.pyc`. Those files are build/cache products rather than Beta 25 migration design work, so they are not duplicated here. They remain recoverable from the archival commit.

Generated `dist` directories and ZIP archives are also excluded. They can be rebuilt and do not explain the migration.

## Runtime result and unknowns

The migration was reported not to work in game. Packaging checks alone therefore did not establish compatibility.

No preserved SkyrimNet log, dashboard rejection message, or precise failing behavior currently identifies whether the problem was:

- rejection of the manifest or external plugin;
- a skipped action or prompt;
- the external layer not being discovered;
- action registration or invocation behavior;
- plugin priority or a player overlay shadowing the files;
- a Beta 25 runtime/API change outside the documented content-layout migration; or
- another installation-specific condition.

Do not mark any of these as the cause without reproducing the failure and collecting evidence.

## Important future checks

Before another migration attempt:

1. Start from a separately verified Beta 24 installation and save its working behavior and logs.
2. Test the external plugin with only the Beta 25 layout installed, avoiding the dual-layout package during diagnosis.
3. Confirm the plugin appears in SkyrimNet's Installed Plugins page with the expected ID, version, and External badge.
4. Inspect `SkyrimNet.log` for rejected folders, skipped files, action validation, and load-order information.
5. Check whether player `overlay/` content or imported old content shadows the external plugin. The migration guide warns that imported mod-owned content can hide later plugin updates.
6. Test one prompt and one minimal action independently before restoring all content.
7. Recheck the current upstream action, prompt, manifest, and API documentation rather than assuming Beta 25 behavior is unchanged.
8. Capture exact SkyrimNet, SKSE, game, and mod versions with the failure report.

## FOMOD compatibility research

A FOMOD can present a manual `SelectExactlyOne` choice and install either Beta 24 or Beta 25 content folders. It cannot reliably compare the version of an arbitrary installed DLL such as `SkyrimNet.dll`.

The FOMOD 5.0 schema's generic `fileDependency` exposes only `Missing`, `Inactive`, and `Active`. Version comparisons are reserved for known dependencies such as the game, mod manager, and script extenders. A Beta 25-only marker file could be tested for existence, but runtime-created or installation-dependent markers are too brittle for reliable automatic selection.

The investigated alternatives were:

- Install both layouts: simplest, with Beta 25 documented to ignore legacy loose content.
- Manual Beta 24/Beta 25 selection: clean, but users can choose incorrectly.
- Automatic marker detection: not recommended without a stable upstream-installed marker guaranteed to exist before the FOMOD runs.

Because the dual-layout attempt still failed in game, its safety must not be inferred solely from the migration guide. A future retry should diagnose the Beta 25-only layout first.

## Rollback intent

After this preservation is verified and committed, the active implementation is intended to return to `8c6381f`, the last known working Beta 24 state. This folder should remain available as historical research and should not be included as active SkyrimNet content by the package builder.
