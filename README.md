# Seeder (WIP)

## Description

The Ruby gem to seed FHIR server with data 

## Usage

### Seeds folder

```bash
seeder seed --server=http://localhost:8888 --source=./resources/seeds --type=seeds --username=user --password=password --attempts=3
```

### Bundle resource

```bash
seeder seed --server=http://localhost:8888 --source=./resources/seeds/bundle.json --type=bundle --username=user --password=password --attempts=3
```

### Docker

```yaml
services:
  seed-database:
    image: ghcr.io/beda-software/fhir_seeder:697883bda5ee533197ed0556593d72e5bd2b1e4f
    env_file:
      - .env
    volumes:
      - ./resources/seeds:/app/data
    command:
      - seed
      - "--server=${AIDBOX_BASE_URL}"
      - "--source=/app/data"
      - "--type=seeds"
      - "--username=${AIDBOX_CLIENT_ID}"
      - "--password=${AIDBOX_CLIENT_SECRET}"
```
