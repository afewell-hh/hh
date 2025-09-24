# Changelog

All notable changes to this project will be documented in this file.

## [v0.1.8] - 2025-09-24

### Fixed
- Correct edge_auth handling: `hh login` now preserves existing edge_auth values instead of overwriting them with pairing codes
- Helper correctly returns credentials with proper config setup
- Anonymous fallback properly allows public registry access when authentication fails

### Added
- Enhanced hh doctor diagnostics with more comprehensive checks
- Improved debug output for troubleshooting authentication issues

## [v0.1.7] - 2025-09-24

### Added
- `hh doctor` command for comprehensive system diagnostics
- Enhanced version command with commit SHA and build timestamp
- Integration tests under `scripts/e2e/`
- Makefile for build automation

### Fixed
- Helper anonymous fallback fixed - now properly returns exit 0 with empty stdout on auth failures
- Strict config discovery - helper now correctly prioritizes new field names (`lease_url`, `edge_auth`, `token`)
- `hh login` now guarantees all required keys (`lease_url`, `edge_auth`, `token`) in config
- Improved error handling and debug output in credential helper

### Changed
- Updated helper to support `HH_DEBUG=1` environment variable for troubleshooting
- Enhanced config normalization to handle both legacy and new field names
- Improved credential helper error messages and fallback behavior

### Technical Details
- Helper now correctly handles lease URLs that already include `/lease` path
- Config discovery search order: `$HH_CONFIG` → `/etc/hh/config.json` → `$XDG_CONFIG_HOME/hh/config.json` → `$HOME/.hh/config.json`
- All diagnostic checks in `hh doctor` include clear PASS/FAIL indicators with actionable next steps

## [v0.1.6] - Previous Release
- Previous functionality preserved for backwards compatibility