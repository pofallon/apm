# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.2] - 2025-09-25

- Copilot CLI Support

## [0.4.1] - 2025-09-18

### Fixed
- Fix prompt file resolution for dependencies in org/repo directory structure
- APM dependency prompt files now correctly resolve from `apm_modules/org/repo/` paths
- `apm run` commands can now find and execute prompt files from installed dependencies
- Updated unit tests to match org/repo directory structure for dependency resolution

## [0.4.0] - 2025-09-18

- Context Packaging
- Context Dependencies
- Context Compilation
- GitHub MCP Registry integration
- Codex CLI Support