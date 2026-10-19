# Change Log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com), and this project adheres to [Semantic Versioning](https://semver.org).

## [2.0.3] - 13-10-2026

### Added
- Post AD action scripts (Set-ACL and icacls): enable inheritance on the newly created directory, fixes [#6](https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-NTFS-Folder/issues/6). Both actions can be toggled with `$setPermissions` and `$enableInheritance`
- icacls post AD action: exit code check, so a failing icacls is now reported as an error
- Post AD action scripts (Set-ACL and icacls): log the AD user identity and selected domain controller before querying Active Directory

### Changed
- Set-ACL post AD action: reads and writes only the DACL (no `SeSecurityPrivilege` required), runs directly instead of in a background job and verifies the result
- Post AD action scripts: shorter and more readable audit log, e.g. `Enabled inheritance and granted user [jdoe] FullControl on this folder, subfolders and files to directory [path]`. Only the enabled actions are logged
- Post AD action scripts: documented the mapping options and their result (inheritance and propagation flags) in the scripts
- Post AD action scripts: `$dryRun` only skips changes when set to `$true`

### Fixed
- icacls post AD action: granting permissions failed with "No mapping between account names and security IDs" because the SID was not prefixed with `*`
- icacls post AD action: inheritance level `This folder and subfolders` was never matched due to a trailing space
- Post AD action scripts (Set-ACL and icacls): ignore the entitlement context domain controller during dry-run and use PDC discovery instead, preventing connection failures

## [2.0.2] - 12-10-2026

### Added
- GitHub workflows and changelog

### Changed
- Fixed [#10](https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-NTFS-Folder/issues/10) by using `outputContext.data` instead of `actionContext.data`
- Logo

### Removed
- Debug toggle
- Forum in README
- DisplayName in Permission Reference


## [2.0.1] - 12-12-2024

- Fix: revoke permission could fail

## [2.0.0] - 17-09-2024

- Fix incorrect use of aref
- Use sid instead of samaccountname
- more appealing icon
- New powershell V2 connector

## [1.0.0] - 22-13-2022

This is the first official release of _HelloID-Conn-Prov-Target-NTFS-Folder_.

### Added

### Changed

### Deprecated

### Removed