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
