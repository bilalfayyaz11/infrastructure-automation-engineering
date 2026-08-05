# Resilient Ansible Error Handling

## What This Does

This implementation demonstrates production-style failure handling and observability patterns in Ansible.

It includes explicit precondition enforcement, multiple debug output styles, custom success and change detection, retry behavior for unreliable operations, structured `block`, `rescue`, and `always` execution, shared deployment logging, failure-specific records, and automated summary reporting.

Every playbook is designed to behave predictably under both successful and intentionally failed conditions. Failures produce actionable messages and structured evidence rather than unhandled exceptions.

## Architecture

    ┌───────────────────────────────────────────────────────────────┐
    │                    Ansible Control Layer                      │
    │                                                               │
    │  Local Inventory                                             │
    │  Central Configuration                                       │
    │  YAML-Formatted Output                                       │
    │  Persistent Ansible Log                                      │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                   Debug and Preconditions                     │
    │                                                               │
    │  Raw Variable Output                                         │
    │  Formatted Messages                                          │
    │  Conditional Messages                                        │
    │  Verbosity-Controlled Diagnostics                            │
    │  Numeric Validation                                          │
    │  Membership Validation                                       │
    │  Boolean Validation                                          │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                  Custom Result Evaluation                     │
    │                                                               │
    │  failed_when Numeric Thresholds                              │
    │  changed_when Overrides                                      │
    │  Multi-Condition Failure Expressions                         │
    │  Predictable Nonzero Exit Results                            │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                 Resilient Deployment Stages                   │
    │                                                               │
    │  Precondition Validation                                     │
    │  Dependency Validation                                       │
    │  Application File Deployment                                │
    │  Retry-Based Health Verification                            │
    │                                                               │
    │  Each Stage Uses                                             │
    │  block → rescue → always                                     │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                    Logging and Reporting                      │
    │                                                               │
    │  Shared Stage Status Log                                     │
    │  Failure-Specific Records                                    │
    │  Timestamped Failure Details                                 │
    │  Summary Dictionary                                          │
    │  Automated PASS or FAIL Determination                        │
    └───────────────────────────────────────────────────────────────┘

## Repository Structure

    ansible-resilient-error-handling/
    ├── ansible.cfg
    ├── inventory/
    │   └── hosts.ini
    ├── playbooks/
    │   ├── debug-and-fail.yml
    │   ├── custom-failure-conditions.yml
    │   ├── resilient-deployment.yml
    │   └── error-report.yml
    ├── logs/
    │   └── .gitkeep
    ├── artifacts/
    │   └── .gitkeep
    ├── requirements.txt
    ├── .gitignore
    └── README.md

## Prerequisites

- Ubuntu 24.04 or another Linux distribution
- Python 3
- Python virtual environments
- pip
- Git
- Bash
- Standard Unix utilities
- Local filesystem access under `/tmp`
- Internet access for installing Ansible

## Setup

Install the required packages:

    sudo apt update

    sudo apt install -y \
      python3-pip \
      python3-venv \
      curl \
      ca-certificates

Create and activate the Python environment:

    python3 -m venv .venv
    source .venv/bin/activate

Install Ansible:

    python -m pip install --upgrade pip
    python -m pip install ansible-core

## Inventory

The inventory targets the local host without SSH:

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

The configuration includes:

    inventory = ./inventory/hosts.ini
    host_key_checking = False
    retry_files_enabled = False
    stdout_callback = default
    result_format = yaml
    log_path = ./logs/ansible.log

The built-in default callback is configured to render results in YAML format.

Verify active settings:

    ansible-config dump --only-changed

Verify the active configuration file:

    ansible --version

## Debug and Preconditions

The `debug-and-fail.yml` playbook demonstrates six variable types:

- String
- Integer
- Boolean
- List
- Dictionary
- Registered command result

It uses the debug module in four distinct ways.

### Raw Variable Output

    ansible.builtin.debug:
      var: service_configuration

