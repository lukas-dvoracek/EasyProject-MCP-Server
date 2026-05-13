# EasyProject MCP — Team konvence & ID cache

Sdílený soubor pro Claude Code uživatele v PDSOFT. Obsahuje cache základních seznamů z EP API (project IDs, user IDs, enumerace, sběrné tickety) + workflow konvence, aby Claude nemusel pro každé volání tahat `list_*` z API.

> **Snapshot:** 2026-05-13. Při rozporu vůči EP UI je autoritativní EP — proveď refresh přes příslušný `list_*` tool a aktualizuj tento soubor.

---

## 1. User IDs

`list_users` vrací **403 Forbidden** (oprávnění). Cache:

| Iniciály | Jméno              | user_id |
|----------|--------------------|---------|
| LD       | Lukáš Dvořáček     | 101     |
| JV       | Jan Valčík         | 126     |
| MVa      | Michal Valčík      | 1       |
| ŠČe      | Šárka Čejková      | 103     |
| LSt      | Lukáš Strapina     | 144     |
| TLe      | Tomáš Lex          | 160     |
| PMo      | Peter Mokrička     | 140     |
| ŠSa      | Šimon Saloň        | 105     |
| LŠi      | Libor Šikl         | 102     |

Doplňuj iniciály postupně, jak je narazíš v `author`/`assigned_to` polích jiných volání.

---

## 2. Konvence pro `create_issue` / `update_issue`

| Pole              | Default                           | Zdroj                            |
|-------------------|-----------------------------------|----------------------------------|
| `project_id`      | 175 (KubiQ mobile) — per kontext  | per `K175` token nebo téma chatu |
| `tracker_id`      | 1 (Úkol)                          | enum níže                        |
| `status_id`       | 2 (Nový)                          | enum níže                        |
| `priority_id`     | 12 (Normální)                     | enum níže                        |
| `assigned_to_id`  | 101 (LD)                          | uživatel session                 |
| `start_date`      | dnes                              | —                                |
| `watcher_user_ids`| `[126]` (JV)                      | **vždy přidat JV jako watcher**  |
| `activity_id` (time entry) | 129 (Programování) / 130 (Schůzka) | dle kontextu             |

**Watcher konvence:** Při vytváření/úpravě úkolu vždy přidej `126` (JV) do `watcher_user_ids`. Dohodnuto napříč týmem.

---

## 3. Enumerace (globální)

### Status (`status_id`)
| ID | Název            | Closed |
|----|------------------|--------|
| 2  | Nový             | ne     |
| 3  | Realizace        | ne     |
| 6  | Přiřazeno        | ne     |
| 7  | Na klientovi     | ne     |
| 8  | Vráceno klientem | ne     |
| 9  | Testování        | ne     |
| 10 | Ke schválení     | ne     |
| 13 | K diskuzi        | ne     |
| 14 | Čeká se          | ne     |
| 31 | K nacenění       | ne     |
| 4  | Hotovo           | **ano**|

### Priority (`priority_id`)
| ID | Název    | Zkratka |
|----|----------|---------|
| 29 | Nízká    | `niz`   |
| 12 | Normální | `norm`  |
| 13 | Vysoká   | `vys`   |
| 20 | Urgentní | `urg`   |

### Tracker (`tracker_id`)
| ID | Název        |
|----|--------------|
| 1  | Úkol         |
| 3  | Požadavek    |
| 4  | User Story   |
| 5  | Chyba        |
| 7  | Otevřený bod |

### Activity (pro `create_time_entry` / `log_time`)
| ID  | Název          |
|-----|----------------|
| 129 | Programování   |
| 130 | Schůzka        |

> Aktivit je víc — doplň, až narazíš na další. Get přes admin UI v EP (Admin → Enumerations → Activities).

---

## 4. Projekty (65 aktivních)

Snapshot z `list_projects(limit=100, sort='name')`. Pokud chybí nový, `list_projects(search='...')` a doplň.

### Strom (parent → children)

- **Vývoj** (189)
  - Aplikační server (210)
  - Dodací list digitálně (325)
  - Implementace EUDR (188)
  - Interní projekty (286) → Servisní app Eliška (212)
  - **KubiQ mobile** (175) → Kubírování hráně dle sekcí (176)
  - Propla2 (181) → Czu.MapApp (345), EUDR (213), ProPla cloud (301), ProPla mobile (209)
  - Štítkování, manipulace na ES, EUDR (173)
  - Výroba 4000 (177)
  - W4 - webová výroba (180)
- **VES** (223)
  - EPO (224) → provoz (225), rozvoj (226) → HR002 (227), PZ 10 (358)
  - ERMA2 (228) → provoz (229) → Obecné (305); rozvoj (230) → HR002 (235)
  - ISND (231) → provoz (233) → Obecné (303), zastropované (302); rozvoj (232) → HR002 (234), PZ034 (349), PZ0xx LHPO (348), PZ0yy EIS (359)
  - PRAIS (236) → RDM provoz (237), rozvoj (241) → HR002 (242); SEPO provoz (239), rozvoj (245) → HR002 (246); SZR provoz (238), rozvoj (243) → HR002 (244); UKZUZ provoz (240), rozvoj (247) → HR002 (248)
  - VES - HelpDesk (253), Nezařazené (252), Odstávky (254)
