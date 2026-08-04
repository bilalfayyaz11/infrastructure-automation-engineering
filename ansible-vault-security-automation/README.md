# Ansible Vault Security Automation

## What This Does

This implementation provides a secure Ansible Vault workflow for encrypting, organizing, consuming, validating, backing up, and recovering sensitive automation variables.

It separates default, staging, administrative, and production secrets into encrypted YAML files. Production credentials use a dedicated vault identity, while password files remain outside the repository with restricted permissions.

The included playbooks load encrypted values into isolated namespaces, render protected configuration files, prevent secrets from appearing in logs, validate process arguments, verify file permissions, and test encrypted backup integrity.

## Architecture

    ┌──────────────────────────────────────────────────────┐
    │                Local Vault Credentials               │
    │                                                      │
    │  ~/.vault_pass                    mode 0600          │
    │  ~/.vault_pass_production         mode 0600          │
    │                                                      │
    │  Stored outside the repository                       │
    └─────────────────────────┬────────────────────────────┘
                              │
               ┌──────────────┴──────────────┐
               │                             │
               ▼                             ▼
    ┌──────────────────────┐      ┌────────────────────────┐
    │ Default Vault Files  │      │ Production Vault       │
    │                      │      │                        │
    │ database_secrets.yml │      │ production_secrets.yml │
    │ staging_secrets.yml  │      │                        │
    │ plain_secrets.yml    │      │ Vault ID: production   │
    └──────────┬───────────┘      └────────────┬───────────┘
               │                               │
               └──────────────┬────────────────┘
                              ▼
    ┌──────────────────────────────────────────────────────┐
    │              Secure Playbook Consumption             │
    │                                                      │
    │  include_vars with isolated namespaces               │
    │  no_log for sensitive operations                     │
    │  masked diagnostic output                            │
    │  secure rendered files with mode 0600                │
    └─────────────────────────┬────────────────────────────┘
                              ▼
    ┌──────────────────────────────────────────────────────┐
    │                Security Validation                   │
    │                                                      │
    │  Namespace isolation                                 │
    │  Secret-leak detection                               │
    │  Process-argument inspection                         │
    │  Permission validation                               │
    │  Controlled decrypt and re-encrypt recovery          │
    │  SHA-256 encrypted backup verification               │
    └──────────────────────────────────────────────────────┘

## Repository Structure

    ansible-vault-security-automation/
    ├── ansible.cfg
    ├── inventory/
    │   └── hosts.ini
    ├── vault_files/
    │   ├── database_secrets.yml
    │   ├── staging_secrets.yml
    │   ├── plain_secrets.yml
    │   └── production_secrets.yml
    ├── playbooks/
    │   ├── vault-consumption.yml
    │   ├── vault-diagnostics.yml
    │   └── vault-security-validation.yml
    ├── templates/
    │   └── secure_app_config.j2
    ├── scripts/
    │   ├── vault_inventory.sh
    │   └── vault_backup.sh
    ├── .gitignore
    └── README.md

## Security Model

The default vault password decrypts:

- `database_secrets.yml`
- `staging_secrets.yml`
- `plain_secrets.yml`

The production vault uses a separate vault identity:

    production

Its password is stored separately in:

    ~/.vault_pass_production

Neither password file belongs inside this repository.

All encrypted vault files use mode `0600`.

## Prerequisites

- Ubuntu or another supported Linux distribution
- Python 3
- pipx
- Ansible
- PyYAML
- Git
- Bash
- SHA-256 utilities

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
    ansible-vault --version
    ansible-inventory --version

Create local password files outside the repository:

    umask 077
    printf '%s\n' 'YOUR_DEFAULT_VAULT_PASSWORD' > ~/.vault_pass
    printf '%s\n' 'YOUR_PRODUCTION_VAULT_PASSWORD' > ~/.vault_pass_production
    chmod 600 ~/.vault_pass ~/.vault_pass_production

The passwords used locally must match the passwords originally used to encrypt the included vault files.

## How to Reproduce

Clone the repository:

    git clone https://github.com/bilalfayyaz11/infrastructure-automation-engineering.git

Enter the implementation directory:

    cd infrastructure-automation-engineering/ansible-vault-security-automation

Verify inventory connectivity:

    ansible-inventory --graph
    ansible local -m ansible.builtin.ping

Inspect an encrypted file header:

    head -n 1 vault_files/database_secrets.yml
    head -n 1 vault_files/production_secrets.yml

View a default vault:

    ansible-vault view \
      --vault-password-file ~/.vault_pass \
      vault_files/database_secrets.yml

View the production vault:

    ansible-vault view \
      --vault-id production@~/.vault_pass_production \
      vault_files/production_secrets.yml

## Secure Vault Consumption

