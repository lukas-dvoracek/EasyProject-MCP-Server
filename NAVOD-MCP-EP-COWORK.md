# EasyProject MCP — napojení v Claude Cowork / Claude Desktop (Windows)

Návod pro připojení **obou** EasyProject MCP serverů (`easy8` + `easyproject`) do **Claude Desktop** (a tím i Cowork) na Windows.

> ⚠️ **Důležité:** Instalaci NEPROVÁDÍ Cowork. Cowork běží v izolovaném sandboxu a pracuje jen ve složce, kterou mu dáš — **nemá zápis do `%APPDATA%\Claude\`**, takže konfiguraci MCP fyzicky nastavit nemůže (stáhne soubory jen k sobě do sandboxu a config se nezmění). Instalace se dělá jednorázovým skriptem, který spustíš sám — trvá ~2 minuty.

## Předpoklady

- **Claude Desktop** nainstalovaný a přihlášený (https://claude.ai/download), placený plán (Pro/Max/Team/Enterprise)
- Windows 10/11, PowerShell (v systému vždy)
- Internet na GitHub (stažení binárky) — případně binárka z USB/sdíleného disku, viz Řešení problémů

## Instalace (2 minuty)

1. Získej si svůj API klíč: přihlas se na https://ep.pdsoft.eu → vpravo nahoře profil → **Můj účet** → vpravo **API přístupový klíč** → **Zobrazit** → zkopíruj.
   ⚠️ Klíč je osobní — nesdílej ho, vše v EP se pak děje pod tvým jménem.
2. Otevři **PowerShell** (Start → napiš „powershell" → Enter) a spusť:

   ```powershell
   iwr https://github.com/lukas-dvoracek/EasyProject-MCP-Server/raw/main/install-mcp-ep.ps1 -OutFile $env:TEMP\install-mcp-ep.ps1
   powershell -ExecutionPolicy Bypass -File $env:TEMP\install-mcp-ep.ps1
   ```

   (Máš-li kopii repa EasyProject-MCP-Server na disku, spusť rovnou `install-mcp-ep.ps1` z jeho kořene — binárku pak vezme lokálně.)

3. Skript se zeptá na API klíč a případně na souhlas s instalací Node.js (potřebný jen pro server `easy8`). Vše ostatní udělá sám:
   - stáhne/zkopíruje `easyproject-mcp-server.exe` do `C:\Tools\easyproject-mcp\`
   - zazálohuje a upraví `%APPDATA%\Claude\claude_desktop_config.json` (existující nastavení zachová)
4. **Úplně ukonči Claude Desktop**: pravý klik na ikonu u hodin (systray) → **Quit**. Zavřít okno NESTAČÍ. Pak spusť znovu.
5. Ověření: v chatu klikni na ikonu nástrojů (posuvníky pod textovým polem) — mají být vidět servery `easyproject` a `easy8`. Test: „Vypiš moje otevřené úkoly v EasyProjectu."

Servery nastavené tímto postupem jsou dostupné v běžném chatu Claude Desktop i v Cowork sezeních.

## Pravidla používání (přečti si po instalaci)

- **Úkoly (výpis, detail, vytvoření, změna statusu/přiřazení, komentáře)** → nástroje `easy8_issues_*`. Důvod: server easyproject má bug — `update_issue` umí tiše zahodit změnu statusu/assignee.
- **Logování času, time entries, milníky, uživatelé, přílohy, reporty, dashboard** → nástroje serveru `easyproject` (easy8 tohle neumí).
- Aktivity pro `log_time`: **Programování = 129**, **Schůzka = 130** (povinný parametr).
- `watcher_user_ids` u create/update nepoužívat (bug — text skončí v popisu úkolu); watchery přidávat ručně v EP webu.
- Komentáře a time entries psát krátké (1–3 věty, srozumitelné i neprogramátorům), bez interních cest a detailů.
- Další konvence: `TEAM-CONVENTIONS.md` v repu EasyProject-MCP-Server.

## Pro Claude / Cowork (když tě uživatel požádá o pomoc s tímto návodem)

Jsi Claude a uživatel tě prosí o nastavení EasyProject MCP. **Nepokoušej se sám upravovat `%APPDATA%\Claude\claude_desktop_config.json` ani nic instalovat** — pokud běžíš v Cowork sandboxu, tvoje zápisy se do hostitelského systému nepropíšou a instalace bude vypadat hotová, ale nebude fungovat. Místo toho:

1. Vysvětli uživateli, že instalace se dělá skriptem mimo Cowork, a dej mu přesně příkazy z bodu 2 sekce **Instalace** výše (ať je spustí v běžném PowerShellu).
2. Připomeň mu, kde vezme API klíč (bod 1 Instalace) a že ho skript bude chtít vložit.
3. Po doběhnutí skriptu mu připomeň úplné ukončení Claude Desktop přes systray → Quit a nový start.
4. Pomoz s ověřením a případnými chybami (sekce Řešení problémů) — logy si nech od uživatele vložit do chatu, sám na ně nevidíš.
5. Na závěr mu shrň Pravidla používání.

## Řešení problémů

- **Server se nenačte / není v seznamu nástrojů** → zkontroluj `%APPDATA%\Claude\claude_desktop_config.json` (validní JSON, zdvojená zpětná lomítka v cestách) a logy `%APPDATA%\Claude\logs\mcp-server-easyproject.log` / `mcp-server-easy8.log`.
- **easy8 nefunguje** → ověř Node.js (`node --version`); po čerstvé instalaci Node pomůže restart počítače (PATH). Ruční test: `npx -y mcp-remote https://ep.pdsoft.eu/mcp --header "X-Redmine-API-Key:<KLÍČ>"`.
- **401/403 z EP** → špatný klíč; vygenerovat nový v Můj účet a spustit skript znovu.
- **Firemní síť/VPN blokuje GitHub** → binárku i skript lze zkopírovat z `D:\Projekty\Claude\EasyProject-MCP-Server\` (Lukáš Dvořáček) na USB/sdílený disk a skript spustit z té složky.
- Odebrání: smazat bloky `easyproject`/`easy8` z `claude_desktop_config.json` a restartovat aplikaci.
