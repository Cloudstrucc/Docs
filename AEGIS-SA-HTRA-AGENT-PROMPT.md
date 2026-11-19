# Aegis SA — HTRA Module Implementation Brief

> **How to use this document:** paste it as the opening prompt for a Claude Code
> session in the Aegis SA repository, or save it as `docs/htra-module-brief.md`
> and point your agent at it. It is written to be executed, not just read.
> Sections marked **VERIFY** require the agent to inspect the real codebase
> before writing code — do not let it assume.

---

## 0. Agent instructions (read first)

You are implementing a new assessment capability in Aegis SA. Before writing any
code, do the following and report back:

1. **Map the existing domain.** Find and summarise: the `project` model and its
   stage/status machine; the `assessment` model; how a framework and its controls
   are stored; how controls get scoped into an assessment at creation; the
   decision-package model and its artifact/sign-off tables.
2. **Confirm the stack specifics** — Express router layout, Handlebars view/partial
   conventions, where Svelte components mount and how they receive props, the
   SQLite driver and migration mechanism in use, and how AI calls are made
   (client wrapper, prompt storage, streaming or not).
3. **Report any conflict** between this brief and what you find. The real codebase
   wins on naming and conventions; this brief wins on the conceptual model.
4. **Do not** add new top-level project stages. Do not rename existing tables.
   Do not refactor the existing control-compliance path. Every change here is
   additive.

Then implement in the phase order given in §7, pausing for review after each phase.

---

## 1. The problem in one paragraph

Aegis SA currently treats "framework" and "control catalogue" as synonyms: every
supported framework (NIST SP 800-53, ISO 27001, SOC 2, ITSG-33) is a list of
controls, and an assessment is a scoped subset of those controls with compliance
state against each. The Government of Canada's **HTRA** (Harmonized Threat and
Risk Assessment, publication TRA-1, CSE + RCMP, 2007) is not a control catalogue.
It is an *analytic methodology*: it values assets by the injury their compromise
would cause, assesses threats against them, measures vulnerability given existing
safeguards, and derives a residual risk that a business owner formally accepts.
It produces a risk register and a TRA report, not a compliance matrix.

Supporting HTRA therefore requires one conceptual change and several additive
tables — **not** a new pipeline and **not** a refactor.

## 2. The one conceptual change

Introduce **method type**. A method is anything that can be scoped into an
assessment and contribute findings to a decision package.

