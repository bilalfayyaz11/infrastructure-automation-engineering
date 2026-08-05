# Multi-Platform Ansible Role Validation

## What This Does

This implementation provides a complete automated validation workflow for an Ansible role using Molecule and Docker.

It creates isolated Linux containers, applies an Apache web server role, verifies the resulting configuration, checks idempotence, captures execution output, generates a Markdown validation report, and removes all temporary containers and published ports after testing.

The same role is validated against Ubuntu 24.04 and Ubuntu 22.04 to prove that its behavior is consistent across maintained operating-system versions.

## Architecture

    ┌───────────────────────────────────────────────────────────────┐
    │                     Developer Workstation                     │
    │                                                               │
    │  Python Virtual Environment                                  │
    │  Ansible Core                                                │
    │  Molecule                                                    │
    │  Molecule Docker Driver                                      │
    │  Docker Engine                                               │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                     Molecule Scenarios                        │
    │                                                               │
    │  default                                                     │
    │    Ubuntu 24.04                                              │
    │    Host Port 8080 → Container Port 80                        │
    │                                                               │
    │  ubuntu2204                                                  │
    │    Ubuntu 22.04                                              │
    │    Host Port 8081 → Container Port 80                        │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                     Ansible Role Execution                    │
    │                                                               │
    │  Install Apache                                              │
    │  Configure Listening Port                                    │
    │  Deploy Managed HTML Template                                │
    │  Enable and Start Service                                    │
    │  Validate Apache Configuration                               │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                     Automated Verification                    │
    │                                                               │
    │  Package Installation                                        │
    │  Service Active State                                        │
    │  Service Enablement                                          │
    │  Port Availability                                           │
    │  File Ownership and Permissions                              │
    │  Managed Content                                             │
    │  HTTP Status and Response Body                               │
    │  Idempotent Second Convergence                               │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                   Reporting and Cleanup                       │
    │                                                               │
    │  Scenario Output Logs                                        │
    │  Markdown Validation Report                                  │
    │  Container Destruction                                       │
    │  Host-Port Release Verification                              │
    └───────────────────────────────────────────────────────────────┘

## Repository Structure

    ansible-molecule-validation/
    ├── .gitignore
    ├── README.md
    ├── requirements.txt
    ├── run-molecule-validation.sh
    ├── reports/
    │   └── .gitkeep
    └── webserver/
        ├── defaults/
        │   └── main.yml
        ├── handlers/
        │   └── main.yml
        ├── meta/
        │   └── main.yml
        ├── tasks/
        │   └── main.yml
        ├── templates/
        │   └── index.html.j2
        ├── vars/
        │   └── main.yml
        └── molecule/
            ├── default/
            │   ├── converge.yml
            │   ├── molecule.yml
            │   ├── prepare.yml
            │   ├── requirements.yml
            │   └── verify.yml
            └── ubuntu2204/
                ├── converge.yml
                ├── molecule.yml
                ├── prepare.yml
                ├── requirements.yml
                └── verify.yml

## Prerequisites

- Ubuntu 24.04 or another modern Linux distribution
- Python 3
- Python virtual environments
- Docker Engine
- Git
- Bash
- Passwordless or interactive sudo access
- Internet connectivity for Python packages and container images

## Setup

Install the required operating-system packages:

    sudo apt update

    sudo apt install -y \
      python3-pip \
      python3-venv \
      python3-dev \
      build-essential \
      git \
      tree \
      curl \
      ca-certificates

Create and activate the Python environment:

    python3 -m venv .venv
    source .venv/bin/activate

Install the automation toolchain:

    python -m pip install --upgrade \
      pip \
      setuptools \
      wheel

    python -m pip install \
      ansible-core \
      molecule \
      "molecule-plugins[docker]" \
      docker

Verify the installation:

    ansible --version
    molecule --version
    docker --version

## Docker Access

Add the current user to the Docker group:

    sudo usermod -aG docker "$USER"

Reconnect to the host, then verify access:

    id
    docker info
    docker ps

The Docker commands should complete without `sudo`.

## Role Behavior

The `webserver` role performs the following operations:

- Updates APT metadata
- Installs Apache
- Configures the Apache listening port
- Deploys a managed HTML template
- Enables the Apache service
- Starts the Apache service
- Waits for the HTTP port to become available
- Validates Apache syntax before restarting or reloading

## Role Variables

Default variables are stored in:

    webserver/defaults/main.yml

The role exposes:

    webserver_package_name
    webserver_service_name
    webserver_document_root
    webserver_port
    webserver_page_title
    webserver_heading

