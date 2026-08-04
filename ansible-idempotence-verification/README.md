# Ansible Idempotence Verification

## What This Does

This implementation demonstrates how to design, measure, and validate idempotent infrastructure automation with Ansible.

It first creates a deliberately non-idempotent configuration that produces repeated filesystem side effects on every execution. It then replaces those imperative patterns with declarative Ansible modules that converge to a stable system state.

A reusable three-run convergence harness captures each playbook execution, extracts the `changed` count from the play recap, and fails when the second or third run reports changes.

The implementation also provisions a production-style Nginx application baseline with package management, dedicated service identities, templates, handlers, configuration validation, HTTP health checks, permission assertions, and automated convergence testing.

## Architecture

    ┌────────────────────────────────────────────────────────────┐
    │                Non-Idempotent Baseline                     │
    │                                                            │
    │  Timestamp append                                          │
    │  Runtime-generated directories                             │
    │  Repeated configuration keys                               │
    │                                                            │
    │  Every run produces new side effects                       │
    └───────────────────────────┬────────────────────────────────┘
                                │
                                ▼
    ┌────────────────────────────────────────────────────────────┐
    │                 Declarative Replacement                    │
    │                                                            │
    │  ansible.builtin.file                                      │
    │  ansible.builtin.copy                                      │
    │  ansible.builtin.lineinfile                                │
    │                                                            │
    │  Stable content and explicit desired state                 │
    └───────────────────────────┬────────────────────────────────┘
                                │
                                ▼
    ┌────────────────────────────────────────────────────────────┐
    │                 Convergence Verification                   │
    │                                                            │
    │  Run 1  → initial state transition                         │
    │  Run 2  → must report changed=0                            │
    │  Run 3  → must report changed=0                            │
    │                                                            │
    │  Exit 0 → converged                                        │
    │  Exit 1 → non-idempotent                                   │
    │  Exit 2 → execution or parsing failure                     │
    └───────────────────────────┬────────────────────────────────┘
                                │
                                ▼
    ┌────────────────────────────────────────────────────────────┐
    │              Production Nginx Baseline                     │
    │                                                            │
    │  Dedicated appuser and appgroup                            │
    │  Fixed UID and GID                                         │
    │  Declarative package installation                          │
    │  Stable application configuration                          │
    │  Nginx virtual host template                               │
    │  conf.d monitoring configuration                           │
    │  Handler-controlled service changes                        │
    │  Syntax validation before reload                           │
    └───────────────────────────┬────────────────────────────────┘
                                │
                                ▼
    ┌────────────────────────────────────────────────────────────┐
    │                 Read-Only Assertions                       │
    │                                                            │
    │  Account and group validation                              │
    │  Package-state validation                                  │
    │  File ownership and permission checks                      │
    │  Nginx active and enabled checks                           │
    │  HTTP 200 and health endpoint checks                       │
    │                                                            │
    │  Expected recap: changed=0 and failed=0                    │
    └────────────────────────────────────────────────────────────┘

## Repository Structure

    ansible-idempotence-verification/
    ├── ansible.cfg
    ├── inventory.ini
    ├── playbooks/
    │   ├── non_idempotent.yml
    │   ├── idempotent_core.yml
    │   ├── system_baseline.yml
    │   └── assert_baseline.yml
    ├── templates/
    │   ├── appsite.conf.j2
    │   └── app.conf.j2
    ├── files/
    │   └── index.html
    ├── tests/
    │   ├── idempotence_contract.sh
    │   └── run_convergence_check.sh
    ├── .gitignore
    └── README.md

## Prerequisites

- Ubuntu 24.04 or another systemd-based Linux distribution
- Python 3
- Python virtual environments
- Ansible Core 2.14 or later
- Bash
- Git
- sudo access
- systemd
- curl
- Standard POSIX tools including `grep`, `awk`, `sed`, and `wc`

## Setup

Install the required control-node packages:

    sudo apt-get update -y
    sudo apt-get install -y python3 python3-venv tree

Create an isolated Ansible environment:

    python3 -m venv ~/ansible-venv

Install Ansible:

    ~/ansible-venv/bin/python -m pip install --upgrade pip
    ~/ansible-venv/bin/python -m pip install ansible

Activate the environment:

    export PATH="$HOME/ansible-venv/bin:$PATH"

Verify the installation:

    ansible --version
    ansible-playbook --version
    ansible-inventory --version

Confirm that Ansible can reach localhost:

    cd ~/ansible-idempotence-engineering
    ansible local -m ansible.builtin.ping

Expected result:

    localhost | SUCCESS

## Non-Idempotent Demonstration

The non-idempotent playbook intentionally creates a new side effect every time it runs.

It performs three unsafe patterns:

- Appends a current timestamp to a file
- Creates a directory with a runtime-generated name
- Appends the same configuration key repeatedly

Run it twice:

    ansible-playbook playbooks/non_idempotent.yml
    ansible-playbook playbooks/non_idempotent.yml

