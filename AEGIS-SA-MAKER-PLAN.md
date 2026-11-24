# Aegis SA Maker — Platform Configuration Plan

> **Status: design only.** Nothing here is to be implemented yet. This document
> supersedes the sequencing in `AEGIS-SA-HTRA-AGENT-PROMPT.md` and
> `AEGIS-SA-GC-ARTIFACTS-PLAN.md`; both remain valid as *domain content* and are
> reused here as Chapters A and B. Where this plan and those briefs disagree on
> **how** something is built, this plan wins. Where they disagree on **what HTRA
> or GC practice requires**, those briefs win.

---

## 0. Agent instructions

This is a plan, not a work order. If you are a coding agent reading this:

1. **Do not start building.** The open decisions in §17 must be answered first,
   and three of them change the schema.
2. When work does begin, Phase 0 produces a metamodel specification and a
   decision log — no code.
3. The rule that governs every later decision is in §1.3. If an implementation
   choice would break it, stop and raise it.

---

## 1. Position

### 1.1 The direction is right

Aegis SA already proved the pattern once. The HTRA work concluded that control
frameworks and risk methodologies are different *method types* over a shared
metamodel, and that HTRA's phases are method-declared sub-steps rather than new
stages. Everything in this document is that same idea applied to fields,
artifacts, rules and views instead of only to methods and scales.

The commercial case is also real: security assessment practice differs by
department, by framework edition, and by year. A tool that needs a release to
follow a tailored profile loses to one that needs a configuration change.

### 1.2 Three risks worth naming before the roadmap

**The authoring UI is not the hard part, and building it first is the classic
failure.** A visual editor over an unproven metamodel produces a metamodel shaped
by what was easy to draw. Build the engine, express HTRA as the first blueprint,
express the GC control extension as the second, and only then build the editor —
by which point you know what the editor must do.

**Upgrading a template the customer has edited is the feature that kills
platforms like this.** Ship v1 of a GC blueprint, customers tailor it, then you
publish v2. Without a real three-way merge and a conflict report, you either
clobber their work or you can never ship an update again. §6.4 treats this as a
first-class problem; it is Phase 6, not a footnote.

**Configurable must not become programmable.** The moment a rule or a report can
run arbitrary code, you inherit every customer's bugs and their security
exposure, and an admin screen becomes remote code execution. §1.3.

### 1.3 The governing rule

> **A fixed metamodel with configurable instances. Configuration selects and
> parameterizes from a vocabulary the platform defines; it never invents new
> kinds of things, and it never executes code.**

Concretely: a blueprint may declare a new *field*, but not a new *field type*. A
new *step*, but not a new *stage*. A new *rule*, but only from the action verbs in
§7.3. A new *report*, but rendered by a sandboxed template engine with a helper
whitelist. Every extension point is an enumeration the platform owns.

This is what keeps the system testable, upgradeable and safe. It is also the only
reason a plan this large is achievable at all.

### 1.4 Naming

Proposed, and worth settling in Phase 0 because it lands in the API namespace and
is expensive to change later:

- **Maker** — the authoring workspace where configuration is built.
- **Blueprint** — the installable, versioned package of configuration. (Alternatives
  considered: Pack, Kit, Module, Profile. "Template" is avoided because it will
  collide with *artifact template*, which is a different thing.)
- **Definition** — one configured object inside a blueprint (a field, a step, a rule).
- **Effective configuration** — the resolved result of all blueprints and local
  edits applying at a given scope.

Used consistently below.

---

## 2. The metamodel

Twelve definition types. This list is the vocabulary; adding a thirteenth is a
platform release, not a configuration change.

| Definition type | What it configures | Attaches to |
|---|---|---|
| `entity_type` | Labels and classes over a **fixed** base vocabulary: `asset`, `threat`, `vulnerability`, `safeguard`, `control`, `control_scope`, `finding`, `poam_item`, `component`, `interconnection`, `artifact` | — |
| `field` | A custom field on an entity type: type, label, help, validation, required-when, indexed | `entity_type` |
| `field_group` | Ordered grouping of fields for forms and reports | `entity_type` |
| `scale` | Named ordinal scale with levels, labels, descriptions, severity token | — |
| `matrix` | Two-input lookup producing a scale value | `scale` × 3 |
| `derivation` | Computed value: matrix lookup or whitelisted expression | `field` |
| `step` | A sub-step inside an existing stage: title, ordinal, required fields, completion predicate | `stage` |
| `rule` | Event → condition → bounded actions (§7) | `entity_type`, `step`, `stage` |
| `artifact_template` | A renderable document | `entity_type` scope |
| `artifact_fragment` | A **patch** into an existing artifact template: a column, a section, a row group (§8.2) | `artifact_template` |
| `view` | List, grid or form layout: columns, filters, sort, inline-edit behaviour | `entity_type` |
| `prompt` | An AI prompt bound to a field and a purpose (§9) | `field` |
| `seed` | Reference data: control catalogues, threat taxonomies, injury categories | `entity_type` |

Plus one non-configurable anchor: **stages stay fixed** at intake → assessment →
decision package → close, with close non-terminal per the GC plan. Steps hang off
stages; stages are platform code.

### 2.1 Field types

The enumeration. A blueprint picks from this list and cannot extend it:

`text` · `long_text` · `number` · `integer` · `boolean` · `date` ·
`select` (options or `seed` reference) · `multi_select` · `scale_value`
(references a `scale`) · `entity_ref` (references another entity type) ·
`user_ref` · `document_ref` · `computed` (references a `derivation`) ·
`rich_text` · `url` · `money` · `duration`

Two types carry special behaviour worth noting: `scale_value` is what makes
Met/Partially Met/Not Met, injury severity and residual risk the same kind of
object, and `computed` is the only field type that cannot be written directly.