### Formatted Message

    ansible.builtin.debug:
      msg: "Preparing the selected application environment."

### Conditional Output

    ansible.builtin.debug:
      msg: "Deployment execution is enabled."
    when:
      - deployment_enabled | bool

### Verbosity-Controlled Output

    ansible.builtin.debug:
      msg: "Verbose diagnostic information"
      verbosity: 1

The verbosity-controlled message appears only when the playbook runs with `-v`.

## Precondition Enforcement

The playbook validates:

- Available memory meets the minimum threshold
- The selected environment exists in the allowed environment list
- Deployment execution is enabled

Run the successful path:

    ansible-playbook \
      playbooks/debug-and-fail.yml

Run with verbose diagnostics:

    ansible-playbook \
      -v \
      playbooks/debug-and-fail.yml

Force insufficient memory:

    ansible-playbook \
      playbooks/debug-and-fail.yml \
      -e available_memory_mb=1024

Force an unsupported environment:

    ansible-playbook \
      playbooks/debug-and-fail.yml \
      -e deployment_environment=unsupported

Force a disabled deployment state:

    ansible-playbook \
      playbooks/debug-and-fail.yml \
      -e deployment_enabled=false

Each failed condition returns a descriptive message with the actual and expected values.

## Custom Failure Conditions

The `custom-failure-conditions.yml` playbook demonstrates custom result evaluation.

### Numeric Threshold

A shell command returns a numeric value. Ansible fails only when that number exceeds the configured limit.

    failed_when:
      - disk_usage_result.stdout | int > disk_usage_limit | int

### Suppressed Change Reporting

A shell command modifies a local marker file but is intentionally reported as unchanged:

    changed_when: false

This is useful for validation or observation commands that should not count as configuration changes.

### Multi-Condition Failure

The playbook combines independent checks with `or`:

    failed_when: >
      simulated_service_state != expected_service_state
      or
      simulated_response_code | int != expected_response_code | int
      or
      'healthy' not in simulated_response_body

Run the successful path:

    ansible-playbook \
      playbooks/custom-failure-conditions.yml

Force a numeric failure:

    ansible-playbook \
      playbooks/custom-failure-conditions.yml \
      -e simulated_disk_usage=99

Force a service-state failure:

    ansible-playbook \
      playbooks/custom-failure-conditions.yml \
      -e simulated_service_state=inactive

Force a response-code failure:

    ansible-playbook \
      playbooks/custom-failure-conditions.yml \
      -e simulated_response_code=503

## Resilient Deployment Flow

The `resilient-deployment.yml` playbook simulates four stages:

    Precondition Validation
            ↓
    Dependency Validation
            ↓
    Application Deployment
            ↓
    Health Verification

Each stage uses:

    block
        Main execution

    rescue
        Structured failure handling

    always
        Shared status logging

This design allows subsequent stages to continue after a handled failure.

## Retry Logic

The health stage simulates an unreliable operation using a counter file.

Each attempt:

- Reads the current counter
- Increments it
- Writes the new value
- Fails while the value is below three
- Succeeds on the third attempt

The retry configuration uses:

    retries: 3
    delay: 1
    until:
      - retry_health_result.rc == 0

Expected behavior:

    FAILED - RETRYING
    FAILED - RETRYING
    ok

The two retry warnings prove the operation succeeds on its third attempt.

## Structured Failure Records

Handled failures create individual files under:

    /tmp/deployment-logs/

Each record contains:

    stage
    timestamp
    status
    message

Example:

    stage=application-deployment
    timestamp=2026-08-06T00:00:00Z
    status=FAILED
    message=Forced application deployment failure

## Shared Run Log

Every `always` section appends one line to:

    /tmp/deployment-logs/run.log

Successful output contains:

    stage=precondition-validation status=PASSED
    stage=dependency-validation status=PASSED
    stage=application-deployment status=PASSED
    stage=health-verification status=PASSED

