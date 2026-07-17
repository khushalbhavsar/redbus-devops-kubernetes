# 📊 Monitoring Stack Documentation

This document provides comprehensive information about setting up Prometheus, Grafana, Node Exporter, and Kube State Metrics for the RedBus DevOps project, including complete dashboard creation and setup guides.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Monitoring Architecture](#-monitoring-architecture)
- [Prometheus](#-prometheus)
- [Grafana](#-grafana)
- [Node Exporter](#-node-exporter)
- [Kube State Metrics](#-kube-state-metrics)
- [Deployment Guide](#-deployment-guide)
- [Dashboard Creation](#-dashboard-creation)
- [PromQL Queries](#-promql-queries)
- [Alerting Setup](#-alerting-setup)
- [Troubleshooting](#-troubleshooting)

---

## 📌 Overview

### Monitoring Stack Components

| Component | Version | Purpose | Port |
|-----------|---------|---------|------|
| **Prometheus** | v2.48.0 | Metrics collection & storage | 9090 |
| **Grafana** | v10.2.0 | Visualization & dashboards | 3000 |
| **Node Exporter** | v1.7.0 | Node/host metrics | 9100 |
| **Kube State Metrics** | v2.10.1 | Kubernetes object metrics | 8080 |

### What Each Component Does

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                  MONITORING COMPONENTS                                      │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│   │                              PROMETHEUS (Time Series DB)                            │   │
│   │   • Collects metrics from all exporters                                             │   │
│   │   • Stores time-series data (15 days retention)                                     │   │
│   │   • Provides PromQL query language                                                  │   │
│   │   • Triggers alerts based on rules                                                  │   │
│   └─────────────────────────────────────────────────────────────────────────────────────┘   │
│                                          │                                                  │
│                    ┌─────────────────────┼─────────────────────┐                           │
│                    │                     │                     │                           │
│                    ▼                     ▼                     ▼                           │
│   ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐               │
│   │   NODE EXPORTER     │  │ KUBE STATE METRICS  │  │   APPLICATION       │               │
│   │                     │  │                     │  │   METRICS           │               │
│   │ • CPU usage         │  │ • Pod status        │  │ • HTTP requests     │               │
│   │ • Memory usage      │  │ • Deployment state  │  │ • Response times    │               │
│   │ • Disk I/O          │  │ • Node conditions   │  │ • Error rates       │               │
│   │ • Network traffic   │  │ • Replica counts    │  │ • Custom metrics    │               │
│   │ • System load       │  │ • Resource quotas   │  │                     │               │
│   └─────────────────────┘  └─────────────────────┘  └─────────────────────┘               │
│                                                                                             │
│                                          │                                                  │
│                                          ▼                                                  │
│   ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│   │                              GRAFANA (Visualization)                                │   │
│   │   • Creates beautiful dashboards                                                    │   │
│   │   • Supports multiple data sources                                                  │   │
│   │   • Alert notifications                                                             │   │
│   │   • User management                                                                 │   │
│   └─────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Access Information

| Service | NodePort | URL | Credentials |
|---------|----------|-----|-------------|
| Prometheus | 30090 | `http://<NODE_IP>:30090` | No auth |
| Grafana | 30030 | `http://<NODE_IP>:30030` | admin / admin123 |

---

## 🏗️ Monitoring Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              EKS CLUSTER - MONITORING NAMESPACE                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│   ┌───────────────────────────────────────────────────────────────────────────────────┐    │
│   │                                  PROMETHEUS                                        │    │
│   │   ┌─────────────┐    ┌─────────────────────────────────────────────────────────┐  │    │
│   │   │ Deployment  │    │                    ConfigMap                            │  │    │
│   │   │ replicas: 1 │    │  prometheus.yml:                                        │  │    │
│   │   │             │◄───│    - scrape_interval: 15s                               │  │    │
│   │   │ prometheus: │    │    - job: node-exporter                                 │  │    │
│   │   │   v2.48.0   │    │    - job: kube-state-metrics                            │  │    │
│   │   └─────────────┘    │    - job: kubernetes-nodes                              │  │    │
│   │         │            │    - job: kubernetes-cadvisor                           │  │    │
│   │         ▼            └─────────────────────────────────────────────────────────┘  │    │
│   │   ┌─────────────┐                                                                 │    │
│   │   │   Service   │    ┌─────────────┐  ┌─────────────┐                            │    │
│   │   │  NodePort   │    │ServiceAcct  │  │ ClusterRole │                            │    │
│   │   │   :30090    │    │ prometheus  │──│  prometheus │                            │    │
│   │   └─────────────┘    └─────────────┘  └─────────────┘                            │    │
│   └───────────────────────────────────────────────────────────────────────────────────┘    │
│                                           │                                                 │
│                     ┌─────────────────────┼─────────────────────┐                          │
│                     │ scrapes             │ scrapes             │ scrapes                  │
│                     ▼                     ▼                     ▼                          │
│   ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐               │
│   │   NODE EXPORTER     │  │ KUBE STATE METRICS  │  │    GRAFANA          │               │
│   │   (DaemonSet)       │  │   (Deployment)      │  │   (Deployment)      │               │
│   │                     │  │                     │  │                     │               │
│   │  Runs on every node │  │  Single replica     │  │  Single replica     │               │
│   │  Port: 9100         │  │  Port: 8080, 8081   │  │  Port: 3000         │               │
│   │                     │  │                     │  │                     │               │
│   │  Metrics:           │  │  Metrics:           │  │  Features:          │               │
│   │  • node_cpu_*       │  │  • kube_pod_*       │  │  • Dashboards       │               │
│   │  • node_memory_*    │  │  • kube_deployment_*│  │  • Data sources     │               │
│   │  • node_disk_*      │  │  • kube_node_*      │  │  • Alerting         │               │
│   │  • node_network_*   │  │  • kube_service_*   │  │  • Users            │               │
│   │                     │  │                     │  │                     │               │
│   │   ┌───────────┐     │  │   ┌───────────┐     │  │   ┌───────────┐     │               │
│   │   │ Service   │     │  │   │ Service   │     │  │   │ Service   │     │               │
│   │   │ ClusterIP │     │  │   │ ClusterIP │     │  │   │ NodePort  │     │               │
│   │   │   :9100   │     │  │   │   :8080   │     │  │   │  :30030   │     │               │
│   │   └───────────┘     │  │   └───────────┘     │  │   └───────────┘     │               │
│   └─────────────────────┘  └─────────────────────┘  └─────────────────────┘               │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔥 Prometheus

### What is Prometheus?

Prometheus is an open-source systems monitoring and alerting toolkit. It collects and stores metrics as time-series data, providing a powerful query language (PromQL) for analysis.

### Key Features

| Feature | Description |
|---------|-------------|
| **Multi-dimensional data model** | Time series identified by metric name and key/value pairs |
| **PromQL** | Flexible query language for slicing and dicing data |
| **Pull-based collection** | Prometheus scrapes metrics from targets |
| **Service discovery** | Automatic discovery of Kubernetes targets |
| **Alerting** | Define alert rules and send notifications |
| **Visualization** | Built-in expression browser |

### Prometheus Deployment (prometheus-deployment.yml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    app: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      containers:
        - name: prometheus
          image: prom/prometheus:v2.48.0
          args:
            - "--config.file=/etc/prometheus/prometheus.yml"
            - "--storage.tsdb.path=/prometheus"
            - "--storage.tsdb.retention.time=15d"
            - "--web.enable-lifecycle"
            - "--web.enable-admin-api"
          ports:
            - containerPort: 9090
              name: http
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          volumeMounts:
            - name: prometheus-config
              mountPath: /etc/prometheus
            - name: prometheus-storage
              mountPath: /prometheus
          livenessProbe:
            httpGet:
              path: /-/healthy
              port: 9090
            initialDelaySeconds: 30
            periodSeconds: 15
          readinessProbe:
            httpGet:
              path: /-/ready
              port: 9090
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: prometheus-config
          configMap:
            name: prometheus-config
        - name: prometheus-storage
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  type: NodePort
  ports:
    - port: 9090
      targetPort: 9090
      nodePort: 30090
  selector:
    app: prometheus
```

### Prometheus Configuration (prometheus-configmap.yml)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
      external_labels:
        cluster: 'redbus-cluster'
        env: 'production'

    scrape_configs:
      # Prometheus self-monitoring
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']

      # Node Exporter
      - job_name: 'node-exporter'
        kubernetes_sd_configs:
          - role: endpoints
            namespaces:
              names:
                - monitoring
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_name]
            regex: node-exporter
            action: keep
          - source_labels: [__meta_kubernetes_endpoint_port_name]
            regex: metrics
            action: keep

      # Kube State Metrics
      - job_name: 'kube-state-metrics'
        kubernetes_sd_configs:
          - role: endpoints
            namespaces:
              names:
                - monitoring
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_name]
            regex: kube-state-metrics
            action: keep
          - source_labels: [__meta_kubernetes_endpoint_port_name]
            regex: http-metrics
            action: keep

      # Kubernetes Nodes (kubelet)
      - job_name: 'kubernetes-nodes'
        kubernetes_sd_configs:
          - role: node
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

      # Kubernetes Cadvisor (container metrics)
      - job_name: 'kubernetes-cadvisor'
        kubernetes_sd_configs:
          - role: node
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
          - target_label: __metrics_path__
            replacement: /metrics/cadvisor
```

### Prometheus RBAC (prometheus-rbac.yml)

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  - apiGroups: [""]
    resources:
      - nodes
      - nodes/proxy
      - nodes/metrics
      - services
      - endpoints
      - pods
    verbs: ["get", "list", "watch"]
  - apiGroups: ["extensions", "networking.k8s.io"]
    resources:
      - ingresses
    verbs: ["get", "list", "watch"]
  - nonResourceURLs: ["/metrics", "/metrics/cadvisor"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: monitoring
```

### Prometheus UI Guide

#### Access Prometheus

```bash
# Get node IP
kubectl get nodes -o wide

# Access via browser
http://<NODE_IP>:30090
```

#### Key Pages

| Page | Path | Purpose |
|------|------|---------|
| Graph | `/graph` | Query and visualize metrics |
| Targets | `/targets` | View scrape targets status |
| Config | `/config` | View current configuration |
| Rules | `/rules` | View alerting/recording rules |
| Status | `/status` | Runtime information |

---

## 📈 Grafana

### What is Grafana?

Grafana is an open-source analytics and interactive visualization platform. It provides beautiful dashboards for your metrics data with support for multiple data sources.

### Key Features

| Feature | Description |
|---------|-------------|
| **Dashboards** | Create and share interactive dashboards |
| **Data Sources** | Connect to Prometheus, InfluxDB, MySQL, etc. |
| **Alerting** | Set up alerts with notifications |
| **Plugins** | Extend functionality with plugins |
| **Users & Teams** | Role-based access control |
| **Annotations** | Mark events on graphs |

### Grafana Deployment (grafana-deployment.yml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
  labels:
    app: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
        - name: grafana
          image: grafana/grafana:10.2.0
          ports:
            - containerPort: 3000
              name: http
          env:
            - name: GF_SECURITY_ADMIN_USER
              value: "admin"
            - name: GF_SECURITY_ADMIN_PASSWORD
              value: "admin123"
            - name: GF_USERS_ALLOW_SIGN_UP
              value: "false"
            - name: GF_SERVER_ROOT_URL
              value: "http://localhost:3000"
            - name: GF_AUTH_ANONYMOUS_ENABLED
              value: "false"
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "250m"
          volumeMounts:
            - name: grafana-datasources
              mountPath: /etc/grafana/provisioning/datasources
            - name: grafana-dashboards-provider
              mountPath: /etc/grafana/provisioning/dashboards
            - name: grafana-storage
              mountPath: /var/lib/grafana
          livenessProbe:
            httpGet:
              path: /api/health
              port: 3000
            initialDelaySeconds: 60
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /api/health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: grafana-datasources
          configMap:
            name: grafana-datasources
        - name: grafana-dashboards-provider
          configMap:
            name: grafana-dashboards-provider
        - name: grafana-storage
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  type: NodePort
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 30030
  selector:
    app: grafana
```

### Grafana ConfigMaps (grafana-configmap.yml)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: monitoring
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus:9090
        isDefault: true
        editable: true
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards-provider
  namespace: monitoring
data:
  dashboards.yaml: |
    apiVersion: 1
    providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards
```

### Grafana Installation (Standalone)

```bash
#!/bin/bash
# Location: scripts/monitoring/grafana.sh

# Update system packages
sudo yum update -y

# Install required dependencies
sudo yum install -y wget

# Create Grafana repository file
cat <<EOF | sudo tee /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# Install Grafana
sudo yum install grafana -y

# Start and enable Grafana service
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Access at http://your-server-ip:3000
# Default credentials: admin / admin
```

---

## 🖥️ Node Exporter

### What is Node Exporter?

Node Exporter is a Prometheus exporter for hardware and OS metrics. It runs as a DaemonSet on every node to collect system-level metrics.

### Metrics Collected

| Category | Metrics | Description |
|----------|---------|-------------|
| **CPU** | `node_cpu_seconds_total` | CPU usage per core and mode |
| **Memory** | `node_memory_*` | Memory usage, free, cached, buffers |
| **Disk** | `node_disk_*` | Disk I/O, read/write bytes |
| **Filesystem** | `node_filesystem_*` | Disk space usage |
| **Network** | `node_network_*` | Network I/O, packets, errors |
| **Load** | `node_load1`, `node_load5`, `node_load15` | System load averages |

### Node Exporter DaemonSet (node-exporter.yml)

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    app: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9100"
    spec:
      hostNetwork: true
      hostPID: true
      containers:
        - name: node-exporter
          image: prom/node-exporter:v1.7.0
          args:
            - "--path.procfs=/host/proc"
            - "--path.sysfs=/host/sys"
            - "--path.rootfs=/host/root"
            - "--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)"
          ports:
            - containerPort: 9100
              hostPort: 9100
              name: metrics
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "100m"
          volumeMounts:
            - name: proc
              mountPath: /host/proc
              readOnly: true
            - name: sys
              mountPath: /host/sys
              readOnly: true
            - name: root
              mountPath: /host/root
              readOnly: true
      volumes:
        - name: proc
          hostPath:
            path: /proc
        - name: sys
          hostPath:
            path: /sys
        - name: root
          hostPath:
            path: /
      tolerations:
        - effect: NoSchedule
          operator: Exists
---
apiVersion: v1
kind: Service
metadata:
  name: node-exporter
  namespace: monitoring
spec:
  type: ClusterIP
  ports:
    - port: 9100
      targetPort: 9100
      name: metrics
  selector:
    app: node-exporter
```

### Key Node Exporter Metrics

| Metric | Description | Example Query |
|--------|-------------|---------------|
| `node_cpu_seconds_total` | CPU time spent in each mode | `rate(node_cpu_seconds_total{mode="idle"}[5m])` |
| `node_memory_MemTotal_bytes` | Total memory | `node_memory_MemTotal_bytes` |
| `node_memory_MemAvailable_bytes` | Available memory | `node_memory_MemAvailable_bytes` |
| `node_filesystem_size_bytes` | Total filesystem size | `node_filesystem_size_bytes` |
| `node_filesystem_avail_bytes` | Available filesystem space | `node_filesystem_avail_bytes` |
| `node_network_receive_bytes_total` | Network bytes received | `rate(node_network_receive_bytes_total[5m])` |
| `node_load1` | 1-minute load average | `node_load1` |

---

## 📊 Kube State Metrics

### What is Kube State Metrics?

Kube State Metrics (KSM) is a service that listens to the Kubernetes API server and generates metrics about the state of objects like deployments, nodes, and pods.

### Metrics Generated

| Object | Metrics | Examples |
|--------|---------|----------|
| **Pods** | `kube_pod_*` | Status, phase, containers, restarts |
| **Deployments** | `kube_deployment_*` | Replicas, available, conditions |
| **Nodes** | `kube_node_*` | Status, conditions, allocatable |
| **Services** | `kube_service_*` | Type, ports, labels |
| **Namespaces** | `kube_namespace_*` | Status, labels |
| **ConfigMaps** | `kube_configmap_*` | Metadata, labels |
| **Secrets** | `kube_secret_*` | Metadata, type |

### Kube State Metrics Deployment (kube-state-metrics.yml)

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-state-metrics
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-state-metrics
rules:
  - apiGroups: [""]
    resources:
      - configmaps
      - secrets
      - nodes
      - pods
      - services
      - resourcequotas
      - replicationcontrollers
      - limitranges
      - persistentvolumeclaims
      - persistentvolumes
      - namespaces
      - endpoints
    verbs: ["list", "watch"]
  - apiGroups: ["apps"]
    resources:
      - statefulsets
      - daemonsets
      - deployments
      - replicasets
    verbs: ["list", "watch"]
  - apiGroups: ["batch"]
    resources:
      - cronjobs
      - jobs
    verbs: ["list", "watch"]
  - apiGroups: ["autoscaling"]
    resources:
      - horizontalpodautoscalers
    verbs: ["list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources:
      - ingresses
    verbs: ["list", "watch"]
  - apiGroups: ["storage.k8s.io"]
    resources:
      - storageclasses
      - volumeattachments
    verbs: ["list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-state-metrics
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-state-metrics
subjects:
  - kind: ServiceAccount
    name: kube-state-metrics
    namespace: monitoring
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-state-metrics
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-state-metrics
  template:
    metadata:
      labels:
        app: kube-state-metrics
    spec:
      serviceAccountName: kube-state-metrics
      containers:
        - name: kube-state-metrics
          image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.10.1
          ports:
            - containerPort: 8080
              name: http-metrics
            - containerPort: 8081
              name: telemetry
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "100m"
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 5
          readinessProbe:
            httpGet:
              path: /
              port: 8081
            initialDelaySeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: kube-state-metrics
  namespace: monitoring
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
spec:
  type: ClusterIP
  ports:
    - port: 8080
      targetPort: 8080
      name: http-metrics
    - port: 8081
      targetPort: 8081
      name: telemetry
  selector:
    app: kube-state-metrics
```

### Key Kube State Metrics

| Metric | Description |
|--------|-------------|
| `kube_pod_status_phase` | Pod phase (Pending, Running, Succeeded, Failed) |
| `kube_pod_container_status_restarts_total` | Container restart count |
| `kube_deployment_status_replicas` | Number of replicas |
| `kube_deployment_status_replicas_available` | Available replicas |
| `kube_node_status_condition` | Node conditions (Ready, MemoryPressure, etc.) |
| `kube_node_status_allocatable` | Allocatable resources |

---

## 🚀 Deployment Guide

### EC2 Instance Requirements

| Component | Instance Type | Security Group Inbound Ports |
|-----------|--------------|------------------------------|
| Grafana Server | t3.medium | 3000, 9090, 9100 |

---

## 📦 EC2 Installation (Standalone Setup)

### 🟠 Grafana Server Installation

#### 1️⃣ Update System & Install Dependencies

```bash
sudo yum update -y
sudo yum install wget tar -y
sudo yum install make -y
```

#### 2️⃣ Install Grafana Enterprise

```bash
sudo yum install -y https://dl.grafana.com/grafana-enterprise/release/12.2.1/grafana-enterprise_12.2.1_18655849634_linux_amd64.rpm
```

#### 3️⃣ Start Grafana Service

```bash
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo systemctl status grafana-server
grafana-server --version
```

#### 4️⃣ Access Grafana

Open in browser:

```
http://<EC2_PUBLIC_IP>:3000
```

**Default Credentials:**
- Username: `admin`
- Password: `admin`
- Change password to: `Admin@123`

---

### 🔥 Prometheus Installation

#### 1️⃣ Download Prometheus

```bash
# Download from https://prometheus.io/download/
wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-amd64.tar.gz
```

#### 2️⃣ Extract & Setup

```bash
sudo tar -xvf prometheus-3.5.0.linux-amd64.tar.gz
sudo mv prometheus-3.5.0.linux-amd64 prometheus
```

#### 3️⃣ Create Prometheus User

```bash
sudo useradd --no-create-home --shell /bin/false prometheus
```

#### 4️⃣ Setup Directories & Binaries

```bash
cd prometheus

# Copy binaries
sudo cp -r prometheus /usr/local/bin/
sudo cp -r promtool /usr/local/bin/

# Create directories
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# Copy config
sudo cp prometheus.yml /etc/prometheus/

# Set ownership
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
```

#### 5️⃣ Create Systemd Service

```bash
sudo nano /etc/systemd/system/prometheus.service
```

Paste:

```ini
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
```

Save & exit.

#### 6️⃣ Start Prometheus

```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl status prometheus
```

#### 7️⃣ Access Prometheus UI

Open in browser:

```
http://<EC2_PUBLIC_IP>:9090
```

---

### 📊 Node Exporter Installation

#### 1️⃣ Download Node Exporter

```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
tar xvf node_exporter-1.10.2.linux-amd64.tar.gz
cd node_exporter-1.10.2.linux-amd64
```

#### 2️⃣ Setup Node Exporter

```bash
sudo cp node_exporter /usr/local/bin
sudo useradd node_exporter --no-create-home --shell /bin/false
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

#### 3️⃣ Create Systemd Service

```bash
sudo nano /etc/systemd/system/node_exporter.service
```

Paste:

```ini
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
```

Save & exit.

#### 4️⃣ Start Node Exporter

```bash
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter
```

#### 5️⃣ Verify Node Exporter

Open in browser:

```
http://<EC2_PUBLIC_IP>:9100/metrics
```

---

### 🔗 Configure Prometheus to Scrape Node Exporter

Edit Prometheus config:

```bash
sudo nano /etc/prometheus/prometheus.yml
```

Add Node Exporter job:

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
```

Restart Prometheus:

```bash
sudo systemctl restart prometheus
```

---

## ☸️ Kubernetes Deployment Guide

### Prerequisites

1. EKS cluster running
2. kubectl configured
3. Sufficient node resources

### Step-by-Step Deployment

#### Option 1: Using Deployment Script

```bash
#!/bin/bash
# Location: scripts/monitoring/deploy-monitoring.sh

set -e

echo "🚀 Deploying Prometheus & Grafana Monitoring Stack..."

# Apply all monitoring manifests in order
kubectl apply -f infra/kubernetes/monitoring/namespace.yml
kubectl apply -f infra/kubernetes/monitoring/prometheus-rbac.yml
kubectl apply -f infra/kubernetes/monitoring/prometheus-configmap.yml
kubectl apply -f infra/kubernetes/monitoring/prometheus-deployment.yml
kubectl apply -f infra/kubernetes/monitoring/grafana-configmap.yml
kubectl apply -f infra/kubernetes/monitoring/grafana-deployment.yml
kubectl apply -f infra/kubernetes/monitoring/node-exporter.yml
kubectl apply -f infra/kubernetes/monitoring/kube-state-metrics.yml

echo "⏳ Waiting for deployments..."
kubectl rollout status daemonset/node-exporter -n monitoring --timeout=120s
kubectl rollout status deployment/kube-state-metrics -n monitoring --timeout=120s
kubectl rollout status deployment/prometheus -n monitoring --timeout=120s
kubectl rollout status deployment/grafana -n monitoring --timeout=120s

echo "✅ Monitoring Stack Deployed Successfully!"
echo ""
echo "📊 Access URLs:"
echo "   Prometheus: http://<NODE_IP>:30090"
echo "   Grafana:    http://<NODE_IP>:30030"
echo ""
echo "🔑 Grafana Credentials:"
echo "   Username: admin"
echo "   Password: admin123"
```

#### Option 2: Manual Step-by-Step

```bash
# Step 1: Create monitoring namespace
kubectl apply -f infra/kubernetes/monitoring/namespace.yml

# Step 2: Deploy Prometheus RBAC
kubectl apply -f infra/kubernetes/monitoring/prometheus-rbac.yml

# Step 3: Deploy Prometheus ConfigMap
kubectl apply -f infra/kubernetes/monitoring/prometheus-configmap.yml

# Step 4: Deploy Prometheus
kubectl apply -f infra/kubernetes/monitoring/prometheus-deployment.yml

# Step 5: Deploy Grafana ConfigMaps
kubectl apply -f infra/kubernetes/monitoring/grafana-configmap.yml

# Step 6: Deploy Grafana
kubectl apply -f infra/kubernetes/monitoring/grafana-deployment.yml

# Step 7: Deploy Node Exporter
kubectl apply -f infra/kubernetes/monitoring/node-exporter.yml

# Step 8: Deploy Kube State Metrics
kubectl apply -f infra/kubernetes/monitoring/kube-state-metrics.yml

# Verify deployment
kubectl get all -n monitoring
```

### Verify Targets in Prometheus

1. Access Prometheus: `http://<NODE_IP>:30090`
2. Go to **Status → Targets**
3. Verify all targets are **UP**:
   - `prometheus` (1/1 up)
   - `node-exporter` (n/n up, where n = number of nodes)
   - `kube-state-metrics` (1/1 up)

---

## 📊 Dashboard Creation

### Recommended Dashboards

| Dashboard ID | Name | Data Required |
|--------------|------|---------------|
| **1860** | Node Exporter Full | Node Exporter |
| **11074** | Node Exporter for Prometheus | Node Exporter |
| **7249** | Kubernetes Cluster | Kube State Metrics |
| **6417** | Kubernetes Cluster (Prometheus) | KSM + Node Exporter |
| **315** | Kubernetes Cluster Monitoring | All metrics |

### Step-by-Step Dashboard Setup

#### Step 1: Access Grafana

```bash
# Get node IP
kubectl get nodes -o wide

# Access Grafana
http://<NODE_IP>:30030

# Login
Username: admin
Password: admin123
```

#### Step 2: Verify Data Source

1. Go to **Configuration → Data Sources**
2. Click on **Prometheus**
3. Verify URL: `http://prometheus:9090`
4. Click **Save & Test** → Should show "Data source is working"

#### Step 3: Import Dashboard

1. Click **+ (Create)** → **Import**
2. Enter Dashboard ID (e.g., `1860`)
3. Click **Load**
4. Select **Prometheus** as data source
5. Click **Import**

### Dashboard 1860 - Node Exporter Full

This dashboard provides comprehensive node metrics:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        NODE EXPORTER FULL (1860)                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐  │
│  │    CPU Busy %       │  │   Memory Usage %    │  │    Disk Space %     │  │
│  │      [====--]       │  │      [=======-]     │  │      [===-----]     │  │
│  │       45%           │  │        78%          │  │        35%          │  │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────────┘  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      CPU Usage Over Time                            │   │
│  │  100% ┤                                                              │   │
│  │   80% ┤    ╭─╮      ╭╮                                               │   │
│  │   60% ┤   ╭╯ ╰╮    ╭╯╰╮     ╭╮                                      │   │
│  │   40% ┤╭╮╭╯   ╰─╮╭╮╭╯  ╰╮   ╭╯╰╮                                    │   │
│  │   20% ┼╯╰╯      ╰╯╰╯    ╰╮╭╮╯  ╰───────────                         │   │
│  │    0% ┴──────────────────╰╯──────────────────────────────────────   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────┐  ┌─────────────────────────────────────┐  │
│  │     Network Traffic         │  │        Disk I/O                     │  │
│  │  IN:  125 MB/s              │  │  Read:  50 MB/s                     │  │
│  │  OUT: 85 MB/s               │  │  Write: 30 MB/s                     │  │
│  └─────────────────────────────┘  └─────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Panels included:**
- Quick CPU / Mem / Disk stats
- System load
- CPU usage per core
- Memory usage breakdown
- Network traffic (in/out)
- Disk I/O
- Filesystem usage
- Network errors

### Dashboard 7249 - Kubernetes Cluster

This dashboard provides Kubernetes-specific metrics:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     KUBERNETES CLUSTER (7249)                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Nodes      │  │    Pods      │  │ Deployments  │  │  Services    │    │
│  │     3        │  │     12       │  │      5       │  │      8       │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      POD STATUS BY NAMESPACE                        │   │
│  │  ┌─────────────┬────────────┬─────────┬─────────┬─────────────┐    │   │
│  │  │ Namespace   │  Running   │ Pending │ Failed  │  Succeeded  │    │   │
│  │  ├─────────────┼────────────┼─────────┼─────────┼─────────────┤    │   │
│  │  │ redbus      │     4      │    0    │    0    │      0      │    │   │
│  │  │ monitoring  │     4      │    0    │    0    │      0      │    │   │
│  │  │ kube-system │     8      │    0    │    0    │      0      │    │   │
│  │  └─────────────┴────────────┴─────────┴─────────┴─────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌───────────────────────────────────┐  ┌───────────────────────────────┐  │
│  │      Deployment Status            │  │    Container Restarts         │  │
│  │                                   │  │                               │  │
│  │  frontend-deployment: 2/2 ✓      │  │  frontend: 0                  │  │
│  │  backend-deployment:  2/2 ✓      │  │  backend:  0                  │  │
│  │  prometheus:          1/1 ✓      │  │  prometheus: 0                │  │
│  │  grafana:             1/1 ✓      │  │  grafana: 0                   │  │
│  └───────────────────────────────────┘  └───────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Panels included:**
- Cluster overview stats
- Pod status by namespace
- Deployment replica status
- Node conditions
- Container restarts
- Resource quotas
- PVC status

### Create Custom Dashboard

#### Step 1: Create New Dashboard

1. Click **+ (Create)** → **Dashboard**
2. Click **Add visualization**

#### Step 2: Add CPU Usage Panel

```
Title: CPU Usage %
Query: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
Legend: CPU Usage
Visualization: Gauge or Graph
```

#### Step 3: Add Memory Usage Panel

```
Title: Memory Usage %
Query: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
Legend: Memory Usage
Visualization: Gauge or Graph
```

#### Step 4: Add Pod Count Panel

```
Title: Running Pods
Query: sum(kube_pod_status_phase{phase="Running"})
Legend: Running Pods
Visualization: Stat
```

#### Step 5: Add Container Restarts Panel

```
Title: Container Restarts (Last 1h)
Query: sum(increase(kube_pod_container_status_restarts_total[1h])) by (pod)
Legend: {{pod}}
Visualization: Table
```

#### Step 6: Save Dashboard

1. Click **Save dashboard** (disk icon)
2. Enter name: "RedBus Monitoring"
3. Click **Save**

---

## 📝 PromQL Queries

### Node Metrics

```promql
# CPU Usage Percentage
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage Percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk Usage Percentage
(1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100

# Network Receive Rate (bytes/sec)
rate(node_network_receive_bytes_total{device!="lo"}[5m])

# Network Transmit Rate (bytes/sec)
rate(node_network_transmit_bytes_total{device!="lo"}[5m])

# System Load (1 min)
node_load1
```

### Kubernetes Metrics

```promql
# Total Running Pods
sum(kube_pod_status_phase{phase="Running"})

# Pods by Namespace
sum(kube_pod_status_phase{phase="Running"}) by (namespace)

# Deployment Replicas Available
kube_deployment_status_replicas_available

# Deployment Replicas Unavailable
kube_deployment_status_replicas_unavailable

# Pod Restarts in Last Hour
sum(increase(kube_pod_container_status_restarts_total[1h])) by (pod, namespace)

# Nodes Ready
sum(kube_node_status_condition{condition="Ready",status="true"})

# Pods Not Running
sum(kube_pod_status_phase{phase!="Running",phase!="Succeeded"}) by (namespace, pod)
```

### Container Metrics

```promql
# Container CPU Usage
sum(rate(container_cpu_usage_seconds_total{namespace="redbus"}[5m])) by (pod)

# Container Memory Usage
sum(container_memory_usage_bytes{namespace="redbus"}) by (pod)

# Container Network Receive
sum(rate(container_network_receive_bytes_total{namespace="redbus"}[5m])) by (pod)

# Container Network Transmit
sum(rate(container_network_transmit_bytes_total{namespace="redbus"}[5m])) by (pod)
```

---

## 🔔 Alerting Setup

### Prometheus Alert Rules

Create alert rules file:

```yaml
# prometheus-alerts.yml
groups:
  - name: node-alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for more than 5 minutes"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 85%"

      - alert: DiskSpaceLow
        expr: (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space"
          description: "Disk usage is above 80%"

  - name: kubernetes-alerts
    rules:
      - alert: PodCrashLooping
        expr: increase(kube_pod_container_status_restarts_total[1h]) > 3
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pod is crash looping"
          description: "Pod {{ $labels.pod }} has restarted more than 3 times in the last hour"

      - alert: DeploymentReplicasUnavailable
        expr: kube_deployment_status_replicas_unavailable > 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Deployment has unavailable replicas"
          description: "Deployment {{ $labels.deployment }} has {{ $value }} unavailable replicas"

      - alert: NodeNotReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Node is not ready"
          description: "Node {{ $labels.node }} is not ready"
```

### Grafana Alerting

#### Step 1: Create Alert Rule

1. Go to dashboard panel
2. Click **Edit**
3. Go to **Alert** tab
4. Click **Create alert rule from this panel**

#### Step 2: Configure Alert

```
Name: High CPU Alert
Evaluate every: 1m
For: 5m
Condition: WHEN avg() OF query(A, 5m, now) IS ABOVE 80
```

#### Step 3: Add Notification

1. Go to **Alerting → Contact points**
2. Add email/Slack notification
3. Link to alert rule

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Prometheus Target Down

```bash
# Check target status
kubectl logs deployment/prometheus -n monitoring

# Verify service exists
kubectl get svc -n monitoring

# Check endpoints
kubectl get endpoints -n monitoring

# Test connectivity
kubectl exec -it deployment/prometheus -n monitoring -- wget -qO- http://node-exporter:9100/metrics
```

#### 2. No Data in Grafana

```bash
# Verify Prometheus is receiving data
# Access Prometheus UI and run query

# Check Grafana data source
# Go to Configuration → Data Sources → Test

# Check Grafana logs
kubectl logs deployment/grafana -n monitoring
```

#### 3. Node Exporter Not Running

```bash
# Check DaemonSet status
kubectl get daemonset node-exporter -n monitoring

# Check pods on each node
kubectl get pods -n monitoring -l app=node-exporter -o wide

# Check pod logs
kubectl logs -l app=node-exporter -n monitoring
```

#### 4. Kube State Metrics No Data

```bash
# Check deployment
kubectl get deployment kube-state-metrics -n monitoring

# Check RBAC
kubectl get clusterrolebinding kube-state-metrics

# Check logs
kubectl logs deployment/kube-state-metrics -n monitoring
```

### Useful Commands

```bash
# Get all monitoring resources
kubectl get all -n monitoring

# Check pod logs
kubectl logs -f deployment/prometheus -n monitoring
kubectl logs -f deployment/grafana -n monitoring

# Port forward for local access
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
kubectl port-forward svc/grafana 3000:3000 -n monitoring

# Restart deployments
kubectl rollout restart deployment/prometheus -n monitoring
kubectl rollout restart deployment/grafana -n monitoring

# Delete and redeploy
kubectl delete -f infra/kubernetes/monitoring/
kubectl apply -f infra/kubernetes/monitoring/
```

---

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- [Kube State Metrics GitHub](https://github.com/kubernetes/kube-state-metrics)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboard Gallery](https://grafana.com/grafana/dashboards/)

---

<p align="center">
  <b>📊 Monitoring Stack for RedBus DevOps Project</b>
</p>
