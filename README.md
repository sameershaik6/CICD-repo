# Jenkins CI/CD README

This repository contains simple Jenkins pipeline examples for CI/CD and Terraform automation.

## 1. What is Jenkins?

Jenkins is an open-source automation server used for:

- Building and testing code
- Running CI/CD pipelines
- Deploying applications and infrastructure
- Automating Terraform and cloud tasks
- Working with Git, GitHub, AWS, Docker, Kubernetes, and more

Jenkins is commonly used to automate the full software delivery process.

---

## 2. Jenkins use cases

Jenkins is used for:

- Continuous Integration (CI): build and test code automatically
- Continuous Delivery/Deployment (CD): deploy to dev, test, staging, or production
- Infrastructure automation: run Terraform, Ansible, shell scripts, and cloud commands
- Multi-stage pipelines: checkout -> build -> test -> deploy

In this repo, Jenkins is used to run Terraform commands such as:

- terraform init
- terraform validate
- terraform fmt -check
- terraform plan
- terraform apply
- terraform destroy

---

## 3. Jenkins installation process

### Prerequisites
Before installing Jenkins, make sure these are available:

- Java (Jenkins requires Java)
- Git
- Terraform
- AWS CLI (if using AWS)
- A server or machine where Jenkins will run

### Common installation on Ubuntu/Linux

```bash
sudo apt update
sudo apt install openjdk-17-jdk -y
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

### Check Jenkins status

```bash
sudo systemctl status jenkins
```

### Get the initial admin password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Access Jenkins
Open your browser at:

```text
http://localhost:8080
```

Then:

1. Paste the initial admin password
2. Install suggested plugins
3. Create the first admin user
4. Start using Jenkins

### Recommended plugins
Install these plugins in Jenkins:

- Git Plugin
- Pipeline Plugin
- GitHub Integration Plugin
- AWS Credentials Plugin
- Terraform Plugin (optional, but helpful)

---

## 4. Prerequisites to run Terraform from Jenkins

To run Terraform from Jenkins, the Jenkins node must have the following available:

### Required tools

- Terraform installed on the Jenkins machine or agent
- Git installed
- AWS CLI installed (recommended)
- Proper permissions to access the Git repository

### AWS prerequisites
If Terraform will create AWS resources, Jenkins needs credentials or an IAM role.

### Best practice: use an IAM role
If Jenkins is running on an EC2 instance, attach an IAM role to that instance.

Example role name:

```text
jenkins-terraform-role
```

### Example IAM permissions for Terraform learning projects
For a basic VPC/subnet example, you can use a role with policies such as:

- AmazonVPCFullAccess
- AmazonEC2FullAccess
- IAMFullAccess (only if Terraform creates IAM resources)

For production, use least-privilege permissions instead of full access.

### Alternative: use AWS credentials in Jenkins
You can also store credentials in Jenkins:

- AWS Access Key ID
- AWS Secret Access Key
- Region (for example, us-east-1)

Then export them in the pipeline if needed:

```groovy
withEnv(["AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}", "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"]) {
    sh 'terraform init'
}
```

> For learning and practice, an EC2 instance with an attached IAM role is usually the simplest option.

---

## 5. Jenkins pipeline types

### A. Scripted Pipeline

Scripted pipelines are written in Groovy and use a more flexible style.

Example structure:

```groovy
node {
    stage('Build') {
        echo 'Building...'
    }
}
```

Features:

- Very flexible
- Uses Groovy syntax
- Good for advanced custom logic
- Works with `node {}` blocks

### B. Declarative Pipeline

Declarative pipelines use a more structured syntax with a clear pipeline block.

Example structure:

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
    }
}
```

Features:

- Easier to read and maintain
- Recommended for beginners and teams
- Safer and more structured
- Uses `pipeline {}`, `stages {}`, `steps {}`

### Difference between scripted and declarative pipelines

| Type | Style | Best for |
|------|------|----------|
| Scripted | Groovy-based, flexible | Advanced automation and custom logic |
| Declarative | Structured, clean syntax | Readable pipelines and team use |

In short:

- Use declarative pipeline for most standard CI/CD jobs
- Use scripted pipeline when you need more control and Groovy logic

---

## 6. Parameters in Jenkins

Jenkins pipelines can accept user input using parameters.

### Example: choice parameter

```groovy
parameters {
    choice(
        name: 'ACTION',
        choices: ['apply', 'destroy'],
        description: 'Select the Terraform action'
    )
}
```