| Method type | Unit of analysis | Produces | Examples |
|---|---|---|---|
| `control_compliance` | Control | Control gaps, compliance state | 800-53, ISO 27001, SOC 2, ITSG-33 |
| `risk_analysis` | Asset × Threat × Vulnerability | Residual risks, recommendations | **HTRA/TRA-1**, ISO 27005, NIST 800-30, FAIR |
| `hybrid` | Both | Both | ITSP.10.035 (ITSG-33's successor) |

All existing frameworks become `control_compliance` rows. HTRA becomes the first
`risk_analysis` row. A project may scope one, the other, or both — and for a GC
system handling PROTECTED B information, both is the normal case.

**The unifying insight that keeps this cheap:** both method types produce
*findings linked to things*. A control-compliance finding is a gap linked to a
system. An HTRA finding is a residual risk linked to an asset, a threat and a
vulnerability. One `finding` table with a flexible set of linked entities serves
both, and the decision package reads findings without knowing which method
produced them.

## 3. Where HTRA sits in the existing pipeline

The project flow — **intake → assessment → decision package → close** — does not
change. HTRA's five phases are *sub-steps inside the assessment stage*:

| TRA-1 phase | Aegis SA stage | New sub-step |
|---|---|---|
| 1. Preparation (scope, work plan) | Intake | reuses existing intake |
| 2. Asset identification & valuation | Assessment | `asset_valuation` |
| 3. Threat assessment | Assessment | `threat_assessment` |
| 4. Risk assessment (vulnerability → residual risk) | Assessment | `risk_evaluation` |
| 5. Recommendations & risk acceptance | Decision package | reuses existing sign-off |
| TRA report deliverable | Decision package | new artifact renderer |

**Anti-requirement:** do not promote these to top-level stages. A method declares
sub-steps; the assessment stage renders whichever sub-steps its scoped methods
declare. That is the whole mechanism, and it is what makes the platform
configurable for any future methodology.

## 4. Method-as-data

A method is a database row plus a declarative definition, not a code module.
The platform implements a fixed superset of capabilities; a method selects from it.

### 4.1 Entity vocabulary (fixed — methods may not invent types)

`asset` · `threat` · `vulnerability` · `safeguard` · `control_instance`

A method chooses which it uses and relabels them for its own UI language
(HTRA calls a `safeguard` a "safeguard"; ISO 27005 would call it a "control").

### 4.2 Scales

Named ordinal scales with explicit levels. HTRA needs `injury_severity`,
`likelihood`, `gravity`, `vulnerability_severity`, and an output `risk_level`.

### 4.3 Derivations

How one value is computed from others. Two forms only:

- **`matrix`** — a lookup table: two input scale values → one output scale value.
- **`expression`** — a tiny whitelisted arithmetic grammar.

> **SECURITY — non-negotiable.** Method definitions are admin-editable data.
> Never evaluate them with `eval`, `new Function`, or any template engine that
> executes arbitrary JS. Implement a small recursive-descent interpreter over a
> fixed token set (`+ - * / min max round clamp`, scale references, numeric
> literals, parentheses) with a depth limit. Reject anything else at save time
> *and* at evaluation time.

### 4.4 Worked example — the HTRA method definition

```json
{
  "key": "htra-tra1",
  "name": "Harmonized Threat and Risk Assessment (TRA-1)",
  "method_type": "risk_analysis",
  "publisher": "CSE / RCMP",
  "version": "2007-10",
  "entities": {
    "asset":         { "label": "Asset",         "classes": ["information", "it_component", "facility", "personnel", "service"] },
    "threat":        { "label": "Threat",        "classes": ["deliberate", "accidental", "natural"] },
    "vulnerability": { "label": "Vulnerability" },
    "safeguard":     { "label": "Safeguard" }
  },
  "scales": {
    "injury_severity":       { "label": "Injury severity",       "levels": 5, "labels": ["Very low","Low","Medium","High","Very high"] },
    "likelihood":            { "label": "Threat likelihood",     "levels": 5, "labels": ["Very low","Low","Medium","High","Very high"] },
    "gravity":               { "label": "Threat gravity",        "levels": 5, "labels": ["Very low","Low","Medium","High","Very high"] },
    "vulnerability_severity":{ "label": "Vulnerability severity","levels": 5, "labels": ["Very low","Low","Medium","High","Very high"] },
    "risk_level":            { "label": "Residual risk",         "levels": 5, "labels": ["Very low","Low","Medium","High","Very high"] }
  },
  "derivations": [
    { "key": "threat_level",  "type": "matrix", "inputs": ["likelihood", "gravity"],              "output": "threat_level" },
    { "key": "residual_risk", "type": "matrix", "inputs": ["asset_value", "exposure"],            "output": "risk_level" },
    { "key": "exposure",      "type": "matrix", "inputs": ["threat_level", "vulnerability_severity"], "output": "exposure" }
  ],
  "steps": [
    { "key": "asset_valuation",   "stage": "assessment", "ordinal": 1, "title": "Assets & statement of sensitivity",
      "requires": ["asset"], "complete_when": "every asset has a valuation for C, I and A" },
    { "key": "threat_assessment", "stage": "assessment", "ordinal": 2, "title": "Threat assessment",
      "requires": ["threat"], "complete_when": "every threat has likelihood and gravity" },
    { "key": "risk_evaluation",   "stage": "assessment", "ordinal": 3, "title": "Vulnerabilities & residual risk",
      "requires": ["vulnerability"], "complete_when": "every asset-threat pair is assessed or explicitly excluded" }
  ],
  "deliverables": [
    { "key": "tra_report",            "name": "TRA Report",               "template": "htra/tra-report" },
    { "key": "statement_sensitivity", "name": "Statement of Sensitivity", "template": "htra/sos" },
    { "key": "risk_register",         "name": "Risk Register",            "template": "htra/risk-register" }
  ]
}
```

> **VERIFY — the published scales.** The structure above is correct, but the
> exact level counts, level labels and matrix cell values must be taken from the
> TRA-1 publication itself (`tra-emr-1-e.pdf` on cyber.gc.ca), **not** from this
> brief and **not** from the model's memory. Seed the matrices from the published
> tables and cite the table number in a `source_ref` column. An assessor will
> compare your output against those tables cell by cell. Until the publication is
> in hand, mark the seeded method `is_draft = 1` and surface that in the UI.

## 5. Schema (SQLite)

Conventions assumed — **VERIFY and match the repo**: integer surrogate keys,
`created_at`/`updated_at` as ISO-8601 TEXT, soft delete via `deleted_at`, JSON in
TEXT columns guarded by `CHECK (json_valid(col))` and read with `json_extract`.

```sql
-- ── Method registry ────────────────────────────────────────────────
ALTER TABLE framework ADD COLUMN method_type TEXT NOT NULL DEFAULT 'control_compliance'
  CHECK (method_type IN ('control_compliance','risk_analysis','hybrid'));
-- VERIFY the real table name; if it is `framework`, consider a `method` view
-- over it rather than a rename, to avoid touching existing queries.

CREATE TABLE method_definition (
  id            INTEGER PRIMARY KEY,
  framework_id  INTEGER NOT NULL REFERENCES framework(id),
  version       TEXT    NOT NULL,
  definition    TEXT    NOT NULL CHECK (json_valid(definition)),
  is_draft      INTEGER NOT NULL DEFAULT 1,
  source_ref    TEXT,
  created_at    TEXT    NOT NULL,
  UNIQUE (framework_id, version)
);

CREATE TABLE method_scale (
  id            INTEGER PRIMARY KEY,
  framework_id  INTEGER NOT NULL REFERENCES framework(id),
  key           TEXT    NOT NULL,
  label         TEXT    NOT NULL,
  UNIQUE (framework_id, key)
);

CREATE TABLE method_scale_level (
  scale_id      INTEGER NOT NULL REFERENCES method_scale(id),
  value         INTEGER NOT NULL,
  label         TEXT    NOT NULL,
  description   TEXT,
  severity_token TEXT,              -- maps to a UI colour token, not a hex
  PRIMARY KEY (scale_id, value)
);

CREATE TABLE method_matrix (
  id            INTEGER PRIMARY KEY,
  framework_id  INTEGER NOT NULL REFERENCES framework(id),
  key           TEXT    NOT NULL,
  input_a_scale INTEGER NOT NULL REFERENCES method_scale(id),
  input_b_scale INTEGER NOT NULL REFERENCES method_scale(id),
  output_scale  INTEGER NOT NULL REFERENCES method_scale(id),
  source_ref    TEXT,               -- e.g. "TRA-1 Table C-3"
  UNIQUE (framework_id, key)
);

CREATE TABLE method_matrix_cell (
  matrix_id     INTEGER NOT NULL REFERENCES method_matrix(id),
  a_value       INTEGER NOT NULL,
  b_value       INTEGER NOT NULL,
  out_value     INTEGER NOT NULL,
  PRIMARY KEY (matrix_id, a_value, b_value)
);

-- ── Which methods are scoped into an assessment ────────────────────
CREATE TABLE assessment_method (
  assessment_id INTEGER NOT NULL REFERENCES assessment(id),
  framework_id  INTEGER NOT NULL REFERENCES framework(id),
  config        TEXT CHECK (config IS NULL OR json_valid(config)),
  scoped_reason TEXT,               -- why the scoping engine chose it
  PRIMARY KEY (assessment_id, framework_id)
);

-- ── Generic typed entities ─────────────────────────────────────────
CREATE TABLE entity (
  id            INTEGER PRIMARY KEY,
  project_id    INTEGER NOT NULL REFERENCES project(id),
  type          TEXT    NOT NULL CHECK (type IN
                  ('asset','threat','vulnerability','safeguard','control_instance')),
  class         TEXT,               -- e.g. 'information' | 'deliberate'
  label         TEXT    NOT NULL,
  description   TEXT,
  attributes    TEXT CHECK (attributes IS NULL OR json_valid(attributes)),
  source        TEXT NOT NULL DEFAULT 'manual'
                  CHECK (source IN ('manual','ai_extracted','catalogue','imported')),
  created_at    TEXT NOT NULL,
  deleted_at    TEXT
);
CREATE INDEX idx_entity_project_type ON entity(project_id, type) WHERE deleted_at IS NULL;

CREATE TABLE entity_link (
  from_entity   INTEGER NOT NULL REFERENCES entity(id),
  to_entity     INTEGER NOT NULL REFERENCES entity(id),
  relation      TEXT    NOT NULL,   -- 'threatens' | 'exposes' | 'mitigated_by' | 'implements'
  PRIMARY KEY (from_entity, to_entity, relation)
);

-- ── Statement of sensitivity: injury valuation per C/I/A ───────────
CREATE TABLE valuation (
  id              INTEGER PRIMARY KEY,
  entity_id       INTEGER NOT NULL REFERENCES entity(id),
  dimension       TEXT    NOT NULL CHECK (dimension IN ('C','I','A')),
  injury_category TEXT,             -- 'financial' | 'privacy' | 'public_confidence' | ...
  scale_id        INTEGER NOT NULL REFERENCES method_scale(id),
  value           INTEGER NOT NULL,
  rationale       TEXT    NOT NULL, -- required: this is what gets defended
  confirmed_by    INTEGER REFERENCES user(id),
  confirmed_at    TEXT,
  UNIQUE (entity_id, dimension)
);

-- ── Findings: one table for both method types ──────────────────────
CREATE TABLE finding (
  id             INTEGER PRIMARY KEY,
  assessment_id  INTEGER NOT NULL REFERENCES assessment(id),
  framework_id   INTEGER NOT NULL REFERENCES framework(id),
  kind           TEXT    NOT NULL CHECK (kind IN ('control_gap','residual_risk')),
  level_scale_id INTEGER REFERENCES method_scale(id),
  level_value    INTEGER,
  computed       TEXT CHECK (computed IS NULL OR json_valid(computed)),
                 -- full derivation trace: inputs, matrices hit, intermediates
  narrative      TEXT,
  status         TEXT NOT NULL DEFAULT 'open',
  created_at     TEXT NOT NULL
);

CREATE TABLE finding_entity (
  finding_id    INTEGER NOT NULL REFERENCES finding(id),
  entity_id     INTEGER NOT NULL REFERENCES entity(id),
  role          TEXT    NOT NULL,   -- 'asset' | 'threat' | 'vulnerability' | 'control'
  PRIMARY KEY (finding_id, entity_id, role)
);

-- ── Recommendations and acceptance ─────────────────────────────────
CREATE TABLE recommendation (
  id                INTEGER PRIMARY KEY,
  finding_id        INTEGER NOT NULL REFERENCES finding(id),
  safeguard_entity  INTEGER REFERENCES entity(id),
  description       TEXT NOT NULL,
  cost_estimate     TEXT,
  effort            TEXT,
  projected_level   INTEGER,        -- residual risk if implemented
  control_refs      TEXT CHECK (control_refs IS NULL OR json_valid(control_refs)),
                                    -- ITSG-33 / 800-53 control ids: the bridge
  priority          INTEGER
);

CREATE TABLE risk_decision (
  id              INTEGER PRIMARY KEY,
  finding_id      INTEGER NOT NULL REFERENCES finding(id),
  disposition     TEXT NOT NULL CHECK (disposition IN ('accept','mitigate','transfer','avoid')),
  rationale       TEXT NOT NULL,
  accepted_by     INTEGER REFERENCES user(id),
  accepted_role   TEXT,             -- 'business_owner' | 'cio' | 'ciso'
  accepted_at     TEXT,
  valid_until     TEXT,
  UNIQUE (finding_id)
);

-- ── AI provenance: every machine-suggested value is reviewable ─────
CREATE TABLE ai_suggestion (
  id            INTEGER PRIMARY KEY,
  project_id    INTEGER NOT NULL REFERENCES project(id),
  target_table  TEXT    NOT NULL,
  target_id     INTEGER,
  field         TEXT    NOT NULL,
  suggested     TEXT    NOT NULL,
  confidence    REAL,
  rationale     TEXT,
  model         TEXT    NOT NULL,
  source_doc_id INTEGER,            -- the uploaded architecture document
  source_quote  TEXT,               -- the passage it was drawn from
  status        TEXT    NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','accepted','edited','rejected')),
  reviewed_by   INTEGER REFERENCES user(id),
  reviewed_at   TEXT,
  created_at    TEXT    NOT NULL
);
```

### 5.1 SQLite and Azure notes

- The database file must live under `/home` on Azure App Service — that is the
  only persisted path. **VERIFY** where the existing connection points.
- Enable `PRAGMA journal_mode=WAL` and `PRAGMA foreign_keys=ON` on every
  connection. The matrix engine is read-heavy, so WAL is a clear win.
- `better-sqlite3` is synchronous: wrap each multi-row write in a transaction
  (`db.transaction(fn)`) and never interleave an `await` inside one.
- Matrix lookups are plain indexed reads. Do not cache them in application
  memory across requests — App Service scales out and a stale matrix is a
  wrong risk rating.

## 6. AI integration

AI is where this gets genuinely good rather than merely compliant, because the
intake document you already parse for control scoping contains almost everything
HTRA's first two phases need.

| Extract from the uploaded architecture / design document | Feeds |
|---|---|
| Data types, classification markings, personal-information indicators | Asset register + injury categories |
| Components, data stores, integrations, hosting model | Asset register (`it_component`, `service`) |
| Internet exposure, user populations, trust boundaries, auth model | Threat likelihood inputs |
| Stated or planned controls | Vulnerability severity, and the control bridge |
| Business criticality, SLA or availability language | Availability injury |

Three rules for the AI layer:

1. **Suggest, never assert.** Every machine-derived value lands in
   `ai_suggestion` with `status = 'pending'` and must be accepted, edited or
   rejected by a human before it reaches `valuation` or `entity`. A TRA is a
   signed document; an unreviewed injury rating is a liability. The UI should
   show a clear "AI suggested — review" state (see the mockups).
2. **Cite the source.** Store `source_quote` and surface it on hover. "Why does
   it think this is Protected B?" must be answerable in one click.
3. **Draft the prose, not the numbers.** AI is well suited to drafting threat
   narratives and the TRA report's descriptive sections, and poorly suited to
   choosing a severity on a published 1–N scale. Let it propose with rationale;
   make the human own the number.

Also useful, and cheap once the above exists: an AI pass that reads the completed
risk register and proposes `recommendation` rows mapped to ITSG-33 control ids —
this is the asset→threat→vulnerability→**control** bridge, generated.

## 7. Implementation phases

Pause for review after each. Each phase ships something usable.

**Phase 1 — Method registry** *(small)*
Add `method_type`; backfill existing frameworks to `control_compliance`; add
`method_definition`, `method_scale`, `method_scale_level`, `method_matrix`,
`method_matrix_cell`, `assessment_method`. Build the definition loader + JSON
schema validator. No UI yet.
*Done when:* HTRA can be seeded as a draft method and read back, and every
existing assessment still behaves identically.

**Phase 2 — Derivation engine** *(small, high value)*
Matrix lookup + the whitelisted expression interpreter. Pure functions, no DB
coupling, exhaustively unit-tested.
*Done when:* given a seeded matrix set, every input combination returns the
published output, and malformed/hostile expressions are rejected without
executing.

**Phase 3 — Entities, assets, statement of sensitivity** *(the real new surface)*
`entity`, `entity_link`, `valuation`. Assessment sub-step UI for the asset
register and SoS grid. Svelte is the right call for the SoS grid — it is dense,
inline-edited and reactive.
*Done when:* a user can build an asset register by hand and value every asset
across C/I/A with a required rationale.

**Phase 4 — Threats and residual risk** *(core)*
Threat catalogue seeded from TRA-1's taxonomy (deliberate / accidental /
natural — note HTRA is all-hazards, so it must not be cyber-only).
Threat assessment sub-step; vulnerability capture with control linkage; residual
risk computed through Phase 2 with the full derivation trace stored in
`finding.computed`.
*Done when:* every asset-threat pair is assessed or explicitly excluded with a
reason, and each residual risk can show its own arithmetic.

