# Ansible Linux Security Baseline

## What This Does

This implementation enforces a reusable Linux security baseline with Ansible.

It hardens OpenSSH, configures a default-deny UFW firewall, enables fail2ban intrusion prevention, activates automatic security updates, disables unnecessary services, validates sensitive file permissions, generates compliance reports, and verifies that the controls remain operational.

The automation is designed for repeatable security enforcement on Ubuntu systems and follows Infrastructure as Code principles for consistency, auditability, and recovery.

## Architecture

    ┌───────────────────────────────────────────────────────────────┐
    │                    Ansible Control Layer                      │
    │                                                               │
    │  Local Inventory                                             │
    │  Security Baseline Playbook                                  │
    │  Reusable Security Role                                      │
    │  Compliance Validation                                       │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                      SSH Security Layer                       │
    │                                                               │
    │  Root Login Disabled                                         │
    │  Password Authentication Disabled                            │
    │  Public-Key Authentication Enabled                           │
    │  Authentication Attempts Restricted                          │
    │  Idle Session Controls                                       │
    │  X11 Forwarding Disabled                                     │
    │  Configuration Validation Before Reload                      │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                    Network Security Layer                     │
    │                                                               │
    │  UFW Default-Deny Inbound Policy                             │
    │  Verified SSH Source Allowance                               │
    │  Rate-Limited General SSH                                    │
    │  HTTP and HTTPS Allowances                                   │
    │  Explicit High-Risk Port Denials                             │
    │  Firewall Logging                                            │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                    Host Protection Layer                      │
    │                                                               │
    │  Fail2ban SSH Jail                                           │
    │  Automatic Security Updates                                  │
    │  Sensitive File Permission Validation                        │
    │  Unnecessary Service Reduction                               │
    └───────────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                    Compliance and Audit                       │
    │                                                               │
    │  Effective SSH Configuration Checks                          │
    │  Firewall State Validation                                   │
    │  Fail2ban Service Validation                                 │
    │  Security Summary                                            │
    │  Detailed Compliance Report                                  │
    │  Idempotency Verification                                    │
    └───────────────────────────────────────────────────────────────┘

## Security Controls Implemented

The automation enforces:

- Disabled SSH root login
- Disabled SSH password authentication
- Enabled public-key authentication
- Disabled keyboard-interactive authentication
- Disabled empty-password access
- Reduced SSH authentication attempts
- SSH idle-session timeout controls
- Disabled X11 forwarding
- Disabled SSH agent forwarding
- Restricted SSH login grace time
- Limited concurrent SSH sessions
- UFW default-deny incoming policy
- UFW default-allow outgoing policy
- UFW default-deny routed policy
- Verified administration-source SSH allowance
- Rate-limited general SSH access
- HTTP and HTTPS firewall allowances
- Explicit denial of selected high-risk ports
- UFW logging
- fail2ban SSH protection
- Automatic security updates
- Secure account-database permissions
- Optional Avahi service disablement
- Automated compliance reporting

## Repository Structure

    ansible-security-hardening/
    ├── ansible.cfg
    ├── inventory.ini
    ├── security-baseline.yml
    ├── compliance-check.yml
    ├── generate-security-report.sh
    ├── roles/
    │   └── security-hardening/
    │       ├── defaults/
    │       │   └── main.example.yml
    │       ├── handlers/
    │       │   └── main.yml
    │       ├── tasks/
    │       │   ├── main.yml
    │       │   ├── ssh-hardening.yml
    │       │   ├── firewall.yml
    │       │   ├── system-security.yml
    │       │   └── compliance-summary.yml
    │       ├── templates/
    │       │   ├── 99-security-hardening.conf.j2
    │       │   ├── sshd.local.j2
    │       │   └── 20auto-upgrades.j2
    │       └── vars/
    │           └── main.yml
    └── README.md

## Prerequisites

- Ubuntu 24.04 or another systemd-based Linux distribution
- Python 3
- Python virtual environments
- pip
- OpenSSH Server
- sudo access
- Active public-key SSH access
- At least one valid authorized key
- Internet access for package installation
- A second terminal for SSH reconnection verification

## Safety Model

SSH and firewall automation can interrupt remote access when applied incorrectly.

This implementation uses the following safeguards:

- Existing public-key access is validated before hardening
- SSH configuration syntax is checked before reload
- Settings are installed through an OpenSSH drop-in file
- The original SSH configuration is backed up
- The active SSH source address is detected before enabling UFW
- A second SSH login is verified before firewall enforcement
- UFW permits the verified administration address
- General SSH access is rate-limited
- Strict shell execution is isolated inside subshells to preserve the interactive session

Do not close the original terminal until a second SSH connection has been verified.

## Setup

Install the required system packages:

    sudo apt update

    sudo apt install -y \
      python3-pip \
      python3-venv \
      openssh-server \
      ufw \
      fail2ban \
      unattended-upgrades \
      net-tools \
      curl \
      ca-certificates

Enable SSH:

    sudo systemctl enable --now ssh

