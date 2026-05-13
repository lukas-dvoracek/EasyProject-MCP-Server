# EasyProject MCP Server — TODO

Chybějící funkce + známé limity wrapperu. Aktualizovat při každé iteraci.

## ✅ Dokončeno

### 2026-05-12
- Attachment support (`get_attachment`, `download_attachment` s save_to_path/base64)
- Issue model rozšířen o `attachments: Option<Vec<Attachment>>`

### 2026-05-13
- Watchers (`watcher_user_ids` v create_issue/update_issue, fallback přes POST /issues/{id}/watchers.json)
- Milníky (`fixed_version_id` v update_issue), plus `category_id`, `parent_issue_id`, `tracker_id`
- Journals/komentáře (`notes` v update_issue, `include=journals` v get_issue)
- Issue model rozšířen o `journals: Option<Vec<Journal>>`
- Wrapper rebuild → Linux ELF v deployment/easyproject-mcp-server-linux (cca 4.3 MB)
- CLAUDE-PROMPTS.md — dokumentace zjednodušených promptů

## 🔴 Otevřené — chybějící v wrapperu

| ID | Co | Důvod / popis |
|----|-----|---------------|
| **T1** | `list_users` vrací 403 Forbidden | API nedost. práv pro current user. Workaround: cache user IDs v Claude memory. Lepší řešení: použít `GET /users.json?status=1` s admin tokenem nebo přepnout autorizaci. |
| **T2** | `list_attachments(issue_id)` standalone | Currently musí se použít `get_issue(id, include=["attachments"])` a parsovat. Standalone tool by byl pohodlnější. |
| **T3** | Watcher list / remove | Aktuálně lze jen `add_issue_watcher` (přes update_issue.watcher_user_ids). Chybí `list_issue_watchers` (include=watchers už podporováno modelem, ale není wrappered) a `remove_issue_watcher`. |
| **T4** | Custom fields | Redmine custom_field_values nejsou v Issue modelu ani v CreateIssue. Nelze nastavit přes create/update_issue. |
| **T5** | Bulk operace | Není `bulk_update_issues` (změna assignee/status/category pro N úkolů). Nutno volat update_issue N×. |
| **T6** | Subtasks listing | `list_issues(parent_issue_id=N)` neexistuje; tracker filter `parent` chybí. Workaround: list_issues + grep parent v JSON. |
| **T7** | Project move (issue→project) | Změna project_id v update_issue není podporována (current_issue.project.id se vždy přepíše). Vyžaduje samostatný tool nebo extension. |
| **T8** | Search across issues | Currently `easy_query_q` text search, ale není fulltext na popis/poznámky. Možné rozšíření o `subject_contains`, `description_contains`. |
| **T9** | Issue history changes detail | Journal entries vrací `notes`, ale chybí `details` (změna fields jako status_id was 1 → 2). Pro audit potřeba doplnit Journal.details. |
| **T10** | Caching invalidation po update | `get_issue` má cache, ale `update_issue`/`update_attachment`/atd. neinvalidují cache → stale data v get po update. Pomoc: u Issue update zavolat `invalidate_cache("issue_{}")`. |

## 🟡 UX / Quality

| ID | Co | Popis |
|----|-----|-------|
| **U1** | Defaults v create_issue | Pokud user vynechá `tracker_id` nebo `priority_id`, vyžaduje teď. Default na 1 (Úkol) a 12 (Normální). |
| **U2** | Error messages česky/anglicky mix | Některé errors jsou v EN ("Add watcher failed"), jiné v CZ. Sjednotit. |
| **U3** | Activity ID enumerations | `log_time` vyžaduje activity_id. Není list_activities tool. Workaround: 129 = Programování (hardcoded). |
| **U4** | Watcher IDs reverse lookup | Po update_issue není v response field "added watchers". Wrapper logy v textu, ale ne structured. |

## 🟢 Nápady / nice-to-have

| ID | Co |
|----|-----|
| N1 | `clone_issue(id)` — kopie úkolu vč. attachments |
| N2 | `link_issues(from, to, type)` — manuální vytvoření relations |
| N3 | `archive_attachment(id)` — soft delete přílohy |
| N4 | Webhook listener — Claude přihlásí na issue update events |
| N5 | Markdown converter — Redmine textile → Markdown a zpět |

## Build & deploy

```bash
# WSL build
cd /mnt/d/Projekty/Claude/EasyProject-MCP-Server
cargo build --release

# Deploy Linux ELF
rm -f deployment/easyproject-mcp-server-linux
cp target/release/easyproject-mcp-server deployment/easyproject-mcp-server-linux

# Pak: /mcp reconnect v Claude Code
```

Wrapper: `/home/frackker/Claude/easyproject-mcp-wrapper.sh` (exportuje API key + spouští ELF).
