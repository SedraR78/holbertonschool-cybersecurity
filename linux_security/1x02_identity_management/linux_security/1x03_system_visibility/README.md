# System Visibility — The Crypto-Jacking

Audit de l'état dynamique d'un système Linux : processus, sockets réseau et
journaux. Réponse à un incident de crypto-jacking sur le serveur web ACME.

## Findings

| Élément | Valeur |
|---|---|
| Process suspect | PID 230, nom `openssl` |
| Utilisateur | `root` |
| PPID | 219 |
| Port en écoute | 40320 (port éphémère, canal C2 probable) |
| Vecteur d'entrée | Login SSH root par mot de passe depuis 10.10.10.10 |

Le processus se fait passer pour `openssl`, un binaire légitime qui n'attire
pas l'attention dans un `top`. Un `openssl` consommant 100% de CPU en continu
n'a pourtant aucune raison d'être.

## Scripts

| Fichier | Rôle |
|---|---|
| `0-hog.sh` | Process consommant le plus de CPU |
| `1-proc_env.sh` | Variables d'environnement depuis `/proc/PID/environ` |
| `2-zombies.sh` | PID des processus en état Z |
| `3-parent.sh` | PPID d'un processus |
| `4-term.sh` | Envoie SIGTERM |
| `5-kill.sh` | Envoie SIGKILL |
| `6-freeze.sh` | Envoie SIGSTOP (gel forensique) |
| `7-listening.sh` | Ports TCP IPv4 en écoute |
| `8-who_listens.sh` | Process propriétaire d'un port |
| `9-process_user.sh` | Utilisateur propriétaire d'un processus |
| `10-recent_logs.sh` | Lignes sshd des 30 dernières minutes |
| `11-kernel.sh` | Recherche de segfault dans les logs kernel |

## Choix techniques

**Ordre forensique.** SIGSTOP avant SIGTERM avant SIGKILL. Un processus tué
fait disparaître `/proc/PID/` — environnement, PPID, descripteurs de fichiers,
tout est perdu. Le gel préserve l'état complet en mémoire pour analyse.

**`/proc` plutôt que `ps` seul.** Un malware peut remplacer le binaire `ps`
pour se masquer. `/proc` est exposé directement par le kernel et ne peut pas
être falsifié depuis l'espace utilisateur.

**Séparation SIGTERM / SIGKILL.** SIGTERM est interceptable : le processus
peut sauvegarder son état et fermer ses connexions. SIGKILL est traité par le
kernel, le processus ne le voit jamais et ne peut ni le bloquer ni l'ignorer.
On demande poliment avant de forcer.

## Corrélation avec le projet IAM

Les logs montrent `Accepted password for root from 10.10.10.10`. Les mesures du
projet précédent — `PermitRootLogin no` et `PasswordAuthentication no` —
auraient bloqué ce vecteur. Même incident, deux couches de défense.

## Limites connues

**Détection par consommation CPU uniquement.** Un miner configuré pour rester
sous les 30% d'usage passe sous le radar de `0-hog.sh`. Un vrai monitoring
compare à une baseline plutôt qu'à un maximum instantané.

**`ss -p` nécessite les privilèges du propriétaire.** Un processus root n'expose
pas son nom à un utilisateur non privilégié, ce qui limite le mapping
port-vers-process sans élévation.

**Le respawn n'est pas traité.** Tuer le processus ne suffit pas s'il est
relancé par un parent, un timer ou une tâche planifiée. Remonter la chaîne des
PPID est nécessaire, tout comme un audit de `cron` et des unités systemd.

**Aucune capture mémoire.** Le gel préserve l'état mais l'analyse réelle
demanderait un dump (`gcore`) avant terminaison.

## Environnement

Testé sur Ubuntu 22.04 et Kali Linux. Outils utilisés : `ps`, `grep`, `awk`,
`ss`, `kill`, `tr`, `sed`.
