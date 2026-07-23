# RedBus DevOps Kubernetes Project — Interview Q&A Guide

## 📋 How to Explain This Project in an Interview

### 30-Second Elevator Pitch
> "I built and deployed a full-stack bus booking application called RedBus using a complete DevOps pipeline. The frontend is React, the backend is Node.js with Express and MongoDB, and I containerized both using Docker with multi-stage builds. I provisioned the entire AWS infrastructure — VPC, EKS cluster, and ECR repositories — using Terraform as Infrastructure as Code. The CI/CD pipeline is automated through Jenkins with 12+ stages including code quality analysis via SonarQube, security scanning with Trivy and OWASP Dependency Check, Docker image building and pushing to ECR, and automated Kubernetes deployment. For observability, I set up Prometheus and Grafana with custom dashboards to monitor both cluster health and application metrics."

### 2-Minute Detailed Explanation
> "Let me walk you through the architecture:
>
> **Application Layer:** The frontend is a React 17 SPA with Redux for state management, Material-UI components, Google OAuth for authentication, and Stripe for payment processing. The backend is a Node.js 18 Express API connected to MongoDB Atlas, handling bus routes, bookings, bus hire services, customer management, and Stripe payment integration.
>
> **Containerization:** I wrote optimized Dockerfiles — the frontend uses a multi-stage build with Node.js for building and Nginx Alpine for serving, reducing the image from ~500MB to ~25MB. The backend runs as a non-root user with health checks. Nginx handles gzip compression, security headers, SPA routing via `try_files`, and reverse proxies API calls to the backend Kubernetes service.
>
> **Infrastructure as Code:** Using Terraform with AWS modules, I provision a VPC with 3 availability zones (public + private subnets), a NAT Gateway, an EKS cluster running Kubernetes 1.29 with managed node groups (t3.medium, auto-scaling 1-5 nodes), and ECR repositories with lifecycle policies. The Terraform state is stored remotely in S3 with DynamoDB locking.
>
> **CI/CD Pipeline:** Jenkins declarative pipeline with 12+ stages: workspace cleanup, ECR setup, checkout, parallel dependency installation, parallel testing, SonarQube analysis with quality gate, OWASP dependency check, Trivy filesystem scan, parallel Docker builds, parallel Docker image scans, ECR push, and Kubernetes rolling deployment. Post-build actions include Docker cleanup, artifact archiving, and email notifications.
>
> **Kubernetes:** Deployments with 2 replicas each, resource requests/limits, liveness and readiness probes, ConfigMaps for environment variables, Secrets for sensitive data, ClusterIP services, and an Nginx Ingress with TLS termination via cert-manager.
>
> **Monitoring:** Custom Prometheus setup with scrape configs for Node Exporter, kube-state-metrics, cAdvisor, kubelet, API server, and application-level metrics. Grafana with pre-configured Prometheus datasource and custom dashboards for application monitoring."

### Key Points to Emphasize
1. **End-to-End Ownership** — You handled everything from application code to production deployment
2. **Security-First Approach** — Trivy image/filesystem scans, OWASP dependency checks, SonarQube, non-root Docker users, Kubernetes Secrets
3. **Production-Ready Practices** — Health checks, resource limits, rolling deployments, auto-scaling, multi-AZ, remote state management
4. **Automation** — Everything is automated; infrastructure, CI/CD, deployment, monitoring setup
5. **Observability** — Full monitoring stack with Prometheus + Grafana + Node Exporter + kube-state-metrics

---

## 40 Interview Questions & Answers

---

### SECTION 1: PROJECT OVERVIEW (Q1–Q5)

---

**Q1. Can you give a high-level overview of your RedBus DevOps project?**

**Answer:**
This is a full-stack bus booking platform built with React (frontend) and Node.js/Express (backend) connected to MongoDB Atlas. I containerized both services with Docker, provisioned AWS infrastructure (VPC, EKS, ECR) using Terraform, automated the entire CI/CD pipeline using Jenkins with 12+ stages including security scanning, and deployed to a Kubernetes cluster on AWS EKS. For observability, I implemented a monitoring stack using Prometheus and Grafana with custom dashboards. The project demonstrates a complete DevOps lifecycle — from code commit to production deployment with security, quality gates, and monitoring built in.

---

**Q2. What is the tech stack of your project?**

**Answer:**
| Layer | Technology |
|-------|-----------|
| **Frontend** | React 17, Redux, Material-UI, Axios, React Router v5, react-google-login, react-stripe-checkout |
| **Backend** | Node.js 18, Express 4.x, Mongoose (MongoDB ODM), Stripe SDK |
| **Database** | MongoDB Atlas (cloud-hosted) |
| **Containerization** | Docker (multi-stage builds), Nginx Alpine |
| **Orchestration** | Kubernetes 1.29 on AWS EKS |
| **IaC** | Terraform with AWS modules (VPC, EKS, ECR) |
| **CI/CD** | Jenkins (Declarative Pipeline) |
| **Code Quality** | SonarQube |
| **Security** | Trivy (image + filesystem scan), OWASP Dependency Check |
| **Monitoring** | Prometheus v2.48.0, Grafana v10.2.0, Node Exporter v1.7.0, kube-state-metrics v2.10.1 |
| **Cloud** | AWS (VPC, EKS, ECR, S3, IAM, NAT Gateway) |

---

**Q3. What are the main API endpoints your backend exposes?**

**Answer:**
The backend exposes these RESTful API routes:
- `GET /health` — Health check endpoint used by Kubernetes liveness/readiness probes
- `/v1/api/bus` — CRUD operations for buses
- `/v1/api/booking` — Bus booking management
- `/v1/api/customer` — Customer management
- `/v1/api/route` — Bus route management
- `/v1/api/bookinghire` — Bus hire booking management
- `/v1/api/busservice` — Bus service listings
- `POST /v1/api/stripe-payments` — Stripe payment processing (creates customer + charge in INR)

All routes are prefixed with `/v1/api/` following REST versioning best practices. The health endpoint is at the root level so Kubernetes probes can check it without authentication.

