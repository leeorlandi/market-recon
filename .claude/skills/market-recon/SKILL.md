---
name: market-recon
description: >
  Market Recon — agentic competitive intelligence for any market, capability area,
  or pasted PRD. Deploys a coordinated agent team: dimension analysts (one per
  capability area), an unconstrained scout, a buyer-perspective analyst, and a
  fact-checker who communicates directly with agents to resolve citation failures.
  Builds a persistent world model that compounds across runs — the scout always
  searches past what's already known. Produces a structured digest, executive brief
  framed for the user's role and decision, and a 7-day live pulse with velocity
  tracking on every identified player.

  Use when the user types /market-recon <topic> or pastes a PRD and asks for
  competitive intelligence, market landscape, or vendor discovery.
---

# /market-recon — Market Recon

## What this skill does

Given a topic (plain-language string or full PRD), this skill:

1. Normalizes input and determines topic scope
2. Checks for an existing world model config; creates one if missing
3. Fans out parallel dimension agents (one per capability area) plus one
   unconstrained scout agent that finds what the dimension agents miss
4. Reconciles scout findings against the world model — new players get logged,
   new angles get tracked, mature angles get promoted to full dimensions
5. Writes a market digest and updates the world model config
6. Runs a live 7-day pulse on every known player
7. Produces a terminal briefing and points to the full output files

The skill gets smarter with each run. The world model records everything discovered
so the scout is never retreading known ground.

---

## Citation Standard

All output files use numbered footnote-style citations:

```
Acme raised a $40M Series B[^1] and charges $50/seat/month[^2].

[^1]: https://techcrunch.com/... — accessed 2026-04-09
[^2]: https://acme.com/pricing — accessed 2026-04-09
```

**Required on:** specific numbers, dollar amounts, funding rounds, player counts,
dates, and any named statistic asserted as fact.

**Not required on:** editorial synthesis sentences that summarize patterns rather
than assert a specific measurable fact.

**Estimates:** claims that are synthesis approximations (not sourced from a specific
page) must be labeled **(estimate)** instead of cited.

The citation reference block does not count toward any agent word limits.

---

## Input

```
/market-recon $ARGUMENTS
```

`$ARGUMENTS` can be:
- A short topic: `AI SDRs`, `revenue intelligence platforms`
- A capability area: `signal-to-deal orchestration`, `buyer intent data`
- A full PRD or product spec pasted inline

---

## Supporting files

Before executing, read these files — they provide the taxonomy and decision
frameworks used throughout:

- `_prompts/dimension-research.md` — dimension agent prompt (fill placeholders before spawning)
- `_prompts/scout.md` — scout agent prompt (fill placeholders before spawning)
- `_prompts/buyer-perspective.md` — buyer perspective agent prompt (fill placeholders before spawning)
- `_prompts/fact-checker.md` — fact-checker agent prompt (fill placeholders before spawning)
- `_prompts/synthesis-generalist.md` — generalist synthesis agent prompt
- `_templates/config.md` — config file skeleton
- `_templates/digest.md` — digest file skeleton
- `_templates/pulse-7d.md` — pulse file skeleton
- `_templates/longitudinal-brief.md` — longitudinal brief skeleton (Run 4+)
- `player-classification.md` — taxonomy for classifying direct / adjacent / infrastructure / pay-to-play
- `procurement-criteria.md` — framework for assessing pay-to-play vs. compete decisions

---

## Phase 0 — Normalize Input

Parse `$ARGUMENTS`. Determine:

**Is this a PRD?**
If the input is longer than ~500 characters and contains multiple headers or
structured sections, treat it as a PRD. Spawn a lightweight extraction agent:

```
Read the following PRD and extract the core market-facing capability areas.
Return 4–6 capability dimensions that describe what this product does in
market terms — not implementation details. 

BAD: "OAuth integration", "PostgreSQL backend", "REST API layer"
GOOD: "Identity and access management", "Developer workflow automation", "Data pipeline orchestration"

Also propose a short filesystem-safe slug for the topic (e.g., "dev-workflow-automation").

PRD:
[paste PRD]
```

Use the extracted dimensions and slug. State your interpretation in the output.

