# Business Analysis Report

As a Business Analyst, the primary objective of this analysis is to identify actionable patterns and improvement opportunities.

---

---

##  Business Questions & Insights

### 1.  Are we retaining our customers over time?

> **Query 1: Monthly Cohort Retention Analysis**

** Insight:**
Customer retention drastically declines after the first month across all cohorts. For example, the January 2017 cohort retained only ~3% of users by Month 3.

** Business Impact:**
- Customer Lifetime Value (CLTV) is low
- High cost of acquisition is not balanced by repeat revenue

** Recommendation:**
- Launch post-purchase journeys (emails, offers)
- Incentivize second purchases (within 30 days)

---

### 2.  What types of customers do we serve?

> **Query 2: RFM Segmentation**

** Insight:**
Most customers fall into **"Others" (22,354 users)** or **"At Risk" (18,553)**. Only 1,759 customers are "Champions".

| Segment               | Count   | Avg Spend | Recency (days) |
|------------------------|---------|-----------|----------------|
| Champions              | 1,759   | $334.81   | 174.3          |
| At Risk                | 18,553  | $244.28   | 435.6          |
| Potential Loyalists    | 19,055  | $236.70   | 128.7          |
| Others                 | 22,354  | $55.30    | 361.8          |

** Business Impact:**
- Inactive customers dominate the platform
- Valuable customers are at risk of churn

** Recommendation:**
- Retarget “At Risk” and “Potential Loyalists” with win-back campaigns
- Reward “Champions” with exclusive perks

---

### 3.  Which sellers are driving our revenue?

> **Query 3: Top 20 Sellers by Order Volume and Delivery Performance**

** Insight:**
Top sellers process over 1,000 orders with <5% late delivery. A few sellers with high sales (e.g., >$200 average price) also maintain strong logistics.

** Business Impact:**
- Small group of sellers contribute to most revenue
- Late deliveries can damage customer experience

** Recommendation:**
- Promote and retain high-performing sellers
- Penalize or support sellers with frequent delays
- Use top sellers to set SLAs for onboarding new vendors

---

### 4.  Are there any unusual order behaviors?

> **Query 4: Products per Order (Order Density)**

** Insight:**
Some individual orders contain a **very high number of products**.

** Business Impact:**
- May indicate **bulk buyers** → potential B2B or VIP segment
- Could also signal **fraudulent or bot behavior**

** Recommendation:**
- Identify repeat bulk purchasers for VIP treatment
- Flag unusual orders for fraud investigation

---

### 5.  Are some sellers overloaded?

> **Query 5: Seller Workload by Order Count**

** Insight:**
A handful of sellers are handling disproportionately more orders. One seller has **849 orders**, far above the rest.

** Business Impact:**
- Operational bottlenecks if overloaded sellers face downtime
- Dependency risk on a few top sellers

** Recommendation:**
- Monitor workload of top sellers
- Encourage diversification by onboarding more sellers

---

##  Tools
```

- **SQL Platform:** MySQL / PostgreSQL
- **Analysis Type:** Cohort, RFM, Operational, Seller Performance
- **Focus Areas:** Retention, Segmentation, Marketplace Health

---

## Final Takeaways

This analysis reveals key revenue and retention risks:

- A **leaky bucket** problem: too many one-time buyers
- **Seller concentration risk**: few sellers dominate the platform
- **Untapped customer segments**: bulk buyers & reactivation opportunities

By acting on these insights, the business can:
- Boost retention & repeat purchase rates
- Improve seller management & marketplace balance
- Prevent churn and fraud through targeted interventions
