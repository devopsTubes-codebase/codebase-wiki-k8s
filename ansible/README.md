# Ansible Provisioning - Codebase Wiki K8s

Provisioning otomatis untuk setup Kubernetes cluster dengan Docker, Minikube, kubectl, dan Helm.

## Support OS

✅ **Ubuntu 20.04 / 22.04** (Debian-based)  
✅ **AlmaLinux 8 / 9** (RedHat-based)  
✅ **Auto-detect** OS family dan gunakan task yang sesuai

## Prerequisites

### Control Node (Ansible master)
- Ansible 2.9+
- SSH access ke managed hosts
- Python 3.6+

### Managed Hosts (Target servers)
- RAM minimal: 8GB (untuk Minikube + workload)
- CPU: 2 cores minimum
- Disk: 20GB free space
- SSH enabled dengan sudo access
- Python 3 installed

## Setup

### 1. Install Ansible di Control Node

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install ansible -y
```

**AlmaLinux/RHEL:**
```bash
sudo dnf install epel-release -y
sudo dnf install ansible -y
```

**macOS:**
```bash
brew install ansible
```

### 2. Configure Inventory

Edit `inventory.ini` dan sesuaikan dengan server kamu:

```ini
[control_node]
localhost ansible_connection=local

[managed_hosts]
vps1 ansible_host=YOUR_VPS_IP ansible_user=YOUR_USERNAME ansible_ssh_private_key_file=~/.ssh/id_rsa
```

**Contoh untuk Ubuntu VPS:**
```ini
[control_node]
localhost ansible_connection=local

[managed_hosts]
codebase-wiki-prod ansible_host=103.127.132.123 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### 3. Test Koneksi SSH

```bash
ansible managed_hosts -i inventory.ini -m ping
```

Expected output:
```
vps1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 4. Run Playbook

**Dry-run (check mode):**
```bash
ansible-playbook -i inventory.ini playbook-setup.yml --check
```

**Actual run:**
```bash
ansible-playbook -i inventory.ini playbook-setup.yml
```

**Dengan sudo password prompt:**
```bash
ansible-playbook -i inventory.ini playbook-setup.yml --ask-become-pass
```

**Verbose mode (untuk debugging):**
```bash
ansible-playbook -i inventory.ini playbook-setup.yml -vvv
```

## Roles

### 1. Docker
- Auto-detect OS (Ubuntu atau AlmaLinux)
- Install Docker CE + Docker Compose
- Configure Docker daemon
- Add user ke docker group

### 2. Minikube
- Download Minikube binary (ARM64 / x86_64)
- Install ke `/usr/local/bin/`
- Verify installation

### 3. kubectl
- Download kubectl binary (sesuai arch)
- Install ke `/usr/local/bin/`
- Configure autocomplete (optional)

### 4. Helm
- Download Helm install script
- Install Helm 3
- Verify installation

## Post-Installation

### 1. Verify Installations

SSH ke managed host dan run:

```bash
docker --version
minikube version
kubectl version --client
helm version
```

### 2. Start Minikube

```bash
minikube start --driver=docker --cpus=2 --memory=6144
```

**Untuk production (lebih banyak resources):**
```bash
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=50g
```

### 3. Verify Kubernetes Cluster

```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

### 4. Setup Namespaces

```bash
# Clone K8s config repo
git clone https://github.com/devopsTubes-codebase/codebase-wiki-k8s.git
cd codebase-wiki-k8s

# Create namespaces
kubectl apply -f k8s/namespaces/
```

### 5. Install ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Akses: https://localhost:8080
```

### 6. Deploy Application via ArgoCD

```bash
kubectl apply -f argocd/application.yaml
```

### 7. Install Monitoring Stack

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/prometheus-values.yaml \
  --wait

# Install Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana \
  --namespace monitoring \
  --values monitoring/grafana-values.yaml \
  --wait

# Apply dashboards
kubectl apply -f monitoring/grafana-dashboards-configmap.yaml
```

## Troubleshooting

### Ansible cannot connect

```bash
# Test SSH manually
ssh -i ~/.ssh/id_rsa ubuntu@YOUR_VPS_IP

# Check SSH config
ansible managed_hosts -i inventory.ini -m ping -vvv
```

### Docker installation fails

```bash
# Check OS version
ansible managed_hosts -i inventory.ini -m setup -a "filter=ansible_distribution*"

# Manual cleanup and retry
ssh ubuntu@YOUR_VPS_IP
sudo apt remove docker docker-engine docker.io containerd runc
sudo apt autoremove
```

### Minikube won't start

```bash
# Check Docker is running
sudo systemctl status docker

# Start with verbose logging
minikube start --driver=docker --alsologtostderr -v=7

# Reset Minikube
minikube delete
minikube start --driver=docker
```

### Permission denied (docker)

```bash
# Re-login untuk apply group membership
exit
ssh ubuntu@YOUR_VPS_IP

# Or manual fix
sudo usermod -aG docker $USER
newgrp docker
```

## Architecture Detection

Playbook otomatis detect:
- **OS Family**: Ubuntu (Debian) vs AlmaLinux (RedHat)
- **Architecture**: ARM64 vs x86_64
- **Package Manager**: apt vs dnf

## Security Notes

1. **SSH Keys**: Gunakan SSH key, jangan password
2. **Sudo Access**: User harus punya sudo privilege
3. **Firewall**: Pastikan port SSH (22) dan K8s ports terbuka
4. **Docker Group**: User di docker group = root equivalent, hati-hati
5. **Minikube**: Jangan expose ke internet, gunakan di private network

## CI/CD Integration

Setelah infrastructure ready:
1. Push code ke GitHub → trigger CI/CD
2. CI/CD build image → push ke Docker Hub
3. CI/CD update K8s manifests di `codebase-wiki-k8s`
4. ArgoCD detect changes → auto-sync ke cluster
5. Prometheus scrape metrics → Grafana visualize

## Maintenance

### Update components

```bash
# Re-run playbook untuk update ke latest version
ansible-playbook -i inventory.ini playbook-setup.yml --tags docker,kubectl,helm
```

### Backup configuration

```bash
# Backup Minikube profile
minikube stop
tar -czf minikube-backup.tar.gz ~/.minikube

# Backup kubectl config
cp ~/.kube/config ~/.kube/config.backup
```

## Contact

Untuk bantuan atau issues, buat issue di repo atau kontak team.
