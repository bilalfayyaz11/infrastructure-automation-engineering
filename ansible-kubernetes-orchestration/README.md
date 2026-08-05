# Ansible-Driven Kubernetes Workload Orchestration

## What This Does

This implementation uses Ansible to provision, validate, manage, and remove Kubernetes resources inside a Minikube cluster.

The automation manages namespaces, ConfigMaps, standalone pods, ClusterIP services, scalable Deployments, NodePort services, workload lifecycle operations, application testing, and resource cleanup. It also validates Kubernetes readiness, replica availability, application connectivity, idempotency, and controlled pod recreation.

This approach demonstrates how infrastructure and application operations can be represented as repeatable, version-controlled automation instead of relying on manual Kubernetes commands.

## Architecture

    ┌─────────────────────────────────────────────────────────────┐
    │                    Automation Controller                    │
    │                                                             │
    │  Ansible Core                                               │
    │  kubernetes.core Collection                                 │
    │  Kubernetes Python Client                                   │
    │  Python Virtual Environment                                 │
    └──────────────────────────────┬──────────────────────────────┘
                                   │
                                   │ Kubernetes API
                                   │ ~/.kube/config
                                   ▼
    ┌─────────────────────────────────────────────────────────────┐
    │                     Minikube Cluster                        │
    │                                                             │
    │  Kubernetes API Server                                     │
    │  Scheduler                                                  │
    │  Controller Manager                                         │
    │  etcd                                                       │
    │  Single Worker Node                                         │
    └──────────────────────────────┬──────────────────────────────┘
                                   │
                                   ▼
    ┌─────────────────────────────────────────────────────────────┐
    │                    ansible-demo Namespace                   │
    │                                                             │
    │  ┌──────────────────────┐                                   │
    │  │ ConfigMap            │                                   │
    │  │ nginx-app-config     │                                   │
    │  └──────────┬───────────┘                                   │
    │             │ Mounted HTML content                          │
    │             ▼                                               │
    │  ┌──────────────────────┐     ┌──────────────────────────┐  │
    │  │ Standalone Nginx Pod │◄────│ ClusterIP Service        │  │
    │  │ nginx-app-pod        │     │ nginx-app-service        │  │
    │  └──────────────────────┘     └──────────────────────────┘  │
    │                                                             │
    │  ┌───────────────────────────────────────────────────────┐  │
    │  │ Nginx Deployment                                     │  │
    │  │                                                       │  │
    │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │  │
    │  │  │ Replica 1│  │ Replica 2│  │ Replica 3│            │  │
    │  │  └──────────┘  └──────────┘  └──────────┘            │  │
    │  └───────────────────────────┬───────────────────────────┘  │
    │                              │                              │
    │                    ┌─────────▼──────────┐                   │
    │                    │ NodePort Service   │                   │
    │                    │ nginx-deployment- │                   │
    │                    │ service            │                   │
    │                    └────────────────────┘                   │
    └─────────────────────────────────────────────────────────────┘

## Prerequisites

- Ubuntu or another supported Linux distribution
- Docker Engine with non-root user access
- Minikube
- kubectl
- Python 3
- Python virtual environment support
- Ansible Core
- kubernetes.core Ansible collection
- Kubernetes Python client
- PyYAML
- jsonpatch
- curl
- At least 2 CPU cores
- At least 4 GB available memory
- At least 12 GB available disk space

## Setup & Installation

Install the required Linux packages:

    sudo apt update

    sudo apt install -y \
      python3-pip \
      python3-venv \
      conntrack \
      socat \
      curl \
      wget

Grant the current user access to Docker:

    sudo usermod -aG docker "$USER"
    sudo chown root:docker /var/run/docker.sock
    sudo chmod 660 /var/run/docker.sock

Install Minikube:

    ARCH=$(dpkg --print-architecture)

    case "$ARCH" in
      amd64)
        MINIKUBE_ARCH="amd64"
        ;;
      arm64)
        MINIKUBE_ARCH="arm64"
        ;;
      *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
    esac

    curl -fLO \
      "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${MINIKUBE_ARCH}"

    sudo install \
      "minikube-linux-${MINIKUBE_ARCH}" \
      /usr/local/bin/minikube

    rm -f "minikube-linux-${MINIKUBE_ARCH}"