Example values:

    webserver_package_name: apache2
    webserver_service_name: apache2
    webserver_document_root: /var/www/html
    webserver_port: 80

## Managed Page

The HTML page is rendered from:

    webserver/templates/index.html.j2

The template includes:

- A configurable page title
- A configurable heading
- The managed Apache port
- A statement confirming that Ansible and Molecule configured the service

## Handlers

The role defines handlers for:

- Apache configuration validation
- Apache restart
- Apache reload

The validation handler runs:

    /usr/sbin/apache2ctl configtest

A restart or reload occurs only after the configuration syntax passes.

## Molecule Scenarios

### Ubuntu 24.04

The default scenario uses:

    geerlingguy/docker-ubuntu2404-ansible:latest

The container runs systemd and publishes:

    Host 8080 → Container 80

### Ubuntu 22.04

The second scenario uses:

    geerlingguy/docker-ubuntu2204-ansible:latest

The container runs systemd and publishes:

    Host 8081 → Container 80

Both scenarios use:

- Docker
- Privileged execution
- Host cgroup namespace
- Writable cgroup mount
- Temporary filesystems for `/run`, `/run/lock`, and `/tmp`
- Ansible as the provisioner
- Ansible as the verifier

## Molecule Lifecycle

The complete Molecule lifecycle includes:

    dependency
    cleanup
    destroy
    syntax
    create
    prepare
    converge
    idempotence
    side_effect
    verify
    cleanup
    destroy

Run the complete default scenario:

    cd webserver
    molecule test -s default

Run the Ubuntu 22.04 scenario:

    molecule test -s ubuntu2204

List available scenarios:

    molecule list

Display the configured execution matrix:

    molecule matrix test -s default
    molecule matrix test -s ubuntu2204

## Individual Molecule Actions

Create a container:

    molecule create -s default

Prepare the container:

    molecule prepare -s default

Apply the role:

    molecule converge -s default

Run verification:

    molecule verify -s default

Check idempotence:

    molecule idempotence -s default

Inspect the container:

    molecule login -s default

Destroy the container:

    molecule destroy -s default

## Verification Coverage

The verification playbook checks all critical outcomes.

### Package Verification

It gathers APT package facts and confirms:

    apache2

is installed.

### Service Verification

It confirms that Apache is:

    active
    enabled

### Configuration Verification

It runs:

    /usr/sbin/apache2ctl configtest

The command must return exit code zero.

### Port Verification

It waits for:

    127.0.0.1:80

to become available.

### File Verification

It validates:

    /var/www/html/index.html

The expected state is:

    Owner: www-data
    Group: www-data
    Mode: 0644
    Type: regular file

### Content Verification

The deployed page must contain:

    Hello from Ansible Molecule
    Managed port: 80

### HTTP Verification

The verifier sends a request to:

    http://127.0.0.1/

The expected result is:

    HTTP status: 200
    Expected heading present in response content

## Idempotence

Idempotence confirms that applying the role a second time makes no additional changes.

Run:

    molecule idempotence -s default

A successful result contains:

    Idempotence completed successfully

This proves that the role converges toward a stable desired state rather than repeatedly modifying the system.

## Host HTTP Verification

While the default container is active:

    curl http://127.0.0.1:8080/

While the Ubuntu 22.04 container is active:

    curl http://127.0.0.1:8081/

Both responses should contain:

    Hello from Ansible Molecule

## Complete Multi-Scenario Validation

Run:

    ./run-molecule-validation.sh

The script:

- Runs the Ubuntu 24.04 scenario
- Runs the Ubuntu 22.04 scenario
- Captures full output for each scenario
- Detects whether each execution passed
- Checks idempotence markers
- Checks HTTP verification markers
- Generates a Markdown report
- Returns a nonzero exit code if either scenario fails

## Generated Reports

Reports are written under:

    reports/

A typical structure is:

    reports/
    ├── molecule-validation-YYYYMMDDTHHMMSSZ.md
    └── output-YYYYMMDDTHHMMSSZ/
        ├── default.log
        └── ubuntu2204.log

The Markdown report includes:

- Timestamp
- Ansible version
- Molecule version
- Docker version
- Host kernel
- Overall result
- Per-scenario result
- Idempotence markers
- HTTP verification markers
- Paths to full execution output

Generated reports and output logs are excluded from Git by default.

## Cleaning the Environment

Destroy the default scenario:

    cd webserver
    molecule destroy -s default

Destroy the Ubuntu 22.04 scenario:

    molecule destroy -s ubuntu2204

