# Market Recon

A competitive intelligence tool powered by a team of AI analysts. Not a software project.

When opened, one command is available:

## /market-recon \<topic\>

Deploys a coordinated agent team to research any market, capability area, or pasted PRD.
Dimension analysts fan out in parallel, a scout finds what they miss, a buyer-side analyst
maps demand signals, and a fact-checker verifies every claim. Findings are synthesized into
an executive brief and a live 7-day pulse on every identified player. The world model grows
smarter with each run — the scout is always looking past what's already known.

**Examples:**
```
/market-recon AI SDRs
/market-recon revenue intelligence platforms
/market-recon signal-to-deal orchestration
/market-recon [paste PRD here]
```

## Output

All research lands in `research/<topic-slug>/`:
- `config.md` — the world model (grows smarter with every run)
- `digest.md` — full competitive landscape + competitive dynamics
- `executive-brief.md` — synthesized brief, framed for your role and decision
- `pulse-7d.md` — weekly player intelligence with velocity tracking
- `agents/` — raw output per analyst

## How the world model works

The first run maps the obvious landscape. Every subsequent run, the scout looks at what's
already known and searches past it. New players get logged, new angles get tracked, and
when an angle appears twice it gets promoted to a full research dimension. After Run 4,
a longitudinal brief synthesizes movement across all runs. Over time the research gets more
targeted and surfaces more interesting findings.

## Extending Market Recon

Specialists are domain-expert analysts you approve after the first run. They apply a specific
lens — SaaS metrics, healthcare regulatory signals, developer-tools adoption patterns — to
every subsequent brief. Define your own in `_specialists/` using `_template.md` as the base.
