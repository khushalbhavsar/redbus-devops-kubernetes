# 🔒 Security Scanning Documentation

This document covers the installation and usage of security scanning tools for the RedBus DevOps project.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Trivy Installation](#-trivy-installation)
- [OWASP ZAP Installation](#-owasp-zap-installation)
- [DevSecOps Pipeline](#-devsecops-pipeline)
- [Troubleshooting](#-troubleshooting)

---

## 📌 Overview

| Tool | Purpose | Type |
|------|---------|------|
| **Trivy** | Container & filesystem vulnerability scanner | Static Analysis |
| **OWASP ZAP** | Web application security scanner | Dynamic Analysis |

> Compatible with **Amazon Linux 2 / Amazon Linux 2023**

---

## 🔥 Trivy Installation

### Step 1: Update Server

```bash
sudo yum update -y
```

### Step 2: Add Official Repository

```bash
sudo rpm -ivh https://aquasecurity.github.io/trivy-repo/rpm/releases/trivy.repo
```

### Step 3: Install Trivy

```bash
sudo yum install trivy -y
```

### Step 4: Verify Installation

```bash
trivy --version
```

### Step 5: Download Vulnerability Database

```bash
trivy --download-db-only
```

> This makes future scans faster by pre-downloading the vulnerability database.

### Test Trivy

```bash
trivy image nginx
```

---

## 🛡️ OWASP ZAP Installation

> **Recommended:** Install via Docker to avoid Java dependency issues.

### Step 1: Install Docker (Skip if already installed)

```bash
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker ec2-user
```

**Logout and login again**, then verify:

```bash
docker --version
```

### Step 2: Pull OWASP ZAP Image

```bash
docker pull ghcr.io/zaproxy/zaproxy:stable
```

### Step 3: Verify Installation

```bash
docker run -t ghcr.io/zaproxy/zaproxy:stable zap.sh -version
```

---

## 🔍 Running Security Scans

### Trivy Scans

| Scan Type | Command |
|-----------|---------|
| **Image Scan** | `trivy image <image-name>` |
| **Filesystem Scan** | `trivy fs .` |
| **High/Critical Only** | `trivy image --severity HIGH,CRITICAL <image>` |

```bash
# Scan Docker image
trivy image redbus-backend:latest

# Scan filesystem
trivy fs --severity HIGH,CRITICAL .

# Generate HTML report
trivy fs --format template --template "@/usr/local/share/trivy/templates/html.tpl" -o report.html .
```

### OWASP ZAP Scans

| Scan Type | Use Case | Command |
|-----------|----------|---------|
| **Baseline Scan** | Safe for production | `zap-baseline.py` |
| **Full Scan** | Staging/test only | `zap-full-scan.py` |

#### Baseline Scan (Safe - Passive)

```bash
docker run -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t https://example.com
```

#### Full Attack Scan (Staging Only)

```bash
docker run -t ghcr.io/zaproxy/zaproxy:stable \
  zap-full-scan.py -t https://example.com
```

> ⚠️ **Warning:** Never run full scan on live production apps.

#### Generate HTML Report

```bash
docker run -v $(pwd):/zap/wrk/:rw -t \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
  -t https://example.com \
  -r zap-report.html
```

Report saved in current directory. Useful for:
- Jenkins artifacts
- Security audits
- Compliance documentation

---

## 🔄 DevSecOps Pipeline

Recommended security scanning order in CI/CD:

```
┌─────────────────────┐
│   Build Docker Image │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│   Trivy Image Scan   │ ← Container vulnerabilities
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Deploy to Staging   │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│   OWASP ZAP Scan     │ ← Web application attacks
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ Deploy to Production │
└─────────────────────┘
```

### Jenkins Pipeline Example

```groovy
stage('Trivy Scan') {
    steps {
        sh 'trivy image --severity HIGH,CRITICAL --exit-code 1 redbus-backend:latest'
    }
}

stage('OWASP ZAP Scan') {
    steps {
        sh '''
            docker run -v $(pwd):/zap/wrk/:rw -t \
            ghcr.io/zaproxy/zaproxy:stable \
            zap-baseline.py -t https://staging.example.com -r zap-report.html
        '''
    }
}
```

---

## 🔧 Troubleshooting

### Permission Denied (Docker)

```bash
# Option 1: Fix socket permissions
sudo chmod 666 /var/run/docker.sock

# Option 2: Re-login after adding docker group
sudo usermod -aG docker $USER
# Then logout and login again
```

### Trivy Database Download Fails

```bash
# Clear cache and retry
trivy --clear-cache
trivy --download-db-only
```

### OWASP ZAP Memory Issues

```bash
# Increase memory allocation
docker run -e ZAP_MEMORY=4g -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://example.com
```

---

## 📚 Additional Resources

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [DevSecOps Best Practices](https://owasp.org/www-project-devsecops-guideline/)