Inspect the repeated side effects:

    wc -l /tmp/ansible-non-idempotent-demo/execution-history.log

    find /tmp/ansible-non-idempotent-demo \
      -maxdepth 1 \
      -type d \
      -name 'runtime-*'

    grep -n '^application_mode=' \
      /tmp/ansible-non-idempotent-demo/application.conf

The second execution continues to report changes because the playbook defines actions rather than a stable desired state.

## Declarative Idempotent Replacement

The corrected playbook uses declarative modules:

- `ansible.builtin.file`
- `ansible.builtin.copy`
- `ansible.builtin.lineinfile`

Run it:

    ansible-playbook playbooks/idempotent_core.yml

Run it again:

    ansible-playbook playbooks/idempotent_core.yml

The second execution should report:

    changed=0
    failed=0

The implementation avoids:

- Runtime timestamps
- Random or epoch-based resource names
- Unbounded shell appends
- Duplicate configuration keys
- Shell and command modules for state management

## Filesystem Contract

Run the filesystem assertion contract:

    ./tests/idempotence_contract.sh

It confirms that:

- The managed execution-history file remains stable
- Only one runtime directory exists
- The application mode key appears at most once
- Declarative state remains unchanged across repeated execution

## Three-Run Convergence Harness

The convergence harness accepts a playbook path:

    ./tests/run_convergence_check.sh <playbook_path>

It executes the playbook exactly three times and stores logs under:

    /tmp/convergence_<timestamp>_<process-id>/

Each execution produces:

    run_1.log
    run_2.log
    run_3.log

The harness extracts the `changed=N` value from each play recap using standard shell tools.

Exit codes:

    0  Playbook converged; runs 2 and 3 reported changed=0
    1  Playbook remained non-idempotent after the first run
    2  Playbook execution failed or the recap could not be parsed

Validate the deliberately non-idempotent playbook:

    ./tests/run_convergence_check.sh \
      playbooks/non_idempotent.yml

Expected exit code:

    1

Validate the declarative playbook:

    ./tests/run_convergence_check.sh \
      playbooks/idempotent_core.yml

Expected exit code:

    0

## Production System Baseline

The production baseline configures a local Nginx application environment.

It manages:

- Group `appgroup`
- User `appuser`
- Fixed UID and GID
- Non-login shell
- No automatically created home directory
- Packages `nginx`, `git`, `curl`, and `tree`
- Application directory `/etc/appsite`
- Web root `/var/www/appsite`
- Application configuration `/etc/appsite/app.conf`
- Nginx virtual host `/etc/nginx/sites-available/appsite`
- Enabled virtual-host symlink
- Stable monitoring format under `/etc/nginx/conf.d`
- Nginx service enablement and reload through handlers

Run the initial deployment:

    ansible-playbook playbooks/system_baseline.yml --diff

Run it again:

    ansible-playbook playbooks/system_baseline.yml --diff

The second run must report:

    changed=0
    failed=0

## Safe Nginx Configuration Management

The custom virtual host is rendered from:

    templates/appsite.conf.j2

It provides:

- Port 80 listener
- Dynamic hostname rendering
- Stable web root
- Root-page routing
- `/health` endpoint
- Dedicated access and error logs

The monitoring format is stored in:

    /etc/nginx/conf.d/app_monitoring.conf

That file is included within the Nginx `http` context by the Ubuntu Nginx configuration.

The managed directive is:

    log_format app_monitor '$remote_addr $request_method $uri $status $request_time';

Managing this directive through `conf.d` avoids unsafe regular-expression insertion into `nginx.conf`.

## Handler Discipline

Service-affecting operations occur only through handlers.

Configuration changes notify:

    Validate nginx configuration
    Reload nginx

Initial package installation can notify:

    Enable and start nginx

Before a service reload, the validation handler runs:

    /usr/sbin/nginx -t

The handler is marked:

    changed_when: false

A syntax error stops execution before the reload handler proceeds.

This protects the running service from invalid configuration changes.

## Application Configuration

The application configuration is rendered to:

    /etc/appsite/app.conf

Expected properties:

    Owner: appuser
    Group: appgroup
    Mode: 0640

The file contains checksum-stable values and no runtime timestamp.

Inspect it:

    sudo stat -c '%a %U:%G %n' /etc/appsite/app.conf
    sudo cat /etc/appsite/app.conf

## Read-Only Assertion Gate

Run:

    ansible-playbook playbooks/assert_baseline.yml

The assertion playbook validates:

- `appuser` exists with the expected UID
- `appgroup` exists with the expected GID
- The account uses `/usr/sbin/nologin`
- All required packages are installed
- The application configuration exists
- Ownership is `appuser:appgroup`
- Permissions are `0640`
- The Nginx virtual host is enabled
- The monitoring configuration exists with mode `0644`
- Nginx configuration syntax is valid
- Nginx is active
- Nginx is enabled
- The root endpoint returns HTTP 200
- The health endpoint returns HTTP 200

Every task explicitly uses:

    changed_when: false

Expected recap:

    changed=0
    failed=0

## HTTP Validation

Test the root page:

    curl --fail http://localhost/

Test the health endpoint:

    curl --fail http://localhost/health

Expected health response:

    {"status":"healthy","host":"<hostname>"}

## Production Convergence Test

