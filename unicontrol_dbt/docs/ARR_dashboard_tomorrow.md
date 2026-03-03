# ARR Dashboard 第二页 — 明天执行清单

目标：**明天一天做完第二页**。按顺序执行，不要跳步。

---

## 前置：dbt 是否有 subscription_plan_key / amount_dkk？

当前 `marts_fact_subscription_terms` 只有 plan、billing_cycle，**没有** subscription_plan_key 和 amount_dkk。

**二选一：**

- **A. 在 dbt 加两列**（推荐，5 分钟）：在 marts_fact_subscription_terms 里 join marts_dim_subscription_plan，补上 subscription_plan_key 和 amount_dkk，然后 `dbt run -s marts_fact_subscription_terms`
- **B. 不在 dbt 加**：在 Power BI 用 plan + billing_cycle 做 bridge 关联，measure 里用 LOOKUPVALUE 取价格

如果选 A，后面的 DAX 会更简单。选 B 也可以，只是 measure 稍复杂。

---

## 第一步：Power BI 关系和辅助列（30 min）

### 1.1 关系

| 从表 | 到表 | 连键 | 说明 |
|------|------|------|------|
| marts_fact_subscription_terms | marts_dim_subscription_plan | plan + billing_cycle（见下） | 取价格 |
| dim_date | （无） | 用于 Slicer | 日期筛选 |

Power BI 默认不支持多列关系。用 bridge：

1. 在 **marts_fact_subscription_terms** 新建列：`PlanBilling = [plan] & "|" & [billing_cycle]`
2. 在 **marts_dim_subscription_plan** 新建列：`PlanBilling = [plan] & "|" & [billing_cycle]`
3. 建关系：terms[PlanBilling] → dim_subscription_plan[PlanBilling]

### 1.2 若用了 A（dbt 加了 amount_dkk）

1. 建关系：terms[subscription_plan_key] → dim_subscription_plan[subscription_plan_key]
2. 不需要 PlanBilling bridge

---

## 第二步：DAX Measures（45 min）

### 2.1 取单日日期（用于筛选）

```
Selected Date = SELECTEDVALUE(dim_date[Date], MAX(dim_date[Date]))
```

### 2.2 Total ARR（某日时点的年化收入）

若 terms 有 amount_dkk（选 A）：

```
Total ARR = 
VAR SnapshotDate = [Selected Date]
VAR ActiveSubs = 
    FILTER(
        marts_fact_subscription_terms,
        marts_fact_subscription_terms[start_date] <= SnapshotDate
        && (ISBLANK(marts_fact_subscription_terms[end_date]) 
            || marts_fact_subscription_terms[end_date] >= SnapshotDate)
    )
RETURN
SUMX(
    ActiveSubs,
    SWITCH(
        LOWER(marts_fact_subscription_terms[billing_cycle]),
        "monthly", RELATED(marts_dim_subscription_plan[amount_dkk]) * 12,
        "month", RELATED(marts_dim_subscription_plan[amount_dkk]) * 12,
        "annual", RELATED(marts_dim_subscription_plan[amount_dkk]),
        "yearly", RELATED(marts_dim_subscription_plan[amount_dkk]),
        RELATED(marts_dim_subscription_plan[amount_dkk]) * 12
    )
)
```

若 terms 没有 amount_dkk（选 B），用 LOOKUPVALUE：

```
Total ARR = 
VAR SnapshotDate = [Selected Date]
VAR ActiveSubs = 
    FILTER(
        marts_fact_subscription_terms,
        marts_fact_subscription_terms[start_date] <= SnapshotDate
        && (ISBLANK(marts_fact_subscription_terms[end_date]) 
            || marts_fact_subscription_terms[end_date] >= SnapshotDate)
    )
RETURN
SUMX(
    ActiveSubs,
    VAR Amt = LOOKUPVALUE(
        marts_dim_subscription_plan[amount_dkk],
        marts_dim_subscription_plan[plan], marts_fact_subscription_terms[plan],
        marts_dim_subscription_plan[billing_cycle], marts_fact_subscription_terms[billing_cycle]
    )
    VAR Cycle = LOWER(marts_fact_subscription_terms[billing_cycle])
    RETURN
    IF(Cycle IN {"annual","yearly"}, Amt, Amt * 12)
)
```

