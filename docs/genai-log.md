# GenAI log, week 3

Tool: Claude (desktop app, agent session) with access to my cloudops folder. No `AGENTS.md` rules were
loaded for this repository, so the "do not run cluster commands" rule from week 2 did not apply by itself.
The assistant could not reach my cluster or GitHub: I ran every cluster and Git command myself.

## What I asked

"Do the week 3 assignment from the slides: install what is needed, connect it, make everything work."
The assistant read `Lesson 3.pptx` and found the homework: put the lab application in a config repository,
let an Argo CD Application deploy it, break it on purpose, watch sync and health.

## What it generated

| Item | Kept / changed |
| --- | --- |
| Config repository layout (`base/`, `overlays/dev/`) | Kept. Matches slide 17. |
| `base/` = my week 2 manifests | Kept. Checked: rendered output equals the live week 2 manifests (no diff), so Argo CD adopts them. |
| Application `labqueue-dev` (automated, prune, selfHeal, CreateNamespace) | Kept. Same shape as slide 10. |
| `bootstrap/bootstrap.sh`, Argo CD v3.5.5 pinned, dex and notifications scaled to 0 | Kept. Reason: one 2 vCPU / 8 GB node. Version came from the Argo CD releases page, 2026-10-15. |
| ADR 0001 (separate repo, directories not branches) | Kept. Slide 18 and 19. |
| Base image tag `set-by-overlay` | Kept: a non-existing tag on purpose, so deploying the base alone fails fast. |

## Where the AI was wrong or sloppy

- The README break-it command used `sed -i.bak`, which is not how macOS `sed` works and leaves a stray file. Fixed to `sed -i ''`.
- `bootstrap.sh` sets `KUBECONFIG` only inside the script. In a new terminal, `kubectl` fell back to `localhost:8080`. I had to export it myself.
- The assistant first said "Argo CD will sync" without mentioning the ~3 minute polling delay. A manual refresh (annotation) made it visible at once.
- It assumed the config repo should live under my own GitHub account. The course may want it somewhere else: *to check on Toledo*.

## What I must double-check or do myself

- [ ] Read Chapter 3, including progressive delivery.
- [ ] Review the AI exercise (slide 33) and Spot the bugs (slide 34): answer **without AI** first.
- [ ] Observations in `README.md` for scenarios A to D, with my own output.
- [ ] I can explain: why `Synced` and `Degraded` can be true at once; what `selfHeal` and `prune` do and when they hurt.