---

## 3. Storage design

### 3.1 The decision

Custom fields live in a JSON column per extensible table, with **SQLite virtual
generated columns and expression indexes** created at install time for fields the
blueprint declares as indexed.

```sql
-- one of these per extensible table
ALTER TABLE control_scope ADD COLUMN custom TEXT
  CHECK (custom IS NULL OR json_valid(custom));

-- at blueprint install, for each field with indexed = true:
ALTER TABLE control_scope
  ADD COLUMN cf_impl_statement TEXT
  GENERATED ALWAYS AS (json_extract(custom, '$.impl_statement')) VIRTUAL;
CREATE INDEX ix_cs_impl_statement ON control_scope(cf_impl_statement);
```

Why this and not the alternatives:

- **Not EAV.** A key-value table turns every list view into a pivot and every
  filter into a self-join. At the row counts a control assessment produces
  (hundreds of controls × dozens of fields × many projects) it degrades fast and
  the queries become unreadable.
- **Not per-blueprint tables.** Installing configuration would mean DDL per
  tenant per blueprint, and cross-blueprint reports would need dynamic SQL.
- **JSON + expression indexes** keeps one schema, one query shape, and gives
  indexed access exactly where declared.

### 3.2 SQLite constraints to design around

- `ALTER TABLE ADD COLUMN` accepts **VIRTUAL** generated columns but **not
  STORED**. Use VIRTUAL and index it; the index materializes the value.
- Indexes cost writes. **Cap indexed custom fields per table** — twelve is a
  sensible starting limit — and make the Maker refuse the thirteenth with a clear
  message rather than silently degrading.
- **Any field used in a view filter or sort must be declared indexed.** Enforce
  this at blueprint validation, not at runtime: an unindexed filter is a full
  table scan that only shows up in production.
- Single writer. Rule cascades and artifact rendering go through a queue (§7.4),
  not inline in the request.

### 3.3 The Postgres door

The metamodel is storage-agnostic and this design ports directly: `jsonb`,
expression indexes, generated columns. Do not migrate now. Do keep two things
true so the door stays open — no SQLite-only SQL in the definition resolver, and
all JSON access through one accessor module. Revisit when either workspace count
or concurrent assessment writers makes the single-writer limit visible; a
**database file per workspace** is the cheap intermediate step and fits Azure App
Service well.

### 3.4 Never destroy data on uninstall

Uninstalling a blueprint marks its fields **orphaned** and hides them from views.
It does not drop the JSON keys, the indexes or the artifacts. Orphaned data is
restored if the blueprint is reinstalled, and is listed in a workspace report so
an administrator can purge deliberately. A configuration platform that loses
assessment data on an uninstall is unusable in a regulated setting.

---

## 4. Scopes and resolution

### 4.1 Scope ladder

`workspace` → `program` → `project` → `assessment`

A blueprint installs at any level. `program` is optional and exists because
departments group systems; include the level now even if the UI hides it, since
adding a ladder rung later invalidates every stored resolution.

### 4.2 Merge semantics per definition type

Resolution is most-specific-wins by default, but several types must union
instead. This table is the contract:

| Type | Semantics |
|---|---|
| `field`, `field_group` | **Union.** Same key at two scopes is an error unless the narrower one is a declared `override`. |
| `step` | **Union**, ordered by `(ordinal, blueprint_id)`; dedupe by key; a narrower scope may disable one. |
| `scale`, `matrix`, `derivation` | **Most specific wins**, whole-object. Never field-by-field merged — a half-merged scale is incoherent. |
| `artifact_template` | **Most specific wins.** |
| `artifact_fragment` | **All apply**, ordered by `(scope specificity, declared order, blueprint_id)`. Order must be stable or reports change between renders. |
| `rule` | **All apply**, ordered by `priority`; a narrower scope may disable by key. |
| `view` | **Most specific wins**, with an explicit `extends` to inherit columns. |
| `prompt` | **Most specific wins.** |
| `seed` | **Union**, keyed; narrower scope may add rows and deactivate rows, never edit a row in place. |

### 4.3 Effective configuration and its hash

Resolution is computed once and materialized:

```sql
CREATE TABLE effective_config (
  id            INTEGER PRIMARY KEY,
  scope_kind    TEXT NOT NULL,     -- 'workspace' | 'program' | 'project' | 'assessment'
  scope_id      INTEGER NOT NULL,
  config_hash   TEXT NOT NULL,     -- stable hash over the resolved definition set
  resolved      TEXT NOT NULL CHECK (json_valid(resolved)),
  computed_at   TEXT NOT NULL,
  UNIQUE (scope_kind, scope_id, config_hash)
);
```

`config_hash` is the keystone of this whole design and pays for itself three
times:

1. **Reproducibility.** Every rendered artifact stores the `config_hash` that
   produced it, so "which configuration generated this SAR?" is answerable.
2. **Staleness.** Combined with the `content_hash` from the GC plan, the app can
   distinguish *the data changed* from *the configuration changed* — two very
   different reasons a report is out of date.
3. **Cache correctness.** Resolution is expensive and read constantly; the hash
   is the cache key, and it changes exactly when it should.

---

## 5. Steps: generalizing the HTRA mechanism

The HTRA brief established that a method declares sub-steps rendered inside the
assessment stage. Maker generalizes that to all four stages and to any entity.