---

**Q4. How does the frontend communicate with the backend in your architecture?**

**Answer:**
In the Kubernetes environment, the frontend is served by Nginx. The `nginx.conf` has a `location /api` block that reverse-proxies requests to the backend Kubernetes ClusterIP service:
```nginx
location /api {
    proxy_pass http://backend-service:5000;
}
```
This means all frontend API calls to `/api/*` are forwarded to the backend service on port 5000 via Kubernetes internal DNS resolution (`backend-service` resolves to the ClusterIP). The frontend itself is a React SPA served as static files, with `try_files $uri $uri/ /index.html` handling client-side routing. This architecture keeps the backend unexposed to the public internet — only the Nginx frontend service is externally accessible through the Ingress.

---

**Q5. What problems does this project solve, and why did you choose this architecture?**

**Answer:**
**Problems Solved:**
- **Manual deployment pain** — Jenkins automates the entire build-test-scan-deploy cycle
- **Environment inconsistency** — Docker ensures the same environment from dev to production
- **Infrastructure drift** — Terraform provides declarative, version-controlled infrastructure
- **Scalability** — Kubernetes auto-scales pods and nodes based on demand
- **Security vulnerabilities** — Trivy and OWASP catch CVEs before deployment
- **Observability gaps** — Prometheus + Grafana provide real-time metrics and alerting

**Why this architecture:**
- **Microservices with Docker** — Independent scaling and deployment of frontend/backend
- **EKS over self-managed K8s** — AWS manages the control plane, reducing operational overhead
- **Terraform over CloudFormation** — Cloud-agnostic, better module ecosystem, state management
- **Jenkins over GitHub Actions** — More control, plugin ecosystem, runs on our own infrastructure
- **Prometheus over CloudWatch** — Open-source, powerful PromQL, Kubernetes-native service discovery

---

### SECTION 2: DOCKER & CONTAINERIZATION (Q6–Q12)

---

**Q6. Explain the multi-stage Docker build you used for the frontend.**

**Answer:**
The frontend Dockerfile uses a two-stage build:

**Stage 1 (Builder):** Uses `node:18-alpine` as the base. It copies `package*.json`, runs `npm install --legacy-peer-deps`, copies the source code, and runs `npm run build` to create an optimized production build in the `/app/build` directory.

**Stage 2 (Production):** Uses `nginx:alpine` as the base. It copies the custom `nginx.conf` and the build artifacts from Stage 1 (`COPY --from=builder /app/build /usr/share/nginx/html`). It exposes port 80 and includes a health check.

**Why multi-stage?** The Node.js build environment (~500MB+) is discarded entirely. The final image only contains Nginx and the static HTML/JS/CSS files, resulting in an image of approximately 25MB. This reduces attack surface, speeds up image pulls, saves ECR storage, and improves deployment times.

---

**Q7. What security best practices did you implement in your Dockerfiles?**

**Answer:**
1. **Non-root user** — The backend Dockerfile creates a dedicated user (`nodeuser:1001`) and switches to it with `USER nodeuser`, preventing container breakout privilege escalation
2. **Alpine base images** — Minimal images with smaller attack surface (fewer packages = fewer CVEs)
3. **Security patches** — `apk update && apk upgrade --no-cache libcrypto3 libssl3` patches OpenSSL vulnerabilities
4. **Production-only dependencies** — `npm ci --only=production` excludes devDependencies, reducing attack surface
5. **npm cache cleanup** — `npm cache clean --force` removes cached packages from the image
6. **Health checks** — `HEALTHCHECK` instructions let Docker and Kubernetes detect unhealthy containers
7. **Multi-stage builds** — Frontend discards the entire build environment, eliminating build tools from production
8. **Specific base image tags** — Using `node:18-alpine` instead of `node:latest` prevents unexpected breaking changes

---

**Q8. Explain your Nginx configuration and why each directive matters.**

**Answer:**
The `nginx.conf` serves multiple purposes:

1. **SPA Routing** — `try_files $uri $uri/ /index.html` ensures React Router works. When a user navigates to `/select-bus`, Nginx doesn't return a 404; it serves `index.html` and lets React handle the route client-side.

2. **API Reverse Proxy** — `location /api { proxy_pass http://backend-service:5000; }` forwards API requests to the Kubernetes backend service. This eliminates CORS issues since the browser sees everything from the same origin.

3. **Gzip Compression** — `gzip on; gzip_types text/plain text/css application/json application/javascript...` compresses responses, reducing bandwidth by 60-80% for text-based assets.

4. **Security Headers:**
   - `X-Frame-Options: SAMEORIGIN` — Prevents clickjacking by disallowing iframe embedding from other domains
   - `X-Content-Type-Options: nosniff` — Prevents MIME-type sniffing attacks
   - `X-XSS-Protection: 1; mode=block` — Enables browser XSS filtering

5. **Static Asset Caching** — `expires 1y` for JS, CSS, PNG, etc. — Sets `Cache-Control: max-age=31536000`. Since React build generates hashed filenames, cache busting happens automatically on new deployments.

6. **Health Endpoint** — `location /health { return 200 "healthy\n"; }` provides a lightweight health check endpoint for Kubernetes probes without hitting the application.

---

**Q9. What is the difference between `npm install` and `npm ci`? Why did you use `npm ci` in the backend Dockerfile?**

**Answer:**
- `npm install` reads `package.json`, resolves dependency versions, may update `package-lock.json`, and installs packages. It's flexible but non-deterministic.
- `npm ci` reads `package-lock.json` exclusively, deletes `node_modules` first, installs exact versions from the lockfile, and fails if `package-lock.json` is out of sync with `package.json`.

I used `npm ci --only=production` in the backend Dockerfile because:
1. **Deterministic builds** — Every build installs the exact same dependency versions
2. **Faster** — Skips dependency resolution, installs directly from lockfile
3. **CI/CD friendly** — Fails loudly if lockfile is inconsistent, catching issues early
4. **Production-only** — `--only=production` skips devDependencies, reducing image size and attack surface

