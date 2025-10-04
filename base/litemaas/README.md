# LiteMaaS Base Configuration

This directory contains the base Kubernetes manifests for deploying LiteMaaS.

## Components

- **Namespace**: litemaas namespace with monitoring enabled
- **Secrets**: Database and application secrets (templates - must be customized)
- **PostgreSQL**: Database for LiteMaaS and LiteLLM
- **Backend**: Node.js API server  
- **Frontend**: React web application
- **LiteLLM**: LLM proxy server

## Quick Start

### 1. Generate Secrets

**Important**: DO NOT use the template secrets in production!

Run the secrets generator script:

```bash
cd ../..  # Go to repository root
chmod +x scripts/generate-secrets.sh
./scripts/generate-secrets.sh
```

This will create customized secrets in `generated-secrets/` directory.

### 2. Apply Configuration

```bash
# Apply secrets
oc apply -f ../../generated-secrets/

# Deploy LiteMaaS (points to upstream manifests)
oc apply -k .
```

## Deployment Source

The actual deployment manifests (postgres, backend, frontend, litellm) are referenced from the upstream LiteMaaS repository:

**Repository**: https://github.com/anatsheh84/litemaas  
**Path**: `/deployment/openshift/`

The kustomization.yaml in this directory uses remote resources to pull the latest stable deployment manifests.

## Configuration

### Secrets

All secrets must be configured before deployment:

1. **postgres-secret.yaml** - Database credentials
2. **backend-secret.yaml** - Backend API configuration
3. **litellm-secret.yaml** - LiteLLM proxy configuration

### Environment-Specific Values

Update these values in the secrets:

- `CLUSTER_DOMAIN` - Your OpenShift cluster domain
- All passwords and API keys (use the generator script)
- OAuth configuration for your cluster

## Accessing the Application

After deployment:

### LiteMaaS Frontend
```
https://litemaas-litemaas.apps.<YOUR_CLUSTER_DOMAIN>
```

Login with OpenShift OAuth

### LiteLLM Admin UI
```
https://litellm-litemaas.apps.<YOUR_CLUSTER_DOMAIN>/ui
```

Username: `admin`  
Password: (from litellm-secret)

## Verification

Check deployment status:

```bash
# Check all pods
oc get pods -n litemaas

# Check routes
oc get routes -n litemaas

# Check backend logs
oc logs -f deployment/backend -n litemaas

# Check database
oc logs -f statefulset/postgres -n litemaas
```

Expected pods:
- `postgres-0` - Database (1/1 Running)
- `backend-xxx` - API server (1/1 Running)
- `frontend-xxx` - Web UI (1/1 Running)
- `litellm-xxx` - LLM proxy (1/1 Running)

## Troubleshooting

### Backend can't connect to database

Check database is running:
```bash
oc get pods -n litemaas -l app=postgres
oc logs statefulset/postgres -n litemaas
```

Verify database secret:
```bash
oc get secret backend-secret -n litemaas -o yaml
```

### Frontend shows blank page

Check backend is accessible:
```bash
oc logs deployment/backend -n litemaas
curl -k https://litemaas-litemaas.apps.<DOMAIN>/api/v1/health/ready
```

### OAuth login fails

Verify OAuth configuration:
```bash
oc get oauthclient litemaas-oauth-client -o yaml
```

Check backend logs for OAuth errors:
```bash
oc logs deployment/backend -n litemaas | grep -i oauth
```

## Customization

To customize the deployment (replicas, resources, etc.):

1. Create an overlay directory
2. Add your customizations
3. Reference this base in your overlay's kustomization.yaml

Example overlay structure:
```
overlays/
  production/
    kustomization.yaml
    replica-patch.yaml
    resource-patch.yaml
```

## Uninstall

```bash
# Delete all resources
oc delete -k .

# Delete namespace (this will delete everything)
oc delete namespace litemaas
```

⚠️ **Warning**: This will delete all data including the database!

## Next Steps

After deploying LiteMaaS:

1. **Add Model Providers**: Configure API keys for OpenAI, Anthropic, etc.
2. **Create Users**: Use the web UI to create user accounts
3. **Deploy Models**: Set up models on OpenShift AI with GPU
4. **Configure Limits**: Set rate limits and budgets per user
