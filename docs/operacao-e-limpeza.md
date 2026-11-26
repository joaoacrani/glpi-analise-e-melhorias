# Operação e limpeza

## Varredura e limpeza

A varredura começou em leitura. O achado mais importante foi o **relógio sem sincronização**: o upgrade para o Debian 13 removeu o `systemd-timesyncd`, e o `timedatectl` mostrava `System clock synchronized: no`, o que afeta certificados, SLA do GLPI, logs e fail2ban.

| O que | Resultado |
|---|---|
| Relógio | `systemd-timesyncd` reinstalado, sincronizado (NTP) |
| Disco usado | 11 GB → **7,6 GB** (17%) |
| `/var/log` | 1.060 MB → **60 MB** |
| Diretório web do GLPI | 1.458 MB → **512 MB** |
| `/var/backups` | 846 MB → 668 MB, organizados em pastas por data |
| Journal do systemd | de 1,1 GB para um limite de **200 MB e 1 mês**, de forma permanente |
| Pacotes | kernel antigo removido e restos de configuração de cerca de 30 pacotes (PHP 8.2 e outros) |
| Código antigo do GLPI | versões 10.0.x removidas (cerca de 800 MB), e os pacotes `.tgz` e dumps intermediários |
| Fila de notificações | 7.410 mensagens paradas apagadas e logs de e-mail de 2025 removidos |
| Serviços de desktop | `cups`, `cups-browsed`, `avahi`, `bluetooth` e `ModemManager` desativados (reversível) |
| Caches do usuário | de 261 MB para 1 MB |

O que **de propósito não foi mexido**: o código do 11.0.13 e o dump anterior ao 12 (rollback, até validar), o ambiente gráfico (removê-lo derrubaria a interface da VM), o `exim4` local e os dados do usuário.

Os backups ficaram em uma pasta `glpi-archive/`, em subpastas por data (antes da versão 10.0.28, endurecimento, upgrade do Debian, GLPI 12 e plug-ins). O backup diário continua à parte.

## VM que não subia sozinha

O VirtualBox só rodava enquanto havia sessão de usuário aberta no Windows. A solução está no **servidor físico**: uma tarefa do Agendador de Tarefas na inicialização, com atraso de 1 minuto, que roda `VBoxManage startvm <UUID> --type headless` (veja [`exemplos/windows/iniciar-vm-glpi.ps1`](../exemplos/windows/iniciar-vm-glpi.ps1)).

- Usa o **UUID** da VM (`VBoxManage list vms`), que não muda se a VM for renomeada.
- Precisa rodar com o **usuário dono da VM**: como SYSTEM o `VBoxManage` não enxerga a VM.
- O erro `0x800706fc` (falha de relação de confiança) apareceu porque o nome da conta foi resolvido contra um domínio. A correção foi usar o nome completo que o `whoami` mostra (`COMPUTADOR\usuario`).
- Boas práticas: não configurar login automático do Windows só para isso, conferir na BIOS a opção de ligar sozinho quando a energia voltar, e desligar a VM de forma limpa (`poweroff` ou `acpipowerbutton`) antes de reiniciar o servidor físico.

Teste definitivo: reiniciar o Windows **sem fazer login** e ver o GLPI responder de outro computador em cerca de 3 minutos.

## Remoção dos plug-ins

O aviso laranja "Você tem 6 plug-ins para atualizar" vinha do **banco**: havia 7 plug-ins cadastrados (mreporting, pdf, financialreports, moreticket, oauthimap, behaviors e consumables), nenhum ativo e nenhum no disco.

O script, nesta ordem: faz o **backup completo do banco** (e aborta se o dump falhar), lista os plug-ins e as tabelas `glpi_plugin_*` com a contagem de linhas, apaga as tabelas e os registros relacionados (configurações, permissões, tarefas, preferências e buscas salvas), limpa o cache e confere o esquema, o HTTPS e o log de erros.

Resultado: 7 plug-ins e 8 tabelas removidos. Só duas tabelas tinham 1 linha cada, com configurações padrão. Restam 0 plug-ins, o esquema íntegro e as 51 tarefas automáticas normais. Um erro `Plugin->clean()` do marketplace no log é de uma tentativa de limpeza pela interface, **antes** do script, e não se repetiu.

## Fechamento do acesso privilegiado

Cada regra do `sudo` substituía a anterior, então no fim só existia a regra do último script. Ela foi removida, junto com os scripts em `/root`. Conferência: `sudo -l` deve mostrar só o `sudo` comum, que pede senha.
