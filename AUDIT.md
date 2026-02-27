# Аудит репозитория claude-workflow (ago:)

> Дата: 2026-02-25
> Метод: полный обход всех файлов, перекрёстная сверка утверждений между файлами

---

## Что это за репозиторий

Claude Code плагин (`ago:`) для оркестрации мультиагентных workflow в софтверных проектах. Весь репозиторий — markdown: конвенции, шаблоны, определения ролей, навыки (skills), команды. При установке в целевой проект создаёт директорию `.workflow/` с эпиками, задачами, логами, решениями.

**Ключевая архитектура:**
- 12 ролей (MASTER, PM, PROJ, ARCH, SEC, DEV, QAL, QAD, MKT, DOC, CICD, CONS) + 1 мета-агент (workflow-developer)
- 9 навыков (skills), 6 команд, 12 шаблонов
- Жизненный цикл сессии: INIT → BRIEF → COLLABORATE → DECOMPOSE → APPROVE → DELEGATE → MONITOR → CONSOLIDATE → REVIEW → UPDATE
- Иерархия ревью: ARCH→DEV, QAL→QAD, PM→MKT, SEC→DEV, ARCH→CICD
- Качество: T1 (Verified) → T2 (Probable) → T3 (Speculative) → T4 (Ungrounded)

---

## Обнаруженные проблемы

### КРИТИЧЕСКИЕ — влияют на корректность работы агентов

#### C1. Пути без `.workflow/` в определениях агентов

**Суть:** Все 13 файлов в `agents/` ссылаются на `docs/`, `log/`, `decisions/` без префикса `.workflow/`, хотя `conventions/file-structure.md` и команды (например `commands/status.md`) используют полные пути `.workflow/docs/`, `.workflow/log/` и т.д.

**Примеры:**
- `agents/architect.md`: `Read 'docs/architecture.md'` → должно быть `.workflow/docs/architecture.md`
- `agents/consolidator.md`: `check 'log/{ROLE}/' directories` → `.workflow/log/{ROLE}/`
- `agents/master-session.md`: смешивает оба формата — `'.workflow/registry.md'` и `'docs/status.md'`
- Аналогично во всех остальных: product-manager, project-manager, security-engineer, documentation, developer, qa-lead, qa-dev, marketer, cicd

**Влияние:** Агенты будут искать файлы по неправильным путям. Это самая массовая проблема в репо.

**Файлы:** Все 13 файлов в `agents/`
**Связь с TODO.md:** Совпадает с P03

---

#### C2. Счёт ролей: «12» vs 13 агентов

**Суть:** CLAUDE.md, README.md и `conventions/roles.md` утверждают «12 ролей», но в `agents/` — 13 файлов. 13-й — `workflow-developer.md` (мета-агент для разработки самого плагина). Он не описан в `conventions/roles.md`.

**Где расхождение:**
- `CLAUDE.md:15` — «12 role definitions»
- `README.md:9` — «12 Agent Roles» (но `README.md:42` — «13 files»)
- `conventions/roles.md` — таблица из 12 строк
- `memory/MEMORY.md:10` — корректно: «13 agent definitions (...+ workflow-developer)»

**Влияние:** Новый пользователь не узнает про workflow-developer. Роль не появится в registry, не будет валидироваться.

**Файлы:** `CLAUDE.md`, `README.md`, `conventions/roles.md`

---

#### C3. Навык `ago:evaluate-quality-gate` отсутствует в таблице навыков master-session

**ИСПРАВЛЕНО** (в рамках C5). `ago:evaluate-quality-gate` добавлен в Available Skills table в `agents/master-session.md`.

---

### ВЫСОКИЙ ПРИОРИТЕТ — приводят к путанице и ошибкам

#### H1. TODO-комментарий в `quality-gates.md` про нереализованный навык

**Суть:** `conventions/quality-gates.md:48` содержит:
> TODO: Implement quality gate evaluation as a skill (`ago:evaluate-quality-gate`) in Iteration 2.