**Phase 5 — Decision package integration** *(small)*
`recommendation`, `risk_decision`. Render findings from both method types in the
existing decision package. Add the TRA report, SoS and risk register as
Handlebars deliverable templates.
*Done when:* a decision package for a project scoping both ITSG-33 and HTRA
shows control gaps and residual risks together, and the TRA report renders.

**Phase 6 — AI assist** *(the differentiator)*
`ai_suggestion` table, extraction prompts, review UI.
*Done when:* uploading a CRM architecture document produces a reviewable draft
asset register and injury valuations with cited source passages.

**Phase 7 — Method recommendation at intake** *(small)*
Extend the existing control-scoping engine from "which controls" to "which
methods and controls". Rules over intake answers — GC department, PROTECTED B,
new system of record, SA&A required → propose `ITSG-33 PBMM + HTRA`, with
`scoped_reason` recorded.
*Done when:* an ERP intake proposes both methods and explains why.

## 8. Acceptance criteria for the module as a whole

- A project can scope zero, one or many methods of either type.
- The project stage machine is unchanged; no new top-level stages exist.
- Every existing control-compliance assessment produces byte-identical output
  to before this work.
- Scales and matrices are data: changing a cell in `method_matrix_cell` changes
  every subsequently computed rating, with no code deploy.
