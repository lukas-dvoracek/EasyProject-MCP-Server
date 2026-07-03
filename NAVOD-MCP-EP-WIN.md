# EasyProject MCP — instalace na Windows přes Claude Code

Návod pro připojení **obou** EasyProject MCP serverů (`easy8` + `easyproject`) na Windows.

## Pro člověka (přečti si jen tohle)

1. Měj nainstalovaný Claude Code — ověř v terminálu: `claude --version`.
2. Získej si svůj API klíč: přihlas se na https://ep.pdsoft.eu → vpravo nahoře profil → **Můj účet** → vpravo **API přístupový klíč** → **Zobrazit** → zkopíruj.
   ⚠️ Klíč je osobní — nesdílej ho, vše v EP se pak děje pod tvým jménem.
3. Zkopíruj si k sobě tento soubor (nic dalšího není potřeba — program serveru si Claude stáhne sám z GitHubu).
4. Spusť `claude` a napiš:

   > Přečti soubor NAVOD-MCP-EP-WIN.md a nastav mi podle něj EasyProject MCP.

5. Claude se tě zeptá na API klíč a vše nastaví. Na konci restartuj Claude Code a ověř příkazem `/mcp`.

---

## Pro Claude (instrukce k provedení)

Jsi Claude Code na **Windows** a máš uživateli nastavit dva MCP servery pro EasyProject (https://ep.pdsoft.eu). Postupuj přesně podle kroků níže. Příkazy spouštěj sám; uživatele se ptej jen na to, co znát nemůžeš.

### Krok 0 — Zjisti vstupy

1. Zeptej se uživatele na jeho **EasyProject API klíč** (40znakový hex řetězec z Můj účet → API přístupový klíč). Bez něj nepokračuj. Klíč nikdy nevypisuj zpět do konverzace ani ho nedávej do gitu.
2. Zkontroluj existující registrace: `claude mcp list`. Pokud už `easy8` nebo `easyproject` existují a fungují, příslušný krok přeskoč.
3. Obstarej Windows binárku serveru:
   - **Pokud složka `deployment\` leží vedle tohoto souboru**, použij `deployment\easyproject-mcp-server.exe`.
   - **Jinak stáhni z GitHubu** (veřejné repo):
     ```powershell
     New-Item -ItemType Directory -Force C:\Tools\easyproject-mcp
     Invoke-WebRequest -Uri "https://github.com/lukas-dvoracek/EasyProject-MCP-Server/raw/main/deployment/easyproject-mcp-server.exe" -OutFile "C:\Tools\easyproject-mcp\easyproject-mcp-server.exe"
     ```

### Krok 1 — Registruj server „easy8" (HTTP, bez instalace)

```powershell
claude mcp add --scope user --transport http easy8 https://ep.pdsoft.eu/mcp --header "X-Redmine-API-Key: <KLÍČ>"
```

### Krok 2 — Nainstaluj a registruj server „easyproject" (lokální EXE)

Pokud jsi EXE stahoval v kroku 0, už leží v `C:\Tools\easyproject-mcp\`. Pokud jsi ho bral z lokální `deployment\`, zkopíruj ho tam:

```powershell
New-Item -ItemType Directory -Force C:\Tools\easyproject-mcp
Copy-Item <cesta-k-deployment>\easyproject-mcp-server.exe C:\Tools\easyproject-mcp\
```

Registrace (dosaď skutečný klíč):

```powershell
claude mcp add --scope user easyproject --env EASYPROJECT_API_KEY=<KLÍČ> --env EASYPROJECT_BASE_URL=https://ep.pdsoft.eu/ -- C:\Tools\easyproject-mcp\easyproject-mcp-server.exe
```

Pozn.: EXE (build 2026-06-11, MSVC) obsahuje plnou sadu 30 nástrojů včetně `get_attachment`/`download_attachment`.

### Krok 3 — Ověř a předej uživateli

1. Spusť `claude mcp list` a zkontroluj, že `easy8` i `easyproject` jsou zaregistrované.
2. Řekni uživateli, ať **restartuje Claude Code** (ukončit a spustit znovu) — MCP servery se načítají při startu.
3. Po restartu ať ověří příkazem `/mcp` — oba servery mají být „connected". Funkční test: „Vypiš moje otevřené úkoly v EasyProjectu."

### Krok 4 — Předej pravidla používání

Na závěr uživateli stručně shrň:

- **Úkoly (výpis, detail, vytvoření, změna statusu/přiřazení, komentáře)** → nástroje `easy8_issues_*`. Důvod: starý server `update_issue` umí tiše zahodit změnu statusu/assignee.
- **Logování času, time entries, milníky, uživatelé, přílohy, reporty, dashboard** → nástroje `mcp__easyproject__*` (easy8 tohle neumí).
- Aktivity pro `log_time`: **Programování = 129**, **Schůzka = 130** (povinný parametr).
- `watcher_user_ids` u create/update nepoužívat (bug — text skončí v popisu úkolu); watchery přidávat ručně v EP webu.
- Komentáře a time entries psát krátké (1–3 věty, srozumitelné i neprogramátorům), bez interních cest a detailů.
- Další konvence: `TEAM-CONVENTIONS.md` v repu EasyProject-MCP-Server.

### Řešení problémů

- `/mcp` ukazuje „failed" → zkontroluj API klíč; zkus EXE spustit ručně v terminálu, zda nehlásí chybu.
- 401/403 z EP → špatný klíč; vygenerovat nový v Můj účet.
- Firemní síť/VPN blokuje GitHub → binárku lze zkopírovat z `D:\Projekty\Claude\EasyProject-MCP-Server\deployment\` (Lukáš Dvořáček) na USB/sdílený disk.
- Odregistrace: `claude mcp remove easy8` / `claude mcp remove easyproject`.
