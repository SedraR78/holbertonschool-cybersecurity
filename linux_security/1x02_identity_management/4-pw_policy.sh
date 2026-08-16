#!/bin/bash
PKG="${1:-libpam-pwquality}"
PAM_FILE="${2:-/etc/pam.d/common-password}"
OPTIONS="retry=3 minlen=12 minclass=3"

dpkg -s "$PKG" >/dev/null 2>&1 || {
	apt-get update -qq
	DEBIAN_FRONTEND=noninteractive apt-get install -y "$PKG"
}

# Repart toujours du fichier d'origine (idempotent)
if [ -f "${PAM_FILE}.bak" ] && [ ! -f "${PAM_FILE}.orig" ]; then
	cp "${PAM_FILE}.bak" "${PAM_FILE}.orig"
fi
[ -f "${PAM_FILE}.orig" ] || cp "$PAM_FILE" "${PAM_FILE}.orig"
cp "${PAM_FILE}.orig" "$PAM_FILE"

# Insere pwquality AVANT pam_unix, en requisite
sed -i "0,/pam_unix\.so/s|^\(password.*pam_unix\.so.*\)$|password\trequisite\t\t\tpam_pwquality.so $OPTIONS\n\1|" "$PAM_FILE"

# pam_unix doit reutiliser le mot de passe deja valide
sed -i "/pam_unix\.so/{/use_authtok/!s/$/ use_authtok/}" "$PAM_FILE"

grep -n "pam_pwquality\|pam_unix" "$PAM_FILE"
