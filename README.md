# LiteMaaS Deployment on OpenShift

This repository contains all the YAML configurations for deploying LiteMaaS on OpenShift with GPU support.

## Structure

```
.
├── apps/                      # ArgoCD Application definitions
├── base/                      # Base configurations
│   ├── litemaas/             # LiteMaaS components
│   ├── gpu-operator/         # NVIDIA GPU Operator
│   └── nfd/                  # Node Feature Discovery
├── overlays/                 # Environment-specific overlays
│   └── production/
└── machineset/               # GPU MachineSet configurations
```

## Prerequisites

- OpenShift 4.18+ cluster
- Cluster admin access
- ArgoCD installed (optional, for GitOps deployment)

## Quick Start

### Option 1: Manual Deployment

1. **Deploy Node Feature Discovery:**
   ```bash
   oc apply -k base/nfd/
   ```

2. **Deploy NVIDIA GPU Operator:**
   ```bash
   oc apply -k base/gpu-operator/
   ```

3. **Create GPU MachineSet (optional):**
   ```bash
   # Update the MachineSet with your cluster details first
   oc apply -f machineset/gpu-machineset.yaml
   ```

4. **Deploy LiteMaaS:**
   ```bash
   oc apply -k base/litemaas/
   ```

### Option 2: ArgoCD Deployment

1. **Deploy the ArgoCD Application:**
   ```bash
   oc apply -f apps/litemaas-app.yaml
   ```

2. **Sync the application:**
   ```bash
   argocd app sync litemaas
   ```

## Configuration

### Environment Variables

Update the following files with your environment-specific values:

- `base/litemaas/backend-secret.yaml` - Update passwords and secrets
- `base/litemaas/postgres-secret.yaml` - Update database password
- `machineset/gpu-machineset.yaml` - Update cluster name and region

### GPU Configuration

The GPU MachineSet is configured for AWS g6.2xlarge instances with NVIDIA L4 GPUs.
To modify:

1. Edit `machineset/gpu-machineset.yaml`
2. Change `instanceType` to your desired GPU instance type
3. Update resource annotations accordingly

## Components

### LiteMaaS
- **Backend**: Node.js API server with PostgreSQL
- **Frontend**: React web interface
- **LiteLLM**: Proxy for LLM APIs
- **PostgreSQL**: Database for user and model management

### GPU Stack
- **Node Feature Discovery**: Hardware feature detection
- **NVIDIA GPU Operator**: GPU driver and device plugin management
- **ClusterPolicy**: GPU operator configuration

## Access

After deployment, access LiteMaaS at:
```
https://litemaas-<namespace>.<cluster-domain>
```

LiteLLM admin UI:
```
https://litellm-<namespace>.<cluster-domain>/ui
Username: admin
Password: Check backend-secret
```

## Troubleshooting

### GPU Nodes Not Ready

Check GPU operator status:
```bash
oc get pods -n nvidia-gpu-operator
oc get clusterpolicy -n nvidia-gpu-operator
```

### LiteMaaS Backend Issues

Check logs:
```bash
oc logs -f deployment/backend -n litemaas
```

### Database Connection Issues

Verify PostgreSQL is running:
```bash
oc get pods -n litemaas -l app=postgres
oc logs -f statefulset/postgres -n litemaas
```

## License

MIT
