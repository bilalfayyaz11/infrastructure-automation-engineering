# Ansible Multi-Tier Application Automation

## What This Does

This implementation deploys a complete three-tier web application using Ansible roles.

The stack includes a MySQL database, a Flask REST API served by Gunicorn, and an Nginx frontend that also acts as a reverse proxy. A single Ansible playbook configures every service, deploys application files, creates the database schema, injects runtime credentials, starts systemd services, and verifies end-to-end communication.

The result is a repeatable infrastructure automation pattern suitable for internal applications, operational dashboards, API services, and model-serving platforms.

## Architecture

    ┌──────────────────────────────────────────────────────────────┐
    │                      Browser or API Client                   │
    │                                                              │
    │  GET /                                                       │
    │  GET /api/tasks                                              │
    │  POST /api/tasks                                             │
    │  GET /health                                                 │
    └──────────────────────────────┬───────────────────────────────┘
                                   │
                                   ▼
    ┌──────────────────────────────────────────────────────────────┐
    │                     Nginx Web Tier                           │
    │                                                              │
    │  Static HTML, CSS, and JavaScript                           │
    │  Reverse proxy for /api/                                    │
    │  Reverse proxy for /health                                  │
    │  Security response headers                                  │
    │  Named access and error logs                                │
    └──────────────────────────────┬───────────────────────────────┘
                                   │
                                   ▼
    ┌──────────────────────────────────────────────────────────────┐
    │                 Flask and Gunicorn API Tier                  │
    │                                                              │
    │  Runs as non-root todoapp user                              │
    │  Managed by systemd                                         │
    │  Listens on 127.0.0.1:8080                                 │
    │  Validates incoming JSON                                    │
    │  Uses parameterized SQL queries                             │
    └──────────────────────────────┬───────────────────────────────┘
                                   │
                                   ▼
    ┌──────────────────────────────────────────────────────────────┐
    │                       MySQL Data Tier                         │
    │                                                              │
    │  todoapp database                                           │
    │  Restricted todouser account                                │
    │  Five-column tasks table                                    │
    │  Idempotent seed records                                    │
    │  Local-only database listener                               │
    └──────────────────────────────────────────────────────────────┘

## Automation Structure

The automation is separated into three reusable Ansible roles:

- `database`
- `application`
- `webserver`

Shared values are maintained in one variables file so every role reads from the same source of configuration.

The top-level playbook applies the roles in this order:

    Database
        ↓
    Application
        ↓
    Web server
        ↓
    End-to-end verification

## Repository Structure

    ansible-multitier-automation/
    ├── ansible.cfg
    ├── site.yml
    ├── inventory/
    │   └── hosts
    ├── group_vars/
    │   └── all/
    │       └── main.example.yml
    ├── roles/
    │   ├── database/
    │   │   ├── defaults/
    │   │   │   └── main.yml
    │   │   ├── handlers/
    │   │   │   └── main.yml
    │   │   ├── tasks/
    │   │   │   └── main.yml
    │   │   ├── templates/
    │   │   │   ├── schema.sql.j2
    │   │   │   ├── todoapp-client.cnf.j2
    │   │   │   └── todoapp-server.cnf.j2
    │   │   └── vars/
    │   │       └── main.yml
    │   ├── application/
    │   │   ├── defaults/
    │   │   │   └── main.yml
    │   │   ├── handlers/
    │   │   │   └── main.yml
    │   │   ├── tasks/
    │   │   │   └── main.yml
    │   │   ├── templates/
    │   │   │   ├── app.py.j2
    │   │   │   ├── todo-app.env.j2
    │   │   │   └── todo-app.service.j2
    │   │   └── vars/
    │   │       └── main.yml
    │   └── webserver/
    │       ├── defaults/
    │       │   └── main.yml
    │       ├── handlers/
    │       │   └── main.yml
    │       ├── tasks/
    │       │   └── main.yml
    │       ├── templates/
    │       │   ├── index.html.j2
    │       │   └── todo-app.conf.j2
    │       └── vars/
    │           └── main.yml
    └── README.md

## Prerequisites

- Ubuntu 24.04 or another systemd-based Linux distribution
- Python 3
- Python virtual environments
- pip
- Ansible Core
- MySQL Server
- MySQL client
- Nginx
- systemd
- curl
- sudo access
- Internet access for package installation

## Setup

Install system dependencies:

    sudo apt update

    sudo apt install -y \
      python3-pip \
      python3-venv \
      mysql-server \
      mysql-client \
      nginx

Enable MySQL and Nginx:

    sudo systemctl enable --now mysql
    sudo systemctl enable --now nginx

Create the automation environment:

    python3 -m venv .venv
    source .venv/bin/activate

