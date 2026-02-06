# External Tables Layer (GCS → BigQuery via dbt)

## Overview

This layer is to create a seamless, automated connection between raw data stored in Google Cloud Storage (GCS) and BigQuery, without physically moving the data (Zero-copy ingestion) by creating **external tables** in BigQuery using **dbt**.

Instead of manually creating tables in the BigQuery UI, infrastructure is defined as code to ensure:
- Automation: Avoids manual CREATE EXTERNAL TABLE SQL statements.
- Scalability: Easily manage dozens of tables via a single YAML configuration.
- Maintainability: Simplifies maintenance when raw data structures change in GCS.

This layer serves as the **entry point of the data platform**, forming the foundation for downstream Bronze, Silver, and Gold transformations.

---

## Architecture Decision

### Why External Tables?

External tables were selected instead of loading raw data into BigQuery to optimize cost and flexibility during early-stage data exploration.

### Tradeoffs

| External Tables                | Loaded Tables            |
|--------------------------------|--------------------------|
| Lower storage cost             | Faster query performance |
| Schema flexibility             | Better optimized         |
| No ingestion pipeline required | Higher storage cost      |

### Decision

External tables are used for the **raw ingestion layer**, allowing fast setup while preserving optionality for future ingestion pipelines.

---

## Implementation Steps

---

### Step 1  Configure dbt Environment

#### Why
dbt requires an isolated Python environment to prevent dependency conflicts.

#### Command

python3 -m venv dbt-env
source dbt-env/bin/activate
pip install dbt-bigquery
dbt --version

### Step 2  Authenticate and Connect to BigQuery

#### Why
dbt must authenticate using a service account or application default credentials to execute DDL operations.

#### Command
(upload the key of service account in advance)

dbt debug

(Expected: All checks passed!)

### Step 3  Create ***External*** Dataset in BigQuery

#### Why
External tables must reside inside a dataset before creation.

#### Command

bq mk --dataset unicontrol-data-project:external

### Step 4  Declare External Tables as Code

All table definitions are stored in: ***models/external/sources.yml***

This approach enforces Infrastructure as Code, eliminating manual UI operations.

#### Command

nano models/external/sources.yml  # edit ***sources.yml***

#### Example Configuration:

version: 2

sources:
  - name: ext
    database: unicontrol-data-project  # project id in BigQuery
    schema: external  # dataset name created in BigQuery

    tables:
      - name: distributors  # name of the external table in ***external*** dataset in BigQuery
        external:
          location: "gs://unicontrol-raw-data-lake/crm/distributors/snapshot_month=*"  # only 1 wildcard can be in the ***location***  
          options:
            format: NEWLINE_DELIMITED_JSON
            hive_partition_uri_prefix: "gs://unicontrol-raw-data-lake/crm/distributors/"  # "/" at then end is must 
        

### Step 5 Install dbt External Tables Package

### Why
dbt itself doesn't have macros to create external tables. The external plugin ***dbt_external_tables*** must be installed.

#### Command
nano packages.yml    # edit ***packages.yml***

packages:
  - package: dbt-labs/dbt_external_tables
    version: latest

dbt deps   # install external plugin ***dbt_external_tables*** 

### Step 6  Generate External Tables

#### Command

dbt run-operation stage_external_sources --vars "ext_full_refresh: true"   

This command instructs dbt to:

- Read the YAML definitions (***models/external/sources.yml***)
- Generate DDL
- Create external tables in BigQuery

### Step 7  Validate Table Creation

#### Command

bq ls unicontrol-data-project:external    # list tables

Example validation sql query in Bigquery:
SELECT * 
FROM external.distributors
where snapshot_month = '2021-01';

---

## External Tables Created
- distributors
- subscription_invoices
- telemetry_machine
- subscription_events
- subscription_terms
- sell_out

---

## Technical Challenges & Optimization

### Multiple wildcards not supported in GCS URI
BigQuery supports only one wildcard per URI.

#### Incorrect
snapshot_month=*/*

#### Correct
snapshot_month=*

### Hive partitioning requires correct folder structure (key=value style)

Partition detection works only when GCS follows:
snapshot_month=202401/
snapshot_month=202402/

Otherwise, partitions will not be recognized.

---

## Next Step : Build Bronze Layer

- ***Completed*** External Table Layer

- ### ***Next Step*** Bronze Layer 

- *** Planned *** Silver Layer

- *** Planned *** Gold Layer
 