Validate SSH configuration:

    sudo sshd -t

Create the Python environment:

    python3 -m venv .venv
    source .venv/bin/activate

Install Ansible:

    python -m pip install --upgrade pip
    python -m pip install ansible-core

Install the firewall collection:

    ansible-galaxy collection install community.general

## Inventory

The inventory manages the local system without SSH transport:

    [local]
    localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3

Verify the inventory:

    ansible-inventory \
      -i inventory.ini \
      --graph

Test Ansible connectivity:

    ansible \
      -i inventory.ini \
      local \
      -m ansible.builtin.ping \
      -e ansible_become=false

Expected result:

    localhost | SUCCESS
    "ping": "pong"

## Configuration

Copy the example role defaults:

    cp \
      roles/security-hardening/defaults/main.example.yml \
      roles/security-hardening/defaults/main.yml

Edit the configuration:

    nano roles/security-hardening/defaults/main.yml

Important variables include:

    ssh_hardening_dropin
    ssh_backup_directory
    ssh_max_auth_tries
    ssh_client_alive_interval
    ssh_client_alive_count_max
    firewall_ssh_port
    firewall_http_port
    firewall_https_port
    approved_ssh_source
    fail2ban_max_retry
    fail2ban_find_time
    fail2ban_ban_time

The real administration-source address is intentionally excluded from Git.

## SSH Hardening

The SSH baseline is installed at:

    /etc/ssh/sshd_config.d/99-security-hardening.conf

The original configuration is preserved at:

    /var/backups/ssh-security/sshd_config.original

The enforced settings include:

    PermitRootLogin no
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    PubkeyAuthentication yes
    PermitEmptyPasswords no
    MaxAuthTries 3
    ClientAliveInterval 300
    ClientAliveCountMax 2
    X11Forwarding no
    AllowAgentForwarding no
    LoginGraceTime 30
    MaxSessions 5
    UseDNS no

Validate syntax:

    sudo sshd -t

Inspect effective settings:

    sudo sshd -T \
      | grep -E \
      '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitemptypasswords|maxauthtries|clientaliveinterval|clientalivecountmax|x11forwarding|allowagentforwarding|logingracetime|maxsessions|usedns) '

## Firewall Enforcement

The UFW baseline applies:

    Incoming: deny
    Outgoing: allow
    Routed: deny

Allowed access:

    SSH from verified administration address
    Rate-limited general SSH
    HTTP on TCP 80
    HTTPS on TCP 443

Explicitly denied TCP ports:

    23
    135
    139
    445
    1433
    3389

Verify firewall status:

    sudo ufw status verbose

View numbered rules:

    sudo ufw status numbered

## Fail2ban Protection

The fail2ban SSH jail is configured at:

    /etc/fail2ban/jail.d/sshd.local

The jail uses:

    maxretry = 3
    findtime = 600
    bantime = 3600
    backend = systemd

Validate fail2ban configuration:

    sudo fail2ban-client -t

Check service health:

    systemctl is-active fail2ban
    systemctl is-enabled fail2ban

Inspect the SSH jail:

    sudo fail2ban-client status sshd

## Automatic Security Updates

The periodic update configuration is maintained at:

    /etc/apt/apt.conf.d/20auto-upgrades

It enables:

    Daily package-list updates
    Automatic package downloads
    Weekly package-cache cleanup
    Unattended security upgrades

Inspect the configuration:

    sudo cat /etc/apt/apt.conf.d/20auto-upgrades

Perform a dry run:

    sudo unattended-upgrade \
      --dry-run \
      --debug

## Applying the Security Baseline

Activate the environment:

    source .venv/bin/activate

Validate syntax:

    ansible-playbook \
      -i inventory.ini \
      --syntax-check \
      security-baseline.yml

Apply the baseline:

    ansible-playbook \
      -i inventory.ini \
      security-baseline.yml

## Compliance Validation

Run the compliance validation:

    ansible-playbook \
      -i inventory.ini \
      compliance-check.yml

The checks confirm:

- SSH root login is disabled
- SSH password authentication is disabled
- Public-key authentication is enabled
- Empty-password access is disabled
- Authentication attempts are restricted
- Idle-session controls are active
- X11 forwarding is disabled
- UFW is active
- fail2ban SSH protection is active
- SSH is running
- fail2ban is running
- Automatic updates are enabled

## Security Reporting

Generate the detailed report:

    ./generate-security-report.sh

The installed report is located at:

    /var/log/security-compliance-report.log

The Ansible-generated summary is located at:

    /var/log/security-hardening-summary.log

Inspect both:

    sudo cat /var/log/security-compliance-report.log
    sudo cat /var/log/security-hardening-summary.log

## Live Verification

Check SSH:

    sudo sshd -t
    systemctl is-active ssh
    systemctl is-enabled ssh

Check port 22:

    sudo ss -lntp \
      | grep -E ':[2]2[[:space:]]'

Check UFW:

    sudo ufw status verbose

Check fail2ban:

    systemctl is-active fail2ban
    sudo fail2ban-client status
    sudo fail2ban-client status sshd

