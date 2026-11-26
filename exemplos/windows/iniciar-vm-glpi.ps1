# Sobe a VM do VirtualBox em segundo plano quando o Windows inicia, mesmo sem ninguem logado.
# Rode no PowerShell como Administrador, NO SERVIDOR FISICO, com a VM desligada para testar.
#   1. Descubra o UUID da VM:   & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list vms
#   2. Descubra o nome completo da conta:   whoami      (formato COMPUTADOR\usuario)
param(
    [Parameter(Mandatory)] [string]$UuidDaVm,
    [Parameter(Mandatory)] [string]$Conta,          # exatamente como o whoami mostra, por exemplo SERVIDOR\admin
    [string]$NomeDaTarefa = 'Iniciar VM GLPI'
)
$ErrorActionPreference = 'Stop'
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$acao = New-ScheduledTaskAction -Execute $vbox -Argument "startvm $UuidDaVm --type headless"
$gatilho = New-ScheduledTaskTrigger -AtStartup
$gatilho.Delay = 'PT1M'    # da tempo para a rede e os servicos do Windows subirem
$config = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
# A tarefa precisa rodar com o usuario DONO da VM (como SYSTEM o VBoxManage nao enxerga a VM)
Register-ScheduledTask -TaskName $NomeDaTarefa -Action $acao -Trigger $gatilho -Settings $config -User $Conta -Password (Read-Host 'Senha da conta do Windows') -RunLevel Highest
Write-Host "Tarefa criada. Teste com: Start-ScheduledTask -TaskName '$NomeDaTarefa'  e depois:  & '$vbox' list runningvms"
