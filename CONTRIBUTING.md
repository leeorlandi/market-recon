# Contributing to market-recon

Thanks for your interest. Contributions fall into a few natural categories.

---

## Reporting bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). The most useful bug reports include:
- The exact command you ran
- Which phase failed (Phase 0 through 5)
- The contents of the relevant `agents/` file if an agent produced unexpected output
- Your Claude Code version (`claude --version`)

---

## Improving the skill

The core logic lives in `.claude/skills/market-recon/SKILL.md`. Changes here affect every run. Before submitting a PR:

- Test against at least two different topics — one well-documented market, one sparse or emerging
- Verify the citation standard is preserved: every specific number needs `[^N]` inline
- Check that Phase 5 self-check conditions still pass for your change
- Don't break the agent team naming convention (`dim-<slug>`, `scout`, `buyer`, `fact-checker`) — teammates reference each other by these names via `SendMessage`

---

## Contributing a specialist

This is the highest-value contribution. A specialist is a domain-expert analyst that self-deploys when relevant research is detected. Good specialists are specific and opinionated — they apply a lens the generalist can't.

Use the [specialist contribution template](.github/ISSUE_TEMPLATE/specialist_contribution.md) to propose one, or submit a PR directly:

1. Copy `_specialists/_template.md` to `_specialists/<your-specialist-slug>.md`
2. Fill in every section — especially `## Your domain lens` and `## What to prioritize`. Generic placeholders will be rejected.
3. Add an entry to `_specialists/roster.md` under `## Active Specialists`
4. Include in your PR description: what markets this specialist is designed for, what the generalist typically underweights that this specialist catches, and what topics should trigger self-deployment

Good specialist domains to contribute:
- Vertical SaaS (healthcare, legal, fintech, edtech) — regulatory and reimbursement signals that a generalist misses
- Developer tools — adoption signals (GitHub stars, StackOverflow mentions, job postings as a leading indicator)
- Marketplace dynamics — liquidity signals, take rate analysis, supply/demand balance
- Open source + commercial — dual-licensing tension, community health as a competitive moat signal

---

## Improving prompts

The `_prompts/` files define how each agent approaches its task. Changes here affect research quality directly. A few principles:

- Keep the citation requirement explicit and non-negotiable in every agent prompt
- Don't remove the team coordination sections — inter-agent messaging is load-bearing
- If you add a new output format, update Phase 5's self-check list in `SKILL.md`

---

## What we're not looking for

- Changes to `research/` (gitignored, runtime output)
- Prompt changes that produce longer output without increasing quality
- Abstractions that optimize for hypothetical future cases — the skill should stay legible

---

## Questions

Open a [discussion](https://github.com/leeorlandi/market-recon/discussions) rather than an issue for questions about usage, research quality, or specialist design.
