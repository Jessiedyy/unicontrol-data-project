# External Tables Layer (GCS → BigQuery via dbt)

## Overview

This layer establishes a zero-copy integration between Google Cloud Storage (GCS) and BigQuery by provisioning external tables via dbt.

Instead of manually creating tables in the BigQuery UI, infrastructure is defined as code to ensure:
- Automation: Avoids manual CREATE EXTERNAL TABLE SQL statements.
- Scalability: Easily manage dozens of tables via a single YAML configuration.
- Maintainability: Simplifies maintenance when raw data structures change in GCS.

This layer serves as the **entry point of the data platform**, forming the foundation for downstream Bronze, Silver, and Gold transformations.

Environment setup steps are intentionally omitted to focus on production-level design rather than local tooling.

---

## Architecture Decision

### Why External Tables?

External tables were selected as the raw access layer to enable immediate queryability without introducing ingestion latency.

### Tradeoffs

| External Tables                | Loaded Tables            |
|--------------------------------|--------------------------|
| Lower storage cost             | Faster query performance |
| Schema flexibility             | Better optimized         |
| No ingestion pipeline required | Higher storage cost      |

### Decision

External tables are used for the **raw ingestion layer**, allowing fast setup while preserving optionality for future ingestion pipelines.

---

## External Tables Provisioning

---

### External Tables as Code

All table definitions are stored in: ***models/external/sources.yml***

External table definitions are version-controlled via dbt source configurations.


#### Example Configuration:

version: 2

sources:
  - name: ext
    database: unicontrol-data-project  
    schema: external  

    tables:
      - name: distributors  
        external:
          location: "gs://unicontrol-raw-data-lake/crm/distributors/snapshot_month=*"  
          options:
            format: NEWLINE_DELIMITED_JSON
            hive_partition_uri_prefix: "gs://unicontrol-raw-data-lake/crm/distributors/"  
        

### Install dbt External Tables Package

The dbt_external_tables package is used to generate external table DDL automatically:

packages:
  - package: dbt-labs/dbt_external_tables
    version: latest

dbt deps   

### Generate External Tables

External tables are programmatically materialized using the dbt_external_tables macro:

dbt run-operation stage_external_sources --vars "ext_full_refresh: true" 

This macro generates DDL from source definitions and provisions the external tables in BigQuery.


### Validate Table Creation

Table accessibility is validated through partition-filtered queries:

e.g.,

SELECT * 
FROM external.distributors
where snapshot_month = '2021-01';

---

## Results: External Tables

- distributors
- subscription_invoices
- telemetry_machine
- subscription_events
- subscription_terms
- sell_out

All external tables are defined declaratively and can be recreated at any time from version-controlled configurations.

This design ensures reproducibility — the entire external layer can be rebuilt from code without manual intervention.

---

## Production Constraints

### BigQuery supports only one wildcard per URI.

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

## Data Flow

```
Source Systems -> API Ingestion -> GCS Raw Storage -> BigQuery External Tables -> Bronze -> Silver -> Gold
```
## Next Step: Build Bronze Layer

 



