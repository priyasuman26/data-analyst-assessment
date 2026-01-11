# SaaS Growth and GTM Analytics (Power BI + MySQL + Python)

  # Overview of the analysis
This project builds a SaaS Growth + GTM Analytics dashboard using MySQL for data modeling/metrics and Power BI for visualization for better desicion making for better decision making.
The goal is to track the complete business flow from customer acquisition → funnel conversion → recurring revenue → churn( entire customer lifecycle)

The output dashboard supports quick GTM decision-making by showing:
- how customer base is growing,
- how MRR behaves month by month,
- to understand the churn spikes,
- to understand the customer segments contribute most,
- to understand the users drop in the funnel 

---

  # Tools used
- MySQL 8
  - Table creation, data cleaning, metric calculation
  - SQL techniques used: CTEs, date-based joins, aggregations and date based aggregations
- Power BI
  - Dashboard creation and interactive slicer are used
- Excel
  - Used to create the    dim_date    calendar CSV and load into MySQL for accurate time series calculations
- Python (Jupyter Notebook)
  - Light EDA and data validation checks
  - to inspect distributions, nulls, and confirm date consistency quickly
  - Helpful for debugging issues like mixed date formats or unexpected duplicates


  # Data issues identified
During EDA + cleaning, it was used to to explore data and clean as you go. 

  # Customers table
- Blank segment values were transformed to  "unspecified"
- Some lifecycle dates (signup/trial/activated/paid/churn) may be NULL → retained as NULL for correct analytics
- For signup_date there are blanks and in situation like this it is best to contact your senior/stakeholder  on how to handle them, either remove or push a fixed date for such issues. 
- in my case, given that the number is low those dates are not taken into consideration while doing the calculations. 

  # Subscriptions table
- end_date had blank strings and then replaced with NULL 
- Subscription activity logic depends on correct date ranges (   start_date   ,    end_date   )

  # Events table
- event_date datatype was then transformed to correct data type 

  # Calendar  (   dim_date )
-    yearmonth    was then altered in table for better time series analysis


  # Metric definitions

  # Customer Metrics
- **Total Customers**
  -    DISTINCTCOUNT(customer_id)    to understand the total unique users
- **Active Customers**
  - Unique customers with an active subscription that are active in a given period of time

  # Revenue Metrics
- **MRR (Monthly Recurring Revenue)**
  - Sum of subscription   of monthly_price for calculate the MRR for the company 
  - Active subscription for the project
    - start_date <= month_end
    - end_date IS NULL OR end_date >= month_start

- **ARR (Annual Recurring Revenue)**
  - ARR = MRR * 12


- **ARPC (Average Revenue per Customer)**
  - ARPC = MRR / Active Customers

  # Churn Metrics
- **Logo churn (customers lost)**
  - Distinct customers whose subscription ended or who never paid again for the subsciption after the initial payment
- **Logo churn rate**
  -    customers_lost / active_customers_at_start_of_month   

- **Revenue churn**
  -    MRR_lost / MRR_at_start_of_month   

  # Funnel Metrics
Customer funnel for the lifecycle of the SaaS product: 
- Signup
- Trial
- Activated
- Paid
- Churned





  # Key insights (from dashboard snapshot)
Based on the dashboard view (Jan 2023 – Sep 2023):

- **Total customers = 964** and **Active customers = 718**  
  → churn customer can be inferred and impacts active number of customers 
- MRR rises strongly early months, peaks around Apr, then trends drops and then before it flatens 
 
- **Logo churn spikes around Apr–May**  
  → retention risk should be carefully investigated 

- Funnel shows largest drop between **Trial → Activated** and **Activated → Paid**  
  → onboarding/activation and conversion are improvement areas and should be investigated for better descision making.
- Segment/source breakdown shows a noticeable **“unspecified” segment**  
  → data capture quality issue for segmentation analysis and should be futhur understood for the better placement of the unspecified data.

---

  # Dashboard explanation

  # Filters
- **Acquisition Channel**
  - Slice dashboard performance by acquisition source and has multiple options for better understanding
- **Country Code**
  - Compare performance by geography and better compairision 
- **Timeline**
  - Select date range for trend analysis

  # Visuals
- **KPI Cards**
  - Total Customers: uniqure customers 
  - Active Customers: unique active customers
- **Revenue Recurring by Month (Line chart)**
  - Tracks MRR trend month-by-month
- **Logo churn customers by month (Bar chart)**
  - Tracks customer churn volume per month
- **Source breakdown (Bar chart)**
  - Segment distribution across SMB/Mid-market/Enterprise/Unspecified
- **Funnel customers by stage (Funnel chart)**
  - Signup → Trial → Activated → Paid → Churned flow and drop-offs


  # Assumptions
-    monthly_price    represents  monthly recurring cost for the customer 
- blank end_date means “not churned yet” and is treated as NULL


  # Instructions to reproduce results

  # 1) Create tables
Run:
-    01_table_creation.sql   

Creates base tables such as:
- customers
- subscriptions
- events
- dim_date

  # 2) Load CSV datasets
