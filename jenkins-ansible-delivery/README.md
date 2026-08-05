# Jenkins and Ansible Application Delivery Pipeline

## What This Does

This implementation provides an end-to-end application delivery pipeline that uses Jenkins to validate, execute, and verify Ansible-based deployments.

Jenkins coordinates pipeline preparation, Ansible syntax validation, connectivity testing, controlled deployment, application verification, metadata validation, and health checks. Ansible configures Nginx, renders deployment-specific application content, manages the virtual host, and confirms the service is operational.

The workflow demonstrates how CI/CD orchestration and configuration automation can be combined to create repeatable, traceable, and secure software delivery processes.

## Architecture

    ┌───────────────────────────────────────────────────────────────┐
    │                       Jenkins Controller                      │
    │                                                               │
    │  Parameterized Pipeline                                      │
    │  Build Number                                                │
    │  Target Environment                                          │
    │  Application Version                                         │
    │  Optional Test Control                                       │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    │ Pipeline execution
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                      Validation Layer                         │
    │                                                               │
    │  Ansible Syntax Check                                        │
    │  Inventory Validation                                        │
    │  Local Connectivity Test                                     │
    │  Parameter Validation                                        │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    │ Controlled sudo wrapper
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                    Ansible Deployment Layer                   │
    │                                                               │
    │  Install and Configure Nginx                                 │
    │  Render Application Template                                 │
    │  Create Application Directory                                │
    │  Enable Nginx Virtual Host                                   │
    │  Validate Configuration                                      │
    │  Reload Service                                               │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                        Nginx Web Tier                         │
    │                                                               │
    │  /                  Application Page                         │
    │  /health            Health Endpoint                          │
    │                                                               │
    │  Deployment Metadata                                         │
    │  Build Number                                                 │
    │  Environment                                                  │
    │  Application Version                                         │
    │  Deployment Timestamp                                        │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                   Automated Verification                     │
    │                                                               │
    │  HTTP 200 Validation                                         │
    │  Application Content Check                                   │
    │  Health Endpoint Check                                       │
    │  Metadata Verification                                       │
    │  Nginx Service Validation                                    │
    └───────────────────────────────────────────────────────────────┘

## Prerequisites

- Ubuntu or another systemd-based Linux distribution
- At least 2 CPU cores
- At least 4 GB available memory
- Git
- curl
- wget
- OpenJDK 21
- Jenkins
- Ansible Core
- Python 3
- Nginx
- systemd
- sudo access for initial setup
- Network access to the Jenkins package repository

## Setup & Installation

Install Java, Nginx, Python tooling, and supporting packages:

    sudo apt update

    sudo apt install -y \
      ca-certificates \
      curl \
      wget \
      gnupg \
      fontconfig \
      openjdk-21-jdk \
      software-properties-common \
      python3-pip \
      python3-venv \
      nginx

Configure the Jenkins stable repository:

    sudo install -d -m 0755 /etc/apt/keyrings

    sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
      https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
      | sudo tee /etc/apt/sources.list.d/jenkins.list \
      >/dev/null

Install Jenkins:

    sudo apt update
    sudo apt install -y jenkins

Install Ansible:

    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt install -y ansible

Start and enable the required services:

    sudo systemctl enable --now jenkins
    sudo systemctl enable --now nginx

Verify installation:

    java -version
    ansible --version
    nginx -v
    systemctl is-active jenkins
    systemctl is-active nginx

## Jenkins Initialization

Create a strong Jenkins administrator account during controlled initialization.

The administrator credential must be stored outside version control with permissions restricted to the local system owner:

    chmod 600 jenkins/admin-credential.txt

Configure the Jenkins controller URL:

    http://127.0.0.1:8080/

Install the required plugins:

    workflow-aggregator
    pipeline-stage-view
    git
    credentials-binding
    ansible

The administrator credential file must never be copied into the Jenkins deployment workspace or committed to Git.

## Repository Structure

    jenkins-ansible-automation/
    ├── ansible.cfg
    ├── Jenkinsfile
    ├── inventory/
    │   └── hosts
    ├── playbooks/
    │   └── deploy-webapp.yml
    ├── templates/
    │   └── index.html.j2
    ├── files/
    │   └── nginx-webapp.conf
    ├── scripts/
    │   └── test-deployment.sh
    ├── jenkins/
    │   ├── pipeline-job.xml
    │   └── jenkins-cli.jar
    └── README.md

## Ansible Inventory

The deployment targets the local system:

    [webservers]
    localhost ansible_connection=local

Privilege escalation is used only during the controlled deployment process.

Pipeline connectivity validation overrides privilege escalation because the Ansible ping action does not require root permissions:

    ansible \
      webservers \
      -m ansible.builtin.ping \
      -e ansible_become=false

## Controlled Privilege Escalation

Jenkins is not granted unrestricted root access.

A root-owned wrapper is installed at:

    /usr/local/sbin/run-ansible-web-deployment

