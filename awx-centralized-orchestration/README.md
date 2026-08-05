# AWX Centralized Orchestration

## Overview

A centralized infrastructure automation platform built with AWX, Kubernetes, Docker, Git, PostgreSQL, and Ansible.

AWX runs inside a kind Kubernetes cluster, synchronizes playbooks from an internal Git service, manages inventory and reusable automation templates, and launches jobs through its REST API.

## Architecture

    Administrator
         |
         v
    AWX Web Interface and REST API
         |
         +-------------------+
         |                   |
         v                   v
    AWX Web             AWX Execution
         |                   |
         +---------+---------+
                   |
                   v
              PostgreSQL
                   |
                   v
          Internal Git Service
                   |
                   v
           Ansible Playbooks

## Implemented Capabilities

- AWX Operator deployment on Kubernetes
- Persistent PostgreSQL storage
- AWX web interface and authenticated REST API
- Internal Git-backed playbook synchronization
- Managed inventory, host, and host group
- Reusable automation templates
- API-driven execution and monitoring
- Captured job output and execution history
- Generated credentials excluded from Git
- Automated syntax and health validation

## Automation Workflows

### System Information

Collects hostname, Linux distribution, architecture, memory, processor count, and an execution confirmation marker.

### Resource Reporting

Collects filesystem usage, memory usage, highest CPU-consuming processes, and host information.

## Technology Stack

AWX, AWX Operator, Ansible, Kubernetes, kind, Docker, PostgreSQL, Git, Python, REST APIs, YAML, jq, and OpenSSL.

## Repository Structure

    awx-centralized-orchestration/
    ├── cluster/
    │   └── kind-awx.yml
    ├── operator/
    │   └── kustomization.yaml
    ├── manifests/
    │   ├── internal-scm.yml
    │   └── platform-awx.yml
    ├── playbooks/
    │   └── centralized-operations/
    │       ├── inventory.ini
    │       ├── requirements.yml
    │       ├── resource-report.yml
    │       └── system-information.yml
    ├── artifacts/
    ├── secrets/
    ├── .gitignore
    ├── requirements.txt
    └── README.md

## Deployment Flow

    Prepare Docker and Python
            |
            v
    Create kind cluster
            |
            v
    Install persistent storage
            |
            v
    Install AWX Operator
            |
            v
    Deploy AWX and PostgreSQL
            |
            v
    Deploy internal Git service
            |
            v
    Synchronize playbooks
            |
            v
    Create inventory and templates
            |
            v
    Launch and verify automation

## Verification

Check AWX resources:

    kubectl get nodes
    kubectl get pods -n awx
    kubectl get services -n awx
    kubectl get pvc -n awx

Verify the API:

    curl -fsS http://127.0.0.1:30080/api/v2/ping/ | jq .

Verify authenticated access:

    curl -fsS \
      --user "admin:$(cat secrets/admin-password.txt)" \
      http://127.0.0.1:30080/api/v2/me/ \
      | jq .

Validate playbooks:

    source .venv/bin/activate

    ansible-playbook \
      --syntax-check \
      -i playbooks/centralized-operations/inventory.ini \
      playbooks/centralized-operations/system-information.yml

    ansible-playbook \
      --syntax-check \
      -i playbooks/centralized-operations/inventory.ini \
      playbooks/centralized-operations/resource-report.yml

## Troubleshooting

Inspect workloads:

    kubectl get pods -n awx -o wide

Inspect recent events:

    kubectl get events \
      -n awx \
      --sort-by='.lastTimestamp' \
      | tail -n50

Inspect operator logs:

    kubectl logs \
      deployment/awx-operator-controller-manager \
      -n awx \
      -c awx-manager \
      --tail=200

Inspect internal Git logs:

    kubectl logs \
      deployment/awx-internal-scm \
      -n awx \
      --tail=100

## Security

- Generated credentials are excluded from Git
- Kubernetes secrets store controller credentials
- AWX provides execution history and audit visibility
- External access should be restricted to trusted addresses
- Production environments should use TLS and durable storage

## Skills Demonstrated

- AWX administration
- Kubernetes operations
- Ansible orchestration
- Container image construction
- Git-backed automation
- REST API integration
- Persistent storage configuration
- Inventory and template design
- Runtime troubleshooting
- Infrastructure observability

## Outcome

This implementation demonstrates how Ansible can be operated as a centralized, repeatable, and auditable automation platform through AWX.