- Every residual risk can display its full derivation chain on demand.
- Traceability is queryable end to end: asset → threat → vulnerability →
  control → residual risk → acceptance.
- No AI-suggested value reaches a published artifact without a recorded human
  review.
- Seeding a second `risk_analysis` method (ISO 27005, as a test) requires a new
  definition row and templates — **no new application code**. This is the real
  test of whether the abstraction worked.

## 9. Traps — do not do these

- **Do not promote HTRA's phases to top-level project stages.** They are
  assessment sub-steps declared by the method.
- **Do not normalise HTRA's risk bands into an existing global risk score.**
  An HTRA "Medium" and an ISO 27005 "Medium" are different objects. Keep
  method-native scoring and display native labels. A cross-method portfolio
  rollup, if wanted, is a separate derived view explicitly labelled approximate.
- **Do not "improve" the arithmetic.** Multiplying ordinal scales is
  mathematically shaky and the temptation to fix it is real. Resist: assessors
  compare output to the published tables. Report the official band; do not
  expose a raw product that implies precision the method lacks.
- **Do not hard-code the scales or matrices.** Departments tweak them, and
  ITSG-33's successor (ITSP.10.035) brings a different set.
- **Do not make the threat catalogue cyber-only.** HTRA covers deliberate,
  accidental and natural hazards against assets, services *and people*.
