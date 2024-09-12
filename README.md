# HelloID-Conn-Prov-Target-NTFS

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://www.tools4ever.nl/connector-logos/ntfs-logo.png" width="500">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-NTFS](#helloid-conn-prov-target-ntfs)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Provisioning PowerShell V2 connector](#provisioning-powershell-v2-connector)
      - [Correlation configuration](#correlation-configuration)
      - [Field mapping](#field-mapping)
    - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-NTFS-Folder is a \_target_ connector that allows you to manage the NTFS folders and permissions.
If you need to adjust the permissions on the folders **created by the HelloID built-in AD connector (Home, TsHome, Profile or TsProfile)**, the Post AD action script can be used.
For creating or managing **folders not created by HelloID**, the GrantPermission and RevokePermission scripts can be used.

The following lifecycle actions are available:

| Action                                                           | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| correlateonly/create.ps1                                         | PowerShell _create_ lifecycle action                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| permissions/HomeFolder/grantPermission.ps1                       | PowerShell _grant_ lifecycle action                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| permissions/HomeFolder/revokePermission.ps1                      | PowerShell _revoke_ lifecycle action                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| permissions/HomeFolder/permissions.ps1                           | PowerShell _permissions_ lifecycle action                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| configuration.json                                               | Default _configuration.json_                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| correlateonly/fieldMapping.json                                  | Default _fieldMapping.json_                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| postAdAction/postAdAction.create.SetDirectoryPermissions.Set-ACL | Set permissions to the **already created** NTFS folder using the command [Set-ACL](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-acl?view=powershell-7.2) used in the **Create** [Post Action](https://docs.helloid.com/hc/en-us/articles/360012421460-Configure-the-on-premises-Microsoft-Active-Directory-target-system#2.4.2:~:text=Post%20Action%20Configuration) of the [built-in Microsoft Active Directory Target Connector](https://docs.helloid.com/hc/en-us/articles/360012421460-Configure-the-on-premises-Microsoft-Active-Directory-target-system) |
| postAdAction/postAdAction.create.SetDirectoryPermissions.icacls  | Set permissions to the **already created** NTFS folder using the command [ICACLS](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls) used in the **Create** [Post Action](https://docs.helloid.com/hc/en-us/articles/360012421460-Configure-the-on-premises-Microsoft-Active-Directory-target-system#2.4.2:~:text=Post%20Action%20Configuration) of the [built-in Microsoft Active Directory Target Connector](https://docs.helloid.com/hc/en-us/articles/360012421460-Configure-the-on-premises-Microsoft-Active-Directory-target-system)                        |

## Getting started

### Provisioning PowerShell V2 connector

#### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _NTFS_ to a person in _HelloID_.

To properly setup the correlation:

1. Open the `Correlation` tab.

2. Specify the following configuration:

   | Setting                   | Value                             |
   | ------------------------- | --------------------------------- |
   | Enable correlation        | `True`                            |
   | Person correlation field  | `PersonContext.Person.ExternalId` |
   | Account correlation field | `employeeId`                      |

> [!TIP] 
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

#### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

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

## Getting help

> [!TIP] 
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012558020-Configure-a-custom-PowerShell-target-system) pages_

> [!TIP] 
> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
