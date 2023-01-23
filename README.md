| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |

<p align="center">
  <img src="https://user-images.githubusercontent.com/69046642/173362624-71b91ad9-55c0-4743-95be-6e66c71872be.png">
</p>

## Versioning
| Version | Description | Date |
| - | - | - |
| 1.0.1   | Updated to use eRef and aRef | 2023/01/23  |
| 1.0.0   | Initial release | 2022/06/13  |

## Table of contents
- [Versioning](#versioning)
- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Remarks](#remarks)
- [Getting help](#getting-help)
- [HelloID docs](#helloid-docs)

## Introduction
_HelloID-Conn-Prov-Target-NTFS-Folder is a _target_ connector that allows you to manage the NTFS permissions. Using the Dynamic Permission entitlements it is possible to also create the folders and map the corresponding AD attribute.
The HelloID connector consists of the template scripts shown in the following table.

| Action                          | Action(s) Performed                           | Comment   | 
| ------------------------------- | --------------------------------------------- | --------- |
| create.correlate.ps1                                | Correlate to the AD account                   | This script has a dependency to the Microsoft AD system, since it has to set the permissions for that account. |
| postAdAction.create.SetDirectoryPermissions.Set-ACL | Set permissions to the __already created__ NTFS folder using the command [Set-ACL](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-acl?view=powershell-7.2)  | This script has to be run in the __Create__ [Post Action](https://docs.helloid.com/hc/en-us/articles/360012421460-Configure-the-on-premises-Microsoft-Active-Directory-target-system#2.4.2:~:text=Post%20Action%20Configuration) of the [built-in Microsoft Active Directory Target Connector](https://docs.helloid.com/hc/en-us/articles/360012421460-Configure-the-on-premises-Microsoft-Active-Directory-target-system)  |
| postAdAction.create.SetDirectoryPermissions.icacls | Set permissions to the __already created__ NTFS folder using the command [ICACLS](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls)  | This script has to be run in the __Create__ [Post Action](https://docs.helloid.com/hc/en-us/articles/360012421460-Configure-the-on-premises-Microsoft-Active-Directory-target-system#2.4.2:~:text=Post%20Action%20Configuration) of the [built-in Microsoft Active Directory Target Connector](https://docs.helloid.com/hc/en-us/articles/360012421460-Configure-the-on-premises-Microsoft-Active-Directory-target-system)  |
| postAdAction.disable.ArchiveDirectory | Archive the __existing__ NTFS folders using the command [Move-Item](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/move-item?view=powershell-7.3)  | This script __cannot__ be run in the __Delete__ action [Post Action](https://docs.helloid.com/hc/en-us/articles/360012421460-Configure-the-on-premises-Microsoft-Active-Directory-target-system#2.4.2:~:text=Post%20Action%20Configuration) of the [built-in Microsoft Active Directory Target Connector](https://docs.helloid.com/hc/en-us/articles/360012421460-Configure-the-on-premises-Microsoft-Active-Directory-target-system). Therefore we recommend archiving the folders in the __Disable__ action or by using an additional PS Connector  |
| grantPermission.Directory.HomeDirectory.ReferenceExample | Create folder if it doesn't exist. Optionally, set the AD attributte. Set permissions to the NTFS folder using the command [Set-ACL](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-acl?view=powershell-7.2)  | If the folder cannot be found, it will be created. This example specifically shows how to set the HomeDirectory in AD.  |
| revokePermission.Directory.HomeDirectory.ReferenceExample | Archive folder if it exists. Optionally, set the AD attributte  | If the folder cannot be found, the archive action will be skipped. This example specifically shows how to set the HomeDirectory in AD.  |


## Getting started

### Prerequisites
- The HelloID Service account requires the following permissions:
  - Local admin on the fileshare/ntfs server.
  - Full Control on the share itself ([Share permissions](https://docs.microsoft.com/en-us/iis/web-hosting/configuring-servers-in-the-windows-web-platform/configuring-share-and-ntfs-permissions#:~:text=To%20configure%20permissions%20for%20the%20share), not NTFS permissions on the folder(s)).
  - Full Control on all folders on the share ([NTFS permissions](https://docs.microsoft.com/en-us/iis/web-hosting/configuring-servers-in-the-windows-web-platform/configuring-share-and-ntfs-permissions#:~:text=To%20configure%20permissions%20for%20the%20folder%20structuree), so not Share permissions on the Share).
  - Optionally, the following policies: 
    - Local Policies > User Rights Assignment > Manage auditing and security log
    - Local Policies > User Rights Assignment > Back up files and directories
    - Local Policies > User Rights Assignment > Restore files and directories

### Remarks
 - Some scripts start the actions as a background job. While this is convenient for Provisioning to avoid the 30 second timeout, creating a background job will result in HelloID always seeing this as a successful action, since the background job is successfully started. The result of the background job will be unknown to HelloID.

## Getting help
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012558020-Configure-a-custom-PowerShell-target-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs
The official HelloID documentation can be found at: https://docs.helloid.com/
