# LiteMaaS Deployment on OpenShift

Production-ready deployment configurations for LiteMaaS on OpenShift with GPU support and ArgoCD integration.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.18+-red.svg)](https://www.openshift.com/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-Ready-blue.svg)](https://argoproj.github.io/cd/)

## 🚀 Quick Start

```bash
git clone https://github.com/anatsheh84/litemaas-deployment.git
cd litemaas-deployment
chmod +x scripts/generate-secrets.sh
./scripts/generate-secrets.sh
oc apply -k base/nfd/
oc apply -k base/gpu-operator/
oc apply -f generated-secrets/
oc apply -k base/litemaas/
```

📖 **[Full Deployment Guide](DEPLOYMENT.md)**

## 📁 Repository Structure

```
.
├── apps/                      # ArgoCD Application definitions
│   ├── litemaas-app.yaml
│   ├── nfd-app.yaml
│   └── gpu-operator-app.yaml
├── base/                      # Base Kubernetes manifests
│   ├── litemaas/             # LiteMaaS components
│   ├── gpu-operator/         # NVIDIA GPU Operator
│   └── nfd/                  # Node Feature Discovery
├── machineset/               # GPU MachineSet templates
│   ├── gpu-machineset-template.yaml
│   └── README.md
├── scripts/                  # Utility scripts
│   └── generate-secrets.sh  # Secret generation script
├── DEPLOYMENT.md            # Comprehensive deployment guide
└── README.md
```

## ✨ Features

- **GitOps Ready**: Full ArgoCD/OpenShift GitOps support
- **GPU Support**: Pre-configured for NVIDIA GPU workloads
- **Secure by Default**: Secret generation with strong random values
- **Production Ready**: Includes monitoring, health checks, and proper resource limits
- **Modular**: Kustomize-based for easy customization
- **Well Documented**: Comprehensive guides and inline comments

## 🎯 What is LiteMaaS?

LiteMaaS (LLM-as-a-Service) is a multi-tenant platform for managing and serving Large Language Models with:

- **Multi-tenant Architecture**: Isolated user workspaces with quotas
- **Model Management**: Easy model deployment and versioning
- **Rate Limiting**: Per-user token and request limits
- **Cost Tracking**: Budget management and usage monitoring
- **OpenShift OAuth**: Integrated authentication
- **LiteLLM Integration**: Support for multiple LLM providers (OpenAI, Anthropic, AWS Bedrock, etc.)

## 📋 Prerequisites

- OpenShift 4.18+ cluster
- Cluster admin access
- `oc` CLI tool
- `openssl` (for secret generation)
- Optional: ArgoCD/OpenShift GitOps operator

## 🛠️ Components

### Core Stack

| Component | Description | Version |
|-----------|-------------|---------|
| **PostgreSQL** | Database for state management | 16-alpine |
| **Backend** | Node.js API server | 0.0.19 |
| **Frontend** | React web interface | 0.0.19 |
| **LiteLLM** | LLM proxy and routing | Latest |

### GPU Infrastructure

| Component | Description |
|-----------|-------------|
| **Node Feature Discovery** | Hardware feature detection |
| **NVIDIA GPU Operator** | GPU driver and device plugin management |
| **GPU MachineSet** | AWS g6 instance template (NVIDIA L4) |

## 📚 Documentation

- **[Deployment Guide](DEPLOYMENT.md)** - Complete step-by-step deployment instructions
- **[LiteMaaS Base](base/litemaas/README.md)** - LiteMaaS configuration details
- **[GPU MachineSet](machineset/README.md)** - GPU node setup guide
- **[ArgoCD Apps](apps/README.md)** - GitOps deployment guide

## 🔧 Deployment Options

### Option 1: Manual Deployment

```bash
# 1. Generate secrets
./scripts/generate-secrets.sh

# 2. Deploy infrastructure
oc apply -k base/nfd/
oc apply -k base/gpu-operator/

# 3. Deploy application
oc apply -f generated-secrets/
oc apply -k base/litemaas/
```

### Option 2: ArgoCD Deployment

```bash
# 1. Generate and apply secrets
./scripts/generate-secrets.sh
oc apply -f generated-secrets/

# 2. Deploy ArgoCD applications
oc apply -f apps/nfd-app.yaml
oc apply -f apps/gpu-operator-app.yaml
oc apply -f apps/litemaas-app.yaml
```

## 🎮 Accessing the Application

After deployment:

### LiteMaaS Web UI
```
https://litemaas-litemaas.apps.<your-cluster-domain>
```
Login with OpenShift OAuth

### LiteLLM Admin UI
```
https://litellm-litemaas.apps.<your-cluster-domain>/ui
```
Username: `admin`  
Password: From `generated-secrets/CREDENTIALS.txt`

## 🔐 Security

### Secrets Management

All secrets are:
- Generated with cryptographically secure random values
- Base64 encoded in Kubernetes secrets
- Excluded from Git via `.gitignore`
- Documented in `CREDENTIALS.txt` (store securely!)

### OAuth Integration

LiteMaaS uses OpenShift OAuth for authentication:
- No separate user management needed
- OpenShift RBAC integration
- Automatic session management

## 🚦 GPU Node Configuration

### Create GPU Workers

```bash
# Update template with your cluster details
cd machineset
cp gpu-machineset-template.yaml gpu-machineset.yaml
# Edit gpu-machineset.yaml

# Create GPU nodes
oc apply -f gpu-machineset.yaml
```

### Supported GPU Instance Types

| Instance | GPU | vCPU | Memory | Use Case |
|----------|-----|------|--------|----------|
| g6.2xlarge | 1x L4 (24GB) | 8 | 32GB | **Recommended** |
| g6.4xlarge | 1x L4 (24GB) | 16 | 64GB | Large models |
| g6.12xlarge | 4x L4 (96GB) | 48 | 192GB | Multi-GPU |
| p3.2xlarge | 1x V100 (16GB) | 8 | 61GB | Training |

## 📊 Monitoring

LiteMaaS includes:
- Prometheus metrics export
- Health check endpoints
- Request/response logging
- Usage tracking per user

Access metrics:
```bash
# Backend health
curl https://litemaas-litemaas.apps.<domain>/api/v1/health/ready

# LiteLLM metrics
curl https://litellm-litemaas.apps.<domain>/metrics
```

## 🔄 Updates

### Update LiteMaaS

```bash
# Update to latest version
oc set image deployment/backend backend=quay.io/rh-aiservices-bu/litemaas-backend:latest -n litemaas
oc set image deployment/frontend frontend=quay.io/rh-aiservices-bu/litemaas-frontend:latest -n litemaas
```

### Update via ArgoCD

```bash
# Trigger sync
argocd app sync litemaas

# Or enable auto-sync in the Application manifest
```

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Pods not starting | `oc get events -n litemaas` |
| Database connection failed | Check postgres-secret values |
| OAuth login fails | Verify oauth-issuer in backend-secret |
| GPU not detected | Ensure NFD and GPU operator running |

See [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting) for detailed troubleshooting.

## 🧹 Cleanup

### Remove LiteMaaS Only
```bash
oc delete -k base/litemaas/
oc delete namespace litemaas
```

### Remove Everything
```bash
oc delete -k base/
oc delete -f machineset/gpu-machineset.yaml
oc delete namespace litemaas nvidia-gpu-operator openshift-nfd
```

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) for details

## 🔗 Related Projects

- **[LiteMaaS](https://github.com/anatsheh84/litemaas)** - Main application repository
- **[OpenShift AI](https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-ai)** - AI/ML platform
- **[LiteLLM](https://github.com/BerriAI/litellm)** - LLM proxy library

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/anatsheh84/litemaas-deployment/issues)
- **Documentation**: [Deployment Guide](DEPLOYMENT.md)
- **LiteMaaS Issues**: [Main Repo Issues](https://github.com/anatsheh84/litemaas/issues)

## 🙏 Acknowledgments

- Red Hat AI Services team
- NVIDIA GPU Operator team
- LiteLLM community
- OpenShift community

---

**Made with ❤️ for the OpenShift community**
