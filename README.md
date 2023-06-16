# dbmigration

Simple no dependency bash database migration

This script is aimed at Postgres, but should be easy to port to any database.

# Objectives

Simplicity and Idempotency.

# Overview

You do not need a fancy migration tool or framework. There I've said it.

## All you need is SQL in the DB

For almost all database migration tasks, you want to have full power of what happens, and the only tool to do that is
SQL.

## Why you do not need a database migration framework

There are so many migration frameworks that it is overwhelming, each with their own details, dependencies, quirks,
documentation and support.

The main sell point for such frameworks are versioned downgrades, which you almost never will need.
In production you almost never (if not never) would want to do downgrades on your database more than a single verion
back
and even then it is better is do a forward going upgrade, removing or changing any issues that a previous migration
could've caused.

# Getting started

## Configure

This is not required but the script provides a user friendly configure command that will write out an `.env` file,
it asks the user for all the required variables.

## Create Migration

`./migrations.sh create [<name>]`

This will create a migration with the name and timestamp in the `migrations/upgrades` and `migrations/downgrades`
folders

### Example

```bash
./migrations.sh create test
# Creating empty upgrade file migrations/upgrades/1686930630_test.sql
# Creating empty downgrade file migrations/downgrades/1686930630_test.sql
```

Add the SQL you need to the upgrade and downgrade scripts.
All SQL should make use of IF EXISTS or IF NOT EXISTS constructs.

## Run Migration Upgrade

```bash
./migrations.sh run
```

This will run all of the migration scripts. Yes all. You should make sure your SQL is idempotent and can be rerun
multiple times. There is nothing more infuriating than having to manually pick through migration scripts that cannot
exist
because something else exist etc. Idempotency in SQL is bliss.

## Run Migration Downgrade

**Important**
This will run all the downgrades scripts and should only be used by developers when they need to delete rerun upgrades.

```bash
./migrations.sh downgrade-all
```

# VARIABLES

`.env` files are automatically loaded.

| Variable       | Description                                                              |
|----------------|--------------------------------------------------------------------------|
| MIGRATIONS_DIR | The root directory for the upgrades, fixtures and downgrades directories |
| DB_HOST        | The postgres host                                                        |
| DB_PORT        | The postgres port default 5432                                           |
| DB_PASSWORD    | The postgres database password, can be empty                             |
| DB_NAME        | The database name                                                        |
