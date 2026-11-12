# GitOps repo (seed)

Copy this folder into its **own** GitHub repository (e.g. `YOUR_ORG/idp-gitops`).
It is the single source of truth for what runs in the cluster.

```
charts/service/        one generic Helm chart (≈ Devtron "Deployment Template")
apps/<name>/app.yaml   name + namespace + owner  -> read by the ApplicationSet
apps/<name>/values.yaml  per-app overrides       -> passed to the chart
apps/<name>/catalog-info.yaml  portal metadata   -> read by Backstage
bootstrap/applicationset.yaml  applied once by an admin
```

Flow: portal template opens a PR adding/changing `apps/<name>/` → reviewer merges →
ApplicationSet creates/updates the Argo CD Application → Argo CD syncs the cluster.
Rollback = revert the PR (or pick an older revision in Argo CD; see docs).
