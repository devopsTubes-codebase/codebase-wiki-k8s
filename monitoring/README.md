# Panduan Instalasi Grafana - Codebase Wiki
# ==========================================
# Prasyarat: Prometheus sudah terinstall di namespace monitoring (Anggota 6)

# 1. Tambah Helm repo
# helm repo add grafana https://grafana.github.io/helm-charts
# helm repo update

# 2. Install Grafana
# helm install grafana grafana/grafana \
#   --namespace monitoring \
#   --values grafana-values.yaml \
#   --wait

# 3. Apply dashboard ConfigMap
# kubectl apply -f grafana-dashboards-configmap.yaml

# 4. Verifikasi
# kubectl get pods -n monitoring | grep grafana
# kubectl get svc -n monitoring | grep grafana

# 5. Akses Grafana UI
# kubectl port-forward svc/grafana 3001:80 -n monitoring
# Buka http://localhost:3001
# Login: admin / admin123

# 6. Verifikasi Data Source
# Configuration > Data Sources > Prometheus > "Save & Test" harus connected

# 7. Verifikasi Dashboard
# Browse > Dashboards > folder "Codebase Wiki"
# Harus ada 2 dashboard:
#   - Backend Metrics (request rate, latency, CPU, memory, health)
#   - Kubernetes Pods (status, restarts, network I/O)

# 8. Generate traffic untuk test
# kubectl port-forward svc/frontend-svc 3000:3000 -n codebase-wiki
# Browse aplikasi -> metrics harus muncul di Grafana dashboard
