# Fact-Driven Ansible Resource Orchestration

## What This Does

This implementation demonstrates advanced Ansible automation using variable-driven loops, dictionary iteration, gathered host facts, Jinja2 branching, per-item conditions, and idempotent resource management.

It provisions local service accounts, creates controlled directory structures, generates service configuration files from dictionaries, installs operating-system-specific packages, classifies the host according to memory and CPU capacity, and creates deployment markers only when application requirements are satisfied.

Every resource name, filesystem path, package, threshold, and configuration value is defined through variables rather than repeated directly across automation actions.

## Architecture

    ┌───────────────────────────────────────────────────────────────┐
    │                    Ansible Control Node                       │
    │                                                               │
    │  Local Inventory                                             │
    │  Central Configuration                                       │
    │  Python Virtual Environment                                  │
    │  Persistent Execution Log                                    │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                     Variable Definitions                      │
    │                                                               │
    │  Service Accounts                                            │
    │  Directory Definitions                                       │
    │  Service Dictionary                                          │
    │  Package List                                                │
    │  Application Requirements                                    │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                      Loop Processing                          │
    │                                                               │
    │  with_items → Service Accounts                               │
    │  loop → Directory Hierarchy                                  │
    │  dict2items → Service Configuration Files                    │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                       Host Fact Analysis                      │
    │                                                               │
    │  Distribution                                                │
    │  Operating-System Family                                     │
    │  Total Memory                                                │
    │  Processor Count                                             │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                    Conditional Execution                      │
    │                                                               │
    │  Debian Package Installation                                 │
    │  Memory-Tier Classification                                  │
    │  CPU-Tier Classification                                     │
    │  Per-Application Eligibility                                 │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                     Result Verification                       │
    │                                                               │
    │  Account State                                               │
    │  Directory Ownership                                         │
    │  Configuration Content                                       │
    │  Deployment Marker Set                                       │
    │  Second-Run Idempotence                                      │
    └───────────────────────────────────────────────────────────────┘

## Repository Structure

    ansible-fact-driven-orchestration/
    ├── ansible.cfg
    ├── inventory/
    │   └── hosts.ini
    ├── playbooks/
    │   ├── loops.yml
    │   └── conditionals.yml
    ├── artifacts/
    │   └── .gitkeep
    ├── logs/
    │   └── .gitkeep
    ├── requirements.txt
    ├── .gitignore
    └── README.md

## Prerequisites

- Ubuntu 24.04 or another modern Linux distribution
- Python 3
- Python virtual-environment support
- pip
- Git
- Bash
- sudo access
- Internet connectivity for package installation

## Setup

Install the required operating-system packages:

    sudo apt update

    sudo apt install -y \
      python3-pip \
      python3-venv \
      python3-dev \
      build-essential \
      git \
      curl \
      ca-certificates

Create and activate the Python environment:

    python3 -m venv .venv
    source .venv/bin/activate

Install Ansible:

    python -m pip install --upgrade \
      pip \
      setuptools \
      wheel

    python -m pip install ansible-core

Verify the installation:

    ansible --version
    ansible-playbook --version
    ansible-inventory --version

## Local Inventory

The inventory targets localhost without SSH:

    [local]
    localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3

Verify the inventory:

    ansible-inventory --graph

Verify local connectivity:

    ansible \
      localhost \
      -m ansible.builtin.ping

Expected response:

    localhost | SUCCESS
    "ping": "pong"

## Ansible Configuration

The configuration provides:

    inventory = ./inventory/hosts.ini
    host_key_checking = False
    retry_files_enabled = False
    interpreter_python = auto_silent
    stdout_callback = default
    result_format = yaml
    log_path = ./logs/ansible.log

Privilege escalation is configured through sudo for system-level resource management.

Verify active settings:

    ansible-config dump --only-changed

## Loop-Driven Resource Provisioning

The `loops.yml` playbook manages three resource categories entirely through variables.

### Managed Service Accounts

The account definitions include:

    name
    shell
    comment

Four system accounts are created:

    apiworker
    queueworker
    metricworker
    auditworker

The account action uses the legacy iteration syntax:

    with_items: "{{ managed_users }}"

Each account:

- Is created as a system account
- Has no home directory
- Uses `/usr/sbin/nologin`
- Receives a descriptive comment
- Is created only when missing

