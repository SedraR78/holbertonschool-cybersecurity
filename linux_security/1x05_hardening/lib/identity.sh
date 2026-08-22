#!/bin/bash
# shellcheck disable=SC2034

# pwquality must come before pam_unix or the hash is written unchecked
set_password_policy() {
	local opts="retry=3 minlen=${PASS_MIN_LEN} ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1"

	if grep -q "pam_pwquality.so" "$PAM_PASSWORD"; then
		sed -i -E "s|^(password.*pam_pwquality\.so).*|\1 ${opts}|" "$PAM_PASSWORD"
	else
		sed -i "0,/pam_unix\.so/s|^\(password.*pam_unix\.so.*\)$|password\trequisite\t\t\tpam_pwquality.so ${opts}\n\1|" "$PAM_PASSWORD"
	fi
}

set_lockout_policy() {
	local opts="preauth silent deny=${FAIL_LOCK_ATTEMPTS} unlock_time=${FAIL_LOCK_TIME}"

	if ! grep -q "pam_faillock.so" "$PAM_AUTH"; then
		sed -i "1i auth\trequired\t\t\tpam_faillock.so ${opts}" "$PAM_AUTH"
	fi
}

# login.defs only affects future accounts, chage covers existing ones
set_password_aging() {
	sed -i -E "s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS\t${PASS_MAX_DAYS}/" "$LOGIN_DEFS"
	sed -i -E "s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS\t${PASS_MIN_DAYS}/" "$LOGIN_DEFS"
	sed -i -E "s/^PASS_WARN_AGE.*/PASS_WARN_AGE\t${PASS_WARN_AGE}/" "$LOGIN_DEFS"

	local user uid
	while IFS=: read -r user _ uid _; do
		[ "$uid" -ge "$UID_MIN" ] && [ "$uid" -ne 65534 ] || continue
		chage -M "$PASS_MAX_DAYS" -m "$PASS_MIN_DAYS" -W "$PASS_WARN_AGE" "$user"
	done < /etc/passwd
}

is_protected() {
	local user="$1" group
	for group in "${PROTECTED_GROUPS[@]}"; do
		if id -nG "$user" 2>/dev/null | tr ' ' '\n' | grep -qx "$group"; then
			return 0
		fi
	done
	return 1
}

remove_unauthorized_users() {
	local user uid removed=()

	while IFS=: read -r user _ uid _; do
		[ "$uid" -gt "$UID_MIN" ] && [ "$uid" -ne 65534 ] || continue
		is_protected "$user" && continue
		[ "$user" = "$(logname 2>/dev/null)" ] && continue

		if userdel -r "$user" 2>/dev/null; then
			removed+=("$user")
			log "INFO" "User removed: ${user}"
		else
			log "WARN" "Could not remove user: ${user}"
		fi
	done < /etc/passwd

	REPORT_USERS_COUNT="${#removed[@]}"
	REPORT_USERS_LIST=$(IFS=', '; echo "${removed[*]}")
}

harden_identity() {
	log "INFO" "=== Identity ==="

	set_password_policy
	log "INFO" "Password policy set: min length ${PASS_MIN_LEN}, 4 character classes"

	set_lockout_policy
	log "INFO" "Account lockout set after ${FAIL_LOCK_ATTEMPTS} failed attempts"

	set_password_aging
	log "INFO" "Password aging set: max ${PASS_MAX_DAYS} days"

	remove_unauthorized_users

	passwd -l root >/dev/null 2>&1
	log "INFO" "Root password locked"
}
