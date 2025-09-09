# Petclinic CD (Continuous Deployment)

A fully automated infrastructure deployment using **Ansible** for setting up Kubernetes, ArgoCD, Prometheus monitoring, and GitOps workflows. This complements the CI pipeline by providing a complete production-ready environment with monitoring and alerting.

## 🚀 CD Overview

This Continuous Deployment setup provisions a complete DevOps infrastructure stack on any Ubuntu server using Ansible automation. Everything is deployed and configured automatically - from Docker to ArgoCD with GitOps.

## 📋 Architecture Components

```mermaid
    A[Ansible Playbook] --> B[Docker Installation]
    A --> C[kubectl Setup]  
    A --> D[Minikube Cluster]
    A --> E[Helm Package Manager]
    
    D --> F[Sealed Secrets Controller]
    F --> G[Prometheus Stack]
    G --> H[ArgoCD GitOps]
    
    H --> I[Pet Clinic App Deployment]
    G --> J[Grafana Dashboard]
    G --> K[AlertManager]
    
    K --> L[📧 Gmail Notifications]
    K --> M[📱 Slack Notifications]
```

## 🎯 Deployment Roles

### **Ansible Playbook Structure**
```yaml
- name: Deployment
  hosts: all
  gather_facts: no
  roles:
    - docker        # Container runtime
    - kubectl       # Kubernetes CLI
    - minikube      # Local Kubernetes cluster
    - helm          # Package manager
    - sealed-secrets # Encrypted secrets management
    - prometheus    # Monitoring & alerting stack
    - argocd        # GitOps deployment tool
```

## 🔧 Role-by-Role Breakdown

### 1. **Docker Role** 🐳
- **Intelligent Installation**: Checks if Docker exists, installs only if needed
- **Secure Setup**: Adds user to docker group for rootless operations
- **Automatic Service**: Ensures Docker daemon is running
- **Package Management**: Updates apt cache and installs dependencies

**Key Features:**
- Idempotent installation (safe to run multiple times)
- GPG key verification for security
- User permission management

### 2. **kubectl Role** ☸️
- **Latest Version**: Downloads current stable release automatically
- **Proper Installation**: System-wide installation with correct permissions
- **Version Detection**: Skips if already installed

### 3. **Minikube Role** 🔄
- **Cluster Management**: Starts Minikube with optimized settings
- **Resource Allocation**: 3.6GB RAM, 2 CPUs for production workloads
- **Kubeconfig Setup**: Automatic kubectl configuration
- **Health Checks**: Waits for Kubernetes API readiness

**Configuration:**
```bash
minikube start --driver=docker --memory=3600 --cpus=2 --wait=all
```

### 4. **Helm Role** 📦
- **Official Installation**: Uses Helm's official installation script
- **Version Management**: Always installs latest stable version
- **Ready for Charts**: Immediately available for deploying applications

### 5. **Sealed Secrets Role** 🔐
**Why Sealed Secrets?**
- **🚫 NOT base64**: Real encryption, not encoding
- **🔒 Asymmetric Encryption**: Public/private key cryptography
- **✅ Git Safe**: Encrypted secrets can be stored in repositories
- **🔄 Automatic Decryption**: Controller decrypts in cluster

**Installation Method:**
- Deployed via **Helm Charts** (not manual YAML)
- Custom private key deployment for consistent encryption
- Namespace: `kube-system`

```bash
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets -n kube-system
```

### 6. **Prometheus Stack Role** 📊🚨

#### **Complete Monitoring Solution**
Deployed via **Helm Chart**: `prometheus-community/kube-prometheus-stack`

#### **Components Included:**
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization dashboards  
- **AlertManager**: Multi-channel notification system

#### **🎨 Grafana Configuration**
- **Default Credentials**: `admin/admin` (no password tracing needed!)
- **Service Type**: NodePort (port 32000) for easy access
- **Persistent Storage**: 5GB PVC for dashboard persistence
- **Pre-configured Dashboard**: ArgoCD monitoring dashboard (ID: 14584) automatically imported

#### **🚨 AlertManager - Smart Notifications**

##### **📧 Gmail Integration**
```yaml
# Sealed Secret for Gmail SMTP
smtp_smarthost: 'smtp.gmail.com:587'
smtp_from: 'sheblabdo00@gmail.com'
smtp_auth_password_file: /etc/alertmanager/secrets/gmail-smtp-secret/smtp_auth_password
```

##### **📱 Slack Integration**  
```yaml
# Sealed Secret for Slack Webhook
api_url_file: /etc/alertmanager/secrets/slack-webhook-secret/slack_api_url
channel: '#argocd-notifications'
```

#### **🎯 Smart Alert Rules**
- **ArgoCDAppSynced**: ✅ Info alert when apps are in sync
- **ArgoCDAppOutOfSync**: ⚠️ Warning when apps drift from Git
- **Alert Inhibition**: Prevents spam by suppressing resolved alerts
- **Filtered Alerts**: Ignores noisy Kubernetes system alerts

##### **Sample Email Alert:**
```html
🚨 [FIRING] ArgoCD App Alert
Status: FIRING
App: pet-clinic-real-app  
Sync Status: OutOfSync
Repo URL: https://github.com/abdelrahman-shebl/PetClinic-app
Summary: ArgoCD app pet-clinic-real-app is OutOfSync
```

##### **Sample Slack Alert:**
```
🚨 [FIRING] (1) alerts
• ArgoCDAppOutOfSync (warning) — ArgoCD app pet-clinic-real-app is OutOfSync
```