Но навык **уже реализован** — файл `skills/evaluate-quality-gate/SKILL.md` существует и полностью описан.

**Влияние:** Вводит в заблуждение разработчиков. Создаёт впечатление незавершённости.

**Файлы:** `conventions/quality-gates.md`

---

#### H2. Регистр директории master-лога: `log/master/` vs `log/MASTER/`

**Суть:** Все остальные роли используют UPPERCASE в путях логов (`log/ARCH/`, `log/DEV/`, `log/QAL/`...), но для MASTER везде lowercase:
- `conventions/logging.md`: `log/master/{YYYY-MM-DD}.md`
- `conventions/naming.md`: `log/master/2026-02-20.md`
- `conventions/roles.md`: `log/master/`

**Влияние:** Нарушение паттерна. Если агент применит общее правило «директория = код роли в uppercase», он создаст `log/MASTER/` вместо `log/master/`.

**Файлы:** `conventions/logging.md`, `conventions/naming.md`, `conventions/roles.md`
**Связь с TODO.md:** Совпадает с P04

---

#### H3. Иерархия ревью неполная в README.md

**Суть:** README.md:20 перечисляет 3 пары: `ARCH→DEV, QAL→QAD, SEC→DEV`. Но фактическая иерархия (из `quality-gates.md`) содержит 6 пар:

| Ревьюер | Ревьюируемый |
|---------|-------------|
| ARCH | DEV |
| QAL | QAD |
| PM | MKT |
| SEC | DEV |
| ARCH | CICD |
| PM + ARCH | DEV (frontend) |

В CLAUDE.md — 4 пары (корректнее, но тоже неполные). Каждый файл описывает иерархию по-разному.

**Влияние:** Нет единого источника истины (single source of truth). Иерархия определена в 3+ местах.

**Файлы:** `README.md`, `CLAUDE.md`, `conventions/quality-gates.md`, `master-session/instructions.md`

---

#### H4. Дублирование quality gates и review hierarchy в 3 местах

**Суть:** Полная таблица качества (T1-T4) и иерархия ревью дублируются:
1. `conventions/quality-gates.md` — конвенция
2. `master-session/instructions.md` — инструкции мастер-сессии
3. `CLAUDE.md` — краткая версия

Ни один файл не ссылается на другой как на canonical source. Изменения нужно вносить в 3 места.

**Файлы:** `conventions/quality-gates.md`, `master-session/instructions.md`, `CLAUDE.md`

---

#### H5. Счёт convention-файлов в MEMORY.md

**Суть:** `memory/MEMORY.md:8` утверждает «6+ files: roles, naming, file-structure, task-lifecycle, decision-records, logging, timeline, quality-gates» — перечислено 8, но написано «6+». При этом пропущен `documentation.md` — фактически файлов 9.

**Файлы:** `memory/MEMORY.md`

---

### СРЕДНИЙ ПРИОРИТЕТ — неточности в документации

#### M1. Codex.md: «стаб» с утвердительными формулировками

**Суть:** `platforms/codex.md:5` объявляет себя стабом для Phase 4, но далее использует утвердительный язык:
- «Codex reads `AGENTS.md` at the project root» — как факт
- «The .workflow/ structure works as-is» — как факт

**Влияние:** Создаёт впечатление, что Codex-интеграция работает, хотя она не реализована.

**Файлы:** `platforms/codex.md`
**Связь с TODO.md:** Совпадает с P12

---

#### M2. Фронтматтер: где обязателен, где нет — нечётко

**Суть:** CLAUDE.md:40 утверждает «All files in `.workflow/` use YAML frontmatter», но:
- `templates/registry.md` — без фронтматтера (registry живёт в `.workflow/`)
- `templates/agent-log-entry.md` — без фронтматтера (логи живут в `.workflow/log/`)

Непонятно: это исключения или ошибка? Нигде не оговорено.

**Файлы:** `CLAUDE.md`, `memory/AGENTS.md`, `templates/registry.md`, `templates/agent-log-entry.md`
**Связь с TODO.md:** Совпадает с P09

