# Aegis SA — GC Security Artifact Coverage and Implementation Plan

> **How to use this document:** paste it as the opening prompt for a Claude Code
> session in the Aegis SA repository, or save it as
> `docs/gc-artifacts-plan.md`. It is a companion to
> `AEGIS-SA-HTRA-AGENT-PROMPT.md` and assumes the method-type design in that
> brief. Items marked **VERIFY** must be checked against the cited source before
> being implemented as fact; §10 lists what is confirmed and what is not.

---

## 0. Agent instructions (read first)

Before writing code:

1. **Inventory what exists.** For each artifact in the §3 table, find whether
   Aegis SA already stores the data it needs, generates it, or neither. Report a
   three-column answer: artifact / data present? / rendered?
2. **Do not add project stages.** Everything here lands as either (a) a
   method-declared sub-step, (b) an artifact template, or (c) new entity types.
   That is the payoff of the method-type design — use it.
3. **Do not treat this as one epic.** §7 phases it. Phase 1 alone is shippable
   and is most of the perceived value.
4. **Report conflicts** between this document and the codebase. The codebase
   wins on naming.

---

## 1. Naming, before anything else

Two corrections to carry into the code and the UI:

- **SRTM**, not SRTL — *Security Requirements Traceability Matrix*. This is the
  GC term. A Shared Services Canada audit of SA&A names "Final SRTM and
  Supporting Documents" as an SA&A artifact, and SRTM appears in ITSG-33
  Annex 2's abbreviation list.
- **SRCL** is a different artifact entirely — *Security Requirements Check List*,
  TBS/SCT form 350-103, used to declare the security requirements of a
  **contract**. It is not part of a system's SA&A package. If Aegis SA serves
  procurement users, it is a separate small feature (§3, row 14); if not, skip it.
- **SCP** most likely means *Security Control Profile* — the tailored baseline
  from ITSG-33 Annex 4/4A (for example Profile 1, PROTECTED B / Medium integrity
  / Medium availability). Treat it that way below. If your users mean *Security
  Categorization Process*, that is row 1 instead, and both are in scope anyway.

## 2. The core finding: Aegis SA is missing the front and the back of the GC process

Aegis SA today runs: **intake → scope controls → gather evidence → determine
Met/Partially Met/Not Met → decision package → POA&M → IATO/ATO.**

The GC SA&A process runs: **categorize → select and tailor a profile → plan the
assessment → assess → report → authorize → monitor.**

Lining those up, three things are absent and one is thin:

| GC step | Aegis SA | Gap |
|---|---|---|
| **Categorize** | classification is an attribute | **Missing as a step.** Categorization is a formal process under the Standard on Security Categorization, and its output *drives* profile selection. |
| Select & tailor profile | controls scoped with AI justification | **Thin.** No versioned profile artifact, no per-control tailoring record. |
| **Plan the assessment** | — | **Missing.** The app jumps straight to evidence. SSC's audit names a "Final SA&A Plan" as a required artifact. |
| Assess | evidence + determination | Strong. This is the app's core. |
| Report | decision package | **Thin.** No SAR, no SRTM — both are mostly renderable from data you hold. |
| Authorize | IATO/ATO | Strong (with the HTRA work). |
| **Monitor** | — | **Missing.** Authorization is described in GC terms as a decision to accept residual risk *and maintain the security posture on an ongoing basis*. The control catalogue has CA-7 Continuous Monitoring for exactly this. |

Each of the three missing steps is a sub-step under an existing stage —
categorize under intake, plan under assessment, monitor after close. No stage
machine change.

## 3. Artifact inventory

`R` = generated report over data you would already hold · `C` = needs new CRUD
data · `R+C` = both. Confidence is about the *artifact's status in GC practice*,
not about the implementation advice.

