# XTM Docker Deployment

Docker deployment for the **eXtended Threat Management (XTM)** stack, combining [OpenCTI](https://github.com/OpenCTI-Platform/opencti), [OpenAEV](https://github.com/OpenAEV-Platform/openaev) and [XTM One](https://github.com/XTM-One-Platform/xtm-one) into a unified threat intelligence, adversary emulation and AI-assisted analysis platform.

## Overview

This repository provides a complete Docker Compose setup for running:

- **OpenCTI** — Open Cyber Threat Intelligence Platform
- **OpenAEV** — Open Adversary Emulation & Validation Platform
- **XTM One** — AI-powered assistant connecting OpenCTI and OpenAEV
- **XTM Composer** — Unified connector/collector management
- **Shared Infrastructure** — Elasticsearch, MinIO, RabbitMQ, Redis
- **Platform-specific** — PostgreSQL (OpenAEV), PostgreSQL+pgvector (XTM One)

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- Minimum 16GB RAM (recommended 32GB for production)
- At least 50GB available disk space

## Architecture

```
┌───────────────────────────────────────────────────────────────────────────┐
│                              XTM Stack                                    │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│    ┌─────────────┐        ┌──────────────┐        ┌─────────────┐         │
│    │   OpenCTI   │◄──────►│ XTM Composer │◄──────►│   OpenAEV   │         │
│    │    :8080    │        │              │        │    :8081    │         │
│    └─────┬────┬──┘        └──────────────┘        └───┬───┬─────┘         │
│          │    │                                       │   │               │
│          │    │                                       │   │               │
│          ▼    │                                       │   ▼               │
│    ┌─────────┐│                                       │┌───────────┐      │
│    │  Redis  ││                                       ││PostgreSQL │      │
│    └─────────┘│                                       │└───────────┘      │
│               │                                       │                   │
│               │  ┌────────────────────────────┐       │                   │
│               └─►│   Shared Infrastructure    │◄──────┘                   │
│                  │                            │                           │
│                  │  ┌──────────────────────┐  │                           │
│                  │  │    Elasticsearch     │  │                           │
│                  │  └──────────────────────┘  │                           │
│                  │                            │                           │
│                  │  ┌─────────┐  ┌─────────┐  │                           │
│                  │  │  MinIO  │  │RabbitMQ │  │                           │
│                  │  └─────────┘  └─────────┘  │                           │
│                  └────────────────────────────┘                           │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/FiligranHQ/xtm-docker.git
cd xtm-docker
```

### 2. Create environment file

Create a `.env` file with the required configuration. An example is available in [.env.sample](.env.sample).

```bash
# PostgreSQL
POSTGRES_USER=openaev
POSTGRES_PASSWORD=<generate-strong-password>

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=<generate-strong-password>

# RabbitMQ
RABBITMQ_DEFAULT_USER=guest
RABBITMQ_DEFAULT_PASS=<generate-strong-password>

# OpenCTI
OPENCTI_EXTERNAL_SCHEME=http
OPENCTI_HOST=localhost
OPENCTI_PORT=8080
OPENCTI_ADMIN_EMAIL=admin@filigran.io
OPENCTI_ADMIN_PASSWORD=<generate-strong-password>
OPENCTI_ADMIN_TOKEN=<generate-uuid-v4>
OPENCTI_HEALTHCHECK_ACCESS_KEY=<generate-uuid-v4>

# OpenAEV
OPENAEV_EXTERNAL_SCHEME=http
OPENAEV_HOST=localhost
OPENAEV_PORT=8081
OPENAEV_ADMIN_EMAIL=admin@filigran.io
OPENAEV_ADMIN_PASSWORD=<generate-strong-password>
OPENAEV_ADMIN_TOKEN=<generate-uuid-v4>
OPENAEV_HEALTHCHECK_KEY=<generate-uuid-v4>

# SMTP (mandatory)
SMTP_HOST=localhost
SMTP_PORT=25
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_AUTH=false
SMTP_SSL_ENABLE=false
SMTP_STARTTLS_ENABLE=false

# IMAP (optional)
OPENAEV_MAIL_IMAP_ENABLED=false
IMAP_HOST=
IMAP_PORT=993
IMAP_USERNAME=
IMAP_PASSWORD=
IMAP_AUTH=true
IMAP_SSL_ENABLE=true
IMAP_STARTTLS_ENABLE=false
```

> **Tip:** Generate UUIDs using `uuidgen`. `OPENCTI_ENCRYPTION_KEY` must be a 32-byte base64 string produced with `openssl rand -base64 32`, **not** a UUID. `XTM_ONE_SECRET_KEY` and `PLATFORM_REGISTRATION_TOKEN` can be any long random string (e.g. `openssl rand -hex 32`).
>
> The full XTM One configuration (admin credentials, image tag, dedicated Postgres credentials, S3 bucket, license) lives at the bottom of [.env.sample](.env.sample). `PLATFORM_REGISTRATION_TOKEN` is the shared secret that lets OpenCTI and OpenAEV register themselves with XTM One — it MUST be identical for the three platforms.

### 3. Start the stack

```bash
docker compose up -d
```

### 4. Access the platforms

Once all services are healthy (this may take a few minutes on first start):

- **OpenCTI**: http://localhost:8080
- **OpenAEV**: http://localhost:8081
- **XTM One**: http://localhost:8090
- **RabbitMQ Management**: http://localhost:15672

## Included Components

### OpenCTI Connectors

| Connector | Description |
|-----------|-------------|
| Export File STIX | Export data in STIX 2.1 format |
| Export File CSV | Export data in CSV format |
| Export File TXT | Export data in plain text format |
| Import File STIX | Import STIX 2.1 bundles |
| Import Document | Import and analyze PDF, HTML, and text documents |
| Import File YARA | Import YARA rules |
| Analysis | Document analysis connector |
| Import External Reference | Import external references |
| OpenCTI Datasets | Default marking definitions and identities |
| MITRE ATT&CK | MITRE ATT&CK framework data |

### OpenAEV Collectors

| Collector | Description |
|-----------|-------------|
| MITRE ATT&CK | Attack techniques and procedures |
| OpenAEV Datasets | Default datasets and configurations |
| Atomic Red Team | Red Canary's Atomic Red Team tests |
| NVD NIST CVE | CVE data from NVD (requires API key) |

### OpenAEV Injectors

| Injector | Description |
|-----------|-------------|
| Nmap | Network scanning capabilities |
| Nuclei | Vulnerability scanning with Nuclei |

## Configuration

### Memory Requirements

Adjust `ELASTIC_MEMORY_SIZE` based on your available RAM:

| Total RAM | Recommended Setting |
|-----------|---------------------|
| 16GB | `2G` |
| 32GB | `4G` |
| 64GB+ | `8G` |

### Scaling Workers

Modify the worker replicas in `docker-compose.yml`:

```yaml
worker:
  deploy:
    mode: replicated
    replicas: 3  # Increase for higher throughput
```

### External Access

To expose the platforms externally (behind reverse-proxy for instance), update the environment variables:

```bash
OPENCTI_EXTERNAL_SCHEME=https
OPENCTI_HOST=opencti.yourdomain.com
OPENCTI_PORT=443

OPENAEV_EXTERNAL_SCHEME=https
OPENAEV_HOST=openaev.yourdomain.com
OPENAEV_PORT=443
```

## Common Operations

### View logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f opencti
docker compose logs -f openaev
```

### Check service health

```bash
docker compose ps
```

### Stop the stack

```bash
docker compose down
```

### Reset data (destructive)

```bash
docker compose down -v
```

## Troubleshooting

### Services not starting

1. Check if Elasticsearch has enough virtual memory:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   ```

2. Verify all environment variables are set in `.env`

3. Check logs for specific errors:
   ```bash
   docker compose logs <service-name>
   ```

### OpenCTI/OpenAEV not connecting

1. Ensure all dependency services are healthy
2. Verify tokens match between services
3. Check network connectivity within Docker network

## Community

### Status & Bugs

If you wish to report bugs or request new features:

- **OpenCTI**: [GitHub Issues](https://github.com/OpenCTI-Platform/opencti/issues)
- **OpenAEV**: [GitHub Issues](https://github.com/OpenAEV-Platform/openaev/issues)

### Discussion

For support or discussions about the XTM stack, join us on our [Slack channel](https://community.filigran.io) or email us at contact@filigran.io.

## About

XTM is a product suite designed and developed by [Filigran](https://filigran.io).

<a href="https://filigran.io" alt="Filigran"><img src="https://github.com/OpenCTI-Platform/opencti/raw/master/.github/img/logo_filigran.png" width="300" /></a>
