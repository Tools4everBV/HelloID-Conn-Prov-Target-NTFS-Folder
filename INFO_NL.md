# NTFS Target Connector

Met behulp van de NTFS Target Connector koppelt de identity & access management (IAM)-oplossing HelloID van Tools4ever NTFS aan de connector die verantwoordelijk is voor het aanmaken van het account. De NTFS Target Connector zorgt dat de homedirectory van gebruikers automatisch over de juiste NTFS permissies beschikt, en beheert deze permissies. In dit artikel lees je meer over deze koppeling en de mogelijkheden.

# Wat is NTFS?

New Technology File System (NTFS) is een bestandssysteem dat door moderne Windows-besturingssystemen van Microsoft - Windows NT en hoger - wordt gebruikt. NTFS is gebaseerd op HPFS, een bestandssysteem dat Microsoft ontwikkelde voor OS/2 ter vervanging van het oudere FAT-besturingssysteem. 

# Waarom is NTFS koppeling handig?

In omgevingen waarin met een on-premises fileserver wordt gewerkt, beschikt iedere gebruiker over een eigen persoonlijke map die we ook wel een homedirectory noemen. Deze map moet over de juiste permissies op het NTFS-bestandssysteem beschikken om goed te kunnen functioneren. Het configureren hiervan is niet alleen tijdrovend, maar ook complex. De NTFS Target Connector automatiseert het proces. De NTFS-connector maakt een koppeling met veelvoorkomende systemen mogelijk, zoals: 

*	Active Directory
*	Entra ID

Verdere details over de koppeling met deze bronsystemen zijn te vinden verderop in het artikel.

# HelloID voor NFTS helpt je met

**Efficiënt accountbeheer:** Het toekennen van de juiste NTFS-permissies aan een homedirectory is een noodzakelijk, maar tijdrovend proces. Met behulp van de NTFS Target Connector automatiseer je dit proces in belangrijke mate en verhoog je je efficiëntie. 

**Betrouwbare techniek:** Het beheren van NTFS-permissies is een complex proces, dat vaak met behulp van script wordt geautomatiseerd. De NTFS-connector maakt het gebruik van losse scripts overbodig. Prettig, want zo zorg je voor een uniforme werkwijze binnen je organisatie. 

**Foutloos en consistent werken:** Met de NTFS Target Connector standaardiseer je het toekennen van NTFS-permissies aan homedirectories. Zo stel je zeker dat je foutloos en consistent werkt. Belangrijk, want zonder de juiste NTFS-permissies kunnen gebruikers niet aan de slag met hun homedirectory. 

**Werkwijze koppelen aan je IDU-proces:** Niet alleen het toekennen van NTFS-permissies is van belang, maar ook het adequaat beheren hiervan. Dat betekent ook dat je permissies bij uitstroom van een gebruiker tijdig weer wilt intrekken. De NTFS-connector automatiseert dit proces en geeft je zekerheid.

# Hoe HelloID integreert met NTFS

HelloID zet de NTFS-connector in als extra stap gedurende het instroom- en uitstoomproces. Bij de instroom van nieuw gebruikers creëert HelloID het account van de persoon. Dit account krijgt een homedirectory toegewezen, dat van de juiste NTFS-permissies moet worden voorzien. Het toekennen van deze permissies automatiseert HelloID met behulp van de NTFS-connector. 

De IAM-oplossing koppelt de NTFS Target Connector aan de connector die het aanmaken van het account verzorgt, en maakt daarmee de accountgegevens beschikbaar binnen de NTFS-connector. De NTFS-connector wijst op zijn beurt de juiste Access Control Lists (ACL’s) toe aan de homedirectory, zodat deze over de benodigde NTFS-permissies beschikt. De NTFS-connector voorziet in een eenvoudige configuratie voor het bepalen van de specifieke NTFS-permissies die moeten worden verwerkt in de ACL op de homedirectory van een account.

| Wijziging in bronsysteem | 	Procedure in NTFS | 
| ---------------------------- | --------------------- | 
| **Nieuwe medewerker** |	Zodra een nieuwe medewerker in dienst treedt maakt HelloID dankzij een koppeling met je bronsysteem automatisch een gebruikersaccount en bijhorende homedirectory aan. De NTFS-connector zorgt dat deze map op de on-premises fileserver in een specifieke share wordt aangemaakt en de map de juiste permissies toegewezen krijgt.|
| **Medewerker treedt uit dienst** |	HelloID deactiveert automatisch het gebruikersaccount in bijvoorbeeld Active Directory of Entra ID, en informeert betrokken medewerkers hierover. Via de NTFS Target Connector trekt HelloID in dit geval ook de NTFS-permissies van de homedirectory van de gebruiker in. | 


# NTFS via HelloID koppelen met systemen

De NTFS-connector wordt voornamelijk gebruikt in combinatie met een andere doelconnector, die verantwoordelijk is voor het aanmaken van accounts. Enkele veelvoorkomende integraties zijn:

**Microsoft Active Directory - NTFS koppeling:** De koppeling tussen Microsoft Active Directory en NTFS zorgt dat bij het aanmaken van een nieuwe gebruikersaccount door de Microsoft Active Directory connector de bijbehorende homedirectory de juiste NTFS-permissies krijgt toegewezen. Je automatiseert hiermee dit proces, wat tijdrovend en complex kan zijn.

**Microsoft Entra ID - NTFS koppeling:** In dit geval koppel je de Microsoft Entra ID connector aan de NTFS Target Connector. De Microsoft Entra ID connector neemt in dit geval het aanmaken van accounts voor rekening. De NTFS-connector zorgt op zijn beurt dat de homedirectory die hierbij wordt gecreëerd de juiste permissies krijgt toegewezen. 

HelloID ondersteunt ruim 200 connectoren. We bieden dan ook een breed scala aan integratiemogelijkheden tussen NTFS en andere bron- en doelsystemen. We breiden ons aanbod aan connectoren en integraties continu uit, waardoor je met alle populaire systemen kunt integreren. 
