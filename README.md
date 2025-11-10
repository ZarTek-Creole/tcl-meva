# MEva (Mini-Eva)

MEva est un script TCL pour Eggdrop qui fournit un système de commandes de modération IRC similaire à UWorld, conçu pour fonctionner avec UnrealIRCD.

## Table des matières

- [Description](#description)
- [Fonctionnalités](#fonctionnalités)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [Commandes disponibles](#commandes-disponibles)
- [Exemples d'utilisation](#exemples-dutilisation)
- [Sécurité](#sécurité)
- [Dépannage](#dépannage)
- [Contribution](#contribution)
- [Licence](#licence)
- [Auteurs](#auteurs)

## Description

MEva permet aux opérateurs IRC de gérer les canaux et les utilisateurs via des commandes simples, sans nécessiter de connexion serveur directe à UnrealIRCD. Le bot agit comme un intermédiaire et nécessite uniquement des droits IRCops sur le serveur IRC.

### Caractéristiques principales

- **Multi-interfaces** : Support des commandes publiques (canal), privées (message privé) et DCC (console Eggdrop)
- **Sécurisé** : Vérification des permissions Eggdrop avant chaque action
- **Flexible** : Configuration personnalisable via variables
- **Complet** : Gestion complète des modes de canal et actions de modération
- **Conforme** : Syntaxe IRC conforme aux standards UnrealIRCD

## Fonctionnalités

### Gestion des modes de canal

- **Op** : Donne le statut @opérateur à un utilisateur
- **DeOp** : Retire le statut @opérateur
- **Voice** : Donne le statut +voice
- **DeVoice** : Retire le statut +voice
- **DeMode** : Retire tous les modes (a, q, o, h, v)

### Modération

- **Kick** : Éjecte un utilisateur d'un canal
- **KickBan / KB** : Éjecte et bannit temporairement (60 minutes par défaut, configurable)
- **Kill** : Déconnecte un utilisateur du serveur
- **GLine** : Bannit globalement un utilisateur du réseau

### Utilitaires

- **BotNick** : Change le pseudonyme du bot
- **help** : Affiche l'aide complète

## Prérequis

### Système

- **Eggdrop** : Version 1.8.0 ou supérieure (1.9+ recommandé)
  - Nécessaire pour le support des capacités IRC (`cap` command)
  - Nécessaire pour les bindings `RAWT` (extended-join)
- **TCL 8.6** : Version 8.6 de TCL ou supérieure
- **UnrealIRCD** : Serveur IRC compatible avec UnrealIRCD (version 4.0+ recommandée)

### Permissions

- **Droits IRCops** : Le bot doit avoir les droits IRCops sur le serveur IRC pour exécuter les commandes de modération (KILL, GLINE, MODE, KICK)
- **Droits Eggdrop** : Les utilisateurs doivent avoir le flag approprié (par défaut `M` pour Master)
  - Flags disponibles : `M` (Master), `n` (Owner), `o` (Op), `m` (Admin)
  - Configurable via le paramètre `mode` dans la configuration

### Capacités IRC (optionnelles mais recommandées)

- **account-notify** : Permet de recevoir les notifications de changement de compte utilisateur
- **extended-join** : Permet de recevoir des informations supplémentaires lors des JOIN (account, realname)
  - Si non disponible, le script utilise un fallback avec `bind join`

> **Note** : Le script détecte automatiquement et active ces capacités si elles sont disponibles sur le serveur IRC.

## Installation

### Étape 1 : Télécharger le script

Placez `MEva.tcl` dans le répertoire `scripts/` de votre Eggdrop :

```bash
cp MEva.tcl /chemin/vers/eggdrop/scripts/
```

### Étape 2 : Charger le script

#### Méthode 1 : Chargement manuel

Dans la console DCC d'Eggdrop ou via telnet :

```
.load scripts/MEva.tcl
```

#### Méthode 2 : Chargement automatique

Ajoutez dans votre fichier de configuration Eggdrop (généralement `eggdrop.conf`) :

```
source scripts/MEva.tcl
```

Puis rechargez la configuration :

```
.rehash
```

### Étape 3 : Vérifier le chargement

Le bot devrait afficher dans les logs :

```
Chargement de Mini-Eva (MEva) version 1.0.0 by ZarTek-Creole & Tibs
```

### Désinstallation

Pour désinstaller le script :

```
.unload MEva
```

Le script nettoie automatiquement tous les bindings et supprime le namespace lors de la désinstallation.

## Configuration

Les paramètres sont définis dans le tableau `CONF` au début du script (`MEva.tcl`). Modifiez ces valeurs selon vos besoins :

```tcl
array set CONF {
    "mode"              "M"      # Flag Eggdrop requis (M=Master, n=Owner, o=Op, etc.)
    "prefix"            "m"      # Préfixe commandes privées/DCC (ex: /msg bot mOp)
    "publicprefix"      "!"      # Préfixe commandes publiques (ex: !mOp dans un canal)
    "raison_default"    "Merci de respecter la netiquette du réseau."
    "kick_prefix"       "Avertissement: "
    "ban_minutes"       60       # Durée ban temporaire en minutes (0 = permanent)
    "action_signed"     1        # Signer les actions (0 = non, 1 = oui)
    "signed_msg"        " - (par %s)"
}
```

### Paramètres détaillés

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `mode` | Flag Eggdrop requis pour utiliser les commandes | `M` (Master) |
| `prefix` | Préfixe pour les commandes privées et DCC | `m` |
| `publicprefix` | Préfixe pour les commandes publiques dans les canaux | `!` |
| `raison_default` | Raison par défaut si aucune raison n'est spécifiée | `"Merci de respecter la netiquette du réseau."` |
| `kick_prefix` | Préfixe ajouté aux raisons de kick | `"Avertissement: "` |
| `ban_minutes` | Durée du ban temporaire en minutes (0 = permanent) | `60` |
| `action_signed` | Activer la signature des actions avec le nom de l'opérateur | `1` (oui) |
| `signed_msg` | Format du message de signature | `" - (par %s)"` |

### Personnalisation

Pour modifier la configuration :

1. Éditez `MEva.tcl` avec votre éditeur préféré
2. Modifiez les valeurs dans le tableau `CONF`
3. Rechargez le script :
   ```
   .rehash
   ```
   ou
   ```
   .unload MEva
   .load scripts/MEva.tcl
   ```

## Utilisation

MEva supporte trois modes d'utilisation :

### Commandes publiques (dans un canal)

Toutes les commandes publiques utilisent le préfixe `!m` par défaut (configurable via `publicprefix` + `prefix`) :

```
!mOp #canal utilisateur
!mKick #canal utilisateur raison
!mhelp
```

### Commandes privées (message privé au bot)

Les commandes privées utilisent le préfixe `m` par défaut (configurable via `prefix`) :

```
/msg BotNick mOp #canal utilisateur
/msg BotNick mKick #canal utilisateur raison
/msg BotNick mhelp
```

### Commandes DCC (console Eggdrop)

Les commandes DCC utilisent le préfixe `.m` par défaut (configurable via `.` + `prefix`) :

```
.mOp #canal utilisateur
.mKick #canal utilisateur raison
.mhelp
```

## Commandes disponibles

### Gestion des modes

#### `Op`
Donne le statut @opérateur à un utilisateur sur un canal.

**Syntaxe :**
```
!mOp <#canal> <pseudo>
```

**Exemple :**
```
!mOp #general Alice
```

#### `DeOp`
Retire le statut @opérateur d'un utilisateur sur un canal.

**Syntaxe :**
```
!mDeOp <#canal> <pseudo>
```

**Exemple :**
```
!mDeOp #general Alice
```

#### `Voice`
Donne le statut +voice à un utilisateur sur un canal.

**Syntaxe :**
```
!mVoice <#canal> <pseudo>
```

**Exemple :**
```
!mVoice #general Bob
```

#### `DeVoice`
Retire le statut +voice d'un utilisateur sur un canal.

**Syntaxe :**
```
!mDeVoice <#canal> <pseudo>
```

**Exemple :**
```
!mDeVoice #general Bob
```

#### `DeMode`
Retire tous les modes (a, q, o, h, v) d'un utilisateur sur un canal.

**Syntaxe :**
```
!mDeMode <#canal> <pseudo>
```

**Exemple :**
```
!mDeMode #general Charlie
```

### Modération

#### `Kick`
Éjecte un utilisateur d'un canal.

**Syntaxe :**
```
!mKick <#canal> <pseudo> [raison]
```

**Exemple :**
```
!mKick #general Dave Spam
```

#### `KickBan` / `KB`
Éjecte et bannit un utilisateur d'un canal. Le ban est temporaire par défaut (60 minutes).

**Syntaxe :**
```
!mKB <#canal> <pseudo> [raison]
!mKickBan <#canal> <pseudo> [raison]
```

**Exemple :**
```
!mKB #general Eve Harassement
```

#### `Kill`
Déconnecte un utilisateur du serveur IRC.

**Syntaxe :**
```
!mKill <pseudo> [raison]
```

**Exemple :**
```
!mKill Frank Violation des règles
```

#### `GLine`
Bannit globalement un utilisateur du réseau IRC (tous les serveurs).

**Syntaxe :**
```
!mGLine <pseudo> [raison]
```

**Exemple :**
```
!mGLine Spammer Comportement abusif
```

### Utilitaires

#### `BotNick`
Change le pseudonyme du bot.

**Syntaxe :**
```
!mBotNick <nouveau_pseudo>
```

**Exemple :**
```
!mBotNick NouveauNom
```

#### `help`
Affiche l'aide complète avec toutes les commandes disponibles.

**Syntaxe :**
```
!mhelp
```

## Exemples d'utilisation

### Scénario 1 : Donner les droits opérateur

```
Utilisateur: !mOp #general Alice
Bot: Félicitation: Alice est maintenant @opérateur sur #general.
```

### Scénario 2 : Éjecter un utilisateur

```
Utilisateur: !mKick #general Bob Spam
Bot: Félicitation: Vous avez éjécté 'Bob' du salon '#general' pour le motif: 'Avertissement: Spam - (par Utilisateur)'.
```

### Scénario 3 : Kick + Ban temporaire

```
Utilisateur: !mKB #general Charlie Harassement
Bot: Félicitation: Vous avez éjecté 'Charlie' du salon '#general' pour le motif: 'Avertissement: Harassement (Expire le 15/01/2024 à 14:30:00 dans 1 heure) - (par Utilisateur)'.
```

Le ban sera automatiquement levé après 60 minutes.

### Scénario 4 : Déconnecter un utilisateur du serveur

```
Utilisateur: !mKill Dave Violation des règles
Bot: Félicitation: Vous avez éjécté 'Dave' du serveur pour le motif: 'Violation des règles - (par Utilisateur)'.
```

### Scénario 5 : Bannir globalement

```
Utilisateur: !mGLine Spammer Comportement abusif
Bot: Félicitation: Vous avez banni globalement 'Spammer' du réseau pour le motif: 'Comportement abusif - (par Utilisateur)'.
```

## Sécurité

### Vérification des permissions

- **Vérification Eggdrop** : Seuls les utilisateurs avec le flag approprié (par défaut `M`) peuvent utiliser les commandes
- **Vérification des arguments** : Toutes les commandes valident leurs arguments avant exécution
- **Signature des actions** : Par défaut, toutes les actions sont signées avec le nom de l'opérateur

### Bans temporaires

Les bans créés via `KickBan` sont automatiquement levés après la durée configurée (`ban_minutes`). Cela évite les bans permanents accidentels.

### Bonnes pratiques

1. **Restreindre les permissions** : Utilisez le flag Eggdrop le plus restrictif possible (`o` au lieu de `M` si possible)
2. **Surveiller les logs** : Vérifiez régulièrement les actions effectuées via MEva
3. **Former les opérateurs** : Assurez-vous que tous les opérateurs comprennent l'utilisation des commandes
4. **Configurer les raisons** : Personnalisez `raison_default` selon les règles de votre réseau

## Architecture et détails techniques

### Structure du code

- **Namespace** : `::MEva` - Toutes les procédures et variables sont encapsulées dans ce namespace
- **Variables principales** :
  - `SCRIPT` : Métadonnées du script (nom, version, auteur)
  - `CONF` : Configuration du script (préfixes, raisons, etc.)
  - `CMD_LIST` : Liste des commandes disponibles
- **Système de bindings** : Chaque commande est automatiquement liée aux trois interfaces (pub, msg, dcc)

### Gestion des capacités IRC

Le script détecte et active automatiquement les capacités IRC suivantes si disponibles :

- **account-notify** : Activé automatiquement si disponible
- **extended-join** : Activé automatiquement si disponible, avec fallback sur `bind join` sinon

### Format des messages de confirmation

Tous les messages de confirmation suivent le format :
```
Félicitation: [description de l'action] - (par [nom_opérateur])
```

Les raisons de kick/ban incluent :
- Le préfixe configuré (`kick_prefix`)
- La raison spécifiée ou la raison par défaut
- La date d'expiration (pour les bans temporaires)
- La signature de l'opérateur (si `action_signed` est activé)

### Gestion des bans temporaires

Les bans créés via `KickBan` sont gérés via `utimer` d'Eggdrop :
- Conversion automatique de minutes en secondes
- Format de la date d'expiration : `DD/MM/YYYY à HH:MM:SS`
- Durée formatée en français (jours, heures, minutes)

> **Important** : Les timers sont perdus en cas de redémarrage du bot. Les bans temporaires ne seront pas automatiquement levés si le bot redémarre avant l'expiration.

## Limitations connues

### Bans temporaires

- **Perte des timers** : Si le bot redémarre ou se déconnecte, les timers de levée de ban sont perdus
  - **Solution** : Les bans restent actifs jusqu'à expiration manuelle ou levée automatique si le bot reste connecté
- **Limitation serveur** : Les bans sont gérés au niveau du canal, pas au niveau serveur

### Commandes IRC

- **Dépendance IRCops** : Toutes les commandes de modération nécessitent des droits IRCops sur le serveur
- **Support serveur** : Certaines commandes (KILL, GLINE) nécessitent un serveur IRC compatible (UnrealIRCD recommandé)

### Compatibilité

- **Version Eggdrop** : Nécessite Eggdrop 1.8+ pour les capacités IRC et bindings RAWT
- **Version TCL** : Nécessite TCL 8.6+ pour certaines fonctionnalités (namespaces, `clock add`)

## Dépannage

### Le script ne se charge pas

**Problème :** Le script ne se charge pas ou génère une erreur.

**Solutions :**
1. Vérifiez que le fichier `MEva.tcl` est dans le répertoire `scripts/` d'Eggdrop
2. Vérifiez les permissions du fichier (lecture nécessaire)
3. Vérifiez la syntaxe TCL avec : `tclsh MEva.tcl`
4. Consultez les logs d'Eggdrop pour les erreurs détaillées

### Les commandes ne fonctionnent pas

**Problème :** Les commandes ne répondent pas ou retournent une erreur de permission.

**Solutions :**
1. Vérifiez que vous avez le flag Eggdrop approprié (par défaut `M`)
2. Vérifiez que le bot a les droits IRCops sur le serveur
3. Vérifiez la syntaxe de la commande (voir section [Commandes disponibles](#commandes-disponibles))
4. Vérifiez que le bot est présent dans le canal (pour les commandes de canal)

### Les commandes IRC échouent

**Problème :** Les commandes sont acceptées mais les actions IRC ne sont pas effectuées.

**Solutions :**
1. Vérifiez que le bot a les droits IRCops nécessaires
2. Vérifiez que le bot est opérateur sur le canal (pour les commandes de mode)
3. Vérifiez la syntaxe des commandes IRC dans les logs du serveur
4. Vérifiez que le serveur IRC supporte les commandes utilisées (KILL, GLINE, etc.)

### Le ban temporaire ne s'expire pas

**Problème :** Le ban créé via `KickBan` ne s'expire pas après la durée configurée.

**Solutions :**
1. Vérifiez que `ban_minutes` est supérieur à 0
2. Vérifiez que le bot est toujours connecté (les timers sont perdus en cas de déconnexion ou redémarrage)
3. Vérifiez les logs pour les erreurs de timer
4. Vérifiez que le bot a toujours les droits nécessaires pour lever le ban (MODE -b)

> **Note** : Si le bot redémarre, les timers sont perdus. Vous devrez lever manuellement les bans ou attendre leur expiration naturelle selon la configuration du serveur IRC.

### Erreurs de compatibilité Eggdrop

**Problème :** Le script ne se charge pas ou génère des erreurs liées aux capacités IRC.

**Solutions :**
1. Vérifiez la version d'Eggdrop : `version` dans la console DCC (minimum 1.8.0 requis)
2. Vérifiez que votre version d'Eggdrop supporte les commandes `cap` (Eggdrop 1.8+)
3. Si vous utilisez une version plus ancienne, certaines fonctionnalités (extended-join) ne seront pas disponibles mais le script fonctionnera en mode dégradé

### Les capacités IRC ne s'activent pas

**Problème :** Les capacités IRC (account-notify, extended-join) ne sont pas activées.

**Solutions :**
1. Vérifiez que le serveur IRC supporte ces capacités (UnrealIRCD 4.0+)
2. Vérifiez les logs d'Eggdrop pour les messages d'erreur liés aux capacités
3. Le script fonctionne sans ces capacités, mais certaines fonctionnalités futures pourraient en dépendre

## Contribution

Les contributions sont les bienvenues ! Voici comment contribuer :

1. **Signaler des bugs** : Ouvrez une issue sur le dépôt avec une description détaillée
2. **Proposer des améliorations** : Ouvrez une issue avec votre suggestion
3. **Soumettre du code** : Créez une pull request avec vos modifications

### Guidelines de contribution

- Respectez le style de code existant
- Ajoutez des commentaires pour le code complexe
- Testez vos modifications avant de soumettre
- Documentez les nouvelles fonctionnalités

## Licence

Ce projet est sous licence Apache 2.0. Voir le fichier `LICENSE` pour plus de détails.

## Auteurs

- **ZarTek-Creole**
- **Tibs**

Version actuelle : **1.0.0**

## Compatibilité

### Versions Eggdrop supportées

| Version Eggdrop | Support | Notes |
|----------------|---------|-------|
| 1.8.0 - 1.8.x | ✅ Complet | Support de base, capacités IRC disponibles |
| 1.9.0+ | ✅ Complet | Recommandé, toutes les fonctionnalités |
| < 1.8.0 | ⚠️ Limité | Fonctionne mais sans capacités IRC (extended-join, account-notify) |

### Serveurs IRC testés

- ✅ **UnrealIRCD 4.0+** : Support complet, toutes les fonctionnalités
- ✅ **UnrealIRCD 5.0+** : Support complet, recommandé
- ⚠️ **Autres serveurs** : Fonctionne mais certaines commandes (GLINE) peuvent ne pas être disponibles

### Versions TCL

- ✅ **TCL 8.6+** : Support complet
- ⚠️ **TCL 8.5** : Fonctionne mais certaines fonctionnalités (`clock add`) peuvent ne pas être disponibles

## Ressources

### Documentation officielle

- [Documentation Eggdrop](https://www.eggheads.org/)
- [Documentation UnrealIRCD](https://www.unrealircd.org/docs/)
- [Documentation TCL 8.6](https://www.tcl-lang.org/man/tcl8.6/)

### Liens utiles

- [Guide des flags Eggdrop](https://www.eggheads.org/support/egghtml/1.9/core.html#flags)
- [Commandes IRC UnrealIRCD](https://www.unrealircd.org/docs/IRC_commands)
- [Capacités IRC (IRCv3)](https://ircv3.net/specs/extensions/capability-negotiation)

## Changelog

### Version 1.0.0 (2024)

- Version stable initiale
- Implémentation complète de toutes les commandes
- Documentation complète
- Corrections de bugs
- Améliorations selon les meilleures pratiques TCL 8.6
- Support multi-interfaces (public, privé, DCC)
- Gestion des capacités IRC (account-notify, extended-join)