For the frontend, I used `npm install --legacy-peer-deps` because React 17 has peer dependency conflicts with some packages, and the build stage is discarded anyway.

---

**Q10. How does the Docker health check work in your containers?**

**Answer:**
Both Dockerfiles include:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1
```

- **`--interval=30s`** — Check every 30 seconds
- **`--timeout=3s`** — Each check must complete within 3 seconds
- **`--start-period=5s`** — Grace period for container startup before checks count as failures
- **`--retries=3`** — Container is marked unhealthy after 3 consecutive failures

The `wget --spider` command makes a HEAD request to the health endpoint without downloading the body. If it returns a non-200 status or times out, `exit 1` signals unhealthy.

Docker uses this for `docker ps` status reporting. In Kubernetes, the HEALTHCHECK is informational — Kubernetes uses its own `livenessProbe` and `readinessProbe` defined in the deployment manifests, which check the same `/health` endpoint.

---

**Q11. Why did you use `node:18-alpine` instead of `node:18` as the base image?**

**Answer:**
| Aspect | `node:18` (Debian) | `node:18-alpine` |
|--------|-------------------|------------------|
| **Image size** | ~900MB | ~130MB |
| **Package manager** | apt | apk |
| **C library** | glibc | musl |
| **Packages included** | Many (git, curl, etc.) | Minimal |
| **Attack surface** | Larger | Smaller |

I chose Alpine because:
1. **Smaller images** — Faster pulls, less ECR storage, quicker deployments
2. **Fewer CVEs** — Less pre-installed software means fewer potential vulnerabilities
3. **Sufficient for Node.js** — Our app doesn't need native compilation tools (no `node-gyp` dependencies)

**Caveat:** Alpine uses musl libc instead of glibc, which can cause issues with some native Node.js modules. For this project, all dependencies are pure JavaScript or have pre-built musl binaries, so Alpine works perfectly.

---

**Q12. How would you reduce the Docker image size further if needed?**

**Answer:**
1. **Use `.dockerignore`** — Exclude `node_modules`, `.git`, test files, docs from the build context
2. **Distroless base images** — Use `gcr.io/distroless/nodejs18-debian12` which has no shell, no package manager — even smaller attack surface
3. **Strip unnecessary files** — `RUN rm -rf /app/test /app/docs /app/*.md` after copying
4. **Use `--production` flag** more aggressively and run `npm prune --production`
5. **Enable BuildKit** — `DOCKER_BUILDKIT=1` enables better layer caching and parallel builds
6. **Compress layers** — Use `--squash` flag to merge layers (experimental)
7. **For frontend** — Already optimized via multi-stage (~25MB). Could further optimize by using `nginx:alpine-slim`

---

### SECTION 3: KUBERNETES (Q13–Q20)

---

**Q13. Explain the Kubernetes architecture of your project.**

**Answer:**
The project runs on AWS EKS with these Kubernetes resources:

**Namespaces:** `redbus` (application) and `monitoring` (observability stack)

**Application namespace (`redbus`):**
- 2 **Deployments** — `redbus-frontend` (2 replicas, port 80) and `redbus-backend` (2 replicas, port 5000)
- 2 **ClusterIP Services** — `frontend-service` and `backend-service` for internal routing
- 1 **Ingress** — Nginx Ingress Controller routes `/api` → backend, `/` → frontend with TLS
- 1 **ConfigMap** (`redbus-config`) — `NODE_ENV`, `PORT`, `REACT_APP_BACKEND_URL`
- 1 **Secret** (`redbus-secrets`) — `mongodb-uri`, `stripe-secret-key`

**Monitoring namespace (`monitoring`):**
- Prometheus Deployment + NodePort Service (30090)
- Grafana Deployment + NodePort Service (30030)
- Node Exporter DaemonSet (runs on every node)
- kube-state-metrics Deployment
- RBAC (ServiceAccounts, ClusterRoles, ClusterRoleBindings)
- ConfigMaps for Prometheus scrape configs and Grafana datasources

---

**Q14. What is the difference between `livenessProbe` and `readinessProbe`? How did you configure them?**

**Answer:**
- **`livenessProbe`** — Checks if the container is alive. If it fails, Kubernetes **restarts** the container. Used to recover from deadlocks or hung processes.
- **`readinessProbe`** — Checks if the container is ready to accept traffic. If it fails, Kubernetes **removes the pod from the Service endpoints** (stops sending traffic) but does NOT restart it. Used during startup or temporary unavailability.

My configuration for the backend:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 5
  periodSeconds: 5
```

**Key design decisions:**
- Readiness probe starts earlier (5s) because we want to start routing traffic as soon as the app is ready
- Liveness probe has a longer initial delay (30s) to give the app time to start and connect to MongoDB before checking health
- Readiness checks more frequently (5s) for faster traffic management; liveness checks less often (10s) to avoid unnecessary restarts

---

**Q15. Why did you choose `ClusterIP` for your services instead of `LoadBalancer` or `NodePort`?**

**Answer:**
- **ClusterIP** — Only accessible within the cluster. This is the correct choice because:
  1. The frontend and backend communicate internally via Kubernetes DNS
  2. External access is handled by the Ingress controller, which is the single entry point
  3. Services don't need individual AWS Load Balancers (which cost ~$20/month each)

- **Why not LoadBalancer?** — Each LoadBalancer service creates an AWS ELB. With 2 services, that's 2 ELBs (~$40/month) plus no path-based routing. The Ingress provides a single entry point with path-based routing.

- **Why not NodePort?** — NodePort exposes services on a static port (30000-32767) on every node. This bypasses the load balancer, requires opening node security groups to the internet, and doesn't support hostname/path-based routing.

- **Exception:** For monitoring, I used NodePort for Prometheus (30090) and Grafana (30030) for direct access during development. In production, these would also go behind an Ingress with authentication.

---

**Q16. Explain how the Ingress routes traffic in your project.**

**Answer:**
The Ingress resource uses the Nginx Ingress Controller and routes traffic based on path:

```yaml
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

**Traffic flow:**
1. User hits `https://redbus.yourdomain.com/api/bus`
2. DNS resolves to the AWS Load Balancer (created by the Ingress Controller)
3. The Load Balancer forwards to the Nginx Ingress Controller pod
4. Ingress matches `/api` prefix → routes to `backend-service:5000`
5. The ClusterIP service load-balances across backend pod replicas

**TLS Configuration:**
- `cert-manager.io/cluster-issuer: letsencrypt-prod` annotation tells cert-manager to automatically obtain and renew a TLS certificate from Let's Encrypt
- `nginx.ingress.kubernetes.io/ssl-redirect: "true"` forces HTTP → HTTPS redirection

---

**Q17. How do ConfigMaps and Secrets work in your project? Why separate them?**

**Answer:**
**ConfigMap (`redbus-config`):**
```yaml
data:
  NODE_ENV: "production"
  PORT: "5000"
  REACT_APP_BACKEND_URL: "http://backend-service:5000"
```
Mounted as environment variables via `envFrom: configMapRef`.

**Secret (`redbus-secrets`):**
```yaml
stringData:
  mongodb-uri: "mongodb+srv://..."
  stripe-secret-key: "sk_live_..."
```
Mounted as individual env vars via `valueFrom: secretKeyRef`.

**Why separate them:**
1. **Access control** — Kubernetes RBAC can restrict who can read Secrets vs ConfigMaps
2. **Encryption** — Secrets can be encrypted at rest (EKS supports AWS KMS encryption). ConfigMaps are stored in plain text in etcd
3. **Auditing** — Secret access can be audited separately
4. **Principle of least privilege** — Developers can access ConfigMaps for debugging without seeing credentials
5. **Rotation** — Secrets can be rotated independently without touching application configs

**Important:** In production, I would use AWS Secrets Manager with the External Secrets Operator instead of native Kubernetes Secrets, since native Secrets are only base64-encoded (not encrypted by default).

---

**Q18. How does Kubernetes handle rolling deployments? What happens when you push a new image?**

**Answer:**
The Jenkins pipeline triggers a rolling update:
```bash
kubectl set image deployment/redbus-frontend redbus-frontend=$FRONTEND_IMAGE:$BUILD_NUMBER -n redbus
kubectl rollout status deployment/redbus-frontend -n redbus --timeout=600s
```

**Rolling update process (with 2 replicas):**
1. Kubernetes creates a new ReplicaSet with the updated image
2. A new pod is scheduled with the new image version
3. Kubernetes waits for the new pod to pass its `readinessProbe`
4. Once ready, Kubernetes terminates one old pod
5. Another new pod is created, becomes ready, another old pod terminates
6. Old ReplicaSet scales to 0 (retained for rollback)

**Default strategy:** `RollingUpdate` with `maxSurge: 25%` (can have 25% extra pods during update) and `maxUnavailable: 25%` (at least 75% of pods must be available).

**Zero-downtime guarantee:** Because the readiness probe ensures new pods only receive traffic when healthy, users never see downtime during deployments.

**Rollback:** If the rollout fails (timeout or crash loop), `kubectl rollout undo deployment/redbus-frontend -n redbus` reverts to the previous ReplicaSet.

---

**Q19. What resource requests and limits did you set, and why?**

**Answer:**
| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|------------|-----------|----------------|-------------|
| Frontend | 100m | 200m | 128Mi | 256Mi |
| Backend | 200m | 500m | 256Mi | 512Mi |
| Prometheus | 250m | 500m | 512Mi | 1Gi |
| Grafana | 100m | 250m | 256Mi | 512Mi |
| Node Exporter | 50m | 100m | 64Mi | 128Mi |
| kube-state-metrics | 50m | 100m | 64Mi | 128Mi |

**Why requests matter:**
- The Kubernetes scheduler uses **requests** to decide which node has enough capacity for a pod
- If a node has 2 CPU cores and existing pods request 1.8 cores, a pod requesting 300m won't be scheduled there

**Why limits matter:**
- **CPU limit** — Pod is throttled (not killed) if it exceeds the limit. This prevents a runaway process from starving others
- **Memory limit** — Pod is **OOM-killed** if it exceeds the limit. This protects node stability

**Design rationale:**
- Backend gets more resources (200m/256Mi) because it handles database queries, Stripe API calls, and JSON serialization
- Frontend gets less (100m/128Mi) because Nginx just serves static files
- Prometheus gets the most memory (1Gi) because it stores time-series data in memory

---

**Q20. How would you scale this application to handle more traffic?**

**Answer:**
**Horizontal Pod Autoscaler (HPA):**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  scaleTargetRef:
    kind: Deployment
    name: redbus-backend
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
This automatically scales backend pods from 2 to 10 when average CPU utilization exceeds 70%.

**Cluster Autoscaler / Karpenter:**
The EKS node group is configured with `min_size=1, max_size=5`. The Cluster Autoscaler adds nodes when pods are pending due to insufficient resources and removes underutilized nodes.

**Other scaling strategies:**
1. **Database** — Move to MongoDB sharded cluster or use DynamoDB for certain tables
2. **Caching** — Add Redis for session storage and frequently accessed routes/bus data
3. **CDN** — CloudFront in front of the frontend for global distribution
4. **Read replicas** — MongoDB replica set for read-heavy operations
5. **Queue-based processing** — SQS for booking confirmations and payment processing

---

### SECTION 4: TERRAFORM & INFRASTRUCTURE (Q21–Q27)

---

**Q21. Explain the AWS infrastructure you provisioned with Terraform.**

**Answer:**
The Terraform code provisions:

1. **VPC** — CIDR `10.0.0.0/16` across 3 Availability Zones (us-east-1a, 1b, 1c) for high availability
   - 3 **Private Subnets** (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24) — EKS worker nodes run here
   - 3 **Public Subnets** (10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24) — NAT Gateway, Load Balancer
   - **NAT Gateway** (single, for dev) — Allows private subnet resources to access the internet
   - **Internet Gateway** — For public subnet internet access

2. **EKS Cluster** (`redbus-cluster`)
   - Kubernetes version 1.29
   - Both public and private API endpoints
   - Managed node group (`redbus-nodes`): t3.medium instances, auto-scaling 1-5, desired 2, ON_DEMAND

3. **ECR Repositories** — `redbus-frontend` and `redbus-backend` with image scan-on-push and lifecycle policy (keep last 10 images)

---

**Q22. Why did you place EKS worker nodes in private subnets?**

**Answer:**
Worker nodes are in private subnets for security:

1. **No direct internet access** — Nodes don't have public IPs. Attackers can't reach them directly
2. **Outbound via NAT Gateway** — Nodes can still pull Docker images, call AWS APIs, and access the internet through the NAT Gateway in the public subnet
3. **Reduced attack surface** — Even if a container is compromised, the attacker can't directly expose services to the internet
4. **Compliance** — Many regulatory frameworks (PCI-DSS, HIPAA) require compute resources in private networks
5. **Network segmentation** — Public subnets only contain the load balancer and NAT Gateway — minimal exposure

The EKS API server has both public and private endpoints enabled. `public` allows developers/Jenkins to run kubectl from outside; `private` allows node-to-control-plane communication within the VPC.

---

**Q23. How does Terraform state management work in your project?**

**Answer:**
Terraform state is stored remotely in S3 with DynamoDB locking:

```hcl
terraform {
  backend "s3" {
    bucket  = "redbus-terraform-state"
    key     = "eks/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}
```

**Why remote state:**
1. **Team collaboration** — Multiple engineers can run Terraform against the same state
2. **State locking** — DynamoDB prevents concurrent `terraform apply` operations that could corrupt state
3. **Encryption** — S3 bucket uses SSE (Server-Side Encryption) for at-rest encryption
4. **Versioning** — S3 bucket versioning allows state rollback if something goes wrong
5. **Backup** — State is not lost if a developer's machine crashes

**Setup requires:**
- S3 bucket with versioning and encryption enabled
- DynamoDB table with `LockID` as primary key

**State file contents:** Maps Terraform resource names to real AWS resource IDs, tracks resource attributes, and manages dependencies.

---

**Q24. What are Terraform modules, and which ones did you use?**

**Answer:**
Terraform modules are reusable, encapsulated sets of resources. They follow DRY (Don't Repeat Yourself) principles and provide tested, community-maintained infrastructure patterns.

I used two community modules from the Terraform Registry:

1. **`terraform-aws-modules/vpc/aws` (~> 5.0):**
   - Creates VPC, subnets, route tables, NAT Gateway, Internet Gateway
   - Handles EKS-required subnet tagging (`kubernetes.io/cluster/redbus-cluster`, `kubernetes.io/role/internal-elb`, `kubernetes.io/role/elb`)
   - Without the module, this would require 20+ individual resources
   
2. **`terraform-aws-modules/eks/aws` (~> 20.0):**
   - Creates EKS cluster, IAM roles (cluster + node), security groups, OIDC provider
   - Manages node groups with launch templates
   - Provides add-on management capability

**Benefits of using modules:**
- Hundreds of configuration options abstracted behind simple variables
- Maintained by HashiCorp and AWS partners
- Tested across thousands of deployments
- Version-pinned for stability (`~> 5.0` allows 5.x, blocks 6.0)

---

**Q25. Explain the Terraform workflow you follow (init, plan, apply).**

**Answer:**
1. **`terraform init`** — Initializes the working directory:
   - Downloads provider plugins (AWS ~> 5.0, Kubernetes ~> 2.0)
   - Downloads modules (vpc, eks)
   - Configures the S3 backend
   - Creates `.terraform/` directory and `.terraform.lock.hcl`

2. **`terraform plan`** — Creates an execution plan:
   - Reads current state from S3
   - Compares desired state (HCL code) with actual state
   - Shows what will be created, modified, or destroyed
   - I always review this output before applying
   
3. **`terraform apply`** — Applies the changes:
   - Acquires DynamoDB state lock
   - Creates/modifies/destroys resources in dependency order
   - Updates the state file in S3
   - Releases the lock

4. **`terraform destroy`** — Tears down all managed resources (used for cleanup/cost savings)

**Best practices I follow:**
- Run `terraform plan -out=tfplan` and then `terraform apply tfplan` for exact execution
- Use `-var-file` for environment-specific values
- Never edit state manually — use `terraform state mv/rm` if needed

---

**Q26. How do you handle different environments (dev, staging, prod) with Terraform?**

**Answer:**
The project uses variables with defaults that can be overridden per environment:

```hcl
variable "environment" { default = "dev" }
variable "node_desired_size" { default = 2 }
variable "node_max_size" { default = 5 }
```

**Strategies for multi-environment:**
1. **Variable files** — `terraform apply -var-file=prod.tfvars` with different values for each environment
2. **Terraform workspaces** — `terraform workspace new prod` maintains separate state per environment
3. **Directory structure** (recommended for large teams):
   ```
   environments/
     dev/
       main.tf (references shared modules)
       terraform.tfvars
     prod/
       main.tf
       terraform.tfvars
   ```
4. **Terragrunt** — DRY wrapper around Terraform for managing multiple environments

For this project, changing the environment is done by overriding variables: larger instances for prod (`t3.large`), more nodes (`min=3, max=10`), multi-NAT Gateway, etc.

---

**Q27. What does the EKS module configure for IAM, and why is it important?**

**Answer:**
The EKS module creates several IAM resources:

1. **Cluster IAM Role** — Allows the EKS control plane to:
   - Manage ENIs for pod networking
   - Create and manage Load Balancers
   - Write logs to CloudWatch
   - Policies: `AmazonEKSClusterPolicy`

2. **Node Group IAM Role** — Allows worker nodes to:
   - Pull images from ECR (`AmazonEC2ContainerRegistryReadOnly`)
   - Communicate with the EKS API (`AmazonEKSWorkerNodePolicy`)
   - Configure VPC networking (`AmazonEKS_CNI_Policy`)

3. **OIDC Provider** — Enables IAM Roles for Service Accounts (IRSA), allowing pods to assume specific IAM roles:
   - Prometheus can read Kubernetes metrics
   - Application pods can access specific AWS services without using node-level credentials

**Why it matters:** Without proper IAM:
- Nodes can't join the cluster
- Pods can't pull images from ECR
- The cluster can't create Load Balancers for Services
- The principle of least privilege ensures compromised pods can't access unrelated AWS resources

---

### SECTION 5: CI/CD PIPELINE — JENKINS (Q28–Q34)

---

**Q28. Walk me through your Jenkins pipeline stages.**

**Answer:**
The Jenkinsfile defines a declarative pipeline with 12+ stages:

| # | Stage | Purpose |
|---|-------|---------|
| 1 | **Clean Workspace** | `cleanWs()` removes artifacts from previous builds |
| 2 | **Setup ECR Registry** | Dynamically gets AWS Account ID via `aws sts get-caller-identity`, constructs ECR URLs |
| 3 | **Ensure ECR Repositories** | Creates ECR repos if they don't exist (`aws ecr describe-repositories \|\| aws ecr create-repository`) |
| 4 | **Checkout** | Pulls source code from Git |
| 5 | **Install Dependencies** | **Parallel:** `npm install` for frontend + backend simultaneously |
| 6 | **Run Tests** | **Parallel:** Runs test suites for both services |
| 7 | **SonarQube Analysis** | Static code analysis for bugs, code smells, vulnerabilities |
| 8 | **SonarQube Quality Gate** | Waits up to 5 minutes for quality gate result |
| 9 | **OWASP Dependency Check** | Scans dependencies for known CVEs (NVD database) |
| 10 | **Trivy FS Scan** | Filesystem security scan for HIGH and CRITICAL vulnerabilities |
| 11 | **Build Docker Images** | **Parallel:** Builds frontend + backend images, tagged with build number + latest |
| 12 | **Scan Docker Images** | **Parallel:** Trivy scans both built images |
| 13 | **Push to ECR** | Logs in to ECR, pushes images with both tags |
| 14 | **Deploy to K8s** | Updates kubeconfig, applies manifests, sets image, waits for rollout |

**Post actions:** Docker cleanup, artifact archival, HTML report publishing, email notifications.

---

**Q29. How does your pipeline handle security scanning? What tools do you use?**

**Answer:**
The pipeline implements **three layers of security scanning:**

1. **SonarQube (SAST — Static Application Security Testing):**
   - Analyzes source code for bugs, code smells, security vulnerabilities, and code duplication
   - Project key: `redbus-devops`
   - Excludes `node_modules`, `build`, `dist`, and test files
   - Quality Gate acts as a gatekeeper (though configured as `UNSTABLE` rather than `FAILURE` to not block deployments)

2. **OWASP Dependency Check (SCA — Software Composition Analysis):**
   - Scans `package.json` and `package-lock.json` against the National Vulnerability Database (NVD)
   - Identifies known CVEs in third-party libraries
   - Generates HTML, JSON, and XML reports for audit trails
   - Uses NVD API key for faster database updates

3. **Trivy (Container & Filesystem Scanning):**
   - **Filesystem scan:** `trivy fs --severity HIGH,CRITICAL .` — Scans source code and configs for secrets, misconfigurations
   - **Image scan:** `trivy image --severity HIGH,CRITICAL $IMAGE` — Scans built Docker images for OS package CVEs and application vulnerabilities
   - Runs in parallel for both frontend and backend images

**Why three tools?** Each covers a different attack surface — source code quality, dependency vulnerabilities, and container/OS-level vulnerabilities.

---

**Q30. How do parallel stages work in your Jenkins pipeline?**

**Answer:**
The Jenkinsfile uses `parallel` blocks for independent tasks:

```groovy
stage('Install Dependencies') {
    parallel {
        stage('Frontend Dependencies') {
            steps { dir('front-end-redbus') { sh 'npm install --legacy-peer-deps' } }
        }
        stage('Backend Dependencies') {
            steps { dir('back-end-redbus') { sh 'npm install' } }
        }
    }
}
```

**Stages using parallelism:**
- Install Dependencies (frontend + backend)
- Run Tests (frontend + backend)
- Build Docker Images (frontend + backend)
- Scan Docker Images (frontend + backend)

**Benefits:**
- Reduces total pipeline time — instead of 10+10 minutes sequentially, both run in ~10 minutes
- The overall stage fails if ANY parallel stage fails
- Each parallel branch has its own workspace context

**Limitation:** Stages that depend on previous outputs (e.g., "Scan Images" depends on "Build Images") must remain sequential.

---

**Q31. How does Jenkins deploy to the EKS cluster?**

**Answer:**
The deployment stage performs these steps:

```groovy
stage('Deploy to Kubernetes') {
    steps {
        script {
            // 1. Configure kubectl to point to the EKS cluster
            sh "aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}"
            
            // 2. Apply all Kubernetes manifests (creates/updates resources)
            sh "kubectl apply -f infra/kubernetes/ -n redbus"
            
            // 3. Update the image tag to the new build number (triggers rolling update)
            sh "kubectl set image deployment/redbus-frontend redbus-frontend=${FRONTEND_IMAGE}:${BUILD_NUMBER} -n redbus"
            sh "kubectl set image deployment/redbus-backend redbus-backend=${BACKEND_IMAGE}:${BUILD_NUMBER} -n redbus"
            
            // 4. Wait for rollout to complete (max 10 minutes)
            sh "kubectl rollout status deployment/redbus-frontend -n redbus --timeout=600s"
            sh "kubectl rollout status deployment/redbus-backend -n redbus --timeout=600s"
        }
    }
}
```

**Key points:**
- `aws eks update-kubeconfig` authenticates Jenkins to the cluster using IAM
- `kubectl apply` is idempotent — safe to run on every build
- `kubectl set image` with `BUILD_NUMBER` triggers a rolling update with a specific, traceable image version
- `kubectl rollout status` blocks the pipeline until all pods are running the new version (or times out after 600s)
- Jenkins needs IAM permissions: `eks:DescribeCluster`, `eks:ListClusters`, and RBAC permissions within the cluster

---

**Q32. How do email notifications work in your Jenkins pipeline?**

**Answer:**
The pipeline uses the **Extended E-mail Notification Plugin** in the `post` block:

```groovy
post {
    success {
        emailext(
            subject: "✅ Pipeline Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: """...<html template with build details>...""",
            to: "${EMAIL_RECIPIENTS}",
            mimeType: 'text/html'
        )
    }
    failure {
        emailext(
            subject: "❌ Pipeline Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: """...<html template with error details and links>...""",
            to: "${EMAIL_RECIPIENTS}",
            mimeType: 'text/html'
        )
    }
}
```

**Features:**
- **HTML email bodies** with formatted tables showing build number, status, duration, triggered by, and direct links to console output and SonarQube
- **Different templates** for success, failure, and unstable (quality gate warnings)
- **SMTP configuration** in Jenkins → Manage Jenkins → Configure System (typically Gmail SMTP or SES)
- Post-build stage also runs `docker system prune -af` for cleanup and archives security scan reports

---

**Q33. What is a SonarQube Quality Gate, and how do you handle it?**

**Answer:**
A Quality Gate is a set of conditions that code must meet to pass. Default conditions include:
- No new bugs
- No new vulnerabilities
- Code coverage > 80%
- Duplication < 3%

In my pipeline:
```groovy
stage('SonarQube Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: false
        }
    }
    post {
        failure {
            script { currentBuild.result = 'UNSTABLE' }
        }
    }
}
```

**Key decision:** `abortPipeline: false` with fallback to `UNSTABLE` means the pipeline **continues** even if the quality gate fails, but the build is marked as **UNSTABLE** (yellow). This approach:
- Doesn't block deployment for non-critical code quality issues
- Still provides visibility (yellow build in Jenkins, notification sent)
- Allows the team to address technical debt without blocking releases
- In a stricter environment, you'd set `abortPipeline: true` to enforce code quality standards

---

**Q34. How does Jenkins authenticate with AWS services (ECR, EKS)?**

**Answer:**
Jenkins authenticates using **IAM credentials** configured as Jenkins credentials:

1. **AWS Credentials in Jenkins:**
   - Stored as `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in Jenkins Credential Store
   - Or better: Jenkins runs on an EC2 instance with an **IAM Instance Profile** (no static credentials)

2. **ECR Authentication:**
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
   ```
   This generates a temporary 12-hour token for Docker to push images to ECR.

3. **EKS Authentication:**
   ```bash
   aws eks update-kubeconfig --name redbus-cluster --region us-east-1
   ```
   This configures `kubectl` with a token-based authentication that uses the IAM identity.

4. **Required IAM Permissions:**
   - `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:PutImage`, etc.
   - `eks:DescribeCluster`
   - The IAM user/role must also be mapped in the EKS `aws-auth` ConfigMap within the cluster

**Best practice:** Use IAM Instance Profile on the Jenkins EC2 instance instead of static access keys. Rotate credentials if static keys are necessary.

---

### SECTION 6: MONITORING & OBSERVABILITY (Q35–Q38)

---

**Q35. Explain your monitoring stack architecture.**

**Answer:**
The monitoring stack consists of four components running in the `monitoring` namespace:

1. **Prometheus (v2.48.0)** — Time-series database and metrics collector
   - Pulls metrics from targets every 15 seconds via HTTP (`/metrics` endpoint)
   - Stores data with 15-day retention in TSDB (emptyDir volume)
   - Service discovery: Kubernetes API for auto-discovering pods, services, nodes
   - NodePort service on 30090 for direct access

2. **Grafana (v10.2.0)** — Visualization and dashboarding
   - Pre-configured Prometheus datasource via ConfigMap
   - Dashboard provisioning via file provider
   - Default admin credentials (`admin/admin123`)
   - NodePort service on 30030

3. **Node Exporter (v1.7.0)** — Host-level metrics
   - Runs as a DaemonSet (one pod per node)
   - Uses `hostNetwork: true` and `hostPID: true` for system access
   - Mounts `/proc`, `/sys`, `/` as read-only
   - Exports CPU, memory, disk, network metrics per node

4. **kube-state-metrics (v2.10.1)** — Kubernetes object metrics
   - Translates Kubernetes object states into Prometheus metrics
   - Tracks: deployments, pods, nodes, services, jobs, HPAs, etc.
   - Example metric: `kube_deployment_status_replicas_available{deployment="redbus-backend"}`

**Data flow:** Node Exporter + kube-state-metrics + Application pods → Prometheus scrapes → Grafana visualizes

---

**Q36. What Prometheus scrape configurations did you set up?**

**Answer:**
The Prometheus ConfigMap defines 10 scrape jobs:

| Job | Target | Method |
|-----|--------|--------|
| `prometheus` | Self-monitoring | Static `localhost:9090` |
| `node-exporter` | Host metrics | Endpoint SD in monitoring namespace |
| `kube-state-metrics` | K8s object metrics | Endpoint SD in monitoring namespace |
| `kubernetes-apiservers` | API server metrics | K8s SD, HTTPS with SA token |
| `kubernetes-nodes` | Kubelet metrics | K8s SD via API proxy |
| `kubernetes-cadvisor` | Container metrics | K8s SD, `/metrics/cadvisor` path |
| `kubernetes-service-endpoints` | Annotated services | Endpoint SD, `prometheus.io/scrape: "true"` |
| `kubernetes-pods` | Annotated pods | Pod SD, annotation-based |
| `redbus-backend` | Backend app | Pod SD in `redbus` namespace, port 5000 |
| `redbus-frontend` | Frontend app | Pod SD in `redbus` namespace |

**Key technique — Annotation-based discovery:**
```yaml
# Any pod/service with these annotations gets scraped automatically:
prometheus.io/scrape: "true"
prometheus.io/port: "8080"
prometheus.io/path: "/custom-metrics"
```

**RBAC:** Prometheus uses a ServiceAccount with a ClusterRole that grants `get`, `list`, `watch` on nodes, services, endpoints, pods, and ingresses — necessary for Kubernetes service discovery.

---

**Q37. What key metrics would you monitor for this application?**

**Answer:**
**Infrastructure Metrics (Node Exporter + kube-state-metrics):**
| Metric | PromQL | Alert Threshold |
|--------|--------|----------------|
| CPU usage per node | `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` | > 80% |
| Memory usage | `node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes` | > 85% |
| Disk usage | `node_filesystem_avail_bytes / node_filesystem_size_bytes` | < 15% free |
| Pod restarts | `kube_pod_container_status_restarts_total` | > 5 in 1 hour |
| Desired vs available replicas | `kube_deployment_status_replicas_available` | < desired count |

**Application Metrics (if instrumented):**
| Metric | Purpose |
|--------|---------|
| HTTP request rate | Traffic volume |
| HTTP error rate (5xx) | Application errors |
| Response latency (p95, p99) | Performance |
| MongoDB connection pool | Database health |

**Kubernetes Metrics (cAdvisor):**
| Metric | Purpose |
|--------|---------|
| `container_cpu_usage_seconds_total` | Container CPU consumption |
| `container_memory_working_set_bytes` | Container memory usage |
| `container_network_receive_bytes_total` | Network throughput |

---

**Q38. How did you configure Grafana to auto-discover Prometheus?**

**Answer:**
Grafana's Prometheus datasource is provisioned via a ConfigMap mounted as a file:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
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
```

This file is mounted at `/etc/grafana/provisioning/datasources/datasources.yaml` in the Grafana container.

**Dashboard provisioning:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards-provider
data:
  dashboards.yaml: |
    apiVersion: 1
    providers:
      - name: 'default'
        folder: ''
        type: file
        options:
          path: /var/lib/grafana/dashboards
```

**Why ConfigMap-based provisioning:**
- Grafana starts with everything pre-configured — no manual setup needed
- Infrastructure as Code — dashboards and datasources are version-controlled
- Reproducible — anyone deploying the stack gets the same monitoring setup
- The `access: proxy` mode means Grafana's backend server makes requests to Prometheus, not the user's browser (works even when Prometheus is internal to the cluster)

---

### SECTION 7: GENERAL DEVOPS & SCENARIO-BASED (Q39–Q40)

---

**Q39. If a deployment fails in production, what is your rollback strategy?**

**Answer:**
**Immediate rollback (under 30 seconds):**
```bash
kubectl rollout undo deployment/redbus-backend -n redbus
kubectl rollout undo deployment/redbus-frontend -n redbus
```
This reverts to the previous ReplicaSet. Kubernetes keeps old ReplicaSets (controlled by `revisionHistoryLimit`, default 10).

**Rollback to specific version:**
```bash
kubectl rollout history deployment/redbus-backend -n redbus
kubectl rollout undo deployment/redbus-backend -n redbus --to-revision=3
```

**Pipeline-level prevention:**
- `kubectl rollout status --timeout=600s` in Jenkins will fail the build if pods don't become healthy within 10 minutes (e.g., CrashLoopBackOff)
- Docker images are tagged with `BUILD_NUMBER`, so you can always redeploy a specific version
- ECR lifecycle policy keeps the last 10 images for rollback scenarios

**Full incident response:**
1. **Detect** — Prometheus alerts on increased error rate or pod restarts
2. **Triage** — Check `kubectl describe pod`, `kubectl logs`, Grafana dashboards
3. **Rollback** — `kubectl rollout undo` for immediate relief
4. **RCA** — Examine the failed build's Trivy reports, SonarQube analysis, test results
5. **Fix** — Push a fix through the full pipeline (tests → scans → deploy)

---

**Q40. What would you improve or add to this project if you had more time?**

**Answer:**
**Security Enhancements:**
- AWS Secrets Manager + External Secrets Operator instead of native K8s Secrets
- Network Policies to restrict pod-to-pod communication (e.g., only frontend can reach backend)
- Pod Security Standards (Restricted) to enforce non-root, read-only filesystem
- OPA/Gatekeeper for admission control policies

**CI/CD Improvements:**
- GitOps with ArgoCD — Kubernetes manifests in a separate repo, ArgoCD syncs automatically
- Helm charts instead of raw manifests for templating and release management
- Blue/Green or Canary deployments using Argo Rollouts
- Automated database migration stage before deployment

**Infrastructure:**
- Multi-region deployment for disaster recovery
- Karpenter instead of Cluster Autoscaler for faster, smarter node provisioning
- AWS WAF in front of the Application Load Balancer
- VPN for private access to monitoring dashboards

**Observability:**
- Distributed tracing with Jaeger or AWS X-Ray
- Log aggregation with EFK stack (Elasticsearch, Fluentd, Kibana) or Loki
- PagerDuty/Slack integration for Prometheus AlertManager
- Custom application metrics using `prom-client` (Node.js Prometheus library)

**Application:**
- API rate limiting with Express middleware or Nginx
- Redis caching layer for frequently queried routes and bus data
- WebSocket support for real-time seat availability updates
- Unit tests with proper coverage (Jest for backend, React Testing Library for frontend)
- API documentation with Swagger/OpenAPI

---

## Quick Reference: Key Numbers to Remember

| Item | Value |
|------|-------|
| Frontend image size | ~25MB (multi-stage) |
| Backend image size | ~150MB |
| VPC CIDR | 10.0.0.0/16 |
| Availability Zones | 3 (us-east-1a, 1b, 1c) |
| K8s version | 1.29 |
| Node instances | t3.medium (1-5 nodes) |
| App replicas | 2 each (frontend + backend) |
| Prometheus retention | 15 days |
| ECR lifecycle | Keep last 10 images |
| Pipeline stages | 12+ |
| Rollout timeout | 600 seconds |
| Health check interval | 30 seconds |
| Terraform modules | 2 (VPC + EKS) |
| Monitoring tools | 4 (Prometheus, Grafana, Node Exporter, kube-state-metrics) |
| Security scanners | 3 (SonarQube, Trivy, OWASP) |
