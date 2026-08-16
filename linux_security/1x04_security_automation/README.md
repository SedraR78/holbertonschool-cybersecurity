# Security Automation — Sentinel

Agent Bash auto-réparateur. Lit une config externe, audite le système, corrige
les déviations et log en JSON pour ingestion SIEM.

## Fichiers

| Fichier | Rôle |
|---|---|
| `sentinel.conf` | Données : services, fichiers, ports autorisés |
| `sentinel.sh` | Logique : 3 checks + logger JSON |
| `sentinel.service` | Unité systemd oneshot |
| `sentinel.timer` | Déclenchement toutes les 5 min |
| `setup_persistence.sh` | Installation |

## Fonctions

- `log` — une ligne JSON par action (ISO 8601, composant, statut OK/FIXED/ALERT)
- `check_services` — relance les services morts
- `check_integrity` — compare le MD5 aux golden copies, restaure si divergence
- `check_ports` — tue tout listener hors whitelist

## Résultat

Premier passage : cron relancé, `sshd_config` restauré, process sur le port
4444 terminé. Second passage : `OK` partout, plus rien à corriger. L'agent
converge puis n'agit plus — c'est l'idempotence.

## Choix techniques

**Séparation code / données.** Aucune valeur en dur. Adapter l'agent à un autre
serveur ne demande que d'éditer le `.conf`, sans toucher au code qui tourne en
root.

**État réappliqué à chaque cycle**, pas de correction ponctuelle. Un attaquant
qui remodifie `sshd_config` voit son changement effacé dans les 5 minutes.

**Codes de retour vérifiés.** Sans ça, l'agent loggerait « FIXED » sur une
réparation échouée — un faux négatif envoyé au SIEM.

**Systemd plutôt que cron** : sortie dans journald, et `Persistent=true`
rattrape les exécutions manquées.

## Limites connues

**TOCTOU.** Entre le calcul du hash et la restauration, un attaquant pourrait
substituer un symlink et faire écrire l'agent (root) dans un fichier
arbitraire. Fix : descripteurs de fichier ouverts + `mv` atomique.

**MD5 n'est pas résistant aux collisions.** SHA-256 serait le bon choix.

**`check_ports` est brutal** : SIGKILL sans distinguer backdoor et service
légitime mal déclaré.

**L'agent ne se surveille pas lui-même.** Un root peut désactiver le timer ou
vider le `.conf`.

## Environnement

Ubuntu 22.04 / Kali. Root requis pour lire les configs système, restaurer les
golden copies et tuer des process tiers.
