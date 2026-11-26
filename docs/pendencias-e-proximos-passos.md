# Pendências e próximos passos

## Pendências

- [ ] Validar o GLPI 12 no navegador: login, lista de chamados, um chamado antigo com anexo e um chamado de teste.
- [ ] Apagar os snapshots do VirtualBox e o código e o dump de rollback do 11.0.13 depois de alguns dias estáveis.
- [ ] **Copiar o backup diário para fora do servidor** (hoje ele fica na própria VM).
- [ ] Remover o ambiente gráfico (GNOME e Evolution), se a VM só for administrada por SSH (libera cerca de 500 MB de RAM e disco).
- [ ] Migrar o SSH para autenticação por chave e desativar o login por senha.
- [ ] Trocar a senha de root se ela for usada em outro lugar (foi digitada para o `su -`).
- [ ] Avaliar o método de autenticação do inventário, se forem usados agentes.

## Opções avaliadas (ainda não implementadas)

### Acessar o GLPI de fora da empresa

| Opção | Como é | Observação |
|---|---|---|
| **VPN** (WireGuard ou Tailscale) | Conectar à rede da empresa e usar o endereço interno | **Recomendada.** O GLPI continua invisível na internet. O Tailscale dispensa abrir porta |
| Cloudflare Tunnel com Access | A VM faz uma conexão de saída e o Access pede login e MFA antes da página | Boa para mais gente sem VPN. Exige domínio público. O plano gratuito atende até 50 usuários |
| Proxy reverso com porta aberta | Domínio, certificado, 2FA, fail2ban e restrição por IP | Dá mais trabalho e tem o maior risco |

Em qualquer caso: ativar o **2FA** do GLPI para os perfis técnicos e administradores, e manter o sistema atualizado.

### Backup semanal na nuvem (OneDrive ou SharePoint)

- **rclone na VM** (recomendado): envia o backup mais recente uma vez por semana, mantém as últimas 8 semanas e usa `rclone crypt` ou `gpg` para criptografar antes de enviar. A autorização é feita uma vez com `rclone authorize` em um computador com navegador. Pode exigir aprovação do administrador do Microsoft 365.
- **Cliente do OneDrive no servidor Windows**: a VM copia o backup para uma pasta sincronizada. É mais simples de autorizar, mas depende de o servidor estar logado e do cliente aberto.
- Valem para as duas: criptografar (o backup tem o banco inteiro), incluir o dump, `config/` e `files/`, **testar a restauração** ao menos uma vez e registrar falhas em log.

### Abrir chamados automaticamente

| Mecanismo | Para quê |
|---|---|
| **Chamados recorrentes** | Rotinas fixas (revisar backup, renovar certificado). Usam a automação de chamados recorrentes, que já roda pelo cron |
| **Coletor de e-mail** (Receptores) | Abrir chamado por e-mail. É independente das notificações desativadas, porque só recebe. Com Microsoft 365, exige OAuth |
| **Regras de negócio** | Definir categoria, prioridade, técnico e grupo a partir do título, do solicitante ou da origem |
| **API REST, Formulários do GLPI 12 e agente de inventário** | Integrar monitoramento, scripts e formulários |