---

#### M3. Шаблон agent-log-entry: неполный перечень статусов

**Суть:** `templates/agent-log-entry.md:14` перечисляет статусы: `in_progress | review | blocked`. Но по `conventions/task-lifecycle.md` существует 6 статусов: `backlog`, `planned`, `in_progress`, `review`, `done`, `blocked`.

Да, агенты не могут ставить `done` (это делает MASTER), но это нигде не пояснено в шаблоне.

**Файлы:** `templates/agent-log-entry.md`

---

#### M4. Отсутствует шаблон `project-docs/timeline.md`

**Суть:** В `templates/project-docs/` есть 6 файлов (eprd, architecture, security, testing, marketing, status). Но `registry.md` ссылается на `[[timeline]]`, а `conventions/timeline.md` описывает формат timeline. При этом шаблона `templates/project-docs/timeline.md` нет.

**Файлы:** `templates/project-docs/`, `conventions/timeline.md`
**Связь с TODO.md:** Совпадает с P02

---

#### M5. Синтаксис вызова команд: `/ago:...` vs `ago:...`

**Суть:** В файлах команд используется разный синтаксис вызова. Claude Code плагины используют формат `/command`, но в документации встречаются оба варианта.

**Файлы:** `commands/*.md`, `README.md`
**Связь с TODO.md:** Совпадает с P10

---

### НИЗКИЙ ПРИОРИТЕТ — мелкие расхождения

#### L1. Отсутствие перекрёстной ссылки task-lifecycle → naming

`conventions/task-lifecycle.md` ссылается на формат task ID, но не содержит ссылки на `conventions/naming.md`, в отличие от `conventions/decision-records.md`, которая корректно ссылается.

#### L2. Конвенция documentation.md не указана в определении роли DOC

`conventions/roles.md` определяет роль DOC, но не ссылается на `conventions/documentation.md` — отдельный файл с правилами владения документами.

#### L3. Epic template: поле `target_date` без пояснений

Шаблон `templates/epic.md` содержит `target_date: {YYYY-MM-DD}`, но нигде не описано, как это поле используется (дедлайн? ориентир? блокер?).

---

## Соответствие роудмапу

### Что написано в роудмапе vs. реальность

| Утверждение в README/CLAUDE.md | Реальность | Вердикт |
|-------------------------------|-----------|---------|
| Phase 1: Foundation — Done | Все конвенции, шаблоны, агенты, навыки созданы | **Верно**, но с inconsistencies выше |
| Phase 2: `ago:status` — Tested | Файл `commands/status.md` существует, помечен как tested | **Верно** |
| Phase 2: остальные 5 команд — TODO | Файлы `commands/*.md` существуют как спецификации | **Неточно** — файлы есть, но не протестированы. README не различает «написана спецификация» и «протестирована» |
| Phase 2: Executable skills — TODO | 9 навыков существуют как SKILL.md | **Неточно** — навыки описаны (спецификации), но не тестировались на реальном проекте |
| Phase 2: Plugin install script — TODO | Нет ни скрипта, ни Makefile | **Верно**, действительно TODO |
| Phase 3: Hooks | Нет реализации | **Верно**, Phase 3 не начата |
| Phase 4: Codex full integration | `platforms/codex.md` — стаб | **Верно**, но стаб написан утвердительно (см. M1) |
| README: «Platform-agnostic — works with Claude Code and Codex» | Codex-интеграция — стаб | **Завышено**. Работает только Claude Code |
| README: Quick Start step 2: `ago:readiness` to bootstrap | Команда не протестирована | **Преждевременно** — Quick Start обещает рабочий flow, но он не verified |
| CLAUDE.md: «Tested: ago:status» | Подтверждается коммитами | **Верно** |

### Главная проблема роудмапа

**Размытие границы между «спецификация написана» и «работает».**

