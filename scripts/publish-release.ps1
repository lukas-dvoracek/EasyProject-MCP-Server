# ============================================================
#  Publish release: build obou binárek → stamp návodů → commit → push
#
#  Spouštět z Windows (PowerShell):
#     powershell -ExecutionPolicy Bypass -File scripts\publish-release.ps1
#
#  Proč: kolegové instalují podle NAVOD-INSTALACE-KOLEGOVE.md, který tahá
#  binárky přes curl z raw.githubusercontent (main). Bez pushnuté binárky
#  dostanou starý build, i když je zdroják aktuální.
#
#  Přepínače:
#     -SkipWindows      nepřekládat Windows exe (použije se, co je v deployment\)
#     -SkipLinux        nepřekládat Linux ELF (přeskočí WSL)
#     -NoPush           jen commit lokálně
#     -NoCommit         jen buildy a stamp návodů, git nechat na uživateli
#     -Distro <name>    WSL distro (default Ubuntu)
#     -ToolCount <n>    počet nástrojů zapsaný do návodů (default 30)
# ============================================================
param(
    [switch]$SkipWindows,
    [switch]$SkipLinux,
    [switch]$NoPush,
    [switch]$NoCommit,
    [string]$Distro = 'Ubuntu',
    [int]$ToolCount = 30
)

$ErrorActionPreference = 'Stop'
$repo    = Split-Path -Parent $PSScriptRoot
$winBin  = Join-Path $repo 'deployment\easyproject-mcp-server.exe'
$linBin  = Join-Path $repo 'deployment\easyproject-mcp-server-linux'

function Write-Utf8NoBom([string]$path, [string]$text) {
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $text, $enc)
}

# ---------- 1. Windows build ----------
if ($SkipWindows) {
    Write-Output "### Windows build PŘESKOČEN (-SkipWindows)"
} else {
    Write-Output "### Windows build"
    & (Join-Path $PSScriptRoot 'build-windows.ps1')
    if ($LASTEXITCODE -ne 0) { throw "build-windows.ps1 selhal" }
}

# ---------- 2. Linux build ve WSL ----------
if ($SkipLinux) {
    Write-Output "### Linux build PŘESKOČEN (-SkipLinux)"
} else {
    Write-Output "### Linux build ve WSL ($Distro)"
    # cesta k repu z pohledu WSL: D:\Projekty\... -> /mnt/d/Projekty/...
    $drive   = $repo.Substring(0,1).ToLower()
    $wslRepo = '/mnt/' + $drive + ($repo.Substring(2) -replace '\\','/')
    wsl.exe -d $Distro bash "$wslRepo/scripts/build-linux.sh"
    if ($LASTEXITCODE -ne 0) { throw "build-linux.sh selhal (exit $LASTEXITCODE)" }
}

# ---------- 3. Stamp návodů ----------
Write-Output "### Stamp datumů buildů do návodů"
if (-not (Test-Path $winBin)) { throw "CHYBÍ $winBin" }
if (-not (Test-Path $linBin)) { throw "CHYBÍ $linBin" }
$winDate = (Get-Item $winBin).LastWriteTime.ToString('yyyy-MM-dd')
$linDate = (Get-Item $linBin).LastWriteTime.ToString('yyyy-MM-dd')
Write-Output "    win exe:   $winDate"
Write-Output "    linux ELF: $linDate"

$stamps = @(
    @{
        File = Join-Path $repo 'NAVOD-INSTALACE-KOLEGOVE.md'
        Pattern = '(?m)^Pozn\.: Windows EXE [^
]*'
        Line = "Pozn.: Windows EXE (build $winDate, MSVC) i Linux binárka (build $linDate) obsahují plnou sadu $ToolCount nástrojů včetně ``get_attachment``/``download_attachment`` a filtrů ``fixed_version_id`` (milník) a ``easy_sprint_id`` (agile sprint)."
    },
    @{
        File = Join-Path $repo 'NAVOD-MCP-EP-WIN.md'
        Pattern = '(?m)^Pozn\.: EXE [^
]*'
        Line = "Pozn.: EXE (build $winDate, MSVC) obsahuje plnou sadu $ToolCount nástrojů včetně ``get_attachment``/``download_attachment`` a filtrů ``fixed_version_id`` (milník) a ``easy_sprint_id`` (agile sprint)."
    }
)
foreach ($s in $stamps) {
    if (-not (Test-Path $s.File)) { Write-Output "    (chybí $($s.File), přeskočeno)"; continue }
    $txt = [System.IO.File]::ReadAllText($s.File)
    if ($txt -notmatch $s.Pattern) { Write-Output "    VAROVÁNÍ: v $(Split-Path $s.File -Leaf) nenalezen řádek 'Pozn.:' — zkontroluj ručně"; continue }
    # '$' v replacement stringu je pro regex speciální ($1, $&) — zdvojit
    $repl = $s.Line -replace '\$', '$$$$'
    $new = [regex]::Replace($txt, $s.Pattern, $repl)
    if ($new -ne $txt) {
        Write-Utf8NoBom $s.File $new
        Write-Output "    aktualizováno: $(Split-Path $s.File -Leaf)"
    } else {
        Write-Output "    bez změny: $(Split-Path $s.File -Leaf)"
    }
}

# ---------- 4. Commit + push ----------
if ($NoCommit) {
    Write-Output "### Commit PŘESKOČEN (-NoCommit)"
    Write-Output "Hotovo (buildy + stamp). Git si commitni sám."
    exit 0
}

Write-Output "### Git commit"
Push-Location $repo
try {
    git add -f -- deployment/easyproject-mcp-server.exe deployment/easyproject-mcp-server-linux
    git add -- NAVOD-INSTALACE-KOLEGOVE.md NAVOD-MCP-EP-WIN.md TEAM-CONVENTIONS.md scripts/build-linux.sh scripts/build-windows.ps1 scripts/publish-release.ps1
    $staged = git diff --cached --name-only
    if (-not $staged) {
        Write-Output "    nic ke commitu"
    } else {
        Write-Output "    staged: $($staged -join ', ')"
        $msg = "chore(deploy): binárky win+linux rebuild ($winDate / $linDate)"
        git commit -m $msg
        if ($LASTEXITCODE -ne 0) { throw "git commit selhal" }
    }

    if ($NoPush) {
        Write-Output "### Push PŘESKOČEN (-NoPush)"
    } else {
        Write-Output "### Push origin main"
        git push origin HEAD
        if ($LASTEXITCODE -ne 0) { throw "git push selhal" }
    }
} finally {
    Pop-Location
}

Write-Output ""
Write-Output "Hotovo. Kolegové dostanou aktuální binárky přes curl z main."