| # | Artifact | Type | Have | Effort | Confidence |
|---|---|---|---|---|---|
| 1 | **Security Categorization** — injury determination for C/I/A producing the category that selects the profile | R+C | classification attribute only | M | High — Standard on Security Categorization, Directive on Security Management Appendix J |
| 2 | **Statement of Sensitivity (SoS)** | R | coming with HTRA | — | High |
| 3 | **Security Control Profile (SCP)** — tailored baseline, versioned, with per-control tailoring rationale | R+C | scoping exists, profile artifact does not | M | High — ITSG-33 Annex 4/4A; GC Security Control Profile for Cloud-based GC Services |
| 4 | **Security Assessment Plan / SA&A Plan** — per control: assessment method (examine / interview / test), assessor, schedule, sampling | C | — | M | High — named in SSC audit as "Final SA&A Plan" |
| 5 | **SRTM** — requirement → control → implementation statement → evidence → assessment method → result → finding → POA&M | R | ~75% of data present | S | High — named in SSC audit; in ITSG-33 Annex 2 abbreviations |
| 6 | **Security Assessment Report (SAR)** — scope, methodology, per-control results, findings with severity, recommendations, assessor attestation | R | ~85% of data present | S | High — named in SSC audit |
| 7 | **TRA** | R | coming with HTRA | — | High |
| 8 | **POA&M** | R | built | — | High |
| 9 | **Authorization instrument (ATO / IATO)** | R | built | — | High |
| 10 | **System description & authorization boundary** — components, data flows, interconnections, hosting model | C | architecture doc parsed, boundary not modelled | M | High — prerequisite for 5, 6 and any SSP-style document |
| 11 | **Control responsibility & inheritance** — customer / provider / shared, and inherited-from | C | — | M | High — the Cyber Centre's CSP assessments are explicitly reusable so departments "focus their efforts on their own internal SA&A" |
| 12 | **Continuous monitoring plan** — reassessment schedule, risk review dates, reauthorization triggers | C | `valid_until` from HTRA only | M | High — CA-7; ITSP.10.033 has an assessment, authorization and monitoring section |
| 13 | **Interconnection agreement (ISA / MOU)** — per external connection | C | — | S | Medium — practice varies; CA-9 Internal System Connections is the catalogue hook |
| 14 | **SRCL** (TBS/SCT 350-103) — contract security requirements | R+C | — | S | High as an artifact, but **out of SA&A scope** — procurement feature |
| 15 | **PIA** — under the Standard on Privacy Impact Assessment, with a mandatory TBS template | R+C | — | L | High — PIA Directive rescinded 2024-10-09; the Standard is now incorporated into the Directive on Privacy Practices |
| 16 | **Cloud guardrails validation record** | R+C | — | S | Medium — GC Cloud Guardrails are a Policy on Service and Digital instrument; the validation deadline needs **VERIFY** |
| 17 | **Vulnerability assessment / penetration test findings** | C | — | S | Medium — CA-8 Penetration Testing is the hook; ingest as a third finding kind |
| 18 | **Portfolio / departmental rollup** — authorizations expiring, POA&M aging, residual risk by injury category, control satisfaction across projects | R | — | M | High as a product need; the Departmental Security Plan is the GC analogue |

**What is NOT clearly a GC artifact:** the **System Security Plan (SSP)**. It is
NIST-native. In GC practice its content is distributed across the SCP, the system
description and the SRTM, and it surfaces mainly in cloud and CSP contexts. Do
not build an SSP as a separate document until a user asks by name; build rows 3,
5 and 10 and you can render one if needed.

## 4. The missing backbone: an artifact registry

With eighteen artifact types, per-method deliverable templates stop being enough.
Add one registry so every artifact is a first-class record with a lifecycle:

```sql
CREATE TABLE artifact (
  id             INTEGER PRIMARY KEY,
  project_id     INTEGER NOT NULL REFERENCES project(id),
  assessment_id  INTEGER REFERENCES assessment(id),
  kind           TEXT NOT NULL,        -- 'sar' | 'srtm' | 'scp' | 'tra' | 'poam' | 'ato' | ...
  framework_id   INTEGER REFERENCES framework(id),   -- null for cross-method artifacts
  version        TEXT NOT NULL,
  status         TEXT NOT NULL CHECK (status IN ('draft','in_review','final','superseded')),
  classification TEXT,                 -- marking stamped on the rendered output
  language       TEXT NOT NULL DEFAULT 'en' CHECK (language IN ('en','fr')),
  template_key   TEXT NOT NULL,
  rendered_at    TEXT,
  rendered_by    INTEGER REFERENCES user(id),
  superseded_by  INTEGER REFERENCES artifact(id),
  content_hash   TEXT,                 -- detects drift from the data it was built from
  ai_provenance  TEXT CHECK (ai_provenance IS NULL OR json_valid(ai_provenance)),
  created_at     TEXT NOT NULL
);

CREATE TABLE artifact_signature (
  artifact_id   INTEGER NOT NULL REFERENCES artifact(id),
  signed_by     INTEGER REFERENCES user(id),
  signed_role   TEXT NOT NULL,         -- 'business_owner' | 'authorizing_official' | 'assessor'
  signed_at     TEXT,
  PRIMARY KEY (artifact_id, signed_role)
);
```

