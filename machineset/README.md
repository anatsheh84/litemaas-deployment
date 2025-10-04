# GPU MachineSet Configuration

This directory contains MachineSet configurations for creating GPU-enabled worker nodes.

## Template Variables

Before applying the MachineSet, replace the following placeholders:

| Variable | Description | Example |
|----------|-------------|---------|
| `CLUSTER_NAME` | Your OpenShift cluster name | `cluster-5wkv7-42286` |
| `ZONE` | AWS availability zone | `us-east-2b` |
| `REGION` | AWS region | `us-east-2` |
| `AMI_ID` | RHCOS AMI ID for your region | `ami-0adb8862ffe5cc2ab` |

## Finding Your Cluster Values

### Get Cluster Name
```bash
oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}'
```

### Get Existing MachineSet Details
```bash
oc get machineset -n openshift-machine-api -o yaml | grep -A 5 "metadata:"
```

### Get AMI ID
```bash
oc get machineset -n openshift-machine-api -o yaml | grep "ami:" -A 1
```

## Quick Setup Script

Create a setup script to replace all variables:

```bash
#!/bin/bash

CLUSTER_NAME="cluster-5wkv7-42286"  # Your cluster name
ZONE="us-east-2b"                    # Your AZ
REGION="us-east-2"                   # Your region
AMI_ID="ami-0adb8862ffe5cc2ab"      # Your AMI

sed -e "s/CLUSTER_NAME/$CLUSTER_NAME/g" \
    -e "s/ZONE/$ZONE/g" \
    -e "s/REGION/$REGION/g" \
    -e "s/AMI_ID/$AMI_ID/g" \
    gpu-machineset-template.yaml > gpu-machineset.yaml

# Apply the MachineSet
oc apply -f gpu-machineset.yaml
```

## GPU Instance Types

Available AWS GPU instance types:

| Instance Type | GPU | vCPUs | Memory | Use Case |
|--------------|-----|-------|--------|----------|
| `g6.xlarge` | 1x L4 (24GB) | 4 | 16GB | Small models |
| `g6.2xlarge` | 1x L4 (24GB) | 8 | 32GB | Medium models (recommended) |
| `g6.4xlarge` | 1x L4 (24GB) | 16 | 64GB | Large models |
| `g6.12xlarge` | 4x L4 (96GB) | 48 | 192GB | Multi-GPU inference |
| `p3.2xlarge` | 1x V100 (16GB) | 8 | 61GB | Training workloads |
| `p4d.24xlarge` | 8x A100 (320GB) | 96 | 1152GB | Large-scale training |

## Scaling

### Scale Up
```bash
oc scale machineset CLUSTER_NAME-gpu-worker-ZONE --replicas=2 -n openshift-machine-api
```

### Scale Down
```bash
oc scale machineset CLUSTER_NAME-gpu-worker-ZONE --replicas=0 -n openshift-machine-api
```

### Delete MachineSet
```bash
oc delete machineset CLUSTER_NAME-gpu-worker-ZONE -n openshift-machine-api
```

## Verification

After creating the MachineSet:

1. **Check MachineSet status:**
   ```bash
   oc get machineset -n openshift-machine-api
   ```

2. **Check Machine provisioning:**
   ```bash
   oc get machine -n openshift-machine-api | grep gpu
   ```

3. **Check Node joining:**
   ```bash
   oc get nodes -l node-role.kubernetes.io/gpu
   ```

4. **Verify GPU detection:**
   ```bash
   oc describe node <gpu-node-name> | grep -A 10 "Capacity:"
   ```

## Troubleshooting

### Machine stuck in Provisioning
```bash
oc describe machine <machine-name> -n openshift-machine-api
```

### Node not joining cluster
Check cloud-init logs on the EC2 instance or check Machine events.

### GPU not detected
Ensure NFD and GPU Operator are installed and running.
