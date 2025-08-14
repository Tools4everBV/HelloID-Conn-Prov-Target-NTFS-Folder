Mit Hilfe des NTFS Target Connectors verbindet die Identity & Access Management (IAM)-Lösung HelloID von Tools4ever NTFS mit dem Connector, der für die Erstellung des Kontos verantwortlich ist. Der NTFS Target Connector stellt sicher, dass das Benutzerverzeichnis automatisch über die richtigen NTFS-Berechtigungen verfügt und verwaltet diese Berechtigungen. In diesem Artikel erfahren Sie mehr über diese Verbindung und die Möglichkeiten.

## Was ist NTFS?

Das New Technology File System (NTFS) ist ein Dateisystem, das von modernen Windows-Betriebssystemen von Microsoft verwendet wird, ab Windows NT. NTFS basiert auf HPFS, einem Dateisystem, das Microsoft für OS/2 entwickelte, um das ältere FAT-Dateisystem zu ersetzen. 

## Warum ist eine NTFS-Verbindung sinnvoll?

In Umgebungen mit einem On-Premises-File-Server besitzt jeder Benutzer ein eigenes persönliches Verzeichnis, das auch als Homedirectory bezeichnet wird. Dieses Verzeichnis muss über die richtigen Berechtigungen im NTFS-Dateisystem verfügen, um ordnungsgemäß funktionieren zu können. Die Konfiguration dieser Berechtigungen ist jedoch nicht nur zeitaufwändig, sondern auch komplex. Der NTFS Target Connector automatisiert diesen Prozess. Der NTFS-Connector ermöglicht eine Verbindung mit verbreiteten Systemen wie:

* Active Directory
* Entra ID

Weitere Details zur Verbindung mit diesen Quellsystemen finden Sie weiter unten im Artikel.

## Wie HelloID für NFTS Ihnen helfen kann

**Effizientes Account-Management:** Die Zuweisung der richtigen NTFS-Berechtigungen zu einem Homedirectory ist ein notwendiger, aber zeitaufwändiger Prozess. Mit dem NTFS Target Connector automatisieren Sie diesen Prozess erheblich und steigern Ihre Effizienz.

**Zuverlässige Technik:** Das Verwalten von NTFS-Berechtigungen ist ein komplexer Prozess, der häufig mit Hilfe von Skripten automatisiert wird. Der NTFS-Connector macht den Einsatz einzelner Skripte überflüssig. Das ist vorteilhaft, da Sie so eine einheitliche Arbeitsweise in Ihrer Organisation sicherstellen.

**Fehlerfreies und konsistentes Arbeiten:** Mit dem NTFS Target Connector standardisieren Sie die Zuweisung von NTFS-Berechtigungen zu Homedirectories. So gewährleisten Sie ein fehlerfreies und konsistentes Arbeiten. Wichtig, denn ohne die richtigen NTFS-Berechtigungen können Benutzer nicht mit ihrem Homedirectory arbeiten.

**Arbeitsweise an Ihr IDU-Prozess koppeln:** Nicht nur die Zuweisung von NTFS-Berechtigungen ist wichtig, sondern auch deren angemessene Verwaltung. Das bedeutet auch, dass Sie die Berechtigungen bei Austritt eines Benutzers rechtzeitig wieder entziehen möchten. Der NTFS-Connector automatisiert diesen Prozess und gibt Ihnen Sicherheit.

## Wie HelloID mit NTFS integriert

HelloID setzt den NTFS-Connector als zusätzlichen Schritt während des Einstiegs- und Austrittsprozesses ein. Beim Einstieg neuer Benutzer erstellt HelloID das Konto der Person. Dieses Konto erhält ein Homedirectory, das mit den richtigen NTFS-Berechtigungen versehen werden muss. Die Zuweisung dieser Berechtigungen automatisiert HelloID mit Hilfe des NTFS-Connectors. 

Die IAM-Lösung verbindet den NTFS Target Connector mit dem Connector, der die Kontoerstellung übernimmt, und stellt damit die Kontodaten innerhalb des NTFS-Connectors zur Verfügung. Der NTFS-Connector weist anschließend die richtigen Access Control Lists (ACLs) dem Homedirectory zu, sodass dieses über die erforderlichen NTFS-Berechtigungen verfügt. Der NTFS-Connector bietet eine einfache Konfiguration zur Bestimmung der spezifischen NTFS-Berechtigungen, die in der ACL im Homedirectory eines Kontos verarbeitet werden sollen.

| Änderung im Quellsystem | 	Verfahren in NTFS | 
| ------------------------ | --------------------- | 
| **Neuer Mitarbeiter** |	Sobald ein neuer Mitarbeiter eintritt, erstellt HelloID dank einer Verbindung mit Ihrem Quellsystem automatisch ein Benutzerkonto und das zugehörige Homedirectory. Der NTFS-Connector sorgt dafür, dass dieses Verzeichnis auf dem On-Premises-File-Server in einem spezifischen Share erstellt wird und die richtigen Berechtigungen erhält. |
| **Mitarbeiter tritt aus** |	HelloID deaktiviert automatisch das Benutzerkonto, z. B. im Active Directory oder Entra ID, und informiert die beteiligten Mitarbeiter darüber. Über den NTFS Target Connector zieht HelloID in diesem Fall auch die NTFS-Berechtigungen des Benutzer-Homedirectorys zurück. |

## NTFS über HelloID mit Systemen verbinden

Der NTFS-Connector wird hauptsächlich in Kombination mit einem anderen Ziel-Connector verwendet, der für die Kontenerstellung verantwortlich ist. Einige gängige Integrationen sind:

* **Microsoft Active Directory - NTFS-Verbindung:** Die Verbindung zwischen Microsoft Active Directory und NTFS stellt sicher, dass bei der Erstellung eines neuen Benutzerkontos durch den Microsoft Active Directory Connector das zugehörige Homedirectory die richtigen NTFS-Berechtigungen erhält. Sie automatisieren mit diesem Prozess, was zeitaufwändig und komplex sein kann.

* **Microsoft Entra ID - NTFS-Verbindung:** In diesem Fall verbinden Sie den Microsoft Entra ID Connector mit dem NTFS Target Connector. Der Microsoft Entra ID Connector übernimmt in diesem Fall die Erstellung von Konten. Der NTFS-Connector sorgt wiederum dafür, dass das hiermit erstellte Homedirectory die richtigen Berechtigungen erhält.

HelloID unterstützt über 200 Connectoren. Wir bieten somit eine breite Palette an Integrationsmöglichkeiten zwischen NTFS und anderen Quell- und Zielsystemen. Wir erweitern kontinuierlich unser Angebot an Connectors und Integrationen, sodass Sie mit allen gängigen Systemen integrieren können.