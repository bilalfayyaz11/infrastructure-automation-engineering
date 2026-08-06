# Ansible Hybrid Cloud Service Automation

## What This Does

This implementation provides an Ansible-controlled hybrid infrastructure environment that simulates on-premises and cloud platforms on a single Docker host.

The on-premises environment contains PostgreSQL, Redis, and an environment-specific web-service instance. The cloud environment contains MySQL, Prometheus, two application instances, and an NGINX load balancer connected to both Docker networks.

The automation provisions infrastructure, deploys services, validates container health, tests database and cache availability, confirms cross-environment communication, monitors resource usage, and safely removes only the resources it manages.

## Architecture

    ┌─────────────────────────────────────────────────────────────────────┐
    │                         Ansible Control Layer                       │
    │                                                                     │
    │  inventory/hosts.yml                                                │
    │  playbooks/onprem-setup.yml                                         │
    │  playbooks/cloud-setup.yml                                          │
    │  playbooks/deploy-webservice.yml                                    │
    │  playbooks/site.yml                                                 │
    └───────────────────────────────┬─────────────────────────────────────┘
                                    │
                   Declarative provisioning and validation
                                    │
             ┌──────────────────────┴──────────────────────┐
             │                                             │
             ▼                                             ▼
    ┌─────────────────────────────┐             ┌─────────────────────────────┐
    │ On-Premises Environment     │             │ Cloud Environment           │
    │                             │             │                             │
    │ Docker network:             │             │ Docker network:             │
    │ onprem-network              │             │ cloud-network               │
    │                             │             │                             │
    │ ┌─────────────────────────┐ │             │ ┌─────────────────────────┐ │
    │ │ PostgreSQL 17           │ │             │ │ MySQL 8.4               │ │
    │ │ onprem-database         │ │             │ │ cloud-database          │ │
    │ └─────────────────────────┘ │             │ └─────────────────────────┘ │
    │                             │             │                             │
    │ ┌─────────────────────────┐ │             │ ┌─────────────────────────┐ │
    │ │ Redis 7                 │ │             │ │ Prometheus              │ │
    │ │ onprem-cache            │ │             │ │ cloud-monitoring        │ │
    │ └─────────────────────────┘ │             │ └─────────────────────────┘ │
    │                             │             │                             │
    │ ┌─────────────────────────┐ │             │ ┌─────────────────────────┐ │
    │ │ Flask + Gunicorn        │ │             │ │ Flask + Gunicorn        │ │
    │ │ webservice-onprem-1     │ │             │ │ webservice-cloud-1      │ │
    │ │ Host port: 5000         │ │             │ │ Host port: 5001         │ │
    │ └─────────────────────────┘ │             │ └─────────────────────────┘ │
    │                             │             │                             │
    │                             │             │ ┌─────────────────────────┐ │
    │                             │             │ │ Flask + Gunicorn        │ │
    │                             │             │ │ webservice-cloud-2      │ │
    │                             │             │ │ Host port: 5002         │ │
    │                             │             │ └─────────────────────────┘ │
    └──────────────┬──────────────┘             └──────────────┬──────────────┘
                   │                                           │
                   └──────────────────┬────────────────────────┘
                                      │
                                      ▼
                     ┌─────────────────────────────────┐
                     │ NGINX Hybrid Load Balancer      │
                     │ cloud-loadbalancer              │
                     │                                 │
                     │ Connected networks:             │
                     │ - onprem-network                │
                     │ - cloud-network                 │
                     │                                 │
                     │ Host port: 8080                 │
                     └─────────────────┬───────────────┘
                                       │
                                       ▼
                     ┌─────────────────────────────────┐
                     │ Monitoring and Verification     │
                     │                                 │
                     │ Container health                │
                     │ HTTP endpoint checks            │
                     │ Database and cache validation   │
                     │ Load distribution verification │
                     │ Docker resource usage           │
                     │ Ansible idempotency             │
                     └─────────────────────────────────┘

## Prerequisites

- Ubuntu or another compatible Linux distribution
- Python 3.12 or newer
- Python virtual environment support
- Docker Engine
- Docker Compose plugin
- Docker access for the current user
- Ansible Core
- Ansible community.docker collection
- Python Docker SDK
- Python requests library
- PyYAML
- Git
- curl
- At least 4 CPU cores
- At least 8 GB of available memory
- Available host ports:
  - 3306
  - 5000
  - 5001
  - 5002
  - 5432
  - 6379
  - 8080
  - 9090

