# Ansible-Driven Kubernetes Lifecycle Automation

## What This Does

This implementation provides a complete Ansible-based automation layer for managing Kubernetes application resources on a local Minikube cluster.

It automates namespace creation, application deployment, service configuration, horizontal scaling, image updates, health monitoring, resource verification, and controlled cleanup. Each operation is declarative, repeatable, and validated through both Ansible modules and native Kubernetes commands.

The design demonstrates how infrastructure teams can replace repetitive manual Kubernetes administration with version-controlled automation while maintaining operational visibility, idempotency, and safe lifecycle controls.

## Architecture

    ┌──────────────────────────────────────────────────────────────┐
    │                    Infrastructure Operator                   │
    │              Executes Ansible lifecycle actions              │
    └──────────────────────────────┬───────────────────────────────┘
                                   │
                                   ▼
    ┌──────────────────────────────────────────────────────────────┐
    │                      Ansible Control Layer                   │
    │                                                              │
    │  ansible.cfg                                                 │
    │  inventory/hosts                                             │
    │                                                              │
    │  ┌────────────────────────────────────────────────────────┐  │
    │  │ Namespace Management                                   │  │
    │  │ Deployment Management                                  │  │
    │  │ Service Management                                     │  │
    │  │ Scaling and Image Updates                              │  │
    │  │ Monitoring and Verification                            │  │
    │  │ Cleanup Automation                                     │  │
    │  └────────────────────────────────────────────────────────┘  │
    └──────────────────────────────┬───────────────────────────────┘
                                   │ kubernetes.core modules
                                   ▼
    ┌──────────────────────────────────────────────────────────────┐
    │                  Kubernetes API Server                       │
    │                     Minikube Cluster                         │
    └──────────────────────────────┬───────────────────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
              ▼                    ▼                    ▼
    ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
    │ Namespace        │  │ NGINX Deployment │  │ ClusterIP Service│
    │ ansible-demo     │  │ Rolling updates  │  │ Internal routing │
    └──────────────────┘  │ Health probes     │  │ Pod endpoints    │
                          │ Resource controls │  └──────────────────┘
                          └──────────────────┘
                                   │
                                   ▼
    ┌──────────────────────────────────────────────────────────────┐
    │             Monitoring and Operational Validation            │
    │                                                              │
    │  Deployment readiness • Pod health • Service endpoints       │
    │  Node status • Resource metrics • Rollout verification       │
    └──────────────────────────────────────────────────────────────┘

## Prerequisites

- Ubuntu or another compatible Linux distribution
- Python 3
- Python virtual environment support
- Docker Engine
- Docker access for the current user
- kubectl
- Minikube
- Ansible Core
- Ansible kubernetes.core collection
- Python Kubernetes client
- PyYAML
- A minimum of 2 CPU cores
- At least 4 GB of available memory
- Internet access for downloading container images and dependencies

## Setup & Installation

Install the required system packages:

    sudo apt-get update
    sudo apt-get install -y \
      python3-pip \
      python3-venv \
      acl \
      curl \
      git

Create the isolated Ansible Python environment:

    mkdir -p ~/.venvs
    python3 -m venv ~/.venvs/ansible-kubernetes

    ~/.venvs/ansible-kubernetes/bin/python -m pip install \
      --upgrade pip setuptools wheel

    ~/.venvs/ansible-kubernetes/bin/python -m pip install \
      ansible-core \
      kubernetes \
      PyYAML \
      requests

Activate the environment:

    export PATH="$HOME/.venvs/ansible-kubernetes/bin:$PATH"

Install the Kubernetes collection:

    ansible-galaxy collection install kubernetes.core

Install Minikube on x86_64 Linux:

    curl -fL \
      https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
      -o /tmp/minikube

    sudo install -m 0755 /tmp/minikube /usr/local/bin/minikube
    rm -f /tmp/minikube

Start the local Kubernetes cluster:

    minikube start \
      --driver=docker \
      --cpus=2 \
      --memory=4096mb \
      --disk-size=12g

Verify cluster access:

    minikube status
    kubectl cluster-info
    kubectl get nodes

## How to Reproduce

Clone the repository and enter the implementation directory:

    git clone https://github.com/bilalfayyaz11/infrastructure-automation-engineering.git
    cd infrastructure-automation-engineering/ansible-kubernetes-automation

Activate the Ansible environment:

    export PATH="$HOME/.venvs/ansible-kubernetes/bin:$PATH"

Verify the inventory and local Ansible connection:

    ansible-inventory --graph
    ansible local -m ansible.builtin.ping

Create the Kubernetes namespace:

    ansible-playbook playbooks/manage-namespace.yml

Deploy the application:

    ansible-playbook playbooks/manage-deployment.yml

Create the internal Kubernetes service:

    ansible-playbook playbooks/manage-service.yml

Scale the deployment to five replicas:

    ansible-playbook playbooks/scale-deployment.yml

Scale the deployment down to two replicas:

    ansible-playbook playbooks/scale-down.yml