### 7. **ArgoCD Role** 🔄

#### **GitOps Deployment Engine**
Deployed via **Helm Chart**: `argo/argo-cd`

#### **🎛️ ArgoCD Configuration**
- **Admin Password**: Pre-configured hash for `admin` user
- **Service Access**: NodePort (HTTP: 32080, HTTPS: 32443)
- **Resource Optimized**: Lightweight resource requests for efficient operation
- **Metrics Enabled**: Full Prometheus integration

#### **📊 Monitoring Integration**
- **ServiceMonitors**: Automatic Prometheus scraping
- **Custom Dashboards**: ArgoCD-specific Grafana dashboard
- **Network Policies**: Secure inter-component communication

#### **🚀 Application Deployment**
Deployed via **ArgoCD Apps Helm Chart**: `argo/argocd-apps`

```yaml
applications:
  pet-clinic-real-app:
    source:
      repoURL: https://github.com/abdelrahman-shebl/PetClinic-app
      path: K8s
      targetRevision: HEAD
    destination:
      namespace: petclinic
    syncPolicy:
      automated:
        prune: true      # Remove deleted resources
        selfHeal: true   # Auto-fix configuration drift
      syncOptions:
        - CreateNamespace=true
```

**🔄 Automatic GitOps Features:**
- **Continuous Monitoring**: Watches Git repository for changes
- **Auto-Sync**: Deploys changes automatically
- **Self-Healing**: Corrects manual changes back to Git state
- **Pruning**: Removes resources deleted from Git

## 🛡️ Security Features

### **🔒 Sealed Secrets Encryption**
All sensitive data encrypted with **asymmetric cryptography**:

#### Gmail SMTP Credentials
```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: gmail-smtp-secret
spec:
  encryptedData:
    smtp_auth_password: AgB2v6fWKTwZ4gHc... # Fully encrypted!
```

#### Slack Webhook URL
```yaml
apiVersion: bitnami.com/v1alpha1  
kind: SealedSecret
metadata:
  name: slack-webhook-secret
spec:
  encryptedData:
    slack_api_url: AgBxh3MqBRXeKs6U... # Fully encrypted!
```

### **🔐 Ansible Vault**
- **Vault Protection**: Sealed Secrets private keys stored in Ansible Vault
- **Double Encryption**: Vault-encrypted files contain encryption keys
- **Secure Deployment**: `--ask-vault-pass` required for deployment

## 🚀 Getting Started

### **Prerequisites**
- Ubuntu server (local or cloud)
- SSH access to target server
- Ansible installed locally

### **1. Server Setup**

#### **Inventory Configuration**
Create `inventory.ini`:
```ini
[servers]
my-ec2 ansible_host=52.47.164.150 ansible_user=ubuntu ansible_ssh_private_key_file=/home/abdelrahman/Downloads/ssh.pem
```

#### **SSH Key Requirements**  
- **AWS EC2**: Use your `.pem` key file
- **Other Providers**: Use appropriate SSH private key
- **Local Server**: Configure SSH key access

### **2. Ansible Deployment**

#### **Run the Playbook**
```bash
# Deploy complete infrastructure
ansible-playbook -i inventory.ini play.yml --ask-vault-pass

# Enter vault password when prompted
```

#### **What Happens:**
1. **Infrastructure Setup**: Docker, Kubernetes, Helm installed
2. **Security Layer**: Sealed Secrets controller deployed
3. **Monitoring Stack**: Prometheus, Grafana, AlertManager configured  
4. **GitOps Engine**: ArgoCD deployed with auto-sync enabled
5. **Application Deployment**: Pet Clinic app automatically deployed



#### **Service URLs**
- **ArgoCD UI**: `http://SERVER_IP:32080` (admin/admin)
- **Grafana**: `http://SERVER_IP:32000` (admin/admin)  
- **Pet Clinic App**: `http://SERVER_IP:35000` 

## 📊 Monitoring & Alerting

### **📈 Grafana Dashboards**
- **Pre-installed**: ArgoCD monitoring dashboard (ID: 14584)
- **Automatic Import**: No manual configuration needed
- **Real-time Metrics**: Application sync status, deployment health

### **🚨 Alert Channels**
- **📧 Email**: Detailed HTML alerts to Gmail
- **📱 Slack**: Channel notifications with status updates
- **🔄 State Changes**: Notifications for sync/out-of-sync transitions

### **📊 Key Metrics**
- Application sync status
- Deployment success/failure rates
- Resource utilization
- Service availability

## 🔄 GitOps Workflow

1. **Code Change** → CI Pipeline builds and pushes image
2. **Manifest Update** → CI updates Kubernetes manifests in Git
3. **ArgoCD Detection** → Detects Git changes within seconds
4. **Automatic Sync** → Deploys changes to cluster
5. **Health Monitoring** → Continuous health checks
6. **Alert Generation** → Notifications for any issues


## ✨ Key Advantages

- **🚀 Zero-Touch Deployment**: Complete infrastructure in one command
- **🔒 Enterprise Security**: Encrypted secrets, not base64 encoding  
- **📊 Built-in Monitoring**: Prometheus + Grafana + AlertManager ready
- **🔄 True GitOps**: Automatic sync with self-healing capabilities
- **📱 Multi-Channel Alerts**: Email + Slack notifications
- **🎯 Production Ready**: Optimized resource allocation and networking
- **🔧 Minimal Maintenance**: Self-managing infrastructure

---

**This CD setup provides enterprise-grade infrastructure automation with GitOps, monitoring, and security built-in from day one!** 🏆