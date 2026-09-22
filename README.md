# TaskBoard — AWS DevSecOps CI/CD Pipeline Project

Sample Node.js app + full pipeline: GitHub -> Jenkins -> SonarQube -> Trivy ->
Docker -> Amazon ECR -> EKS -> Prometheus/Grafana -> Alerts

## Layout

```
taskboard/
├── src/, test/, Dockerfile, Jenkinsfile, sonar-project.properties, package.json
├── k8s/                     # Deployment, Service, Ingress, Alertmanager config
├── terraform/               # Core infra: VPC, EKS, ECR, IAM
└── terraform-jenkins/       # Jenkins EC2 server + IAM + EKS access entry
    └── DEPLOY.md            # <-- Start here to actually run the pipeline
```

## Quick start

1. `terraform/` — stand up VPC + EKS + ECR (see main build guide).
2. `terraform-jenkins/` — stand up the Jenkins box itself. Read
   `terraform-jenkins/DEPLOY.md` for the exact commands and the full
   first-run walkthrough (get admin password, install plugins, configure
   credentials, create the pipeline job, wire the GitHub webhook).
3. Push this repo to GitHub, point the Jenkins job at it, click **Build
   Now** (or push a commit) — the `Jenkinsfile` runs all 9 pipeline
   stages end-to-end.

## Local development (before touching AWS at all)

```bash
npm install
npm test
npm start
curl localhost:3000/health
```

## Monitoring

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80
```

## Cost control

```bash
cd terraform-jenkins && terraform destroy
cd ../terraform        && terraform destroy
```