```json
{
  "type": "step",
  "key": "control_responsibility",
  "stage": "assessment",
  "ordinal": 25,
  "title": { "en": "Control responsibility", "fr": "Responsabilité des contrôles" },
  "entity_type": "control_scope",
  "view": "control_responsibility_grid",
  "required_fields": ["responsibility", "inherited_from"],
  "complete_when": {
    "all": [
      { "field": "responsibility", "op": "is_set" },
      { "any": [
          { "field": "responsibility", "op": "neq", "value": "inherited" },
          { "field": "inherited_from", "op": "is_set" }
      ]}
    ]
  },
  "visible_when": { "field": "project.hosting", "op": "in", "value": ["iaas","paas","saas"] }
}
```

Three properties matter. `complete_when` is a predicate, not a flag, so progress
is derived rather than tracked. `visible_when` means a step can be conditional —
the cloud responsibility step simply does not appear for an on-premises system.
And `ordinal` with gaps of ten lets blueprints interleave steps without
renumbering each other.

---

## 6. Blueprints

### 6.1 Manifest

```json
{
  "key": "gc-itsg33-satra",
  "name": { "en": "GC — ITSG-33 with HTRA", "fr": "GC — ITSG-33 avec EMR" },
  "version": "2.1.0",
  "publisher": "aegis-first-party",
  "metamodel_version": "1.x",
  "installable_at": ["workspace", "program", "project"],
  "requires": [{ "key": "core-controls", "version": ">=1.4.0 <2.0.0" }],
  "conflicts_with": ["gc-itsg33-legacy"],
  "definitions": "./definitions/",
  "migrations": "./migrations/",
  "capabilities_required": ["ai_suggestions", "artifact_rendering"]
}
```

`metamodel_version` is the compatibility gate: a blueprint declares which
platform vocabulary it was authored against, and the platform refuses to install
one it cannot interpret. Without this field you cannot ever evolve the metamodel.

### 6.2 Definition provenance

Every stored definition records where it came from. This is what makes upgrades
tractable:

```sql
CREATE TABLE definition (
  id              INTEGER PRIMARY KEY,
  scope_kind      TEXT NOT NULL,
  scope_id        INTEGER NOT NULL,
  type            TEXT NOT NULL,      -- 'field' | 'step' | 'rule' | ...
  key             TEXT NOT NULL,
  body            TEXT NOT NULL CHECK (json_valid(body)),
  source          TEXT NOT NULL CHECK (source IN ('blueprint','local','override')),
  blueprint_id    INTEGER REFERENCES blueprint_install(id),
  base_version    TEXT,               -- blueprint version this came from
  disabled        INTEGER NOT NULL DEFAULT 0,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL,
  UNIQUE (scope_kind, scope_id, type, key, source)
);
```

An `override` row stores **only the changed properties** — a patch, not a copy.
That distinction is what makes the merge in §6.4 possible: a full copy loses the
information about what the user actually intended to change.

### 6.3 Lifecycle

`draft` → `validated` → `published` → `installed` → `upgraded` → `deprecated`

Validation runs before publish and is strict: schema conformance, referential
integrity across definitions, no cyclic derivations, indexed-field cap respected,
every view filter field indexed, every template compiles, every rule's actions in
the verb set, bounded cascade depth, and all i18n keys present for both EN and FR.
A blueprint that fails validation cannot be published, let alone installed.

### 6.4 Upgrade: the three-way merge

This is the hardest problem in the plan. Treat it as such.

```
base v1  ──────────────►  base v2          (what the publisher changed)
   │                          │
   │ user overrides           │ re-apply
   ▼                          ▼
local state  ─────────►  merged state  +  conflict list
```

Procedure:

1. **Dry run first, always.** Produce a report before anything changes:
   definitions added / changed / removed; overrides that still apply cleanly;
   overrides in conflict; data migrations required; artifacts whose
   `config_hash` will change and therefore need re-rendering.
2. **Classify each override.** Clean if it touches properties v2 left alone.
   Conflicting if v2 changed or removed the same property.
3. **Block activation on unresolved conflicts.** Present each with three choices:
   keep mine, take theirs, or edit the merged result. Never silently drop an
   override — a dropped tailoring rationale is a compliance failure, not a
   cosmetic one.
4. **Apply within a transaction**, bump `config_hash`, mark affected artifacts
   stale, and write the whole operation to the configuration audit log.

### 6.5 Data migrations are declared, never inferred

Some configuration changes invalidate stored data, and the platform must refuse
to guess. The dangerous ones:

- **A scale's level count changes.** Every stored `scale_value` references a level
  by number. Going from five levels to four requires an explicit mapping
  (`{5:4, 4:3, 3:3, 2:2, 1:1}`), declared in the migration. Without one, the
  upgrade is rejected.
- **A field is renamed or retyped.** Declare the JSON key move and the value
  coercion; a failed coercion aborts the migration rather than storing junk.
- **A matrix cell changes.** Existing findings keep their stored
  `finding.computed` trace, which is why that trace exists. New computations use
  the new cell. The migration declares whether historical findings are
  recomputed — default **no**, because a signed artifact's numbers must not move
  under it.

That last default is worth stating in the UI: *changing this matrix will not
alter findings already assessed.*

---

## 7. The rules engine

### 7.1 Shape

```json
{
  "type": "rule",
  "key": "gate_mfa_before_production_data",
  "priority": 100,
  "on": { "event": "stage.transition_requested", "from": "decision_package", "to": "close" },
  "when": {
    "all": [
      { "field": "project.has_production_data", "op": "eq", "value": true },
      { "exists": { "entity": "poam_item", "where":
          { "all": [ { "field": "control_refs", "op": "contains", "value": "IA-2" },
                     { "field": "status", "op": "eq", "value": "open" } ] } } }
    ]
  },
  "then": [
    { "action": "block_transition",
      "message": { "en": "Client-facing MFA (IA-2) is an open POA&M item and production data is present.",
                   "fr": "..." } }
  ]
}
```

### 7.2 Events