Phase 1 объявлена Done, Phase 2 — In Progress. Но фактически:
- Phase 1 доставила спецификации (markdown-файлы)
- Ни один навык не был протестирован end-to-end
- Quick Start в README подразумевает рабочий продукт

Нет критерия «что значит Done для Phase 1». Написать markdown ≠ работающий плагин.

---

## Сводная таблица

| # | Проблема | Серьёзность | Новая? | Связь с TODO.md |
|---|---------|-------------|--------|-----------------|
| C1 | Пути без `.workflow/` в агентах | Критическая | Нет | P03 |
| C2 | 12 ролей vs 13 агентов | Критическая | Частично | — |
| C3 | `evaluate-quality-gate` нет в таблице master-session | Критическая | Да | — |
| H1 | TODO про нереализованный навык (уже реализован) | Высокая | Да | — |
| H2 | `log/master/` vs `log/MASTER/` | Высокая | Нет | P04 |
| H3 | Неполная иерархия ревью в README | Высокая | Да | — |
| H4 | Дублирование quality gates в 3 местах | Высокая | Да | — |
| H5 | Счёт convention-файлов в MEMORY.md | Высокая | Да | — |
| M1 | Codex.md: стаб с утвердительным языком | Средняя | Нет | P12 |
| M2 | Правило фронтматтера: исключения не оговорены | Средняя | Нет | P09 |
| M3 | Agent-log-entry: неполный список статусов | Средняя | Да | — |
| M4 | Нет шаблона `project-docs/timeline.md` | Средняя | Нет | P02 |
| M5 | Синтаксис вызова: `/ago:` vs `ago:` | Средняя | Нет | P10 |
| L1 | task-lifecycle не ссылается на naming | Низкая | Да | — |
| L2 | Роль DOC не ссылается на documentation.md | Низкая | Да | — |
| L3 | target_date без пояснений | Низкая | Да | — |
| — | Роудмап: нет границы spec vs working | Высокая | Да | Частично P11 |

**Из 17 пунктов существующего TODO.md:**
- P02, P03, P04, P09, P10, P12 — подтверждены, актуальны
- P13, P14, P15, P16, P17 — подтверждены (см. раздел ниже)
- P01, P05, P06, P07, P08, P11 — подтверждены на уровне описания, но не проверялись файл-за-файлом

---

## Верификация P13–P17

### P13. DOC scope contradiction — ПОДТВЕРЖДЕНО

**Противоречие внутри одного файла** `agents/documentation.md`:
- Строка 15: «Maintain README and developer guides» — README живёт в корне проекта
- Строка 26: «Only modify `.workflow/` files (docs, registry, task artifacts)»
- Строка 43: «Modify files outside `.workflow/` directory» — в секции «You Do NOT»

Те же самые слова «Maintain README» повторяются в `conventions/roles.md:202`. Это не просто документационный баг — агент получит прямо противоречащие инструкции.

---

### P14. Status-change logging ownership for MASTER transitions — ПОДТВЕРЖДЕНО

`conventions/task-lifecycle.md:33`: «Every status change MUST be logged in the agent's raw log»
`conventions/task-lifecycle.md:27`: `review → done` — делает MASTER
`conventions/logging.md:47`: «Master log captures cross-agent events only»

Когда MASTER переводит задачу в `done` — куда пишется лог?
- В master log? Но правило говорит «в raw log агента»
- В raw log исполнителя? Но исполнитель уже завершил работу

Неопределённость.

---

### P15. ago:clarify behavior vs lifecycle — ПОДТВЕРЖДЕНО

`commands/clarify.md:14`: «Creates task.md files in .workflow/epics/»
Жизненный цикл master-session:
- Step 4 (DECOMPOSE): Break into subtasks
- Step 5 (APPROVE): **User approves the plan**
- Step 6 (DELEGATE): Create task.md files, launch agents

`ago:clarify` объединяет DECOMPOSE + DELEGATE(create), пропуская APPROVE. Это нарушает принцип collaborative mode: «every decision requires user confirmation».

---