Install Python and Ansible dependencies:

    python -m pip install --upgrade pip

    python -m pip install \
      ansible-core \
      flask \
      flask-cors \
      mysql-connector-python \
      gunicorn \
      PyMySQL

Install the MySQL collection:

    ansible-galaxy collection install ansible.mysql

## Inventory

The inventory targets the local machine without SSH:

    [local]
    localhost ansible_connection=local

Verify inventory parsing:

    ansible-inventory \
      -i inventory/hosts \
      --graph

Verify connectivity:

    ansible \
      -i inventory/hosts \
      local \
      -m ansible.builtin.ping \
      -e ansible_become=false

Expected response:

    localhost | SUCCESS
    "ping": "pong"

## Configuration

Copy the example variables file:

    cp \
      group_vars/all/main.example.yml \
      group_vars/all/main.yml

Edit the real values:

    nano group_vars/all/main.yml

The configuration includes:

    database_name
    database_user
    database_password
    database_host
    database_port
    application_name
    application_user
    application_group
    application_directory
    application_port
    web_root
    web_server_port

The real `group_vars/all/main.yml` file is excluded from Git because it contains the database password.

For stronger secret management, the same variables can be encrypted with Ansible Vault.

## Database Tier

The database role:

- Installs MySQL packages
- Starts and enables MySQL
- Applies a local-only server configuration
- Creates the `todoapp` database
- Creates the restricted `todouser` account
- Grants access only to `todoapp.*`
- Renders the database schema from Jinja2
- Creates the `tasks` table
- Inserts idempotent seed records
- Verifies the exact table structure
- Restarts MySQL only when configuration changes

The table contains:

    id
    title
    description
    status
    created_at

Verify the schema:

    mysql \
      --host=127.0.0.1 \
      --user=todouser \
      --password \
      todoapp \
      --execute="DESCRIBE tasks;"

## Application Tier

The application role deploys a Flask REST API with these endpoints:

### Health Check

    GET /health

Example response:

    {
      "service": "todo-app",
      "status": "healthy"
    }

### List Tasks

    GET /api/tasks

Returns all database rows as a JSON array.

### Create Task

    POST /api/tasks

Example request:

    curl -X POST \
      -H "Content-Type: application/json" \
      -d '{
        "title": "Automation verification",
        "description": "Created through the API",
        "status": "pending"
      }' \
      http://127.0.0.1/api/tasks

Expected response code:

    201

## Runtime Security

The application runs under a dedicated non-root system account:

    todoapp

Gunicorn listens only on the loopback interface:

    127.0.0.1:8080

Database credentials are injected through a protected environment file:

    /etc/todo-app/todo-app.env

The Python source reads credentials through environment variables:

    DB_HOST
    DB_PORT
    DB_NAME
    DB_USER
    DB_PASSWORD

No database password is hardcoded inside the Flask source template.

The systemd service includes hardening controls such as:

    NoNewPrivileges=true
    PrivateTmp=true
    ProtectSystem=strict
    ProtectHome=true

## Web Tier

The webserver role:

- Installs Nginx
- Creates the frontend directory
- Deploys the HTML, CSS, and JavaScript interface
- Creates the Nginx virtual host from Jinja2
- Removes the default virtual host
- Proxies `/api/` to Gunicorn
- Proxies `/health` to Flask
- Creates named access and error logs
- Validates Nginx before reloading
- Reloads Nginx only when configuration changes

Frontend path:

    /var/www/todo-app/

Nginx configuration:

    /etc/nginx/sites-available/todo-app

Named logs:

    /var/log/nginx/todo-app-access.log
    /var/log/nginx/todo-app-error.log

## Security Headers

Nginx adds these response headers:

    X-Frame-Options: SAMEORIGIN
    X-Content-Type-Options: nosniff
    X-XSS-Protection: 1; mode=block

Verify them:

    curl -sSI http://127.0.0.1/

## Deployment

Activate the automation environment:

    source .venv/bin/activate

Validate syntax:

    ansible-playbook \
      -i inventory/hosts \
      --syntax-check \
      site.yml

Deploy the complete stack:

    ansible-playbook \
      -i inventory/hosts \
      site.yml

## Service Verification

Check MySQL:

    systemctl is-active mysql
    systemctl is-enabled mysql

Check the Flask and Gunicorn service:

    systemctl is-active todo-app
    systemctl is-enabled todo-app
    systemctl status todo-app --no-pager

Check Nginx:

    systemctl is-active nginx
    systemctl is-enabled nginx
    sudo nginx -t

Check listening ports:

    sudo ss -lntp \
      | grep -E ':(80|8080|3306)\b'

## End-to-End Verification

Verify the frontend:

    curl -sS \
      -o /dev/null \
      -w "%{http_code}\n" \
      http://127.0.0.1/

Expected response:

    200

Verify the backend health endpoint through Nginx:

    curl -fsS \
      http://127.0.0.1/health