- **Do not `eval` method definitions.** See §4.3.
- **Do not let AI write a severity straight into `valuation`.** See §6.

## 10. Context worth carrying

- **HTRA ≠ ITSG-33.** ITSG-33 (*IT Security Risk Management: A Lifecycle
  Approach*, CSE, 2012) is a framework and control catalogue — the Canadian
  analogue of NIST RMF + SP 800-53. HTRA/TRA-1 (CSE + RCMP, 2007) is an
  assessment methodology — closer to NIST SP 800-30. They are complementary
  layers: CSE's own training course is titled *"HTRA Methodology **within** the
  ITSG-33."* HTRA produces the risk analysis that justifies the ITSG-33 control
  profile you selected.
- **ITSG-33 is being superseded** by the ITSP.10.035 / .036 / .037 series,
  which broadens scope to OT and privacy. Departments are mid-transition, so
  both must be supportable — another reason methods are data.
- **Deliverable quality is the product.** GC users are judged on a TRA document
  in the expected structure. Report rendering is a first-class feature, not an
  export afterthought.
- **Bilingual output (EN/FR)** is a real requirement for GC deliverables.
  Keep method labels, scale level labels and templates translatable from the
  start — retrofitting i18n through a method definition is painful.
- **Classification handling:** a completed TRA is itself typically PROTECTED B.
  Reports need classification markings, and the app should carry a
  classification attribute on the project and stamp rendered artifacts.

---

*Companion artifacts: the architecture and process diagrams, and the UI mockups
for each sub-step and deliverable, accompany this brief.*
