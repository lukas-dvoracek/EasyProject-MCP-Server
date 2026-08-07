# ============================================================
#  Build + deploy Windows binárky EasyProject MCP serveru
#
#  Spouštět z Windows (PowerShell) v kořeni repa nebo odkudkoli:
#     powershell -ExecutionPolicy Bypass -File scripts\build-windows.ps1
#
#  Co dělá:
#   1) ukončí běžící easyproject-mcp-server.exe (jinak drží zámek souboru)
#   2) cargo build --release
#   3) záloha stávající deployment\ binárky do temp_bac\
#   4) kopie čerstvé binárky do deployment\easyproject-mcp-server.exe
#   5) ověří symboly (easy_sprint_id, ...) a smoke test tools/list
#
#  POZOR: po deployi je nutný restart Claude Code, MCP se načítá při startu.
#  Commit + push řeší scripts\publish-release.ps1
# ============================================================
param(
    [switch]$SkipBuild   # jen znovu nasadit už přeloženou target\release binárku
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $repo 'target\release\easyproject-mcp-server.exe'
$out  = Join-Path $repo 'deployment\easyproject-mcp-server.exe'
# Symboly, které musí být v každém čerstvém buildu (rozšiřovat s novými featurami)
$requiredSymbols = @('easy_sprint_id', 'fixed_version_id', 'download_attachment')

Write-Output "=== 1. Ukončení běžících MCP procesů ==="
$procs = Get-Process -Name 'easyproject-mcp-server' -ErrorAction SilentlyContinue
if ($procs) {
    $procs | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Output "    ukončeno: $($procs.Count) proc."
} else {
    Write-Output "    nic neběží"
}

if (-not $SkipBuild) {
    Write-Output "=== 2. cargo build --release ==="
    Push-Location $repo
    try {
        cargo build --release
        if ($LASTEXITCODE -ne 0) { throw "cargo build selhal (exit $LASTEXITCODE)" }
    } finally {
        Pop-Location
    }
} else {
    Write-Output "=== 2. cargo build PŘESKOČEN (-SkipBuild) ==="
}

if (-not (Test-Path $src)) { throw "CHYBA: chybí $src" }

Write-Output "=== 3. Záloha stávající deployment binárky ==="
$bacDir = Join-Path $repo 'temp_bac'
if (-not (Test-Path $bacDir)) { New-Item -ItemType Directory -Path $bacDir | Out-Null }
if (Test-Path $out) {
    $stamp = (Get-Item $out).LastWriteTime.ToString('yyyyMMdd-HHmmss')
    Copy-Item $out (Join-Path $bacDir "easyproject-mcp-server.exe.$stamp") -Force
    Write-Output "    záloha: temp_bac\easyproject-mcp-server.exe.$stamp"
}

Write-Output "=== 4. Kopie do deployment\ ==="
Copy-Item $src $out -Force
Get-Item $out | Select-Object Name, Length, LastWriteTime | Format-List

Write-Output "=== 5. Ověření symbolů ==="
$fail = $false
foreach ($sym in $requiredSymbols) {
    if (Select-String -Path $out -Pattern $sym -Encoding Byte -Quiet) {
        Write-Output "    OK    $sym"
    } else {
        Write-Output "    CHYBÍ $sym"
        $fail = $true
    }
}
if ($fail) { throw "CHYBA: binárka neobsahuje očekávané symboly." }

Write-Output "=== 6. Smoke test (stdio initialize + tools/list) ==="
# Dummy klíč — smoke test nevolá API, jen ověří start serveru a registraci nástrojů
$tmp = Join-Path $env:TEMP "ep-mcp-smoke.jsonl"
@(
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"1"}}}'
    '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
) | Out-File -FilePath $tmp -Encoding ascii
$env:EASYPROJECT_API_KEY  = 'smoketest'
$env:EASYPROJECT_BASE_URL = 'https://ep.pdsoft.eu/'
$reply = Get-Content $tmp | & $out
Remove-Item $tmp -Force
$names = [regex]::Matches(($reply -join ''), '"name":"[a-z_]+"') | ForEach-Object { $_.Value } | Sort-Object -Unique
Write-Output "    registrovaných nástrojů: $($names.Count)"
if ($names.Count -lt 25) { throw "CHYBA: tools/list vrátil jen $($names.Count) nástrojů." }

Write-Output ""
Write-Output "Hotovo. Windows binárka nasazena: $out"
Write-Output "Dál: restart Claude Code, pak scripts\publish-release.ps1 (commit + push)."
