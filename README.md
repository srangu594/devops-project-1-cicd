# Project 1 — Dockerized CI/CD with Jenkins + GitHub

## What You Learn
- Writing a multi-stage Dockerfile (tests run in Stage 1, production in Stage 2)
- Building a declarative Jenkins pipeline from scratch
- GitHub Webhooks to auto-trigger builds on every push
- Pushing Docker images to Docker Hub from a pipeline
- Remote SSH deployment with automatic rollback on failure

## Stack
`Flask` · `Docker` · `Jenkins` · `GitHub` · `Docker Hub` · `EC2`

## Setup

### Step 1 — Edit Jenkinsfile
Replace `YOUR_DOCKERHUB_USERNAME` on line 6 with your Docker Hub username.

### Step 2 — Jenkins EC2 (t2.medium, Amazon Linux 2) 
```bash
sudo yum update -y
sudo yum install java-11-amazon-corretto git docker -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install jenkins -y
sudo systemctl start jenkins docker
sudo systemctl enable jenkins docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
Open http://JENKINS-IP:8080 and complete setup.
Install plugins: Docker Pipeline, GitHub Integration, Credentials Binding.

### Step 3 — Jenkins Credentials
| ID | Type | Value |
|---|---|---|
| `dockerhub-credentials` | Username + Password | Docker Hub login |
| `deploy-server-ip` | Secret Text | Deploy EC2 IP |
| `deploy-ssh-key` | SSH private key | Contents of .pem file |

### Step 4 — Create Pipeline Job
- New Item → Pipeline → Name: `project1-pipeline`
- Pipeline Definition: `Pipeline script from SCM`
- SCM: Git → your repo URL → Branch: `*/main`
- Script Path: `Jenkinsfile`
- Build Triggers: ✓ `GitHub hook trigger for GITScm polling`

### Step 5 — GitHub Webhook
```
Repo → Settings → Webhooks → Add webhook
Payload URL: http://JENKINS-IP:8080/github-webhook/
Content type: application/json
Events: Just the push event
```

### Step 6 — Deploy EC2 (t2.micro, Amazon Linux 2)
```bash
sudo yum install docker -y
sudo systemctl start docker && sudo systemctl enable docker
```

### Test Locally
```bash
pip install -r app/requirements.txt
python -m pytest tests/ -v
docker build -t project1-test .
docker run -p 5000:5000 project1-test
curl http://localhost:5000/health
```

### Trigger the Pipeline
```bash
echo "# bump" >> app/app.py
git add . && git commit -m "trigger pipeline" && git push origin main
```

## What Happens on Push
1. GitHub sends webhook → Jenkins auto-triggers
2. Docker builds image → runs tests in Stage 1
3. Trivy scans image for CVEs
4. Image pushed to Docker Hub with build number tag
5. SSH into deploy EC2 → stops old container → starts new one
6. Health check confirms /health returns 200
7. If anything fails → auto-rollback to previous build
========

this is to check webhook working and this is final commit


=======
