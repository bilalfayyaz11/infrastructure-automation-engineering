# Ansible Variable and Fact Orchestration

## What This Does

This implementation demonstrates how Ansible resolves variables across group, host, play, and extra-variable scopes. It also implements partial dictionary overrides, executable custom facts, selective system fact gathering, and conditional automation based on live host characteristics.

The automation adapts its behavior according to memory, operating-system family, CPU resources, mounted filesystems, and custom application metadata. Validation commands confirm variable precedence, fact discovery, conditional execution, and successful playbook completion.

## Architecture

    ┌───────────────────────────────────────────────────────┐
    │                 Ansible Inventory                     │
    │                                                       │
    │  inventory/hosts.ini                                  │
    │  ├── group_vars/local.yml                             │
    │  └── host_vars/localhost.yml                          │
    └──────────────────────────┬────────────────────────────┘
                               │
                               ▼
    ┌───────────────────────────────────────────────────────┐
    │                Variable Resolution                    │
    │                                                       │
    │  Group Variables                                      │
    │          ↓                                            │
    │  Host Variables                                       │
    │          ↓                                            │
    │  Play Variables                                       │
    │          ↓                                            │
    │  Extra Variables                                      │
    └──────────────────────────┬────────────────────────────┘
                               │
                               ▼
    ┌───────────────────────────────────────────────────────┐
    │              Deployment Configuration                 │
    │                                                       │
    │  Play-level defaults                                  │
    │          +                                            │
    │  External YAML overrides                              │
    │          ↓                                            │
    │  Explicit dictionary merge                            │
    └──────────────────────────┬────────────────────────────┘
                               │
                               ▼
    ┌───────────────────────────────────────────────────────┐
    │                Fact-Driven Automation                 │
    │                                                       │
    │  Native facts                                         │
    │  ├── Operating system                                 │
    │  ├── Memory                                           │
    │  ├── Processor cores                                  │
    │  └── Mounted filesystems                              │
    │                                                       │
    │  Custom facts                                         │
    │  └── /etc/ansible/facts.d/app_meta.fact               │
    └──────────────────────────┬────────────────────────────┘
                               │
                               ▼
    ┌───────────────────────────────────────────────────────┐
    │              Conditional Decisions                    │
    │                                                       │
    │  ├── Low or sufficient memory                         │
    │  ├── Debian or Red Hat behavior                       │
    │  └── Filesystem capacity evaluation                   │
    └───────────────────────────────────────────────────────┘

## Repository Structure

    ansible-variable-fact-orchestration/
    ├── ansible.cfg
    ├── README.md
    ├── inventory/
    │   ├── hosts.ini
    │   ├── group_vars/
    │   │   └── local.yml
    │   └── host_vars/
    │       └── localhost.yml
    ├── vars/
    │   └── production-overrides.yml
    └── playbooks/
        ├── group-host-precedence.yml
        ├── variable-precedence.yml
        ├── deployment-config.yml
        ├── deployment-config-merge.yml
        └── fact-driven-deployment.yml

## Variable Precedence

The implementation proves the following effective order:

    group variables
        ↓
    host variables
        ↓
    play variables
        ↓
    extra variables

Run the host-over-group test:

    ansible-playbook playbooks/group-host-precedence.yml

Expected value:

    Resolved log_level: host-scope

Run the play-level test:

    ansible-playbook playbooks/variable-precedence.yml

Expected value:

    Resolved log_level: play-scope

Run the extra-variable test:

    ansible-playbook playbooks/variable-precedence.yml \
      -e log_level=extravars-scope

Expected value:

    Resolved log_level: extravars-scope

## Dictionary Override Design

The default deployment configuration contains:

    environment: development
    version: 1.0.0
    replicas: 1

The external override changes only:

    environment: production
    replicas: 4

The playbook explicitly merges both dictionaries with Ansible's `combine` filter so the original version remains unchanged.

Run:

    ansible-playbook playbooks/deployment-config-merge.yml \
      -e @vars/production-overrides.yml

Expected result:

    Environment: production
    Version: 1.0.0
    Replicas: 4

## Custom Facts

The host exposes application metadata through:

    /etc/ansible/facts.d/app_meta.fact

The executable fact returns:

    app_version: 2.4.0
    deploy_env: production
    max_workers: 4

Inspect the custom facts:

    ansible local \
      -m ansible.builtin.setup \
      -a 'filter=ansible_local'

## Fact-Driven Automation

The main fact-driven playbook disables automatic fact gathering:

    gather_facts: false

It then gathers only required fact namespaces through explicit setup operations:

- Linux distribution
- Operating-system family
- Total memory
- Processor cores
- Mounted filesystems
- Local custom facts

Run:

    ansible-playbook -v playbooks/fact-driven-deployment.yml

The playbook performs:

- Low-memory or sufficient-memory evaluation
- Debian-family or Red Hat-family branching
- Filesystem available-space calculations
- Custom application metadata inspection

Exactly one memory branch runs during each execution.

## Prerequisites

- Ubuntu or another supported Linux distribution
- Python 3
- pipx
- Ansible
- PyYAML
- sudo privileges
- systemd-compatible Linux environment

## Setup

Install pipx:

    sudo apt update
    sudo apt install -y pipx

Configure the executable path:

    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"

Install Ansible:

    pipx install --include-deps ansible

Verify the toolchain:

    ansible --version
    ansible-playbook --version
    ansible-inventory --version

## How to Reproduce

Clone the repository:

    git clone https://github.com/bilalfayyaz11/infrastructure-automation-engineering.git

Enter the implementation directory:

    cd infrastructure-automation-engineering/ansible-variable-fact-orchestration

Verify inventory connectivity:

    ansible-inventory --graph
    ansible local -m ansible.builtin.ping

Validate all playbooks:

    ansible-playbook --syntax-check playbooks/group-host-precedence.yml
    ansible-playbook --syntax-check playbooks/variable-precedence.yml
    ansible-playbook --syntax-check playbooks/deployment-config.yml
    ansible-playbook --syntax-check playbooks/deployment-config-merge.yml
    ansible-playbook --syntax-check playbooks/fact-driven-deployment.yml

Run precedence validation:

    ansible-playbook playbooks/group-host-precedence.yml
    ansible-playbook playbooks/variable-precedence.yml
    ansible-playbook playbooks/variable-precedence.yml \
      -e log_level=extravars-scope

Run dictionary merging:

    ansible-playbook playbooks/deployment-config-merge.yml \
      -e @vars/production-overrides.yml

Run fact-driven automation:

    ansible-playbook -v playbooks/fact-driven-deployment.yml

## Tools Used

- Ansible
- YAML
- Python 3
- PyYAML
- pipx
- Ubuntu Linux
- Jinja2 expressions
- Custom Ansible facts
- Linux filesystem and hardware facts

## Key Skills Demonstrated

- Designing layered Ansible variable architecture
- Verifying variable precedence through runtime output
- Separating group and host inventory variables
- Applying play-level and extra-variable overrides
- Merging nested configuration dictionaries explicitly
- Loading external YAML values
- Creating executable local custom facts
- Selectively gathering system facts
- Writing portable conditional automation
- Evaluating memory and operating-system facts
- Iterating real filesystem mount data
- Validating playbook output and exit status

## Real-World Use Case

Infrastructure and platform teams can use this pattern to maintain reusable playbooks across development, staging, and production environments. Shared defaults remain stable while host, environment, and runtime values override only the configuration they own.

Live system facts allow the same automation to adapt to different operating systems, instance sizes, CPU resources, filesystem layouts, and application metadata without manually changing host-specific logic.

## Lessons Learned

- Host variables override group variables, while play variables override inventory variables.
- Extra variables have the highest precedence in this implementation.
- Partial dictionaries should be merged explicitly rather than relying on automatic nested merging.
- Inventory variable directories should be placed beside the active inventory source.
- Custom fact scripts must be executable and return valid JSON.
- Selective setup operations reduce unnecessary fact collection.
- Mutually exclusive conditions should be validated to ensure only one branch executes.
- Mount information must be gathered explicitly before filesystem conditions can run.

## Troubleshooting Log

### Inventory variables were undefined

The initial variable directories were outside the active inventory directory, so Ansible did not load them reliably.

They were moved to:

    inventory/group_vars/
    inventory/host_vars/

### Incorrect precedence assumption

A play-level variable overrides group and host variables. A separate playbook without a play-level value was used to demonstrate host-over-group precedence accurately.

### Partial dictionary replacement

An external extra-variable dictionary would normally replace the complete play-level dictionary.

The implementation uses:

    deployment_config | combine(deployment_overrides, recursive=True)

This preserves values that are not present in the override file.

### System Python package protection

Ansible was installed through pipx rather than system-level pip to avoid conflicts with Ubuntu's managed Python environment.

### Missing custom fact directory

The required directory was created with:

    sudo mkdir -p /etc/ansible/facts.d

The custom fact was made executable with:

    sudo chmod 755 /etc/ansible/facts.d/app_meta.fact
