# Editor list divider

The message editor now has one horizontal drag handle between its controls and existing scrollable entry list. Drag upward for more editing room; controls remain scrollable. The split is bounded to retain controls and at least 100 pixels for entries, adapts to window resizing, and persists locally. Arrow keys resize by 5%, Page Up/Down by 20%, Home/End select limits; double-click resets. Pointer cancellation and loss of focus stop dragging.

Files: `fomod/choices/maid-roster-ui/Magelight/mmeextensions/views/roster/index.html`, `dashboard.js`. No Papyrus or native gameplay changes.

Validation: actual dashboard JavaScript harness covers drag bounds, cancellation, keyboard operation, persistence/reset, and existing editor save/draft/filter/session behavior. Catalog contract tests passed. In-game visual acceptance remains pending restart.

Authorized installation targets only these two UI assets in the enabled, higher-priority `MME Extensions-A` mod. Existing installer choices and the other enabled installation remain untouched. Previous UI files are backed up under `build/diagnostics/dashboard-before-divider-*`.

Display configuration: backed up the Default MO2 profile's SkyrimPrefs.ini, set bBorderless=1, bFull Screen=0 and 2560x1440 after closing MO2. Backup under `build/diagnostics/display-backup-*`. Requires a fresh game launch; observed fullscreen behavior remains untested.