**Breadth check:**
If the topic would produce more than 8 dimensions, it is too broad. Pause.
Present 3–4 narrowed sub-topics with one-line descriptions and ask the user
to confirm which to proceed with. Do not create a config until confirmed.
Example: "AI" → offer "AI for sales", "AI for customer support", "AI infrastructure / LLMOps", "AI coding tools".

**Slug generation:**
Convert the topic to a lowercase, hyphenated filesystem slug: `ai-sdrs`, `revenue-intelligence`.
Before creating a config, check if `research/<slug>/config.md` already exists.
If it does, load it and check the `## Topic` field. If the topic doesn't match the
current input, append a number: `ai-sdrs-2`. Never silently reuse a mismatched config.

State your interpretation at the top of all output:
```
Interpreting as: <topic label> (scope: <capability | product-area | prd>)
Config path: research/<slug>/config.md
```

**Strategic context capture:**

Before creating or loading the config, ask the user two questions:

```
Two quick questions before we begin:

1. What's your role in relation to this market?
   [A] Buyer evaluating vendors
   [B] Founder mapping competitors
   [C] Investor sizing a category
   [D] Operator benchmarking
   [E] Other (describe briefly)

2. What decision does this research need to support?
   (1–2 sentences)
```

Wait for the response. Store both answers in `config.md` under `## Research Context`.

**If this is a re-run on an existing config (Run Status = complete):** load the stored
context and confirm:
```
Researching for: [role] — [decision]. Same context? (y/n)
```
If "n", ask for updated answers and overwrite the Research Context section.

Do not proceed to Phase 1 until context is captured.

---

## Phase 1 — Config Check and World Model Load

### If config exists

Load `research/<slug>/config.md`. Check `## Run Status`:

**`complete`** — last run finished. Ask the user:
```
Found existing world model for "<topic>" (Run N, <date>).
  [1] Full refresh — re-run all dimension agents and scout
  [2] Pulse only — skip research, just update 7-day pulse
  [3] Specific dimension — re-run one dimension (which one?)
```
Default to [1] if no response within the turn.

**`partial`** — run was interrupted. Auto-resume:
```
Last run was incomplete. Resuming from Phase <N>.
Skipping dimension agents that already have output files in agents/.
```
Check `agents/` for existing files and skip those dimensions. Re-run Phase 3
reconciliation in full regardless — partial runs may have missed world model updates.

**`in-progress`** — run may be active or crashed. Warn and offer reset:
```
A run appears to be in progress or crashed without cleanup.
Set Run Status to "partial" and resume? (y/n)
```

### If no config exists

Generate the research schema using `_templates/config.md`. Fill in:
- Topic label and human-readable name
- Scope type
- 4–7 established dimensions appropriate to the topic
- Schema Version: 1.0
- Run Status: in-progress
- Run Count: 0
- Created date

Write to `research/<slug>/config.md`.

Display: `No config found for "<topic>". Created new world model at research/<slug>/config.md`

---

## Phase 2 — Fan Out the Agent Team

Spawn the research team as an agent team. The team lead (orchestrator) coordinates.

### Teammate naming — required for inter-agent messaging

When spawning each teammate, assign it a predictable name. Teammates discover each other's
names from `~/.claude/teams/{team-name}/config.json` (the `members` array) and use the
`SendMessage` tool to communicate. Predictable names make this reliable.

**Required naming convention:**
- Dimension agents: `dim-<dimension-slug>` (e.g. `dim-pricing`, `dim-positioning`)
- Scout: `scout`
- Buyer perspective: `buyer`
- Fact checker (Phase 2.5): `fact-checker`

### Research team members

**Dimension agents** — one per dimension listed in `## Established Dimensions` in the config.

For each dimension agent, read `_prompts/dimension-research.md` and fill the placeholders:
- `{{TOPIC}}` → the topic label
- `{{DIMENSION}}` → this dimension's name
- `{{KNOWN_PLAYERS}}` → the full `## Known Players` list from config, formatted
  as a plain list. If the list is empty (first run), pass: "None yet — this is
  a first run. Research freely."
- `{{TEAMMATE_NAMES}}` → a list of all teammate names on this team (dimension agents,
  scout, buyer) so each agent knows who it can SendMessage

