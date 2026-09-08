# TaskBoard — AWS DevSecOps CI/CD Pipeline Project

Sample Node.js app + full pipeline: **GitHub → Jenkins → SonarQube → Trivy →
Docker → Amazon ECR → EKS → Prometheus/Grafana → Alerts**

See `AWS-DevSecOps-CICD-Project-Guide.md` (in the parent chat) for the full
phase-by-phase build walkthrough. Quick start below.

## Local development

```bash
npm install
npm test
npm start
curl localhost:3000/health
```

## Docker

```bash
docker build -t taskboard:local .
docker run -p 3000:3000 taskboard:local
```

## Infrastructure (Terraform)

```bash
cd terraform
terraform init
terraform apply
aws eks update-kubeconfig --name taskboard-eks --region ap-south-1
kubectl get nodes
```

> Destroy when done for the day to avoid ongoing EKS/NAT gateway charges:
> `terraform destroy`

## Deploy manually (before wiring up Jenkins)

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl get pods
```

## CI/CD

Point a Jenkins pipeline job at this repo — it will pick up the `Jenkinsfile`
automatically. Configure a GitHub webhook to `<jenkins-url>/github-webhook/`
so pushes trigger builds.

Required Jenkins credentials/env:
- `AWS_ACCOUNT_ID` (used to build the ECR repo URL)
- AWS credentials with ECR push + EKS deploy permissions (prefer an
  instance profile / IAM role over static keys)
- `sonar-token` credential for the SonarQube server

## Monitoring

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace

kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80
```

Grafana login: `admin` / `prom-operator` (change this in production).

## Project structure

```
taskboard/
├── src/app.js              # Express app (health + metrics endpoints)
├── src/routes/tasks.js     # Reserved for route splitting
├── test/app.test.js        # Jest + Supertest unit tests
├── Dockerfile               # Multi-stage, non-root image
├── Jenkinsfile              # Full 9-stage pipeline
├── sonar-project.properties
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── alertmanager-config.yaml
└── terraform/
    ├── main.tf
    ├── vpc.tf
    ├── eks.tf
    ├── ecr.tf
    ├── iam.tf
    └── variables.tf
```