## Managed Directories

Directory definitions include:

    path
    owner
    group
    mode

The playbook creates:

    /opt/platform-api/config
    /opt/platform-queue/config
    /opt/platform-metrics/config
    /var/lib/platform-audit/config

The directory action uses the modern syntax:

    loop: "{{ managed_directories }}"

Each path is created with:

    Mode: 0750
    Owner: Matching service account
    Group: Matching service account

## Service Dictionary Iteration

Service definitions are stored as a dictionary.

Example:

    platform_api:
      port: 8080
      config_dir: /opt/platform-api/config
      owner: apiworker
      group: apiworker

The playbook converts the dictionary into iterable key-value entries:

    loop: "{{ managed_services | ansible.builtin.dict2items }}"

Inside the loop:

    item.key

contains the service name, while:

    item.value

contains its port, configuration directory, owner, and group.

## Generated Service Configuration

Each service receives:

    service.conf

Example content:

    service_name=platform_api
    service_port=8080
    config_directory=/opt/platform-api/config

Configuration files use:

    Mode: 0640

Ownership matches the service account associated with each definition.

## Running Loop-Based Provisioning

Activate the Python environment:

    source .venv/bin/activate

Validate syntax:

    ansible-playbook \
      --syntax-check \
      playbooks/loops.yml

Run the playbook:

    ansible-playbook \
      playbooks/loops.yml

Inspect configuration files:

    sudo cat \
      /opt/platform-api/config/service.conf

    sudo cat \
      /opt/platform-queue/config/service.conf

    sudo cat \
      /opt/platform-metrics/config/service.conf

Verify directory state:

    stat -c \
      'Path=%n Owner=%U Group=%G Mode=%a' \
      /opt/platform-api/config \
      /opt/platform-queue/config \
      /opt/platform-metrics/config \
      /var/lib/platform-audit/config

## Host Fact Gathering

The `conditionals.yml` playbook gathers host facts before applying decisions.

The displayed facts include:

    distribution
    os_family
    memory_mb
    processor_count

Inspect the same values directly:

    ansible \
      localhost \
      -m ansible.builtin.setup \
      -a 'filter=ansible_distribution*'

    ansible \
      localhost \
      -m ansible.builtin.setup \
      -a 'filter=ansible_memtotal_mb'

    ansible \
      localhost \
      -m ansible.builtin.setup \
      -a 'filter=ansible_processor_count'

## Operating-System Conditional

A package list is stored in:

    debian_packages

The packages are installed only when:

    ansible_facts['os_family'] == 'Debian'

The configured package set includes:

    curl
    jq
    unzip

This keeps package selection separate from the conditional action.

## Memory-Based Resource Profile

The playbook creates:

    /tmp/resource-profile.txt

A Jinja2 conditional selects one of three memory tiers.

### Small

Condition:

    memory_mb < 2048

Result:

    memory_tier=small
    workload_profile=lightweight

### Medium

Condition:

    memory_mb >= 2048
    memory_mb < 8192

Result:

    memory_tier=medium
    workload_profile=standard

### Large

Condition:

    memory_mb >= 8192

Result:

    memory_tier=large
    workload_profile=high-capacity

Inspect the result:

    cat /tmp/resource-profile.txt

## CPU-Based Execution Profile

The playbook also creates:

    /tmp/cpu-profile.txt

### Small CPU Tier

Condition:

    processor_count < 4

Result:

    cpu_tier=small
    parallel_workers=2

### Medium CPU Tier

Condition:

    processor_count >= 4
    processor_count < 8

Result:

    cpu_tier=medium
    parallel_workers=4

### High CPU Tier

Condition:

    processor_count >= 8

Result:

    cpu_tier=high
    parallel_workers=8

Inspect the result:

    cat /tmp/cpu-profile.txt

## Per-Application Eligibility

Each application definition contains:

    name
    environment
    min_memory_mb

The configured entries include production and development workloads with different memory requirements.

A marker is created only when:

    ansible_facts['memtotal_mb'] >= item.min_memory_mb

Example eligible marker:

    /tmp/telemetry-api-deployment.marker

Example content:

    application=telemetry-api
    environment=production
    required_memory_mb=2048
    actual_memory_mb=15832
    deployment_status=eligible