Three properties this buys you, none of which you can retrofit cheaply:

- **Versioning and supersession.** "Which SAR did the authorizer actually sign?"
  becomes answerable.
- **Drift detection.** `content_hash` over the source data means the app can say
  *this SAR is stale; findings changed after it was rendered*. In an audit that
  is the difference between a tool and a document folder.
- **Bilingual pairs.** EN and FR are two rows of one logical artifact, not two
  unrelated files.

## 5. New data the reports need

Five fields unlock rows 5, 6 and 10 almost entirely. Add these and the SRTM and
SAR become rendering work rather than data-modelling work:

```sql
-- per scoped control, on whatever table holds control scoping:
--   implementation_statement  TEXT   how this control is satisfied, in prose
--   responsibility            TEXT   'customer' | 'provider' | 'shared' | 'inherited'
--   inherited_from            INTEGER  references a provider assessment or platform ATO
--   assessment_method         TEXT   'examine' | 'interview' | 'test' (may be several)
--   tailoring                 TEXT   'baseline' | 'added' | 'removed' | 'modified' | 'compensating'
--   tailoring_rationale       TEXT   required when tailoring <> 'baseline'
```

`implementation_statement` is the single highest-value missing field: it is what
an assessor reads, what the SRTM's middle column holds, and what your existing AI
guidance feature is already most of the way to drafting. `responsibility` and
`inherited_from` are what make the app usable for cloud systems at all, since a
department assessing a SaaS system needs to state plainly which controls it does
not own.

```sql
-- system description / authorization boundary
CREATE TABLE system_component (
  id            INTEGER PRIMARY KEY,
  project_id    INTEGER NOT NULL REFERENCES project(id),
  entity_id     INTEGER REFERENCES entity(id),   -- reuse the HTRA asset where it is one
  name          TEXT NOT NULL,
  role          TEXT,            -- 'app_tier' | 'datastore' | 'identity' | 'network' | ...
  in_boundary   INTEGER NOT NULL DEFAULT 1,
  hosting       TEXT,            -- 'on_prem' | 'iaas' | 'paas' | 'saas'
  provider      TEXT,
  created_at    TEXT NOT NULL
);

CREATE TABLE interconnection (
  id              INTEGER PRIMARY KEY,
  project_id      INTEGER NOT NULL REFERENCES project(id),
  remote_party    TEXT NOT NULL,
  direction       TEXT NOT NULL CHECK (direction IN ('inbound','outbound','bidirectional')),
  data_described  TEXT NOT NULL,
  classification  TEXT,
  protocol        TEXT,
  agreement_ref   TEXT,          -- ISA / MOU reference
  agreement_date  TEXT,
  created_at      TEXT NOT NULL
);

-- continuous monitoring
CREATE TABLE monitoring_schedule (
  id               INTEGER PRIMARY KEY,
  project_id       INTEGER NOT NULL REFERENCES project(id),
  subject_kind     TEXT NOT NULL,   -- 'control' | 'finding' | 'artifact' | 'authorization'
  subject_id       INTEGER NOT NULL,
  frequency_months INTEGER,
  next_due         TEXT,
  last_completed   TEXT,
  owner            TEXT,
  trigger_note     TEXT             -- event-based triggers, e.g. boundary change
);
```

## 6. Where each piece attaches

Nothing below is a new project stage.

| Lands as | Items |
|---|---|
| **Intake sub-step** | Security categorization (1); system description & boundary (10) |
| **Assessment sub-step** | Profile tailoring (3); assessment plan (4); control responsibility & inheritance (11); VA/pen-test ingest (17) |
| **Decision-package artifact** | SRTM (5); SAR (6); SCP document (3); categorization report (1) |
| **Post-authorization** | Continuous monitoring plan (12) — reached from the Close stage, which stops being terminal |
| **Project-level CRUD, stage-independent** | Interconnections (13); artifact registry (4) |
| **Separate module** | PIA (15); SRCL (14) |
| **Enterprise reporting, outside the project flow** | Portfolio rollup (18) |

