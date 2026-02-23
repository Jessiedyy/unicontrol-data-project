# Data Quality Check Memo

## silver_crm_distributor_info_practice_1

### 1. PK Check (Unique & Not Null)

- **Check SQL:**
  ```sql
  select dealer_id, 
       _snapshot_month,
        count(*) 
  from `dbt_dev_silver.silver_crm_distributor_info_practice_1`
  group by dealer_id, _snapshot_month
  having count(*) > 1 or dealer_id is null;
  ```
- **Result:** 36 rows not unique 
- **Action:** Keep the latest row ordered by updated_at, created_at, bronze_loaded_at_utc. If all the same, keep row No.1.

### 2. Unwanted Space (Leading/Trailing Spaces in Strings)

- **Check String Columns SQL**
  ```sql
  select column_name
  FROM `dbt_dev_silver.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name = 'silver_crm_distributor_info_practice_1'
  AND data_type = 'STRING'
  ORDER BY ordinal_position;

- **Action:** Apply `trim()` to all STRING columns in silver model

### 3. Column Data Type Check

- **Note:** Inferred from ndjson
- **Result** All columns are correct data type

### 4. RECORD Flatten

- **Action:** Flatten `primary_contact` and `billing_address` into separate columns with prefix (e.g. `primary_contact_name`, `billing_address_city`) and trim() string columns

### 5. Null Check

- **Check SQL:**
  ```sql
  select * from
  (select 'dealer_id' as col, countif(dealer_id is null) as null_count from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'created_at', countif(created_at is null) from   dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'is_deleted', countif(is_deleted is null) from  dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'partner_since', countif(partner_since is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'updated_at', countif(updated_at is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'sf_account_id', countif(sf_account_id is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'vat_number', countif(vat_number is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'partner_tier', countif(partner_tier is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'status',countif(status is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'name', countif(name is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'region', countif(region is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'country', countif(country is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'currency', countif(currency is null) from   dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'primary_contact_name',countif(primary_contact_name is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'primary_contact_email', countif(primary_contact_email is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'primary_contact_phone', countif(primary_contact_phone is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'billing_address_city', countif(billing_address_city is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'billing_address_country_code', countif(billing_address_country_code is null)  from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'billing_address_line1', countif(billing_address_line1 is null) from dbt_dev_silver.silver_crm_distributor_info_practice_1
  union all
  select 'billing_address_postal_code', countif(billing_address_postal_code is null)  from dbt_dev_silver.silver_crm_distributor_info_practice_1)
  where null_count != 0
  ```
- **Columns with nulls:**

| Column                      | Null Count | Type    | Note                            |
|-----------------------------|------------|---------|---------------------------------|
| billing_address_postal_code | 548        | INTEGER | Use 0 if filling                |
| primary_contact_phone       | 1228       | STRING  | Use 'not available' if filling  |
| billing_address_line1       | 322        | STRING  | Use 'not available' if filling  |
| primary_contact_email       | 769        | STRING  | Use 'not available' if filling  |
| vat_number                  | 837        | STRING  | Use 'not available' if filling  |

- **Action:** Replace nulls with 'not available' for string columns, with 0 for numeric columns.

### 6. Data Consitency and Standardization for column "country" and column "billing_address_country_code"

- **Check SQL**
```sql
select distinct(country) from `dbt_dev_silver.silver_crm_distributor_info_practice_1`;
```
- **Results:** Some are full name and some are abbreviation.

-**Action:** Create seeds/dim_country.csv, left join them to replace abbreviation values with full names.

## silver_sell_out_practice_1

### 1. Check for Nulls or Duplicates in PK
- **Check SQL**
```sql
select order_id, 
        count(*) 
from `dbt_dev_silver.silver_sell_out_practice_1`
group by order_id
having count(*) > 1 or order_id is null;
```

- **Results:** No Duplicates or Nulls
- **Action:** None

### 2. Check unwanted space in string columns
#### 2.1 Identify all string columns
**Check SQL**
```sql
select column_name
FROM `dbt_dev_silver.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'silver_sell_out_practice_1'
  AND data_type = 'STRING'
ORDER BY ordinal_position;
```

#### 2.2 Check if unwanted spaces exist
**Check SQL**
```sql
select * from dbt_dev_silver.silver_sell_out_practice_1
where order_type != trim(order_type);