The wrapper validates the build number, deployment environment, and application version before executing Ansible.

The Jenkins sudo policy permits only that wrapper:

    jenkins ALL=(root) NOPASSWD: /usr/local/sbin/run-ansible-web-deployment *

Validate the sudo policy:

    sudo visudo -cf /etc/sudoers.d/jenkins-deployment

Verify wrapper ownership:

    sudo stat -c \
      'Path: %n | Owner: %U:%G | Permissions: %a' \
      /usr/local/sbin/run-ansible-web-deployment

## How to Reproduce

Activate the working directory:

    cd ~/jenkins-ansible-automation

Validate the Ansible inventory:

    ansible-inventory \
      --inventory inventory/hosts \
      --graph

Validate playbook syntax:

    ansible-playbook \
      --syntax-check \
      playbooks/deploy-webapp.yml

Test local connectivity without privilege escalation:

    ansible \
      webservers \
      -m ansible.builtin.ping \
      -e ansible_become=false

Run a controlled deployment manually:

    sudo /usr/local/sbin/run-ansible-web-deployment \
      manual \
      development \
      1.0.0

Verify the application:

    curl http://127.0.0.1/

Verify the health endpoint:

    curl http://127.0.0.1/health

Run the deployment validation script:

    scripts/test-deployment.sh

## Jenkins Pipeline Stages

### Preparation

The pipeline displays build metadata, confirms the automation directory, and verifies the Ansible installation.

### Validate Automation

The pipeline validates:

- Ansible inventory structure
- Playbook syntax
- Local Ansible connectivity
- Required deployment files

### Deploy Application

Jenkins invokes the controlled root-owned wrapper with:

- Build number
- Deployment environment
- Application version

The wrapper executes the Ansible playbook and validates Nginx after deployment.

### Verify Deployment

The automated test script validates:

- Nginx service state
- Port 80 availability
- HTTP 200 response
- Expected application content
- Deployment metadata
- Health endpoint response

### Validate Metadata

The pipeline confirms that the rendered page contains the expected:

- Build number
- Environment
- Application version

### Health Summary

The pipeline verifies the final Nginx state, HTTP status, and health endpoint.

## Running the Jenkins Pipeline

Load the local Jenkins administrator credential:

    source ~/jenkins-ansible-automation/jenkins/admin-credential.txt

Define Jenkins CLI variables:

    JOB_NAME="Ansible-Web-Delivery"
    JENKINS_URL="http://127.0.0.1:8080/"
    JENKINS_CLI="$HOME/jenkins-ansible-automation/jenkins/jenkins-cli.jar"
    JENKINS_AUTH="${JENKINS_ADMIN_USER}:${JENKINS_ADMIN_PASSWORD}"

Run the default build:

    java -jar "$JENKINS_CLI" \
      -s "$JENKINS_URL" \
      -http \
      -auth "$JENKINS_AUTH" \
      build "$JOB_NAME" \
      -s \
      -v

Run a parameterized staging deployment:

    java -jar "$JENKINS_CLI" \
      -s "$JENKINS_URL" \
      -http \
      -auth "$JENKINS_AUTH" \
      build "$JOB_NAME" \
      -p DEPLOYMENT_ENVIRONMENT=staging \
      -p APP_VERSION=2.0.0 \
      -p SKIP_TESTS=false \
      -s \
      -v

Read the latest console output:

    java -jar "$JENKINS_CLI" \
      -s "$JENKINS_URL" \
      -http \
      -auth "$JENKINS_AUTH" \
      console "$JOB_NAME" \
      -f

## Deployment Parameters

### DEPLOYMENT_ENVIRONMENT

Supported values:

- development
- staging
- production

### APP_VERSION

Defines the version displayed in the deployed application.

Example:

    2.0.0

### SKIP_TESTS

Controls whether post-deployment application tests run.

Recommended value:

    false

## Application Endpoints

Application:

    http://127.0.0.1/

Health check:

    http://127.0.0.1/health

Expected health response:

    healthy

## Verification Commands

Check Jenkins:

    systemctl is-active jenkins
    systemctl is-enabled jenkins
    curl -I http://127.0.0.1:8080/login

Check Ansible:

    ansible --version
    ansible-playbook --version

Check Nginx:

    systemctl is-active nginx
    sudo nginx -t
    sudo ss -lntp | grep -E ':[8]0[[:space:]]'

Check the application:

    curl -fsS http://127.0.0.1/

Check deployment metadata:

    curl -fsS http://127.0.0.1/ \
      | grep -E \
      "Build Number:|Environment:|Application Version:|Deployment Time:"

Check health:

    curl -fsS http://127.0.0.1/health

## Tools Used

- Jenkins
- Jenkins Pipeline
- Jenkins CLI
- Ansible Core
- OpenJDK 21
- Nginx
- Python 3
- Bash
- Groovy
- XML
- YAML
- systemd
- curl
- Git
- Linux
- sudo