The one structural change worth noting: **Close can no longer be terminal.**
Continuous monitoring means an authorized system comes back — a review falls due,
a reassessment is triggered, an authorization nears expiry. Model that as the
project re-entering assessment with a `reassessment` flag rather than as a new
stage, so the same sub-steps and artifacts apply on the second pass.

## 7. Phases

**Phase 1 — The two reports you can almost already render** *(small, highest value)*
Add the five per-control fields from §5. Build the **SRTM** and the **SAR**.
Add the `artifact` registry with versioning, status and `content_hash`.
*Why first:* these are the two artifacts GC assessors ask for by name, you hold
most of the data, and the AI guidance feature already drafts the hardest field.
*Done when:* an assessment with evidence and determinations renders an SRTM and a
SAR, both versioned, and the app flags either as stale when findings change after
rendering.

**Phase 2 — Security categorization as a step** *(medium)*
Categorization as an intake sub-step producing the category that selects the
profile, registered as a `method_scale` so the injury levels are configurable.
Wire the result to profile selection so the PBMM proposal is *derived* rather
than asserted.
*Done when:* an intake categorization produces a category, the categorization
report renders, and the proposed control profile cites it as the reason.

**Phase 3 — Profile as a versioned artifact** *(medium)*
Per-control tailoring with required rationale for anything off-baseline;
versioned SCP document; diff between profile versions.
*Done when:* a tailored profile renders as a document showing baseline, additions,
removals, modifications and compensating controls, each with its rationale.

**Phase 4 — Assessment plan** *(medium)*
Per control: assessment method, assessor, schedule, sampling. Plan renders as the
SA&A Plan artifact, and the evidence workflow is driven *from* the plan rather
than starting cold.
*Done when:* an assessor works a planned queue instead of an unordered control
list, and the plan-versus-actual gap is visible.

**Phase 5 — Cloud reality: responsibility and inheritance** *(medium, unlocks a market)*
Control responsibility, inheritance from a provider assessment or platform ATO,
system components with hosting model, guardrails validation record.
*Done when:* a SaaS project's SAR states which controls are provider-responsible
and what assessment they are inherited from, and the count of self-assessed
controls drops accordingly.

**Phase 6 — Continuous monitoring** *(medium)*
Monitoring schedule, due-date engine, reassessment re-entry, authorization expiry
warnings. Close becomes non-terminal.
*Done when:* an authorized project surfaces its next review, and an expiring
authorization appears on a dashboard before it expires.

**Phase 7 — Portfolio reporting** *(medium)*
Cross-project rollup: authorizations and their expiries, POA&M aging, residual
risk by injury category, control satisfaction, AI provenance in aggregate.
*Done when:* a departmental security officer can answer "what is expiring in the
next 90 days and what is overdue" without opening a project.

**Phase 8 — Optional modules** *(large, only on demand)*
PIA (15) and SRCL (14). Both are real GC artifacts and neither belongs in the
SA&A critical path. PIA is the bigger opportunity and the bigger build: it needs
a personal-information inventory, trigger screening, the mandatory TBS template,
and submission tracking to the OPC and TBS. Its asset and injury data overlaps
HTRA's heavily, which is the argument for doing it inside Aegis SA rather than
beside it.

## 8. Acceptance criteria

- Every artifact in §3 that the app produces is an `artifact` row with a version,
  a status and a classification marking — not a transient download.
- A rendered artifact can be detected as stale when its source data changes.
- The SRTM shows an unbroken chain per control: requirement → implementation
  statement → evidence → assessment method → determination → finding → POA&M
  item, with gaps shown as gaps rather than omitted rows.
- A control can be marked provider-responsible or inherited, and the SAR reports
  self-assessed and inherited counts separately.
- Security categorization is a recorded step whose output is cited as the reason
  for the selected profile.
- Close is not terminal: a project can re-enter assessment as a reassessment and
  reuse the same sub-steps and templates.
- Every artifact renders in EN and FR from the same data.
- Adding a nineteenth artifact type requires a template and a registry row — no
  new application code.

## 9. Scope discipline — what not to build

