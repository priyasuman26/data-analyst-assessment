# SaaS Growth and GTM Analytics (Power BI + MySQL)

## Overview of the analysis
This project builds a SaaS Growth + GTM Analytics dashboard using MySQL for data modeling/metrics and Power BI for visualization.
The goal is to track the complete business flow from customer acquisition → funnel conversion → recurring revenue → churn.

The output dashboard supports quick GTM decision-making by showing:
- how customer base is growing,
- how MRR behaves month by month,
- where churn spikes,
- which customer segments contribute most,
- where users drop in the funnel (Signup → Paid).

---

## Tools used
- MySQL 8
  - Table creation, data cleaning, metric computation (MRR/ARR/Churn/Funnel)
  - SQL techniques used: CTEs, date-based joins, aggregations
- Power BI
  - Dashboard creation and interactive slicing (Channel, Country, Timeline)
- Excel
  - Used to create the `dim_date` calendar CSV and load into MySQL
- Python (Jupyter Notebook)
  - Light EDA and data validation checks
  - Used to quickly inspect distributions, nulls, and confirm date consistency
  - Helpful for debugging issues like mixed date formats or unexpected duplicates
---

## Data issues identified
During EDA + cleaning, a few quality issues were noticed and fixed:

### Customers table
- Blank `segment` values (`''`) existed → standardized to "unspecified"
- Some lifecycle dates (signup/trial/activated/paid/churn) may be NULL → retained as NULL for correct analytics
- For signup_date there are blanks and in situation like this it is best to contact your senior/stakeholder  on how to handle them, either remove or push a fixed date for such issues. 
- in my case, given that the number id low those dates are not taken into consideration while doing the calculations. 

### Subscriptions table
- `end_date` had blank strings (`''`) → converted to NULL
- Subscription activity logic depends on correct date ranges (`start_date`, `end_date`)

### Events table
- `event_date` datatype inconsistencies → converted to proper DATE type

### Calendar dimension (`dim_date`)
- Added `yearmonth` to simplify month-level grouping
- Datatypes were adjusted to avoid YYYY-MM being treated like a full DATE

---

## Metric definitions

### Customer Metrics
- **Total Customers**
  - `DISTINCTCOUNT(customer_id)` in selected filter window
- **Active Customers**
  - Unique customers with an active subscription in the selected time period

### Revenue Metrics
- **MRR (Monthly Recurring Revenue)**
  - Sum of subscription `monthly_price` for subscriptions active in the month  
  - Active subscription definition:
    - `start_date <= month_end`
    - `end_date IS NULL OR end_date >= month_start`

- **ARR (Annual Recurring Revenue)**
  - `ARR = MRR * 12`
  - Assumes `monthly_price` is normalized monthly recurring price

- **ARPC (Average Revenue per Customer)**
  - `ARPC = MRR / Active Customers`

### Churn Metrics
- **Logo churn (customers lost)**
  - Distinct customers whose subscription ended in that month
- **Logo churn rate**
  - `customers_lost / active_customers_at_start_of_month`

- **Revenue churn**
  - `MRR_lost / MRR_at_start_of_month`

### Funnel Metrics
Customer funnel is tracked using milestone dates:
- Signup
- Trial
- Activated
- Paid
- Churned

Counts at each stage are shown in funnel visualization to locate conversion drop-offs.


## Key insights (from dashboard snapshot)
Based on the dashboard view (Jan 2023 – Sep 2023):

- **Total customers = 964** and **Active customers = 718**  
  → churn exists and impacts active base
- MRR rises strongly early months, peaks around Apr, then trends flatter  
  → growth slowed or churn offset new additions
- **Logo churn spikes around Apr–May**  
  → retention risk period worth investigation
- Funnel shows largest drop between **Trial → Activated** and **Activated → Paid**  
  → onboarding/activation and conversion are improvement areas
- Segment/source breakdown shows a noticeable **“unspecified” segment**  
  → data capture quality issue for segmentation analysis

---

## Dashboard explanation