### P16. Hardcoded path in config template — ПОДТВЕРЖДЕНО (тривиально)

`templates/config.md:4`: `conventions_repo: ~/dev/claude-workflow`

Путь специфичен для одной машины. Нужен placeholder типа `{CONVENTIONS_REPO_PATH}`.

---

### P17. Wikilink target ambiguity for tasks — ПОДТВЕРЖДЕНО

`conventions/documentation.md:27`: `[[T003-DEV-mel-spectrogram]]` — wikilink
Но задача — это **директория** (`epics/{epic}/tasks/T003-DEV-mel-spectrogram/`), внутри которой `task.md`.

Obsidian wikilinks `[[name]]` ищут файлы с таким именем, не директории. Значит:
- Или ссылка должна быть `[[T003-DEV-mel-spectrogram/task]]`
- Или нужна конвенция, что `task.md` — единственный файл и ссылка идёт на него

`skills/validate-docs-integrity/SKILL.md:13`: «All task IDs mentioned in docs/DRs exist as task directories» — проверяет директории, а не файлы. Рассинхрон с wikilink-форматом.

---

## Новые находки (раунд 2)

### КРИТИЧЕСКИЕ

#### C4. `agents/master-session.md` не содержит Task tool — MASTER не может запускать агентов

**ИСПРАВЛЕНО.** Task tool добавлен в frontmatter `agents/master-session.md`.

---

#### C5. Два конкурирующих canonical source для роли MASTER

**ИСПРАВЛЕНО.** `master-session/instructions.md` и `master-session/collaborative-mode.md` удалены. Всё содержимое слито в единый self-contained файл `agents/master-session.md`:
- Quality Gate Evaluation (review hierarchy, quality tiers, evaluation process, anti-hallucination checks)
- Collaborative workflow (task formulation, decomposition, approval gate)
- Available Skills table (включая `ago:evaluate-quality-gate` — исправляет C3)
- Все пути нормализованы к `.workflow/` (частичное исправление C1)

Директория `master-session/` удалена. Ссылки в `CLAUDE.md` и `memory/AGENTS.md` обновлены.

---

### ВЫСОКИЙ ПРИОРИТЕТ

#### H6. `collaborative-mode.md` — сиротский файл

**ИСПРАВЛЕНО** (в рамках C5). Уникальное содержимое (task formulation, decomposition process, execution monitoring, review process) слито в `agents/master-session.md`. Файл удалён.

---

#### H7. P03 scope значительно шире, чем описано в TODO.md

**Суть:** TODO.md P03 перечисляет 5 файлов для нормализации путей:
> master-session/instructions.md, agents/master-session.md, agents/project-manager.md, agents/documentation.md, conventions/roles.md

Но **реальный scope** проблемы включает минимум 20 файлов:

| Файл | Путь без `.workflow/` |
|------|----------------------|
| Все 13 файлов в `agents/` | `docs/`, `log/`, `decisions/` |
| `conventions/roles.md` | все «Owns:» поля |
| `conventions/naming.md` | `epics/`, `log/`, `docs/` |
| `conventions/logging.md` | `log/master/`, `log/{ROLE}/` |
| `conventions/decision-records.md` | `log/{ROLE}/`, `decisions/`, `docs/` |
| `conventions/documentation.md` | `docs/architecture.md` (строка 40, при том что строка 5 корректно использует `.workflow/docs/`) |
| `master-session/instructions.md` | смешанный формат |

Исправление 5 файлов не решит проблему — нужен grep и замена по всему репо.

**Файлы:** 20+ файлов

---

#### H8. `conventions/documentation.md` — смешанные пути внутри одного файла

**Суть:**
- Строка 5: «in `.workflow/docs/`» — с префиксом
- Строка 40: «`docs/architecture.md`» — без префикса
- Строка 41: «`docs/security.md`» — без префикса

Единственный файл конвенций, который начинает корректно и потом забывает про `.workflow/`.

**Файлы:** `conventions/documentation.md`

---