This allows the user to choose whether to run Terraform apply or destroy at runtime.

---

## 7. Running on a specific node/agent label

You can assign a pipeline to run only on a specific Jenkins agent.

### Scripted example

```groovy
node('dev') {
    stage('Checkout') {
        echo 'Running on dev node'
    }
}
```

### Declarative example

```groovy
pipeline {
    agent { label 'dev' }
    stages {
        stage('Build') {
            steps {
                echo 'Running on labeled agent'
            }
        }
    }
}
```

This is useful when you want different machines for:

- Dev jobs
- Test jobs
- Prod jobs
- Terraform-only agents

---

## 8. Conditions in Jenkins pipelines

### Example with branch condition

```groovy
if (env.BRANCH_NAME == 'main') {
    echo 'Deploy to production'
}
```

### Example with if/else

```groovy
if (environment == 'dev') {
    echo 'Deploy to DEV'
} else {
    echo 'Deploy to PROD'
}
```

### Example with loop

```groovy
def services = ['auth', 'payment', 'orders']
for (svc in services) {
    stage("Build ${svc}") {
        echo "Building ${svc}"
    }
}
```

These conditions help you control flow based on branch names, environment values, or user input.

---

## 9. Examples in this repository

### A. Scripted pipeline example
File: [groovy/jenkinsfile](groovy/jenkinsfile)

This file contains:

- Basic scripted pipeline examples
- If/else logic
- For loop examples
- Choice parameters
- Terraform workflow example
- Specific node label example

### B. Declarative pipeline example
File: [pipelinefromSCM-jenkins/jenkinsfile](pipelinefromSCM-jenkins/jenkinsfile)

This file shows a declarative pipeline with:

- `pipeline {}`
- `agent any`
- `parameters {}`
- `stages {}`
- `steps {}`
- Terraform init/validate/plan/apply/destroy

### C. Terraform Jenkins example
File: [day-1-terraform-jenkins/terraform-jenkinsfile](day-1-terraform-jenkins/terraform-jenkinsfile)

This is a Terraform-focused pipeline example that demonstrates:

- Checkout from Git
- terraform init
- terraform validate
- terraform fmt -check
- terraform plan
- manual approval
- terraform apply

### D. Terraform configuration example
File: [terraform-file/main.tf](terraform-file/main.tf)

This sample Terraform file creates:

- A VPC
- Public subnets

This is a good example for testing Jenkins + Terraform automation.

---

## 10. Example Jenkins job setup

To use one of these pipelines:

1. Open Jenkins
2. Create a new item
3. Choose Pipeline
4. Under Definition, choose Pipeline script from SCM
5. Provide your Git repository URL
6. Set the Jenkinsfile path
7. Save and build

For this repo, you can point Jenkins to:

- Repository: your GitHub repository URL
- Jenkinsfile path: `groovy/jenkinsfile` or `pipelinefromSCM-jenkins/jenkinsfile`

---

## 11. Simple Terraform pipeline example

```groovy
pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Select Terraform action'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sameershaik6/CICD-repo.git'
            }
        }

        stage('Init') {
            steps {
                dir('terraform-file') {
                    sh 'terraform init'
                }
            }
        }

        stage('Plan') {
            steps {
                dir('terraform-file') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Approval') {
            steps {
                input 'Approve Terraform Apply?'
            }
        }

        stage('Apply or Destroy') {
            steps {
                script {
                    if (params.ACTION == 'apply') {
                        dir('terraform-file') {
                            sh 'terraform apply -auto-approve'
                        }
                    } else {
                        dir('terraform-file') {
                            sh 'terraform destroy -auto-approve'
                        }
                    }
                }
            }
        }
    }
}
```

---

## 12. Key takeaway

Jenkins is a powerful automation server used for:

- CI/CD pipelines
- Build and test automation
- Terraform infrastructure automation
- Parameterized and conditional pipelines
- Running jobs on specific agents/nodes

For your repository, the main learning points are:

- Scripted pipeline syntax
- Declarative pipeline syntax
- Choice parameters
- Node/agent labels
- Conditional logic
- Terraform automation with Jenkins

---

## 13. Recommended next steps

To practice further:

1. Install Jenkins on a VM or local machine
2. Install Git and Terraform
3. Configure AWS access
4. Create a Pipeline job in Jenkins
5. Point it to one of the Jenkinsfiles in this repo
6. Run the pipeline and observe the output

If you want, the next step can be to add a full Jenkinsfile for AWS EKS, Docker deployment, or a production-style Terraform pipeline.
