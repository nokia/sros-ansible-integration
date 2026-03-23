# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0]
### Added
- Support for `flat` and `xml` output formats in `get_config()`
- Support for `intended` as a valid configuration source in `get_config()`
- Support for `active` as a valid configuration source in `get_config()`
  Same as `running` but excludes index persistency.
- Support for commit comments in `edit_config()` using the `comment` parameter
- Support `replace` with local file in `edit_config()`

### Changed
- Inherid base-class RPCs, while adding the SROS specific ones
- Use `info /` and `compare /` to ensure all tree levels are included in output
- Construct `info` commands using `' '.join()` to prevent trailing/double spaces when optional parameters are not provided
- Added exception handling for rollback

### Fixed
- Ensure `load full-replace` and `rollback` commands are correctly executed in CLI context `configure`
- Ensure `quit-config` is correctly executed in CLI root context
- Release workflow to automatically set collection version meta and upload to galaxy

## [2.0.0]
### Added
- Containerlab topology as test-automation reference
- GitHub workflow to build collection for every new release

### Changed
- Single repo for `nokia.sros` collection for simplified release management

### Fixed
- Updated playbooks for compatibility with latest Ansible releases

[2.0.0]: https://github.com/nokia/sros-ansible/releases/tag/v2.0.0
