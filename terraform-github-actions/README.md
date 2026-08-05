Below is a README you can save as `README.md` in the repository.

```md
# Terraform CI/CD with GitHub Actions

This project runs Terraform commands using GitHub Actions. It can use either:

1. A GitHub-hosted Ubuntu runner (`ubuntu-latest`)
2. A self-hosted runner installed on an AWS EC2 instance (`self-hosted`)

## Current pipeline

The workflow is located at:

`.github/workflows/terraform.yml`

It currently uses a self-hosted runner and can be triggered manually from the GitHub Actions tab.

```yaml
name: CI Pipeline on Self-Hosted Runner

on:
  workflow_dispatch:

jobs:
  terraform:
    runs-on: self-hosted
```

- `name`: Friendly pipeline name displayed in GitHub Actions.
- `on`: Defines when the workflow runs.
- `workflow_dispatch`: Enables the **Run workflow** button for manual execution.
- `jobs`: Defines one or more jobs.
- `runs-on: self-hosted`: Runs the job on a machine you manage, such as an EC2 instance.

## Pipeline steps

```yaml
steps:
  - name: Checkout Code
    uses: actions/checkout@v4
```

Downloads the repository source code onto the runner.

```yaml
- name: Terraform Init
  run: terraform init
```

Initializes Terraform. It downloads providers and configures the Terraform backend.

```yaml
- name: Terraform Plan
  run: terraform plan
```

Shows the infrastructure changes Terraform plans to make. It does not create, modify, or delete resources.

```yaml
- name: Terraform Apply
  run: terraform apply -auto-approve
```

Applies the Terraform changes automatically.

> Warning: `-auto-approve` skips the manual Terraform confirmation. Use it carefully, especially in production.



## Option 1: GitHub-hosted Ubuntu runner

GitHub provides an ephemeral virtual machine for each workflow run.

```yaml
runs-on: ubuntu-latest
```

Example workflow:

```yaml
name: Terraform CI Pipeline

on:
  workflow_dispatch:
  push:
    branches:
      - main

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Terraform init
        run: terraform init

      - name: Terraform plan
        run: terraform plan

      - name: Terraform apply
        run: terraform apply -auto-approve
```

### How GitHub-hosted runners work

1. GitHub creates a fresh Ubuntu VM.
2. The repository is checked out.
3. Terraform is installed through `hashicorp/setup-terraform`.
4. AWS credentials are retrieved from GitHub Secrets.
5. Terraform commands run.
6. GitHub destroys the VM after the job completes.

### Limitations of GitHub-hosted runners

- The runner is temporary; files installed or created during a run are removed afterward.
- You cannot directly access private AWS resources unless network access is configured, such as through a public endpoint or supported private networking setup.
- Available CPU, memory, disk, and job duration are controlled by GitHub and your GitHub plan.
- AWS credentials must be supplied securely, preferably using GitHub OIDC rather than long-lived access keys.
- Installed tools or custom configurations must be recreated for every run.

## Option 2: Self-hosted EC2 runner

A self-hosted runner is an EC2 instance that you configure and connect to GitHub Actions.

```yaml
runs-on: self-hosted
```

You can also use labels to select a particular runner:

```yaml
runs-on: [self-hosted, Linux, terraform]
```

### Self-hosted runner requirements

Your EC2 instance needs:

- Linux operating system, commonly Ubuntu.
- Git installed.
- Terraform installed.
- GitHub Actions runner software installed and registered.
- Network access to GitHub.
- AWS permissions, preferably through an EC2 IAM role.
- Appropriate security-group and IAM configuration.

### Configure an EC2 self-hosted runner

1. Launch an Ubuntu EC2 instance.
2. Attach an IAM role with only the AWS permissions Terraform requires.
3. In GitHub, open:

   `Repository → Settings → Actions → Runners → New self-hosted runner`

4. Choose Linux and copy the displayed setup commands.
5. Run the commands on the EC2 instance to download and register the runner.
6. Install Terraform on the EC2 instance.
7. Start the runner service.
8. Confirm that the runner appears as **Idle** in GitHub.

Example registration commands supplied by GitHub generally look like:

```bash
./config.sh --url https://github.com/OWNER/REPOSITORY --token TOKEN
./run.sh
```

For a persistent runner, configure it as a service:

```bash
sudo ./svc.sh install
sudo ./svc.sh start
```

### AWS authentication on EC2

For EC2, use an IAM role instead of storing AWS access keys in GitHub Secrets.

Terraform and the AWS CLI can then use the instance role automatically.

```yaml
- name: Terraform Init
  run: terraform init

- name: Terraform Plan
  run: terraform plan

- name: Terraform Apply
  run: terraform apply -auto-approve
```

No `configure-aws-credentials` step is required when the EC2 instance has a correctly configured IAM role.

## GitHub-hosted vs self-hosted EC2 runner

| Feature | GitHub-hosted Ubuntu | Self-hosted EC2 |
|---|---|---|
| Managed by | GitHub | Your team |
| Machine lifetime | New VM per job | Persistent EC2 instance |
| Terraform installation | Install in workflow | Install once on EC2 |
| AWS authentication | GitHub Secrets or OIDC | Prefer EC2 IAM role |
| Private VPC access | Limited/configuration required | Easy when EC2 is in the VPC |
| Maintenance | GitHub handles OS maintenance | You patch and secure the server |
| Cost | Depends on GitHub plan and usage | EC2, storage, and networking costs |
| Security responsibility | Shared with GitHub | Mostly your responsibility |
| Best for | Simple, isolated CI/CD | Private infrastructure and custom tooling |

## Recommended security improvements

- Use separate `plan` and `apply` jobs.
- Protect production with GitHub Environments and required approvals.
- Use EC2 IAM roles for self-hosted runners.
- Use GitHub OIDC for GitHub-hosted runners instead of permanent AWS access keys.
- Do not give Terraform unrestricted AWS administrator permissions.
- Add runner labels, for example `terraform`, `dev`, or `production`.
- Do not expose a self-hosted runner unnecessarily; treat it as a sensitive deployment machine.

## Recommended workflow trigger

For safer Terraform automation:

```yaml
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  workflow_dispatch:
```

Recommended behavior:

- Pull request: run `terraform fmt`, `terraform validate`, and `terraform plan`.
- Push to `main`: run the approved `terraform apply`.
- Manual trigger: use only for controlled deployments or testing.
```

