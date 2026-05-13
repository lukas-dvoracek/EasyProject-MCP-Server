# EasyProject MCP — Zjednodušené prompty pro Claude

Reference k používání MCP wrapperu z Claude Code session. Stručné prompty → MCP volání s rozumnými defaulty.

## Implicitní hodnoty (Claude doplní automaticky)

| Pole | Default | Zdroj |
|------|---------|-------|
| `project_id` | 175 (KubiQ mobile) | per `K175` token nebo memory |
| `tracker_id` | 1 (Úkol) | — |
| `status_id` | 2 (Nový) | — |
| `assigned_to_id` | 101 (Lukáš Dvořáček, ty) | — |
| `priority_id` | 12 (Normální) | — |
| `start_date` | dnes | — |
| `watcher_user_ids` | `[126]` (JV) | memory `feedback_ep_watcher_jv.md` |
| `activity_id` (log_time) | 129 (Programování) | per session log |

## Zkratky priorit a statusů

**Priority** (`prio:`): `niz` = 29, `norm` = 12, `vys` = 13, `urg` = 20
**Status** (`status:`): `nový` = 2, `realizace` = 3, `přiřaz` = 6, `klient` = 7, `test` = 9, `diskuze` = 13
**Tracker**: 1=Úkol, 4=User Story, 5=Chyba, 7=Otevřený bod

## Vytvoření úkolu

```
ep úkol K175: <předmět>
desc: <popis (1-N řádků, případně HTML)>
prio: vys
odhad: 4h
milník: 224
spolupracovníci: MVa ŠČe
```

Vynechané položky se doplní z defaultů. Předmět + project jsou jediné povinné.

Příklad:
```
ep úkol K175: Bug v exportu CSV
desc: Krátké názvy sloupců se ořezávají na 10 znaků v UTF-8.
prio: vys
odhad: 2
milník: 224
```

## Editace úkolu

```
ep upd <ID>: <jedna nebo více změn oddělených čárkami>
```

Příklady:
```
ep upd 204861: done 100
ep upd 204861: prio urg, due 2026-05-20
ep upd 204861: assign LD, status realizace
ep upd 204861: milník 224
ep upd 204861: spolupracovníci MVa ŠČe
ep upd 204861: tracker chyba, kategorie 5
```

## Komentář k úkolu (journal note)

> Implementováno 2026-05-13 přes `notes` field v update_issue + `include=journals` v get_issue.

**Přidat komentář**:
```
ep komentář 204861: <text komentáře>
```

→ `update_issue(id=204861, notes="<text>")` — vytvoří journal entry s autorem = ty.

**Vypsat komentáře**:
```
ep komentáře 204861
```

→ `get_issue(id=204861, include=["journals"])` → vrátí seznam s autorem, časem, textem.

## Zalogovat čas (time entry)

```
ep log <ID> Nh: <komentář>
```

Defaults: dnes, activity 129 (Programování), zaloguje se na issue (ne na project).

Příklad:
```
ep log 204861 1.5h: analýza + návrh řešení
```

## Stažení přílohy

```
ep příloha <attachment_id> [-> /tmp/path.png]
```

→ `download_attachment(id, save_to_path)` nebo bez path → base64.

Pro nalezení IDs:
```
ep úkol <ID> přílohy
```

→ `get_issue(id, include=["attachments"])` → seznam s ID, filename, content_type, content_url.

## Milníky (versions)

```
ep milníky K175 [open|closed]
```

→ `list_milestones(project_id=175, status=...)`. Defaultně `open`.

KubiQ relevantní (k 2026-05-13):
- 197 KubiQ backlog
- 224 Verze KubiQ 1.11.xx.xx (aktuální vývoj)
- 226 Verze KubiQ 1.11.04.01 — NASAZENO

## User ID mapping (cached v Claude memory)

| Iniciály / Jméno | user_id |
|------------------|---------|
| LD — Lukáš Dvořáček (ty) | 101 |
| JV — Jan Valčík | 126 |
| MVa — Michal Valčík | 1 |
| ŠČe — Šárka Čejková | 103 |

V promptu stačí iniciály — Claude dohledá ID z paměti. `list_users` vrací 403 (nedost. práv).

## Časté kombinace promptů

### Bug report
```
ep úkol K175: <bug>
desc: <co se děje, kroky, očekávané chování>
prio: vys
milník: 224
log 0.5h: diagnostika, lokalizace v <soubor>:<řádek>
```

### Feature
```
ep úkol K175: <feature>
desc: <cíl, akceptační kritéria>
odhad: <N>h
milník: 224
spolupracovníci: MVa
```

### Hotová oprava
```
ep upd <ID>: done 100, status test
ep komentář <ID>: Opraveno v <commit> / <soubor>:<řádek>
ep log <ID> Nh: implementace + test
```

## Co MCP wrapper NEUMÍ (známé limity)

- `list_users` → 403 Forbidden (user nedost. práv). Workaround: cache user IDs v memory.
- Bulk operace (přesun mezi projekty, hromadný update) — jen jednotlivě.
- Custom fields — nelze nastavit přes wrapper.
- Watchers list (kdo aktuálně watcher) — wrapper nevrací. Workaround: ověřit přes web UI.

## Wrapper source

- Rust source: `/mnt/d/Projekty/Claude/EasyProject-MCP-Server/`
- Build: `cargo build --release` (z root)
- Deploy: `cp target/release/easyproject-mcp-server deployment/easyproject-mcp-server-linux`
- Po deploy: `/mcp` reconnect v Claude Code
- Wrapper: `/home/frackker/Claude/easyproject-mcp-wrapper.sh` (exec ELF s WSLENV)
