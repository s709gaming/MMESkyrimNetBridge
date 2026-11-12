# MME Extensions — Development Changelog

Repository-only record of player-visible changes being prepared for release. Keep investigation notes and build details in `TASK.md`. Use [example-changelog.md](example-changelog.md) as the release-writing style reference.

## Unreleased

### Added

### Improved

### Fixed

- **Elsie LaVache detection:** Compatibility detection quietly skips form lookups when Elsie is not installed. **Needs in-game testing.**
- **Naked orgasm armor checks:** Missing body armor no longer causes invalid armor-name calls during orgasm processing; normal milking continues. Applies to common, P+ and generated OStim hooks. **Needs in-game testing.**
- **Arousal compatibility:** MME Extensions pauses arousal reads and writes when known legacy framework prerequisites are missing, then retries safely. Modern OSL/NG paths retain their authoritative readings, and recovery clears stale pending reactions. This mitigates Extensions calls; original MME's separate SLA calls remain outside this protection. **Needs in-game testing.**

When preparing a release, review the entries against in-game results and move verified changes into the release changelog.