### СРЕДНИЙ ПРИОРИТЕТ

#### M6. Два списка навыков MASTER рассинхронизированы

**ИСПРАВЛЕНО** (в рамках C5). `instructions.md` удалён. Единственный список навыков — в `agents/master-session.md` (таблица Available Skills).

---

#### M7. Роли-ревьюеры не описаны единообразно в agent-файлах

**Суть:** Формулировка Quality Gate секции различается:
- Senior reviewers (ARCH, QAL, SEC, PM) — говорят «You review: **DEV** work for...»
- Reviewed roles (DEV, QAD, MKT, CICD) — говорят «Your work is reviewed by **ARCH**...»
- DOC, PROJ, CONS — говорят «Your work is reviewed by **MASTER**...»

Но PM нигде в agent-файлах не описан как reviewer. `agents/product-manager.md:43-44` говорит «Your work is reviewed by the user and MASTER», а PM→MKT ревью из quality-gates.md не отражено в PM agent file.

Аналогично: `agents/marketer.md:46` корректно говорит «reviewed by PM», но `agents/product-manager.md` не упоминает ревью MKT.

**Файлы:** `agents/product-manager.md`

---

## Полная сводная таблица (обновлённая)

| # | Проблема | Серьёзность | Новая? | TODO.md |
|---|---------|-------------|--------|---------|
| ~~C1~~ | ~~Пути без `.workflow/` в агентах~~ | ~~Критическая~~ | — | **ИСПРАВЛЕНО** (P03) |
| ~~C2~~ | ~~12 ролей vs 13 агентов~~ | ~~Критическая~~ | — | **ИСПРАВЛЕНО** |
| ~~C3~~ | ~~`evaluate-quality-gate` нет в таблице master-session~~ | ~~Критическая~~ | — | **ИСПРАВЛЕНО** |
| ~~C4~~ | ~~master-session agent без Task tool~~ | ~~Критическая~~ | — | **ИСПРАВЛЕНО** |
| ~~C5~~ | ~~Два canonical source для MASTER без связи~~ | ~~Критическая~~ | — | **ИСПРАВЛЕНО** |
| ~~H1~~ | ~~TODO про нереализованный навык (уже реализован)~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** |
| ~~H2~~ | ~~`log/master/` vs `log/MASTER/`~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** (P04) |
| ~~H3~~ | ~~Неполная иерархия ревью в README~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** (ссылка на quality-gates.md) |
| ~~H4~~ | ~~Дублирование quality gates в 3 местах~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** (canonical: quality-gates.md) |
| ~~H5~~ | ~~Счёт convention-файлов в MEMORY.md~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** |
| ~~H6~~ | ~~collaborative-mode.md — сиротский файл~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** |
| ~~H7~~ | ~~P03 scope — 20+ файлов, не 5~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** (все 20+ файлов) |
| ~~H8~~ | ~~documentation.md — смешанные пути~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** |
| ~~M1~~ | ~~Codex.md: стаб с утвердительным языком~~ | ~~Средняя~~ | — | **ИСПРАВЛЕНО** (P12) |
| ~~M2~~ | ~~Правило фронтматтера: исключения не оговорены~~ | ~~Средняя~~ | — | **ИСПРАВЛЕНО** (P09) |
| M3 | Agent-log-entry: неполный список статусов | Средняя | Да | — |
| ~~M4~~ | ~~Нет шаблона `project-docs/timeline.md`~~ | ~~Средняя~~ | — | **ИСПРАВЛЕНО** (P02) |
| ~~M5~~ | ~~Синтаксис вызова: `/ago:` vs `ago:`~~ | ~~Средняя~~ | — | **ИСПРАВЛЕНО** (P10) |
| ~~M6~~ | ~~Два списка навыков MASTER рассинхронизированы~~ | ~~Средняя~~ | — | **ИСПРАВЛЕНО** |
| ~~M7~~ | ~~PM agent не описан как reviewer MKT~~ | ~~Средняя~~ | — | **ИСПРАВЛЕНО** |
| L1 | task-lifecycle не ссылается на naming | Низкая | Да | — |
| L2 | Роль DOC не ссылается на documentation.md | Низкая | Да | — |
| L3 | target_date без пояснений | Низкая | Да | — |
| ~~—~~ | ~~Роудмап: нет границы spec vs working~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** (P11) |
| ~~—~~ | ~~P13: DOC scope contradiction~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** |
| ~~—~~ | ~~P14: MASTER logging ownership~~ | ~~Средняя~~ | — | **ИСПРАВЛЕНО** |
| ~~—~~ | ~~P15: ago:clarify пропускает APPROVE~~ | ~~Высокая~~ | — | **ИСПРАВЛЕНО** |
| ~~—~~ | ~~P16: Hardcoded path~~ | ~~Низкая~~ | — | **ИСПРАВЛЕНО** |
| ~~—~~ | ~~P17: Wikilink target ambiguity~~ | ~~Средняя~~ | — | **ИСПРАВЛЕНО** |

