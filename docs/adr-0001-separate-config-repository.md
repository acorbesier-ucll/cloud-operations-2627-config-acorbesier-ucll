# ADR 0001: a separate config repository, directories per environment

## Status
Accepted (2026-10-15)

## Context
The Lab Queue app repository holds code, Dockerfile and the CI workflow. Argo CD needs a Git
repository that describes the desired state of the cluster.

## Decision
- Manifests live in this separate repository, not in the app repository.
- Environments are directories (`apps/labqueue/overlays/<env>`) on branch `main`, not branches.
- Shared manifests are in `base/`, the image tag is the only thing an overlay sets.
- CI (GitHub Actions in the app repository) builds and pushes an image tagged with the commit SHA.
  It has no cluster credentials. A release is a pull request in this repository that changes `newTag`.
- Secrets (`labqueue-db`, `ghcr-pull`) are not in Git. They are created by hand until lesson 5.
- The repository is public, so Argo CD needs no repository credentials. It contains no secrets.

## Consequences
- A config change does not trigger a CI build, and a deploy has its own history and review.
- Two repositories to keep in mind.
- Promotion to another environment is a one-line pull request. `diff -r overlays/dev overlays/prod`
  shows exactly what changes.
- Not automated yet: opening the pull request with the new tag (Argo CD Image Updater, Renovate or a CI step).