Applications that exceed the host's available memory do not receive markers.

## Stale Marker Removal

The automation also removes markers for entries that are no longer eligible.

This prevents an old success marker from remaining after:

- Memory requirements increase
- Host resources decrease
- Application definitions change

The resulting marker set always reflects the current variables and current host facts.

## Running Fact-Driven Configuration

Validate syntax:

    ansible-playbook \
      --syntax-check \
      playbooks/conditionals.yml

Run the playbook:

    ansible-playbook \
      playbooks/conditionals.yml

Inspect profiles:

    cat /tmp/resource-profile.txt
    cat /tmp/cpu-profile.txt

List deployment markers:

    find /tmp \
      -maxdepth 1 \
      -type f \
      -name '*-deployment.marker' \
      -printf '%f\n' \
      | sort

Inspect a marker:

    cat /tmp/telemetry-api-deployment.marker

## Idempotence

Both playbooks are designed to converge toward stable state.

Run each playbook twice:

    ansible-playbook \
      playbooks/loops.yml

    ansible-playbook \
      playbooks/loops.yml

    ansible-playbook \
      playbooks/conditionals.yml

    ansible-playbook \
      playbooks/conditionals.yml

The second execution should report:

    changed=0
    failed=0

This confirms that existing accounts, directories, files, packages, profiles, and markers are not unnecessarily modified.

## Verification Commands

### Accounts

    getent passwd apiworker
    getent passwd queueworker
    getent passwd metricworker
    getent passwd auditworker

### Directory Ownership

    stat -c \
      '%n %U:%G %a' \
      /opt/platform-api/config \
      /opt/platform-queue/config \
      /opt/platform-metrics/config \
      /var/lib/platform-audit/config

### Service Configuration

    sudo grep -R \
      -E 'service_name|service_port|config_directory' \
      /opt/platform-api/config \
      /opt/platform-queue/config \
      /opt/platform-metrics/config

### Package State

    dpkg-query \
      -W \
      -f='${Package} ${Status}\n' \
      curl \
      jq \
      unzip

### Resource Profiles

    cat /tmp/resource-profile.txt
    cat /tmp/cpu-profile.txt

### Marker State

    find /tmp \
      -maxdepth 1 \
      -type f \
      -name '*-deployment.marker' \
      -print \
      -exec cat {} \;

## Generated Runtime Resources

The automation creates:

    /opt/platform-api/config/
    /opt/platform-queue/config/
    /opt/platform-metrics/config/
    /var/lib/platform-audit/config/