`entity.created` · `entity.updated` · `field.changed` · `step.completed` ·
`step.reopened` · `determination.set` · `finding.computed` ·
`stage.transition_requested` · `stage.entered` · `artifact.rendered` ·
`artifact.stale` · `approval.granted` · `schedule.due` · `suggestion.reviewed`

### 7.3 Action verbs — the complete set

`set_field` · `require_field` · `block_transition` · `request_transition` ·
`create_record` · `open_poam_item` · `require_approval` · `assign` ·
`render_artifact` · `mark_artifact_stale` · `notify` · `schedule_review` ·
`flag_contradiction` · `request_ai_suggestion` · `write_audit_note`

Nothing else. Adding a verb is a platform release. A rule cannot call out to a
URL, run a script, or alter configuration.

### 7.4 Safety properties

- **No code execution.** Conditions are a predicate AST interpreted by the same
  whitelisted evaluator as derivations — one interpreter, one audit surface.
- **Bounded cascades.** Maximum depth three, with cycle detection on
  `(rule_key, entity_id)`. Exceeding the bound aborts the transaction and logs;
  it does not partially apply.
- **Queued, not inline.** Cascades and rendering run through a job queue, which
  also respects SQLite's single writer.
- **Every execution logged.** `rule_execution` stores rule key, event, inputs,
  matched condition, actions taken, and `config_hash`. This is the same
  defensibility argument as AI provenance: a state change nobody can explain is
  worse than no automation.
- **Simulate mode.** Run the rule set against a project snapshot and report what
  *would* happen, changing nothing. This is a shipping requirement, not a nicety —
  it is how an administrator gains the confidence to enable a gate.

### 7.5 The boundary rules must not cross

A rule may **gate** a transition and may **request** one. It may not invent a
stage, skip the stage order, or grant an authorization. Authorization stays a
human act with a recorded signature, for the reasons in the HTRA brief's §11.4.

---

## 8. Artifacts

### 8.1 Templates

Sandboxed Handlebars: precompiled at install, a helper whitelist, no runtime
partial resolution from disk, no filesystem or process access. **Strict mode** —
an undefined value renders an explicit marker, never a blank. That directly
implements the GC plan's rule that a blank SRTM cell is read by an assessor as
either "not applicable" or "not done", and guessing wrong fails an audit.

### 8.2 Fragments — extending a report you did not write

This is the mechanism behind "choosing a template should update existing reports
to include the new fields". A template declares named anchors; a fragment patches
one.

```json
{
  "type": "artifact_fragment",
  "key": "srtm_add_responsibility",
  "target_template": "srtm",
  "patches": [
    { "kind": "table_column",
      "target": "srtm.control_rows",
      "after": "control",
      "header": { "en": "Responsibility", "fr": "Responsabilité" },
      "cell": { "field": "control_scope.responsibility" },
      "width": "narrow" },
    { "kind": "section",
      "target": "srtm.preamble",
      "position": "after",
      "content_template": "fragments/srtm-inheritance-note" }
  ]
}
```

Patch kinds: `table_column` · `section` · `row_group` · `summary_tile` ·
`footnote` · `signature_block`. Each is a structural operation the renderer
understands — not a string substitution, which would break the moment the base
template was reformatted.

Ordering is deterministic per §4.2. Fragments are additive only: a fragment may
not remove a column from a base template, because a blueprint author cannot know
what a downstream regulator needs. To get a different report, override the
template.

---

## 9. AI in a configurable world

The HTRA brief's §11 established that Aegis SA already has a suggest-then-confirm
provenance record and that HTRA must extend it rather than duplicate it. Maker
generalizes it a third time: AI becomes configurable per field.

```json
{
  "type": "prompt",
  "key": "draft_implementation_statement",
  "field": "control_scope.implementation_statement",
  "purpose": "guidance",
  "inputs": {
    "documents": ["project.architecture_documents"],
    "fields": ["control.requirement_text", "control.guidance", "project.description"],
    "entities": ["component[in_boundary=true]"]
  },
  "output": { "kind": "long_text", "must_cite": true },
  "review": "required"
}
```

Four properties to hold onto:

- **`purpose`** is an enumeration — `guidance`, `justification`,
  `preliminary_determination`, `extraction`, `narrative` — so the platform knows
  which existing feature a prompt plugs into.
- **`inputs`** is declared, so the platform assembles context without bespoke
  code per prompt. This is what makes a new AI-assisted field a configuration
  change.
- **`must_cite`** and **`review`** are not optional for anything reaching a signed
  artifact. A blueprint cannot set `review: "none"` on a field that feeds an
  authorization instrument; validation rejects it.
- The provenance record gains **`config_hash`** and **`prompt_version`**. After a
  blueprint upgrade, "why did the model say that?" still has an answer.

---

## 10. REST API

### 10.1 Two surfaces

```
/api/v1/config/*     definitions, blueprints, install, dry-run, resolve, schema
/api/v1/data/*       projects, assessments, entities, findings, artifacts, rules
```

Separating them matters: configuration is low-volume and high-privilege, data is
the opposite. They deserve different rate limits, different scopes and probably
different audit retention.

### 10.2 The endpoint that makes SDKs possible

```
GET /api/v1/config/schema?scope=project:184
→ { "config_hash": "…",
    "entity_types": { "control_scope": { "json_schema": { … }, "views": [ … ] }, … },
    "scales": { … }, "steps": [ … ], "artifacts": [ … ] }
```

Because the schema is configuration, it must be *discoverable at runtime*. This
one endpoint is what the codegen in §11 consumes, what a UI renders forms from,
and what lets an integrator validate a payload before sending it.

### 10.3 Conventions

- **Concurrency:** `ETag` on every entity, `If-Match` required on write. With
  rules firing on update, last-write-wins would silently undo a gate.
