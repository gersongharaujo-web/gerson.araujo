$ErrorActionPreference = 'SilentlyContinue'
Clear-Host

$pc = Read-Host "Equipamento"
if (-not (Test-Connection -ComputerName $pc -Count 1 -Quiet)) {
    Write-Host "FALHOU: $pc nao responde" -ForegroundColor Red
    Read-Host "ENTER para sair" | Out-Null
    return
}

function Status { (Get-Service -ComputerName $pc -Name Spooler).Status }

function Parar {
    Get-Service -ComputerName $pc -Name Spooler | Stop-Service -Force
    Start-Sleep 3
    if ((Status) -eq 'Stopped') { Write-Host "OK: spooler PARADO" -ForegroundColor Green }
    else { Write-Host "FALHOU: spooler nao parou" -ForegroundColor Red }
}

function Limpar {
    $pasta = "\\$pc\c$\Windows\System32\spool\PRINTERS"
    if (-not (Test-Path $pasta)) { Write-Host "FALHOU: sem acesso a fila" -ForegroundColor Red; return }
    Remove-Item "$pasta\*" -Force
    $r = @(Get-ChildItem $pasta).Count
    if ($r -eq 0) { Write-Host "OK: fila LIMPA" -ForegroundColor Green }
    else { Write-Host "FALHOU: restam $r arquivo(s)" -ForegroundColor Red }
}

function Iniciar {
    Get-Service -ComputerName $pc -Name Spooler | Start-Service
    Start-Sleep 3
    if ((Status) -eq 'Running') { Write-Host "OK: spooler INICIADO" -ForegroundColor Green }
    else { Write-Host "FALHOU: spooler nao iniciou" -ForegroundColor Red }
}

do {
    Clear-Host
    Write-Host $pc.ToUpper() -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1 - Parar"
    Write-Host "2 - Limpar"
    Write-Host "3 - Iniciar"
    Write-Host "4 - Trocar equipamento"
    Write-Host "0 - Sair"
    Write-Host ""
    $op = Read-Host "Opcao"
    Write-Host ""

    switch ($op) {
        "1" { Parar;   Read-Host "ENTER para voltar" | Out-Null }
        "2" { Limpar;  Read-Host "ENTER para voltar" | Out-Null }
        "3" { Iniciar; Read-Host "ENTER para voltar" | Out-Null }
        "4" {
            $novo = Read-Host "Equipamento"
            if (Test-Connection -ComputerName $novo -Count 1 -Quiet) { $pc = $novo }
            else { Write-Host "FALHOU: $novo nao responde" -ForegroundColor Red; Read-Host "ENTER para voltar" | Out-Null }
        }
    }
} while ($op -ne "0")