Create the working directory and Python environment:

    mkdir -p ~/ansible-kubernetes-automation
    cd ~/ansible-kubernetes-automation

    python3 -m venv .venv
    source .venv/bin/activate

Install the automation dependencies:

    python -m pip install --upgrade pip setuptools wheel

    python -m pip install \
      ansible-core \
      kubernetes \
      PyYAML \
      jsonpatch

    ansible-galaxy collection install kubernetes.core

Verify the installation:

    minikube version
    kubectl version --client
    ansible --version
    ansible-galaxy collection list kubernetes.core

## How to Reproduce

Start the Kubernetes cluster:

    minikube start \
      --driver=docker \
      --cpus=2 \
      --memory=4096 \
      --disk-size=12g

Confirm the cluster is ready:

    minikube status
    kubectl cluster-info
    kubectl get nodes -o wide
    kubectl get pods -n kube-system

Activate the automation environment:

    cd ~/ansible-kubernetes-automation
    source .venv/bin/activate

Create the application namespace:

    ansible-playbook playbooks/create-namespace.yml

Verify namespace creation:

    kubectl get namespace ansible-demo

Deploy the standalone Nginx workload:

    ansible-playbook playbooks/deploy-pod.yml

Verify the ConfigMap, pod, and service:

    kubectl get configmap,pod,service \
      -n ansible-demo \
      -o wide

Inspect the standalone pod:

    ansible-playbook \
      playbooks/manage-pod.yml \
      -e "pod_action=info"

Perform a controlled pod restart:

    ansible-playbook \
      playbooks/manage-pod.yml \
      -e "pod_action=restart"

Verify that the recreated pod is ready:

    kubectl wait \
      --for=condition=Ready \
      pod/nginx-app-pod \
      -n ansible-demo \
      --timeout=300s

Deploy the scalable three-replica workload:

    ansible-playbook playbooks/deploy-deployment.yml

Verify Deployment rollout:

    kubectl rollout status \
      deployment/nginx-deployment \
      -n ansible-demo \
      --timeout=300s

Verify the requested replicas:

    kubectl get deployment,pods,service \
      -n ansible-demo \
      -o wide

Test the standalone service:

    kubectl port-forward \
      service/nginx-app-service \
      -n ansible-demo \
      8080:80

In another terminal:

    curl http://127.0.0.1:8080

Test the Deployment service:

    kubectl port-forward \
      service/nginx-deployment-service \
      -n ansible-demo \
      8081:80

In another terminal:

    curl http://127.0.0.1:8081

Run the playbooks again to validate idempotency:

    ansible-playbook playbooks/create-namespace.yml
    ansible-playbook playbooks/deploy-pod.yml
    ansible-playbook playbooks/deploy-deployment.yml

An unchanged environment should complete with no unnecessary resource modifications.

Remove all managed Kubernetes resources:

    ansible-playbook playbooks/cleanup.yml

Confirm namespace deletion:

    kubectl get namespace ansible-demo

The expected result is a Kubernetes NotFound response.

## Repository Structure

    ansible-kubernetes-automation/
    ├── ansible.cfg
    ├── inventory/
    │   └── hosts
    ├── playbooks/
    │   ├── create-namespace.yml
    │   ├── deploy-pod.yml
    │   ├── manage-pod.yml
    │   ├── deploy-deployment.yml
    │   └── cleanup.yml
    ├── roles/
    └── README.md

## Tools Used

- Ansible Core
- kubernetes.core
- Kubernetes Python client
- Kubernetes
- Minikube
- kubectl
- Docker
- Python
- PyYAML
- jsonpatch
- Nginx
- Linux
- YAML
- curl

## Key Skills Demonstrated