## Key Skills Demonstrated

- Jenkins controller installation and secure initialization
- Jenkins CLI authentication
- Declarative pipeline development
- Parameterized release workflows
- Ansible inventory design
- Ansible syntax validation
- Configuration management through Ansible
- Jinja template rendering
- Nginx virtual host automation
- Controlled privilege escalation
- HTTP deployment verification
- Application health-check implementation
- Build metadata injection
- Pipeline failure enforcement
- CI/CD troubleshooting
- Secure credential exclusion
- Service-state validation
- Repeatable application delivery

## Real-World Use Case

This delivery pattern can be used by DevOps, platform engineering, AIOps, and DevSecOps teams that need a controlled mechanism for deploying applications and configuration changes to managed Linux systems.

Jenkins provides centralized orchestration, build history, parameter handling, and delivery visibility. Ansible provides repeatable server configuration and application deployment. The controlled wrapper limits privileged execution while still allowing Jenkins to perform the required system changes.

The same approach can be extended to deploy internal APIs, model-serving applications, monitoring agents, inference gateways, data-processing services, and infrastructure components used by Applied AI platforms.

## Lessons Learned

- Jenkins extensions such as pipeline options depend on the corresponding plugin being installed.
- Declarative pipeline parameters may require a successful bootstrap execution before CLI parameter submission becomes available.
- Updating job XML can temporarily remove materialized parameter properties until the pipeline runs again.
- Jenkins shell steps may execute through `/bin/sh`, so Bash-specific options should not be assumed.
- Strict shell behavior should run inside a subshell to avoid terminating an interactive SSH session.
- Ansible connectivity checks should not request privilege escalation when elevated access is unnecessary.
- Unrestricted passwordless sudo should be replaced with narrowly scoped execution.
- Jinja variables must be rendered through the Ansible template action rather than copied as static files.
- Pipeline verification commands must return nonzero status when validation fails.
- Build history provides valuable evidence of troubleshooting and recovery.

## Troubleshooting Log

### Jenkins CLI Rejected the Connection

Observed error:

    Jenkins URL is not configured

Cause:

The global Jenkins controller URL had not been configured.

Resolution:

The Jenkins location configuration was set to:

    http://127.0.0.1:8080/

The CLI was then executed using HTTP transport.

### Unsupported Pipeline Option

Observed error:

    Invalid option type "timestamps"

Cause:

The Timestamper plugin was not installed.

Resolution:

The nonessential timestamps option was removed from the pipeline.

### Pipeline Was Not Parameterized

Observed error:

    The job is not parameterized but the -p option was specified

Cause:

Declarative parameters had not yet been materialized after job creation or update.

Resolution:

A successful bootstrap build was executed before submitting parameterized builds.

### Unsupported Pipefail Option

Observed error:

    set: Illegal option -o pipefail

Cause:

Jenkins executed the shell step through `/bin/sh`, which mapped to dash on Ubuntu.

Resolution:

Pipeline shell steps were changed to use POSIX-compatible:

    set -eu

The root-owned wrapper retained Bash strict mode because it executes directly through its Bash shebang.

### Missing First-Build Parameters

Observed error:

    DEPLOYMENT_ENVIRONMENT: parameter not set

Cause:

The bootstrap build executed before Jenkins registered the Declarative Pipeline parameters.

Resolution:

Safe default values were provided for the initial build:

    development
    1.0.0

### SSH Session Closed After Pipeline Failure

Cause:

Strict shell mode had been enabled directly in the interactive login shell. A failed Jenkins CLI command caused Bash to exit, which closed the SSH session.

Resolution:

Strict execution was moved into a subshell:

    (
      set -euo pipefail
      commands
    )

A failure now exits only the subshell while preserving the SSH connection.

### Ansible Connectivity Requested Sudo

Observed error:

    sudo: a password is required
    Premature end of stream waiting for become success

Cause:

The inventory enabled privilege escalation globally, including for the nonprivileged Ansible ping validation.

Resolution:

The validation command explicitly disabled privilege escalation:

    ansible \
      webservers \
      -m ansible.builtin.ping \
      -e ansible_become=false

### Secure Deployment Permission Design

The Jenkins service account was not granted unrestricted passwordless root access.

A fixed root-owned wrapper was created and validated before execution. Jenkins can invoke only that controlled deployment command.

### Deprecated Ansible Fact Injection

The application template originally referenced:

    ansible_date_time.iso8601

It was updated to:

    ansible_facts["date_time"]["iso8601"]

This avoids reliance on deprecated top-level fact injection behavior.

### Static File Rendering Issue

Application content containing Jinja expressions was initially treated as a static file.

The page was moved to:

    templates/index.html.j2

It is now rendered through:

    ansible.builtin.template

### Informational Failure Checks

Some initial verification commands printed failure messages without returning a failing exit status.

The final pipeline uses strict command checks and exits nonzero when syntax, connectivity, deployment, content, metadata, or health validation fails.