## Setup & Installation

Install the required system packages:

    sudo apt-get update

    sudo apt-get install -y \
      python3-pip \
      python3-venv \
      acl \
      curl \
      git

Add the current user to the Docker group:

    sudo usermod -aG docker "$USER"

Create the isolated Python environment:

    mkdir -p "$HOME/.venvs"

    python3 -m venv "$HOME/.venvs/hybrid-automation"

Upgrade the Python packaging tools:

    "$HOME/.venvs/hybrid-automation/bin/python" -m pip install \
      --upgrade pip setuptools wheel

Install Ansible and its Python dependencies:

    "$HOME/.venvs/hybrid-automation/bin/python" -m pip install \
      ansible-core \
      docker \
      requests \
      PyYAML

Activate the environment:

    export PATH="$HOME/.venvs/hybrid-automation/bin:$PATH"

Install the Ansible Docker collection:

    ansible-galaxy collection install community.docker

Verify the installation:

    ansible --version
    ansible-playbook --version
    ansible-galaxy collection list community.docker
    docker --version
    docker compose version

## How to Reproduce

Clone the repository:

    git clone https://github.com/bilalfayyaz11/infrastructure-automation-engineering.git

Enter the implementation directory:

    cd infrastructure-automation-engineering/hybrid-cloud-automation

Activate the Ansible Python environment:

    export PATH="$HOME/.venvs/hybrid-automation/bin:$PATH"

Verify the inventory:

    ansible-inventory --graph

Test both simulated environments:

    ansible onpremises -m ansible.builtin.ping
    ansible cloud -m ansible.builtin.ping

Build the web-service container image:

    docker build \
      --tag hybrid-web-service:1.0.0 \
      --tag hybrid-web-service:latest \
      webservice

Provision the on-premises environment:

    ansible-playbook playbooks/onprem-setup.yml

Provision the cloud environment:

    ansible-playbook playbooks/cloud-setup.yml

Deploy the application instances:

    ansible-playbook playbooks/deploy-webservice.yml

Run the complete orchestration workflow:

    ansible-playbook playbooks/site.yml

Verify the application instances directly:

    curl --fail http://127.0.0.1:5000/info
    curl --fail http://127.0.0.1:5001/info
    curl --fail http://127.0.0.1:5002/info

Verify the NGINX load balancer:

    curl --fail http://127.0.0.1:8080/info

Verify Prometheus:

    curl --fail http://127.0.0.1:9090/-/healthy

Run the operational monitor:

    ./scripts/monitor-services.sh

Run the Python deployment-status utility:

    python3 scripts/deployment-status.py

Test cross-environment communication:

    ./scripts/test-communication.sh

Run the complete verification suite:

    ./verify-environment.sh

Safely remove managed containers and networks:

    ./scripts/cleanup-deployment.sh

The cleanup utility preserves persistent data under:

    /opt/onprem-data
    /opt/cloud-data

## Managed Services

### On-Premises Environment

- PostgreSQL 17
- Redis 7
- Flask and Gunicorn web-service instance
- Dedicated Docker bridge network
- Persistent PostgreSQL and Redis storage
- Container health checks
- Host ports 5000, 5432, and 6379

### Cloud Environment

- MySQL 8.4
- Prometheus
- Two Flask and Gunicorn web-service instances
- NGINX load balancer
- Dedicated Docker bridge network
- Persistent MySQL and Prometheus storage
- Host ports 3306, 5001, 5002, 8080, and 9090

## Tools Used

- Ansible Core
- Ansible community.docker collection
- Docker Engine
- Docker Compose
- Docker bridge networking
- Python 3
- Flask
- Gunicorn
- PostgreSQL
- Redis
- MySQL
- Prometheus
- NGINX
- Python Docker SDK
- Python requests
- PyYAML
- Bash
- Git
- Linux

## Key Skills Demonstrated

