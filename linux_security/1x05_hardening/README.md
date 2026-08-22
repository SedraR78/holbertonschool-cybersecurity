# Linux Capstone — Hardening Automation

STIG-2024 hardening engine for Ubuntu 22.04. Turns a fresh install into a
secured bastion host.

## Architecture

    hardening/
    ├── harden.sh          Orchestration only
    ├── config/
    │   └── harden.cfg     Data, no logic
    ├── lib/
    │   ├── network.sh     Firewall and kernel (N-01 to N-03)
    │   ├── ssh.sh         SSH daemon (S-01, S-02)
    │   ├── identity.sh    Accounts and PAM (I-01 to I-04)
    │   └── system.sh      Packages and report (H-01 to H-03)
    ├── audit_report.txt   Compliance evidence
    └── README.md

## Usage

    sudo ./harden.sh

Exits with an error if not run as root. Report goes to `audit_report.txt`,
logs to `/var/log/hardening.log`.

## Controls

| ID | Control |
|---|---|
| N-01 | Firewall policy persisted to `/etc/hardening/firewall.rules` |
| N-02 | Allowed ports: SSH, HTTP, HTTPS |
| N-03 | `ip_forward = 0`, `icmp_echo_ignore_all = 1` in `/etc/sysctl.conf` |
| S-01 | Key-based authentication only |
| S-02 | `PermitRootLogin no` |
| I-01 | Password: 12 chars minimum, 4 classes, 90-day max age |
| I-02 | Account lockout after 5 failed attempts |
| I-03 | Removes UID > 1000 accounts not in sudo or wheel |
| I-04 | Root password locked |
| H-01 | Non-interactive update and upgrade |
| H-02 | Purges telnet, ftp, netcat-traditional |
| H-03 | Installs auditd and fail2ban |

## Design notes

**Code and data are separated.** No business value appears in the logic files.
Adapting the tool to another fleet means editing `config/harden.cfg`, never
touching code that runs as root.

**Idempotence through delete-then-write.** Every configuration write removes
the existing key before rewriting it, so a file holds exactly one occurrence
regardless of how many times the script runs.

**Directives are inserted at the top of `sshd_config`.** sshd keeps the first
value it finds; appending risks landing inside an existing `Match` block, where
the setting would apply to a subset of users only.

**PAM stack order.** `pam_pwquality` is placed before `pam_unix`. PAM runs
modules top to bottom — writing the hash before the complexity check makes the
policy meaningless.

**Aging applies to existing accounts.** `login.defs` only governs accounts
created afterwards, so `chage` is run against each current account.

**The operator is protected.** The account in `$SUDO_USER` is excluded from
deletion and password aging. Without that guard, a key-authenticated account
ends up with an expired password it cannot change — having never had one — and
loses all access.

**Validate before applying.** `sshd -t` runs before any reload, with rollback
to the backup on failure.

## Idempotence check

    md5sum /etc/sysctl.conf /etc/ssh/sshd_config
    sudo ./harden.sh
    md5sum /etc/sysctl.conf /etc/ssh/sshd_config
    sudo ./harden.sh
    md5sum /etc/sysctl.conf /etc/ssh/sshd_config

The last two sets must match. Each of these must return `1`:

    grep -c "ip_forward" /etc/sysctl.conf
    grep -c "^PermitRootLogin" /etc/ssh/sshd_config
    grep -c "pam_pwquality" /etc/pam.d/common-password

## Known limitations

**The firewall is not activated.** As specified, the policy is written to a
persistent config file rather than applied. A production version would enforce
it through UFW, allowing SSH before any default-deny rule to avoid lockout.

**MD5 is used for integrity.** Fine for detecting accidental changes, not
against an adversary who can forge a collision. SHA-256 would be correct.

**No dry-run mode.** Previewing changes without applying them would be required
before any production rollout.

**No execution lock.** Two concurrent runs could write to the same files. A
`flock` would fix it.

**Local accounts only.** `/etc/passwd` does not cover LDAP or Active Directory
identities; `getent passwd` would be needed in a centralised environment.

## Environment

Ubuntu 22.04 LTS. Root required. Passes `shellcheck` with no warnings.
