Avec le connecteur NTFS, la solution de Gestion des Identités et Accès (GIA) HelloID de Tools4ever connecte NTFS au connecteur responsable de la création de comptes. Le connecteur cible « NTFS Target Connector » garantit que le répertoire personnel des utilisateurs dispose automatiquement des bonnes permissions NTFS et gère ces permissions. Cet article vous en dira plus sur cette intégration et ses fonctionnalités.

## Qu’est-ce que NTFS

Le New Technology File System (NTFS) est un système de fichiers utilisé par les systèmes d'exploitation Windows modernes de Microsoft, à partir de Windows NT. NTFS est basé sur HPFS, un système de fichiers développé par Microsoft pour OS/2 pour remplacer l'ancien système de fichiers FAT. 

## Pourquoi utiliser le connecteur NTFS ?

Dans les environnements utilisant un serveur de fichiers sur site, chaque utilisateur dispose d'un dossier personnel appelé répertoire personnel (ou home directory). Ce dossier doit avoir les bonnes permissions NTFS pour fonctionner correctement. Configurer cela manuellement est non seulement chronophage, mais aussi complexe. Le connecteur cible NTFS automatise ce processus et permet de se connecter à des systèmes courants tels que :

*	Active Directory
*	Entra ID

Vous trouverez plus de détails sur l'intégration avec ces systèmes sources plus bas.

## Les avantages d'HelloID pour NTFS :

**Gestion efficace des comptes :** Attribuer les bonnes permissions NTFS à un répertoire personnel est une tâche nécessaire mais chronophage. Avec le connecteur cible NTFS, vous pouvez automatiser ce processus, augmentant ainsi votre efficacité.

**Technologie fiable :** La gestion des permissions NTFS est un processus complexe souvent automatisé par des scripts. Le connecteur NTFS élimine le besoin de scripts individuels, assurant une méthode de travail uniforme au sein de votre organisation.

**Travail plus fluide et sans erreur :** Avec le connecteur cible NTFS, vous standardisez l'attribution des permissions NTFS aux répertoires personnels, garantissant un travail plus fluide et sans erreur. C'est crucial, car sans les bonnes permissions NTFS, les utilisateurs ne peuvent pas utiliser leur répertoire personnel.

**Intégration avec vos processus d'identité :** Non seulement il est important d'attribuer des permissions NTFS, mais il est également crucial de les gérer correctement. Cela inclut la révocation des permissions lors du départ d'un utilisateur. Le connecteur NTFS automatise ce processus, vous offrant ainsi une tranquillité d'esprit.

## Comment HelloID s'intègre avec NTFS 

HelloID utilise le connecteur NTFS comme une étape supplémentaire lors des processus d'intégration et de départ des utilisateurs. Lors de l'intégration d'un nouvel utilisateur, HelloID crée le compte de la personne. Ce compte se voit attribuer un répertoire personnel, qui doit être doté des permissions NTFS appropriées. HelloID automatise l'attribution de ces permissions via le connecteur NTFS.

La solution GIA connecte le connecteur cible NTFS au connecteur responsable de la création de comptes, rendant ainsi les informations du compte disponibles pour le connecteur NTFS. Le connecteur NTFS attribue ensuite les bonnes listes de contrôle d'accès (ACL) au répertoire personnel, assurant ainsi qu'il dispose des permissions NTFS nécessaires. Le connecteur NTFS offre une configuration simple pour déterminer les permissions spécifiques à appliquer aux ACL du répertoire personnel d'un compte.

| Modification dans le système source	| Procédure dans NTFS |
| ----------------------------------- | ------------------- |
| **Nouvel employé** | Dès qu'un nouvel employé est embauché, HelloID crée automatiquement un compte utilisateur et un répertoire personnel associé grâce à une connexion avec votre système source. Le connecteur NTFS s'assure que ce dossier est créé sur le serveur de fichiers sur site dans un partage spécifique et que les permissions appropriées sont attribuées. |
| **Départ d'un employé** | 	HelloID désactive automatiquement le compte utilisateur dans, par exemple, Active Directory ou Entra ID, et informe les employés concernés. Le connecteur NTFS révoque alors également les permissions NTFS du répertoire personnel de l'utilisateur. | 

## Connecter NTFS via HelloID à d'autres systèmes :

Le connecteur NTFS est principalement utilisé en combinaison avec un autre connecteur cible responsable de la création de comptes. Quelques intégrations courantes incluent :

* **Intégration Active Directory - NTFS :** L'intégration entre Microsoft Active Directory et NTFS garantit que lors de la création d'un nouveau compte utilisateur par le connecteur Microsoft Active Directory, le répertoire personnel associé reçoit les bonnes permissions NTFS. Vous automatisez ainsi ce processus, souvent complexe et chronophage.

* **Intégration Entra ID - NTFS :** Dans ce cas, vous connectez le connecteur Microsoft Entra ID au connecteur cible NTFS. Le connecteur Microsoft Entra ID prend en charge la création des comptes. Le connecteur NTFS garantit ensuite que le répertoire personnel créé reçoit les permissions appropriées.

HelloID propose plus de 200 connecteurs, offrant une large gamme d'intégrations possibles entre NTFS et d'autres systèmes sources et cibles. Nous élargissons continuellement notre offre de connecteurs et d'intégrations, vous permettant de vous connecter à tous les systèmes populaires.