- **Idempotency:** `Idempotency-Key` on POST, stored for 24h.
- **Pagination:** cursor, never offset.
- **Errors:** `application/problem+json`, with validation failures naming the
  definition key that rejected the value — an integrator needs to know *which
  configured rule* refused their payload.
- **Config echo:** every data response carries the `config_hash` it was served
  under, so a client can detect that configuration moved mid-session.
- **Auth:** OAuth 2.0 client credentials for service integrations, scoped API
  keys for simple cases; RBAC per scope, with configuration write as a distinct
  permission from data write.
- **Webhooks:** the §7.2 event list, signed, with replay.
- **Artifact render** is asynchronous: POST returns a job, GET polls, the result
  carries `config_hash` and `content_hash`.

---

## 11. SDKs

### 11.1 The shape dynamic schema forces

A configurable platform cannot ship a hand-written typed client — the types
depend on the customer's configuration. So each SDK is two layers:

**Core** (hand-written, stable): auth, retry with backoff, pagination,
concurrency headers, problem+json errors, webhook signature verification, and an
untyped escape hatch (`client.entities.raw('control_scope', …)`) for fields
discovered at runtime.

**Generated** (per workspace): typed models and accessors emitted from
`/config/schema`.

```bash
npx @aegis-sa/codegen --scope project:184 --out ./src/aegis
dotnet tool run aegis-codegen --scope project:184 --out ./Aegis
```

Regeneration is tied to `config_hash`: the generated code embeds the hash it was
built from, and the core layer warns at runtime when the server reports a
different one. That turns a confusing class of integration bug into a clear
message.

### 11.2 Targets

- **Node / TypeScript** — the reference implementation, since it matches the app.
- **.NET** — `IAegisClient` with DI registration, `System.Text.Json`,
  `CancellationToken` throughout, async streams for pagination.
- **Blueprint CLI** — `aegis blueprint init | validate | test | publish`. Because
  definitions are JSON, this lets power users keep blueprints in git with code
  review and CI validation. For enterprise buyers this is often the feature that
  closes the deal, and it is nearly free once validation exists as a service.

### 11.3 Golden-file testing

`aegis blueprint test` renders every artifact in a blueprint against a fixture
project and diffs the output against committed expectations. This is the only
practical way to keep a growing library of blueprints from silently breaking when
the engine changes, and it should exist from Phase 3 rather than being retrofitted.

---

# Chapter A — Configuring a method type from scratch: HTRA

This chapter shows what an administrator does in Maker to build HTRA with no
HTRA-specific application code. The domain detail — the real scales, the matrix
values, the TRA report structure — stays in `AEGIS-SA-HTRA-AGENT-PROMPT.md`.
What follows is the *mechanism*.

### A.1 Declare the entity types

HTRA needs four, all drawn from the fixed base vocabulary, relabelled and given
classes:

```json
[
  { "type": "entity_type", "key": "asset", "label": { "en": "Asset", "fr": "Bien" },
    "classes": ["information","it_component","facility","personnel","service"] },
  { "type": "entity_type", "key": "threat", "label": { "en": "Threat", "fr": "Menace" },
    "classes": ["deliberate","accidental","natural"] },
  { "type": "entity_type", "key": "vulnerability", "label": { "en": "Vulnerability", "fr": "Vulnérabilité" } },
  { "type": "entity_type", "key": "safeguard", "label": { "en": "Safeguard", "fr": "Mesure de protection" } }
]
```

Note what is *not* happening: no new tables, no new base types. The platform
already understands `asset`; the blueprint names it and constrains its classes.

### A.2 Declare the scales

```json
{ "type": "scale", "key": "injury_severity",
  "label": { "en": "Injury severity", "fr": "Gravité du préjudice" },
  "levels": [
    { "value": 1, "label": { "en": "Very low" }, "severity_token": "sev1" },
    { "value": 2, "label": { "en": "Low" },      "severity_token": "sev2" },
    { "value": 3, "label": { "en": "Medium" },   "severity_token": "sev3" },
    { "value": 4, "label": { "en": "High" },     "severity_token": "sev4" },
    { "value": 5, "label": { "en": "Very high" },"severity_token": "sev5" }
  ],
  "source_ref": "TRA-1 Annex — VERIFY against publication",
  "draft": true }
```

Five of these: `injury_severity`, `likelihood`, `gravity`,
`vulnerability_severity`, `risk_level`. The `draft: true` flag and `source_ref`
implement the discipline the HTRA brief insists on — a provisional scale is
visibly provisional in the UI until the published tables are loaded.

### A.3 Declare matrices and derivations

```json
{ "type": "matrix", "key": "threat_level",
  "input_a": "likelihood", "input_b": "gravity", "output": "threat_level_scale",
  "cells": [[1,1,1],[1,2,1],[1,3,2],[1,4,2],[1,5,3], "… 25 cells …"],
  "source_ref": "TRA-1 Table — VERIFY" }

{ "type": "derivation", "key": "residual_risk",
  "method": "matrix", "matrix": "risk_level",
  "inputs": ["asset_value", "exposure"],
  "field": "finding.level_value",
  "trace": true }
```

`trace: true` is what stores the full derivation chain in `finding.computed`, so
every rating can show its own arithmetic. Configuration, not code.

### A.4 Declare fields

On `asset`, the statement of sensitivity is three `scale_value` fields plus a
mandatory rationale each:

```json
[
  { "type": "field", "entity_type": "asset", "key": "injury_c",
    "field_type": "scale_value", "scale": "injury_severity",
    "label": { "en": "Confidentiality injury" }, "required": true, "indexed": true },
  { "type": "field", "entity_type": "asset", "key": "injury_c_rationale",
    "field_type": "long_text", "required_when": { "field": "injury_c", "op": "is_set" },
    "label": { "en": "Rationale" } }
]
```