Check automatic updates:

    sudo cat /etc/apt/apt.conf.d/20auto-upgrades

Check high-risk listening ports:

    sudo ss -lntup \
      | grep -E ':(23|135|139|445|1433|3389)\b'

No output is expected from the high-risk port check.

## Idempotency

Run the baseline again:

    ansible-playbook \
      -i inventory.ini \
      security-baseline.yml

A stable repeated execution should complete with:

    failed=0

Ideally, it should also report:

    changed=0

Handler-driven reloads and restarts occur only when managed configuration changes.

## Recovery

### Restore the Original SSH Configuration

Remove the managed drop-in:

    sudo rm -f \
      /etc/ssh/sshd_config.d/99-security-hardening.conf

Restore the preserved configuration:

    sudo cp \
      /var/backups/ssh-security/sshd_config.original \
      /etc/ssh/sshd_config

Validate it:

    sudo sshd -t

Reload SSH:

    sudo systemctl reload ssh

### Disable UFW Temporarily

    sudo ufw disable

### Reset UFW

    sudo ufw --force reset

### Inspect SSH Failures

    sudo journalctl \
      -u ssh \
      -n 100 \
      --no-pager

    sudo tail -n 100 \
      /var/log/auth.log

### Inspect Fail2ban Failures

    sudo journalctl \
      -u fail2ban \
      -n 100 \
      --no-pager

    sudo fail2ban-client -t

### Inspect Current Network Exposure

    sudo ss -lntup

## Tools Used

- Ansible Core
- Ansible roles
- Community General collection
- OpenSSH Server
- UFW
- fail2ban
- unattended-upgrades
- Python 3
- Jinja2
- YAML
- systemd
- Bash
- Git
- Linux networking tools

## Key Skills Demonstrated

- Security as Code
- Linux security baseline enforcement
- Reusable Ansible role development
- OpenSSH configuration hardening
- Safe remote-access preservation
- Firewall policy automation
- Default-deny network controls
- Source-restricted administration access
- SSH rate limiting
- Intrusion-prevention configuration
- Automatic security-update management
- Service exposure validation
- Sensitive file permission validation
- Handler-driven service reloads
- Compliance assertion development
- Security audit reporting
- Idempotency testing
- Recovery planning

## Real-World Use Case

This pattern can be applied to cloud virtual machines, internal servers, bastion hosts, automation workers, data-processing nodes, monitoring systems, and AI infrastructure.

In an Applied AI or AIOps environment, the same controls can protect model-serving hosts, inference gateways, orchestration nodes, internal APIs, data services, and administrative systems.

Automated security enforcement reduces configuration drift, improves auditability, and enables teams to apply consistent controls across many systems.

## Troubleshooting

### SSH Access Risk

Potential cause:

A restrictive SSH setting was applied before validating public-key access.

Resolution:

- Keep the original terminal open
- Verify a second key-based login
- Validate `authorized_keys`
- Run `sshd -t`
- Confirm the effective SSH settings
- Apply the firewall only after successful reconnection

### SSH Service Is Active but Disabled

On socket-activated Ubuntu systems, SSH may be started by `ssh.socket`.

Check both:

    systemctl status ssh
    systemctl status ssh.socket

The automation explicitly enables the SSH service for predictable operation.

### UFW Is Active but SSH Is Unreachable

Use the original active terminal:

    sudo ufw status numbered

Allow the verified source:

    sudo ufw allow \
      from YOUR_PUBLIC_IP \
      to any port 22 \
      proto tcp

Disable UFW temporarily when necessary:

    sudo ufw disable

### Fail2ban Jail Is Missing

Validate configuration:

    sudo fail2ban-client -t

Restart the service:

    sudo systemctl restart fail2ban

Check the jail:

    sudo fail2ban-client status sshd

### High-Risk Port Is Listening

Identify the owning process:

    sudo ss -lntup

Inspect its service:

    systemctl status SERVICE_NAME

Stop and disable it only after confirming it is unnecessary:

    sudo systemctl disable --now SERVICE_NAME

### Ansible Cannot Parse the Inventory

Pass the inventory explicitly:

    ansible-playbook \
      -i inventory.ini \
      security-baseline.yml

Check the active configuration:

    ansible --version
    ansible-config dump --only-changed

## Lessons Learned

- SSH hardening must preserve a verified recovery path.
- A second SSH login should be proven before enabling restrictive firewall rules.
- Effective SSH configuration should be checked with `sshd -T`.
- SSH syntax should be validated before reload.
- OpenSSH drop-in files are safer and easier to manage than repeatedly editing the primary configuration.
- Default-deny firewall policies reduce unnecessary network exposure.
- fail2ban complements firewall controls by responding to repeated authentication failures.
- Automatic security updates reduce exposure to known vulnerabilities.
- Security checks should assert the effective system state rather than only inspect source files.
- Idempotency is essential for repeatable security enforcement.
- Recovery procedures should be documented before restrictive controls are applied.
