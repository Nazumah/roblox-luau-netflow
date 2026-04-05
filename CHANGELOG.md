# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.5] - 2026-04-05

### Added
- **IntelliSense Overhaul**: Introduced explicit `NetFlowLib` and `DataTypes` interfaces in `init.luau`. This enables full IDE autocompletion for all core functions and data type definitions (`Net.t.*`) through Wally.
- Synchronized Async dependency to v1.0.4 for improved type safety in `invokeServer/Client` calls.

## [1.7.3] - 2026-04-05

### Changed
- General API documentation review and version bump.
- Bumped Async dependency to 1.0.2.

## [1.7.2] - 2026-04-05

### Fixed
- Updated Async dependency to 1.0.1.
- Minor performance improvements in buffer serialization.
- Corrected documentation and examples in the README.

## [1.7.1] - 2026-03-20

### Added
- Initial public release of NetFlow.
- Binary networking with low-bandwidth buffer serialization.
- High-performance namespaced packets.
- Support for complex schemas.
