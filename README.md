# Ansible Infrastructure Automation Engineering

A recruiter-focused collection of production-oriented Ansible implementations covering configuration management, infrastructure orchestration, security automation, container platforms, CI/CD integration, testing, centralized operations, and distributed cloud environments.

The repository demonstrates how Ansible can be used as a unified automation layer across Linux systems, Docker, Kubernetes, Jenkins, AWX, hybrid infrastructure, and cloud platforms.

---

## Portfolio Overview

This repository contains **15 selected implementations** from a broader Ansible learning path.

Only implementations with meaningful engineering depth, operational relevance, troubleshooting value, and recruiter-facing potential are included.

The work demonstrates capabilities aligned with:

* AIOps Engineering
* Applied AI Infrastructure
* DevSecOps Engineering
* Platform Engineering
* Cloud Engineering
* Site Reliability Engineering
* Infrastructure Automation

---

## Implementation Index

| #  | What Was Built                                                                                  | Key Technologies                                                 | Level        | Repository                                                   |
| -- | ----------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- | ------------ | ------------------------------------------------------------ |
| 1  | Static and API-driven infrastructure inventory orchestration                                    | Ansible Inventory, YAML, JSON, REST APIs, Python                 | Intermediate | [View Implementation](./ansible-inventory-orchestration)     |
| 2  | Adaptive configuration using variables, precedence, registered output, and system facts         | Ansible Variables, Facts, Jinja2, YAML                           | Intermediate | [View Implementation](./ansible-variable-fact-orchestration) |
| 3  | Secure secrets automation with encrypted configuration and runtime credential handling          | Ansible Vault, Encryption, YAML, Linux Security                  | Intermediate | [View Implementation](./ansible-vault-security-automation)   |
| 4  | Repeatable infrastructure execution with measurable idempotence validation                      | Ansible, Idempotence, Assertions, State Verification             | Intermediate | [View Implementation](./ansible-idempotence-verification)    |
| 5  | Fact-driven resource orchestration that adapts to host capabilities and operating conditions    | Ansible Facts, Conditionals, Jinja2, System Resources            | Advanced     | [View Implementation](./ansible-fact-driven-orchestration)   |
| 6  | Automated deployment of a secure multi-tier application architecture                            | Ansible, NGINX, Application Services, Database Services, Linux   | Advanced     | [View Implementation](./ansible-multitier-application)       |
| 7  | Linux security baseline enforcement through reusable automation                                 | Ansible, Linux Hardening, SSH Security, Firewall, Audit Controls | Advanced     | [View Implementation](./ansible-linux-security-baseline)     |
| 8  | Resilient automation with structured failure handling, retries, recovery blocks, and validation | Ansible Blocks, Rescue, Always, Assertions, Error Handling       | Advanced     | [View Implementation](./ansible-resilient-error-handling)    |
| 9  | Multi-platform role validation using isolated infrastructure testing                            | Ansible Molecule, Docker, Testinfra, Role Testing                | Advanced     | [View Implementation](./ansible-molecule-validation)         |
| 10 | Centralized automation control and execution through AWX                                        | AWX, Ansible, Docker, Inventory, Credentials, Templates          | Advanced     | [View Implementation](./awx-centralized-orchestration)       |
| 11 | Secure Jenkins-driven Ansible delivery workflow                                                 | Jenkins, Ansible, CI/CD, Credentials, Pipeline Automation        | Advanced     | [View Implementation](./jenkins-ansible-delivery)            |
| 12 | Kubernetes resource orchestration using Ansible modules                                         | Ansible, Kubernetes, Minikube, kubectl, YAML                     | Advanced     | [View Implementation](./ansible-kubernetes-orchestration)    |
| 13 | Complete Kubernetes application lifecycle automation                                            | Ansible, Kubernetes, Docker, Minikube, Metrics Server, NGINX     | Advanced     | [View Implementation](./ansible-kubernetes-automation)       |
| 14 | Hybrid infrastructure and distributed service delivery across simulated environments            | Ansible, Docker, PostgreSQL, Redis, MySQL, Prometheus, NGINX     | Advanced     | [View Implementation](./hybrid-cloud-automation)             |
| 15 | Dynamic infrastructure orchestration driven by discovered system state                          | Ansible, Facts, Conditionals, Resource Validation, Linux         | Advanced     | [View Implementation](./ansible-fact-driven-orchestration)   |

---

## Engineering Progression

The implementations follow a deliberate progression from foundational automation to distributed infrastructure management.

### Configuration Foundation

The initial implementations establish the core mechanics required for reliable Ansible engineering:

* Inventory organization
* Host and group variables
* Fact gathering
* Variable precedence
* Secure secret handling
* Module execution
* Idempotent state management

### Application and Security Automation

The next layer applies Ansible to complete operational outcomes:

* Multi-tier application deployment
* Linux security enforcement
* Conditional configuration
* Service validation
* Failure recovery
* Defensive execution
* Reusable automation patterns

### Validation and Centralized Operations

The repository then introduces professional automation governance:

* Molecule-based testing
* Multi-platform validation
* AWX centralized execution
* Credential isolation
* Controlled inventory management
* Repeatable execution templates
* Automated CI/CD delivery

### Container and Distributed Infrastructure

The advanced implementations extend Ansible into modern platform environments:

* Kubernetes resource orchestration
* Application lifecycle automation
* Container health validation
* Service discovery
* Deployment scaling
* Metrics collection
* Hybrid infrastructure simulation
* Cross-environment traffic management
* Load balancing and observability

---

## Architecture Coverage

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Ansible Automation Control                      │
│                                                                     │
│  Inventories • Variables • Facts • Vault • Roles • Playbooks       │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
           ┌────────────────────┼────────────────────┐
           │                    │                    │
           ▼                    ▼                    ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐
│ Linux Systems    │  │ CI/CD Platforms │  │ Container Platforms  │
│                  │  │                  │  │                      │
│ Configuration    │  │ Jenkins          │  │ Docker               │
│ Hardening        │  │ AWX              │  │ Kubernetes           │
│ Packages         │  │ Delivery Gates   │  │ Minikube             │
│ Services         │  │ Credentials      │  │ Metrics Server       │
└─────────┬────────┘  └─────────┬────────┘  └──────────┬───────────┘
          │                     │                      │
          └─────────────────────┼──────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Distributed Infrastructure                       │
│                                                                     │
│  On-Premises Simulation • Cloud Simulation • Hybrid Networking     │
│  Databases • Caching • Monitoring • Load Balancing • Web Services  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Technical Capabilities

### Ansible Engineering

* Structured inventory design
* Host and group variable management
* Fact-based decision-making
* Conditional task execution
* Registered output processing
* Jinja2 templating
* Handler-based service control
* Reusable automation structures
* Fully qualified collection modules
* Idempotent state enforcement

### Security Automation

* Encrypted secrets with Ansible Vault
* Secure runtime credential handling
* Linux baseline enforcement
* SSH hardening
* Firewall configuration
* Permission validation
* Secret-file protection
* Controlled privilege escalation

### Reliability and Troubleshooting

* Structured error handling
* Block, rescue, and always workflows
* Retry and timeout logic
* Assertions and precondition checks
* Post-deployment validation
* Service health checks
* Idempotency testing
* Safe cleanup procedures
* Defensive resource verification

### CI/CD and Centralized Operations

* Jenkins pipeline integration
* AWX inventory and credential management
* Centralized execution templates
* Automated deployment validation
* Secure pipeline credential usage
* Repeatable infrastructure delivery
* Operational workflow standardization

### Kubernetes and Container Automation

* Namespace management
* Deployment creation
* Service configuration
* Horizontal scaling
* Rolling image updates
* Readiness and liveness probes
* Resource requests and limits
* Endpoint verification
* Metrics Server integration
* Container lifecycle management

### Distributed Infrastructure

* Isolated Docker network design
* Multi-environment service deployment
* PostgreSQL and MySQL automation
* Redis caching
* Prometheus monitoring
* NGINX load balancing
* Cross-network service discovery
* Multi-instance application delivery
* Persistent storage configuration
* End-to-end health validation

---

## Tools and Technologies

| Category                | Technologies                                                |
| ----------------------- | ----------------------------------------------------------- |
| Automation              | Ansible Core, Ansible Vault, Ansible Galaxy                 |
| Control Platforms       | AWX, Jenkins                                                |
| Testing                 | Molecule, Testinfra, Docker                                 |
| Containers              | Docker Engine, Docker Networks                              |
| Kubernetes              | Kubernetes, kubectl, Minikube, Metrics Server               |
| Operating Systems       | Ubuntu Linux, Debian-based Systems                          |
| Web and Proxy           | NGINX, Flask, Gunicorn                                      |
| Databases               | PostgreSQL, MySQL                                           |
| Caching                 | Redis                                                       |
| Monitoring              | Prometheus                                                  |
| Languages               | YAML, Python, Bash, Jinja2                                  |
| Version Control         | Git, GitHub                                                 |
| Security                | SSH Hardening, Firewall Rules, Encrypted Secrets            |
| Infrastructure Patterns | Idempotence, Infrastructure as Code, Declarative Automation |

---

## Troubleshooting Experience Demonstrated

The implementations intentionally include real operational failures and outdated patterns that were diagnosed and corrected.

Examples include:

* Docker socket permission failures
* Missing Python dependencies
* Ubuntu externally managed Python restrictions
* Unsupported Ansible module parameters
* Deprecated package names
* Invalid YAML indentation
* Incorrect Dockerfile JSON syntax
* Unavailable Ansible callback plugins
* Kubernetes rollout validation errors
* Unsafe partial resource updates
* Service selector and endpoint mismatches
* NGINX upstream connectivity failures
* Docker loopback networking limitations
* Container health-check failures
* CI/CD credential and permission problems
* Unsafe global cleanup commands
* Non-idempotent timestamp-based container names
* Incorrect assumptions about returned API structures

Each implementation documents the failure, root cause, corrected approach, and final validation.

---

## Operational Standards Applied

Every selected implementation follows the same engineering principles:

* Verify the environment before installation
* Install only missing dependencies
* Use isolated Python environments
* Prefer current supported syntax
* Avoid unnecessary privilege escalation
* Use stable and descriptive resource names
* Validate syntax before execution
* Verify runtime state after execution
* Test repeated execution for idempotence
* Add health checks to managed services
* Protect credentials and secrets
* Preserve unrelated host resources
* Document troubleshooting decisions
* Provide reproducible setup instructions
* Use controlled cleanup procedures

---

## Repository Structure

```
ansible-infrastructure-automation/
│
├── ansible-inventory-orchestration/
├── ansible-variable-fact-orchestration/
├── ansible-vault-security-automation/
├── ansible-idempotence-verification/
├── ansible-fact-driven-orchestration/
├── ansible-multitier-application/
├── ansible-linux-security-baseline/
├── ansible-resilient-error-handling/
├── ansible-molecule-validation/
├── awx-centralized-orchestration/
├── jenkins-ansible-delivery/
├── ansible-kubernetes-orchestration/
├── ansible-kubernetes-automation/
├── hybrid-cloud-automation/
└── README.md
```

Each directory contains its own documentation, architecture, prerequisites, reproduction steps, operational validation, lessons learned, and troubleshooting history.

---

## Skills Mapped to Target Roles

### Applied AI Engineer

* Infrastructure automation for model-serving platforms
* Kubernetes workload management
* Repeatable environment provisioning
* Service health validation
* Containerized application delivery
* Monitoring and resource visibility
* CI/CD integration

### AIOps Engineer

* Fact-driven automation
* Automated remediation patterns
* Infrastructure state validation
* Monitoring integration
* Failure recovery
* Distributed service health checks
* Centralized operations through AWX

### DevSecOps Engineer

* Secure secret handling
* Linux security enforcement
* Jenkins delivery workflows
* Controlled privilege usage
* Encrypted configuration
* Infrastructure compliance patterns
* Secure and repeatable automation

### Platform Engineer

* Standardized infrastructure workflows
* Kubernetes lifecycle automation
* Container networking
* Multi-environment service delivery
* Centralized control planes
* Reusable automation patterns
* Operational self-service foundations

---

## Portfolio Highlights

The strongest demonstrations in this repository include:

### Hybrid Infrastructure Automation

A distributed environment containing PostgreSQL, Redis, MySQL, Prometheus, NGINX, and multiple application instances across isolated Docker networks.

The implementation validates container health, database availability, load distribution, cross-network discovery, resource usage, and safe teardown.

### Kubernetes Lifecycle Automation

A complete Ansible-controlled Kubernetes workflow covering namespaces, deployments, services, scaling, image updates, health monitoring, metrics, and cleanup.

The automation validates exact replica state, service endpoints, rollout completion, container health, and repeated execution.

### Centralized AWX Orchestration

A centralized automation platform demonstrating inventories, credentials, execution templates, controlled automation, and infrastructure governance through AWX.

### Jenkins and Ansible Delivery

A CI/CD workflow connecting Jenkins with Ansible for secure, repeatable infrastructure and application delivery.

### Molecule Validation

An isolated testing workflow for validating Ansible roles across containerized environments before they are applied to real infrastructure.

### Linux Security Enforcement

A reusable security baseline covering system configuration, access restrictions, firewall controls, permissions, and validation.

---

## Professional Focus

This repository is designed to demonstrate more than basic playbook syntax.

It focuses on the engineering practices required to operate automation safely:

* Predictable execution
* Secure credential handling
* Repeatable outcomes
* Failure isolation
* Infrastructure validation
* Cross-platform compatibility
* Production-aware troubleshooting
* Clear operational documentation
* Controlled resource lifecycle management

---

## Author

**Bilal Fayyaz**

GitHub: [bilalfayyaz11](https://github.com/bilalfayyaz11)

Target roles:

* Applied AI Engineer
* AIOps Engineer
* DevSecOps Engineer
* Platform Engineer
* Cloud Automation Engineer

---

## Status

**15 recruiter-facing Ansible implementations completed and documented.**

Additional implementations will be added only when they demonstrate distinct technical depth, operational value, or production relevance.
