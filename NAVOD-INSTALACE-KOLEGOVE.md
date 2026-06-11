# EasyProject MCP — automatická instalace přes Claude Code

## Pro člověka (přečti si jen tohle)

1. Měj nainstalovaný Claude Code (`claude --version` v terminálu).
2. Získej si svůj API klíč: přihlas se na https://ep.pdsoft.eu → vpravo nahoře profil → **Můj účet** → vpravo **API přístupový klíč** → **Zobrazit** → zkopíruj.
   ⚠️ Klíč je osobní — nesdílej ho, vše v EP se pak děje pod tvým jménem.
3. Zkopíruj si k sobě tento soubor (nic dalšího není potřeba — program serveru si Claude stáhne sám z GitHubu).
4. Spusť `claude` a napiš:

   > Přečti soubor NAVOD-INSTALACE-KOLEGOVE.md a nastav mi podle něj EasyProject MCP.

5. Claude se tě zeptá na API klíč a vše nastaví. Na konci restartuj Claude Code a ověř příkazem `/mcp`.

---

## Pro Claude (instrukce k provedení)

Jsi Claude Code a máš uživateli nastavit dva MCP servery pro EasyProject (https://ep.pdsoft.eu). Postupuj přesně podle kroků níže. Příkazy spouštěj sám přes Bash; uživatele se ptej jen na to, co znát nemůžeš.

### Krok 0 — Zjisti vstupy

1. Zeptej se uživatele na jeho **EasyProject API klíč** (40znakový hex řetězec z Můj účet → API přístupový klíč). Bez něj nepokračuj. Klíč nikdy nevypisuj zpět do konverzace ani ho nedávej do gitu.
2. Zjisti platformu: spusť `uname -a 2>/dev/null || ver`. WSL poznáš podle „microsoft" ve výstupu uname; čisté Windows podle toho, že uname neexistuje.
3. Obstarej binárky serveru ze složky `deployment/`:
   - **Pokud složka `deployment/` leží vedle tohoto souboru**, použij ji.
   - **Jinak stáhni repo z GitHubu** (veřejné):
     ```bash
     git clone --depth 1 https://github.com/lukas-dvoracek/EasyProject-MCP-Server.git /tmp/ep-mcp
     ```
     Binárky pak najdeš v `/tmp/ep-mcp/deployment/`. Bez gitu lze stáhnout i přímo:
     ```bash
     curl -L -o easyproject-mcp-server-linux https://github.com/lukas-dvoracek/EasyProject-MCP-Server/raw/main/deployment/easyproject-mcp-server-linux
     curl -L -o easyproject-mcp-server.exe https://github.com/lukas-dvoracek/EasyProject-MCP-Server/raw/main/deployment/easyproject-mcp-server.exe
     ```
   Obsah `deployment/`:
   - `easyproject-mcp-server-linux` (Linux/WSL build)
   - `easyproject-mcp-server.exe` (Windows build)

### Krok 1 — Registruj server „easy8" (HTTP, bez instalace)

```bash
claude mcp add --scope user --transport http easy8 https://ep.pdsoft.eu/mcp --header "X-Redmine-API-Key: <KLÍČ>"
```

Pokud už `easy8` existuje (`claude mcp list`), přeskoč.

### Krok 2 — Nainstaluj a registruj server „easyproject" (lokální binárka)

**Linux / WSL:**

```bash
mkdir -p ~/easyproject-mcp
cp <cesta-k-deployment>/easyproject-mcp-server-linux ~/easyproject-mcp/
chmod +x ~/easyproject-mcp/easyproject-mcp-server-linux
```

Vytvoř `~/easyproject-mcp/wrapper.sh` s tímto obsahem (dosaď skutečný klíč):

```bash
#!/bin/bash
export EASYPROJECT_API_KEY=<KLÍČ>
export EASYPROJECT_BASE_URL=https://ep.pdsoft.eu/
exec "$HOME/easyproject-mcp/easyproject-mcp-server-linux"
```

Pak `chmod +x ~/easyproject-mcp/wrapper.sh` a registruj:

```bash
claude mcp add --scope user easyproject -- "$HOME/easyproject-mcp/wrapper.sh"
```

**Windows (nativní):**

```powershell
mkdir C:\Tools\easyproject-mcp 2>$null
copy <cesta-k-deployment>\easyproject-mcp-server.exe C:\Tools\easyproject-mcp\
claude mcp add --scope user easyproject --env EASYPROJECT_API_KEY=<KLÍČ> --env EASYPROJECT_BASE_URL=https://ep.pdsoft.eu/ -- C:\Tools\easyproject-mcp\easyproject-mcp-server.exe
```

⚠️ Upozorni uživatele: Windows EXE je build z 2026-05-04 — neobsahuje nástroje `get_attachment`/`download_attachment`. Vše ostatní funguje.

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

- `/mcp` ukazuje „failed" → zkontroluj API klíč; u Linux binárky `chmod +x`; zkus binárku spustit ručně, zda se nehlásí chybějící knihovny.
- 401/403 z EP → špatný klíč; vygenerovat nový v Můj účet.
- Odregistrace: `claude mcp remove easy8` / `claude mcp remove easyproject`.
