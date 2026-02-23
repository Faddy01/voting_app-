#!/bin/zsh

# === CONFIGURATION ===
CLUSTER_NAME="fawad-voting-app-cluster"
NODEGROUP_NAME="fawad-voting-workers"
REGION="eu-central-1"
NODE_TYPE="t3.medium"
MIN_NODES=2
MAX_NODES=2
ZONES="eu-central-1a,eu-central-1b,eu-central-1c"

echo "=== Step 1: Delete stuck CloudFormation stacks ==="

# List all stacks in failure/rollback states
STACKS=$(aws cloudformation list-stacks \
    --stack-status-filter CREATE_FAILED ROLLBACK_COMPLETE ROLLBACK_FAILED \
    --query "StackSummaries[].StackName" --output text --region $REGION)

for stack in $STACKS; do
    echo "Deleting stack: $stack"
    aws cloudformation delete-stack --stack-name $stack --region $REGION
    aws cloudformation wait stack-delete-complete --stack-name $stack --region $REGION
done

echo "=== Step 2: Release unused Elastic IPs ==="
# List all EIPs with no association
EIPS=$(aws ec2 describe-addresses --region $REGION \
    --query "Addresses[?AssociationId==null].AllocationId" --output text)

for eip in $EIPS; do
    echo "Releasing Elastic IP: $eip"
    aws ec2 release-address --allocation-id $eip --region $REGION
done

echo "=== Step 3: Delete existing EKS cluster if any ==="
if eksctl get cluster --name $CLUSTER_NAME --region $REGION &>/dev/null; then
    echo "Deleting existing cluster: $CLUSTER_NAME"
    eksctl delete cluster --name $CLUSTER_NAME --region $REGION
else
    echo "No existing cluster found."
fi

echo "=== Step 4: Create new EKS cluster ==="
eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $REGION \
    --nodegroup-name $NODEGROUP_NAME \
    --node-type $NODE_TYPE \
    --nodes-min $MIN_NODES \
    --nodes-max $MAX_NODES \
    --managed \
    --with-oidc \
    --zones $ZONES

echo "✅ Cluster creation initiated. Monitor progress with 'eksctl get cluster --region $REGION'"