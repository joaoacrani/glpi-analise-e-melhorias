# Migração: do GLPI 10.0.27 ao 12.0.2

## Preparação

1. **Aumentar a RAM da VM** (de 2 GB para cerca de 6 GB) e **tirar um snapshot**, com a VM desligada.
2. **Pré-teste** (não altera a produção):
   - disco livre e tamanho do banco (229 MB);
   - integridade do esquema e ausência de tabelas MyISAM;
   - plug-ins cadastrados (7, nenhum ativo e nenhum no disco);
   - download das versões novas e **checagem de integridade**;
   - requisitos da versão nova numa pasta temporária, apagada depois.
3. **Script de atualização**: a cada salto faz o dump do banco, ativa o modo de manutenção, instala o código novo **em uma pasta nova** (a antiga fica guardada), reaplica `config/` e `files/` (que ficam fora do código), roda a atualização do banco e valida o resultado. Se algum passo falhar, restaura o código e o banco sozinho. Aceita só versões explícitas, sem curinga.

## Os saltos

| Salto | Resultado |
|---|---|
| 10.0.27 → 10.0.28 → **11.0.13** | Migrações 11.0.0 até 11.0.13 concluídas, HTTPS 200, `status.php` com `glpi: OK` e `db: OK`. Único aviso: `mkdir()` negado na pasta do marketplace, inofensivo |
| 11.0.13 → **12.0.2** (primeira tentativa) | **Bloqueado no pré-teste**: o GLPI 12 exige **PHP 8.3 ou mais** e o servidor tinha o 8.2 do Debian 12. O erro era uma sintaxe (`DEFAULT_MODE`) que só existe a partir do 8.3 |

## Como o bloqueio do PHP foi resolvido

| Opção | O que envolve | Risco |
|---|---|---|
| A. Ficar no GLPI 11.0.13 | Nada a fazer | Baixo (versão mantida) |
| B. PHP 8.3 por repositório de terceiros | Adicionar um repositório externo, instalar o PHP e migrar as configurações | Médio: dependência externa em um servidor com dados sensíveis |
| **C. Atualizar o Debian 12 para o 13** | PHP 8.4 e MariaDB mais novo, atualizando o sistema inteiro | Mais alto, mas é a solução de longo prazo |

Foi escolhida a **C**, por ser uma base só com o GLPI na máquina, com snapshot e janela de manutenção.

## O upgrade do Debian 13

Um script, executado em segundo plano com `systemd-run` (não morre se a sessão SSH cair), com log:

1. Confere que o sistema é o Debian 12, o espaço (mais de 8 GB) e o espelho.
2. Backup do dump, de `/etc` e da lista de pacotes.
3. Para o Apache e atualiza o Debian 12 ao último ponto.
4. Troca os repositórios para `trixie` e faz o upgrade mínimo e depois o completo, mantendo as configurações existentes (`--force-confold`).
5. Instala o **PHP 8.4** com as extensões do GLPI, copia o `.ini` do GLPI e valida o Apache.
6. Reinicia os serviços, testa o HTTPS e reinicia a máquina.

Duração: cerca de 40 minutos, com o GLPI fora do ar. O MariaDB passou do 10.11 para o **11.8.6**, migrado no lugar (sem volta, então o snapshot era o rollback real).

**Conferência depois do reinício:** Debian 13.7, PHP 8.4.28 com Redis, APCu, OPcache e as demais extensões, Apache 2.4 com os módulos, nenhuma unidade com falha, HTTPS 200, `status.php` OK, 3306 só em `127.0.0.1`, cron rodando a cada minuto e disco em 22%.

Sobre os sete erros `Cannot find the "redis" extension` do log: aconteceram **durante** o upgrade, antes de o PHP 8.4 e o `php8.4-redis` serem instalados, e não se repetiram.

## GLPI 12.0.2

- O pré-teste precisou de ajuste: os comandos do console perderam o prefixo `glpi:` no GLPI 12. O script passou a descobrir o nome válido em cada versão.
- O pré-teste passou: requisitos obrigatórios e sugeridos OK, esquema íntegro, sem MyISAM, pacote de 110 MB íntegro.
- A migração aplicou as migrações 12.0.0, 12.0.1 e 12.0.2, com esquema íntegro antes e depois.
- Resultado: HTTPS 200, `status.php` com `glpi: OK` e `db: OK`, **51 tarefas automáticas** (eram 41) sem nenhuma em execução, bloqueada ou com erro.
- As tarefas novas do GLPI 12 vieram em modo interno e foram passadas para **CLI**.
- O upgrade avisou que não há método de autenticação configurado para o inventário, o que só importa se forem usados agentes de inventário.

## Rollback

Cada salto deixou o código anterior em uma pasta ao lado e o dump do banco. O código do 11.0.13 e o dump anterior ao 12 ficaram guardados até a validação no navegador (login, lista de chamados, um chamado antigo com anexo e a criação de um chamado de teste).