Spawn each with the filled prompt and name it `dim-<dimension-slug>`.
Each dimension is one task. Teammates share the task list and self-claim when available.

Write each agent's raw output to:
```
research/<slug>/agents/<dimension-slug>.md
```

**Scout agent** — one unconstrained discovery teammate.

Read `_prompts/scout.md` and fill the placeholders:
- `{{TOPIC}}` → the topic label
- `{{KNOWN_PLAYERS}}` → the full `## Known Players` list from config
- `{{ESTABLISHED_DIMENSIONS}}` → the full `## Established Dimensions` list
- `{{EMERGING_ANGLES}}` → the full `## Emerging Angles` list from config
- `{{TEAMMATE_NAMES}}` → list of all teammate names on this team

Spawn with name `scout`. The scout's task is: "Find what dimension teammates miss."

Write the scout's raw output to:
```
research/<slug>/agents/scout.md
```

**Buyer perspective agent** — researches the demand side of the market.

Read `_prompts/buyer-perspective.md` and fill the placeholder:
- `{{TOPIC}}` → the topic label
- `{{TEAMMATE_NAMES}}` → list of all teammate names on this team

Spawn with name `buyer`.

Write output to:
```
research/<slug>/agents/buyer-perspective.md
```

### Inter-agent coordination

Teammates share a task list and communicate via the `SendMessage` tool using the names above.
Teammates can also read `~/.claude/teams/{team-name}/config.json` to discover all current
members if the name list wasn't sufficient:

- **Dimension agents → scout:** route out-of-scope finds via SendMessage("scout", ...)
- **Scout → dimension agents:** flag lane-specific finds via SendMessage("dim-<slug>", ...)
- **Buyer perspective agent → dimension agents:** flag review-prominent but missing vendors
- **Fact checker (Phase 2.5):** joins after research completes; messages agents via
  SendMessage to resolve citation failures before writing its report

**If parallel agent spawning is not available:** Run all agents sequentially.
Note in the Phase 5 header: `Run mode: sequential`. Output is identical, just slower.

**Do not proceed to Phase 2.5 until all dimension agents, the scout, and the buyer
perspective agent have marked their tasks complete.**

---

## Phase 2.5 — Fact-Check Teammate

The fact checker joins the research team as an additional teammate. It does NOT run
as a separate sequential pass — it waits for all other teammates to finish, then
engages them directly to resolve citation failures.

Add the fact checker to the research team. Read `_prompts/fact-checker.md` and fill:
- `{{AGENT_FILES}}` → a list of all agent output file paths written in Phase 2
  (e.g. `research/<slug>/agents/pricing.md`, `research/<slug>/agents/scout.md`,
  `research/<slug>/agents/buyer-perspective.md`, etc.)

The fact checker:
1. Waits for all dimension agents, the scout, and the buyer perspective agent to finish
2. Reads all output files and extracts every cited high-stakes claim
3. Fetches each URL and verifies the claim is supported
4. Messages any dimension agent or the scout directly when a claim can't be verified:
   "Your [^N] citation for [claim] — [failure reason]. Do you have an alternative source,
   or should this be marked unverified?"
5. The agent responds with a corrected URL (fact checker re-checks) or confirms unverifiable
6. After all exchanges resolve, writes `agents/fact-check.md` and marks its task complete

Write the fact-checker's output to:
```
research/<slug>/agents/fact-check.md
```

**Do not proceed to Phase 3 until the fact-checker has marked its task complete.**

### How Phase 3 uses the fact-check report

When writing the digest, read `agents/fact-check.md` first. For each entry in
**Failed Claims**:

- `DEAD LINK` → remove the citation marker and append **(link dead — unverified)**
  to the claim. Do not delete the claim itself.
- `NOT FOUND` → append **(source does not confirm)** to the claim.
- `CONTRADICTS` → remove the specific number/fact and replace with **(disputed —
  see fact-check.md)**.
- `CANNOT VERIFY` → append **(paywalled — unverified)** and keep the URL.

Claims in **Verified Claims** with `PASS` carry through unchanged.

