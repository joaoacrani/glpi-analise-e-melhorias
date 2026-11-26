# Análise inicial

Feita **somente em leitura**, sem root. Por isso não deu para ver os logs do Apache, o crontab do `www-data`, o firewall e o banco, o que foi complementado depois, quando houve acesso privilegiado.

**Ambiente encontrado:** Debian 12, GLPI 10.0.27, Apache 2.4 (`mod_php`, prefork), PHP 8.2, MariaDB 10.11, Redis local como cache. A máquina tinha 2 vCPU, 1,9 GB de RAM e 27% de disco usado. O site respondia, o `status.php` retornava OK e o TLS era 1.3.

## Crítico e alto

| # | Achado | Por que importa | Ação |
|---|---|---|---|
| 1 | O MariaDB **respondia na rede** (porta 3306), apesar do `bind-address = 127.0.0.1` | O GLPI usa `localhost`, não há motivo para expor o banco | Achar o que sobrescreve o bind e bloquear a porta |
| 2 | **Sem firewall** (nem `ufw`, nem `iptables`, nem `nft`) | 22, 80, 443 e 3306 abertas para a rede interna | Instalar o `ufw` e liberar só o necessário |
| 3 | `config_db.php` (senha do banco) e `glpicrypt.key` (chave das senhas guardadas) com permissão **644** | Qualquer usuário local lê os segredos | Passar para `640`, dono `www-data` |
| 4 | **Sem fail2ban e sem atualizações automáticas**; SSH padrão (senha, root e X11 permitidos) | O `event.log` já tinha tentativas de login falhas | Instalar os dois e endurecer o SSH |
| 5 | **Sem backup visível** do banco, de `files/` e de `config/` | Sem a `glpicrypt.key` no backup, os dados cifrados ficam irrecuperáveis | Backup diário com retenção e teste de restauração |

## Médio

| # | Achado | Ação |
|---|---|---|
| 6 | O cron do GLPI rodava em **modo interno** (só quando alguém acessa o sistema): atrasa SLA, e-mail e coletor | Cron de sistema a cada minuto e modo CLI |
| 7 | Notificações por e-mail com falha (`SMTP connect() failed`, destinatários como `admsys@localhost`), logs parados desde abril de 2025 | Confirmar se ainda saem (depois, desativar) |
| 8 | Arquivos antigos no diretório web: o código da versão 10.0.7 (275 MB), um `.tgz` (61 MB) e o `install.php` | Mover para fora do diretório web |
| 9 | Série 10.0 legada, com o GLPI 11 já disponível | Planejar a migração com teste em cópia |
| 10 | Apache sem endurecimento: `ServerTokens OS`, assinatura ligada, sem `mod_headers` (faltavam HSTS, `X-Content-Type-Options`, `X-Frame-Options`) | Ajustar e adicionar os cabeçalhos |
| 11 | Sessões do PHP com `use_strict_mode = 0` | Ligar o modo estrito |

## Desempenho e capacidade

| # | Achado | Ação |
|---|---|---|
| 12 | Pouca memória: 77 MB livres, swap em uso, e o servidor rodava ambiente gráfico | Aumentar a RAM da VM e considerar rodar sem interface |
| 13 | `memory_limit` 128M, upload 2M e `post_max_size` 8M (anexos maiores falhariam); MariaDB sem ajuste | 256M, 50M e 60M; `innodb_buffer_pool_size` |
| 14 | Redis sem senha (aceitável enquanto só em `127.0.0.1`) | Manter local |

## Logs e erros

| # | Achado | Ação |
|---|---|---|
| 15 | `php-errors.log` com cerca de 258 avisos: chaves de array indefinidas (da própria base do GLPI) e `mkdir()` negado | Investigar a permissão de `files/` e da pasta do marketplace |
| 16 | Sem rotação de logs do GLPI (o `cron.log` já tinha 2,3 MB) | `logrotate` |
| 17 | Certificado da CA interna (RSA 2048, válido até 2028), mas o SAN tinha um IP que não era mais o da máquina | Reemitir se for acessar por IP |
| 18 | Duas sessões do mesmo usuário abertas (uma local e uma por SSH) e acessos de `sudo` sem revisão | Revisar acessos |

## Ordem sugerida

1. Fechar a 3306 e ajustar as permissões de `config/`.
2. Instalar fail2ban e atualizações automáticas e endurecer o SSH.
3. Cron de sistema do GLPI.
4. Backup diário com teste de restauração.
5. Limpar arquivos antigos, remover `install.php` e ajustar PHP e Apache.
6. Planejar o GLPI 11 e aumentar a RAM.