Verify no Molecule containers remain:

    docker ps -a \
      --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'

Verify ports are released:

    sudo ss -lntp \
      | grep -E ':(8080|8081)[[:space:]]' \
      || echo "Molecule ports are clear"

## Troubleshooting

### Docker Permission Denied

Check group membership:

    id
    groups

Add the user to the Docker group:

    sudo usermod -aG docker "$USER"

Reconnect before retrying.

Verify:

    docker info

### Docker Service Is Not Running

Run:

    sudo systemctl enable --now docker

Check:

    systemctl status docker --no-pager

### Molecule Cannot Find the Docker Driver

Activate the Python environment:

    source .venv/bin/activate

Verify the plugin:

    python -m pip show molecule-plugins

Reinstall when necessary:

    python -m pip install \
      "molecule-plugins[docker]" \
      docker

### Molecule Cannot Find a Scenario

Run from the role directory:

    cd webserver

List scenarios:

    molecule list

The expected scenarios are:

    default
    ubuntu2204

### Apache Is Not Active

Inspect the container:

    molecule login -s default

Inside the container:

    systemctl status apache2 --no-pager
    journalctl -u apache2 --no-pager
    apache2ctl configtest
    curl http://127.0.0.1/

### Port 8080 or 8081 Is Already Used

Check listening processes:

    sudo ss -lntp \
      | grep -E ':(8080|8081)[[:space:]]'

Remove old Molecule containers:

    cd webserver
    molecule destroy -s default
    molecule destroy -s ubuntu2204

Check Docker directly:

    docker ps -a

### Idempotence Fails

Run convergence twice with verbose output:

    molecule converge -s default
    molecule converge -s default -- -vv

Inspect tasks reporting unexpected changes.

Common causes include:

- Shell commands without `changed_when`
- Templates containing changing timestamps
- Package metadata updated on every run
- Service actions forced on every convergence
- File permissions repeatedly corrected

### Container Remains After Testing

Run:

    molecule destroy -s default
    molecule destroy -s ubuntu2204

Remove a container directly only when Molecule cleanup fails:

    docker rm -f molecule-ubuntu
    docker rm -f molecule-ubuntu2204

### Image Pull Fails

Verify Docker Hub connectivity:

    curl -I https://registry-1.docker.io/v2/

Pull manually:

    docker pull \
      geerlingguy/docker-ubuntu2404-ansible:latest

    docker pull \
      geerlingguy/docker-ubuntu2204-ansible:latest

## Tools Used

- Ansible Core
- Molecule
- Molecule Docker Driver
- Docker Engine
- Docker Python SDK
- Python 3
- YAML
- Jinja2
- Bash
- systemd
- Apache HTTP Server
- Git
- curl
- Linux networking utilities

## Key Skills Demonstrated

- Ansible role design
- Default variable management
- Template rendering
- Handler orchestration
- Apache configuration management
- Service lifecycle management
- Molecule scenario design
- Container-based infrastructure validation
- systemd-enabled container configuration
- Multi-version operating-system compatibility
- Automated package verification
- Automated service-state verification
- Configuration syntax validation
- File ownership and permission assertions
- HTTP endpoint testing
- Idempotence validation
- Full lifecycle automation
- Execution-output capture
- Markdown report generation
- Container cleanup verification
- Host-port cleanup verification
- Deterministic failure reporting
- Reproducible infrastructure quality checks

## Real-World Use Case

This workflow can be used before merging or deploying infrastructure automation.

A CI system can run the Molecule scenarios whenever the role changes. The pipeline can reject changes that:

- Fail to install the expected package
- Leave a service inactive
- Produce an invalid configuration
- Deploy incorrect content
- Return an unhealthy HTTP response
- Break compatibility with a supported operating system
- Introduce non-idempotent behavior
- Leave temporary containers behind

This reduces the risk of discovering automation failures during production deployment.

## Lessons Learned

- Infrastructure automation should be tested before it reaches production.
- A successful first convergence does not prove idempotence.
- Verification should inspect the actual resulting state.
- Service validation should include both process state and endpoint behavior.
- Multi-version testing catches operating-system compatibility issues early.
- systemd containers require compatible images and cgroup configuration.
- Temporary containers and host ports must always be cleaned up.
- Test reports make automation quality visible and reviewable.
- Failure output should be captured for later diagnosis.
- A role should expose configurable defaults instead of embedding fixed values.
- Handlers should validate configuration before restarting services.
- Molecule provides a repeatable quality gate for Ansible changes.
