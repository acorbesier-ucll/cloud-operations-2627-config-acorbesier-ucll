# GenAI log, week 3

**Tool:** Claude (desktop app, agent session)  
**Approach:** I implemented the week 3 assignment myself and used Claude to review my work, identify
potential issues and verify the configuration.

## What I did

I asked Claude to review the week 3 assignment in the slides and help me verify that my
implementation met the requirements. The assignment was to move the lab application into a
configuration repository, deploy it through an Argo CD Application, deliberately introduce a problem
and observe the resulting sync and health status.

I created the configuration repository structure with `base/` and `overlays/dev/`, based on
slide 17. I reused my week 2 manifests and checked that the rendered output matched the existing
live manifests, ensuring that Argo CD could adopt the existing resources without introducing
configuration differences.

I also configured the `labqueue-dev` Argo CD Application with automated synchronization, pruning,
self-healing and namespace creation. I created a bootstrap script, pinned Argo CD to version 3.5.5
and scaled Dex and Notifications to zero to accommodate the resources available on my single-node
cluster (2 vCPU and 8 GB RAM). Additionally, I documented the decision to use a separate
configuration repository with directories instead of branches in ADR 0001.

To test failure handling, I configured the base image tag as `set-by-overlay`, which does not exist.
This allows me to demonstrate what happens when the base configuration is deployed without the
required overlay.

## How I used Claude

I implemented the configuration and used Claude as a review tool to check my decisions, compare the
manifests and identify mistakes. Claude could not access my Kubernetes cluster or GitHub repository,
so I executed all cluster and Git commands myself and verified the results.

The review also helped me identify several issues:

- **macOS compatibility:** The README initially used `sed -i.bak`, which was not appropriate for the
  intended macOS command. I corrected it to `sed -i ''`.
- **Kubernetes configuration:** The bootstrap script only set `KUBECONFIG` within its own execution.
  I had to export the variable manually in a new terminal to ensure `kubectl` used the correct
  configuration.
- **Argo CD refresh behaviour:** I verified that synchronization was not immediately visible because
  of the polling interval. I used a manual refresh annotation to trigger an update sooner.
- **Repository ownership:** The configuration repository was initially assumed to belong under my
  personal GitHub account. I still need to confirm the correct location with Toledo.

## What I still need to do

- [ ] Read Chapter 3, including progressive delivery.
- [ ] Complete the AI exercise on slide 33 and _Spot the Bugs_ on slide 34 independently, before
      consulting AI.
- [ ] Record my own observations and command output for scenarios A to D in `README.md`.
- [ ] Make sure I can explain why an application can be both `Synced` and `Degraded`, what
      `selfHeal` and `prune` do, and when these features can cause problems.

## Reflection

This assignment helped me practise configuring GitOps with Argo CD and managing Kubernetes manifests
through a configuration repository. I made the implementation decisions and carried out the commands
myself, while using Claude to review the configuration and catch potential mistakes. The process
also showed me that AI-generated suggestions still need to be tested in the actual environment,
particularly when dealing with operating-system differences, Kubernetes configuration and Argo CD
synchronisation behaviour.
