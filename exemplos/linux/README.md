# Configurações de referência (Linux)

Equivalentes **genéricos** do que foi aplicado no servidor (os arquivos originais ficaram nele). Ajuste caminhos e valores ao seu ambiente.

| Arquivo | Destino | Para quê |
|---|---|---|
| `glpi-cron` | `/etc/cron.d/glpi` | Ações automáticas do GLPI a cada minuto, em modo CLI |
| `99-glpi.ini` | `/etc/php/8.4/apache2/conf.d/99-glpi.ini` | Limites de PHP para anexos e sessões |
| `fail2ban-sshd.local` | `/etc/fail2ban/jail.d/sshd.local` | Jail do SSH lendo o journal (Debian sem `auth.log`) |
| `mariadb-socket-override.conf` | `/etc/systemd/system/mariadb.socket.d/override.conf` | Impede que o socket do systemd abra a 3306 na rede |
| `journald-size.conf` | `/etc/systemd/journald.conf.d/size.conf` | Limita o tamanho e o tempo do journal |

Depois de copiar: `systemctl daemon-reload` para o override do MariaDB, e reinicie o serviço correspondente.
