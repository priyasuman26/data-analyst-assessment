# data-analyst-assessment


1) Total Customers (KPI Card)

Shows the total number of unique customers in the selected time period.
This is a top-level indicator of customer base growth.

Metric logic: Distinct Count(customer_id)

2) Active Customers (KPI Card)

Shows customers who are currently active in the selected period (not churned).
This gives a clearer picture than total customers because it focuses on current usage/revenue base.

Metric logic: Distinct customers with active subscription

3) Revenue Recurring by Month (Line Chart)

Displays Monthly Recurring Revenue (MRR) trend over time.
Helps spot revenue momentum — growth, stagnation, or decline.

Why it matters: MRR is the core SaaS growth metric.

Metric logic: Sum(monthly_price) for active subscriptions per month

4) Logo Churn Customers by Month (Bar Chart)

Shows number of customers churned each month (logo churn).
This highlights customer retention issues even when revenue looks stable.

Why it matters: Losing customers continuously is a long-term risk for sustainable growth.

Metric logic: Distinct customers where end_date falls in month

5) Source Breakdown (Horizontal Bar Chart)

Breakdown of customers by segment/source buckets like SMB, Enterprise, Mid-Market, unspecified.
This helps understand which customer segment is contributing most.

Why it matters: Helps align GTM strategy and prioritization.

Metric logic: Customer share by segment

6) Funnel Customers by Stage (Funnel Chart)

Tracks customer movement across lifecycle stages:
Signup → Trial → Activated → Paid → Churned

Why it matters: This is useful to identify funnel leakage and where conversions drop most.

Metric logic: Count of customers per lifecycle stage based on milestone dates.

✅ How to Use the Dashboard (Best Practice)

Start with Timeline to focus on a period (ex: last 6 months)

Check MRR trend to see revenue direction

Compare with Logo churn to see if growth is healthy or just temporary

Use Funnel chart to find conversion bottlenecks

Slice by Channel / Country to identify high-quality acquisition sources

🔍 Key Insights You Can Pull From This

If MRR rises but churn also rises → growth may be “unstable”

If signups are high but paid is low → conversion gap in funnel

If churn spikes in a specific month → possible product/price/support issue

If SMB dominates but Enterprise is low → GTM focus may need adjustment