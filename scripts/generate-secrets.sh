#!/bin/bash

# LiteMaaS Secrets Generator
# This script generates random secrets for your LiteMaaS deployment

set -e

echo "========================================="
echo "LiteMaaS Secrets Generator"
echo "========================================="
echo ""

# Get cluster domain
read -p "Enter your OpenShift cluster domain (e.g., apps.cluster-xyz.example.com): " CLUSTER_DOMAIN

echo ""
echo "Generating random secrets..."
echo ""

# Generate random secrets
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
ADMIN_API_KEY="sk-admin-$(openssl rand -hex 32)"
JWT_SECRET=$(openssl rand -base64 32)
LITELLM_API_KEY="sk-litellm-$(openssl rand -hex 32)"
OAUTH_CLIENT_SECRET=$(openssl rand -hex 64)
LITELLM_UI_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)

# Create secrets directory
mkdir -p generated-secrets

# Generate postgres-secret.yaml
cat > generated-secrets/postgres-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: litemaas
  labels:
    app: postgres
type: Opaque
stringData:
  postgres-password: "${POSTGRES_PASSWORD}"
  postgres-user: "litemaas_admin"
  postgres-db: "litemaas_db"
EOF

# Generate backend-secret.yaml
cat > generated-secrets/backend-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: backend-secret
  namespace: litemaas
  labels:
    app: backend
    component: api
type: Opaque
stringData:
  admin-api-keys: "${ADMIN_API_KEY}"
  cors-origin: "https://litemaas-litemaas.${CLUSTER_DOMAIN}"
  database-url: "postgresql://litemaas_admin:${POSTGRES_PASSWORD}@postgres:5432/litemaas_db?sslmode=disable"
  jwt-secret: "${JWT_SECRET}"
  litellm-api-key: "${LITELLM_API_KEY}"
  oauth-callback-url: "https://litemaas-litemaas.${CLUSTER_DOMAIN}/api/auth/callback"
  oauth-client-id: "litemaas-oauth-client"
  oauth-client-secret: "${OAUTH_CLIENT_SECRET}"
  oauth-issuer: "https://oauth-openshift.${CLUSTER_DOMAIN}"
EOF

# Generate litellm-secret.yaml
cat > generated-secrets/litellm-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: litellm-secret
  namespace: litemaas
  labels:
    app: litellm
type: Opaque
stringData:
  master-key: "${LITELLM_API_KEY}"
  database-url: "postgresql://litemaas_admin:${POSTGRES_PASSWORD}@postgres:5432/litemaas_db"
  ui-username: "admin"
  ui-password: "${LITELLM_UI_PASSWORD}"
EOF

# Generate credentials file for reference
cat > generated-secrets/CREDENTIALS.txt <<EOF
========================================
LiteMaaS Deployment Credentials
========================================
Generated on: $(date)

IMPORTANT: Store these credentials securely!

Cluster Domain: ${CLUSTER_DOMAIN}

--- Database ---
PostgreSQL User: litemaas_admin
PostgreSQL Password: ${POSTGRES_PASSWORD}
PostgreSQL Database: litemaas_db

--- Backend API ---
Admin API Key: ${ADMIN_API_KEY}
JWT Secret: ${JWT_SECRET}

--- LiteLLM ---
LiteLLM API Key: ${LITELLM_API_KEY}
LiteLLM UI Username: admin
LiteLLM UI Password: ${LITELLM_UI_PASSWORD}
LiteLLM UI URL: https://litellm-litemaas.${CLUSTER_DOMAIN}/ui

--- OAuth ---
OAuth Client ID: litemaas-oauth-client
OAuth Client Secret: ${OAUTH_CLIENT_SECRET}
OAuth Issuer: https://oauth-openshift.${CLUSTER_DOMAIN}
OAuth Callback: https://litemaas-litemaas.${CLUSTER_DOMAIN}/api/auth/callback

--- Application URLs ---
LiteMaaS Frontend: https://litemaas-litemaas.${CLUSTER_DOMAIN}
LiteMaaS Backend API: https://litemaas-litemaas.${CLUSTER_DOMAIN}/api
LiteLLM Proxy: https://litellm-litemaas.${CLUSTER_DOMAIN}
LiteLLM Admin UI: https://litellm-litemaas.${CLUSTER_DOMAIN}/ui

========================================
EOF

echo "✅ Secrets generated successfully!"
echo ""
echo "Files created in generated-secrets/:"
echo "  - postgres-secret.yaml"
echo "  - backend-secret.yaml"
echo "  - litellm-secret.yaml"
echo "  - CREDENTIALS.txt (for your records)"
echo ""
echo "⚠️  IMPORTANT:"
echo "  1. Store CREDENTIALS.txt in a secure location"
echo "  2. Add generated-secrets/ to .gitignore (already done)"
echo "  3. Apply secrets with: oc apply -f generated-secrets/"
echo ""
echo "Next steps:"
echo "  1. Review the generated secrets"
echo "  2. Apply them: oc apply -f generated-secrets/"
echo "  3. Deploy LiteMaaS: oc apply -k base/litemaas/"
echo ""
