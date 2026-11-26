# Auto-elevar para administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
$Host.UI.RawUI.WindowTitle = "Spooler de Impressao"
try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(60,26) } catch { }

$W = 46

function Linha([string]$txt = "", [string]$cor = "Cyan") {
    Write-Host ("  |  " + $txt.PadRight($W - 4) + "|") -ForegroundColor $cor
}
function Borda { Write-Host ("  +" + ("-" * ($W - 1)) + "+") -ForegroundColor DarkCyan }

function Cabecalho {
    Clear-Host
    Write-Host ""
    Borda
    Linha "        SPOOLER DE IMPRESSAO  -  REMOTO" White
    Borda
}

function Ok($m)    { Write-Host ""; Write-Host "   [ OK ] $m" -ForegroundColor Green }
function Falha($m) { Write-Host ""; Write-Host "   [FALHA] $m" -ForegroundColor Red }

function Pedir-Equipamento {
    while ($true) {
        Cabecalho
        Write-Host ""
        Write-Host "   Equipamento: " -NoNewline -ForegroundColor Yellow
        $nome = (Read-Host).Trim()
        if (-not $nome) { continue }
        Write-Host ""
        Write-Host "   Verificando conexao..." -ForegroundColor DarkGray
        if (Test-Connection -ComputerName $nome -Count 1 -Quiet) { return $nome }
        Falha "$nome nao responde na rede"
        Write-Host ""
        Read-Host "   ENTER para tentar de novo" | Out-Null
    }
}

function Status { (Get-Service -ComputerName $pc -Name Spooler).Status }

function Parar {
    Write-Host "   Parando spooler em $pc..." -ForegroundColor DarkGray
    Get-Service -ComputerName $pc -Name Spooler | Stop-Service -Force
    Start-Sleep 3
    if ((Status) -eq 'Stopped') { Ok "spooler PARADO" } else { Falha "spooler nao parou" }
}

function Limpar {
    Write-Host "   Limpando fila em $pc..." -ForegroundColor DarkGray
    $pasta = "\\$pc\c$\Windows\System32\spool\PRINTERS"
    if (-not (Test-Path $pasta)) { Falha "sem acesso a fila"; return }
    Remove-Item "$pasta\*" -Force
    $r = @(Get-ChildItem $pasta).Count
    if ($r -eq 0) { Ok "fila LIMPA" } else { Falha "restam $r arquivo(s) na fila" }
}

function Iniciar {
    Write-Host "   Iniciando spooler em $pc..." -ForegroundColor DarkGray
    Get-Service -ComputerName $pc -Name Spooler | Start-Service
    Start-Sleep 3
    if ((Status) -eq 'Running') { Ok "spooler INICIADO" } else { Falha "spooler nao iniciou" }
}

$pc = Pedir-Equipamento

do {
    Cabecalho
    Linha ("Equipamento:  " + $pc.ToUpper()) Yellow
    Borda
    Linha
    Linha "  [1]  Parar spooler" Green
    Linha "  [2]  Limpar fila de impressao" Green
    Linha "  [3]  Iniciar spooler" Green
    Linha "  [4]  Trocar equipamento" Cyan
    Linha "  [0]  Sair" DarkGray
    Linha
    Borda
    Write-Host ""
    Write-Host "   Opcao: " -NoNewline -ForegroundColor Yellow
    $op = Read-Host
    Write-Host ""

    switch ($op) {
        "1" { Parar;   Write-Host ""; Read-Host "   ENTER para voltar" | Out-Null }
        "2" { Limpar;  Write-Host ""; Read-Host "   ENTER para voltar" | Out-Null }
        "3" { Iniciar; Write-Host ""; Read-Host "   ENTER para voltar" | Out-Null }
        "4" { $pc = Pedir-Equipamento }
    }
} while ($op -ne "0")