- **Firma PDSOFT** (174)
  - Integrace + automatizace (214), Porady PDSOFT priority Choceň (217)
- **CZ - Realizace** (206)
  - Implementace KubiQ (279), Implementace KubiQ ESCO (172)
- **SK - realizace** (193) → SK - Realizácia (207)

### Root projekty (bez parent)

| ID  | Název                       |
|-----|-----------------------------|
| 174 | Firma PDSOFT                |
| 189 | Vývoj                       |
| 193 | SK - realizace              |
| 204 | Fronta požadavků PDSOFT     |
| 205 | Obecná režie PDSOFT         |
| 206 | CZ - Realizace              |
| 185 | Helpdesk                    |
| 223 | VES                         |
| 250 | UUR - provoz                |
| 251 | UUR - rozvoj                |

---

## 5. Sběrné tickety (Režie)

| ID    | Subject                       | Project (ID)              | Použití                  |
|-------|-------------------------------|---------------------------|--------------------------|
| 4561  | KubiQ mobile - Režie          | KubiQ mobile (175)        | režie/schůzky KubiQ      |
| 4551  | Obecná režie PDSOFT - Režie   | Obecná režie PDSOFT (205) | firma-wide režie         |
| 200484| Testování a režie KubiQ - LSt | KubiQ mobile (175)        | LSt-specifické testování |
| 203574| Obecná režie - PMo            | Obecná režie PDSOFT (205) | PMo                      |

### Rozcestníky / čas s odstávkami (per VES projekt)

| Issue   | Účel                              |
|---------|-----------------------------------|
| #200036 | EPO rozcestník                    |
| #200037 | ERMA2 rozcestník                  |
| #5843   | ISND katalogový list              |
| #5972   | MPŽ katalogový list               |
| #5973   | CESNaP katalogový list            |
| #5975   | LHE katalogový list               |
| #5976   | SOP katalogový list               |
| #200039 | SZR katalogový list               |
| #200040 | RDM katalogový list               |
| #201378 | EPO — čas s odstávkami            |
| #201379 | ERMA2 — čas s odstávkami          |
| #201380 | ISND — čas s odstávkami           |
| #201381 | SZR+SEPO — čas s odstávkami       |
| #201382 | RDM — čas s odstávkami            |

---

## 6. Workflow: denní diff vlastních úkolů

Cílem je upozornit uživatele na **nově přidané otevřené úkoly** přiřazené jemu, bez ručního dotazu.

### Recept

1. Při první konverzaci nového dne (datum změnil) zavolej:
   ```
   list_issues(assigned_to_id=<user_id>, sort='created_on:desc', limit=25)
   ```
2. Porovnej IDs proti uloženému snapshotu (per-user soubor `my-issues-<user_id>.json` mimo git — viz §7).
3. Nové IDs → stručná zpráva uživateli: `Nové EP úkoly dnes: #ID Subject (Project, Prio)`.
4. Chybějící IDs → ověř `get_issue(id)` — pokud `is_closed=true`, smaž ze snapshotu.
5. Po 7+ dnech od snapshot date proveď plný refresh přes `assigned_to_id=<id>, limit=100` + offset pages.

### Throughput pozor

`list_issues(assigned_to_id, limit=100)` může vrátit ~3 800 řádků JSON. Pro denní diff stačí `limit=25, sort='created_on:desc'` (jen nově přidané). Plný snapshot dělej týdně.

---

## 7. Per-user snapshot file (mimo git)

Každý kolega si drží lokální soubor s vlastním snapshotem. Doporučená cesta v Claude Code memory:

```
~/.claude/projects/-home-<user>-Claude/memory/reference_ep_my_issues.md
```

Struktura: viz `reference_ep_my_issues.md` v memory uživatele LD jako vzor. Sloupce: `ID | Subject | Project | Status | Prio | Done% | Due`.

**Soubor NEcommitovat** do EP MCP repa — obsahuje per-user data.

---

## 8. Údržba tohoto souboru

Pokud Claude (kterýkoli uživatel) zjistí, že byl přidán/přejmenován projekt, vytvořena nová enumerace, objevila se nová iniciála uživatele nebo nová sběrná tikettka:

1. Updatuj příslušnou tabulku zde.
2. Commit + push s message `EP cache update: <co se změnilo>`.
3. Kolegové si při dalším `git pull` natáhnou aktuální seznam.

Snapshot date v hlavičce udržuj aktuální při jakékoli úpravě.

---

## 9. Odkazy

- `README.md` — instalace MCP serveru, registrace
- `CLAUDE-PROMPTS.md` — zjednodušené prompty pro Claude
- `BUILD-GUIDE.md` — build z source (Rust)
- `DEPLOYMENT.md` — deployment na server
