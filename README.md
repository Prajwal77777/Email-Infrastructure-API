## EMAIL INFRASTRUCTURE API

A starter repo for Rails API development that includes all the latest and greatest gems and pattern to start off an API development.

### Tech Stack

Framework: Ruby on Rails

## Getting Started

### 1. Setup Development Environment

Install the IDE or relevant ruby versions and gems.

```bash
bundle install
```

### 2. Create environment variables file by running:

```bash
# skip this if you already have config/application.yml file existing
bundle exec figaro install
```

Use following environment values for development in `config/application.yml`

```yaml
BASE_DOMAIN: "http://localhost:3000"
DB_USER: "<-DATABASE USER_NAME->"
DB_NAME: "<-DATABASE_NAME->"
DB_PASSWORD: "<-DATABASE_PASSWORD->"
HETZNER_BASE_URL: "<-HETZNER_BASE_URL->"
HETZNER_API_KEY: "<-HETZNER_API_KEY->"
DNS_SIMPLE_BASE_URL: "<-DNS_SIMPLE_BASE_URL->"
DNS_SIMPLE_API_KEY: "<-DNS_SIMPLE_API_KEY->"
DNS_SIMPLE_ACCOUNT_ID: "<-DNS_SIMPLE_ACCOUNT_ID->"
SSH_KEYS_NAME: "<-SSH_KEYS_NAME->"
 ```

### 3. Setup Database

```
rails db:create
```

### 4. Run the server

Then, run the server

```bash
rails s
```

Enjoy coding