Load the raw CSV files into MySQL (using    LOAD DATA INFILE   ).
Ensure MySQL secure-file-priv folder is used if enabled.

  # 3) Data cleaning
Run:
-    02_data_cleaning.sql   

Cleans missing/blank values, fixes date columns, calendar helper fields etc.

  # 4) Core SaaS metrics
Run:
-    03_core_metrics.sql   

Generates:
- MRR
- ARR
- ARPC
- churn metrics

# 5) Funnel analysis
Run:
-    04_funnel_analysis.sql   

Generates funnel stage metrics and conversion counts to understandf the drop

  # 6) Optional analysis
Run:
-    05_optional_analysis.sql   

Includes additional EDA / supporting analysis to better understand the database. 

  # 7) Python EDA (validation notebook)
Open and run:
-    *.ipynb    notebook (Jupyter)

This notebook is used for:
- quick data profiling (null checks, duplicates)
- validating date ranges and month-level outputs
- sanity checking metric outputs before visualizing in Power BI

  # 8) Power BI dashboard build
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
-- multiple selction can be made in the filter and slicer of acquition and country on powerbi based on the stakeholders needs and vision for better desicion making

 Chart Explanations + Actions
1) Total Customers (KPI Card)
What it shows: Total unique customers in the selected time period.

2) Active Customers (KPI Card)
What it shows: Customers who are currently active (not churned).


3) Acquisition Channel (Slicer)
What it does: Filters performance by source.
Purpose:
Use it to identify the various channels through which the acquistion is made and based filter based on that. 


4) Country Code (Slicer)
What it does: Filters by geography.
Purpose: 
1. If churn spikes in a region → may indicate localization/pricing/support issues.
2. If a country performs well → then campaign and sales for product can be more. 

5) Timeline (Date Slicer)
What it does: Lets you focus trends for a selected date window.
Purpose:
1. Helps validate if GTM actions actually moved metrics.

6) Revenue Recurring by Month (MRR Line Chart)
What it shows: Monthly recurring revenue trend (growth, stability, decline).
Purpose
1. If MRR increases steadily → good GTM execution, strong recurring revenue engine.
2.  If MRR flattens → growth slowed → check funnel drop-offs + expansion then look into various campaigna and support
3.  If MRR declines → churn / contraction issue → analyze churn months + customer segment losses
then look into various campaigna and support

7) Logo Churn Customers by Month (Bar Chart)
What it shows: Number of churned customers per month.
Action lens:
1. If churn is low/stable → retention is under control.
2. If churn spikes → investigate that cohort:
relook into:  pricing change? product issue? focus on the segment churn? 
8) Source Breakdown (Segment Distribution Bar Chart)
this graph show how various source affect on the product and gives better understanding where the stakeholder should be focussing on in terms for the source and segment
9) Funnel Customers by Stage (Funnel Chart)
What it shows: Customer movement through lifecycle:
Signup → Trial → Activated → Paid → Churned
Action lens:
If Trial → Activated drops → onboarding/product adoption issue.
If Activated → Paid drops → pricing
If Paid → Churned increases → retention success + customer health should be focussed on. 

# Insights & Recommendations
1) Key growth bottlenecks to understand where the growth is slow

Bottleneck 1: Funnel leakage (Trial → Activated + Activated → Paid)
From the funnel view:
Signup: 964
Trial: 649
Activated: 388
Paid: 358
The largest drop is between Trial → Activated, which signals an onboarding / adoption bottleneck. Customers are interested enough to try, but do not deem worthy enough to have it has recurring  payment for the product.
Second leakage occurs at Activated → Paid, meaning value communication, pricing or conversion nudges are not strong enough for customer acquisition 


Bottleneck 2: Churn spikes have negative impacts
Logo churn peaks sharply in:
Apr with 80 churned customers
May with 55 churned customers
Mar with 52 churned customers 
Even if acquisition is steady, churn at this scale can reduce net growth of the product which also aligns with MRR flattening after hitting the peak.

2) Strongest and weakest acquisition channels

From the dashboard, acquisition channel is present as a slicer
it is used to classify strongest/weakest channels:

Strongest channel = high Paid conversion, low churn, high ARPC

Weakest channel = high Trial volume but low activation + high churn

Purpose:  Use the acquisition channel slicer and validate:
Funnel conversion rate per channel
Logo churn per channel
ARPC and MRR contribution per channel

3) What I would investigate next 

If I had to prioritize next investigations, I’d do this in order:

Churn by signup month / paid month for better understanding 
Check whether churn is during onboarding or if it is a retention issue 
Understand the Churn spike root cause (Mar–May)


4) Actionable recommendations for leadership (1–2 key actions)
Recommendation 1: Fix activation bottleneck (Trial → Activated)

Why: That is the biggest funnel leak and strongest controllable growth lever.

What to do:
Improve onboarding by guided setup, checklists etc
Add activation nudges such as email sequences, in-app prompts
Track activation drivers using event data

Expected impact:

Even a small activation lift will significantly increase Paid conversions because it’s earlier in funnel and impacts the full pipeline.