# LiteMaaS GitOps Deployment

This repository contains the GitOps configuration for deploying LiteMaaS on OpenShift using ArgoCD.

## 📋 Overview

This deployment uses OpenShift GitOps (ArgoCD) to automatically deploy and manage:
- **GPU MachineSet** - Provisions GPU-enabled worker nodes
- **Node Feature Discovery (NFD)** - Detects hardware features
- **NVIDIA GPU Operator** - Manages GPU resources
- **LiteMaaS** - AI Model as a Service platform
  - PostgreSQL Database
  - LiteLLM Proxy (OpenAI-compatible API gateway)

## 🏗️ Repository Structure

```
litemaas-deployment/
├── apps/                          # ArgoCD Application definitions
│   ├── gpu-machineset-app.yaml   # GPU MachineSet
│   ├── nfd-app.yaml              # Node Feature Discovery
│   ├── nvidia-gpu-operator-app.yaml
│   └── litemaas-app.yaml         # LiteMaaS application
├── base/
│   ├── gpu-machineset/
│   │   ├── kustomization.yaml
│   │   └── gpu-machineset.yaml   # GPU node configuration
│   ├── nfd/
│   │   └── kustomization.yaml
│   ├── nvidia-gpu-operator/
│   │   └── kustomization.yaml
│   └── litemaas/
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       └── generated-secrets/
└── README.md
```

## 🚀 Deployment

### Prerequisites
- OpenShift 4.x cluster on AWS
- OpenShift GitOps operator installed
- GitHub repository access

### Complete Deployment Order

Deploy in this order for proper dependency management:

```bash
# 1. Deploy GPU MachineSet (provisions GPU nodes)
oc apply -f apps/gpu-machineset-app.yaml

# Wait for GPU node to be ready (5-10 minutes)
watch oc get machines -n openshift-machine-api

# 2. Deploy Node Feature Discovery
oc apply -f apps/nfd-app.yaml

# 3. Deploy NVIDIA GPU Operator
oc apply -f apps/nvidia-gpu-operator-app.yaml

# 4. Deploy LiteMaaS
oc apply -f apps/litemaas-app.yaml
```

### Quick Deploy All

```bash
# Deploy all applications at once (ArgoCD handles dependencies)
oc apply -f apps/
```

### Monitor Deployment

```bash
# Check ArgoCD applications
oc get applications -n openshift-gitops

# Check GPU node provisioning
oc get machines -n openshift-machine-api
oc get nodes -l node-role.kubernetes.io/gpu

# Check GPU operator status
oc get pods -n nvidia-gpu-operator

# Check LiteMaaS pods
oc get pods -n litemaas

# Get LiteLLM route URL
oc get route litellm -n litemaas
```

## 🖥️ GPU MachineSet Configuration

### Important Notes
⚠️ **The GPU MachineSet is cluster-specific** and requires customization for your environment:

1. **Update AMI ID**: The AMI must match your cluster's RHCOS version
   ```yaml
   ami:
     id: ami-0adb8862ffe5cc2ab  # Get from existing worker machines
   ```

2. **Update Cluster Name**: Replace `cluster-5wkv7-42286` with your cluster name
   ```yaml
   metadata:
     name: <YOUR-CLUSTER-NAME>-gpu-worker-us-east-2b
   ```

3. **Update Availability Zone**: Match your cluster's zone
   ```yaml
   placement:
     availabilityZone: us-east-2b  # Your AZ
     region: us-east-2             # Your region
   ```

### Getting Cluster-Specific Values

```bash
# Get your cluster name
oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}'

# Get AMI ID from existing worker
oc get machine -n openshift-machine-api \
  $(oc get machines -n openshift-machine-api -l machine.openshift.io/cluster-api-machine-role=worker -o name | head -1) \
  -o jsonpath='{.spec.providerSpec.value.ami.id}'

# Get availability zones
oc get machines -n openshift-machine-api \
  -o jsonpath='{range .items[*]}{.spec.providerSpec.value.placement.availabilityZone}{"\n"}{end}' | sort -u
```

## 🔐 Secrets Configuration

### ⚠️ IMPORTANT: Update Secrets for Production

Before deploying to production, update the following files with secure credentials:

1. **PostgreSQL Secret** (`base/litemaas/generated-secrets/postgres-secret.yaml`)
2. **LiteLLM Secret** (`base/litemaas/generated-secrets/litellm-secret.yaml`)
3. **Backend Secret** (`base/litemaas/generated-secrets/backend-secret.yaml`)

### Default Credentials (Development Only)
- **LiteLLM UI Username**: `admin`
- **LiteLLM UI Password**: `changeme456`
- **LiteLLM Master Key**: `sk-1234567890abcdef`
- **PostgreSQL Password**: `changeme123`

## 📦 Components

### 1. GPU MachineSet
- **Purpose**: Provisions AWS EC2 GPU instances (g6.2xlarge) as OpenShift worker nodes
- **Namespace**: `openshift-machine-api`
- **Features**:
  - NVIDIA L4 GPU (24GB GDDR6)
  - Node taint: `nvidia.com/gpu=true:NoSchedule`
  - Node label: `node-role.kubernetes.io/gpu=`
- **Status Check**: `oc get machinesets -n openshift-machine-api`

### 2. Node Feature Discovery (NFD)
- **Purpose**: Detects hardware capabilities and labels nodes
- **Namespace**: `openshift-nfd`
- **Status Check**: `oc get pods -n openshift-nfd`

### 3. NVIDIA GPU Operator
- **Purpose**: Automates GPU driver installation and management
- **Namespace**: `nvidia-gpu-operator`
- **Status Check**: `oc get clusterpolicy -n nvidia-gpu-operator`

### 4. LiteMaaS
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

### Scale GPU Nodes
```bash
# Scale up GPU nodes
oc scale machineset <cluster-name>-gpu-worker-<zone> --replicas=2 -n openshift-machine-api

# Scale down GPU nodes
oc scale machineset <cluster-name>-gpu-worker-<zone> --replicas=0 -n openshift-machine-api
```

### Update Secrets
After updating secrets in Git, ArgoCD will automatically sync changes within 3 minutes.

### View Logs
```bash
# GPU operator logs
oc logs -n nvidia-gpu-operator -l app=nvidia-driver-daemonset

# LiteLLM logs
oc logs -f deployment/litellm -n litemaas

# PostgreSQL logs
oc logs -f postgres-0 -n litemaas
```

## 🐛 Troubleshooting

### GPU MachineSet Issues

**Machine in Failed State:**
```bash
# Check machine status
oc get machine <machine-name> -n openshift-machine-api -o yaml

# Common issues:
# - Invalid AMI ID: Update with correct RHCOS AMI
# - Instance type not available: Check AWS service quotas
# - Subnet/security group issues: Verify cluster configuration
```

**GPU Node Not Joining Cluster:**
```bash
# Check machine-api-operator logs
oc logs -n openshift-machine-api -l k8s-app=machine-api-operator

# Check node status
oc get nodes -l node-role.kubernetes.io/gpu
oc describe node <gpu-node-name>
```

### GPU Operator Not Ready
```bash
# Check GPU operator pods
oc get pods -n nvidia-gpu-operator

# Verify NFD is running first
oc get pods -n openshift-nfd

# Check node labels
oc get nodes --show-labels | grep nvidia
```

### ArgoCD Application Not Syncing
```bash
# Check application status
oc get application -n openshift-gitops

# Force refresh
oc annotate application gpu-machineset -n openshift-gitops argocd.argoproj.io/refresh=hard --overwrite
```

## 📚 Additional Resources

- [LiteLLM Documentation](https://docs.litellm.ai/)
- [OpenShift GitOps](https://docs.openshift.com/gitops/)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)
- [OpenShift Machine API](https://docs.openshift.com/container-platform/latest/machine_management/index.html)

## ⚠️ Production Checklist

Before deploying to production:
- [ ] Update GPU MachineSet with cluster-specific values (AMI, cluster name, zones)
- [ ] Verify AWS service quotas for GPU instances (g6.2xlarge)
- [ ] Update all default passwords and API keys
- [ ] Configure proper backup strategy for PostgreSQL
- [ ] Set up monitoring and alerting (GPU metrics, node health)
- [ ] Review resource limits and requests
- [ ] Configure proper RBAC and network policies
- [ ] Set up log aggregation
- [ ] Configure high availability for LiteLLM (multiple replicas)
- [ ] Review and harden security contexts
- [ ] Test GPU workload scheduling with node taints/tolerations