select * from dbt_dev_silver.silver_sell_out_practice_1
where order_id != trim(order_id);

select * from dbt_dev_silver.silver_sell_out_practice_1
where vin != trim(vin);

select * from dbt_dev_silver.silver_sell_out_practice_1
where _source != trim(_source);
```

- **Results:** No unwanted spaces 
- **Action:** None

### 3. Flatten RECORD and trim string columns with unwanted spaces

### 4. Check if data type is correct
- **Results:** Correct
- **Action:** None

### 5. Check null values 

#### 5.1 count total rows of dbt_dev_silver.silver_sell_out_practice_1
**SQL**
```sql
select count(*) from dbt_dev_silver.silver_sell_out_practice_1;
```
- **Results:** 3000 rows

#### 5.2 Check which columns have nulls
**Check SQL**
```sql
select * from
(select 'vin' as col, countif(vin is null) as null_count from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'contract_date', countif(contract_date is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'occurred_at', countif(occurred_at is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'activate_date', countif(activate_date is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'order_type', countif(order_type is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'order_id', countif(order_id is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select '_month', countif(_month is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'raw_notes', countif(raw_notes is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'raw_discount_pct',countif(raw_discount_pct is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'raw_dealer_payload_version', countif(raw_dealer_payload_version is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'raw_source_system', countif(raw_source_system is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'customer_contact_phone', countif(customer_contact_phone is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'customer_contact_email', countif(customer_contact_email is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'customer_country_code',countif(customer_country_code is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'customer_customer_name', countif(customer_customer_name is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'customer_vat', countif(customer_vat is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'customer_customer_external_id', countif(customer_customer_external_id is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'dealer_country', countif(dealer_country is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'dealer_onboard_date', countif(dealer_onboard_date is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'dealer_dealer_name', countif(dealer_dealer_name is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'dealer_region', countif(dealer_region is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'dealer_dealer_id', countif(dealer_dealer_id is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'product_list_price_dkk', countif(product_list_price_dkk is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'product_currency', countif(product_currency is null) from dbt_dev_silver.silver_sell_out_practice_1
union all
select 'product_product_type', countif(product_product_type is null) from dbt_dev_silver.silver_sell_out_practice_1
)
where null_count != 0;
```

- **Results** 
col                     | null_count | notes  
customer_vat            | 57         | replace nulls with 'not available'
customer_contact_email  | 2583       | no transformation temporarily
customer_country_code   | 1653       | no transformation temporarily
raw_notes               | 2051       | no transformation temporarily
customer_contact_phone  | 3000       | nulls in the entire column, no transformation temporarily
raw_discount_pct        | 3000       | nulls in the entire column, no transformation temporarily


### 6. Data Consitency and Standardization for column "dealer_country" 
**Check SQL**
```sql
select distinct(dealer_country) from `dbt_dev_silver.silver_sell_out_practice_1`;
select distinct(product_product_type) from `dbt_dev_silver.silver_sell_out_practice_1`;
```
- **Action:** use full name to fill in dealer_country


### 7. Check if 'product_list_price_dkk' has negative values
**Check SQL**
```sql

select *
from `dbt_dev_silver.silver_sell_out_practice_1`
where product_list_price_dkk < 0 or product_list_price_dkk is null;
```

- **Results:** No negative values or nulls
- **Action**: None

### 8. Check for invalid date orders
#### 8.1 if activate_date < contract_date
**Check SQL**
```sql
select * from `dbt_dev_silver.silver_sell_out_practice_1`
where activate_date < contract_date;
```
- **Results:** All of activate_date >= contract_date
- **Action** None

#### 8.2 if YYYY-MM of contract_date != that of _month
**Check SQL**
```sql

select * from `dbt_dev_silver.silver_sell_out_practice_1`
where substring(cast(contract_date as string),1,7) != left(cast(_month as string),7);
```
- **Results:** no difference, YYYY-MM of contract_date = that of _month

- **Action:** None

## silver_subscription_invoice_practice_1
### 1. Check for Nulls or Duplicates in PK
**Check SQL**
```sql
select invoice_id, 
        count(*) 
from `dbt_dev_silver.silver_subscription_invoice_practice_1`
group by invoice_id
having count(*) > 1 or invoice_id is null;
```
- **Results** No Duplicates or Nulls
- **Action** None

### 2. Check unwanted space in string columns
#### 2.1 Identify all string columns
**Check SQL**
```sql
select column_name
FROM `dbt_dev_silver.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'silver_subscription_invoice_practice_1'
  AND data_type = 'STRING'
ORDER BY ordinal_position;
```

#### 2.2 Check if unwanted spaces exist
**Check SQL**
```sql
select * from dbt_dev_silver.silver_subscription_invoice_practice_1
where source_system != trim(source_system)
or
invoice_id != trim(invoice_id)
or
currency != trim(currency)
or
status != trim(status)
or
plan != trim(plan)
or
vin != trim(vin)
or
billing_cycle != trim(billing_cycle)
or
subscription_id != trim(subscription_id);
```
- **Results**  No unwanted spaces 
- **Action** None

### 3. Flatten RECORD and trim string columns with unwanted spaces
- **Results:** No columns is RECORD type
- **Action** None

### 4. Check if data type is correct
- **Results:** Correct
- **Action** None

### 5. Check null values 
#### 5.1 count total rows of dbt_dev_silver.silver_sell_out_practice_1
**Check SQL**
```sql
select count(*) from dbt_dev_silver.silver_subscription_invoice_practice_1;
```
- **Results:** 3000 rows

#### 5.2 Check which columns have nulls
**Check SQL**
```sql
select * from
(select 'updated_at' as col, countif(updated_at is null) as null_count from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'source_system', countif(source_system is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'paid_at', countif(paid_at is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'invoice_id', countif(invoice_id is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'currency', countif(currency is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'issue_date', countif(issue_date is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select '_month', countif(_month is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'period_end', countif(period_end is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'status',countif(status is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'amount_dkk', countif(amount_dkk is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'period_start', countif(period_start is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'due_date', countif(due_date is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'plan', countif(plan is null) from  dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'vin',countif(vin is null) from  dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'billing_cycle', countif(billing_cycle is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'created_at', countif(created_at is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
union all
select 'subscription_id', countif(subscription_id is null) from dbt_dev_silver.silver_subscription_invoice_practice_1
)
where null_count != 0;
```
- **Results:** no nulls
- **Action** None

### 6. Check if 'amount_dkk' is invalid 
-- Check if negative values or incorrect
**Check SQL**
```sql
select *
from dbt_dev_silver.silver_subscription_invoice_practice_1
where amount_dkk < 0 or amount_dkk is null;

select sum(cnt)
from (select plan, billing_cycle, amount_dkk, count(*) as cnt from `dbt_dev_silver.silver_subscription_invoice_practice_1`
where amount_dkk !=0 and amount_dkk != 3290 and amount_dkk !=2990 and amount_dkk !=8490 and amount_dkk != 29990
group by plan, billing_cycle, amount_dkk
order by plan asc, amount_dkk desc);
```
- **Results:** No negative values, 33 rows with incorrect amount
- **Action** Mark these 33 rows as 'incorrect amount'

### 7. Check for invalid date orders
#### 7.1 if period_start >= period_end
**Check SQL**
```sql
select * from `dbt_dev_silver.silver_subscription_invoice_practice_1`
where period_end <= period_start;
```
- **Results** 22 rows are invalid (period_start = period_end), which are involved into those 33 rows with incorrect amount

- **Action** Mark them as 'invalid period'

#### 7.2 if paid_at != period_start
**Check SQL**
```sql
select * from `dbt_dev_silver.silver_subscription_invoice_practice_1`
where cast(paid_at as date) != period_start;
```
- **Results:** all is valid (paid_at = period_start)
- **Action** None

### 8 Check if YYYY-MM of paid_at != that of _month
**Check SQL**
```sql
select * from `dbt_dev_silver.silver_subscription_invoice_practice_1`
where substring(cast(paid_at as string),1,7) != left(cast(_month as string),7);
```
- **Results:** all valid, YYYY-MM of paid_at = that of _month
- **Action** None

### 9. check how many rows are 'invalid subscription invoice' (should be 33)
**Check SQL**
```sql
select count(valid_subscription_invoice) from `dbt_dev_silver.silver_subscription_invoice_practice_1`
where valid_subscription_invoice=FALSE;
```
- **Results** 33 rows, correct!


## silver_subscription_event_practice_1
### 1. Check for Nulls or Duplicates in PK
**Check SQL**
```sql
select event_id, 
        count(*) 
from `dbt_dev_silver.silver_subscription_event_practice_1`
group by event_id
having count(*) > 1 or event_id is null;
```
- **Results** No Duplicates or Nulls
- **Action** None


### 2. Check unwanted space in string columns
#### 2.1 Identify all string columns
**Check SQL**
```sql
select column_name
FROM `dbt_dev_silver.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'silver_subscription_event_practice_1'
  AND data_type = 'STRING'
ORDER BY ordinal_position;
```
#### 2.2 Check if unwanted spaces exist
**Check SQL**
```sql
select * from dbt_dev_silver.silver_subscription_event_practice_1
where event_id != trim(event_id)
or
vin != trim(vin)
or
source_system != trim(source_system)
or
event_type != trim(event_type)
or
subscription_id != trim(subscription_id)
or
_source != trim(_source);
```
- **Results** No unwanted spaces
- **Action** None

### 3. Flatten RECORD and trim string columns with unwanted spaces

### 4. Check if data type is correct
- **Results** Correct
- **Action** None

### 5. Check null values 
**Check SQL**
```sql
select * from
(select 'occurred_at' as col, countif(occurred_at is null) as null_count from dbt_dev_silver.silver_subscription_event_practice_1
union all
select 'event_id', countif(event_id is null) from dbt_dev_silver.silver_subscription_event_practice_1
union all
select 'effective_at', countif(effective_at is null) from dbt_dev_silver.silver_subscription_event_practice_1
union all
select 'vin', countif(vin is null) from dbt_dev_silver.silver_subscription_event_practice_1
union all
select 'source_system', countif(source_system is null) from dbt_dev_silver.silver_subscription_event_practice_1
union all
select 'event_type', countif(event_type is null) from dbt_dev_silver.silver_subscription_event_practice_1
union all
select '_month', countif(_month is null) from dbt_dev_silver.silver_subscription_event_practice_1
union all
select 'subscription_id', countif(subscription_id is null) from dbt_dev_silver.silver_subscription_event_practice_1
union all
select 'attributes_billing_cycle',countif(attributes_billing_cycle is null) from dbt_dev_silver.silver_subscription_event_practice_1
union all
select 'attributes_plan', countif(attributes_plan is null) from dbt_dev_silver.silver_subscription_event_practice_1
)
where null_count != 0;
```

- **Results** No Nulls
- **Action** None

## silver_subscription_terms_practice_1

### 1. Check for Nulls or Duplicates in PK
**Check SQL**
```sql
select subscription_id, 
        count(*) 
from `dbt_dev_silver.silver_subscription_terms_practice_1`
group by subscription_id
having count(*) > 1 or subscription_id is null;
```
- **Results** No Duplicates or Nulls
- **Action** None

### 2. Check unwanted space in string columns
#### 2.1 Identify all string columns
**Check SQL**
```sql
select column_name
FROM `dbt_dev_silver.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'silver_subscription_terms_practice_1'
  AND data_type = 'STRING'
ORDER BY ordinal_position;
```

#### 2.2 Check if unwanted spaces exist
**Check SQL**
```sql
select * from dbt_dev_silver.silver_subscription_terms_practice_1
where plan != trim(plan)
or
status != trim(status)
or
vin != trim(vin)
or
source_system != trim(source_system)
or
billing_cycle != trim(billing_cycle)
or
subscription_id != trim(subscription_id)
or
_source != trim(_source);
```
- **Results:** No unwanted spaces
- **Action** None 

### 3. Flatten RECORD and trim string columns with unwanted spaces
- **Results:** No RECORD columns
- **Action** None 

### 4. Check if data type is correct
- **Results:** Correct
- **Action** None 

### 5. Check null values 
**Check SQL**
```sql
select * from
(select 'source_system' as col, countif(source_system is null) as null_count from dbt_dev_silver.silver_subscription_terms_practice_1
union all
select 'updated_at' as col, countif(updated_at is null) as null_count from dbt_dev_silver.silver_subscription_terms_practice_1
union all
select 'created_at', countif(created_at is null) from dbt_dev_silver.silver_subscription_terms_practice_1
union all
select 'status', countif(status is null) from dbt_dev_silver.silver_subscription_terms_practice_1
union all
select 'end_date', countif(end_date is null) from dbt_dev_silver.silver_subscription_terms_practice_1
union all
select 'start_date', countif(start_date is null) from dbt_dev_silver.silver_subscription_terms_practice_1
union all
select 'plan', countif(plan is null) from dbt_dev_silver.silver_subscription_terms_practice_1
union all
select 'vin', countif(vin is null) from dbt_dev_silver.silver_subscription_terms_practice_1
union all
select 'billing_cycle', countif(billing_cycle is null) from dbt_dev_silver.silver_subscription_terms_practice_1
union all
select 'subscription_id', countif(subscription_id is null) from dbt_dev_silver.silver_subscription_terms_practice_1
union all
select '_month', countif(_month is null) from dbt_dev_silver.silver_subscription_terms_practice_1
)
where null_count != 0;
```
- **Results:** no nulls
- **Action** None

### 6. Check for invalid date 
**Check SQL**
```sql
select *
from dbt_dev_silver.silver_subscription_terms_practice_1
where end_date <= start_date;
```
- **Results:** All valid
- **Action** None


## silver_telemetry_machine_events_practice_1
### 1. Check for Nulls or Duplicates in PK
**Check SQL**
```sql
select event_id, 
        count(*) 
from `dbt_dev_silver.silver_telemetry_machine_events_practice_1`
group by event_id
having count(*) > 1 or event_id is null;
```
**Results:** No Duplicates or Nulls
**Action** None


### 2. Check unwanted space in string columns
#### 2.1 Identify all string columns
**Check SQL**
```sql
select column_name
FROM `dbt_dev_silver.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'silver_telemetry_machine_events_practice_1'
  AND data_type = 'STRING'
ORDER BY ordinal_position;
```

#### 2.2 Check if unwanted spaces exist
**Check SQL**
```sql
select * from dbt_dev_silver.silver_telemetry_machine_events_practice_1
where event_id != trim(event_id)
or
session_id != trim(session_id)
or
vin != trim(vin)
or
project_id != trim(project_id)
or
event_type != trim(event_type)
or
payload_job_type != trim(payload_job_type)
or
payload_duration_min != trim(payload_duration_min)
or
payload_method != trim(payload_method)
or
payload_offset_type != trim(payload_offset_type)
or
payload_point_type != trim(payload_point_type)
or
payload_product_type != trim(payload_product_type);
```
**Results:** No unwanted spaces 
**Action** None

### 3. Flatten payload_raw；Delete payload STRUCT, as they are overlapped

### 4. Check if data type is correct
**Results:** Correct
**Action** None

### 5. Check null values, except that columns can have nulls
**Check SQL**
```sql
select * from
(select 'event_time' as col, countif(event_time is null) as null_count from dbt_dev_silver.silver_telemetry_machine_events_practice_1
union all
select 'event_id' as col, countif(event_id is null) as null_count from dbt_dev_silver.silver_telemetry_machine_events_practice_1
union all
select 'session_id', countif(session_id is null) from dbt_dev_silver.silver_telemetry_machine_events_practice_1
union all
select 'vin', countif(vin is null) from dbt_dev_silver.silver_telemetry_machine_events_practice_1
union all
select 'event_date', countif(event_date is null) from dbt_dev_silver.silver_telemetry_machine_events_practice_1
union all
select 'received_at_utc', countif(received_at_utc is null) from dbt_dev_silver.silver_telemetry_machine_events_practice_1
union all
select 'project_id', countif(project_id is null) from dbt_dev_silver.silver_telemetry_machine_events_practice_1
union all
select 'event_type', countif(event_type is null) from dbt_dev_silver.silver_telemetry_machine_events_practice_1
union all
select 'year', countif(year is null) from dbt_dev_silver.silver_telemetry_machine_events_practice_1
union all
select 'day', countif(day is null) from dbt_dev_silver.silver_telemetry_machine_events_practice_1
union all
select '_month', countif(_month is null) from dbt_dev_silver.silver_telemetry_machine_events_practice_1
)
where null_count != 0;
```
**Results:** vin has 237 nulls and project_id has 216 nulls
**Action:** Replace nulls with 'not available'


### 6. Check for invalid date (event_date = day)
**Check SQL**
```sql
select *
from dbt_dev_silver.silver_telemetry_machine_events_practice_1
where event_date != day;
```
**Results:** All valid
**Action:** None