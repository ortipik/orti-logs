<div align="center">
  <img src="https://raw.githubusercontent.com/ortipik/ortipik/refs/heads/main/docs/assets/orti-logs.png" alt="Orti-Logs" width="384">
</div>
# 📜 orti-logs — Gestion des logs Lighttpd & Maintenance

[![Bash](https://img.shields.io/badge/Bash-5.0%2B-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Omega-serv](https://img.shields.io/badge/Omega-serv-0A84FF?style=for-the-badge&labelColor=0a0e1a)](https://github.com/kraynux/omega-serv/)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu%20%7C%20Debian%20%7C%20Arch-FCC624?logo=linux&logoColor=black)](https://www.kernel.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](#-licence)
[![Version](https://img.shields.io/badge/version-1.0-00d4ff.svg)](#)

> **Analyse, nettoie et sauvegarde automatiquement les logs de votre serveur web** — un script Bash interactif pour ne plus jamais perdre le contrôle de vos fichiers de logs.

---

## 📖 Sommaire

- [Présentation](#-présentation)
- [Fonctionnalités](#-fonctionnalités)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Utilisation](#-utilisation)
- [Résilience & sécurité](#-résilience--sécurité)
- [Détails techniques](#-détails-techniques)
- [Sécurité](#-sécurité)
- [FAQ](#-faq)
- [Licence](#-licence)

---

## 🎯 Présentation

**orti-logs** est un script Bash conçu pour la **gestion complète des fichiers de log** d'un `serveur web` (adaptable à tout autre serveur : omega-serv, lighttpd, nginx, apache, etc.).

Il permet d'**analyser les IPs**, de **nettoyer les logs**, de faire des **sauvegardes compressées** et de **restaurer des backups** en toute sécurité — le tout via un menu interactif.

> 💡 Initialement pensé pour **omega-serv*, le script peut être adapté à n'importe quel serveur en modifiant simplement le chemin `LOG_FILE`.

---

## ✨ Fonctionnalités

### 📊 Statistiques
- Taille du fichier de log (lisible : Ko / Mo / Go)
- Nombre de lignes
- Nombre de backups disponibles

### 🔍 Traitement d'une IP spécifique
- Supprimer toutes les lignes d'une IP
- Masquer l'IP (remplacer par `***BLOCKED***`)
- Afficher les lignes contenant l'IP
- Afficher les statistiques de l'IP (occurrences + dernière apparition)

### 🧹 Nettoyage des logs
- Vider complètement les logs (avec arrêt/redémarrage automatique de lighttpd)
- Garder uniquement les 1000 dernières lignes
- Supprimer les logs de plus de 7 jours

### 📋 Analyse
- Top 20 des IPs les plus fréquentes

### 💾 Sauvegarde & restauration
- Compresser le fichier de log avec horodatage
- Lister les backups disponibles
- Restaurer un backup (avec sauvegarde automatique avant)

---

## 📋 Prérequis

- **Bash** 5.0 ou supérieur
- **`sudo`** (le script doit être exécuté en root)
- **`lighttpd`** installé et géré par `systemctl`
- Utilitaires standards : `awk`, `grep`, `sed`, `du`, `wc`, `find`, `gzip`

### Installation des dépendances

**Debian / Ubuntu :**
```bash
sudo apt update
sudo apt install lighttpd gzip
```

**Arch Linux :**
```bash
sudo pacman -S lighttpd gzip
```

**Fedora / RHEL :**
```bash
sudo dnf install lighttpd gzip
```

---

## 🚀 Installation

```bash
# Cloner le dépôt
git clone https://github.com/Ortipik/orti-logs.git
cd orti-logs

# Rendre le script exécutable
chmod +x orti-logs.sh

# Lancer
sudo ./orti-logs.sh
```

**Installation globale (optionnelle) :**
```bash
sudo cp orti-logs.sh /usr/local/bin/orti-logs
sudo chmod +x /usr/local/bin/orti-logs
sudo orti-logs
```

---

## ⚙️ Configuration

Toute la configuration se trouve en tête du script :

```bash
# ======================================================================
# PARTIE À CONFIGURER — indiquez vos chemins de logs
# ----------------------------------------------------------------------
LOG_FILE="/var/log/lighttpd/access.log"
BACKUP_DIR="/var/log/lighttpd/backups"
# ----------------------------------------------------------------------
# ======================================================================
```

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `LOG_FILE` | Chemin du fichier de log à gérer | `/var/log/lighttpd/access.log` |
| `BACKUP_DIR` | Dossier où sont stockés les backups | `/var/log/lighttpd/backups` |

> 💡 **Astuce** : pour un serveur nginx, remplacez `LOG_FILE` par `/var/log/nginx/access.log`. Le script fonctionne tel quel.

---

## 🎮 Utilisation

```bash
sudo ./orti-logs.sh
```

### Menu principal

```
🔷====================================================🔷
🔷    GESTION DES LOGS : WEB-SERVER-ACCES             🔷
🔷====================================================🔷

📊 Taille: 12M | Lignes: 45231
📦 Backups disponibles: 5

1) Traiter une IP spécifique
2) Vider complètement les logs
3) Garder les 1000 dernières lignes
4) Supprimer les logs de plus de 7 jours
5) Afficher les IPs les plus fréquentes (top 20)
6) 💾 Sauvegarder le fichier de log
7) 📂 Lister les backups disponibles
8) 🔄 Restaurer un backup
0) Quitter

? Votre choix:
```

### Exemples d'utilisation

**Masquer une IP dans les logs :**
```
1 → 192.168.1.100 → 2
```

**Garder uniquement les 1000 dernières lignes :**
```
3
```

**Restaurer un backup :**
```
8 → [numéro du backup] → o
```

---

## 🛡️ Résilience & sécurité

Le script est conçu pour être **sûr et non destructif** :

- ✅ **Sauvegarde automatique** 📦 avant toute modification du fichier de log
- ✅ **Vérifications d'existence** 🔍 des fichiers et dossiers avant chaque action
- ✅ **Validation des IPs** ✅ avec une regex robuste avant tout traitement
- ✅ **Nettoyage automatique** 🧹 des backups de plus de 30 jours
- ✅ **Confirmation interactive** ❓ pour les actions destructives (vider, restaurer)

En cas d'erreur, le script affiche un message clair avec codes couleurs et retourne au menu **sans planter**.

---

## 🔧 Détails techniques

### Commandes système utilisées

| Commande | Usage |
|----------|-------|
| `awk` | Extraction et statistiques sur les IPs |
| `grep` / `sed` | Filtrage et modification des lignes |
| `du` / `wc` | Statistiques de taille et de lignes |
| `systemctl` | Arrêt / redémarrage de lighttpd |
| `gzip` / `gunzip` | Compression / décompression des backups |
| `find` | Nettoyage automatique des vieux backups |

### Fichiers manipulés

| Fichier / dossier | Rôle |
|-------------------|------|
| `/var/log/lighttpd/access.log` | Fichier de log principal |
| `/var/log/lighttpd/backups/` | Dossier des sauvegardes compressées |
| `/var/log/lighttpd/backups/access.log-YYYYMMDD-HHMMSS.gz` | Backups horodatés |

---

## 🔐 Sécurité

> ⚠️ **Attention** : ce script modifie les fichiers de log. Une sauvegarde automatique est effectuée avant chaque modification — mais vérifiez toujours que vous ne supprimez pas des logs critiques.

**Bonnes pratiques :**

1. Tester sur un environnement de staging avant la production
2. Vérifier régulièrement l'espace disque disponible dans `BACKUP_DIR`
3. Ne jamais exécuter le script sans `sudo` (risque d'échec silencieux)
4. Configurer `logrotate` en complément pour une rotation automatique

---

## ❓ FAQ

<details>
<summary><strong>Puis-je utiliser ce script avec nginx ou apache ?</strong></summary>

Oui ! Changez simplement la variable `LOG_FILE` en tête du script :
```bash
LOG_FILE="/var/log/nginx/access.log"
BACKUP_DIR="/var/log/nginx/backups"
```
Pensez aussi à adapter la commande `systemctl` (option 2) si nécessaire.

</details>

<details>
<summary><strong>Combien de temps sont conservés les backups ?</strong></summary>

Par défaut, les backups de plus de **30 jours** sont automatiquement supprimés à chaque nouvelle sauvegarde. Modifiable dans la fonction `backup_log()`.

</details>

<details>
<summary><strong>Le script fonctionne-t-il sans lighttpd installé ?</strong></summary>

Partiellement : les options de lecture/analyse (1, 3, 5, 6, 7, 8) fonctionnent, mais l'option 2 (vider les logs) échouera car elle utilise `systemctl stop lighttpd`.

</details>

<details>
<summary><strong>Comment changer le nombre de lignes conservées (option 3) ?</strong></summary>

Modifiez la valeur `1000` dans la ligne :
```bash
sudo tail -n 1000 "$LOG_FILE" > /tmp/lighttpd.log
```

</details>

---

## 🤝 Contribuer

1. Forkez le projet
2. Créez votre branche : `git checkout -b feature/ma-fonctionnalite`
3. Committez : `git commit -m 'Ajout de ma fonctionnalité'`
4. Pushez : `git push origin feature/ma-fonctionnalite`
5. Ouvrez une Pull Request

---

## 📜 Licence

Distribué sous licence **MIT**. Voir [LICENSE](LICENSE).

---

## 👤 Auteur

**Ortipik** — pour [OMEGA-server](https://kraynux.snake-mackarel.ts.net) 

- 🌐 Page : [orti-log](https://kraynux.snake-mackarel.ts.net/public/scripts/Logs-manager-webserver-access.html)
- 🐙 GitHub : [@Ortipik](https://github.com/Ortipik)

---

<div align="center">

**⭐ Si ce projet vous est utile, n'oubliez pas de lui mettre une étoile ! ⭐**

`© 2026 – Ortipik – Scripts & outils pour développeurs`

</div>
