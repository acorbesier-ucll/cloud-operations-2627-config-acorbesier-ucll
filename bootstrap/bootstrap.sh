#!/usr/bin/env bash
# One-time setup: install Argo CD, then hand it the labqueue-dev Application.
# After this, Git is the only way in: change apps/ and push, Argo CD does the rest.
set -euo pipefail
cd "$(dirname "$0")/.."

export KUBECONFIG="${KUBECONFIG:-$PWD/../kubeconfig.yaml}"

echo ">> Cluster check (opens the Omni login in your browser the first time)"
kubectl get nodes

echo ">> Installing Argo CD (pinned in bootstrap/argocd/kustomization.yaml)"
kubectl get namespace argocd >/dev/null 2>&1 || kubectl create namespace argocd
# Server-side apply: the Argo CD CRDs are too large for client-side apply annotations.
kubectl apply --server-side -k bootstrap/argocd

echo ">> Waiting for Argo CD"
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
for d in argocd-server argocd-repo-server argocd-redis argocd-applicationset-controller; do
  kubectl -n argocd rollout status "deployment/$d" --timeout=300s
done

echo ">> Creating the Application (the repository must already be pushed to GitHub)"
kubectl apply -f argocd/labqueue-dev.yaml

echo ">> Result"
kubectl -n argocd get applications
cat <<'MSG'

Next:
  kubectl -n argocd get applications -w
  # UI: kubectl -n argocd port-forward svc/argocd-server 8443:443  -> https://localhost:8443  (user: admin)
  # Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
MSG