Log a one-line summary in the digest footer:
```
Fact-check: N claims verified, N failed (see agents/fact-check.md)
```

---

## Phase 3 — Reconcile, Dedupe, and Write the Digest

This is the most important phase. It does three things in sequence.

### Step 1: Reconcile the scout's findings against the world model

Read `agents/scout.md`. For each finding:

**New player found:**
- Is it already in `## Known Players`? → Discard. Already mapped.
- Is it genuinely new? → Add to the Known Players running list (will be written
  to config in Step 3). Route it to the closest established dimension or mark
  as "uncategorized" if it doesn't fit. Flag as "newly discovered this run" in the digest.

**New angle found:**
- Does it match an existing entry in `## Emerging Angles`?
  → Yes: increment its appearance count. If count reaches 2, mark it for promotion.
  → No: add it as a new Emerging Angle with `[Run N]` tag and appearance count 1.

**Promoted angles:**
- Any Emerging Angle hitting 2 appearances → move it to `## Established Dimensions`.
  A full dimension agent will cover it from the next run onward.
- Log the promotion in `## Graduation Log`.

**Market shifts:**
- Include these in the digest TL;DR and Hot Themes if they're significant.
  They don't create new config entries unless they signal a new angle.

### Step 2: Deduplicate across dimension agents and map relationships

Read all `agents/<dimension>.md` files and `agents/buyer-perspective.md`.
Merge any company that appears in multiple dimensions into a single canonical entry.
Players with cross-dimension presence are platform plays — flag them explicitly in the Landscape Map.

After deduping, explicitly look for **relationships** between the players found:
- **Head-to-head competition:** which players compete directly in the same lane? Based on
  their differentiators and pricing, who appears to be winning and on what dimension?