**Все 17 пунктов TODO.md исправлены.**
**Все AUDIT проблемы исправлены, кроме 4 низкоприоритетных:** M3 (статусы в шаблоне лога), L1-L3

---

## Changelog

### 2026-02-25 — Merge & cleanup

**Выполнено:**
1. **Merged** `master-session/instructions.md` + `master-session/collaborative-mode.md` → `agents/master-session.md` (self-contained agent file)
2. **Deleted** `master-session/` directory (both files removed)
3. **Fixed C4:** Added `Task` tool to master-session agent frontmatter
4. **Fixed C3:** Added `ago:evaluate-quality-gate` to Available Skills table
5. **Fixed C5:** Single canonical source for MASTER role (agent file only)
6. **Fixed H6:** Collaborative mode principles merged into agent file
7. **Fixed M6:** Single skills list (no more dual maintenance)
8. **Fixed paths** in `agents/master-session.md`: all refs now use `.workflow/` prefix
9. **Updated** `CLAUDE.md` and `memory/AGENTS.md` references

**Remaining open:** M3, L1, L2, L3 (низкий приоритет)

### 2026-02-27 — Executable skills v0.2.0 + full consistency pass

**Выполнено:**
1. **All 9 skills rewritten** to executable v0.2.0 format (frontmatter, params, step-by-step instructions, validation, error handling)
2. **Fixed C1/H7/H8:** `.workflow/` path normalization across all 20+ files (agents, conventions, skills)
3. **Fixed C2:** WFDEV role added to `conventions/roles.md`, counts updated to 13 everywhere
4. **Fixed H1:** Removed stale TODO from `conventions/quality-gates.md`
5. **Fixed H2:** All log dirs lowercase (`{role}`, not `{ROLE}`)
6. **Fixed H3/H4:** README and CLAUDE.md now reference `conventions/quality-gates.md` as canonical source
7. **Fixed H5:** Convention file count corrected in MEMORY.md (9 files)
8. **Fixed M1/P12:** Codex claims narrowed to "planned" in README
9. **Fixed M2/P09:** Frontmatter rule narrowed to entity docs; logs exempt
10. **Fixed M4/P02:** Added `templates/project-docs/timeline.md`
11. **Fixed M5/P10:** All commands use `ago:` without leading slash
12. **Fixed M7:** PM agent now describes review of MKT work
13. **Fixed P05:** Short ID (`T001`) documented as canonical
14. **Fixed P06:** `blocked → planned | in_progress` transitions explicit
15. **Fixed P07/P08:** Doc ownership and DR authorship clarified
16. **Fixed P13:** DOC scope limited to `.workflow/` only
17. **Fixed P14:** MASTER logs transitions in own log only
18. **Fixed P15:** `ago:clarify` creates task.md after APPROVE step
19. **Fixed P16:** Removed hardcoded path from config template
20. **Fixed P17:** Wikilinks use full slug format

**Remaining open:** M3, L1, L2, L3 (низкий приоритет)
