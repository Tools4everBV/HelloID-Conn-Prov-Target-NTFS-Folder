## NTFS Target Connector

With the NTFS Target Connector, Tools4ever's identity & access management (IAM) solution HelloID links NTFS to the connector responsible for account creation. The NTFS Target Connector ensures that users' home directories automatically have the correct NTFS permissions and manages these permissions. This article provides more information about this connection and its capabilities.

## What is NTFS?

New Technology File System (NTFS) is a file system used by modern Microsoft Windows operating systems, meaning Windows NT and more recent. NTFS is based on HPFS, a file system developed by Microsoft for OS/2 to replace the older FAT file system.

## Why is NTFS integration useful?

In environments using an on-premises file server, each user has their own personal folder, also known as a home directory. This folder must have the correct permissions on the NTFS file system to function properly. Configuring these permissions is not only time-consuming but also complex. The NTFS Target Connector automates this process. The NTFS connector allows integration with common systems such as:

* Active Directory
* Entra ID

Further details about the integration with these source systems can be found later in this article.

## HelloID for NTFS helps with

**Efficient account management:** Assigning the correct NTFS permissions to a home directory is a necessary but time-consuming process. The NTFS Target Connector significantly automates this process, increasing efficiency.

**Reliable technology:** Managing NTFS permissions is a complex process often automated using scripts. The NTFS connector eliminates the need for individual scripts. This ensures a uniform approach within your organisation.

**Error-free and consistent operation:** The NTFS Target Connector standardises the assignment of NTFS permissions to home directories. This ensures error-free and consistent operation. This is important because without the correct NTFS permissions, users cannot access their home directory.

**Integration with your IDU process:** Not only is assigning NTFS permissions important, but managing them adequately is as well. This means that permissions need to be revoked in a timely manner when a user leaves. The NTFS connector automates this process and provides assurance.

## How HelloID integrates with NTFS

HelloID uses the NTFS connector as an additional step during the onboarding and offboarding process. When new users are onboarded, HelloID creates the person’s account. This account is assigned a home directory, which must have the correct NTFS permissions. HelloID automates the assignment of these permissions using the NTFS connector.

The IAM solution links the NTFS Target Connector to the connector responsible for account creation, making the account information available within the NTFS connector. The NTFS connector then assigns the correct Access Control Lists (ACLs) to the home directory, ensuring it has the necessary NTFS permissions. The NTFS connector provides simple configuration for determining the specific NTFS permissions to be included in the ACL of an account’s home directory.

| Change in source system | 		Procedure in NTFS | 
| ---------------------------- | --------------------- | 
| New employee| As soon as a new employee joins, HelloID automatically creates a user account and associated home directory through a link with your source system. The NTFS connector ensures that this folder on the on-premises file server is created in a specific share and is assigned the correct permissions. | 
| Employee leaves the organisation |	HelloID automatically deactivates the user account in, for example, Active Directory or Entra ID, and informs the relevant staff. Through the NTFS Target Connector, HelloID also revokes the NTFS permissions of the user’s home directory. | 

## Integrating NTFS with systems via HelloID

The NTFS connector is primarily used in combination with another target connector responsible for creating accounts. Some common integrations are:

**Microsoft Active Directory – NTFS integration:** The integration between Microsoft Active Directory and NTFS ensures that when a new user account is created by the Microsoft Active Directory connector, the associated home directory is assigned the correct NTFS permissions. This automates a process that can be time-consuming and complex.

**Microsoft Entra ID – NTFS integration:** In this case, the Microsoft Entra ID connector is linked to the NTFS Target Connector. The Microsoft Entra ID connector handles account creation. The NTFS connector ensures that the home directory created receives the correct permissions.

HelloID supports over 200 connectors. We offer a wide range of integration possibilities between NTFS and other source and target systems. We continuously expand our range of connectors and integrations, allowing you to integrate with all popular systems.