- **Partnership signals:** shared integrations, co-marketing announcements, built-on
  relationships (Company A is built on Company B's platform)
- **Acquisition activity:** any announced acquisitions, or players that look like
  acquisition targets based on size, capability fit, and funding stage
- **Trajectory signals:** based on funding recency, hiring pace, and launch frequency
  in the past 12 months — who is accelerating? Who has gone quiet?

Fill the `## Competitive Dynamics` section of the digest from this analysis.

Also incorporate buyer perspective findings:
- Route buyer pain points to the White Space section
- Note in the digest any vendor who appears prominently in buyer reviews but is
  underrepresented in the dimension agent output

### Step 3: Write the digest and update the world model

**Write the digest** using `_templates/digest.md` as the skeleton. Fill in:
- TL;DR: 3–5 bullets covering the landscape, what moved, and what the scout found
- Landscape Map: core players table, infrastructure layer, white space
- New This Run: the scout's reconciled findings — newly discovered players,
  new emerging angles, any promotions
- Dimension Breakdowns: each agent's output, cleaned and formatted
- Procurement Hit List: apply `procurement-criteria.md` to flag pay-to-play targets

Write to: `research/<slug>/digest.md`

**Update the config** — this must happen before Phase 4:
- Add all new players to `## Known Players`
- Update `## Emerging Angles` with new entries and incremented counts
- Move promoted angles to `## Established Dimensions`
- Log promotions in `## Graduation Log`
- Update `## 7-Day Pulse Targets` with any new players
- Set `## Run Status` to `in-progress` (complete after Phase 5 finishes)
- Increment `## Run Count`

---

## Phase 3.5 — Synthesis: Generalist Brief + Specialist Roster

This phase turns the raw digest into a polished executive brief and manages the
specialist roster. It runs in three sequential steps.

### Step 1: Generalist synthesis

Spawn the generalist synthesis agent.

Read `_prompts/synthesis-generalist.md` and fill the placeholders:
- `{{TOPIC}}` → the topic label
- `{{DIGEST}}` → full contents of `research/<slug>/digest.md`
- `{{PULSE}}` → full contents of `research/<slug>/pulse-7d.md`
- `{{ROSTER}}` → full contents of `_specialists/roster.md`
- `{{RESEARCH_CONTEXT}}` → the `## Research Context` section from `research/<slug>/config.md`
  (role + decision captured in Phase 0)

The generalist produces three things:
1. An executive brief (Part 1)
2. A deployment decision for each rostered specialist — DEPLOY or SKIP (Part 2)
3. Proposals for new specialists not yet on the roster (Part 3)

Write the generalist's full output to:
```
research/<slug>/agents/synthesis-generalist.md
```

### Step 2: Deploy rostered specialists

Read the generalist's Part 2 output. For each specialist marked `DEPLOY`:

1. Read the specialist's file from `_specialists/<filename>.md`
2. Fill the placeholders with topic, digest, pulse, and generalist brief
3. Spawn the specialist agent
4. Write their output to: `research/<slug>/agents/synthesis-<specialist-slug>.md`

Run all deployed specialists in parallel.

**Do not proceed to Step 3 until all deployed specialists have returned.**

### Step 3: New specialist proposals

Read the generalist's Part 3 output. If new specialists were proposed:

Present them to the user in this format:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SPECIALIST PROPOSALS
  The generalist identified gaps the roster doesn't cover.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] <Specialist Name>
    Expertise: <what they know>
    Why valuable here: <specific reason for this research>
    Triggers: <when they'd self-deploy in future>

[2] <Specialist Name>
    ...

Enter numbers to approve (e.g. "1 2"), "all", or "none":
```

Wait for user response. For each approved specialist:

1. Generate a specialist prompt file using `_specialists/_template.md` as the base.
   Fill in all placeholders — the domain lens and priority signals sections must be
   specific and detailed, not generic. These are permanent files.
2. Write to: `_specialists/<specialist-slug>.md`
3. Add an entry to `_specialists/roster.md` under `## Active Specialists`
4. Spawn the specialist agent immediately using the research from this run
5. Write their output to: `research/<slug>/agents/synthesis-<specialist-slug>.md`

Run all newly approved specialists in parallel.

**If the user responds "none" or there are no proposals:** proceed immediately.

### Step 4: Assemble the executive brief

Read all synthesis agent outputs:
- `research/<slug>/agents/synthesis-generalist.md`
- `research/<slug>/agents/synthesis-<specialist-slug>.md` (all deployed/approved)

Assemble into a single `executive-brief.md`:

```markdown
# Executive Brief: {{TOPIC}}
Generated: {{DATE}} | Run: {{RUN_NUMBER}}
Analysts: Generalist[, <Specialist Names>]

---

## Market Intelligence Brief
<generalist Part 1 — headline, what's happening, who's winning, gap, what to watch>

---

## Specialist Perspectives

### <Specialist Name> Lens
<specialist output>

### <Specialist Name> Lens
<specialist output>

<!-- If no specialists deployed: omit this section entirely -->
```

Write to: `research/<slug>/executive-brief.md`

Increment `runs` counter for each specialist that deployed in `_specialists/roster.md`.

---

## Phase 3.5b — NOTE on pulse sequencing

The generalist synthesis in Phase 3.5 receives `{{PULSE}}` as an input. On the
**first run**, `pulse-7d.md` does not exist yet — pass an empty string and note
"Pulse not yet generated — will be available from Run 2 onward." in the brief header.

On **subsequent runs**, pass the prior run's `pulse-7d.md`. The pulse for the
current run is written in Phase 4, which runs after synthesis. This means the
executive brief always reflects current digest + prior pulse. This is an intentional
sequencing trade-off: synthesis happens while the market is fresh in context, and the
updated pulse is appended to `pulse-7d.md` after.

If the user needs synthesis with current-run pulse data, they can re-run Phase 3.5
after Phase 4 completes — Phase 5 will assemble the final brief regardless.

---

## Phase 3.6 — Longitudinal Synthesis (Run 4+)

**Skip this phase if Run Count < 4.**

This phase synthesizes movement across all runs rather than just the current snapshot.
It runs after Phase 3.5 and before Phase 4.

Read:
- `config.md` full history: Known Players (with first-seen run annotations), Emerging Angles
  (with appearance counts and graduation log), Run Count, Last Run date
- All prior `digest.md` files if archived, or reconstruct from config history
- Prior `executive-brief.md` for "What to Watch Next" predictions (for the scorecard)

Spawn a longitudinal synthesis agent with this task (fill `{{RUN_COUNT}}` and `{{TOPIC}}`
from the config before spawning):

> You are synthesizing research movement across {{RUN_COUNT}} runs on {{TOPIC}}.
>
> Answer these questions using the config history and prior digests:
> 1. Which players appeared early and have since grown in signal density?
> 2. Which emerging angles were flagged 3+ runs ago and never graduated — are they
>    dying or still building?
> 3. Which players have gone quiet for 3+ runs — are they still active?
> 4. What has the market done in the past N runs that wasn't predictable from Run 1?
> 5. Score any "What to Watch Next" predictions from prior executive briefs.
>
> Write to: `research/<slug>/longitudinal-brief.md`
> Use `_templates/longitudinal-brief.md` as the skeleton.

After the agent returns:
- Append a `## Longitudinal Summary` section to `executive-brief.md` with 3–5 bullets
  from the longitudinal agent's Longitudinal Takeaway section
- Write to: `research/<slug>/longitudinal-brief.md`

**Do not block Phase 4 if this phase fails** — log a note and continue.

---

## Phase 4 — 7-Day Pulse: Live Player Intelligence

Read the `## 7-Day Pulse Targets` list directly from the config. Do not derive
it from the digest — the config list is canonical and may include players not
prominent in this run's digest.

**Build a baseline from prior pulse runs before searching:**

Read prior pulse files from `research/<slug>/` if they exist. For each player that
appeared in prior pulses, count how many signals they generated per run on average.
Use this to set a baseline. As you collect signals this run, compare:
- If a player's signal count this run is meaningfully **higher** than their baseline → flag as Accelerating
- If a player's signal count is meaningfully **lower** (or zero when usually active) → flag as Going Quiet
- Update the `## Velocity Changes` section of the pulse accordingly

Requires at least 2 prior pulse runs to populate Velocity Changes. If fewer than 2 prior
runs exist, skip Velocity Changes but still read prior pulses for run history context.

Also update the Quiet Players run history column: instead of "consecutive quiet runs",
record the last 3 run states: e.g. `quiet | active | quiet`.

As you search for each player, record the URL of each signal source immediately —
do not rely on reconstructing it later. If you cannot find a citable source for
a signal, do not include the signal.

For each player, run a focused web search scoped to the past 7 days:
```
"<Company>" OR "<Product>" announcement launch funding partnership site:techcrunch.com OR site:venturebeat.com OR site:linkedin.com
```
```
"<Company>" news 2025 2026
```

Collect for each player:
- Product launches or feature announcements
- Funding rounds or M&A activity
- Executive hires or departures
- Customer wins or published case studies
- Conference appearances or keynotes
- Restructuring or workforce changes

Write results using `_templates/pulse-7d.md` as the skeleton:

**Active players** — any detectable movement. One entry per player with signal
type, what happened, why it matters, and source URL.

**Quiet players** — no signals found. Track consecutive quiet runs.
Flag any player quiet for 3+ consecutive runs as "verify still active."

**Hot themes** — where are multiple players moving simultaneously?
Requires at least 2 players. This section is often the most forward-looking
part of the entire briefing.

Write to: `research/<slug>/pulse-7d.md`

---

## Phase 5 — Final Output Assembly

Before assembling output, run a brief self-check:
- Does `digest.md` have all required sections? (Research Confidence, TL;DR, Landscape Map,
  Competitive Dynamics, New This Run, Dimension Breakdowns, Procurement table)
- Does `pulse-7d.md` have all required sections? (Active Players, Velocity Changes,
  Quiet Players, Hot Themes)
- Were all dimension agents accounted for?
- Was the buyer perspective agent output incorporated into the digest White Space section?
- Was the config updated with new players and angles?
- Does every row in the Landscape Map core players table have a Source entry?
- Do the Market Signals bullets in each dimension breakdown have citations on
  specific factual claims (numbers, funding, pricing)?
- Does every Active Player entry in `pulse-7d.md` have a Source URL?
- Does the Newly Discovered Players table have Source URLs for every row?
- Was the fact-check summary line added to the digest footer?
- Was the Research Confidence block in the digest populated (maturity, data density,
  run number, fact-check result)?
- Was the Competitive Dynamics section filled (not all-empty tables)?
- If Run Count ≥ 4: does `longitudinal-brief.md` exist and does `executive-brief.md`
  have a `## Longitudinal Summary` section?

If any check fails, fix it before printing. Do not silently produce incomplete output.

Then print to terminal in this order:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MARKET RESEARCH BRIEF: <TOPIC>
  Scope: <type>  |  Run: <N>  |  Date: <date>
  Dimensions: <N established>  |  Known players: <N>
  Analysts: Generalist[, <Specialist Names>]
  Run mode: parallel | sequential
  Config: research/<slug>/config.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXECUTIVE BRIEF
───────────────
<headline from generalist brief>
<what's actually happening — bullets>
<who's winning and why>
<the gap nobody's filling>
<what to watch next>

<if specialists deployed:>
── <Specialist Name> Lens ──
<specialist what to watch / recommendation — 3–5 lines>

LANDSCAPE — CORE PLAYERS
─────────────────────────
<core players table from digest>

NEW THIS RUN
────────────
<scout findings — newly discovered players and angles>
<if nothing: "No new players or angles discovered this run.">

7-DAY PULSE — TOP 5 SIGNALS
────────────────────────────
<top 5 active player entries from pulse>

PROCUREMENT HIT LIST
────────────────────
<procurement table from digest>

NEXT ACTIONS
────────────
<3–5 suggested follow-up /market-recon refinements based on what was found>
<e.g. narrow into a specific angle, research a newly discovered player category>

Executive brief → research/<slug>/executive-brief.md
Full digest     → research/<slug>/digest.md
Full pulse      → research/<slug>/pulse-7d.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After printing, update config `## Run Status` to `complete` and `## Last Run` to today's date.

---

## File outputs

Runtime files written to `research/<slug>/` in the active project:

```
research/
└── <topic-slug>/
    ├── config.md               ← world model (grows every run)
    ├── digest.md               ← full competitive landscape (raw source of truth)
    ├── pulse-7d.md             ← weekly player intelligence
    ├── executive-brief.md      ← synthesized brief (generalist + specialists)
    ├── longitudinal-brief.md   ← cross-run synthesis (Phase 3.6, Run 4+ only)
    └── agents/
        ├── <dimension-1>.md          ← raw dimension agent output
        ├── <dimension-2>.md
        ├── scout.md                  ← raw scout output
        ├── buyer-perspective.md      ← demand-side research (Phase 2)
        ├── fact-check.md             ← citation verification report (Phase 2.5)
        ├── synthesis-generalist.md   ← generalist brief + roster decisions (Phase 3.5)
        └── synthesis-<specialist>.md ← specialist output, one file per deployed specialist
```

Specialist definitions (persistent across all runs and topics):
```
.claude/skills/market-recon/
└── _specialists/
    ├── roster.md          ← index of all specialists (active + retired)
    ├── _template.md       ← template for generating new specialists
    └── <specialist>.md    ← one file per specialist on the roster
```

---

## Error handling

**Sparse results for a player or dimension (fewer than 3 named players):**
Note explicitly — "sparse results, possible pre-market signal" — and include
what was searched for but not found. Sparse = signal, not failure.

**Scout returns no new findings:**
Write "No new players or angles found this run." in the New This Run section.
This is a valid result that means the world model is current.

**Input topic too broad (>8 dimensions):**
Pause and present narrowing options. Do not create a config or spend compute
until the user confirms scope.

**Interrupted run:**
On next invocation, Phase 1 detects `partial` or `in-progress` status and
resumes automatically. Always re-run Phase 3 reconciliation in full on resume —
never skip it, even if some agent files exist.

**Sub-agent token limit:**
If an agent output is cut off, note it in the relevant `agents/` file and in
the digest. Flag the dimension as "incomplete — re-run recommended."

---

## Usage examples

```bash
# Plain topic — first run creates world model
/market-recon AI SDRs

# Capability area
/market-recon signal-to-deal orchestration

# PRD pasted inline — extraction agent normalizes it first
/market-recon [paste PRD here]

# Re-run on same topic — world model exists, picks up where it left off
/market-recon AI SDRs

# Narrow into something the scout surfaced
/market-recon autonomous AI SDR agents
```
