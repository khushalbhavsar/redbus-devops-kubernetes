# ☸️ Kubernetes & AWS EKS Documentation

This document provides comprehensive information about Kubernetes, AWS EKS, kubectl, and eksctl for the RedBus DevOps project.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Kubernetes Fundamentals](#-kubernetes-fundamentals)
- [AWS EKS (Elastic Kubernetes Service)](#-aws-eks-elastic-kubernetes-service)
- [kubectl CLI Tool](#-kubectl-cli-tool)
- [eksctl CLI Tool](#-eksctl-cli-tool)
- [Project Kubernetes Resources](#-project-kubernetes-resources)
- [Manifest Files](#-manifest-files)
- [Deployment Guide](#-deployment-guide)
- [Scaling & Updates](#-scaling--updates)
- [Monitoring & Debugging](#-monitoring--debugging)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)

---

## 📌 Overview

### Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| **Container Orchestration** | Kubernetes | 1.29 |
| **Managed Kubernetes** | AWS EKS | Latest |
| **Kubernetes CLI** | kubectl | 1.28+ |
| **EKS CLI** | eksctl | Latest |
| **Ingress Controller** | NGINX Ingress | Latest |
| **TLS Certificates** | cert-manager | Latest |

### Project Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS EKS CLUSTER                                      │
│                                   (redbus-cluster)                                      │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│   │                              NAMESPACE: redbus                                  │   │
│   │                                                                                 │   │
│   │   ┌─────────────────────────────────────────────────────────────────────────┐  │   │
│   │   │                        NGINX INGRESS CONTROLLER                         │  │   │
│   │   │   ┌─────────────────────────────────────────────────────────────────┐   │  │   │
│   │   │   │  /api/* ──────────▶ backend-service:5000                        │   │  │   │
│   │   │   │  /*     ──────────▶ frontend-service:80                         │   │  │   │
│   │   │   └─────────────────────────────────────────────────────────────────┘   │  │   │
│   │   └─────────────────────────────────────────────────────────────────────────┘  │   │
│   │                                      │                                          │   │
│   │            ┌─────────────────────────┴─────────────────────────┐               │   │
│   │            │                                                   │               │   │
│   │            ▼                                                   ▼               │   │
│   │   ┌─────────────────────┐                         ┌─────────────────────┐      │   │
│   │   │  frontend-service   │                         │  backend-service    │      │   │
│   │   │   (ClusterIP:80)    │                         │  (ClusterIP:5000)   │      │   │
│   │   └──────────┬──────────┘                         └──────────┬──────────┘      │   │
│   │              │                                               │                  │   │
│   │              ▼                                               ▼                  │   │
│   │   ┌─────────────────────┐                         ┌─────────────────────┐      │   │
│   │   │frontend-deployment  │                         │backend-deployment   │      │   │
│   │   │  ┌───────┐ ┌───────┐│                         │  ┌───────┐ ┌───────┐│      │   │
│   │   │  │ Pod 1 │ │ Pod 2 ││                         │  │ Pod 1 │ │ Pod 2 ││      │   │
│   │   │  │ React │ │ React ││                         │  │Node.js│ │Node.js││      │   │
│   │   │  └───────┘ └───────┘│                         │  └───────┘ └───────┘│      │   │
│   │   └─────────────────────┘                         └─────────────────────┘      │   │
│   │                                                                                 │   │
│   │   ┌─────────────────────────────────────────────────────────────────────────┐  │   │
│   │   │                         CONFIGMAP & SECRETS                             │  │   │
│   │   │  ┌─────────────────────┐         ┌─────────────────────┐               │  │   │
│   │   │  │   redbus-config     │         │   redbus-secrets    │               │  │   │
│   │   │  │ • NODE_ENV          │         │ • mongodb-uri       │               │  │   │
│   │   │  │ • PORT              │         │ • stripe-secret-key │               │  │   │
│   │   │  │ • REACT_APP_*       │         │                     │               │  │   │
│   │   │  └─────────────────────┘         └─────────────────────┘               │  │   │
│   │   └─────────────────────────────────────────────────────────────────────────┘  │   │
│   └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│   │                            EKS MANAGED NODE GROUP                               │   │
│   │   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │   │
│   │   │  EC2 Node   │    │  EC2 Node   │    │  EC2 Node   │    │  EC2 Node   │     │   │
│   │   │  t3.medium  │    │  t3.medium  │    │  t3.medium  │    │  t3.medium  │     │   │
│   │   └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘     │   │
│   │                        (min: 1, max: 5, desired: 2)                             │   │
│   └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🎓 Kubernetes Fundamentals

### What is Kubernetes?

Kubernetes (K8s) is an open-source container orchestration platform that automates deployment, scaling, and management of containerized applications.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Pod** | Smallest deployable unit; contains one or more containers |
| **Deployment** | Manages Pod replicas and rolling updates |
| **Service** | Stable network endpoint for Pods |
| **Ingress** | HTTP/HTTPS routing and load balancing |
| **ConfigMap** | Store non-sensitive configuration data |
| **Secret** | Store sensitive data (passwords, keys) |
| **Namespace** | Virtual cluster for resource isolation |
| **Node** | Worker machine running Pods |

### Kubernetes Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KUBERNETES ARCHITECTURE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                         CONTROL PLANE (Master)                        │  │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐  │  │
│  │  │ API Server  │ │   etcd      │ │ Scheduler   │ │ Controller Mgr  │  │  │
│  │  │  (kube-api) │ │  (storage)  │ │             │ │                 │  │  │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                      │                                      │
│                                      ▼                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                          WORKER NODES                                 │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │                           NODE 1                                │  │  │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌────────────────────────┐  │  │  │
│  │  │  │   kubelet   │  │ kube-proxy  │  │   Container Runtime    │  │  │  │
│  │  │  │             │  │             │  │   (containerd/docker)  │  │  │  │
│  │  │  └─────────────┘  └─────────────┘  └────────────────────────┘  │  │  │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │  │  │
│  │  │  │    Pod 1    │  │    Pod 2    │  │    Pod 3    │            │  │  │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘            │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Kubernetes Objects in This Project

| Object | Name | Replicas | Port |
|--------|------|----------|------|
| Namespace | redbus | - | - |
| Deployment | frontend-deployment | 2 | 80 |
| Deployment | backend-deployment | 2 | 5000 |
| Service | frontend-service | - | 80 |
| Service | backend-service | - | 5000 |
| Ingress | redbus-ingress | - | 80/443 |
| ConfigMap | redbus-config | - | - |
| Secret | redbus-secrets | - | - |

---

## ☁️ AWS EKS (Elastic Kubernetes Service)

### What is AWS EKS?

Amazon Elastic Kubernetes Service (EKS) is a fully managed Kubernetes service that makes it easy to run Kubernetes on AWS without needing to install and operate your own Kubernetes control plane.

### EKS Features

| Feature | Description |
|---------|-------------|
| **Managed Control Plane** | AWS manages the Kubernetes control plane |
| **High Availability** | Control plane runs across multiple AZs |
| **Security** | Integrated with AWS IAM, VPC, and security groups |
| **Scaling** | Auto-scaling with managed node groups |
| **Updates** | Automated Kubernetes version updates |
| **Networking** | VPC CNI plugin for native VPC networking |
| **Load Balancing** | Integration with ALB/NLB |
| **Monitoring** | CloudWatch and Container Insights |

### EKS Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                   AWS EKS ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│   ┌──────────────────────────────────────────────────────────────────────────────┐  │
│   │                        AWS MANAGED CONTROL PLANE                             │  │
│   │   ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐               │  │
│   │   │   AZ-1a         │ │   AZ-1b         │ │   AZ-1c         │               │  │
│   │   │  ┌───────────┐  │ │  ┌───────────┐  │ │  ┌───────────┐  │               │  │
│   │   │  │ API Server│  │ │  │ API Server│  │ │  │ API Server│  │               │  │
│   │   │  │   etcd    │  │ │  │   etcd    │  │ │  │   etcd    │  │               │  │
│   │   │  └───────────┘  │ │  └───────────┘  │ │  └───────────┘  │               │  │
│   │   └─────────────────┘ └─────────────────┘ └─────────────────┘               │  │
│   └──────────────────────────────────────────────────────────────────────────────┘  │
│                                         │                                           │
│                                         ▼                                           │
│   ┌──────────────────────────────────────────────────────────────────────────────┐  │
│   │                        CUSTOMER VPC (10.0.0.0/16)                            │  │
│   │                                                                              │  │
│   │   ┌──────────────────────────────────────────────────────────────────────┐  │  │
│   │   │                     PRIVATE SUBNETS (EKS Nodes)                      │  │  │
│   │   │   ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐       │  │  │
│   │   │   │ Managed Node    │ │ Managed Node    │ │ Managed Node    │       │  │  │
│   │   │   │ Group (AZ-1a)   │ │ Group (AZ-1b)   │ │ Group (AZ-1c)   │       │  │  │
│   │   │   │  ┌───────────┐  │ │  ┌───────────┐  │ │  ┌───────────┐  │       │  │  │
│   │   │   │  │ EC2 Nodes │  │ │  │ EC2 Nodes │  │ │  │ EC2 Nodes │  │       │  │  │
│   │   │   │  │ t3.medium │  │ │  │ t3.medium │  │ │  │ t3.medium │  │       │  │  │
│   │   │   │  └───────────┘  │ │  └───────────┘  │ │  └───────────┘  │       │  │  │
│   │   │   └─────────────────┘ └─────────────────┘ └─────────────────┘       │  │  │
│   │   └──────────────────────────────────────────────────────────────────────┘  │  │
│   │                                                                              │  │
│   │   ┌──────────────────────────────────────────────────────────────────────┐  │  │
│   │   │                     PUBLIC SUBNETS (Load Balancers)                  │  │  │
│   │   │   ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐       │  │  │
│   │   │   │ NGINX Ingress   │ │ NAT Gateway     │ │ Internet        │       │  │  │
│   │   │   │ Controller      │ │                 │ │ Gateway         │       │  │  │
│   │   │   └─────────────────┘ └─────────────────┘ └─────────────────┘       │  │  │
│   │   └──────────────────────────────────────────────────────────────────────┘  │  │
│   └──────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                     │
│   ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐           │
│   │     AWS ECR        │  │     AWS IAM        │  │   CloudWatch       │           │
│   │  Container Images  │  │  Roles & Policies  │  │   Monitoring       │           │
│   └────────────────────┘  └────────────────────┘  └────────────────────┘           │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Project EKS Configuration

| Setting | Value |
|---------|-------|
| **Cluster Name** | redbus-cluster |
| **Kubernetes Version** | 1.29 |
| **Region** | us-east-1 |
| **Node Group Name** | redbus-nodes |
| **Instance Type** | t3.medium |
| **Min Nodes** | 1 |
| **Max Nodes** | 5 |
| **Desired Nodes** | 2 |
| **Capacity Type** | ON_DEMAND |

### EKS IAM Roles

| Role | Purpose |
|------|---------|
| **EKS Cluster Role** | Allows EKS to manage AWS resources |
| **Node Group Role** | Allows EC2 nodes to join the cluster |
| **Pod Execution Role** | (Optional) For Fargate pods |

---

## 🔧 kubectl CLI Tool

### What is kubectl?

`kubectl` is the Kubernetes command-line tool that allows you to run commands against Kubernetes clusters. You can use kubectl to deploy applications, inspect and manage cluster resources, and view logs.

### Installation

#### Amazon Linux / RHEL / CentOS

```bash
#!/bin/bash
# Location: scripts/aws/kubectl.sh

# Update system packages
sudo yum update -y

# Install curl
sudo yum install curl -y

# Download the latest stable kubectl binary
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl

# Install kubectl and set correct permissions
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Clean up downloaded file
rm -f kubectl

# Verify the installation
kubectl version --client
```

#### Ubuntu / Debian

```bash
# Download signing key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubectl
sudo apt-get update
sudo apt-get install -y kubectl
```

#### macOS

```bash
# Using Homebrew
brew install kubectl

# Or download directly
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### Windows (PowerShell)

```powershell
# Using Chocolatey
choco install kubernetes-cli

# Or download directly
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/windows/amd64/kubectl.exe"
# Add to PATH
```

### kubectl Commands Reference

#### Cluster Information

```bash
# View cluster information
kubectl cluster-info

# Get all nodes
kubectl get nodes

# Get node details
kubectl describe node <node-name>

# Check kubectl version
kubectl version --client
```

#### Namespace Operations

```bash
# List all namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace redbus

# Set default namespace
kubectl config set-context --current --namespace=redbus

# Delete namespace
kubectl delete namespace redbus
```

#### Pod Operations

```bash
# List all pods
kubectl get pods -n redbus

# List pods with more details
kubectl get pods -n redbus -o wide

# Describe pod
kubectl describe pod <pod-name> -n redbus

# Get pod logs
kubectl logs <pod-name> -n redbus

# Stream pod logs
kubectl logs -f <pod-name> -n redbus

# Execute command in pod
kubectl exec -it <pod-name> -n redbus -- /bin/bash

# Delete pod
kubectl delete pod <pod-name> -n redbus
```

#### Deployment Operations

```bash
# List deployments
kubectl get deployments -n redbus

# Describe deployment
kubectl describe deployment frontend-deployment -n redbus

# Scale deployment
kubectl scale deployment frontend-deployment --replicas=3 -n redbus

# Rolling update
kubectl set image deployment/frontend-deployment frontend=new-image:tag -n redbus

# Rollout status
kubectl rollout status deployment/frontend-deployment -n redbus

# Rollback deployment
kubectl rollout undo deployment/frontend-deployment -n redbus

# View rollout history
kubectl rollout history deployment/frontend-deployment -n redbus
```

#### Service Operations

```bash
# List services
kubectl get services -n redbus

# Describe service
kubectl describe service backend-service -n redbus

# Port forward to service
kubectl port-forward service/frontend-service 8080:80 -n redbus
```

#### ConfigMap & Secret Operations

```bash
# List ConfigMaps
kubectl get configmaps -n redbus

# Create ConfigMap from file
kubectl create configmap app-config --from-file=config.env -n redbus

# List Secrets
kubectl get secrets -n redbus

# Create Secret
kubectl create secret generic db-secret --from-literal=password=mypassword -n redbus

# Decode Secret
kubectl get secret redbus-secrets -n redbus -o jsonpath='{.data.mongodb-uri}' | base64 -d
```

#### Apply & Delete Resources

```bash
# Apply manifest
kubectl apply -f deployment.yml -n redbus

# Apply all manifests in directory
kubectl apply -f infra/kubernetes/ -n redbus

# Delete resource
kubectl delete -f deployment.yml -n redbus

# Delete all resources
kubectl delete -f infra/kubernetes/ -n redbus
```

### kubectl Aliases (Optional)

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
```

---

## 🛠️ eksctl CLI Tool

### What is eksctl?

`eksctl` is a simple CLI tool for creating and managing Kubernetes clusters on Amazon EKS. It provides the fastest and easiest way to create a new cluster with nodes.

### Installation

#### Amazon Linux / RHEL / CentOS

```bash
#!/bin/bash
# Location: scripts/aws/eksctl.sh

# Update system packages
sudo yum update -y

# Install required dependencies
sudo yum install curl tar gzip -y

# Download and extract the latest eksctl binary
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

# Move eksctl to /usr/local/bin to make it executable from anywhere
sudo mv /tmp/eksctl /usr/local/bin

# Verify installation
eksctl version
```

#### Ubuntu / Debian

```bash
# Download and install
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

#### macOS

```bash
# Using Homebrew
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Or download directly
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Darwin_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

#### Windows (PowerShell)

```powershell
# Using Chocolatey
choco install eksctl

# Or using Scoop
scoop install eksctl
```

### eksctl Commands Reference

#### Create Cluster

```bash
# Create basic cluster
eksctl create cluster --name redbus-cluster --region us-east-1

# Create cluster with configuration
eksctl create cluster --name redbus-cluster \
  --region us-east-1 \
  --version 1.29 \
  --nodegroup-name redbus-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 5 \
  --managed

# Create cluster from config file
eksctl create cluster -f cluster-config.yaml
```

#### Cluster Configuration File

```yaml
# cluster-config.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: redbus-cluster
  region: us-east-1
  version: "1.29"

vpc:
  cidr: 10.0.0.0/16
  nat:
    gateway: Single

managedNodeGroups:
  - name: redbus-nodes
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 1
    maxSize: 5
    volumeSize: 50
    ssh:
      allow: true
    labels:
      role: worker
    tags:
      Project: RedBus
      Environment: production

cloudWatch:
  clusterLogging:
    enableTypes:
      - api
      - audit
      - authenticator
      - controllerManager
      - scheduler
```

#### Manage Clusters

```bash
# List clusters
eksctl get cluster --region us-east-1

# Get cluster info
eksctl get cluster --name redbus-cluster --region us-east-1

# Delete cluster
eksctl delete cluster --name redbus-cluster --region us-east-1

# Update cluster version
eksctl upgrade cluster --name redbus-cluster --version 1.30 --region us-east-1
```

#### Manage Node Groups

```bash
# List node groups
eksctl get nodegroup --cluster redbus-cluster --region us-east-1

# Create node group
eksctl create nodegroup \
  --cluster redbus-cluster \
  --region us-east-1 \
  --name new-nodes \
  --node-type t3.large \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed

# Scale node group
eksctl scale nodegroup \
  --cluster redbus-cluster \
  --name redbus-nodes \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 6 \
  --region us-east-1

# Delete node group
eksctl delete nodegroup \
  --cluster redbus-cluster \
  --name old-nodes \
  --region us-east-1
```

#### Update kubeconfig

```bash
# Update kubeconfig for EKS cluster
aws eks update-kubeconfig --region us-east-1 --name redbus-cluster

# Or using eksctl
eksctl utils write-kubeconfig --cluster redbus-cluster --region us-east-1

# Verify connection
kubectl get nodes
```

#### IAM & OIDC

```bash
# Associate OIDC provider (for IAM roles for service accounts)
eksctl utils associate-iam-oidc-provider \
  --cluster redbus-cluster \
  --region us-east-1 \
  --approve

# Create IAM service account
eksctl create iamserviceaccount \
  --name my-service-account \
  --namespace default \
  --cluster redbus-cluster \
  --region us-east-1 \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve
```

---

## 📄 Project Kubernetes Resources

### File Structure

```
infra/kubernetes/
├── namespace.yml              # Namespace definition
├── configmap.yml              # ConfigMap and Secrets
├── backend-deployment.yml     # Backend Deployment
├── backend-service.yml        # Backend Service
├── frontend-deployment.yml    # Frontend Deployment
├── frontend-service.yml       # Frontend Service
├── ingress.yml                # Ingress rules
└── monitoring/                # Prometheus & Grafana
    ├── namespace.yml
    ├── prometheus-configmap.yml
    ├── prometheus-deployment.yml
    ├── prometheus-rbac.yml
    ├── grafana-configmap.yml
    ├── grafana-deployment.yml
    ├── node-exporter.yml
    └── kube-state-metrics.yml
```

### Resources Summary

| Resource | File | Purpose |
|----------|------|---------|
| Namespace | namespace.yml | Isolate RedBus resources |
| ConfigMap | configmap.yml | Environment variables |
| Secret | configmap.yml | Sensitive credentials |
| Backend Deployment | backend-deployment.yml | Node.js API (2 replicas) |
| Backend Service | backend-service.yml | Internal service (ClusterIP) |
| Frontend Deployment | frontend-deployment.yml | React app (2 replicas) |
| Frontend Service | frontend-service.yml | Internal service (ClusterIP) |
| Ingress | ingress.yml | NGINX routing & TLS |

---

## 📋 Manifest Files

### Namespace (namespace.yml)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: redbus
  labels:
    name: redbus
```

### ConfigMap & Secret (configmap.yml)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redbus-config
data:
  NODE_ENV: "production"
  PORT: "5000"
  REACT_APP_BACKEND_URL: "https://redbus.yourdomain.com/api"
  REACT_APP_GOOGLE_CLIENT_ID: "your-google-client-id"
---
apiVersion: v1
kind: Secret
metadata:
  name: redbus-secrets
type: Opaque
stringData:
  mongodb-uri: "<YOUR_MONGODB_URI>"
  stripe-secret-key: "your-stripe-secret-key"
```

### Backend Deployment (backend-deployment.yml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  labels:
    app: redbus-backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: redbus-backend
  template:
    metadata:
      labels:
        app: redbus-backend
    spec:
      containers:
        - name: backend
          image: your-registry/redbus-backend:latest
          ports:
            - containerPort: 5000
          resources:
            requests:
              memory: "256Mi"
              cpu: "200m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 15
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 5
            periodSeconds: 5
          envFrom:
            - configMapRef:
                name: redbus-config
          env:
            - name: MONGODB_URI
              valueFrom:
                secretKeyRef:
                  name: redbus-secrets
                  key: mongodb-uri
            - name: STRIPE_SECRET_KEY
              valueFrom:
                secretKeyRef:
                  name: redbus-secrets
                  key: stripe-secret-key
```

### Backend Service (backend-service.yml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  labels:
    app: redbus-backend
spec:
  type: ClusterIP
  selector:
    app: redbus-backend
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
```

### Frontend Deployment (frontend-deployment.yml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  labels:
    app: redbus-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: redbus-frontend
  template:
    metadata:
      labels:
        app: redbus-frontend
    spec:
      containers:
        - name: frontend
          image: your-registry/redbus-frontend:latest
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
          livenessProbe:
            httpGet:
              path: /health
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
          envFrom:
            - configMapRef:
                name: redbus-config
```

### Frontend Service (frontend-service.yml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  labels:
    app: redbus-frontend
spec:
  type: ClusterIP
  selector:
    app: redbus-frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

### Ingress (ingress.yml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: redbus-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
    - hosts:
        - redbus.yourdomain.com
      secretName: redbus-tls
  rules:
    - host: redbus.yourdomain.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 5000
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

---

## 🚀 Deployment Guide

### Prerequisites

1. AWS CLI configured with credentials
2. kubectl installed
3. eksctl installed (optional)
4. EKS cluster running

### Step 1: Connect to EKS Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name redbus-cluster

# Verify connection
kubectl get nodes
```

### Step 2: Create Namespace

```bash
# Create namespace
kubectl apply -f infra/kubernetes/namespace.yml

# Verify
kubectl get namespaces
```

### Step 3: Create ConfigMap and Secrets

```bash
# Apply ConfigMap and Secrets
kubectl apply -f infra/kubernetes/configmap.yml -n redbus

# Verify
kubectl get configmaps -n redbus
kubectl get secrets -n redbus
```

### Step 4: Deploy Backend

```bash
# Apply deployment and service
kubectl apply -f infra/kubernetes/backend-deployment.yml -n redbus
kubectl apply -f infra/kubernetes/backend-service.yml -n redbus

# Verify
kubectl get pods -n redbus -l app=redbus-backend
kubectl get services -n redbus
```

### Step 5: Deploy Frontend

```bash
# Apply deployment and service
kubectl apply -f infra/kubernetes/frontend-deployment.yml -n redbus
kubectl apply -f infra/kubernetes/frontend-service.yml -n redbus

# Verify
kubectl get pods -n redbus -l app=redbus-frontend
kubectl get services -n redbus
```

### Step 6: Apply Ingress

```bash
# Install NGINX Ingress Controller (if not installed)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.0/deploy/static/provider/aws/deploy.yaml

# Apply Ingress
kubectl apply -f infra/kubernetes/ingress.yml -n redbus

# Verify
kubectl get ingress -n redbus
```

### Step 7: Verify Deployment

```bash
# Check all resources
kubectl get all -n redbus

# Check pod status
kubectl get pods -n redbus

# Check logs
kubectl logs -f deployment/frontend-deployment -n redbus
kubectl logs -f deployment/backend-deployment -n redbus
```

### One-Command Deployment

```bash
# Deploy all resources
kubectl apply -f infra/kubernetes/ -n redbus

# Check status
kubectl rollout status deployment/frontend-deployment -n redbus
kubectl rollout status deployment/backend-deployment -n redbus
```

---

## ⚖️ Scaling & Updates

### Manual Scaling

```bash
# Scale frontend to 3 replicas
kubectl scale deployment frontend-deployment --replicas=3 -n redbus

# Scale backend to 4 replicas
kubectl scale deployment backend-deployment --replicas=4 -n redbus

# Verify
kubectl get pods -n redbus
```

### Horizontal Pod Autoscaler (HPA)

```yaml
# hpa.yml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-hpa
  namespace: redbus
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

```bash
# Apply HPA
kubectl apply -f hpa.yml

# Check HPA status
kubectl get hpa -n redbus
```

### Rolling Updates

```bash
# Update image
kubectl set image deployment/frontend-deployment \
  frontend=123456789.dkr.ecr.us-east-1.amazonaws.com/redbus-frontend:v2 \
  -n redbus

# Watch rollout
kubectl rollout status deployment/frontend-deployment -n redbus

# Rollback if needed
kubectl rollout undo deployment/frontend-deployment -n redbus
```

---

## 📊 Monitoring & Debugging

### View Logs

```bash
# Pod logs
kubectl logs <pod-name> -n redbus

# Stream logs
kubectl logs -f <pod-name> -n redbus

# Previous container logs
kubectl logs <pod-name> --previous -n redbus

# All pods in deployment
kubectl logs -l app=redbus-backend -n redbus
```

### Debug Commands

```bash
# Describe pod (see events)
kubectl describe pod <pod-name> -n redbus

# Get pod events
kubectl get events -n redbus --sort-by='.lastTimestamp'

# Execute shell in pod
kubectl exec -it <pod-name> -n redbus -- /bin/sh

# Port forward for local testing
kubectl port-forward pod/<pod-name> 8080:80 -n redbus
kubectl port-forward service/frontend-service 8080:80 -n redbus
```

### Resource Usage

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods -n redbus

# All pods sorted by CPU
kubectl top pods -n redbus --sort-by=cpu
```

---

## ✅ Best Practices

### Resource Management

| Practice | Recommendation |
|----------|----------------|
| **Resource Requests** | Always set CPU and memory requests |
| **Resource Limits** | Set limits to prevent resource hogging |
| **Replicas** | Run at least 2 replicas for HA |
| **Pod Disruption Budget** | Ensure minimum available pods |

### Security

| Practice | Recommendation |
|----------|----------------|
| **Secrets** | Use Kubernetes Secrets for sensitive data |
| **RBAC** | Implement role-based access control |
| **Network Policies** | Restrict pod-to-pod communication |
| **Image Scanning** | Scan images with Trivy before deployment |

### Health Checks

| Probe | Purpose | Recommendation |
|-------|---------|----------------|
| **Liveness** | Restart unhealthy pods | Check /health endpoint |
| **Readiness** | Control traffic routing | Check app is ready |
| **Startup** | Slow-starting containers | For apps with long startup |

---

## 🔧 Troubleshooting

### Common Issues

#### Pod in CrashLoopBackOff

```bash
# Check pod logs
kubectl logs <pod-name> -n redbus --previous

# Describe pod for events
kubectl describe pod <pod-name> -n redbus

# Common causes:
# - Application error
# - Missing ConfigMap/Secret
# - Incorrect image
# - Resource limits too low
```

#### Pod in Pending State

```bash
# Check events
kubectl describe pod <pod-name> -n redbus

# Check node resources
kubectl describe nodes

# Common causes:
# - Insufficient resources
# - Node selector/affinity issues
# - PVC not bound
```

#### Service Not Accessible

```bash
# Check service exists
kubectl get service backend-service -n redbus

# Check endpoints
kubectl get endpoints backend-service -n redbus

# Test from within cluster
kubectl run debug --rm -it --image=busybox -- wget -qO- backend-service:5000
```

#### Ingress Not Working

```bash
# Check ingress status
kubectl get ingress -n redbus

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Debug Checklist

1. ✅ Check pod status: `kubectl get pods -n redbus`
2. ✅ Check pod logs: `kubectl logs <pod> -n redbus`
3. ✅ Check pod events: `kubectl describe pod <pod> -n redbus`
4. ✅ Check service endpoints: `kubectl get endpoints -n redbus`
5. ✅ Check node status: `kubectl get nodes`
6. ✅ Check resource usage: `kubectl top pods -n redbus`

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [eksctl Documentation](https://eksctl.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

---

<p align="center">
  <b>☸️ Kubernetes & AWS EKS for RedBus DevOps Project</b>
</p>
