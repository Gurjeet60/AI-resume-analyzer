# 🎯 AI Resume Analyzer — Full-Stack DevOps Project

An end-to-end **cloud-native application** with a complete DevOps toolchain: Infrastructure as Code, CI/CD automation, Kubernetes orchestration, observability, autoscaling, and self-healing — deployed on AWS EKS.

![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20RDS%20%7C%20ECR-orange)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)
![Kubernetes](https://img.shields.io/badge/K8s-1.36-326CE5)
![Docker](https://img.shields.io/badge/Containers-Docker-2496ED)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF)
![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-E6522C)
![Grafana](https://img.shields.io/badge/Dashboards-Grafana-F46800)
![Python](https://img.shields.io/badge/Python-3.12-3776AB)
![React](https://img.shields.io/badge/React-19-61DAFB)

**🌐 Live Application:** http://k8s-resume-resumese-6a3673c33d-8ebd8a7ddaa19575.elb.ap-south-1.amazonaws.com

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Features](#-features)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [One-Click Automation](#-one-click-automation)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Observability](#-observability)
- [Autoscaling](#-autoscaling)
- [Security](#-security)
- [Cost Optimization](#-cost-optimization)
- [Challenges Solved](#-challenges-solved)
- [Screenshots](#-screenshots)
- [Future Improvements](#-future-improvements)
- [Author](#-author)

---

## 🎯 Overview

**AI Resume Analyzer** is a full-stack application that helps job seekers improve their resumes through AI-powered analysis. Users can upload resumes (PDF/DOCX), receive an ATS score, get skill detection, structural feedback, and match their resume against job descriptions.

The project is designed as a **production-grade DevOps showcase**, covering:

- **Infrastructure as Code** with Terraform (VPC, EKS, RDS, ECR, IAM, security groups)
- **Container orchestration** on Kubernetes (EKS 1.36) with self-healing and rolling updates
- **CI/CD** via GitHub Actions with multi-arch builds and security scanning
- **Observability** with Prometheus, Grafana, and email alerts
- **Autoscaling** at both pod level (HPA) and node level (Cluster Autoscaler)
- **Security-first** design: IRSA, AWS Secrets Manager, immutable ECR tags, non-root containers
- **One-click automation** with a Bash framework that handles the entire lifecycle

---

## 🏗 Architecture

```
                    ┌─────────────────────────────────────────────────────┐
                    │                     INTERNET                         │
                    └──────────────────────────┬──────────────────────────┘
                                               │
                                               ▼
                                  ┌────────────────────────┐
                                  │  Network Load Balancer  │
                                  │ (AWS LB Controller)     │
                                  └───────────┬────────────┘
                                              │
                                              ▼
                    ┌───────────────────────────────────────────────────┐
                    │              EKS CLUSTER (K8s 1.36)                │
                    │                                                    │
                    │   ┌─────────────────┐     ┌─────────────────┐     │
                    │   │  Frontend Pods  │────▶│  Backend Pods   │     │
                    │   │ (React + Nginx) │     │    (FastAPI)    │     │
                    │   └─────────────────┘     └────────┬────────┘     │
                    │           ▲                        │               │
                    │           │                        ▼               │
                    │   ┌───────┴────────┐      ┌─────────────────┐     │
                    │   │   HPA (1→5)    │      │  RDS PostgreSQL │     │
                    │   └────────────────┘      │   (t4g.micro)   │     │
                    │                            └─────────────────┘     │
                    │                                                    │
                    │   ┌─────────────────┐      ┌─────────────────┐     │
                    │   │  Prometheus     │      │  Grafana        │     │
                    │   │  + Node Exporter│─────▶│  + Email Alerts │     │
                    │   └─────────────────┘      └─────────────────┘     │
                    │                                                    │
                    │   ┌─────────────────────────────────────────┐      │
                    │   │   Cluster Autoscaler (1→2 nodes)         │      │
                    │   └─────────────────────────────────────────┘      │
                    │                                                    │
                    │   ┌─────────────────────────────────────────┐      │
                    │   │  Launch Template (max-pods=110)          │      │
                    │   └─────────────────────────────────────────┘      │
                    └────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         Terraform (IaC)                                  │
│  VPC · Subnets · NAT · EKS · RDS · ECR · IAM · OIDC                     │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      GitHub Actions (CI/CD)                              │
│  TruffleHog → Trivy → Multi-Arch Build → ECR Push → Kustomize Deploy    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠 Tech Stack

### Application

| Layer | Technology |
|-------|-----------|
| **Frontend** | React 19, TypeScript, Vite, Nginx |
| **Backend** | FastAPI, SQLAlchemy, Pydantic, Python 3.12 |
| **Database** | PostgreSQL 16 (AWS RDS, t4g.micro) |
| **AI** | OpenAI API (GPT models) |
| **Auth** | JWT, bcrypt |

### DevOps

| Category | Technology |
|----------|-----------|
| **Cloud** | AWS (EKS, RDS, ECR, VPC, NLB, Secrets Manager) |
| **IaC** | Terraform 1.6+ (modular, remote state on S3) |
| **Containers** | Docker (multi-stage, multi-arch ARM64/AMD64) |
| **Orchestration** | Kubernetes 1.36 (EKS) |
| **CI/CD** | GitHub Actions |
| **GitOps** | Kustomize |
| **Monitoring** | Prometheus, Grafana, Node Exporter, Kube State Metrics |
| **Autoscaling** | HPA (pods), Cluster Autoscaler (nodes) |
| **Ingress** | AWS Load Balancer Controller + NLB |
| **Security** | Trivy, TruffleHog, SonarQube (optional), IRSA |

---

## ✨ Features

### Application Features

- 🔐 JWT-based user authentication
- 📄 PDF/DOCX resume upload (max 5 MB)
- 🎯 Deterministic ATS score (0–100)
- 🧠 AI-powered resume analysis (summary, strengths, weaknesses, recommendations)
- 💼 Job description matching with skill gap analysis
- 📊 Interactive resume dashboard

### DevOps Features

- ✅ **Infrastructure as Code** — 43 Terraform resources across modular stacks
- ✅ **Multi-arch containers** — ARM64 (Graviton) + AMD64 for scanner compatibility
- ✅ **Zero-downtime deployments** — rolling updates with readiness/liveness probes
- ✅ **Self-healing** — probes + ReplicaSets + auto-remediation script
- ✅ **Horizontal Pod Autoscaling** — 1→5 replicas based on CPU/memory
- ✅ **Cluster Autoscaling** — 1→2 nodes based on scheduling pressure
- ✅ **110 pods per node** via VPC CNI prefix delegation
- ✅ **Container vulnerability scanning** — Trivy in CI
- ✅ **Secret scanning** — TruffleHog in CI
- ✅ **Immutable ECR tags** — prevents tag overwrites
- ✅ **Secrets management** — AWS Secrets Manager
- ✅ **IRSA** — pod-level IAM permissions
- ✅ **Prometheus metrics** — cluster, node, kubelet, and application
- ✅ **Grafana dashboards** — pre-built Kubernetes compute dashboards
- ✅ **5 production alerts** — email notifications via Gmail SMTP

---

## 📁 Project Structure

```
AI-resume-analyzer/
├── devops.sh                             # 🚀 Main automation entrypoint
├── automation/                           # Automation framework
│   ├── lib/                              # Shared utilities
│   │   ├── colors.sh                     # Terminal colors
│   │   ├── logging.sh                    # Logging helpers
│   │   ├── utils.sh                      # Common functions
│   │   └── checks.sh                     # Pre-flight checks
│   ├── commands/                         # Lifecycle commands
│   │   ├── bootstrap.sh                  # Full setup
│   │   ├── deploy.sh                     # App deploy
│   │   ├── status.sh                     # Health dashboard
│   │   ├── heal.sh                       # Self-healing
│   │   ├── destroy.sh                    # Teardown
│   │   ├── cost.sh                       # Cost analysis
│   │   └── logs.sh                       # Log viewer
│   └── README.md                         # Framework docs
├── backend/                              # FastAPI application
│   ├── app/
│   │   ├── ai/                           # OpenAI integration
│   │   ├── api/                          # Route handlers
│   │   ├── core/                         # Config, security, DB
│   │   ├── models/                       # SQLAlchemy models
│   │   ├── schemas/                      # Pydantic schemas
│   │   ├── services/                     # Business logic
│   │   └── main.py                       # App entry point
│   ├── Dockerfile                        # Multi-stage backend image
│   └── requirements.txt
├── frontend/                             # React + Vite application
│   ├── src/
│   ├── Dockerfile                        # Multi-stage frontend image
│   └── nginx.conf
├── terraform/                            # Infrastructure as Code
│   ├── environments/dev/                 # Dev environment config
│   └── modules/
│       ├── vpc/                          # VPC, subnets, NAT, IGW
│       ├── eks/                          # EKS cluster + node group + LT
│       ├── rds/                          # PostgreSQL + Secrets Manager
│       ├── ecr/                          # Container registries
│       └── alb-controller/               # IAM for AWS LB Controller
├── k8s/                                  # Kubernetes manifests
│   ├── deployment.yaml                   # Frontend deployment
│   ├── backend-deployment.yaml           # Backend deployment
│   ├── service.yaml                      # NLB service
│   ├── backend-service.yaml              # ClusterIP service
│   ├── hpa.yaml                          # Horizontal Pod Autoscaler
│   └── kustomization.yaml                # Kustomize entrypoint
├── docs/
│   └── screenshots/                      # README screenshots
└── .github/workflows/
    └── devsecops.yml                     # CI/CD pipeline
```

---

## 🚀 Getting Started

### Prerequisites

- AWS account with admin access
- Terraform 1.6+
- AWS CLI v2
- kubectl
- Helm 3.x
- Docker with buildx support
- Node.js 20+ (for frontend)
- Python 3.12+ (for backend)

### 🔥 One-Command Setup

```bash
# Full setup from scratch (~35 minutes)
./devops.sh bootstrap
```

That single command:

1. Checks prerequisites
2. Provisions AWS infrastructure (VPC, EKS, RDS, ECR, IAM) with Terraform
3. Configures kubeconfig
4. Waits for worker nodes
5. Installs Metrics Server, AWS Load Balancer Controller, Cluster Autoscaler
6. Installs Prometheus + Grafana (kube-prometheus-stack)
7. Deploys the application
8. Runs verification tests

### Manual Setup (If You Prefer)

<details>
<summary>Click to expand manual steps</summary>

#### 1. Provision Infrastructure

```bash
cd terraform/environments/dev
terraform init
terraform apply -auto-approve
```

#### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region ap-south-1 --name ai-resume-analyzer-dev
```

#### 3. Install Cluster Add-ons

```bash
# Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployment metrics-server --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

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

# Monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set grafana.adminPassword=admin
```

#### 4. Deploy the Application

```bash
kubectl apply -k k8s/
```

</details>

---

## 🎬 One-Click Automation

The project includes a **Bash automation framework** at `./devops.sh`:

| Command | Description |
|---------|-------------|
| `./devops.sh bootstrap` | Full setup from scratch (~35 min) |
| `./devops.sh deploy` | Build, push, deploy new version |
| `./devops.sh status` | Complete health dashboard |
| `./devops.sh heal` | Auto-detect and fix common issues |
| `./devops.sh logs [app\|monitoring]` | Interactive log viewer |
| `./devops.sh cost` | AWS cost analysis + idle resource audit |
| `./devops.sh destroy` | Full teardown with confirmation |
| `./devops.sh help` | Show usage |

### Self-Healing Capabilities

The `heal` command runs 5 checks:

1. **Pod health** — fixes `InvalidImageName` by resolving correct image from ECR; force-restarts `CrashLoopBackOff` pods
2. **HPA metrics** — installs or restarts Metrics Server if HPA shows `<unknown>`
3. **NLB target health** — auto re-registers the node if the load balancer has no targets
4. **Node capacity** — verifies the 110-pod capacity from prefix delegation
5. **ReplicaSet cleanup** — removes stale ReplicaSets to keep the cluster tidy

Each check is **idempotent** — safe to run multiple times.

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

### Prometheus

- **2-day retention** configured via `prometheus.prometheusSpec.retention`
- Scrapes: nodes, kubelet, kube-state-metrics, and application pods
- 13+ up targets, 9+ container metrics series

### Grafana

- Pre-built Kubernetes dashboards:
  - Kubernetes / Compute Resources / Cluster
  - Kubernetes / Compute Resources / Namespace (Pods)
  - Node Exporter / Nodes

**Access:**

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open http://localhost:3000  (admin/admin)
```

### Alerts

5 production alerts configured with email notifications:

| Alert | Threshold | Pending | Severity |
|-------|-----------|---------|----------|
| **Pod Down** | Any pod not Running | 1m | Critical |
| **High CPU Usage** | CPU > 80% of request | 5m | Warning |
| **High Memory Usage** | Memory > 90% of request | 5m | Warning |
| **Node Memory High** | Node memory > 85% | 10m | Warning |
| **HPA at Max Replicas** | Current == max replicas | 5m | Warning |

Alerts send email via **Gmail SMTP** with App Password authentication.

---

## 📈 Autoscaling

### Horizontal Pod Autoscaler (HPA)

| Metric | Target | Min Replicas | Max Replicas |
|--------|--------|--------------|--------------|
| CPU | 70% | 1 | 5 |
| Memory | 80% | 1 | 5 |

### Cluster Autoscaler

- Node group min: `1`, max: `2`
- Scales up when pods are `Pending` (insufficient resources)
- Scales down when nodes are underutilized

### Prefix Delegation

Custom **launch template** enables **110 pods per node** (up from the default 17) via VPC CNI prefix delegation. Configured in `terraform/modules/eks/main.tf`:

```hcl
user_data = base64encode(<<-EOF
  #!/bin/bash
  /etc/eks/bootstrap.sh ${var.cluster_name} \
    --use-max-pods false \
    --kubelet-extra-args '--max-pods=110'
EOF
)
```

---

## 🔒 Security

| Layer | Measure |
|-------|---------|
| **Secrets** | AWS Secrets Manager for DB credentials; K8s Secrets for app config |
| **IAM** | IRSA (IAM Roles for Service Accounts) — pods get only the permissions they need |
| **Images** | Multi-stage builds, non-root user, distroless/minimal base |
| **Registry** | ECR with immutable tags + scan-on-push + lifecycle policy |
| **CI Scans** | TruffleHog (secrets), Trivy (CVEs), SonarQube (SAST) |
| **Network** | VPC with public/private/DB subnets; security groups scoped per service |
| **Kubernetes** | RBAC, resource limits, readiness/liveness probes, NetworkPolicy-ready |

---

## 💰 Cost Optimization

A full AWS cost audit identified several optimization opportunities:

| Optimization | Monthly Savings |
|--------------|-----------------|
| **Upgraded EKS 1.33 → 1.36** (exit Extended Support — 6× pricing) | **~$250** |
| Reduced CloudWatch log retention to 7 days | ~$20 |
| Removed 3 unused VPC Interface Endpoints | ~$17 |
| Enabled ECR lifecycle policy (auto-delete untagged >14d) | ~$5 |
| Audited: no idle EBS, no orphan EIPs, single NAT Gateway | – |
| **Total monthly savings** | **~$292** |

**Before:** ~$468/month (September)
**After:** ~$170/month (projected October)
**Reduction:** **64%**

### Cost Controls in Place

- **AWS Budget** with email alerts at 80% and 100%
- **Compute Optimizer** enabled for right-sizing recommendations
- **Cluster Autoscaler** prevents over-provisioning
- **HPA min=1 replica** keeps idle cost low
- **ECR lifecycle policies** auto-clean old images

---

## 🧩 Challenges Solved

### 1. **Pod Limit on EKS Nodes (17 → 110 pods)**

- **Problem:** `Too many pods` errors blocked monitoring stack scheduling
- **Root Cause:** AWS VPC CNI limits pods per node based on ENI count
- **Solution:** Enabled **prefix delegation** + created a **custom launch template** with `--max-pods=110` in the kubelet bootstrap script

### 2. **EKS Extended Support Charge ($360/month)**

- **Problem:** Cluster was on 1.33, incurring 6× standard support pricing
- **Root Cause:** Auto-upgrade window passed, cluster entered extended support
- **Solution:** Upgraded control plane → 1.35 → 1.36, upgraded node group in lockstep, aligned Terraform config

### 3. **Stale NLB Targets After Node Replacement**

- **Problem:** NLB kept pointing to dead node IPs after Terraform replaced the node
- **Solution:** Manually deregistered stale targets, restarted AWS LB Controller, added self-referencing security group rules

### 4. **Prometheus Kubelet Scrape Failure**

- **Problem:** `no route to host` on port 10250, then certificate error
- **Root Cause:** EKS kubelet uses self-signed cert + node SG blocks pod traffic + stale Endpoints
- **Solution:** Added SG rule for port 10250, patched ServiceMonitor with `insecureSkipVerify`, cleaned stale EndpointSlices

### 5. **Grafana OOMKilled Every 4 Minutes**

- **Problem:** Grafana pod restarting with `exit code 137`
- **Root Cause:** Memory limit 256Mi — Grafana 13.x needs ~500Mi
- **Solution:** Increased to 1Gi limit / 256Mi request

### 6. **Helm Upgrade Conflicts**

- **Problem:** `conflict occurred while applying object ...`
- **Root Cause:** Manual `kubectl patch` operations created foreign annotations
- **Solution:** Deleted conflicting ServiceMonitors, let Helm recreate them

### 7. **Immutable ECR Tag Collisions**

- **Problem:** Pipeline failed pushing `:latest` tag to immutable repo
- **Solution:** Removed `:latest` tag from pipeline, use SHA-only tags 

## 🚧 Future Improvements

- [ ] **ArgoCD** — GitOps-based deployments (pull-based instead of push)
- [ ] **Loki** — centralized log aggregation
- [ ] **TLS + Custom Domain** — ACM certificate + ALB Ingress
- [ ] **Distributed Tracing** — OpenTelemetry + Tempo
- [ ] **Chaos Engineering** — Chaos Mesh for resilience testing
- [ ] **Multi-environment** — staging + production with Terraform workspaces
- [ ] **Service Mesh** — Istio for mTLS and traffic management
- [ ] **External Secrets Operator** — better secrets lifecycle
- [ ] **Policy-as-Code** — OPA/Kyverno for K8s policies
- [ ] **Database Migrations** — Alembic in the pipeline
- [ ] **SLO/SLI tracking** — error budgets via Prometheus
- [ ] **Backup automation** — Velero for cluster state

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Gurjeet Singh** — Aspiring DevOps / Cloud Engineer

- GitHub: [@Gurjeet60](https://github.com/Gurjeet60)
- LinkedIn: [gurjeet-singh-39762b224](https://linkedin.com/in/gurjeet-singh-39762b224)
- Email: gurjeetsaini60@gmail.com

---

## 🙏 Acknowledgments

- AWS EKS documentation
- Prometheus Operator community
- Kubernetes SIG Autoscaling
- FastAPI and React communities

---

⭐ **If you found this project useful, please consider giving it a star!**
