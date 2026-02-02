# 🔄 Jenkins CI/CD Pipeline Documentation

This document provides comprehensive information about the Jenkins CI/CD pipeline, including step-by-step setup guides for Jenkins, SonarQube, Trivy, OWASP Dependency Check, Git, and GitHub integration.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Pipeline Architecture](#-pipeline-architecture)
- [Pipeline Stages](#-pipeline-stages)
- [Complete Jenkinsfile](#-complete-jenkinsfile)
- [Jenkins Installation & Setup](#-jenkins-installation--setup)
- [Git & GitHub Integration](#-git--github-integration)
- [SonarQube Setup](#-sonarqube-setup)
- [Trivy Security Scanner](#-trivy-security-scanner)
- [OWASP Dependency Check](#-owasp-dependency-check)
- [Credentials Configuration](#-credentials-configuration)
- [Email Notifications](#-email-notifications)
- [Pipeline Execution](#-pipeline-execution)
- [Troubleshooting](#-troubleshooting)

---

## 📌 Overview

The RedBus DevOps project uses a comprehensive Jenkins CI/CD pipeline with 11+ stages covering code quality, security scanning, containerization, and Kubernetes deployment.

### Pipeline Summary

| Aspect | Details |
|--------|---------|
| **Pipeline Type** | Declarative Pipeline |
| **Stages** | 11+ stages |
| **Parallel Execution** | Yes (Dependencies, Tests, Docker builds) |
| **Security Scans** | SonarQube, Trivy, OWASP |
| **Deployment Target** | AWS EKS (Kubernetes) |
| **Notifications** | Email (Success/Failure/Unstable) |

### Tools Integration

| Tool | Purpose | Stage |
|------|---------|-------|
| Git/GitHub | Source Control | Checkout |
| Node.js | Build & Test | Install Dependencies, Run Tests |
| SonarQube | Code Quality | SonarQube Analysis |
| OWASP DC | Dependency Vulnerabilities | OWASP Dependency Check |
| Trivy | Container Security | Security Scan, Image Scan |
| Docker | Containerization | Build Docker Images |
| AWS ECR | Container Registry | Push Docker Images |
| kubectl | K8s Deployment | Deploy to Kubernetes |

---

## 🏗️ Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              JENKINS CI/CD PIPELINE FLOW                                    │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐                  │
│  │  Clean  │───▶│  Setup  │───▶│ Checkout│───▶│ Install │───▶│  Test   │                  │
│  │Workspace│    │   ECR   │    │   Git   │    │  Deps   │    │  Jest   │                  │
│  └─────────┘    └─────────┘    └─────────┘    └────┬────┘    └────┬────┘                  │
│                                                     │              │                        │
│                                               ┌─────┴─────┐  ┌─────┴─────┐                 │
│                                               │ Frontend  │  │ Frontend  │                 │
│                                               │ Backend   │  │ Backend   │   (Parallel)   │
│                                               └───────────┘  └───────────┘                 │
│                                                                    │                        │
│                               ┌────────────────────────────────────┘                        │
│                               ▼                                                             │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐                  │
│  │SonarQube│───▶│ Quality │───▶│  OWASP  │───▶│  Trivy  │───▶│  Build  │                  │
│  │Analysis │    │  Gate   │    │  Check  │    │ FS Scan │    │ Docker  │                  │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘    └────┬────┘                  │
│                                                                    │                        │
│                                                              ┌─────┴─────┐                 │
│                                                              │ Frontend  │                 │
│                                                              │ Backend   │   (Parallel)   │
│                                                              └───────────┘                 │
│                                                                    │                        │
│                               ┌────────────────────────────────────┘                        │
│                               ▼                                                             │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐                                  │
│  │  Trivy  │───▶│  Push   │───▶│ Deploy  │───▶│  Email  │                                  │
│  │Image Scan    │   ECR   │    │   K8s   │    │ Notify  │                                  │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘                                  │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Pipeline Stages

### Stage 1: Clean Workspace

```groovy
stage('Clean Workspace') {
    steps {
        cleanWs()
    }
}
```

| Purpose | Remove all files from previous builds |
|---------|--------------------------------------|
| **Plugin** | Workspace Cleanup |
| **When** | Start of every build |

### Stage 2: Setup ECR Registry

```groovy
stage('Setup ECR Registry') {
    steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
            script {
                env.AWS_ACCOUNT_ID = sh(
                    script: 'aws sts get-caller-identity --query Account --output text',
                    returnStdout: true
                ).trim()
                env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                env.FRONTEND_IMAGE = "${env.ECR_REGISTRY}/redbus-frontend"
                env.BACKEND_IMAGE = "${env.ECR_REGISTRY}/redbus-backend"
            }
        }
    }
}
```

| Purpose | Configure ECR registry dynamically |
|---------|-----------------------------------|
| **Credentials** | AWS credentials |
| **Output** | ECR_REGISTRY, FRONTEND_IMAGE, BACKEND_IMAGE |

### Stage 3: Ensure ECR Repositories

```groovy
stage('Ensure ECR Repositories') {
    steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
            sh '''
                aws ecr describe-repositories --repository-names redbus-frontend --region ${AWS_REGION} || \
                aws ecr create-repository --repository-name redbus-frontend --region ${AWS_REGION}
                
                aws ecr describe-repositories --repository-names redbus-backend --region ${AWS_REGION} || \
                aws ecr create-repository --repository-name redbus-backend --region ${AWS_REGION}
            '''
        }
    }
}
```

| Purpose | Create ECR repositories if they don't exist |
|---------|---------------------------------------------|

### Stage 4: Checkout

```groovy
stage('Checkout') {
    steps {
        echo '📥 Checking out source code...'
        checkout scm
    }
}
```

| Purpose | Clone source code from Git repository |
|---------|--------------------------------------|
| **SCM** | Git/GitHub |

### Stage 5: Install Dependencies (Parallel)

```groovy
stage('Install Dependencies') {
    parallel {
        stage('Frontend Dependencies') {
            steps {
                dir('front-end-redbus') {
                    sh 'npm install'
                }
            }
        }
        stage('Backend Dependencies') {
            steps {
                dir('back-end-redbus') {
                    sh 'npm install'
                }
            }
        }
    }
}
```

| Purpose | Install npm packages for both services |
|---------|---------------------------------------|
| **Execution** | Parallel (faster builds) |

### Stage 6: Run Tests (Parallel)

```groovy
stage('Run Tests') {
    parallel {
        stage('Frontend Tests') {
            steps {
                dir('front-end-redbus') {
                    sh 'CI=true npm test -- --passWithNoTests'
                }
            }
        }
        stage('Backend Tests') {
            steps {
                dir('back-end-redbus') {
                    sh 'npm test'
                }
            }
        }
    }
}
```

| Purpose | Execute unit tests |
|---------|-------------------|
| **Framework** | Jest |
| **CI Mode** | Non-interactive |

### Stage 7: SonarQube Analysis

```groovy
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('SonarQube') {
            sh '''
                ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                    -Dsonar.projectName="RedBus DevOps" \
                    -Dsonar.projectVersion=${BUILD_NUMBER} \
                    -Dsonar.sources=front-end-redbus,back-end-redbus \
                    -Dsonar.exclusions=**/node_modules/**,**/build/**,**/dist/**,**/*.test.js \
                    -Dsonar.javascript.lcov.reportPaths=front-end-redbus/coverage/lcov.info,back-end-redbus/coverage/lcov.info
            '''
        }
    }
}
```

| Purpose | Analyze code quality |
|---------|---------------------|
| **Metrics** | Bugs, Vulnerabilities, Code Smells, Coverage |

### Stage 8: SonarQube Quality Gate

```groovy
stage('SonarQube Quality Gate') {
    steps {
        script {
            timeout(time: 5, unit: 'MINUTES') {
                def qg = waitForQualityGate()
                if (qg.status != 'OK') {
                    unstable('SonarQube Quality Gate failed')
                }
            }
        }
    }
}
```

| Purpose | Wait for and check quality gate result |
|---------|---------------------------------------|
| **Timeout** | 5 minutes |
| **On Failure** | Mark build unstable |

### Stage 9: OWASP Dependency Check

```groovy
stage('OWASP Dependency Check') {
    steps {
        script {
            withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                dependencyCheck additionalArguments: """
                    --scan .
                    --format HTML
                    --format JSON
                    --format XML
                    --out dependency-check-report
                    --prettyPrint
                    --disableYarnAudit
                    --nvdApiKey ${NVD_API_KEY}
                """, odcInstallation: 'OWASP-Dependency-Check'
            }
            dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.xml'
        }
    }
}
```

| Purpose | Scan for known CVE vulnerabilities |
|---------|-----------------------------------|
| **Database** | NVD (National Vulnerability Database) |
| **Reports** | HTML, JSON, XML |

### Stage 10: Trivy Filesystem Scan

```groovy
stage('Security Scan - Trivy') {
    steps {
        sh '''
            trivy fs --severity HIGH,CRITICAL --format table -o trivy-fs-report.txt .
            trivy fs --severity HIGH,CRITICAL --exit-code 0 .
        '''
    }
}
```

| Purpose | Scan source code for vulnerabilities |
|---------|-------------------------------------|
| **Severity** | HIGH, CRITICAL |

### Stage 11: Build Docker Images (Parallel)

```groovy
stage('Build Docker Images') {
    parallel {
        stage('Build Frontend Image') {
            steps {
                sh '''
                    docker build -f docker/frontend.Dockerfile -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} .
                    docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${FRONTEND_IMAGE}:latest
                '''
            }
        }
        stage('Build Backend Image') {
            steps {
                sh '''
                    docker build -f docker/backend.Dockerfile -t ${BACKEND_IMAGE}:${BUILD_NUMBER} .
                    docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${BACKEND_IMAGE}:latest
                '''
            }
        }
    }
}
```

| Purpose | Build container images |
|---------|------------------------|
| **Tags** | BUILD_NUMBER and latest |

### Stage 12: Scan Docker Images (Parallel)

```groovy
stage('Scan Docker Images') {
    parallel {
        stage('Scan Frontend Image') {
            steps {
                sh '''
                    trivy image --severity HIGH,CRITICAL --format table -o trivy-frontend-report.txt ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                    trivy image --severity CRITICAL --exit-code 0 ${FRONTEND_IMAGE}:${BUILD_NUMBER} || true
                '''
            }
        }
        stage('Scan Backend Image') {
            steps {
                sh '''
                    trivy image --severity HIGH,CRITICAL --format table -o trivy-backend-report.txt ${BACKEND_IMAGE}:${BUILD_NUMBER}
                    trivy image --severity CRITICAL --exit-code 0 --scanners vuln ${BACKEND_IMAGE}:${BUILD_NUMBER} || true
                '''
            }
        }
    }
}
```

| Purpose | Scan container images for vulnerabilities |
|---------|------------------------------------------|

### Stage 13: Push Docker Images

```groovy
stage('Push Docker Images') {
    steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
            sh '''
                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                docker push ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                docker push ${FRONTEND_IMAGE}:latest
                docker push ${BACKEND_IMAGE}:${BUILD_NUMBER}
                docker push ${BACKEND_IMAGE}:latest
            '''
        }
    }
}
```

| Purpose | Push images to ECR |
|---------|-------------------|

### Stage 14: Deploy to Kubernetes

```groovy
stage('Deploy to Kubernetes') {
    steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
            sh '''
                aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                kubectl get ns redbus || kubectl create ns redbus
                kubectl apply -f infra/kubernetes/ -n redbus
                kubectl set image deployment/frontend-deployment frontend=${FRONTEND_IMAGE}:${BUILD_NUMBER} -n redbus
                kubectl set image deployment/backend-deployment backend=${BACKEND_IMAGE}:${BUILD_NUMBER} -n redbus
                kubectl rollout status deployment/frontend-deployment -n redbus --timeout=600s
                kubectl rollout status deployment/backend-deployment -n redbus --timeout=600s
            '''
        }
    }
}
```

| Purpose | Deploy to EKS cluster |
|---------|----------------------|
| **Timeout** | 600 seconds |

---

## 📄 Complete Jenkinsfile

### Environment Variables

```groovy
pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER_NAME = 'redbus-cluster'
        SONAR_SCANNER_HOME = tool 'SonarQubeScanner'
        SONAR_PROJECT_KEY = 'redbus-devops'
    }

    tools {
        nodejs 'NodeJS-18'
    }
    
    // ... stages ...
}
```

| Variable | Value | Description |
|----------|-------|-------------|
| `AWS_REGION` | us-east-1 | AWS region |
| `EKS_CLUSTER_NAME` | redbus-cluster | EKS cluster name |
| `SONAR_SCANNER_HOME` | tool reference | SonarQube scanner path |
| `SONAR_PROJECT_KEY` | redbus-devops | SonarQube project key |

### Post Actions

```groovy
post {
    always {
        sh 'docker system prune -f || true'
        archiveArtifacts artifacts: '**/dependency-check-report/**', allowEmptyArchive: true
        archiveArtifacts artifacts: '**/trivy-*.txt', allowEmptyArchive: true
        publishHTML(target: [
            allowMissing: true,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: 'dependency-check-report',
            reportFiles: 'dependency-check-report.html',
            reportName: 'OWASP Dependency Check Report'
        ])
    }
    success {
        emailext(
            subject: "✅ SUCCESS: RedBus Pipeline - Build #${BUILD_NUMBER}",
            body: "...",
            mimeType: 'text/html',
            to: '${DEFAULT_RECIPIENTS}'
        )
    }
    failure {
        emailext(
            subject: "❌ FAILED: RedBus Pipeline - Build #${BUILD_NUMBER}",
            body: "...",
            mimeType: 'text/html',
            to: '${DEFAULT_RECIPIENTS}',
            attachLog: true
        )
    }
    unstable {
        emailext(
            subject: "⚠️ UNSTABLE: RedBus Pipeline - Build #${BUILD_NUMBER}",
            body: "...",
            mimeType: 'text/html',
            to: '${DEFAULT_RECIPIENTS}'
        )
    }
}
```

---

## 🔧 Jenkins Installation & Setup

### Step 1: Launch EC2 Instance

- **AMI**: Amazon Linux 2023
- **Instance Type**: t2.medium or larger (Jenkins needs 2GB+ RAM)
- **Security Group**: Allow ports 22 (SSH), 8080 (Jenkins), 9000 (SonarQube)

### Step 2: Install Required Packages

#### 1. Update System and Install Git

```bash
sudo yum update -y
sudo yum install git -y
git --version
```

#### 2. Install Docker

```bash
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
```

#### 3. Install Java (Amazon Corretto 21)

```bash
# Option 1: Amazon Corretto
sudo dnf install java-21-amazon-corretto -y

# Option 2: OpenJDK
sudo yum install fontconfig java-21-openjdk -y

# Verify installation
java --version
```

#### 4. Install Maven

```bash
sudo yum install maven -y
mvn -v
```

#### 5. Install Jenkins

```bash
# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

# Import Jenkins GPG key
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Update and install Jenkins
sudo yum upgrade -y
sudo yum install jenkins -y

# Verify installation
jenkins --version
```

#### 6. Add Jenkins User to Docker Group

```bash
sudo usermod -aG docker jenkins
```

### ▶️ Step 3: Start Jenkins

```bash
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 🌐 Step 4: Access Jenkins Web UI

1. Open your browser and go to:
   ```
   http://<YOUR_EC2_PUBLIC_IP>:8080
   ```

2. Unlock Jenkins using the initial admin password:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

3. Install suggested plugins
4. Create admin user
5. Configure Jenkins URL

### Step 5: Install Required Plugins

Navigate to: `Dashboard > Manage Jenkins > Manage Plugins > Available`

| Plugin | Purpose |
|--------|---------|
| **Pipeline** | Pipeline support |
| **Git** | Git integration |
| **GitHub** | GitHub integration |
| **Docker Pipeline** | Docker build support |
| **NodeJS** | Node.js tool |
| **SonarQube Scanner** | SonarQube integration |
| **OWASP Dependency-Check** | Dependency scanning |
| **Email Extension** | Email notifications |
| **Amazon Web Services SDK** | AWS integration |
| **Kubernetes CLI** | kubectl commands |
| **Workspace Cleanup** | Clean workspace |
| **HTML Publisher** | HTML reports |

### Step 6: Configure Global Tools

Navigate to: `Dashboard > Manage Jenkins > Global Tool Configuration`

#### NodeJS Configuration

```
Name: NodeJS-18
Version: NodeJS 18.x
Global npm packages: (leave empty)
```

#### SonarQube Scanner

```
Name: SonarQubeScanner
Install automatically: ✓
Version: Latest
```

#### OWASP Dependency-Check

```
Name: OWASP-Dependency-Check
Install automatically: ✓
Version: Latest
```

### Step 7: Configure Jenkins System

Navigate to: `Dashboard > Manage Jenkins > Configure System`

#### SonarQube Servers

```
Name: SonarQube
Server URL: http://your-sonarqube:9000
Server authentication token: (select sonar-token credential)
```

#### Extended E-mail Notification

```
SMTP server: smtp.gmail.com
SMTP port: 465
Use SSL: ✓
Credentials: (email credentials)
Default recipients: team@example.com
```

---

## 📂 Git & GitHub Integration

### Git Overview

| Attribute | Details |
|-----------|---------|
| **Purpose** | Distributed version control |
| **Used For** | Source code management |
| **Integration** | Jenkins SCM checkout |

### Git Commands Used in Pipeline

```bash
# Clone repository (handled by checkout scm)
git clone https://github.com/user/repo.git

# Jenkins automatically handles:
# - Checkout specific branch
# - Fetch commit information
# - Provide GIT_BRANCH, GIT_COMMIT variables
```

### GitHub Integration

#### Step 1: Create GitHub Personal Access Token

1. Go to GitHub → Settings → Developer settings
2. Personal access tokens → Tokens (classic)
3. Generate new token with scopes:
   - `repo` (Full control of private repositories)
   - `admin:repo_hook` (Webhooks)

#### Step 2: Add GitHub Credentials in Jenkins

Navigate to: `Dashboard > Manage Jenkins > Manage Credentials`

```
Kind: Username with password
Username: your-github-username
Password: your-personal-access-token
ID: github-credentials
Description: GitHub Access Token
```

#### Step 3: Configure Webhook (Auto-trigger builds)

1. Go to GitHub repository → Settings → Webhooks
2. Add webhook:
   ```
   Payload URL: http://your-jenkins:8080/github-webhook/
   Content type: application/json
   Events: Just the push event
   ```

#### Step 4: Create Pipeline Job

Navigate to: `Dashboard > New Item > Pipeline`

```
Name: redbus-pipeline
Type: Pipeline

Pipeline:
  Definition: Pipeline script from SCM
  SCM: Git
  Repository URL: https://github.com/yourusername/redbus-devops.git
  Credentials: github-credentials
  Branch: */main
  Script Path: Jenkinsfile
```

### Git Best Practices

| Practice | Implementation |
|----------|----------------|
| Branch Protection | Require PR reviews |
| Commit Messages | Conventional commits |
| .gitignore | Exclude node_modules, build |
| Tags | Version releases |

---

## 🔍 SonarQube Setup

### Overview

| Attribute | Details |
|-----------|---------|
| **Purpose** | Code quality & security analysis |
| **Metrics** | Bugs, Vulnerabilities, Code Smells, Coverage, Duplications |
| **Integration** | Jenkins SonarQube Scanner plugin |
| **Port** | 9000 |

---

### Option 1: Install SonarQube on EC2 (Production)

#### 1️⃣ Update System Packages

```bash
sudo yum update -y
sudo dnf update -y
sudo yum install unzip -y
```

#### 2️⃣ Install Java 17 (Amazon Corretto)

```bash
sudo yum search java-17
sudo yum install java-17-amazon-corretto.x86_64 -y
java --version
```

#### 3️⃣ Install PostgreSQL 15

```bash
sudo dnf install postgresql15.x86_64 postgresql15-server -y
sudo postgresql-setup --initdb

sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### 4️⃣ Configure PostgreSQL User & Database

```bash
sudo passwd postgres
# Set password: Admin@123 (retype)
```

Login as postgres:

```bash
sudo -i -u postgres psql
```

Run SQL commands:

```sql
ALTER USER postgres WITH PASSWORD 'Admin@1234';
CREATE DATABASE sonarqube;
CREATE USER sonar WITH ENCRYPTED PASSWORD 'Sonar@123';
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;
\q
```

#### 5️⃣ Download & Setup SonarQube

```bash
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.6.0.92116.zip
sudo unzip sonarqube-10.6.0.92116.zip
sudo mv sonarqube-10.6.0.92116 sonarqube
```

#### 6️⃣ Set Kernel & OS Limits

```bash
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

Add limits:

```bash
sudo tee -a /etc/security/limits.conf <<EOF
sonar   -   nofile   65536
sonar   -   nproc    4096
EOF
```

#### 7️⃣ Configure SonarQube Database Settings

Edit config:

```bash
sudo nano /opt/sonarqube/conf/sonar.properties
```

Add these lines:

```properties
sonar.jdbc.username=sonar
sonar.jdbc.password=Sonar@123
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube
```

#### 8️⃣ Create SonarQube User

```bash
sudo useradd sonar
sudo chown -R sonar:sonar /opt/sonarqube
```

#### 9️⃣ Create Systemd Service File

```bash
sudo nano /etc/systemd/system/sonarqube.service
```

Paste:

```ini
[Unit]
Description=SonarQube LTS Service
After=network.target

[Service]
Type=forking
User=sonar
Group=sonar
LimitNOFILE=65536
LimitNPROC=4096

Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto.x86_64"
Environment="PATH=/usr/lib/jvm/java-17-amazon-corretto.x86_64/bin:/usr/local/bin:/usr/bin:/bin"

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

Restart=always

[Install]
WantedBy=multi-user.target
```

#### 🔟 Set Permissions

```bash
sudo chmod +x /opt/sonarqube/bin/linux-x86-64/sonar.sh
sudo chmod -R 755 /opt/sonarqube/bin/
sudo chown -R sonar:sonar /opt/sonarqube
```

#### 1️⃣1️⃣ Start SonarQube Service

```bash
sudo systemctl reset-failed sonarqube
sudo systemctl daemon-reload
sudo systemctl start sonarqube
sudo systemctl enable sonarqube
sudo systemctl status sonarqube -l
```

#### 💻 Access SonarQube

Open in browser:

```
http://<EC2-PUBLIC-IP>:9000
```

**Default credentials:** `admin` / `admin`

---

### Option 2: Install SonarQube (Docker - Quick Setup)

```bash
# Run SonarQube container
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  sonarqube:lts-community

# Access at http://your-server:9000
# Default credentials: admin/admin
```

---

### Configure SonarQube Project

1. Login to SonarQube (http://your-server:9000)
2. Change default password
3. Create new project:
   ```
   Project Key: redbus-devops
   Display Name: RedBus DevOps
   ```

### Generate Token

1. Go to: My Account → Security
2. Generate Token:
   ```
   Name: jenkins-token
   Type: Project Analysis Token
   Project: redbus-devops
   ```
3. Copy the token

### Add Token to Jenkins

Navigate to: `Dashboard > Manage Jenkins > Manage Credentials`

```
Kind: Secret text
Secret: your-sonarqube-token
ID: sonar-token
Description: SonarQube Token
```

### Configure SonarQube in Jenkins

Navigate to: `Dashboard > Manage Jenkins > Configure System > SonarQube servers`

```
Name: SonarQube
Server URL: http://your-sonarqube:9000
Server authentication token: sonar-token
```

### SonarQube Scanner Properties

```properties
# sonar-project.properties (optional file in project root)
sonar.projectKey=redbus-devops
sonar.projectName=RedBus DevOps
sonar.sources=front-end-redbus,back-end-redbus
sonar.exclusions=**/node_modules/**,**/build/**,**/dist/**,**/*.test.js
sonar.javascript.lcov.reportPaths=front-end-redbus/coverage/lcov.info,back-end-redbus/coverage/lcov.info
sonar.sourceEncoding=UTF-8
```

### Quality Gate Configuration

Default Quality Gate conditions:

| Metric | Condition | Value |
|--------|-----------|-------|
| Coverage | Less than | 80% |
| Duplicated Lines | Greater than | 3% |
| Maintainability Rating | Worse than | A |
| Reliability Rating | Worse than | A |
| Security Rating | Worse than | A |

### SonarQube Metrics

| Metric | Description | Icon |
|--------|-------------|------|
| Bugs | Reliability issues | 🐛 |
| Vulnerabilities | Security issues | 🔓 |
| Code Smells | Maintainability issues | 🦨 |
| Coverage | Test coverage % | 📊 |
| Duplications | Duplicated code % | 📋 |

---

## 🔒 Trivy Security Scanner

### Overview

| Attribute | Details |
|-----------|---------|
| **Purpose** | Vulnerability scanner for containers & filesystems |
| **Scan Types** | Filesystem, Container Image, IaC |
| **Database** | Trivy DB (auto-updated) |

### Step 1: Install Trivy

```bash
#!/bin/bash
# Location: scripts/monitoring/trivy.sh

# Update system packages
sudo yum update -y

# Install dependencies
sudo yum install -y wget

# Create Trivy repository file
cat <<EOF | sudo tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
gpgcheck=0
enabled=1
EOF

# Install Trivy
sudo yum install trivy -y

# Verify installation
trivy --version
```

### Alternative Installation Methods

```bash
# Ubuntu/Debian
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# macOS
brew install aquasecurity/trivy/trivy

# Docker
docker run aquasec/trivy image your-image:tag
```

### Trivy Scan Types

#### 1. Filesystem Scan (Source Code)

```bash
# Basic scan
trivy fs .

# With severity filter
trivy fs --severity HIGH,CRITICAL .

# Output to file
trivy fs --format table -o trivy-fs-report.txt .

# Exit with error on vulnerabilities
trivy fs --severity CRITICAL --exit-code 1 .

# JSON output
trivy fs --format json -o trivy-fs-report.json .
```

#### 2. Container Image Scan

```bash
# Scan local image
trivy image redbus-backend:latest

# Scan with severity filter
trivy image --severity HIGH,CRITICAL redbus-frontend:latest

# Scan remote image
trivy image nginx:alpine

# Output formats
trivy image --format table -o report.txt image:tag
trivy image --format json -o report.json image:tag
trivy image --format sarif -o report.sarif image:tag
```

#### 3. IaC Scan (Terraform, Kubernetes)

```bash
# Scan Terraform files
trivy config ./infra/terraform/

# Scan Kubernetes manifests
trivy config ./infra/kubernetes/

# With specific policies
trivy config --severity HIGH,CRITICAL ./infra/
```

### Trivy in Jenkins Pipeline

```groovy
// Filesystem scan
stage('Security Scan - Trivy') {
    steps {
        sh '''
            trivy fs --severity HIGH,CRITICAL --format table -o trivy-fs-report.txt .
            trivy fs --severity HIGH,CRITICAL --exit-code 0 .
        '''
    }
}

// Image scan
stage('Scan Docker Images') {
    steps {
        sh '''
            trivy image --severity HIGH,CRITICAL --format table -o trivy-image-report.txt ${IMAGE}:${TAG}
            trivy image --severity CRITICAL --exit-code 0 ${IMAGE}:${TAG} || true
        '''
    }
}
```

### Trivy Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| CRITICAL | Severe vulnerabilities | Block deployment |
| HIGH | Significant vulnerabilities | Review before deploy |
| MEDIUM | Moderate vulnerabilities | Schedule fix |
| LOW | Minor vulnerabilities | Track for reference |
| UNKNOWN | Unknown severity | Investigate |

### Trivy Report Example

```
redbus-backend:latest (alpine 3.18.4)
=====================================
Total: 5 (HIGH: 3, CRITICAL: 2)

┌──────────────────┬──────────────────┬──────────┬──────────────────────────────────────────────┐
│     Library      │  Vulnerability   │ Severity │                    Title                     │
├──────────────────┼──────────────────┼──────────┼──────────────────────────────────────────────┤
│ libcrypto3       │ CVE-2023-XXXX    │ CRITICAL │ OpenSSL: Buffer overflow vulnerability       │
│ libssl3          │ CVE-2023-YYYY    │ CRITICAL │ OpenSSL: Memory corruption                   │
│ curl             │ CVE-2023-ZZZZ    │ HIGH     │ curl: HTTP/2 memory leak                     │
└──────────────────┴──────────────────┴──────────┴──────────────────────────────────────────────┘
```

---

## 🛡️ OWASP Dependency Check

### Overview

| Attribute | Details |
|-----------|---------|
| **Purpose** | Identify known CVE vulnerabilities in dependencies |
| **Database** | NVD (National Vulnerability Database) |
| **Languages** | Java, .NET, JavaScript, Python, Ruby, etc. |
| **Integration** | Jenkins plugin |

### Step 1: Install OWASP Dependency-Check Plugin

Navigate to: `Dashboard > Manage Jenkins > Manage Plugins`

Search and install: `OWASP Dependency-Check`

### Step 2: Configure OWASP DC Tool

Navigate to: `Dashboard > Manage Jenkins > Global Tool Configuration`

```
OWASP Dependency-Check:
  Name: OWASP-Dependency-Check
  Install automatically: ✓
  Version: dependency-check 8.x (latest)
```

### Step 3: Get NVD API Key

1. Go to: https://nvd.nist.gov/developers/request-an-api-key
2. Register and get API key
3. Add to Jenkins credentials:
   ```
   Kind: Secret text
   Secret: your-nvd-api-key
   ID: nvd-api-key
   Description: NVD API Key for OWASP DC
   ```

### Step 4: Use in Pipeline

```groovy
stage('OWASP Dependency Check') {
    steps {
        script {
            // Create output directory
            sh 'mkdir -p dependency-check-report'
            
            withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                dependencyCheck additionalArguments: """
                    --scan .
                    --format HTML
                    --format JSON
                    --format XML
                    --out dependency-check-report
                    --prettyPrint
                    --disableYarnAudit
                    --nvdApiKey ${NVD_API_KEY}
                """, odcInstallation: 'OWASP-Dependency-Check'
            }
            
            // Publish report
            dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.xml'
        }
    }
}
```

### OWASP DC Command Line Options

| Option | Description |
|--------|-------------|
| `--scan` | Path to scan |
| `--format` | Output format (HTML, JSON, XML, CSV) |
| `--out` | Output directory |
| `--nvdApiKey` | NVD API key for faster updates |
| `--failOnCVSS` | Fail if CVSS score >= threshold |
| `--suppression` | Suppression file path |
| `--disableYarnAudit` | Disable yarn audit analyzer |
| `--enableExperimental` | Enable experimental analyzers |

### Report Analysis

| CVSS Score | Severity | Color |
|------------|----------|-------|
| 0.0 | None | - |
| 0.1 - 3.9 | Low | Green |
| 4.0 - 6.9 | Medium | Yellow |
| 7.0 - 8.9 | High | Orange |
| 9.0 - 10.0 | Critical | Red |

### Suppression File Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
    <suppress>
        <notes>This is a false positive</notes>
        <packageUrl regex="true">^pkg:npm/example-package@.*$</packageUrl>
        <cve>CVE-2023-XXXXX</cve>
    </suppress>
</suppressions>
```

---

## 🔐 Credentials Configuration

### Required Credentials

| Credential ID | Type | Purpose |
|--------------|------|---------|
| `aws-credentials` | AWS Credentials | ECR, EKS access |
| `github-credentials` | Username/Password | GitHub repo access |
| `sonar-token` | Secret text | SonarQube authentication |
| `nvd-api-key` | Secret text | OWASP DC NVD API |
| `docker-credentials` | Username/Password | Docker Hub (optional) |

### Adding AWS Credentials

Navigate to: `Dashboard > Manage Jenkins > Manage Credentials > (global) > Add Credentials`

```
Kind: AWS Credentials
Access Key ID: AKIAXXXXXXXXXX
Secret Access Key: xxxxxxxxxxxxxxxx
ID: aws-credentials
Description: AWS Credentials for ECR/EKS
```

### Adding GitHub Credentials

```
Kind: Username with password
Username: your-github-username
Password: github-personal-access-token
ID: github-credentials
Description: GitHub Access Token
```

### Adding Secret Text

```
Kind: Secret text
Secret: your-secret-value
ID: sonar-token
Description: SonarQube Token
```

---

## 📧 Email Notifications

### Configure SMTP Settings

Navigate to: `Dashboard > Manage Jenkins > Configure System`

#### Extended E-mail Notification

```
SMTP server: smtp.gmail.com
SMTP port: 465
Use SSL: ✓
SMTP Authentication: ✓
User Name: your-email@gmail.com
Password: app-password
Default Content Type: text/html
Default Recipients: team@example.com
```

### Gmail App Password Setup

1. Enable 2-Factor Authentication in Google Account
2. Go to: Google Account → Security → App passwords
3. Generate app password for "Mail"
4. Use this password in Jenkins

### Email Templates in Pipeline

```groovy
// Success Email
emailext(
    subject: "✅ SUCCESS: ${JOB_NAME} - Build #${BUILD_NUMBER}",
    body: '''
        <html>
        <body>
            <h2 style="color: #28a745;">🎉 Pipeline Successful!</h2>
            <p><strong>Project:</strong> ${JOB_NAME}</p>
            <p><strong>Build Number:</strong> ${BUILD_NUMBER}</p>
            <p><strong>Build URL:</strong> <a href="${BUILD_URL}">${BUILD_URL}</a></p>
            <hr>
            <p>All stages completed successfully.</p>
        </body>
        </html>
    ''',
    mimeType: 'text/html',
    to: '${DEFAULT_RECIPIENTS}'
)

// Failure Email
emailext(
    subject: "❌ FAILED: ${JOB_NAME} - Build #${BUILD_NUMBER}",
    body: '''
        <html>
        <body>
            <h2 style="color: #dc3545;">⚠️ Pipeline Failed!</h2>
            <p><strong>Build URL:</strong> <a href="${BUILD_URL}console">${BUILD_URL}console</a></p>
            <p>Please check the attached log for details.</p>
        </body>
        </html>
    ''',
    mimeType: 'text/html',
    to: '${DEFAULT_RECIPIENTS}',
    attachLog: true,
    compressLog: true
)
```

---

## 🚀 Pipeline Execution

### Method 1: Manual Trigger

1. Go to Jenkins Dashboard
2. Select `redbus-pipeline`
3. Click `Build Now`
4. Monitor in `Build History`

### Method 2: GitHub Webhook (Auto-trigger)

1. Push code to GitHub
2. Webhook triggers Jenkins
3. Pipeline starts automatically

### Method 3: Scheduled Build

```groovy
// Add triggers block to Jenkinsfile
pipeline {
    triggers {
        // Poll SCM every 5 minutes
        pollSCM('H/5 * * * *')
        
        // Or cron schedule
        cron('H 2 * * *')  // Daily at 2 AM
    }
    // ...
}
```

### Viewing Build Results

1. **Console Output**: Full build log
2. **Stage View**: Visual stage progress
3. **Blue Ocean**: Modern UI (if plugin installed)
4. **Test Results**: Test reports
5. **Artifacts**: Security reports, build files

### Build Status Indicators

| Status | Color | Meaning |
|--------|-------|---------|
| Success | 🟢 Blue | All stages passed |
| Unstable | 🟡 Yellow | Tests failed or quality gate issues |
| Failure | 🔴 Red | Pipeline failed |
| Aborted | ⚪ Gray | Build cancelled |

---

## 🔧 Troubleshooting

### Common Issues

#### 1. SonarQube Connection Failed

```
Error: Unable to connect to SonarQube server

Solutions:
- Verify SonarQube URL in Jenkins config
- Check SonarQube is running
- Verify authentication token
- Check firewall/security groups
```

#### 2. OWASP DC NVD Update Failed

```
Error: Unable to download NVD data

Solutions:
- Add NVD API key (free registration)
- Check internet connectivity
- Increase timeout settings
- Use local NVD mirror
```

#### 3. Docker Permission Denied

```
Error: permission denied while trying to connect to Docker daemon

Solutions:
- Add jenkins user to docker group:
  sudo usermod -aG docker jenkins
- Restart Jenkins service
- Verify docker socket permissions
```

#### 4. AWS Credentials Invalid

```
Error: Unable to locate credentials

Solutions:
- Verify AWS credentials in Jenkins
- Check IAM user permissions
- Ensure credentials are not expired
```

#### 5. Trivy Scan Timeout

```
Error: Trivy scan timed out

Solutions:
- Pre-download Trivy DB
- Increase timeout in pipeline
- Use cache directory
```

```bash
# Pre-download Trivy DB
trivy image --download-db-only
```

#### 6. Kubernetes Deployment Failed

```
Error: Unable to connect to EKS cluster

Solutions:
- Verify EKS cluster exists
- Check kubeconfig update command
- Verify AWS credentials have EKS access
- Check security groups allow connection
```

### Debug Commands

```bash
# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Check Docker status
sudo systemctl status docker

# Verify AWS credentials
aws sts get-caller-identity

# Check kubectl config
kubectl config current-context

# Test SonarQube connection
curl -u admin:password http://sonarqube:9000/api/system/status
```

---

## 📊 Quick Reference

### Pipeline Environment Variables

| Variable | Description |
|----------|-------------|
| `BUILD_NUMBER` | Current build number |
| `BUILD_URL` | URL to build |
| `JOB_NAME` | Name of the job |
| `WORKSPACE` | Workspace directory |
| `GIT_BRANCH` | Git branch name |
| `GIT_COMMIT` | Git commit SHA |

### Useful Jenkins Pipeline Syntax

```groovy
// Parallel execution
parallel {
    stage('A') { steps { ... } }
    stage('B') { steps { ... } }
}

// Conditional execution
when {
    branch 'main'
}

// Timeout
timeout(time: 10, unit: 'MINUTES') {
    // steps
}

// Retry
retry(3) {
    // steps
}

// Input approval
input message: 'Deploy to production?'

// Archive artifacts
archiveArtifacts artifacts: '**/*.jar'

// Credentials
withCredentials([string(credentialsId: 'id', variable: 'VAR')]) {
    sh 'echo $VAR'
}
```

---

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/)
- [GitHub Actions Migration Guide](https://docs.github.com/en/actions)

---

<p align="center">
  <b>🔄 Jenkins CI/CD Pipeline for RedBus DevOps Project</b>
</p>