### Filters
- **Acquisition Channel**
  - Slice dashboard performance by acquisition source
- **Country Code**
  - Compare performance by geography
- **Timeline**
  - Select date window for trend analysis

### Visuals
- **KPI Cards**
  - Total Customers: overall base
  - Active Customers: currently active customers
- **Revenue Recurring by Month (Line chart)**
  - Tracks MRR trend month-by-month
- **Logo churn customers by month (Bar chart)**
  - Tracks customer churn volume per month
- **Source breakdown (Bar chart)**
  - Segment distribution across SMB/Mid-market/Enterprise/Unspecified
- **Funnel customers by stage (Funnel chart)**
  - Signup → Trial → Activated → Paid → Churned flow and drop-offs

---

## Assumptions and limitations

### Assumptions
- `monthly_price` represents normalized monthly recurring subscription value
- Subscription is considered active for a month if it overlaps any day in that month
- Blank end_date means “not churned yet” and is treated as NULL
- Funnel stage dates correctly represent customer movement through lifecycle

### Limitations
- If a customer can have **multiple subscriptions**, churn metrics need customer-level consolidation (otherwise churn may be overstated)
- ARR assumes monthly pricing model (no annual billing logic included)
- Segment analysis depends on completeness of `segment/source` fields

---

## Instructions to reproduce results

### 1) Create tables
Run:
- `01_table_creation.sql`

Creates base tables such as:
- customers
- subscriptions
- events
- dim_date

### 2) Load CSV datasets
Load the raw CSV files into MySQL (using `LOAD DATA INFILE`).
Ensure MySQL secure-file-priv folder is used if enabled.

### 3) Data cleaning
Run:
- `02_data_cleaning.sql`

Cleans missing/blank values, fixes date columns, calendar helper fields etc.

### 4) Core SaaS metrics
Run:
- `03_core_metrics.sql`

Generates:
- MRR
- ARR
- ARPC
- churn metrics

### 5) Funnel analysis
Run:
- `04_funnel_analysis.sql`

Generates funnel stage metrics and conversion counts.

### 6) Optional analysis
Run:
- `05_optional_analysis.sql`

Includes additional EDA / supporting analysis.

### 7) Python EDA (validation notebook)
Open and run:
- `*.ipynb` notebook (Jupyter)

This notebook is used for:
- quick data profiling (null checks, duplicates)
- validating date ranges and month-level outputs
- sanity checking metric outputs before visualizing in Power BI

### 8) Power BI dashboard build
1. Connect Power BI to MySQL database
2. Import cleaned tables
3. Build visuals:
   - KPI cards (Total / Active)
   - MRR trend line
   - churn bar chart
   - segment/source breakdown
   - funnel by stage
4. Add slicers: Channel, Country, Timeline


 Explaination of each chart
-- multiple selction can be made in the filters of acquition and country code based on the stakeholders needs.

 Chart Explanations + Actions
1) Total Customers (KPI Card)

What it shows: Total unique customers in the selected time period.
Action lens:

✅ If it increases → acquisition is working, top-of-funnel is healthy.

❌ If flat/drops → pipeline/acquisition needs attention (channels, targeting, lead flow).

2) Active Customers (KPI Card)

What it shows: Customers who are currently active (not churned).
Action lens:

✅ If active customers grow → retention + acquisition both stable.

❌ If active customers fall while total customers grows → churn is eating growth → retention initiatives needed (product adoption, CSM, support, pricing).

3) Acquisition Channel (Slicer)

What it does: Filters performance by source.
Action lens:

Use it to identify the various channels through which the acquistion is made and based filter based on that. 


4) Country Code (Slicer)

What it does: Filters by geography.
Action lens:

If churn spikes in a region → may indicate localization/pricing/support issues.

If a country performs well → double down via campaigns or sales focus there.

5) Timeline (Date Slicer)

What it does: Lets you focus trends for a selected date window.
Action lens:

Helps validate if GTM actions actually moved metrics.

