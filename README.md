# market-recon

**Deploy a coordinated team of AI analysts to research any market. Gets smarter with every run.**

→ **[leeorlandi.github.io/market-recon](https://leeorlandi.github.io/market-recon/)**

---

Market Recon is a [Claude Code](https://claude.ai/code) skill that fans out a structured agent team across any competitive landscape. Dimension analysts research each capability lane in parallel, a scout finds what they miss, a buyer-side analyst reads what customers actually complain about, and a fact-checker resolves citations before anything gets written. Findings are synthesized into an executive brief framed for your role and decision.

The world model records everything discovered. The next run inherits it — the scout always searches past what's known.

## Requirements

- **Claude Code v2.1.32 or later** — check with `claude --version`
- **Agent teams enabled** — add to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

> Agent teams are experimental and disabled by default. The research pipeline depends on them — teammates share a task list and message each other directly to route findings and resolve citation failures.

## Install

**Project-scoped** (recommended for getting started):

```bash
git clone https://github.com/leeorlandi/market-recon
claude market-recon/
```

Then run your first recon:

```
/market-recon AI SDRs
```

**Global install** (makes `/market-recon` available in every project):

```bash
./install.sh
```

## How it works

```
/market-recon AI go-to-market tools
```

**Phase 0 — Scope check.** Market Recon parses your topic, verifies it produces a manageable number of dimensions (≤8), and asks two questions before deploying: your role in relation to the market, and what decision this research needs to support. This context shapes the entire brief.

**Phase 1 — World model.** Checks for an existing config at `research/<slug>/config.md`. First run: creates it with 4–7 capability dimensions. Subsequent runs: loads the world model and confirms context.

**Phase 2 — Agent team.** Deploys a coordinated research team via Claude Code agent teams:
- `dim-<slug>` — one dimension analyst per capability lane, running in parallel
- `scout` — unconstrained; finds players and angles the dimension analysts miss
- `buyer` — reads G2, Reddit, and community forums for what buyers actually say
- `fact-checker` — joins after research completes; messages agents directly to resolve citation failures

Teammates share a task list and communicate via `SendMessage` — a dimension analyst can route an out-of-scope find to the scout in real time, and the scout can flag lane-specific players back.

**Phase 3 — Digest.** Reconciles findings, dedupes players across dimensions, maps competitive dynamics (head-to-head matchups, partnerships, acquisition signals, velocity), and writes `digest.md`.

**Phase 3.5 — Synthesis.** A generalist synthesis agent produces an executive brief framed for your role and decision. Proposes and deploys specialist analysts — domain experts (PLG dynamics, SaaS metrics, enterprise adoption signals) that apply a specific lens to the findings.

**Phase 4 — 7-day pulse.** Live search on every identified player scoped to the past 7 days. On subsequent runs, reads prior pulses to flag velocity changes: who's accelerating, who's gone quiet.

**Phase 4+ — Longitudinal brief.** After Run 4, a longitudinal synthesis agent reads across all prior runs: which players have grown in signal density, which angles graduated or stalled, and what the market has done that wasn't predictable from Run 1.

## What you get

```
research/<topic-slug>/
├── config.md               ← world model (grows every run)
├── digest.md               ← competitive landscape + dynamics
├── executive-brief.md      ← brief framed for your role & decision
├── pulse-7d.md             ← 7-day live pulse with velocity tracking
├── longitudinal-brief.md   ← cross-run synthesis (Run 4+)
└── agents/
    ├── dim-<slug>.md       ← raw dimension analyst output
    ├── scout.md            ← what dimension agents missed
    ├── buyer.md            ← demand-side signals
    ├── fact-check.md       ← citation verification log
    └── synthesis-*.md      ← generalist + specialist briefs
```

## Extending with specialists

Specialists are domain-expert analysts you approve after the first run. The generalist synthesis agent reads the digest and proposes specialists that fit what was actually found — it won't propose a healthcare regulatory specialist if you're researching sales tools.

Once approved, a specialist is added to `_specialists/roster.md` and self-deploys on every subsequent run where their triggers are relevant. No intervention needed.

To build your own specialist, use `_specialists/_template.md` as the base. The `## Your domain lens` and `## What to prioritize` sections are where the value lives — be specific about what signals matter and what the generalist typically underweights.

## Citation standard

Every specific number, funding figure, date, and named statistic in the output carries a `[^N]` inline citation with a URL and access date. Claims that can't be sourced are labeled **(estimate)**. The fact-checker verifies high-stakes citations before the digest is written and messages agents directly to correct or flag unresolvable sources.

## License

MIT — see [LICENSE](LICENSE).