> 提示：若 billing_cycle 实际取值不同，把 "monthly"/"annual" 等改成你数据里的值。

### 2.3 New ARR（某月新增订阅的 ARR）

```
New ARR = 
VAR PeriodStart = EOMONTH([Selected Date], -1) + 1
VAR PeriodEnd = EOMONTH([Selected Date], 0)
VAR NewSubs = 
    FILTER(
        marts_fact_subscription_terms,
        marts_fact_subscription_terms[start_date] >= PeriodStart
        && marts_fact_subscription_terms[start_date] <= PeriodEnd
    )
RETURN
SUMX(
    NewSubs,
    SWITCH(
        LOWER(marts_fact_subscription_terms[billing_cycle]),
        "monthly", RELATED(marts_dim_subscription_plan[amount_dkk]) * 12,
        "month", RELATED(marts_dim_subscription_plan[amount_dkk]) * 12,
        "annual", RELATED(marts_dim_subscription_plan[amount_dkk]),
        "yearly", RELATED(marts_dim_subscription_plan[amount_dkk]),
        RELATED(marts_dim_subscription_plan[amount_dkk]) * 12
    )
)
```

（选 B 时同样把 RELATED 换成 LOOKUPVALUE 版本）

### 2.4 MRR（可选，Total ARR / 12）

```
MRR = [Total ARR] / 12
```

---

## 第三步：第二页布局（60 min）

### 3.1 顶部：日期 Slicer

- 用 dim_date[Date] 做 Slicer，支持单日或多日
- 若希望按「月」选，可再加一列 `YearMonth = FORMAT(dim_date[Date], "YYYY-MM")` 做 Slicer

### 3.2 KPI Cards（4 个）

| 卡片 | Measure |
|------|---------|
| Total ARR | [Total ARR] |
| New ARR | [New ARR] |
| MRR | [MRR] |
| 活跃订阅数 | 见下 |

### 2.5 活跃订阅数（用于 KPI）

```
Active Subscriptions = 
VAR SnapshotDate = [Selected Date]
RETURN
COUNTROWS(
    FILTER(
        marts_fact_subscription_terms,
        marts_fact_subscription_terms[start_date] <= SnapshotDate
        && (ISBLANK(marts_fact_subscription_terms[end_date]) 
            || marts_fact_subscription_terms[end_date] >= SnapshotDate)
    )
)
```

### 3.3 图表

| 图表 | 类型 | X 轴 | Y 轴 |
|------|------|------|------|
| ARR by Plan | 柱状图 | plan | [Total ARR] |
| ARR by Billing Cycle | 柱状图/饼图 | billing_cycle | [Total ARR] |
| ARR 趋势（可选） | 折线图 | dim_date[Date] | [Total ARR] |

---

## 第四步：校验（15 min）

1. 选某一天（如 2024-06-30）
2. 用 Excel：对 terms 筛 start_date ≤ 日期、end_date ≥ 日期，按 plan 查价格，手算 ARR
3. 对比 Power BI 的 Total ARR 是否一致

---

## 时间分配建议

| 时段 | 内容 |
|------|------|
| 上午 | dbt 加列（如需）+ 关系 + PlanBilling + 3 个核心 measure（Total ARR, New ARR, Active Subscriptions）|
| 中午 | KPI 卡片 + 日期 Slicer，先出「能看」的一版 |
| 下午 | 按 plan、billing_cycle 的图表 + 趋势图 |
| 收尾 | 校验 + 格式 |

---

## 可能卡住的地方

1. **terms 没有关联到 dim_date**：不用建关系，用 Slicer 选日期，measure 用 `[Selected Date]` 即可
2. **Total ARR 为 0**：检查 start_date/end_date 格式、billing_cycle 取值是否和 SWITCH 里一致
3. **LOOKUPVALUE 多行报错**：在 SUMX 里逐行取，不要对整表用 LOOKUPVALUE

按这个顺序做，一天可以收尾。加油。
