# ARR 计算思路（SaaS）

基于当前 marts 表的 ARR 计算方案。

---

## 一、你的表结构概览

| 表 | 核心字段 | 用途 |
|----|----------|------|
| **marts_fact_subscription_terms** | subscription_key, vin, start_date, end_date, status, plan, billing_cycle | 订阅生命周期、哪些订阅在某个时点是否有效 |
| **marts_fact_subscription_invoice** | subscription_key, amount_dkk, billing_cycle, paid_at | 发票、单价、计费周期 |
| **marts_dim_subscription_plan** | plan, billing_cycle, amount_dkk, valid_from, valid_to | 订阅计划价格目录 |
| **marts_dim_vin** | vin, customer_key, distributor_id | VIN ↔ 客户 / 经销商 |
| **marts_dim_customer** | customer_key | 客户维度 |
| **dim_date** (Power BI) | date, year, month | 日期维度 |

---

## 二、ARR 公式

**ARR = MRR × 12**，其中 MRR 需要按 billing_cycle 折算：

| billing_cycle | amount_dkk 含义 | 单条订阅的 MRR | 单条订阅的 ARR |
|---------------|-----------------|----------------|----------------|
| monthly       | 月费            | amount_dkk     | amount_dkk × 12 |
| annual / yearly | 年费         | amount_dkk ÷ 12 | amount_dkk     |

> 说明：billing_cycle 具体取值需要你查一次真实数据（如 `SELECT DISTINCT billing_cycle FROM marts_fact_subscription_invoice`）。

---

## 三、推荐做法：在 dbt 里建一个 ARR 快照表

在 dbt 中建一张「按月底的订阅快照 + MRR/ARR」，Power BI 直接用：

**新建：`marts/marts_fact_subscription_arr_snapshot.sql`**

```sql
-- 每月底：活跃订阅数 + 每条的 MRR/ARR，方便在 Power BI 按日期切片算 ARR
with date_spine as (
  -- 用 dim_date 或生成每月最后一天
  select date_trunc(date, month) as month_start,
         last_day(date_trunc(date, month)) as month_end
  from unnest(generate_date_array('2020-01-01', current_date(), interval 1 month)) as date
),
active_subs as (
  select
    d.month_end as snapshot_date,
    t.subscription_key,
    t.vin,
    t.plan,
    t.billing_cycle,
    t.start_date,
    t.end_date,
    p.amount_dkk
  from date_spine d
  cross join {{ ref('marts_fact_subscription_terms') }} t
  inner join {{ ref('marts_dim_subscription_plan') }} p
    on t.plan = p.plan and t.billing_cycle = p.billing_cycle
    and d.month_end between p.valid_from and p.valid_to
  where t.start_date <= d.month_end
    and (t.end_date is null or t.end_date >= d.month_end)
    and lower(coalesce(t.status, '')) not in ('cancelled', 'churned')  -- 按实际 status 调整
),
mrr_calc as (
  select *,
    case
      when lower(billing_cycle) in ('monthly', 'month') then amount_dkk
      when lower(billing_cycle) in ('annual', 'yearly', 'year') then amount_dkk / 12
      else amount_dkk  -- 默认当 monthly
    end as mrr_dkk,
    case
      when lower(billing_cycle) in ('monthly', 'month') then amount_dkk * 12
      when lower(billing_cycle) in ('annual', 'yearly', 'year') then amount_dkk
      else amount_dkk * 12
    end as arr_dkk
  from active_subs
)
select
  snapshot_date,
  subscription_key,
  vin,
  plan,
  billing_cycle,
  amount_dkk,
  mrr_dkk,
  arr_dkk
from mrr_calc
```

在 Power BI 中：

- 用 `dim_date` 的「月末日期」与 `snapshot_date` 做关系（或直接用 `snapshot_date` 作为日期维度）
- 新建 measure：`ARR Total = SUM(marts_fact_subscription_arr_snapshot[arr_dkk])`  
  或  
  `ARR Total = SUM(marts_fact_subscription_arr_snapshot[mrr_dkk]) * 12`

---

## 四、替代做法：完全在 Power BI 里算 ARR

不建 snapshot 的话，也可以直接从 invoice 算，但无法做「某日时点 ARR」，只能做「某月收入对应的年化」。

### 4.1 基于 subscription_invoice

```dax
ARR from Invoices = 
SUMX(
  marts_fact_subscription_invoice,
  marts_fact_subscription_invoice[amount_dkk] 
  * SWITCH(
      LOWER(marts_fact_subscription_invoice[billing_cycle]),
      "monthly", 12,
      "month", 12,
      "annual", 1,
      "yearly", 1,
      12  // 默认按月年化
  )
)
```

- 适合：想看「某月开票收入对应的年化」  
- 不适合：想看「某日时点 ARR」（需要订阅快照）

### 4.2 基于 subscription_terms + 日期切片

思路：用 subscription_terms 的 start_date / end_date，在 DAX 里判断「在某日是否活跃」，再乘以对应的 plan 价格。  
实现较复杂，建议还是用 dbt 的 snapshot 方案。

---

## 五、订阅 terms 的数据形态

`marts_fact_subscription_terms` 来自按月分区的 silver，可能有多条历史记录（同一 subscription_id 不同 _month）。  
若要做「某日时点」ARR，需保证能选出「该日仍有效」的订阅，通常需要：

1. 取每个 subscription 在目标日期的「最新一条 terms」
2. 或使用 `_month` 等字段做版本控制，只保留 snapshot_date 所在月的 terms

如你当前 terms 是一月一条快照，可考虑在 snapshot 模型中用 `t._month = last_day(d.month_end)` 之类的条件来对齐月份。

---

## 六、建议实施顺序

1. 查一次真实值：  
   `SELECT DISTINCT billing_cycle, plan, amount_dkk FROM marts_fact_subscription_invoice`
2. 建 `marts_fact_subscription_arr_snapshot`（可按上面 SQL 再根据实际 status、billing_cycle 微调）
3. 在 Power BI 用 dim_date 和 snapshot 做关系，建 `ARR Total` 等 measure
4. 需要「某日 ARR」时，用 snapshot_date；需要「某月开票年化」时，用 invoice + 上面 DAX

如果你贴一下 `marts_fact_subscription_terms` 和 `marts_fact_subscription_invoice` 的几条样例数据，我可以帮你把 snapshot 的过滤条件和 billing_cycle 映射写得更精确。
