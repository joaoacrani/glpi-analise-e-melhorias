# Endurecimento

Aplicado por **um script único**, executado como root, com backup antes de qualquer alteração (dump do banco, `config/` e as configurações de Apache, PHP, MariaDB e SSH, em uma pasta com data).

## O que o script fez

| Etapa | Alteração |
|---|---|
| MariaDB | `bind-address = 127.0.0.1`, reinício e conferência de que a 3306 saiu da rede; `innodb_buffer_pool_size = 256M` |
| Permissões | `config_db.php` e `glpicrypt.key` em `640` |
| Firewall | `ufw` liberando só 22, 80 e 443 (o SSH fica aberto para a sessão não cair) |
| Proteção | instalação e ativação do **fail2ban** e do **unattended-upgrades** |
| SSH | X11 desligado, login de root desligado, limite de tentativas. **O login por senha foi mantido** para não trancar o acesso |
| PHP | `memory_limit` 256M, upload 50M, `post_max_size` 60M, `session.use_strict_mode = 1` |
| Apache | `ServerTokens Prod`, assinatura desligada, cabeçalhos HSTS, `X-Content-Type-Options`, `X-Frame-Options` e `Referrer-Policy`, validado com `apache2ctl -t` antes do reinício |
| Cron do GLPI | `/etc/cron.d/glpi`, a cada minuto |
| Logs | `logrotate` para os logs do GLPI |
| Limpeza | arquivos antigos movidos (não apagados) para uma pasta de backup |
| Backup diário | 02:30, retenção de 14 dias |
| Verificação final | HTTPS, `status.php` e estado dos serviços |

## O que falhou e como foi corrigido

| Problema | Causa | Correção |
|---|---|---|
| A porta 3306 **continuou exposta** | O `mariadb.socket` do systemd abre a porta em todas as interfaces e ignora o `bind-address` | Sobrescrever o socket para escutar só no socket Unix e em `127.0.0.1` |
| O **fail2ban não iniciava** | O Debian 12 não tem `/var/log/auth.log` | `backend = systemd` no jail do SSH |

Depois da correção: a 3306 só escuta em `127.0.0.1` (testado conectando pelo IP da LAN), o fail2ban monitora o SSH pelo journal, e os acessos ao GLPI vinham de poucos IPs da rede interna, sem nada suspeito.

## E-mail e ações automáticas

O envio de notificações passou para outra ferramenta, então o GLPI deixou de mandar e-mail. Um script com dump prévio do banco:

- confirmou que `notifications_mailing` e `use_notifications` já estavam em 0;
- desativou as tarefas `queuednotification*` (havia **7.410 mensagens paradas** na fila, que nunca seriam enviadas);
- desativou os alarmes que só gerariam e-mail (contrato, certificado, insumo e outros), de forma reversível;
- desativou `mailgate` e `mailgateerror` porque **não havia coletor de e-mail cadastrado**;
- passou as **41 tarefas** para o modo **CLI** (30 eram internas e 11 externas). O `cron.log` passou a mostrar execuções "Externo" a cada minuto.

## Pontos que ficaram de fora de propósito

- O SMTP não foi corrigido, porque as notificações foram desativadas.
- O certificado não foi reemitido.
- O login por senha no SSH continua permitido (o ideal é migrar para chave).
- O Redis continua sem senha, porque só escuta localmente.