`required_when` is how the brief's rule — *a rationale is required on every
value, it is what gets defended* — becomes a declaration rather than a hand-coded
validator.

### A.5 Declare steps

Three, all in the assessment stage, at ordinals 10 / 20 / 30 so a later blueprint
can interleave:

```json
[
  { "type": "step", "key": "htra_assets", "stage": "assessment", "ordinal": 10,
    "title": { "en": "Assets & statement of sensitivity" },
    "entity_type": "asset", "view": "sos_grid",
    "complete_when": { "every": { "entity": "asset",
      "satisfies": { "all": [ { "field": "injury_c", "op": "is_set" },
                              { "field": "injury_i", "op": "is_set" },
                              { "field": "injury_a", "op": "is_set" } ] } } } },
  { "type": "step", "key": "htra_threats", "stage": "assessment", "ordinal": 20, "…": "…" },
  { "type": "step", "key": "htra_risk",    "stage": "assessment", "ordinal": 30, "…": "…" }
]
```

### A.6 Declare the views

`sos_grid` is the dense inline-edit grid the HTRA mockups show — a `view`
definition naming columns, inline-edit behaviour and the AI-suggestion affordance.
The platform renders it; the blueprint describes it.

### A.7 Declare artifacts

Three `artifact_template` definitions — `tra_report`, `statement_of_sensitivity`,
`risk_register` — each a sandboxed template over the resolved entities, plus the
`signature_block` anchors the authorization flow needs.

### A.8 Declare prompts

Four `prompt` definitions, all `review: "required"` and `must_cite: true`: draft
asset identification from the architecture document, propose injury valuations,
draft threat narratives, draft the TRA report's descriptive sections. Each plugs
into the existing suggest-then-confirm feature by its `purpose`.

### A.9 Declare one rule, to earn the contradiction check

The HTRA brief's two-way bridge — a Very High residual risk on a vulnerability
whose linked controls all read Met means one assessment is wrong — is a rule, not
a feature:

```json
{ "type": "rule", "key": "flag_risk_control_contradiction",
  "on": { "event": "finding.computed" },
  "when": { "all": [
    { "field": "finding.level_value", "op": "gte", "value": 4 },
    { "every": { "entity": "control_scope", "related_via": "mitigates",
                 "satisfies": { "field": "determination", "op": "eq", "value": "met" } } } ] },
  "then": [
    { "action": "flag_contradiction",
      "message": { "en": "Residual risk is High or above while every linked control reads Met. One assessment is wrong." } },
    { "action": "write_audit_note" } ] }
```

**This is the payoff.** That check was a bespoke feature in the earlier plan. Here
it is nine lines of configuration, a customer can tune the threshold, and a
customer who disagrees can disable it at their scope.

---

# Chapter B — Extending the control model: GC fields and reports

Chapter A built a new method. This chapter does the harder and more common thing:
**extend an entity and an artifact that already exist**, which is what "choosing
a template should add these control fields and update the existing reports" means
in practice.

### B.1 The fields

The five from the GC plan, declared on the existing `control_scope` entity:

```json
[
  { "type": "field", "entity_type": "control_scope", "key": "implementation_statement",
    "field_type": "long_text", "indexed": false,
    "label": { "en": "Implementation statement", "fr": "Énoncé de mise en œuvre" },
    "help": { "en": "How this control is satisfied, in prose. This is what an assessor reads." } },

  { "type": "field", "entity_type": "control_scope", "key": "responsibility",
    "field_type": "select", "indexed": true, "required": true,
    "options": ["customer","provider","shared","inherited"],
    "default": "customer" },

  { "type": "field", "entity_type": "control_scope", "key": "inherited_from",
    "field_type": "entity_ref", "ref_entity_type": "provider_assessment", "indexed": true,
    "required_when": { "field": "responsibility", "op": "in", "value": ["provider","inherited"] } },

  { "type": "field", "entity_type": "control_scope", "key": "assessment_method",
    "field_type": "multi_select", "options": ["examine","interview","test"], "indexed": true },

  { "type": "field", "entity_type": "control_scope", "key": "tailoring",
    "field_type": "select", "indexed": true,
    "options": ["baseline","added","removed","modified","compensating"], "default": "baseline" },

  { "type": "field", "entity_type": "control_scope", "key": "tailoring_rationale",
    "field_type": "long_text",
    "required_when": { "field": "tailoring", "op": "neq", "value": "baseline" } }
]
```

Two things to notice. `required_when` on `inherited_from` encodes the rule that an
inherited control must say what it is inherited *from* — the thing that makes a
cloud SAR defensible. And `indexed` is set deliberately: `implementation_statement`
is long prose nobody filters on, so it stays out of the index budget, while the
four short fields that drive views and report counts are indexed.

### B.2 The new report: SAR

An `artifact_template` for the Security Assessment Report, with anchors declared
so later blueprints can patch it:

```json
{ "type": "artifact_template", "key": "sar",
  "name": { "en": "Security Assessment Report", "fr": "Rapport d'évaluation de la sécurité" },
  "entity_scope": "assessment",
  "template": "templates/sar",
  "anchors": ["preamble","scope","methodology","control_rows","findings","provenance","signatures"],
  "requires_fields": ["control_scope.implementation_statement","control_scope.assessment_method"],
  "classification_marked": true,
  "languages": ["en","fr"] }
```

`requires_fields` is the dependency declaration that makes the install-time
behaviour correct: installing this blueprint cannot produce a SAR template
without also installing the fields it reads, and validation enforces it.

### B.3 The interesting part: patching reports that already exist

The SRTM and the POA&M already exist. This blueprint does not fork them — it
patches them:

```json
[
  { "type": "artifact_fragment", "key": "srtm_control_columns",
    "target_template": "srtm",
    "patches": [
      { "kind": "table_column", "target": "srtm.control_rows", "after": "control",
        "header": { "en": "Implementation statement" },
        "cell": { "field": "control_scope.implementation_statement", "truncate": 280 } },
      { "kind": "table_column", "target": "srtm.control_rows", "after": "evidence",
        "header": { "en": "Method" },
        "cell": { "field": "control_scope.assessment_method" } },
      { "kind": "table_column", "target": "srtm.control_rows", "after": "method",
        "header": { "en": "Responsibility" },
        "cell": { "field": "control_scope.responsibility" } }
    ] },

  { "type": "artifact_fragment", "key": "sar_inheritance_summary",
    "target_template": "sar",
    "patches": [
      { "kind": "summary_tile", "target": "sar.scope",
        "label": { "en": "Self-assessed" },
        "value": { "count": "control_scope", "where": { "field": "responsibility", "op": "in", "value": ["customer","shared"] } } },
      { "kind": "summary_tile", "target": "sar.scope",
        "label": { "en": "Inherited" },
        "value": { "count": "control_scope", "where": { "field": "responsibility", "op": "in", "value": ["provider","inherited"] } } },
      { "kind": "footnote", "target": "sar.scope",
        "content": { "en": "Self-assessed and inherited counts are reported separately and are never summed." } }
    ] }
]
```

**That fragment list is the answer to the original question.** An administrator
picks "GC control extension" in Maker; the fields appear on the control form, and
the SRTM they were already producing grows three columns while the SAR grows two
summary tiles and a footnote. No forked templates, no release.

### B.4 The step

One new assessment step at ordinal 25 — between HTRA's threats (20) and risk (30)
— shown in §5 above, conditional on the project being cloud-hosted.

### B.5 The prompt

One `prompt` on `implementation_statement`, `purpose: "guidance"`, inputs drawn
from the architecture documents and the control requirement text, `must_cite:
true`, `review: "required"`. This is the single highest-value AI binding in the
product: it drafts the field an assessor actually reads, and it reuses the feature
that already exists.

### B.6 The rules

Two gates, both configuration:

```json
[
  { "type": "rule", "key": "require_inheritance_evidence",
    "on": { "event": "step.completed", "step": "control_responsibility" },
    "when": { "exists": { "entity": "control_scope", "where": { "all": [
        { "field": "responsibility", "op": "in", "value": ["provider","inherited"] },
        { "field": "inherited_from", "op": "is_unset" } ] } } },
    "then": [ { "action": "block_transition",
      "message": { "en": "Every inherited control must cite the assessment it is inherited from." } } ] },

  { "type": "rule", "key": "stale_sar_on_determination_change",
    "on": { "event": "determination.set" },
    "then": [ { "action": "mark_artifact_stale", "artifact": "sar" },
              { "action": "mark_artifact_stale", "artifact": "srtm" } ] }
]
```

The second one is how `content_hash` staleness from the GC plan becomes a
behaviour rather than a background job.

---

# Chapter C — Packaging, publishing and installing

### C.1 What ships first-party

Four blueprints, composed rather than monolithic, so a customer can take the
control layer without the risk layer or vice versa:

| Blueprint | Contents | Depends on |
|---|---|---|
| `core-controls` | The control entity, determination scale, evidence, SRTM and POA&M base templates with anchors | — |
| `htra-tra1` | Chapter A in full | `core-controls` |
| `gc-control-extension` | Chapter B in full | `core-controls` |
| `gc-cloud` | Responsibility seeds, provider assessment entity, guardrails record, cloud profile seed | `gc-control-extension` |
| `gc-satra-suite` | A meta-blueprint that installs the four above with GC defaults | all |

The meta-blueprint matters for sales: one choice, a configured GC workspace. The
composition matters for everyone else.

### C.2 Install flow

1. **Select** a blueprint and a scope.
2. **Preflight** — a dry run that reports: definitions to add, fields to create
   with their index cost against the per-table cap, steps appearing in which
   stages, artifacts created and existing artifacts that will gain fragments,
   rules that will become active, conflicts with installed blueprints, and seeds
   to load. Nothing has changed yet.
3. **Confirm** — the administrator sees the preflight and accepts.
4. **Apply** in a transaction: definitions written, DDL for indexed fields,
   seeds loaded, `config_hash` recomputed, affected artifacts marked stale.
5. **Verify** — a post-install report: every artifact renders against a fixture,
   every view loads, every rule simulates clean.

Step 2 is what makes a configuration platform trustworthy. An install that
silently changes six reports is indistinguishable from a bug.

### C.3 Scope examples

- **Workspace:** a department installs `gc-satra-suite` once; every project gets
  GC practice by default.
- **Program:** a cloud modernization program adds `gc-cloud` for its systems only.
- **Project:** one system with unusual requirements gets an extra step and two
  fields, authored locally, never published.
- **Assessment:** a reassessment under a newer profile edition installs the v2
  control profile at the assessment scope, leaving the original assessment's
  configuration — and therefore its signed artifacts — intact.

That last one is the strongest argument for the scope ladder. Without
assessment-level scoping, reassessing a system under a new profile would rewrite
the configuration that produced the signed artifacts of the previous
authorization.

### C.4 Customer-authored blueprints

A customer promotes local definitions at any scope into a blueprint: Maker
collects them, asks for a key, version and labels, validates, and publishes to the
workspace library. From there it installs at other scopes like any first-party
blueprint, and `aegis blueprint publish` does the same from CI.

Deliberately **out of scope for now:** cross-tenant sharing, a public marketplace,
and third-party signing. Those need a trust model, a review process and a
liability answer. Revisit once the first-party library has proven the format.

