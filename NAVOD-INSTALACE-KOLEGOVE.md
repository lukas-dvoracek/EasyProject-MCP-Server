# EasyProject MCP — návod na instalaci a používání (pro kolegy)

Tento návod popisuje, jak si připojit EasyProject (https://ep.pdsoft.eu) do Claude Code pomocí MCP serverů, a jak je pak používat. Existují **dva** MCP servery a doporučujeme mít zaregistrované oba:

| Server | Typ | K čemu slouží |
|---|---|---|
| **easy8** | HTTP (bez instalace) | Práce s úkoly — výpis, čtení, vytváření, úpravy, komentáře, seznam projektů |
| **easyproject** | lokální program (stdio) | Vše ostatní — logování času, time entries, milníky, uživatelé, přílohy, dashboard, reporty |

---

## 1. Předpoklady

- Nainstalovaný **Claude Code** (CLI). Ověření: v terminálu spusť `claude --version`.
- Účet v EasyProject na https://ep.pdsoft.eu s vlastním API klíčem.

### Získání vlastního API klíče

1. Přihlas se na https://ep.pdsoft.eu
2. Vpravo nahoře klikni na svůj profil → **Můj účet**
3. V pravém panelu najdi **API přístupový klíč** (API access key) → **Zobrazit**
4. Klíč si zkopíruj — budeš ho potřebovat v dalších krocích.

⚠️ **Klíč je osobní — nesdílej ho a nedávej do gitu.** Všechny akce v EP se pak dějí pod tvým jménem.

---

## 2. Instalace serveru „easy8" (jednoduchá, doporučený start)

Nic se nestahuje — server běží přímo na ep.pdsoft.eu. Stačí jeden příkaz v terminálu (ve složce, kde používáš Claude Code, nebo s `--scope user` pro všechny projekty):

```bash
claude mcp add --transport http easy8 https://ep.pdsoft.eu/mcp --header "X-Redmine-API-Key: TVŮJ_API_KLÍČ"
```

Pak restartuj Claude Code session. Ověření: v Claude Code napiš `/mcp` — easy8 by měl být ve výpisu jako connected.

**Dostupné nástroje (6):**
- `easy8_issues_list` — výpis úkolů (filtry: projekt, přiřazený, status…)
- `easy8_issues_get` — detail úkolu
- `easy8_issues_create` — nový úkol
- `easy8_issues_update` — úprava úkolu (status, přiřazení, komentář)
- `easy8_issues_comments_list` — komentáře úkolu
- `easy8_projects_list` — seznam projektů

---

## 3. Instalace serveru „easyproject" (plný — logování času atd.)

Tento server je lokální program (Rust). Hotové binárky jsou v tomto repu ve složce `deployment/`:

- `easyproject-mcp-server.exe` — Windows
- `easyproject-mcp-server-linux` — Linux / WSL

### 3a. Windows (nativní Claude Code ve Windows)

1. Zkopíruj si `deployment\easyproject-mcp-server.exe` někam k sobě, např. `C:\Tools\easyproject-mcp\`.
2. Zaregistruj server (PowerShell / cmd):

```bash
claude mcp add easyproject --env EASYPROJECT_API_KEY=TVŮJ_API_KLÍČ --env EASYPROJECT_BASE_URL=https://ep.pdsoft.eu/ -- C:\Tools\easyproject-mcp\easyproject-mcp-server.exe
```

### 3b. Linux / WSL

1. Zkopíruj si binárku a vytvoř wrapper skript (drží API klíč mimo registraci):

```bash
mkdir -p ~/easyproject-mcp
cp /cesta/k/repu/deployment/easyproject-mcp-server-linux ~/easyproject-mcp/
chmod +x ~/easyproject-mcp/easyproject-mcp-server-linux

cat > ~/easyproject-mcp/wrapper.sh << 'EOF'
#!/bin/bash
export EASYPROJECT_API_KEY=TVŮJ_API_KLÍČ
export EASYPROJECT_BASE_URL=https://ep.pdsoft.eu/
exec ~/easyproject-mcp/easyproject-mcp-server-linux
EOF
chmod +x ~/easyproject-mcp/wrapper.sh
```

2. Otevři `~/easyproject-mcp/wrapper.sh` a nahraď `TVŮJ_API_KLÍČ` svým klíčem.
3. Zaregistruj:

```bash
claude mcp add easyproject -- ~/easyproject-mcp/wrapper.sh
```

4. Restartuj Claude Code session a ověř přes `/mcp`.

**Dostupné nástroje (~27):** list/get/create/update/delete_project, list/get/create/update_issue, assign_issue, complete_task, list/get_user, get_user_workload, list/get/create/update/delete_time_entry, **log_time**, list/get/create/update/delete_milestone, get_attachment, download_attachment, generate_project_report, get_dashboard_data, get_issue_enumerations.

---

## 4. Jak se to používá

V Claude Code prostě piš česky, co chceš — Claude si zvolí správný nástroj. Příklady:

- „Vypiš moje otevřené úkoly v EasyProjectu."
- „Ukaž mi detail úkolu 206401 včetně komentářů."
- „Založ úkol *Oprava tisku* v projektu KubiQ, přiřaď ho mně."
- „Přepni úkol 206290 do stavu Testování."
- „Zaloguj 2 hodiny na úkol 205787, aktivita Programování, popis: oprava exportu."
- „Kolik hodin jsem tento týden vykázal?"

### Dělba práce mezi servery (důležité)

- **Úkoly (čtení, vytváření, změna statusu/přiřazení)** → **easy8** (`easy8_issues_*`). Je spolehlivější — starý server `update_issue` umí tiše zahodit změnu statusu/assignee.
- **Logování času, time entries, milníky, uživatelé, přílohy, reporty** → **easyproject** (easy8 tohle neumí).

### Užitečné konstanty

- Aktivity pro logování času: **Programování = 129**, **Schůzka = 130** (povinný parametr u `log_time`).
- ID uživatelů a další konvence: viz `TEAM-CONVENTIONS.md` v tomto repu.

### Známé mouchy starého serveru (easyproject)

- `update_issue` může tiše ignorovat změnu statusu/assignee (komentář projde) → na statusy používej `easy8_issues_update`.
- Parametr `watcher_user_ids` u create/update nefunguje správně (text skončí v popisu) → watchery přidávej ručně v EP webu.

---

## 5. Řešení problémů

- **Server se nepřipojí** → `/mcp` v Claude Code ukáže stav; zkontroluj API klíč a u Linux binárky `chmod +x`.
- **401/403 odpovědi** → špatný nebo expirovaný API klíč; vygeneruj nový v Můj účet.
- **Odregistrování:** `claude mcp remove easy8` / `claude mcp remove easyproject`.
- Registrace se ukládají do `~/.claude.json`; `claude mcp list` vypíše, co máš zaregistrované.