- Hybrid infrastructure modeling with isolated Docker networks
- Multi-environment provisioning through Ansible inventories
- Declarative container lifecycle management
- Idempotent infrastructure execution
- Persistent database and monitoring storage configuration
- Environment-aware application deployment
- Multi-instance service deployment
- Cross-network Docker service discovery
- NGINX upstream load balancing
- Database, cache, and HTTP health validation
- Container-level health-check configuration
- Prometheus service deployment
- Defensive shell and Python monitoring utilities
- Controlled cleanup that protects unrelated Docker workloads
- Automated infrastructure and application verification
- Troubleshooting Ansible collection parameter differences
- Troubleshooting Docker host networking and loopback bindings
- Troubleshooting Dockerfile syntax and container health checks

## Real-World Use Case

Organizations commonly maintain workloads across private infrastructure and public cloud environments during migrations, compliance-driven deployments, disaster-recovery preparation, or gradual modernization initiatives. This automation pattern provides a centralized Ansible workflow for provisioning environment-specific services while maintaining isolated networking, consistent application versions, operational health checks, and shared traffic management. The same design can be extended to remote hosts, cloud virtual machines, managed databases, container registries, and CI/CD deployment pipelines.

## Lessons Learned

- Simulated inventory hosts can share one physical machine while still remaining isolated through environment-specific networks, storage paths, ports, and container names.
- Stable container names are required for idempotent Ansible execution and reliable Docker DNS resolution.
- Docker Compose and the Ansible Docker collection use different parameter names for host-entry configuration.
- Services bound only to the host loopback interface cannot be reached through a Docker host-gateway address from another container.
- Connecting NGINX directly to both Docker networks provides more reliable service discovery than routing through host-published ports.
- Container health checks must use explicit IPv4 loopback addresses when application listeners do not bind to IPv6.
- A master Ansible workflow should validate both infrastructure state and application endpoints after provisioning.
- Cleanup automation must target only managed resources rather than removing every container on a shared host.

## Troubleshooting Log

### Docker Access Was Unavailable

The Docker service was active, but the current user was not a member of the Docker group.

Permanent membership was configured with:

    sudo usermod -aG docker "$USER"

Temporary access for the active session was granted through the Docker socket ACL:

    sudo setfacl -m "u:${USER}:rw" /var/run/docker.sock

### Obsolete Python Docker Package Name

The source instructions referenced docker-py.

The maintained Python package is:

    docker

### Unsupported Ansible Container Parameter

The NGINX container definition originally used:

    extra_hosts

The community.docker.docker_container module expects:

    etc_hosts

The corrected configuration uses:

    etc_hosts:
      host.docker.internal: host-gateway

### NGINX Health Check Failed on localhost

The NGINX Alpine container resolved localhost in a way that did not reach its IPv4 listener.

The health check was changed to:

    http://127.0.0.1/load-balancer-health

### Dockerfile JSON Command Parsing Failure

A multi-line JSON-form Docker CMD instruction was interpreted as separate Dockerfile instructions.

The command was changed to one valid JSON-array instruction:

    CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "2", "--timeout", "30", "--access-logfile", "-", "--error-logfile", "-", "app:app"]

### NGINX Returned HTTP 502

The application ports were published only on host loopback, while NGINX attempted to reach them through host.docker.internal.

The load balancer was connected directly to both environment networks and configured with Docker DNS names:

    webservice-onprem-1:5000
    webservice-cloud-1:5000
    webservice-cloud-2:5000

### Invalid Python Command Quoting

An inline Python f-string contained escaped quotes inside its expression and produced a syntax error.

The output formatting was changed to:

    print("{} | {}".format(d["environment"], d["instance_id"]))

### SSH Session Closed After Validation Failure

Execution blocks used:

    set -euo pipefail

A failed curl command caused the remote shell to exit immediately, which closed the portal SSH session.

Recoverable operational checks were changed to explicit conditional handling rather than globally terminating the session.

### Unsafe Global Docker Cleanup

The original cleanup logic stopped and removed every Docker container on the host.

The corrected utility removes only the eight named containers and two networks managed by this automation.

## Operational Verification

The final verification confirms:

- Eight required containers are present and running
- All configured container health checks pass
- Both Docker networks exist
- NGINX is connected to both environment networks
- All three application instances return correct metadata
- PostgreSQL accepts connections
- Redis returns PONG
- MySQL responds to administrative health checks
- Prometheus reports healthy
- NGINX reports healthy
- Load balancing reaches all three application instances
- All required Ansible files and scripts exist
- All playbooks pass syntax validation
- The master orchestration workflow completes successfully
- Repeated execution remains operationally idempotent