- **No SSP as a separate document.** Build the system description, the SCP and
  the SRTM; render an SSP later only if a user asks by name.
- **No separate privacy product** unless you intend to enter that market. Phase 8.
- **No new stages.** Every item above attaches per §6.
- **Do not merge categorization into the HTRA statement of sensitivity.** They
  overlap but are distinct: categorization is upstream, drives profile selection,
  and answers to its own TBS standard. Let the SoS *reuse* the categorization's
  injury values rather than replacing them.
- **Do not combine control-assessment severity and HTRA residual risk into one
  score** anywhere in these reports. Same rule as the POA&M.
- **Do not generate an SRTM row for an unassessed control and leave it blank
  silently.** An assessor reads blanks as either "not applicable" or "not done",
  and guessing wrong is the kind of thing that fails an audit. Mark them.

## 10. Verification notes — what is confirmed and what is not

Confirmed against Government of Canada sources:

- **SRTM, SA&A Plan and Security Assessment Report** are named SA&A artifacts.
  A Shared Services Canada audit of SA&A (2020) distinguishes *project artifacts*
  from *SA&A artifacts* and names "Final SA&A Plan, Final SRTM and Supporting
  Documents, Security Assessment Report" as examples of the latter. SRTM also
  appears in ITSG-33 Annex 2's abbreviation list.
- **Security authorization** is described as the decision to accept residual risk
  and maintain the security posture on an ongoing basis.
- **Control profiles** live in ITSG-33 Annex 4/4A — e.g. Profile 1 (PROTECTED B /
  Medium integrity / Medium availability) and Profile 3 (SECRET / Medium / Medium)
  — and there is a separate GC Security Control Profile for Cloud-based GC Services.
- **Security categorization** has its own TBS standard, referenced as Appendix J
  of the Directive on Security Management; for cloud there is ITSP.50.103.
- **CA family** includes CA-7 Continuous Monitoring, CA-8 Penetration Testing and
  CA-9 Internal System Connections.
- **PIA:** the Directive on Privacy Impact Assessment was rescinded 2024-10-09;
  the Standard on Privacy Impact Assessment is now incorporated into the Directive
  on Privacy Practices, with mandatory requirements and a mandatory template.
  Privacy Implementation Notice 2025-02 (2025-07-07) requires institutions to
  submit PIAs to the OPC and TBS.
- **Cloud:** GC Cloud Guardrails are a Policy on Service and Digital instrument;
  the Direction on the Secure Use of Commercial Cloud Services applies to
  PROTECTED B / Medium / Medium; the Cyber Centre's Cloud Security Assessment
  Program produces reusable CSP reports (ITSM.50.100), with ITSP.50.105 on cloud
  SA&A and ITSM.50.062 on cloud security risk management.
- **SRCL** is TBS/SCT form 350-103, completed by the project authority at the
  start of procurement, required where a contract needs access to PROTECTED or
  CLASSIFIED information, assets or sites, with separate SRCLs for subcontractors.
- **ITSG-33 is being superseded** by the ITSP.10.035 / .036 / .037 series;
  ITSP.10.033-01 is the organizational profile for medium impact, and its control
  families are renamed (for example an "assessment, authorization and monitoring"
  section rather than CA).

**VERIFY before relying on these:**

- The exact ISSIP activity names in ITSG-33 Annex 2 and which artifact each
  activity produces. I could not read Annex 2 — searches returned only its table
  of contents and abbreviation list.
- The injury levels and exact scale labels in the Standard on Security
  Categorization (Appendix J), needed to seed the categorization scale.
- Whether Appendix B (Mandatory Procedures for Information Technology Security
  Control) of the Directive on Security Management is still current. Appendix A
  was replaced by the Directive on Security Screening effective 2025-01-06;
  whether B or J moved similarly is unconfirmed.
- The GC Cloud Guardrails validation deadline and the evidence required. The
  commonly cited "within 30 days" could not be confirmed.
- The field list of the mandatory TBS PIA template.
- Any mandated reauthorization interval. None was found in GC sources; treat the
  interval as departmental policy and make it configurable rather than fixed.

Read the primary sources before seeding any scale, template field list or
deadline. The pattern from the HTRA work applies here too: seed as draft, stamp a
`source_ref`, and surface the draft state in the UI.
