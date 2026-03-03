# 订阅相关模型 — 当前结构梳理

---

## 一、数据流概览

```
bronze (external)          silver                    gold                     marts
─────────────────────────────────────────────────────────────────────────────────────
subscription_invoices  →  silver_subscription_   →  fact_erp_subscription_  →  marts_fact_subscription_invoice
                           invoice_practice_1        invoice                    (join plan 取 subscription_plan_key)

subscription_terms     →  silver_subscription_   →  dim_billing_            →  marts_fact_subscription_terms
                           terms_practice_1          subscription_terms        (join plan 取 amount_dkk)

subscription_events    →  silver_subscription_   →  fact_billing_           →  marts_fact_subscription_events
                           event_practice_1          subscription_events

                          fact_erp_subscription_invoice (valid 发票)
                                    ↓
                          dim_subscription_plan (plan 价格目录)  →  marts_dim_subscription_plan
```

---

## 二、各表职责

| 表 | 来源 | 颗粒度 | 核心字段 | 用途 |
|----|------|--------|----------|------|
| **marts_fact_subscription_invoice** | fact_erp + dim_plan | 每张发票一行 | subscription_key, paid_at, amount_dkk, plan, billing_cycle | **算 MRR/ARR 的主力**：每续订一张票，有 period_start/period_end（在 gold 有，marts 未选出） |
| **marts_fact_subscription_terms** | dim_terms + dim_plan | 每个订阅一行 | subscription_key, start_date, end_date, amount_dkk | 订阅生命周期；业务假设：价格锁在 created_at |
| **marts_fact_subscription_events** | fact_events | 每个事件一行 | event_type, plan, billing_cycle | 创建/续订/取消等行为 |
| **marts_dim_subscription_plan** | dim_plan | plan 价格目录 | plan, billing_cycle, amount_dkk, valid_from, valid_to | 不同时期的 plan 价格 |

---

## 三、MRR/ARR 计算 — 你现在的选择

### 方案：以 Invoice 为主（推荐）

- 用 **marts_fact_subscription_invoice**
- 需要在 marts 中补充 **period_start**、**period_end**（gold 已有）
- 按 `period_start` 的月份汇总，并按 billing_cycle 做月化 → MRR
- ARR = MRR × 12
- New ARR = 每个订阅的首张发票（MIN period_start）的年化金额

### Terms 的角色

- 当前：每条 terms 通过 `created_at between valid_from and valid_to` 取 plan 价格
- 若只用 Invoice 算 MRR/ARR，terms 可用于补充分析（cohort、流失归因等），非必选

---

## 四、需要补齐的点

1. **marts_fact_subscription_invoice**：在 select 中加上 `period_start`、`period_end`（便于按 period 算 MRR）
2. **marts_fact_subscription_invoice**：在 select 中加上 `mrr_per_invoice`、`arr_per_invoice`（按 billing_cycle 换算）— 可选，也可在 Power BI 中算

---

## 五、简化记忆

| 问题 | 答案 |
|------|------|
| 算 MRR/ARR 用哪个表？ | **marts_fact_subscription_invoice** |
| Terms 必须吗？ | 不必须，以 Invoice 为主即可 |
| Events 必须吗？ | 不必须，做归因时再用 |
| Plan 用来做什么？ | 价格目录，Invoice/Terms 通过 plan + 日期 join 取价格 |