Run the main secure-consumption playbook:

    ansible-playbook playbooks/vault-consumption.yml \
      --vault-password-file ~/.vault_pass \
      --vault-id production@~/.vault_pass_production

This playbook:

- Loads each encrypted file into a separate namespace
- Prevents overlapping variable names from overwriting one another
- Uses `no_log` for secret-bearing operations
- Displays only masked or non-sensitive information
- Creates protected rendered files with mode `0600`

## Diagnostics

Run secure diagnostics:

    ansible-playbook playbooks/vault-diagnostics.yml \
      --vault-password-file ~/.vault_pass

The diagnostic workflow validates required variables, generates a masked connection description, and creates a protected report without writing passwords or API keys.

## Security Validation

Run the full validation:

    ansible-playbook playbooks/vault-security-validation.yml \
      --vault-password-file ~/.vault_pass \
      --vault-id production@~/.vault_pass_production

The validation confirms:

- Default, staging, and production namespaces remain isolated
- Secret values do not appear in process arguments
- Both vault identities decrypt successfully
- Playbook execution finishes with zero failures

## Vault Inventory Reporting

Run:

    ./scripts/vault_inventory.sh

The script reports:

- Vault filename
- Encryption header
- File mode
- Encrypted file size
- Number of variables after authorized decryption

It does not display secret values.

## Encrypted Backup and Recovery

Create an encrypted backup:

    ./scripts/vault_backup.sh

The backup workflow:

- Copies encrypted vault files only
- Applies mode `0600`
- Creates a SHA-256 checksum manifest
- Keeps descriptive metadata separate from checksum data

Verify a backup:

    cd backups/vault-backup-YYYYMMDDTHHMMSSZ
    sha256sum -c manifest.sha256

Controlled recovery can be tested on a copy:

    mkdir -p decrypted
    chmod 700 decrypted

    cp vault_files/staging_secrets.yml \
      decrypted/staging-recovery-test.yml

    ansible-vault decrypt \
      --vault-password-file ~/.vault_pass \
      decrypted/staging-recovery-test.yml

    ansible-vault encrypt \
      --vault-password-file ~/.vault_pass \
      decrypted/staging-recovery-test.yml

The `decrypted/` and `backups/` directories are excluded from version control.

## Tools Used

- Ansible
- Ansible Vault
- YAML
- Python 3
- PyYAML
- pipx
- Bash
- Git
- SHA-256 checksums
- Linux file permissions

## Key Skills Demonstrated

- Encrypting sensitive infrastructure variables
- Managing separate vault identities
- Keeping vault password files outside version control
- Applying restrictive file permissions
- Loading encrypted variables into isolated namespaces
- Preventing sensitive Ansible output with `no_log`
- Rendering protected configuration files
- Detecting secret leakage in process arguments and source files
- Performing controlled decrypt and re-encrypt recovery
- Creating checksum-verified encrypted backups
- Validating secure automation through executable tests

## Real-World Use Case

This pattern can support secure configuration management across development, staging, and production infrastructure. Teams can commit encrypted variables alongside automation code while keeping decryption credentials in protected CI/CD secret stores, password managers, or restricted operator environments.

Separate vault identities allow production credentials to remain isolated from lower environments. Namespaced secret loading also prevents overlapping variable names from silently replacing one another.

## Lessons Learned

- Vault password files must never be committed to source control.
- Different environments should use separate vault identities where appropriate.
- Encrypted variables should be loaded into namespaces to avoid collisions.
- Sensitive tasks should use `no_log`, but safe validation output should remain visible.
- Passwords and tokens should not be hard-coded into validation source code.
- Rendered secret-bearing files require restrictive permissions.
- Backup manifests must contain only checksum-formatted lines when used with `sha256sum -c`.
- Decryption should occur only on controlled copies and should be followed by immediate re-encryption or secure deletion.

## Troubleshooting Log

### Unsafe Ansible installation

System-level pip installation may conflict with Ubuntu's managed Python environment. Ansible was installed through pipx:

    sudo apt install -y pipx
    pipx install --include-deps ansible

### Incorrect vault identity

A production vault cannot be decrypted with the default vault password.

Use:

    ansible-vault view \
      --vault-id production@~/.vault_pass_production \
      vault_files/production_secrets.yml

### Variable collisions

Loading multiple secret files directly into the same variable scope can overwrite shared keys such as `db_username` and `db_password`.

The playbooks use named `include_vars` namespaces:

    database_secrets
    staging_secrets
    production_secrets
    admin_secrets

### Secret literals in validation code

Security tests originally contained complete simulated password strings. The validation now compares loaded secret variables against process output without placing those secret values in source code.

### Invalid checksum manifest

Descriptive metadata mixed into a checksum file caused formatting warnings. Backup metadata is now stored in `manifest.txt`, while `manifest.sha256` contains only valid checksum entries.
