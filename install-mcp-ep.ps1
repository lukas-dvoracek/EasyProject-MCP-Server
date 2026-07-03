# install-mcp-ep.ps1 — instalace EasyProject MCP serveru (easyproject + easy8) do Claude Desktop / Cowork
# Spusteni:  powershell -ExecutionPolicy Bypass -File .\install-mcp-ep.ps1
# Skript se zepta na API klic, obstara binarku, pripadne Node.js, a zapise konfiguraci.

$ErrorActionPreference = 'Stop'

$targetDir  = 'C:\Tools\easyproject-mcp'
$exeName    = 'easyproject-mcp-server.exe'
$exeUrl     = 'https://github.com/lukas-dvoracek/EasyProject-MCP-Server/raw/main/deployment/easyproject-mcp-server.exe'
$configDir  = Join-Path $env:APPDATA 'Claude'
$configPath = Join-Path $configDir 'claude_desktop_config.json'

Write-Host '=== Instalace EasyProject MCP pro Claude Desktop / Cowork ===' -ForegroundColor Cyan

# 0) Kontrola Claude Desktop
if (-not (Test-Path $configDir)) {
    Write-Host "Slozka $configDir neexistuje - Claude Desktop zrejme neni nainstalovany, nebo jeste nebyl ani jednou spusten." -ForegroundColor Yellow
    $go = Read-Host 'Pokracovat presto? (A/N)'
    if ($go -notmatch '^[Aa]') { Write-Host 'Konec.'; exit 1 }
    New-Item -ItemType Directory -Force $configDir | Out-Null
}

# 1) API klic
$apiKey = (Read-Host 'Vloz svuj EasyProject API klic (ep.pdsoft.eu -> Muj ucet -> API pristupovy klic)').Trim()
if (-not $apiKey) { Write-Host 'Bez klice nelze pokracovat.' -ForegroundColor Red; exit 1 }
if ($apiKey -notmatch '^[0-9a-fA-F]{40}$') {
    Write-Host 'Pozor: klic nevypada jako 40znakovy hex retezec. Pokracuji, ale zkontroluj ho.' -ForegroundColor Yellow
}

# 2) Binarka easyproject-mcp-server.exe
New-Item -ItemType Directory -Force $targetDir | Out-Null
$exePath  = Join-Path $targetDir $exeName
$localExe = Join-Path $PSScriptRoot "deployment\$exeName"
if (Test-Path $exePath) {
    Write-Host "EXE uz existuje: $exePath - ponechavam."
} elseif (Test-Path $localExe) {
    Copy-Item $localExe $exePath
    Write-Host "EXE zkopirovan z lokalni slozky deployment."
} else {
    Write-Host 'Stahuji EXE z GitHubu...'
    Invoke-WebRequest -Uri $exeUrl -OutFile $exePath
    Write-Host "Stazeno: $exePath"
}

# 3) Node.js (potreba jen pro server easy8)
$hasNode = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
$installEasy8 = $true
if (-not $hasNode) {
    $ans = Read-Host 'Node.js nenalezen - je potreba pro server easy8. Nainstalovat pres winget? (A/N)'
    if ($ans -match '^[Aa]') {
        winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        Write-Host 'Node.js nainstalovan. Pokud by easy8 po restartu Claude Desktop nefungoval, restartuj cely pocitac (kvuli PATH).' -ForegroundColor Yellow
    } else {
        $installEasy8 = $false
        Write-Host 'Preskakuji easy8 - nastavi se jen server easyproject. Az doinstalujes Node.js, spust tento skript znovu.' -ForegroundColor Yellow
    }
}

# 4) Zapis konfigurace (s merge a zalohou existujiciho souboru)
if (Test-Path $configPath) {
    $backup = "$configPath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item $configPath $backup
    Write-Host "Zaloha stavajiciho configu: $backup"
    $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
} else {
    $cfg = [PSCustomObject]@{}
}
if (-not ($cfg.PSObject.Properties.Name -contains 'mcpServers') -or $null -eq $cfg.mcpServers) {
    $cfg | Add-Member -MemberType NoteProperty -Name mcpServers -Value ([PSCustomObject]@{}) -Force
}

$easyproject = [PSCustomObject]@{
    command = $exePath
    env     = [PSCustomObject]@{
        EASYPROJECT_API_KEY  = $apiKey
        EASYPROJECT_BASE_URL = 'https://ep.pdsoft.eu/'
    }
}
$cfg.mcpServers | Add-Member -MemberType NoteProperty -Name easyproject -Value $easyproject -Force

if ($installEasy8) {
    $easy8 = [PSCustomObject]@{
        command = 'cmd'
        args    = @('/c', 'npx', '-y', 'mcp-remote', 'https://ep.pdsoft.eu/mcp', '--header', "X-Redmine-API-Key:$apiKey")
    }
    $cfg.mcpServers | Add-Member -MemberType NoteProperty -Name easy8 -Value $easy8 -Force
}

$json = $cfg | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($configPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Config zapsan: $configPath" -ForegroundColor Green

# 5) Zaver
Write-Host ''
Write-Host '=== HOTOVO ===' -ForegroundColor Green
Write-Host '1) UPLNE ukonci Claude Desktop: prava mys na ikonu u hodin (systray) -> Quit. Zavrit okno NESTACI.'
Write-Host '2) Spust Claude Desktop znovu.'
if ($installEasy8) {
    Write-Host '3) V chatu klikni na ikonu nastroju (posuvniky pod textovym polem) - maji byt videt servery easyproject a easy8.'
} else {
    Write-Host '3) V chatu klikni na ikonu nastroju (posuvniky pod textovym polem) - ma byt videt server easyproject.'
}
Write-Host '4) Test: napis "Vypis moje otevrene ukoly v EasyProjectu."'
