# Lab Queue: config repository (GitOps)

Desired state of Lab Queue on my cluster (`labqueue.113.co.ucll.cloud`). Argo CD pulls from this
repository. Nobody runs `kubectl apply` for the app any more. App code and CI live in
[`cloud-operations-2627-homework-week-2-acorbesier-ucll`](https://github.com/Cloud-Operations-UCLL/cloud-operations-2627-homework-week-2-acorbesier-ucll).
GenAI log: [`docs/genai-log.md`](docs/genai-log.md). Design choices: [`docs/adr-0001-separate-config-repository.md`](docs/adr-0001-separate-config-repository.md).

```text
.
├── README.md
├── apps/labqueue/
│   ├── base/                       # shared manifests (same as week 2)
│   │   ├── kustomization.yaml
│   │   ├── configmap.yaml  deployment.yaml  service.yaml  httproute.yaml
│   │   └── postgres-service.yaml  postgres-statefulset.yaml
│   └── overlays/dev/kustomization.yaml   # image tag = the release
├── argocd/labqueue-dev.yaml        # the Application (applied once by bootstrap)
├── bootstrap/
│   ├── bootstrap.sh                # install Argo CD + create the Application
│   └── argocd/kustomization.yaml   # pinned Argo CD v3.5.5, dex and notifications off
└── docs/adr-0001-separate-config-repository.md
```

## Setup (once)

The Secrets are not in Git. They already exist in namespace `labqueue` from week 2 (`labqueue-db`,
`ghcr-pull`). On a fresh cluster, create them first as described in the week 2 `infra/README.md`.

```bash
# 1. Push this folder as its own repository (public, no secrets inside)
cd cloud-operations-2627-config-acorbesier-ucll
git init -b main && git add -A && git commit -m "Config repository for Lab Queue"
gh repo create acorbesier-ucll/cloud-operations-2627-config-acorbesier-ucll --public --source=. --push

# 2. Install Argo CD and create the Application
./bootstrap/bootstrap.sh
```

If the GitHub account or repository name differs, change `repoURL` in `argocd/labqueue-dev.yaml` first.

Check:

```bash
kubectl -n argocd get applications          # labqueue-dev   Synced   Healthy
kubectl -n labqueue get pods
curl -s http://labqueue.113.co.ucll.cloud/api/info
```

The existing Deployment, StatefulSet and Service are adopted, not recreated: the rendered manifests are
identical to week 2, so the database and its PVC are untouched.

UI: `kubectl -n argocd port-forward svc/argocd-server 8443:443`, open https://localhost:8443, user `admin`,
password from `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`.

## Release

1. Push to `main` in the app repository, wait for the green run, copy the commit SHA.
2. Change `newTag` in `apps/labqueue/overlays/dev/kustomization.yaml`, commit and push (or pull request).
3. Argo CD syncs within about 3 minutes (or press Refresh). Watch: `kubectl -n labqueue rollout status deployment/labqueue`.

Rollback = `git revert <commit>` and push.

## Break it on purpose

Run each experiment and watch `kubectl -n argocd get applications -w` and the UI. Paste your own output
under "Observations".

### A. A bad tag in Git

```bash
sed -i '' 's/newTag: .*/newTag: does-not-exist/' apps/labqueue/overlays/dev/kustomization.yaml   # macOS sed
git commit -am "Break it: bad tag" && git push
kubectl -n argocd get applications -w
kubectl -n labqueue get pods
kubectl -n labqueue describe pod -l app.kubernetes.io/name=labqueue | grep -A3 -i "failed\|backoff"
curl -s http://labqueue.113.co.ucll.cloud/api/info
git revert --no-edit HEAD && git push        # fix: back to a known commit
```

Expect: the Application becomes `Synced` (cluster matches Git) but not `Healthy` (`Progressing`, then
`Degraded`): the new pod is in `ImagePullBackOff`. The two old pods keep serving (`maxUnavailable: 0`), so the site stays up.
Synced is not healthy.

### B. A manual change in the cluster

```bash
kubectl -n labqueue scale deployment/labqueue --replicas=5
kubectl -n labqueue get pods -w
```

Expect: `selfHeal` puts it back to 2 within seconds. Now turn selfHeal off and repeat to see `OutOfSync`:

```bash
kubectl -n argocd patch application labqueue-dev --type merge \
  -p '{"spec":{"syncPolicy":{"automated":{"selfHeal":false}}}}'
kubectl -n labqueue scale deployment/labqueue --replicas=5
kubectl -n argocd get application labqueue-dev            # OutOfSync
kubectl -n argocd patch application labqueue-dev --type merge \
  -p '{"spec":{"syncPolicy":{"automated":{"selfHeal":true}}}}'   # heals again
```

### C. Delete something

```bash
kubectl -n labqueue delete service labqueue    # recreated by Argo CD
kubectl -n labqueue get service labqueue -w
```

### D. Delete a manifest from Git (prune)

```bash
git rm apps/labqueue/base/postgres-service.yaml
sed -i '' '/postgres-service.yaml/d' apps/labqueue/base/kustomization.yaml   # macOS sed
git commit -am "Break it: remove postgres Service" && git push
kubectl -n argocd annotate application labqueue-dev argocd.argoproj.io/refresh=normal --overwrite
kubectl -n labqueue get service -w        # the postgres Service disappears (prune)
kubectl -n labqueue get pods              # the app loses its database: readiness fails
git revert --no-edit HEAD && git push     # and it comes back
```

Expect: `prune: true` deletes the Service because it is no longer in Git. The app pods go `0/1 READY`
(`/readyz` cannot reach `postgres`), the database pod itself keeps running. Why is `prune` dangerous when a path is wrong?

### Observations

(fill in: what you saw for A, B and C, with the sync status and health status at each step)