6) Revenue Recurring by Month (MRR Line Chart)

What it shows: Monthly recurring revenue trend (growth, stability, decline).
Action lens:

✅ If MRR increases steadily → good GTM execution, strong recurring revenue engine.

❌ If MRR flattens → growth slowed → check funnel drop-offs + expansion.

❌ If MRR declines → churn / contraction issue → analyze churn months + customer segment losses.

7) Logo Churn Customers by Month (Bar Chart)

What it shows: Number of churned customers per month.
Action lens:

✅ If churn is low/stable → retention is under control.

❌ If churn spikes → investigate that cohort:

Did pricing change?

Was there a product issue?

Did one segment churn heavily?

Prioritize retention playbooks / customer success outreach for high-risk groups.

8) Source Breakdown (Segment Distribution Bar Chart)

What it shows: Customer distribution across segments (SMB / Enterprise / Mid-Market / Unspecified).
Action lens:

If SMB dominates → GTM is volume-driven; focus on efficiency + automation.

If Enterprise is growing → focus on account expansion + long-term retention.

If “Unspecified” is high → data capture issue → fix segmentation fields in CRM/forms.

9) Funnel Customers by Stage (Funnel Chart)

What it shows: Customer movement through lifecycle:
Signup → Trial → Activated → Paid → Churned
Action lens:

Biggest drop = biggest opportunity.

If Trial → Activated drops → onboarding/product adoption issue.

If Activated → Paid drops → pricing/value packaging issue.

If Paid → Churned increases → retention success + customer health monitoring needed.



# Insights & Recommendations
1) Key growth bottlenecks (what’s slowing growth)

Bottleneck 1: Funnel leakage (Trial → Activated + Activated → Paid)
From the funnel view:

Signup: 964

Trial: 649

Activated: 388

Paid: 358

The largest drop is between Trial → Activated, which signals an onboarding / adoption bottleneck. Customers are interested enough to try, but a big chunk doesn’t reach the “value moment”.

Second leakage occurs at Activated → Paid, meaning value communication, pricing or conversion nudges are not strong enough.

Bottleneck 2: Churn spikes are offsetting growth
Logo churn peaks sharply in:

Apr (~80 churned customers)

May (~55 churned customers)

Mar (~52 churned customers)

Even if acquisition is steady, churn at this scale can cap net growth. This also aligns with MRR flattening after the peak.

2) Strongest and weakest acquisition channels

From the dashboard, acquisition channel is present as a slicer, but channel performance is not explicitly visualized in the screenshot.

How I would classify strongest/weakest channels (logic):

Strongest channel = high Paid conversion, low churn, high ARPC

Weakest channel = high Trial volume but low activation + high churn

✅ Next action: Use the acquisition channel slicer and validate:

Funnel conversion rate per channel

Logo churn per channel

ARPC/MRR contribution per channel

If 1 channel drives a large portion of churn (common), that’s where leadership attention should go first.

3) What I would investigate next (next analysis steps)

If I had to prioritize next investigations, I’d do this in order:

Cohort churn analysis

Churn by signup month / paid month

Check whether churn is early-life churn (bad onboarding) or late-life churn (retention issue)

Churn spike root cause (Mar–May)

Were these customers from the same channel/segment/country?

Did pricing/product/support change around that time?

Segment retention

SMB vs Mid-market vs Enterprise churn pattern
SMB churn tends to spike if value onboarding is weak.

Time-to-activate & time-to-paid

If time-to-activate is long → users not reaching product value quickly

4) Actionable recommendations for leadership (1–2 key actions)
Recommendation 1: Fix activation bottleneck (Trial → Activated)

Why: That is the biggest funnel leak and strongest controllable growth lever.

What to do:

Improve onboarding (guided setup, checklists, first success milestone)

Add activation nudges (email sequences + in-app prompts)

Track activation drivers using event data (what actions predict activation)

Expected impact:

Even a small activation lift will significantly increase Paid conversions because it’s earlier in funnel and impacts the full pipeline.