Run:

    ./tests/run_convergence_check.sh \
      playbooks/system_baseline.yml

Expected result:

    PASS: playbooks/system_baseline.yml converged with changed=0 on runs 2 and 3.

Expected exit code:

    0

## Tools Used

- Ansible
- Ansible Playbook
- YAML
- Jinja2 templates
- Python virtual environments
- Bash
- Nginx
- systemd
- Git
- curl
- POSIX text-processing tools
- Linux users, groups, ownership, and permissions

## Key Skills Demonstrated

- Designing declarative automation
- Detecting structural non-idempotence
- Replacing imperative shell operations with Ansible modules
- Measuring changed-task counts programmatically
- Preserving playbook exit codes
- Parsing Ansible recaps with standard shell tools
- Building reusable convergence gates
- Managing Linux users and groups with fixed identities
- Applying stable package configuration
- Rendering checksum-stable templates
- Using handlers for service lifecycle control
- Validating Nginx before reload
- Building read-only post-deployment assertions
- Verifying HTTP application health
- Enforcing file ownership and permissions
- Creating automation suitable for CI validation

## Real-World Use Case

Infrastructure automation is frequently executed multiple times through CI/CD pipelines, scheduled configuration runs, deployment recovery procedures, and drift-remediation systems.

A playbook that reports changes every time creates operational uncertainty. Teams cannot distinguish legitimate drift from automation defects, and unnecessary service reloads may affect availability.

The convergence harness in this implementation converts idempotence into a measurable contract:

    Run 1 may change state.
    Run 2 must report changed=0.
    Run 3 must report changed=0.

The assertion playbook independently verifies that the expected operating state actually exists.

Together, these patterns can act as deployment gates for Platform Engineering, DevOps, SRE, DevSecOps, and AIOps workflows.

## Lessons Learned

- Idempotence depends on complete task design, not only module selection.
- Runtime timestamps and generated resource names break convergence.
- Shell appends should be replaced with state-aware modules.
- Stable file content is required for repeatable configuration.
- Repeated configuration entries should be controlled with `lineinfile` or `blockinfile`.
- Service reloads should be triggered only by actual configuration changes.
- Syntax validation should run before service reloads.
- Broad insertion expressions can match commented examples instead of active configuration contexts.
- Context-sensitive Nginx directives should be placed in known include directories.
- Recap parsing should target host-summary lines rather than arbitrary output.
- Convergence tests must preserve execution failures separately from idempotence failures.
- Post-run assertions should inspect state without modifying it.
- Automated convergence testing is more reliable than manually comparing terminal output.

## Troubleshooting Log

### Ansible unavailable on Ubuntu 24.04

Ansible was installed inside a Python virtual environment to avoid conflicts with Ubuntu's externally managed Python installation.

Commands:

    python3 -m venv ~/ansible-venv
    ~/ansible-venv/bin/python -m pip install ansible
    export PATH="$HOME/ansible-venv/bin:$PATH"

### Incorrect active Ansible configuration

Ansible resolves `ansible.cfg` from the current working directory.

Confirm the active configuration:

    cd ~/ansible-idempotence-engineering
    ansible --version

The output should reference:

    /home/ubuntu/ansible-idempotence-engineering/ansible.cfg

### Convergence parser cannot find changed count

Inspect the generated log:

    cat /tmp/convergence_<identifier>/run_2.log

Confirm that the play recap contains a host line similar to:

    localhost : ok=N changed=0 unreachable=0 failed=0

The harness parses this line using `awk`.

### Nginx log format placed in the wrong context

An early implementation inserted `log_format` directly into `nginx.conf` using a broad regular-expression match.

The expression matched a commented example near the end of the file rather than the active `http {}` block.

Nginx returned:

    "log_format" directive is not allowed here

The corrected implementation manages:

    /etc/nginx/conf.d/app_monitoring.conf

Ubuntu includes this directory inside the Nginx `http` context.

### Nginx syntax validation fails

Run:

    sudo nginx -t

Inspect the referenced file and line number.

Also inspect active configuration files:

    sudo nginx -T

Check the managed files:

    sudo cat /etc/nginx/sites-available/appsite
    sudo cat /etc/nginx/conf.d/app_monitoring.conf

### Nginx is active but HTTP validation fails

Check the listener:

    sudo ss -ltnp | grep ':80'

Check enabled sites:

    ls -l /etc/nginx/sites-enabled/

Validate syntax:

    sudo nginx -t

Inspect the virtual host:

    sudo cat /etc/nginx/sites-available/appsite

Test locally with verbose output:

    curl -v http://localhost/

Likely causes include:

- The virtual-host symlink is missing
- Another server block owns the default listener
- The configured web root or index file is missing

### Second run still reports changes

Execute with diff output:

    ansible-playbook playbooks/system_baseline.yml --diff

Run with increased verbosity:

    ansible-playbook playbooks/system_baseline.yml --diff -vv

Identify the task reporting `changed`.

Common causes include:

- Dynamic timestamps
- Unstable template content
- Incorrect ownership or mode
- Unconditional service actions
- Changing package-cache behavior
- Recreated symlinks
- Improper handler notifications