Retrieve tasks:

    curl -fsS \
      http://127.0.0.1/api/tasks \
      | python3 -m json.tool

Create a task through the complete request path:

    curl -X POST \
      -H "Content-Type: application/json" \
      -d '{
        "title": "Ansible test",
        "description": "Verified through Nginx, Flask, and MySQL",
        "status": "pending"
      }' \
      http://127.0.0.1/api/tasks

Confirm persistence:

    curl -fsS \
      http://127.0.0.1/api/tasks \
      | grep "Ansible test"

This validates the full flow:

    Client
        ↓
    Nginx
        ↓
    Flask
        ↓
    MySQL
        ↓
    JSON response

## Idempotency

Run the playbook a second time:

    ansible-playbook \
      -i inventory/hosts \
      site.yml

A stable second execution should report:

    changed=0
    failed=0

The database seed statements use idempotent insertion logic so existing rows are not duplicated.

Handlers restart or reload services only when managed configuration changes.

## Tools Used

- Ansible Core
- Ansible roles
- Ansible MySQL collection
- Python 3
- Flask
- Flask-CORS
- Gunicorn
- MySQL
- Nginx
- Jinja2
- YAML
- systemd
- Bash
- curl
- Git
- Linux

## Key Skills Demonstrated

- Multi-tier architecture deployment
- Reusable Ansible role development
- Centralized variable management
- Local inventory configuration
- Idempotent infrastructure automation
- MySQL database provisioning
- Restricted database user management
- Jinja2 schema generation
- Flask REST API development
- Gunicorn process management
- systemd service configuration
- Non-root application execution
- Environment-based credential injection
- Nginx static content delivery
- Reverse proxy configuration
- HTTP security header configuration
- Handler-driven service reloads
- End-to-end API verification
- Database persistence testing
- Infrastructure troubleshooting

## Real-World Use Case

This architecture is suitable for internal business applications, administrative interfaces, monitoring dashboards, automation portals, data services, and AI platform components.

The Flask and Gunicorn tier can be replaced with a model inference API, retrieval service, feature service, or orchestration endpoint while preserving the same MySQL, Nginx, systemd, and Ansible automation pattern.

This makes the implementation relevant to Applied AI Engineering, AIOps, Platform Engineering, DevOps, DevSecOps, and infrastructure automation roles.

## Troubleshooting

### Inventory Was Not Parsed

Observed output:

    No inventory was parsed
    Could not match supplied host pattern
    skipping: no hosts matched

Cause:

Ansible did not load the intended inventory configuration.

Resolution:

The inventory was passed explicitly:

    ansible-playbook \
      -i inventory/hosts \
      site.yml

The active configuration can be checked with:

    ansible --version
    ansible-config dump --only-changed

### Deprecated MySQL Modules

Observed warning:

    community.mysql.mysql_db has been deprecated

Resolution:

The database role was updated to use:

    ansible.mysql.mysql_db
    ansible.mysql.mysql_user
    ansible.mysql.mysql_query

The current collection is installed with:

    ansible-galaxy collection install ansible.mysql

### Multiple SQL Statements Failed

Observed error:

    You have an error in your SQL syntax near INSERT INTO tasks

Cause:

Two SQL statements were passed as one query string.

Resolution:

The seed data was separated into individual queries and made idempotent with:

    INSERT IGNORE

### Gunicorn Service Validation

Check the service:

    sudo systemctl status \
      todo-app \
      --no-pager \
      --full

Read recent logs:

    sudo journalctl \
      -u todo-app \
      -n 100 \
      --no-pager

### Nginx Validation

Validate syntax before reload:

    sudo nginx -t

Read application-specific logs:

    sudo tail -n 50 \
      /var/log/nginx/todo-app-access.log

    sudo tail -n 50 \
      /var/log/nginx/todo-app-error.log

### Database Connectivity

Verify local MySQL access:

    sudo mysql \
      --execute="SELECT VERSION();"

Verify the restricted account:

    mysql \
      --host=127.0.0.1 \
      --user=todouser \
      --password \
      todoapp \
      --execute="SELECT COUNT(*) FROM tasks;"

## Lessons Learned

- Explicit inventory paths prevent configuration discovery ambiguity.
- Ansible role boundaries improve maintainability and reuse.
- Shared variables provide one source of configuration truth.
- Database accounts should be restricted to the required schema.
- Runtime credentials should be injected rather than embedded in source code.
- systemd provides reliable process supervision for application services.
- Gunicorn should bind to localhost when Nginx is the public entry point.
- Service handlers prevent unnecessary restarts and reloads.
- SQL statements should be passed separately when modules do not support multi-statement execution.
- End-to-end checks are necessary because individual service health does not prove that all tiers communicate correctly.
- A second Ansible execution is essential for validating idempotency.
