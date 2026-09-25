# 🎯 AI Resume Analyzer — Production-Grade DevOps Project

An end-to-end **cloud-native application** with a full DevOps toolchain: Infrastructure as Code, CI/CD automation, Kubernetes orchestration, observability, and autoscaling — all deployed on AWS.

![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20RDS%20%7C%20ECR-orange)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)
![Kubernetes](https://img.shields.io/badge/K8s-EKS-326CE5)
![Docker](https://img.shields.io/badge/Containers-Docker-2496ED)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF)
![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-E6522C)
![Grafana](https://img.shields.io/badge/Dashboards-Grafana-F46800)

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Features](#-features)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Observability](#-observability)
- [Autoscaling](#-autoscaling)
- [Security](#-security)
- [Screenshots](#-screenshots)
- [Challenges & Solutions](#-challenges--solutions)
- [Future Improvements](#-future-improvements)
- [Author](#-author)

---

## 🎯 Overview

**AI Resume Analyzer** is a full-stack application that helps job seekers improve their resumes through AI-powered analysis. Users can upload resumes (PDF/DOCX), receive an ATS score, get skill detection, structural feedback, and match their resume against job descriptions.

The project is designed as a **production-grade DevOps showcase**, covering:

- **Infrastructure as Code** with Terraform (VPC, EKS, RDS, ECR, IAM, security groups)
- **Container orchestration** on Kubernetes (EKS) with self-healing and rolling updates
- **CI/CD** via GitHub Actions with security scanning (Trivy, TruffleHog, SonarQube)
- **Observability** with Prometheus + Grafana + email alerts
- **Autoscaling** at both pod level (HPA) and node level (Cluster Autoscaler)
- **Security-first** design: IRSA, Secrets Manager, immutable ECR tags, non-root containers

---

## 🏗 Architecture

```
                    ┌─────────────────────────────────────────────────────┐
                    │                     INTERNET                         │
                    └──────────────────────────┬──────────────────────────┘
                                               │
                                               ▼
                                  ┌────────────────────────┐
                                  │   Network Load Balancer │
                                  │  (AWS LB Controller)    │
                                  └───────────┬────────────┘
                                              │
                                              ▼
                    ┌───────────────────────────────────────────────────┐
                    │                 EKS CLUSTER                        │
                    │                                                    │
                    │   ┌─────────────────┐     ┌─────────────────┐     │
                    │   │  Frontend Pods  │────▶│  Backend Pods   │     │
                    │   │ (React + Nginx) │     │    (FastAPI)    │     │
                    │   └─────────────────┘     └────────┬────────┘     │
                    │           ▲                        │               │
                    │           │                        ▼               │
                    │   ┌───────┴────────┐      ┌─────────────────┐     │
                    │   │   HPA (1→5)    │      │  RDS PostgreSQL │     │
                    │   └────────────────┘      │   (Multi-AZ)    │     │
                    │                            └─────────────────┘     │
                    │                                                    │
                    │   ┌─────────────────┐      ┌─────────────────┐     │
                    │   │  Prometheus     │      │  Grafana        │     │
                    │   │  + Node Exporter│─────▶│  + Alerts       │     │
                    │   └─────────────────┘      └─────────────────┘     │
                    │                                                    │
                    │   ┌─────────────────────────────────────────┐      │
                    │   │     Cluster Autoscaler (1→2 nodes)      │      │
                    │   └─────────────────────────────────────────┘      │
                    └────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         Terraform (IaC)                                  │
│  VPC · Public/Private/DB Subnets · NAT GW · EKS · RDS · ECR · IAM       │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      GitHub Actions (CI/CD)                              │
│  TruffleHog → SonarQube → Build (ARM64+AMD64) → Trivy → Kustomize Deploy│
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠 Tech Stack

### Application
| Layer | Technology |
|-------|-----------|
| Frontend | React 19, TypeScript, Vite, React Router |
| Backend | FastAPI, SQLAlchemy, Pydantic, Python 3.12 |
| Database | PostgreSQL 16 (AWS RDS) |
| AI | OpenAI API (GPT models) |
| Auth | JWT, bcrypt |

### DevOps
| Category | Technology |
|----------|-----------|
| Cloud | AWS (EKS, RDS, ECR, VPC, NLB, Secrets Manager) |
| IaC | Terraform 1.6+ |
| Containers | Docker (multi-stage, multi-arch ARM64/AMD64) |
| Orchestration | Kubernetes 1.33 (EKS) |
| CI/CD | GitHub Actions |
| GitOps | Kustomize |
| Monitoring | Prometheus, Grafana, Node Exporter, Kube State Metrics |
| Autoscaling | HPA (pods), Cluster Autoscaler (nodes) |
| Ingress | AWS Load Balancer Controller + NLB |
| Security | Trivy, TruffleHog, SonarQube, IRSA |

---

## ✨ Features

### Application Features
- 🔐 JWT-based user authentication
- 📄 PDF/DOCX resume upload (up to 5 MB)
- 🎯 Deterministic ATS score (0–100)
- 🧠 AI-powered resume analysis (summary, strengths, weaknesses, recommendations)
- 💼 Job description matching with skill gap analysis
- 📊 Interactive resume dashboard

### DevOps Features
- ✅ **Infrastructure as Code** — 43 Terraform resources
- ✅ **Multi-arch containers** — Graviton (ARM64) + x86_64 (AMD64)
- ✅ **Zero-downtime deployments** — rolling updates with readiness probes
- ✅ **Self-healing** — liveness/readiness probes + ReplicaSets
- ✅ **Horizontal Pod Autoscaling** — 1→5 replicas based on CPU/memory
- ✅ **Cluster Autoscaling** — 1→2 nodes based on scheduling pressure
- ✅ **Container vulnerability scanning** — Trivy in CI
- ✅ **Secret scanning** — TruffleHog in CI
- ✅ **Static code analysis** — SonarQube (optional)
- ✅ **Immutable ECR tags** — prevents tag overwrites
- ✅ **Secrets management** — AWS Secrets Manager + K8s secrets
- ✅ **IRSA** — pod-level IAM permissions
- ✅ **Prometheus metrics** — cluster + application
- ✅ **Grafana dashboards** — pre-built Kubernetes dashboards
- ✅ **Email alerts** — for CPU, memory, pod failures

---

## 📁 Project Structure

```
AI-resume-analyzer/
├── backend/                          # FastAPI application
│   ├── app/
│   │   ├── ai/                       # OpenAI integration
│   │   ├── api/                      # Route handlers
│   │   ├── core/                     # Config, security, DB
│   │   ├── models/                   # SQLAlchemy models
│   │   ├── schemas/                  # Pydantic schemas
│   │   ├── services/                 # Business logic
│   │   └── main.py                   # App entry point
│   ├── Dockerfile                    # Multi-stage backend image
│   └── requirements.txt
├── frontend/                         # React + Vite application
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   └── services/
│   ├── Dockerfile                    # Multi-stage frontend image
│   └── nginx.conf                    # SPA + reverse proxy config
├── terraform/                        # Infrastructure as Code
│   ├── environments/dev/             # Dev environment config
│   │   ├── main.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   └── backend.tf                # S3 state backend
│   └── modules/
│       ├── vpc/                      # VPC, subnets, NAT, IGW
│       ├── eks/                      # EKS cluster + node group
│       ├── rds/                      # PostgreSQL with Secrets Manager
│       ├── ecr/                      # Container registries
│       └── alb-controller/           # IAM for AWS LB Controller
├── k8s/                              # Kubernetes manifests
│   ├── deployment.yaml               # Frontend deployment
│   ├── backend-deployment.yaml       # Backend deployment
│   ├── service.yaml                  # NLB service
│   ├── backend-service.yaml          # ClusterIP for backend
│   ├── hpa.yaml                      # Horizontal Pod Autoscaler
│   ├── ingress.yaml                  # ALB ingress (optional)
│   └── kustomization.yaml            # Kustomize entrypoint
└── .github/workflows/
    └── devsecops.yml                 # CI/CD pipeline
```

---

## 🚀 Getting Started

### Prerequisites

- AWS account with admin access
- Terraform 1.6+
- AWS CLI v2
- kubectl
- Helm 3.x
- Docker (with buildx)
- Node.js 20+ (for frontend)
- Python 3.12+ (for backend)

### 1. Provision Infrastructure

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply -auto-approve
```

Outputs include:
- EKS cluster endpoint
- RDS endpoint
- ECR repository URLs
- VPC/subnet IDs

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region ap-south-1 --name ai-resume-analyzer-dev
kubectl get nodes
```

### 3. Install Cluster Add-ons

```bash
# Metrics Server (for HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ai-resume-analyzer-dev \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Cluster Autoscaler
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  -n kube-system \
  --set autoDiscovery.clusterName=ai-resume-analyzer-dev \
  --set awsRegion=ap-south-1 \
  --set cloudProvider=aws
```

### 4. Deploy Monitoring Stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set grafana.adminPassword=admin
```

### 5. Build & Push Images

```bash
# Login to ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-south-1.amazonaws.com

# Build and push (multi-arch)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t <ecr-url>/ai-resume-analyzer-backend:latest --push ./backend
```

### 6. Deploy Application

```bash
kubectl apply -k k8s/
```

---

## 🔄 CI/CD Pipeline

The pipeline in `.github/workflows/devsecops.yml` runs on every push to `main`:

```
┌──────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Pipeline                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  1. Checkout                                                       │
│       ↓                                                            │
│  2. TruffleHog (secret scanning)                                  │
│       ↓                                                            │
│  3. SonarQube (static analysis — optional)                        │
│       ↓                                                            │
│  4. Setup QEMU + Docker Buildx                                    │
│       ↓                                                            │
│  5. Build Backend (multi-arch) → Push to ECR                      │
│       ↓                                                            │
│  6. Build Frontend (multi-arch) → Push to ECR                     │
│       ↓                                                            │
│  7. Trivy (container vulnerability scan) → SARIF upload           │
│       ↓                                                            │
│  8. Kustomize: inject image SHA tags                              │
│       ↓                                                            │
│  9. kubectl apply → EKS                                           │
│       ↓                                                            │
│ 10. Wait for rollout → Verify                                     │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
```

### Required GitHub Secrets

| Secret | Purpose |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | AWS authentication |
| `AWS_SECRET_ACCESS_KEY` | AWS authentication |
| `OPENAI_API_KEY` | AI resume analysis |
| `SONAR_TOKEN` | SonarCloud token (optional) |
| `SONAR_ORG` | SonarCloud org key (optional) |

---

## 📊 Observability

### Prometheus Metrics

Prometheus scrapes:
- **Node-level**: CPU, memory, disk, network (via Node Exporter)
- **Cluster-level**: pod status, deployments, HPAs (via Kube State Metrics)
- **Container-level**: per-container CPU/memory (via kubelet/cAdvisor)
- **Application-level**: FastAPI metrics (via `prometheus-fastapi-instrumentator`)

### Grafana Dashboards

Pre-built dashboards available:
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods)
- Kubernetes / Compute Resources / Node (Pods)
- Node Exporter / Nodes

### Alerts

Configured email alerts for:
- Pod down (any pod not `Running`)
- High CPU (>80% of request for 5 min)
- High memory (>90% of request for 5 min)
- HPA at max replicas
- Node memory pressure (>85%)

### Accessing Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open http://localhost:3000 — admin/admin
```

---

## 📈 Autoscaling

### Horizontal Pod Autoscaler (HPA)

| Metric | Target | Min | Max |
|--------|--------|-----|-----|
| CPU | 70% | 1 | 5 |
| Memory | 80% | 1 | 5 |

Scales frontend and backend independently based on load.

### Cluster Autoscaler

Automatically adjusts the EKS node group size (1→2 nodes) when:
- Pods are `Pending` due to insufficient resources
- Nodes are underutilized and pods can be consolidated

### Prefix Delegation

The EKS node group uses **AWS VPC CNI prefix delegation** to increase pod capacity from **17 to 110 pods per node**. This is configured via a custom launch template in the Terraform module.

---

## 🔒 Security

| Layer | Measure |
|-------|---------|
| **Secrets** | AWS Secrets Manager for DB credentials; K8s Secrets for app config |
| **IAM** | IRSA (IAM Roles for Service Accounts) — pods get only the permissions they need |
| **Images** | Multi-stage builds, non-root user, distroless/minimal base images |
| **Registry** | ECR with immutable tags + scan-on-push |
| **CI Scans** | TruffleHog (secrets), Trivy (CVEs), SonarQube (SAST) |
| **Network** | VPC with public/private/DB subnets, security groups scoped per service |
| **TLS** | Optional ACM cert + ALB ingress for HTTPS |
| **Kubernetes** | Network policies, RBAC, resource limits, readiness/liveness probes |

---

## 📸 Screenshots

> Add screenshots of these views to your repo:

1. **App Dashboard** — resume upload + ATS score
2. **Grafana Dashboard** — pod CPU/memory metrics
3. **HPA Autoscaling** — replicas scaling 1→5 under load
4. **GitHub Actions** — green pipeline with all security scans
5. **Cluster Autoscaler logs** — node scale-up event

---

## 🧩 Challenges & Solutions

### 1. **Pod Limit on EKS Nodes (17 pods)**
- **Problem**: `Too many pods` errors blocked scheduling
- **Root Cause**: AWS VPC CNI limits pods per node based on ENI count
- **Solution**: Enabled **prefix delegation** (`ENABLE_PREFIX_DELEGATION=true`) + created a **custom launch template** with `--max-pods=110` in the kubelet bootstrap

### 2. **Stale NLB Targets After Node Replacement**
- **Problem**: NLB kept pointing to dead node IPs
- **Root Cause**: AWS Load Balancer Controller cached old endpoints
- **Solution**: Manually deregistered stale targets + restarted the controller; added self-referencing security group rules

### 3. **Prometheus Kubelet Scrape Failure**
- **Problem**: `no route to host` on port 10250
- **Root Cause**: EKS kubelet uses a self-signed cert + node SG blocks pod traffic
- **Solution**: Added SG rules for port 10250 + patched ServiceMonitor with `insecureSkipVerify: true`

### 4. **Grafana OOMKilled Every 4 Minutes**
- **Problem**: Grafana pod kept restarting with `exit code 137`
- **Root Cause**: Memory limit set to 256Mi — Grafana 13.x needs ~500Mi
- **Solution**: Increased limit to 1Gi and adjusted requests accordingly

### 5. **Helm Upgrade Conflicts**
- **Problem**: `conflict occurred while applying object ...`
- **Root Cause**: Manual `kubectl patch` operations overwrote Helm-managed resources
- **Solution**: Deleted conflicting resources and let Helm recreate them

---

## 🚧 Future Improvements

- [ ] **TLS/HTTPS** — ACM certificate + ALB Ingress for secure access
- [ ] **Custom domain** — Route 53 alias to the load balancer
- [ ] **ArgoCD** — GitOps-based deployments instead of GitHub Actions push
- [ ] **Loki** — centralized log aggregation
- [ ] **Distributed tracing** — OpenTelemetry + Tempo
- [ ] **Chaos engineering** — Chaos Mesh for resilience testing
- [ ] **Multi-environment** — staging + production with Terraform workspaces
- [ ] **Service Mesh** — Istio for mTLS between services
- [ ] **Cost optimization** — Spot instances for non-critical workloads
- [ ] **Backup automation** — Velero for cluster state backups

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Gurjeet Singh**
- GitHub: [@Gurjeet60](https://github.com/Gurjeet60)
- Project: [AI-resume-analyzer](https://github.com/Gurjeet60/AI-resume-analyzer)

---

## 🙏 Acknowledgments

- AWS EKS documentation
- Prometheus Operator community
- Kubernetes SIG Autoscaling
- FastAPI and React communities

---

⭐ **If you found this project useful, please consider giving it a star!**
