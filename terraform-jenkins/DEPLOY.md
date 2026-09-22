# Deploying via Jenkins — Step by Step

This provisions a real Jenkins server on EC2, wired into the `taskboard-eks`
cluster and ECR repo you already have, then walks you through running the
actual pipeline.

## 0. Why you're running this yourself

I generated and validated all the Terraform/IAM/bootstrap logic here, but I
don't have a working execution path to your AWS account right now — the
tool that would let me run this directly returned an approval error I
couldn't get past. Rather than guess blindly against your real
infrastructure, everything below is ready to run as-is; it should take
about 10-15 minutes end-to-end.

## 1. Apply the Jenkins infrastructure

```bash
cd taskboard/terraform-jenkins

# IMPORTANT: restrict this before applying, or anyone on the internet
# can hit your Jenkins UI:
#   -var="allowed_ui_cidr=<your-ip>/32"
# Find your IP: curl -s ifconfig.me

terraform init
terraform plan  -var="allowed_ui_cidr=$(curl -s ifconfig.me)/32"
terraform apply -var="allowed_ui_cidr=$(curl -s ifconfig.me)/32"
```

This creates:
- An EC2 instance (`t3.medium`, Ubuntu 22.04) in the **existing** taskboard
  VPC's public subnet — it does not touch your EKS nodes or networking.
- An IAM role with ECR push access + an EKS **access entry** granting that
  role `AmazonEKSClusterAdminPolicy` on `taskboard-eks` (no manual
  `aws-auth` ConfigMap editing needed).
- A security group open on 8080 (Jenkins UI) only to the CIDR you pass in.
- A bootstrap script (`user_data.sh`) that installs: Jenkins LTS, Docker,
  AWS CLI v2, kubectl v1.29, eksctl, Trivy, Node.js 20, and sonar-scanner —
  everything the `Jenkinsfile` needs, already on the box.

Boot + bootstrap takes ~3-5 minutes after `apply` finishes. Note the
`jenkins_url` output.

## 2. Get the initial admin password

Via SSM (no SSH key needed — the IAM role already grants this):

```bash
aws ssm start-session --target $(terraform output -raw jenkins_instance_id)
# once connected:
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
exit
```

## 3. First-time Jenkins setup (in the browser)

1. Open `http://<jenkins_public_ip>:8080`, paste the admin password.
2. Install suggested plugins, then also add: **Docker Pipeline**,
   **Amazon ECR**, **SonarQube Scanner**, **Kubernetes CLI**, **Slack
   Notification** (if you want alerts).
3. Create your admin user when prompted.

## 4. Configure credentials & tools in Jenkins

**Manage Jenkins → Credentials → (global):**
- `AWS_ACCOUNT_ID` — Secret text — your 12-digit account ID (not a secret
  really, but keeps the Jenkinsfile clean).
- Since the EC2 instance already has an IAM role attached, you do **not**
  need to store AWS access keys — `aws`/`kubectl`/`docker` on the box
  inherit permissions automatically via the instance profile.
- `sonar-token` — Secret text — generate this in your SonarQube server
  under **My Account → Security → Generate Token**.

**Manage Jenkins → System → SonarQube servers:**
- Name it `sonarqube-server` (matches the `Jenkinsfile`'s
  `withSonarQubeEnv('sonarqube-server')`), point it at your SonarQube URL,
  and select the `sonar-token` credential.

  > You still need a SonarQube server reachable from this box. Fastest
  > option: run it as a container on the same EC2 host —
  > `docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community`
  > then use `http://localhost:9000` as the server URL.

## 5. Create the pipeline job

1. **New Item → Pipeline**, name it `taskboard`.
2. Under **Pipeline**, choose **Pipeline script from SCM** → Git → paste
   your repo URL → branch `main` → script path `Jenkinsfile`.
3. In the `Jenkinsfile`, replace:
   - `<your-username>` in the `Checkout` stage's git URL
   - `${AWS_ACCOUNT_ID}` — either set it as a Jenkins env var or hardcode
     your account ID in the `ECR_REPO` line
4. Save.

## 6. Wire up the GitHub webhook

In your GitHub repo → **Settings → Webhooks → Add webhook**:
- Payload URL: `http://<jenkins_public_ip>:8080/github-webhook/`
- Content type: `application/json`
- Event: **Just the push event**

## 7. Run it

- Push a commit, or click **Build Now** on the `taskboard` job manually
  for the first run.
- Watch **Console Output** — it will walk through all 9 stages: checkout,
  build/test, SonarQube, Trivy (fs), Docker build, Trivy (image), push to
  ECR, deploy to EKS.
- Verify the rollout from your own machine:
  ```bash
  aws eks update-kubeconfig --name taskboard-eks --region ap-south-1
  kubectl get pods
  kubectl get deployment taskboard
  ```

## 8. Clean-up reminder

This adds one more billable EC2 instance on top of the EKS nodes. When
you're done for the day:

```bash
cd taskboard/terraform-jenkins && terraform destroy
cd ../terraform && terraform destroy
```

## If something fails

- **Pipeline can't reach ECR/EKS** — check the instance actually has the
  IAM role attached: `aws ec2 describe-instances --instance-ids <id>
  --query 'Reservations[0].Instances[0].IamInstanceProfile'`
- **kubectl: Unauthorized** — the access entry (`iam.tf`) needs a minute or
  two to propagate after `apply`; also confirm you ran
  `aws eks update-kubeconfig` on the Jenkins box itself (Jenkins runs as
  the `jenkins` OS user — the pipeline's `sh` steps already do this).
- **Trivy/SonarQube stage hangs** — the SonarQube container needs a
  minute to start up the first time; retry the build once `docker logs
  sonarqube` shows it's ready.
