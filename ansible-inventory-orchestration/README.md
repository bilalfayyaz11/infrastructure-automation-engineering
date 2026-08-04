# Ansible Inventory Orchestration

## What This Does

This implementation provides a production-style Ansible inventory system using equivalent INI and YAML static inventories, hierarchical group and host variables, an API-backed dynamic inventory source, and automated validation.

The static inventory models production web, database, and load-balancer tiers alongside a separate development environment. The dynamic inventory queries a local HTTP API, converts instance metadata into Ansible groups, and exposes connection details through `_meta.hostvars`.

## Architecture

    ┌───────────────────────────────────────────────────────┐
    │                Ansible Inventory Sources              │
    └──────────────────────────┬────────────────────────────┘
                               │
              ┌────────────────┴────────────────┐
              │                                 │
              ▼                                 ▼
    ┌──────────────────────┐         ┌────────────────────────┐
    │ Static Inventory     │         │ Dynamic Inventory      │
    │                      │         │                        │
    │ hosts.ini            │         │ dynamic_inventory.py   │
    │ hosts.yml            │         │          │             │
    │ group_vars/          │         │          ▼             │
    │ host_vars/           │         │ HTTP API :8080         │
    └──────────┬───────────┘         └──────────┬─────────────┘
               │                                │
               └────────────────┬───────────────┘
                                ▼
    ┌───────────────────────────────────────────────────────┐
    │              ansible-inventory Processing             │
    │                                                       │
    │  Static groups: production, development, tier groups  │
    │  Dynamic groups: role_*, environment_*, team_*        │
    │  Variables: group_vars, host_vars, _meta.hostvars     │
    └──────────────────────────┬────────────────────────────┘
                               ▼
    ┌───────────────────────────────────────────────────────┐
    │                    validate.py                        │
    │                                                       │
    │  Executes ansible-inventory --list                    │
    │  Parses JSON                                          │
    │  Counts groups and hosts                              │
    │  Returns PASS/FAIL with exit code 0 or 1              │
    └───────────────────────────────────────────────────────┘

## Repository Structure

    ansible-inventory-orchestration/
    ├── ansible.cfg
    ├── validate.py
    ├── static/
    │   ├── ini/hosts.ini
    │   └── yaml/hosts.yml
    ├── group_vars/
    │   ├── production.yml
    │   ├── webservers.yml
    │   └── databases.yml
    ├── host_vars/
    │   └── web01.yml
    ├── dynamic/
    │   ├── api_server.py
    │   └── dynamic_inventory.py
    └── playbooks/

## Inventory Design

The static inventory represents the following hierarchy:

    production
    ├── webservers
    │   ├── web01
    │   └── web02
    ├── databases
    │   ├── db01
    │   └── db02
    └── loadbalancers
        ├── lb01
        └── lb02

    development
    ├── dev01
    └── dev02

The production group contains child groups instead of direct hosts. Variables are separated by scope through `group_vars` and `host_vars`.

The dynamic inventory retrieves six simulated instances from:

    http://127.0.0.1:8080/instances

Hosts are grouped using their metadata:

    Role=web                 → role_web
    Environment=production  → environment_production
    Team=platform           → team_platform

Each dynamic host includes `ansible_host`, instance metadata, and connection variables in `_meta.hostvars`.

## Prerequisites

- Ubuntu or another supported Linux distribution
- Python 3
- pipx
- Ansible
- Python requests library
- curl
- Git
- Available local TCP port 8080

## Setup

Install pipx and Ansible:

    sudo apt update
    sudo apt install -y pipx
    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
    pipx install --include-deps ansible

Verify the toolchain:

    ansible --version
    ansible-inventory --version
    python3 -c "import requests; print(requests.__version__)"

## How to Reproduce

Clone the repository:

    git clone https://github.com/bilalfayyaz11/infrastructure-automation-engineering.git
    cd infrastructure-automation-engineering/ansible-inventory-orchestration

Validate the static inventories:

    ansible-inventory -i static/ini/hosts.ini --graph
    ansible-inventory -i static/yaml/hosts.yml --graph

Inspect merged variables for `web01`:

    ansible-inventory -i static/yaml/hosts.yml --host web01

Start the local inventory API:

    nohup python3 dynamic/api_server.py \
      > dynamic/api_server.log 2>&1 &

    echo $! > dynamic/api_server.pid

Verify the API:

    curl -fsSL http://127.0.0.1:8080/instances \
      | python3 -m json.tool

Inspect the dynamic inventory:

    dynamic/dynamic_inventory.py --list \
      | python3 -m json.tool

    ansible-inventory \
      -i dynamic/dynamic_inventory.py \
      --graph

Validate all inventory sources:

    python3 validate.py \
      static/ini/hosts.ini \
      static/yaml/hosts.yml \
      dynamic/dynamic_inventory.py

Expected validation format:

    PASS static/ini/hosts.ini: 5 groups, 8 hosts
    PASS static/yaml/hosts.yml: 5 groups, 8 hosts
    PASS dynamic/dynamic_inventory.py: 7 groups, 6 hosts

Stop the API when finished:

    kill "$(cat dynamic/api_server.pid)"
    rm -f dynamic/api_server.pid

## Tools Used

- Ansible
- Python 3
- Python requests
- Python HTTP server
- YAML
- INI
- JSON
- HTTP
- pipx
- curl
- Git
- Ubuntu Linux

## Key Skills Demonstrated

- Designing multi-environment Ansible inventories
- Maintaining equivalent INI and YAML formats
- Implementing parent and child groups
- Applying group and host variable inheritance
- Building executable dynamic inventory sources
- Consuming HTTP APIs with Python
- Transforming metadata into Ansible groups
- Producing `_meta.hostvars`
- Validating infrastructure definitions programmatically
- Returning reliable process exit codes

## Real-World Use Case

Platform and infrastructure teams can use this pattern to combine stable, version-controlled hosts with dynamically discovered cloud resources. Playbooks remain independent of infrastructure location because host definitions, metadata, and environment-specific variables are managed through inventory sources.

## Lessons Learned

- Static formats should produce equivalent hosts and group hierarchies.
- Parent groups should reference child groups rather than duplicate hosts.
- Inventory structure and scoped variables should remain separate.
- Dynamic inventory scripts must emit only valid JSON to standard output.
- Every dynamic host should include connection data in `_meta.hostvars`.
- External metadata should be normalized before becoming group names.
- Inventory behavior should be validated automatically.

## Troubleshooting Log

### Ansible installation

System-level `sudo pip3 install ansible` can conflict with Ubuntu's managed Python environment. Ansible was installed safely through pipx:

    sudo apt install -y pipx
    pipx install --include-deps ansible

### Dynamic inventory parsing

Debug output printed to standard output corrupts inventory JSON. The dynamic script sends only JSON to standard output and sends errors to standard error.

### Executable permissions

The inventory source must be executable:

    chmod 755 dynamic/dynamic_inventory.py

### API connectivity

Check the process, port, log, and endpoint:

    kill -0 "$(cat dynamic/api_server.pid)"
    ss -ltnp | grep ':8080'
    cat dynamic/api_server.log
    curl -fsSL http://127.0.0.1:8080/instances