A handled failure changes only the affected stage:

    stage=application-deployment status=FAILED

Subsequent stages continue running.

## Running the Resilient Deployment

Run the successful flow:

    ansible-playbook \
      playbooks/resilient-deployment.yml

Inspect the shared log:

    cat /tmp/deployment-logs/run.log

Inspect the retry counter:

    cat /tmp/deployment-counter

Expected value:

    3

Force a handled deployment failure:

    ansible-playbook \
      playbooks/resilient-deployment.yml \
      -e force_deployment_failure=true

Other available failure controls:

    force_precondition_failure
    force_dependency_failure
    force_deployment_failure
    force_health_failure

## Error Reporting

The `error-report.yml` playbook:

- Finds every file under `/tmp/deployment-logs/`
- Reads each file
- Builds a failure file list
- Reads `run.log`
- Creates a summary dictionary
- Determines PASS or FAIL
- Stops with a descriptive message when failure markers exist
- Prints the summary when all records are successful

Run the report:

    ansible-playbook \
      playbooks/error-report.yml

Successful summary fields include:

    total_log_files
    run_log_lines
    status
    failure_files

Example successful result:

    {
      "total_log_files": 1,
      "run_log_lines": [
        "stage=precondition-validation status=PASSED",
        "stage=dependency-validation status=PASSED",
        "stage=application-deployment status=PASSED",
        "stage=health-verification status=PASSED"
      ],
      "status": "PASS",
      "failure_files": []
    }

When a failure record exists, the playbook stops and names the specific file containing the `FAILED` marker.

## Full Verification Sequence

Activate the Python environment:

    source .venv/bin/activate

Validate all playbooks:

    ansible-playbook \
      --syntax-check \
      playbooks/debug-and-fail.yml

    ansible-playbook \
      --syntax-check \
      playbooks/custom-failure-conditions.yml

    ansible-playbook \
      --syntax-check \
      playbooks/resilient-deployment.yml

    ansible-playbook \
      --syntax-check \
      playbooks/error-report.yml

Run the successful debug flow:

    ansible-playbook \
      playbooks/debug-and-fail.yml

Run the successful custom-condition flow:

    ansible-playbook \
      playbooks/custom-failure-conditions.yml

Run the resilient deployment:

    ansible-playbook \
      playbooks/resilient-deployment.yml

Generate the report:

    ansible-playbook \
      playbooks/error-report.yml

## Generated Runtime Files

The deployment flow creates:

    /tmp/resilient-application/application.txt
    /tmp/deployment-counter
    /tmp/deployment-logs/run.log

Failure simulations may create:

    /tmp/deployment-logs/precondition-failure.log
    /tmp/deployment-logs/dependency-failure.log
    /tmp/deployment-logs/application-deployment-failure.log
    /tmp/deployment-logs/health-verification-failure.log

These runtime files are intentionally excluded from Git.

## Cleaning the Runtime State

Remove the simulated deployment:

    rm -rf \
      /tmp/resilient-application \
      /tmp/deployment-logs \
      /tmp/deployment-counter \
      /tmp/ansible-custom-change-marker.txt

Run the deployment again to recreate a clean successful state:

    ansible-playbook \
      playbooks/resilient-deployment.yml

## Ansible Logging

Ansible execution output is written to:

    logs/ansible.log

Inspect recent entries:

    tail -n 100 logs/ansible.log

The logs directory is retained in Git through `.gitkeep`, while generated log content is ignored.

## Tools Used

- Ansible Core
- Python 3
- YAML
- Jinja2
- Bash
- POSIX shell
- Git
- Linux filesystem utilities
- Ansible debug module
- Ansible fail module
- Ansible block, rescue, and always
- Ansible set_fact module
- Ansible slurp module
- Ansible find module
- Ansible lineinfile module
- Ansible copy module
- Ansible shell and command modules

## Key Skills Demonstrated