- Automated Kubernetes resource provisioning using Ansible
- Declarative management of namespaces, ConfigMaps, pods, services, and Deployments
- Integration between Ansible and the Kubernetes API
- Kubernetes workload lifecycle automation
- Idempotent infrastructure execution
- Controlled pod deletion and recreation
- Multi-replica workload orchestration
- Kubernetes readiness and liveness probe configuration
- Resource request and limit configuration
- ClusterIP and NodePort service management
- Automated rollout and replica verification
- Application connectivity testing through port forwarding
- Automated resource cleanup
- Python dependency isolation using virtual environments
- Troubleshooting Docker permissions and Kubernetes connectivity

## Real-World Use Case

This automation pattern can be used by platform engineering, DevOps, AIOps, and DevSecOps teams that need to deploy and manage Kubernetes resources consistently across development, testing, and controlled infrastructure environments.

Ansible can coordinate Kubernetes configuration alongside operating-system preparation, secrets retrieval, infrastructure provisioning, validation, and post-deployment checks. This is useful when organizations already use Ansible as a central automation platform and want Kubernetes operations integrated into the same controlled workflow.

For Applied AI infrastructure, the same pattern can be extended to deploy model-serving containers, inference APIs, internal AI tools, observability components, data-processing workers, and supporting services.

## Lessons Learned

- Ansible can manage Kubernetes resources through the Kubernetes API without relying entirely on imperative kubectl commands.
- Kubernetes Python client dependencies must exist in the same Python environment used by Ansible.
- Docker group access must be active before Minikube can use the Docker driver.
- Floating container tags such as latest reduce deployment predictability and should be replaced with pinned versions.
- Standalone pods cannot be scaled and must be recreated manually when lifecycle changes are required.
- Deployments are more appropriate than standalone pods for scalable and self-healing workloads.
- Readiness probes prevent Kubernetes services from routing traffic to containers before they are ready.
- Liveness probes allow Kubernetes to detect and restart unhealthy containers.
- Resource requests and limits improve scheduling predictability and reduce uncontrolled resource consumption.
- Re-running playbooks is an effective way to verify idempotent automation behavior.

## Troubleshooting Log

### Docker Socket Permission Failure

The Docker service was running, but the current user could not access the Docker socket.

Resolution:

    sudo usermod -aG docker "$USER"
    sudo chown root:docker /var/run/docker.sock
    sudo chmod 660 /var/run/docker.sock

The Docker-enabled group session was then activated before starting Minikube.

### Existing Port 8443 Listener

Port 8443 was already being used by the remote desktop service.

The process was identified as dcvserver and was left running because it was required by the environment. Minikube using the Docker driver did not require terminating that process.

### Missing Minikube Installation

Minikube was not installed in the fresh environment.

The correct binary was downloaded based on the system architecture and installed into:

    /usr/local/bin/minikube

### Missing Python Package Manager

The system Python installation did not initially include pip.

The required packages were installed through the Ubuntu package manager:

    sudo apt install -y python3-pip python3-venv

### Isolated Python Environment

An isolated virtual environment was used to prevent system Python package conflicts:

    python3 -m venv .venv
    source .venv/bin/activate

### Missing Kubernetes Automation Dependencies

The Kubernetes Python client and supporting libraries were installed inside the virtual environment:

    python -m pip install \
      ansible-core \
      kubernetes \
      PyYAML \
      jsonpatch

### Ansible Callback Compatibility

A YAML callback was not assumed to be available in the installed Ansible Core version.

The default callback was used in ansible.cfg to avoid callback-loading errors.

### Floating Container Image Tag

The original configuration used nginx:latest.

It was replaced with:

    nginx:1.27-alpine

This makes workload behavior more predictable and reproducible.

### Unrestricted Container Resources

The standalone pod and Deployment were given explicit CPU and memory requests and limits to improve scheduling consistency and prevent uncontrolled consumption.

### Missing Health Checks

Readiness and liveness probes were added to the Deployment so Kubernetes could validate workload health and avoid routing traffic to unavailable replicas.

### Incorrect Standalone Pod Scaling Concept

A standalone pod cannot be scaled because it is not controlled by a Deployment or ReplicaSet.

The lifecycle workflow was corrected to delete and recreate the pod for restart testing, while scalable behavior was implemented through a Deployment.
