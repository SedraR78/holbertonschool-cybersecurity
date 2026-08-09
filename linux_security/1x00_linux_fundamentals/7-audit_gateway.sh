#!/bin/bash
printf '#!/bin/bash\ncat /var/www/html/secret_config.php\n' > /usr/local/bin/audit-read-secret && chown root:root /usr/local/bin/audit-read-secret && chmod 755 /usr/local/bin/audit-read-secret && echo "$1 ALL=(root) NOPASSWD: /usr/local/bin/audit-read-secret" > /etc/sudoers.d/audit-gateway && chmod 440 /etc/sudoers.d/audit-gateway
