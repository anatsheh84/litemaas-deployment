# LiteMaaS GitOps Deployment

This repository contains the GitOps configuration for deploying LiteMaaS on OpenShift using ArgoCD.

## 📋 Overview

This deployment uses OpenShift GitOps (ArgoCD) to automatically deploy and manage:
- **Node Feature Discovery (NFD)** - Detects hardware features
- **NVIDIA GPU Operator** - Manages GPU resources
- **LiteMaaS** - AI Model as a Service platform
  - PostgreSQL Database
  - LiteLLM Proxy (OpenAI-compatible API gateway)

## 🏗️ Repository Structure

```
litemaas-deployment/
├── apps/                          # ArgoCD Application definitions
│   ├── litemaas-app.yaml         # LiteMaaS application
│   ├── nfd-app.yaml              # Node Feature Discovery
│   └── nvidia-gpu-operator-app.yaml
├── base/
│   ├── litemaas/
│   │   ├── kustomization.yaml    # Main kustomization file
│   │   ├── namespace.yaml        # Namespace definition
│   │   └── generated-secrets/    # Secret configurations
│   │       ├── postgres-secret.yaml
│   │       ├── backend-secret.yaml
│   │       └── litellm-secret.yaml
│   ├── nfd/
│   │   └── kustomization.yaml
│   └── nvidia-gpu-operator/
│       └── kustomization.yaml
└── README.md
```

## 🚀 Deployment

### Prerequisites
- OpenShift 4.x cluster with GPU nodes
- OpenShift GitOps operator installed
- GitHub repository access

### Initial Setup

1. **Install OpenShift GitOps Operator** (if not already installed):
   ```bash
   oc apply -f https://raw.githubusercontent.com/redhat-developer/gitops-operator/master/deploy/operator.yaml
   ```

2. **Apply ArgoCD Applications**:
   ```bash
   oc apply -f apps/nfd-app.yaml
   oc apply -f apps/nvidia-gpu-operator-app.yaml
   oc apply -f apps/litemaas-app.yaml
   ```

3. **Monitor Deployment**:
   ```bash
   # Check ArgoCD applications
   oc get applications -n openshift-gitops
   
   # Check LiteMaaS pods
   oc get pods -n litemaas
   
   # Get LiteLLM route URL
   oc get route litellm -n litemaas
   ```

## 🔐 Secrets Configuration

### ⚠️ IMPORTANT: Update Secrets for Production

Before deploying to production, update the following files with secure credentials:

1. **PostgreSQL Secret** (`base/litemaas/generated-secrets/postgres-secret.yaml`):
   ```yaml
   stringData:
     username: postgres
     password: <CHANGE-THIS-SECURE-PASSWORD>
   ```

2. **LiteLLM Secret** (`base/litemaas/generated-secrets/litellm-secret.yaml`):
   ```yaml
   stringData:
     database-url: postgresql://postgres:<POSTGRES-PASSWORD>@postgres:5432/litemaas_db
     master-key: <CHANGE-THIS-SECURE-API-KEY>
     ui-username: <CHANGE-USERNAME>
     ui-password: <CHANGE-THIS-SECURE-PASSWORD>
   ```

3. **Backend Secret** (`base/litemaas/generated-secrets/backend-secret.yaml`):
   ```yaml
   stringData:
     DATABASE_URL: postgresql://postgres:<POSTGRES-PASSWORD>@postgres:5432/litemaas_db
     SECRET_KEY: <CHANGE-THIS-SECURE-SECRET-KEY>
     ALLOWED_ORIGINS: "https://your-domain.com"
   ```

### Default Credentials (Development Only)
- **LiteLLM UI Username**: `admin`
- **LiteLLM UI Password**: `changeme456`
- **LiteLLM Master Key**: `sk-1234567890abcdef`
- **PostgreSQL Password**: `changeme123`

## 📦 Components

### Node Feature Discovery (NFD)
- **Purpose**: Detects hardware capabilities and labels nodes
- **Namespace**: `openshift-nfd`
- **Status Check**: `oc get pods -n openshift-nfd`

### NVIDIA GPU Operator
- **Purpose**: Automates GPU driver installation and management
- **Namespace**: `nvidia-gpu-operator`
- **Status Check**: `oc get clusterpolicy -n nvidia-gpu-operator`

### LiteMaaS
- **Purpose**: AI Model serving platform with LiteLLM proxy
- **Namespace**: `litemaas`
- **Components**:
  - PostgreSQL StatefulSet (persistent database)
  - LiteLLM Deployment (AI proxy service)
  - OpenShift Routes (external access)

## 🌐 Access

After deployment, access LiteLLM at the route URL:

```bash
# Get the URL
LITELLM_URL=$(oc get route litellm -n litemaas -o jsonpath='{.spec.host}')
echo "LiteLLM UI: https://${LITELLM_URL}"
```

## 🔧 Maintenance

### Update Secrets
After updating secrets in Git, ArgoCD will automatically sync changes. To force immediate sync:
```bash
oc delete pod -l app=litellm -n litemaas
oc delete pod postgres-0 -n litemaas  # Be careful - will cause downtime
```

### View Logs
```bash
# LiteLLM logs
oc logs -f deployment/litellm -n litemaas

# PostgreSQL logs
oc logs -f postgres-0 -n litemaas
```

### Scale LiteLLM
```bash
oc scale deployment litellm --replicas=3 -n litemaas
```

## 🐛 Troubleshooting

### ArgoCD Application Not Syncing
```bash
# Check application status
oc get application litemaas -n openshift-gitops -o yaml

# Force refresh
oc annotate application litemaas -n openshift-gitops argocd.argoproj.io/refresh=hard --overwrite
```

### LiteLLM Pod Stuck in Init
- Check if PostgreSQL is ready: `oc logs postgres-0 -n litemaas`
- Verify secret has correct database URL with matching credentials

### Database Connection Issues
1. Check secrets match between postgres-secret and litellm-secret
2. Verify PostgreSQL service: `oc get svc postgres -n litemaas`
3. Test connection from litellm pod:
   ```bash
   oc exec -it deployment/litellm -n litemaas -- sh
   psql $DATABASE_URL -c '\l'
   ```

## 📚 Additional Resources

- [LiteLLM Documentation](https://docs.litellm.ai/)
- [OpenShift GitOps](https://docs.openshift.com/gitops/)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in a development cluster
5. Submit a pull request

## 📝 Notes

- This configuration uses `raw.githubusercontent.com` URLs to fetch deployment manifests from the upstream LiteMaaS repository
- ArgoCD auto-sync is enabled with self-healing
- PostgreSQL uses a 10Gi persistent volume claim
- TLS termination is handled by OpenShift Routes

## ⚠️ Production Checklist

Before deploying to production:
- [ ] Update all default passwords and API keys
- [ ] Configure proper backup strategy for PostgreSQL
- [ ] Set up monitoring and alerting
- [ ] Review resource limits and requests
- [ ] Configure proper RBAC and network policies
- [ ] Enable authentication for ArgoCD UI
- [ ] Set up log aggregation
- [ ] Configure high availability for LiteLLM (multiple replicas)
- [ ] Review and harden security contexts