- Explicit failure-path design
- Ansible debug output control
- Verbosity-based diagnostics
- Precondition enforcement
- Human-readable validation failures
- Registered command-result handling
- Numeric threshold evaluation
- Custom failure detection
- Custom change detection
- Multi-condition failure expressions
- Retry and delay configuration
- Until-condition design
- Block-based execution control
- Rescue-based recovery
- Always-run status recording
- Structured failure logging
- Shared deployment-status logging
- Dynamic summary dictionary creation
- Failure artifact discovery
- Predictable exit-code behavior
- Automated positive and negative testing
- Local deployment simulation
- Operational troubleshooting

## Real-World Use Case

These patterns can be applied to software delivery, infrastructure provisioning, configuration changes, service restarts, database migrations, container deployment, cloud automation, and AI platform operations.

A production automation workflow must do more than execute successful commands. It must validate prerequisites, recognize abnormal conditions, retry temporary failures, preserve useful evidence, continue safely when appropriate, and stop clearly when recovery is impossible.

The same techniques are especially useful for:

- CI/CD delivery automation
- AIOps remediation workflows
- Model-serving deployments
- Infrastructure provisioning
- Service health validation
- Configuration compliance
- Incident-response automation
- Platform engineering workflows

## Troubleshooting

### Verbose Debug Message Does Not Appear

Run the playbook with:

    ansible-playbook \
      -v \
      playbooks/debug-and-fail.yml

A debug action configured with `verbosity: 1` is intentionally skipped without `-v`.

### Forced Boolean Failure Does Not Trigger

Command-line variables may be interpreted as strings.

The playbook converts the value using:

    deployment_enabled | bool

Run:

    ansible-playbook \
      playbooks/debug-and-fail.yml \
      -e deployment_enabled=false

### Custom Shell Command Shows Changed

Validation commands should explicitly define:

    changed_when: false

This prevents observation-only commands from appearing as configuration changes.

### Retry Task Does Not Retry

Remove the existing counter file:

    rm -f /tmp/deployment-counter

Then rerun:

    ansible-playbook \
      playbooks/resilient-deployment.yml

The playbook normally removes the counter during initialization.

### Failure Report Returns FAIL After Testing

A failure simulation may have left a file containing `FAILED`.

Restore a clean state:

    ansible-playbook \
      playbooks/resilient-deployment.yml

The deployment playbook resets `/tmp/deployment-logs/` at the beginning.

Then run:

    ansible-playbook \
      playbooks/error-report.yml

### No Inventory Was Parsed

Run from the repository directory:

    cd ansible-resilient-error-handling

Check the active configuration:

    ansible --version

Pass the inventory explicitly when needed:

    ansible-playbook \
      -i inventory/hosts.ini \
      playbooks/resilient-deployment.yml

### YAML Callback Is Unavailable

Current Ansible versions may not provide a standalone callback named `yaml`.

This implementation uses:

    stdout_callback = default
    result_format = yaml

Verify the applied settings:

    ansible-config dump --only-changed

### Ansible Log File Is Missing

Run an Ansible command from the repository directory:

    ansible localhost \
      -m ansible.builtin.ping

Then check:

    ls -l logs/ansible.log

## Lessons Learned

- Failure behavior should be designed before success behavior.
- Preconditions should fail with actual and expected values.
- Debug verbosity prevents routine output from becoming noisy.
- `failed_when` makes application-specific failure logic explicit.
- `changed_when` prevents validation commands from creating misleading change reports.
- Retry logic should be deterministic and testable.
- `rescue` converts failures into controlled recovery paths.
- `always` guarantees operational status recording.
- Structured log records are easier to analyze than unformatted console output.
- Handled failures can allow later stages to continue safely.
- Final reporting should identify the exact failure artifact.
- Success and failure paths should both be tested automatically.
- Exit codes are part of the automation contract.
- Raw Python tracebacks should never be the expected operator experience.
