# LiteMaaS Deployment Guide

Complete guide for deploying LiteMaaS on OpenShift with GPU support.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [ArgoCD Deployment](#argocd-deployment)
5. [GPU Configuration](#gpu-configuration)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required

- OpenShift 4.18+ cluster
- Cluster admin access
- `oc` CLI tool installed
- `kubectl` CLI tool installed
- OpenSSL (for secret generation)

### Optional

- ArgoCD/OpenShift GitOps operator (for GitOps deployment)
- AWS account (for GPU nodes on AWS)

## Quick Start

For experienced users:

```bash
# Clone repository
git clone https://github.com/anatsheh84/litemaas-deployment.git
cd litemaas-deployment

# Generate secrets
chmod +x scripts/generate-secrets.sh
./scripts/generate-secrets.sh

# Deploy everything
oc apply -k base/nfd/
oc apply -k base/gpu-operator/
oc apply -f generated-secrets/
oc apply -k base/litemaas/

# Create GPU MachineSet (optional)
# Update machineset/gpu-machineset-template.yaml first
oc apply -f machineset/gpu-machineset.yaml
```

## Step-by-Step Deployment

### 1. Clone Repository

```bash
git clone https://github.com/anatsheh84/litemaas-deployment.git
cd litemaas-deployment
```

### 2. Generate Secrets

```bash
chmod +x scripts/generate-secrets.sh
./scripts/generate-secrets.sh
```

Enter your cluster domain when prompted (e.g., `apps.cluster-xyz.example.com`).

This creates:
- `generated-secrets/postgres-secret.yaml`
- `generated-secrets/backend-secret.yaml`
- `generated-secrets/litellm-secret.yaml`
- `generated-secrets/CREDENTIALS.txt` (save this securely!)

### 3. Deploy Node Feature Discovery

NFD detects hardware features on nodes:

```bash
oc apply -k base/nfd/
```

Wait for operator to install:
```bash
oc get pods -n openshift-nfd -w
```

### 4. Deploy NVIDIA GPU Operator

```bash
oc apply -k base/gpu-operator/
```

Wait for operator to install:
```bash
oc get pods -n nvidia-gpu-operator -w
```

### 5. Create GPU MachineSet (Optional)

If you need GPU nodes:

```bash
# Get your cluster details
CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
echo "Cluster name: $CLUSTER_NAME"

# Edit the MachineSet template
cd machineset
cp gpu-machineset-template.yaml gpu-machineset.yaml

# Update gpu-machineset.yaml with your values:
# - CLUSTER_NAME
# - ZONE (e.g., us-east-2b)
# - REGION (e.g., us-east-2)
# - AMI_ID

# Apply the MachineSet
oc apply -f gpu-machineset.yaml

# Watch the machine being created
oc get machines -n openshift-machine-api -w
```

### 6. Apply Secrets

```bash
cd ..
oc apply -f generated-secrets/
```

### 7. Deploy LiteMaaS

```bash
oc apply -k base/litemaas/
```

Watch deployment:
```bash
oc get pods -n litemaas -w
```

## ArgoCD Deployment

If you have OpenShift GitOps installed:

### 1. Install OpenShift GitOps

```bash
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

### 2. Deploy Applications

```bash
# Deploy in order
oc apply -f apps/nfd-app.yaml
oc apply -f apps/gpu-operator-app.yaml

# Generate and apply secrets
./scripts/generate-secrets.sh
oc apply -f generated-secrets/

# Deploy LiteMaaS
oc apply -f apps/litemaas-app.yaml
```

### 3. Access ArgoCD UI

```bash
# Get route
oc get route openshift-gitops-server -n openshift-gitops

# Get admin password
oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\\.password}' | base64 -d
```

## GPU Configuration

### Create ClusterPolicy

After GPU operator is installed and GPU nodes are ready:

```bash
cat <<EOF | oc apply -f -
apiVersion: nvidia.com/v1
kind: ClusterPolicy
metadata:
  name: gpu-cluster-policy
spec:
  operator:
    defaultRuntime: crio
    use_ocp_driver_toolkit: true
  driver:
    enabled: true
  toolkit:
    enabled: true
  devicePlugin:
    enabled: true
  dcgmExporter:
    enabled: true
  gfd:
    enabled: true
EOF
```

### Verify GPU Detection

```bash
# Check GPU nodes
oc get nodes -l feature.node.kubernetes.io/pci-10de.present=true

# Check node capacity
oc describe node <gpu-node-name> | grep -A 10 Capacity

# Should show:
#   nvidia.com/gpu: 1
```

## Verification

### Check All Deployments

```bash
# NFD
oc get pods -n openshift-nfd
oc get nodefeaturediscovery -n openshift-nfd

# GPU Operator
oc get pods -n nvidia-gpu-operator
oc get clusterpolicy -n nvidia-gpu-operator

# LiteMaaS
oc get pods -n litemaas
oc get routes -n litemaas
```

### Access Applications

Get application URLs:

```bash
# LiteMaaS Frontend
echo "https://$(oc get route litemaas -n litemaas -o jsonpath='{.spec.host}')"

# LiteLLM UI
echo "https://$(oc get route litellm -n litemaas -o jsonpath='{.spec.host}')/ui"
```

### Test Backend API

```bash
BACKEND_URL=$(oc get route litemaas -n litemaas -o jsonpath='{.spec.host}')
curl -k https://$BACKEND_URL/api/v1/health/ready
```

## Troubleshooting

### Pods Not Starting

Check events:
```bash
oc get events -n litemaas --sort-by='.lastTimestamp'
```

Check pod logs:
```bash
oc logs -f deployment/<deployment-name> -n litemaas
```

### Database Connection Issues

Check PostgreSQL:
```bash
oc logs statefulset/postgres -n litemaas
oc exec -it postgres-0 -n litemaas -- psql -U litemaas_admin -d litemaas_db -c '\l'
```

### GPU Drivers Not Loading

Check driver compilation:
```bash
oc logs -f daemonset/nvidia-driver-daemonset -c nvidia-driver-ctr -n nvidia-gpu-operator
```

Check ClusterPolicy status:
```bash
oc get clusterpolicy gpu-cluster-policy -n nvidia-gpu-operator -o yaml
```

### OAuth Issues

Check OAuth client:
```bash
oc get oauthclient litemaas-oauth-client
```

Verify callback URL matches:
```bash
oc get route litemaas -n litemaas -o jsonpath='{.spec.host}'
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Pods stuck in `Pending` | Check PVC status: `oc get pvc -n litemaas` |
| Backend can't connect to DB | Verify secrets: `oc get secret backend-secret -n litemaas -o yaml` |
| Frontend shows blank page | Check backend logs for errors |
| OAuth login fails | Verify oauth-issuer in backend-secret matches cluster |
| GPU not detected | Ensure NFD and GPU operator are running |

## Scaling

### Scale GPU Nodes

```bash
# Scale up
oc scale machineset <gpu-machineset-name> --replicas=2 -n openshift-machine-api

# Scale down
oc scale machineset <gpu-machineset-name> --replicas=0 -n openshift-machine-api
```

### Scale Application

```bash
# Scale backend
oc scale deployment backend --replicas=3 -n litemaas

# Scale frontend
oc scale deployment frontend --replicas=2 -n litemaas
```

## Cleanup

### Remove LiteMaaS Only

```bash
oc delete -k base/litemaas/
oc delete namespace litemaas
```

### Remove Everything

```bash
# Delete applications
oc delete -k base/litemaas/
oc delete -k base/gpu-operator/
oc delete -k base/nfd/

# Delete GPU MachineSet
oc delete machineset <gpu-machineset-name> -n openshift-machine-api

# Delete namespaces
oc delete namespace litemaas nvidia-gpu-operator openshift-nfd
```

## Next Steps

After successful deployment:

1. **Configure Model Providers**
   - Add API keys for OpenAI, Anthropic, etc. in LiteLLM UI

2. **Create Users**
   - Use LiteMaaS web UI to create user accounts
   - Set budgets and rate limits

3. **Deploy Models on GPU**
   - Use OpenShift AI to deploy models on GPU nodes
   - Configure LiteMaaS to connect to deployed models

4. **Monitor Usage**
   - Access LiteLLM UI for request metrics
   - Check user consumption in LiteMaaS dashboard

5. **Set Up Backups**
   - Configure PostgreSQL backups
   - Export configuration regularly

## Additional Resources

- [LiteMaaS Repository](https://github.com/anatsheh84/litemaas)
- [OpenShift Documentation](https://docs.openshift.com/)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)
- [Node Feature Discovery](https://docs.openshift.com/container-platform/latest/hardware_enablement/psap-node-feature-discovery-operator.html)

## Support

For issues and questions:
- GitHub Issues: https://github.com/anatsheh84/litemaas-deployment/issues
- LiteMaaS Issues: https://github.com/anatsheh84/litemaas/issues