It also creates:

    /tmp/resource-profile.txt
    /tmp/cpu-profile.txt
    /tmp/*-deployment.marker

System accounts created:

    apiworker
    queueworker
    metricworker
    auditworker

## Cleaning the Runtime State

Remove generated marker and profile files:

    sudo rm -f \
      /tmp/resource-profile.txt \
      /tmp/cpu-profile.txt \
      /tmp/*-deployment.marker

Remove managed directories:

    sudo rm -rf \
      /opt/platform-api \
      /opt/platform-queue \
      /opt/platform-metrics \
      /var/lib/platform-audit

Remove system accounts only when they are no longer required:

    sudo userdel apiworker
    sudo userdel queueworker
    sudo userdel metricworker
    sudo userdel auditworker

Rerun both playbooks to recreate the desired state.

## Ansible Logging

Execution output is recorded in:

    logs/ansible.log

Inspect recent activity:

    tail -n 100 logs/ansible.log

Generated log content is excluded from Git while the directory remains present through `.gitkeep`.

## Tools Used

- Ansible Core
- Python 3
- YAML
- Jinja2
- Bash
- Git
- Linux account management
- Linux filesystem utilities
- APT package management
- Ansible user resource interface
- Ansible filesystem resource interface
- Ansible managed-content interface
- Ansible package-management interface
- Ansible fact-gathering interface
- Ansible diagnostic-output interface
- `with_items`
- `loop`
- `dict2items`
- `when` conditions

## Key Skills Demonstrated

- Variable-driven automation
- Legacy loop compatibility
- Modern loop implementation
- Dictionary-to-list transformation
- Per-item labeling
- System account provisioning
- Directory ownership management
- Configuration-file generation
- Host fact gathering
- Operating-system branching
- Memory-based branching
- CPU-based branching
- Jinja2 conditional rendering
- Per-item resource eligibility
- Stale-state removal
- Package installation based on facts
- Exact result verification
- Declarative state management
- Second-run idempotence
- Local Ansible control-node configuration
- Structured execution logging

## Real-World Use Case

These patterns apply to infrastructure and platform environments where many similar resources must be managed consistently.

Examples include:

- Provisioning service identities
- Creating application directory hierarchies
- Generating service configuration files
- Installing distribution-specific dependencies
- Selecting workload profiles based on host capacity
- Controlling deployment eligibility
- Configuring worker counts according to CPU resources
- Deploying different components to differently sized hosts
- Maintaining consistent state across fleets

The same structure can be extended to cloud instances, container hosts, database servers, observability nodes, CI workers, and AI inference systems.

## Troubleshooting

### Ansible Cannot Be Found

Activate the Python environment:

    cd ~/ansible-advanced-automation
    source .venv/bin/activate

Verify:

    command -v ansible
    ansible --version

### Inventory Is Not Loaded

Run from the repository directory:

    cd ~/ansible-advanced-automation

Check:

    ansible --version
    ansible-inventory --graph

The active configuration should be:

    ~/ansible-advanced-automation/ansible.cfg

### Privilege Escalation Fails

Verify passwordless sudo:

    sudo -n true

Test Ansible privilege escalation:

    ansible \
      localhost \
      -b \
      -m ansible.builtin.command \
      -a 'id -u'

Expected output:

    stdout: "0"

### User Creation Fails

Check whether the account already exists:

    getent passwd apiworker

Verify the configured shell:

    getent passwd apiworker \
      | cut -d: -f7

Expected value:

    /usr/sbin/nologin

### Directory Ownership Is Incorrect

Inspect the path:

    stat -c \
      '%n %U:%G %a' \
      /opt/platform-api/config

Reapply the loop playbook:

    ansible-playbook \
      playbooks/loops.yml

### Configuration Content Is Incorrect

Inspect the source dictionary:

    grep -A8 \
      'managed_services:' \
      playbooks/loops.yml

Inspect the generated file:

    sudo cat \
      /opt/platform-api/config/service.conf

Reapply the playbook after correcting variables.

### Memory Profile Does Not Match the Host

Gather the Ansible value:

    ansible \
      localhost \
      -m ansible.builtin.setup \
      -a 'filter=ansible_memtotal_mb'

Compare it with:

    cat /tmp/resource-profile.txt

The profile is rendered from the gathered Ansible fact, not from the human-readable value shown by `free -h`.

### Expected Marker Is Missing

Inspect the application's requirement:

    grep -A20 \
      'application_entries:' \
      playbooks/conditionals.yml

Check actual memory:

    ansible \
      localhost \
      -m ansible.builtin.setup \
      -a 'filter=ansible_memtotal_mb'

A marker is created only when actual memory meets or exceeds the configured minimum.

### Ineligible Marker Still Exists

Rerun:

    ansible-playbook \
      playbooks/conditionals.yml

The stale-marker removal action deletes markers for applications that no longer satisfy their memory requirement.

### Second Execution Reports Changes

Review the recap and identify the changing action:

    ansible-playbook \
      playbooks/conditionals.yml \
      -vv

Possible causes include:

- Variables changed between runs
- File content changed manually
- Ownership or permissions were modified outside Ansible
- A package was removed
- An account was altered
- A generated marker was deleted manually

## Lessons Learned

- Resource names should be stored in variables instead of repeated across automation actions.
- `with_items` remains useful when maintaining older Ansible content.
- `loop` provides a consistent modern iteration interface.
- `dict2items` enables structured dictionary processing.
- Gathered facts allow one playbook to adapt to different hosts.
- Package installation should follow operating-system family checks.
- Jinja2 branching can generate one deterministic file from several possible host states.
- Loop conditions enable per-resource eligibility decisions.
- Stale resources must be removed when conditions become false.
- Verification should compare generated state with source variables.
- Idempotence confirms that automation converges instead of repeatedly changing stable resources.
- Variables, facts, loops, and conditions form the foundation of maintainable Ansible orchestration.