Use the unified lifecycle controller:

    ansible-playbook playbooks/full-app-lifecycle.yml \
      -e "action=deploy"

    ansible-playbook playbooks/full-app-lifecycle.yml \
      -e "action=scale new_replica_count=6"

    ansible-playbook playbooks/full-app-lifecycle.yml \
      -e "action=update new_image=nginx:stable-alpine"

Enable cluster metrics:

    minikube addons enable metrics-server

    kubectl rollout status deployment/metrics-server \
      --namespace kube-system \
      --timeout=300s

Run the monitoring automation:

    ansible-playbook playbooks/monitor-resources.yml

Inspect Kubernetes resource usage:

    kubectl top nodes
    kubectl top pods --namespace ansible-demo --containers

Remove the namespace and all contained resources:

    ansible-playbook playbooks/cleanup.yml

Verify cleanup:

    kubectl get namespace ansible-demo

## Tools Used

- Ansible Core
- Ansible kubernetes.core collection
- Kubernetes
- Minikube
- kubectl
- Docker Engine
- Python 3
- Python Kubernetes client
- PyYAML
- Metrics Server
- NGINX
- YAML
- Git
- Linux

## Key Skills Demonstrated

- Declarative Kubernetes infrastructure management through Ansible
- Idempotent automation and repeatable infrastructure execution
- Kubernetes namespace, Deployment, Service, Endpoint, Pod, and Node management
- Safe partial resource updates using merge strategies
- Rolling application updates and container image lifecycle management
- Horizontal deployment scaling and exact replica validation
- Kubernetes readiness and liveness probe configuration
- Resource request and limit configuration
- Service discovery and internal connectivity testing
- Kubernetes API integration through Python and Ansible
- Deployment health verification and rollout monitoring
- Metrics Server enablement and resource-consumption analysis
- Controlled cleanup of namespaced Kubernetes resources
- Defensive playbook design with assertions and state validation
- Troubleshooting outdated commands and unsafe assumptions

## Real-World Use Case

A platform engineering or AIOps team can use this pattern to provide a controlled automation interface for Kubernetes workloads across development, testing, and internal application environments. Instead of requiring engineers to manually create resources or run multiple Kubernetes commands, approved Ansible playbooks can perform deployments, scaling, updates, monitoring, and cleanup consistently. The same approach can be integrated into CI/CD systems, operational runbooks, service-management workflows, and automated remediation pipelines.

## Lessons Learned

- Kubernetes deployment availability must be validated using exact ready, available, and updated replica counts rather than relying only on an Available condition.
- Partial Deployment updates require an explicit merge strategy to avoid unintentionally replacing existing resource fields.
- Ansible must use the Python interpreter containing the Kubernetes client library, especially when dependencies are installed inside a virtual environment.
- Kubernetes services should be validated through their endpoint objects, not only by checking that the Service resource exists.
- Namespace deletion is cleaner and more reliable than manually deleting every namespaced resource individually.
- Metrics Server must be enabled before kubectl top can return node and pod resource usage.

## Troubleshooting Log

### Docker Socket Access Was Unavailable

The Docker service was active, but the current user did not have access to the Docker socket.

The user was added to the Docker group and temporary socket access was granted for the active portal session:

    sudo usermod -aG docker "$USER"
    sudo setfacl -m "u:${USER}:rw" /var/run/docker.sock

### Ubuntu Blocked Global Python Package Installation

Ubuntu 24.04 uses an externally managed Python environment, which can prevent direct global installation through pip.

A dedicated virtual environment was created for Ansible and Kubernetes dependencies:

    python3 -m venv ~/.venvs/ansible-kubernetes

### Legacy Ansible YAML Callback Configuration

The legacy stdout_callback configuration may be unavailable in modern Ansible Core installations.

The built-in default callback with YAML result formatting was used instead:

    stdout_callback = ansible.builtin.default
    result_format = yaml

### Outdated NGINX Image

The original configuration used the obsolete nginx:1.21 image.

The implementation uses maintained Alpine-based image tags:

    app_image: nginx:alpine
    new_image: nginx:stable-alpine

### Unsafe Resource Indexing

Several original operations directly accessed the first returned Kubernetes resource without verifying that the response contained any items.

Assertions were added before indexing resource lists.

### Incomplete Scaling Validation

Waiting only for a Deployment availability condition does not guarantee that all old pods have terminated or that the exact target replica count has been reached.

The corrected playbooks validate desired, ready, available, and updated replica counts.

### Unsafe Partial Deployment Updates

Scaling and image-update definitions contained only partial Deployment specifications without a merge strategy.

The implementation uses merge and strategic-merge behavior for controlled updates.

### Unreliable Cleanup Lookup

The original cleanup approach used a Kubernetes lookup result as though it always contained a resources field.

The corrected implementation deletes the namespace and allows Kubernetes garbage collection to remove all contained resources.

### Metrics API Unavailable by Default

kubectl top requires Metrics Server, which is not always enabled by default in Minikube.

It was enabled and validated before resource-usage commands were executed:

    minikube addons enable metrics-server
