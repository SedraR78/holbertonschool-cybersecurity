# Linux Capstone — Hardening Automation

Moteur d'automatisation du durcissement pour Ubuntu 22.04, conforme STIG-2024.

## Architecture

    hardening/
    ├── harden.sh          Orchestration uniquement
    ├── config/
    │   └── harden.cfg     Données, aucune logique
    ├── lib/
    │   ├── network.sh     Pare-feu et kernel
    │   ├── ssh.sh         Démon SSH
    │   ├── identity.sh    Comptes, PAM, mots de passe
    │   └── system.sh      Permissions, services
    └── README.md

## Usage

    sudo ./harden.sh

Le script refuse de s'exécuter sans root et sort avec un code d'erreur.

## Choix techniques

**Séparation code / données.** Aucune valeur métier dans les fichiers de
logique. Adapter l'outil revient à éditer `config/harden.cfg`, sans toucher
à du code exécuté en root.

**Chargement dynamique.** `harden.sh` source tous les fichiers de `lib/` via
un glob. Ajouter un module ne demande aucune modification du point d'entrée.

**Chemin absolu.** `SCRIPT_DIR` est dérivé de `BASH_SOURCE`, rendant le script
exécutable depuis n'importe quel répertoire.

**Horodatage UTC.** Sur un parc réparti, l'heure locale rend la corrélation
d'événements impossible. Le format ISO 8601 est exploitable par un SIEM.

**Mode strict.** `set -euo pipefail` bloque la poursuite après erreur,
l'usage d'une variable non définie, et l'échec silencieux dans un pipe.

## Journalisation

`/var/log/hardening.log` — niveaux `INFO`, `FIXED`, `ERROR`.

    [2026-08-17T14:04:00Z] [INFO] Hardening framework initialized

## Environnement

Ubuntu 22.04 LTS. Root requis.