---

## 15. Roadmap

Phases are ordered so that each one is provable by the next. Sizes are relative,
not estimates.

| Phase | What | Size | Proves |
|---|---|---|---|
| **0** | Metamodel specification, decision log, §17 answered. No code. | S | The vocabulary is closed |
| **1** | Walking skeleton: definition store, resolver, `effective_config` + hash, fields with JSON + virtual generated columns + expression indexes, steps, scales, matrices, derivation engine, template rendering. JSON editing only — no UI. | L | The engine holds |
| **2** | **HTRA as blueprint #1** (Chapter A). Ships HTRA to customers. | M | The metamodel can express a whole method |
| **3** | Artifact fragments + **GC control extension as blueprint #2** (Chapter B), golden-file testing. | M | It can extend what it did not write |
| **4** | Rules engine, gates, execution log, simulate mode. | M | State changes are configurable and explainable |
| **5** | **Maker workspace UI**: field, step, rule, view and report editors; preview; preflight. | L | Non-engineers can use it |
| **6** | Blueprint lifecycle: publish, install at scope, three-way upgrade merge, declared data migrations. | L | You can ship v2 |
| **7** | REST API v1, `/config/schema`, webhooks. | M | Integrators can build |
| **8** | SDKs (Node, .NET), codegen, blueprint CLI. | M | Enterprise buyers can commit |
| **9** | First-party library: `gc-cloud`, PIA, remaining GC artifacts from the GC plan. Customer-authored blueprints. | M | The library compounds |
| **10** | *Optional:* cross-tenant sharing, marketplace, signing. | L | — |

### 15.1 The sequencing change this makes to the earlier plans

The HTRA brief phased HTRA as direct implementation. **Do not build it that way
now.** Build Phase 1, then express HTRA as blueprint #1. HTRA arrives later than
it would have, and in exchange you get an engine instead of a feature — and the
GC control extension that follows costs a fraction of what it would have.

The one thing to protect: Phase 1 must contain only what HTRA actually needs. If
Phase 1 grows a rules engine, a UI and an API before a single blueprint exists,
the plan has failed in the way §1.2 warns about.

---

## 16. Risks and scope discipline

### 16.1 Do not build

- **Arbitrary code execution** anywhere: rules, derivations, templates, prompts.
- **New stages, ever.** Steps are configurable; the four stages are the product.
- **A visual form designer in Phase 1.** JSON with validation and a preview is
  enough for the two blueprints that prove the engine.
- **A marketplace** before the blueprint format has survived one real upgrade.
- **Fragment deletion.** Additive only; to change a base report, override it.
- **Implicit data migration.** Scale and field changes are declared or rejected.
- **A general-purpose app builder.** Aegis SA configures security assessment, not
  arbitrary business processes. Say no to the first customer who asks for a CRM.

### 16.2 Risks to manage actively

- **The two-layer trap.** Once customers configure, engine changes are breaking
  changes. Mitigated by `metamodel_version`, the closed vocabulary, and golden-file
  tests per blueprint — all three, not one.
- **Testing surface.** Combinations grow multiplicatively. The answer is
  golden-file rendering per blueprint from Phase 3, plus rule simulation fixtures.
- **Support load.** "My report broke" needs tooling, not heroics: the
  configuration audit log, the preflight report, rule execution traces, and an
  *explain this value* view that walks a derivation or rule chain. Build these as
  features, not debug pages.
- **Performance.** Resolution caching by `config_hash`, the indexed-field cap, the
  queue for cascades and rendering. Watch list-view queries over custom fields
  first — that is where it will hurt.
- **SQLite's single writer.** Fine now. Revisit at the thresholds in §3.3, and keep
  the door open in the meantime.
- **Scope creep in the metamodel.** Every "can a blueprint also…" request is a
  platform release. Keep a visible backlog of rejected extensions and the reason,
  so the twelfth definition type is a decision rather than a drift.

---

## 17. Open decisions — answer these in Phase 0

Nine questions. Three change the schema, so they come first.

**Schema-affecting:**

1. **Is `program` a real scope now, or reserved?** Adding a ladder rung later
   invalidates every stored resolution. Recommendation: build it, hide it.
2. **Does an `override` store a patch or a full copy?** This plan assumes a patch
   (§6.2) because the merge in §6.4 depends on it. Confirm.
3. **Are historical findings ever recomputed when a matrix changes?** This plan
   says no by default (§6.5). Confirm, because the alternative changes what
   `finding.computed` is for.

**Product shape:**

4. **Naming:** Maker and Blueprint, or something else? It lands in the API
   namespace.
5. **Who may author configuration?** One admin role, or separate
   configuration-author and configuration-publisher roles? Regulated customers
   will want the split.
6. **Can a project-scope local definition exist without ever being a blueprint?**
   Recommendation: yes — most tailoring is one-off and forcing packaging would
   kill adoption.
7. **Multi-tenancy model:** one database per workspace, or shared with a tenant
   column? This interacts with §3.3 and with how `effective_config` is cached.

**Commercial:**

8. **Is the blueprint library a differentiator or a product line?** If customers
   can author and share, does Aegis SA curate? This determines whether Phase 10
   ever happens.
9. **Do the SDKs ship with the API, or a release later?** Shipping the API without
   an SDK invites integrators to hard-code a schema that is configuration, which
   generates support load that looks like bugs.

---

*Companion documents: `AEGIS-SA-HTRA-AGENT-PROMPT.md` holds the HTRA domain
detail that Chapter A configures. `AEGIS-SA-GC-ARTIFACTS-PLAN.md` holds the GC
artifact inventory that Chapters B and C draw on, and its remaining artifacts are
Phase 9 blueprint content.*
