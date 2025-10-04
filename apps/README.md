# ArgoCD Applications

This directory contains ArgoCD Application definitions for GitOps-based deployment.

## Prerequisites

- OpenShift GitOps (ArgoCD) operator installed
- Access to the ArgoCD instance

## Applications

### 1. Node Feature Discovery (NFD)
**File**: `nfd-app.yaml`  
**Purpose**: Detects hardware features on nodes (required for GPU detection)

### 2. NVIDIA GPU Operator
**File**: `gpu-operator-app.yaml`  
**Purpose**: Manages GPU drivers and device plugins

### 3. LiteMaaS
**File**: `litemaas-app.yaml`  
**Purpose**: Main LiteMaaS application stack

## Deployment Order

Deploy in this order for proper dependency management:

```bash
# 1. Deploy NFD (required for GPU detection)
oc apply -f nfd-app.yaml

# 2. Deploy GPU Operator (after NFD is ready)
oc apply -f gpu-operator-app.yaml

# 3. Generate and apply secrets first
cd ..
./scripts/generate-secrets.sh
oc apply -f generated-secrets/

# 4. Deploy LiteMaaS
cd apps
oc apply -f litemaas-app.yaml
```

## All-in-One Deployment

To deploy everything at once:

```bash
# Deploy all ArgoCD applications
oc apply -f .
```

**Note**: Make sure secrets are generated and applied before LiteMaaS sync completes.

## Accessing ArgoCD UI

Get the ArgoCD route:
```bash
oc get route openshift-gitops-server -n openshift-gitops
```

Login with OpenShift credentials.

## Sync Policies

All applications are configured with:

- **Automated sync**: Changes in Git trigger automatic updates
- **Self-heal**: Drift from Git state is automatically corrected
- **Auto-prune**: Resources deleted from Git are removed from cluster

## Customization

To customize sync behavior, edit the respective application YAML:

```yaml
syncPolicy:
  automated:
    prune: true      # Auto-delete resources not in Git
    selfHeal: true   # Auto-fix drift from Git state
```

To disable automation (manual sync only):

```yaml
syncPolicy:
  # Remove or comment out the 'automated' section
  syncOptions:
    - CreateNamespace=true
```

## Troubleshooting

### Application not syncing

Check application status:
```bash
oc get application -n openshift-gitops
```

View detailed status:
```bash
oc describe application litemaas -n openshift-gitops
```

### Manual sync

Force a sync via CLI:
```bash
argocd app sync litemaas
```

Or via UI: Click "Sync" button in ArgoCD dashboard

### Sync fails due to missing secrets

Ensure secrets are created before syncing LiteMaaS:
```bash
./scripts/generate-secrets.sh
oc apply -f generated-secrets/
```

## Uninstall

Delete applications (this removes all deployed resources):

```bash
# Delete individual app
oc delete application litemaas -n openshift-gitops

# Delete all
oc delete -f .
```
