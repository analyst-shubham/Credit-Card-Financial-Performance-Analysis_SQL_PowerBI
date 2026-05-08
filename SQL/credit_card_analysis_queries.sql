Credit Card Financial Performance Analysis | SQL + Power BI
By:Shubham Kumar Bhakta
=============================================
SECTION 1: DATABASE SETUP
=============================================
-- Create cc_detail table

CREATE TABLE cc_detail (
    Client_Num INT,
    Card_Category VARCHAR(20),
    Annual_Fees INT,
    Activation_30_Days INT,
    Customer_Acq_Cost INT,
    Week_Start_Date DATE,
    Week_Num VARCHAR(20),
    Qtr VARCHAR(10),
    current_year INT,
    Credit_Limit DECIMAL(10,2),
    Total_Revolving_Bal INT,
    Total_Trans_Amt INT,
    Total_Trans_Ct INT,
    Avg_Utilization_Ratio DECIMAL(10,3),
    Use_Chip VARCHAR(10),
    Exp_Type VARCHAR(50),
    Interest_Earned DECIMAL(10,3),
    Delinquent_Acc VARCHAR(5)
);

-- Create cust_detail table

CREATE TABLE cust_detail (
    Client_Num INT,
    Customer_Age INT,
    Gender VARCHAR(5),
    Dependent_Count INT,
    Education_Level VARCHAR(50),
    Marital_Status VARCHAR(20),
    State_cd VARCHAR(50),
    Zipcode VARCHAR(20),
    Car_Owner VARCHAR(5),
    House_Owner VARCHAR(5),
    Personal_Loan VARCHAR(5),
    Contact VARCHAR(50),
    Customer_Job VARCHAR(50),
    Income INT,
    Cust_Satisfaction_Score INT
);

-- Importing Data to both tables

COPY cc_detail
FROM 'D:\DA Prep\Projects\SQL + Power bi\Credit Card Finance\credit_card.csv'
DELIMITER ','
CSV HEADER ;

COPY cust_detail
FROM 'D:\DA Prep\Projects\SQL + Power bi\Credit Card Finance\customer.csv'
DELIMITER ','
CSV HEADER ;

SELECT * FROM cc_detail ;
SELECT * FROM cust_detail;

=============================================
SECTION 2: DATA EXPLORATION
=============================================
-- Total customers, total transactions
SELECT count(DISTINCT client_num) FROM cc_detail ;
SELECT count(DISTINCT client_num) FROM cust_detail ;

-- Date range
SELECT min(week_start_date) as start_date, max(week_start_date) as end_date
FROM cc_detail;

-- How many unique card categories exist?
SELECT DISTINCT card_category FROM cc_detail;

-- Check for nulls or anomalies
SELECT * FROM cc_detail WHERE client_num IS NULL;
SELECT * FROM cust_detail WHERE client_num IS NULL;
SELECT * FROM cc_detail WHERE card_category IS NULL;

=============================================
SECTION 3: Revenue Analysis
=============================================
-- KPIs 
SELECT 
    SUM(annual_fees + total_trans_amt + interest_earned) AS total_revenue,
    SUM(interest_earned) AS total_interest,
    SUM(total_trans_amt) AS transaction_amount,
    COUNT(DISTINCT client_num) AS total_customers
FROM cc_detail;

-- Revenue, Utilization, Transaction count, Interest earned and Annual Fees by card category
SELECT 
    card_category,
    SUM(annual_fees + total_trans_amt + interest_earned) AS total_revenue,
    ROUND(AVG(avg_utilization_ratio)::NUMERIC,3) AS avg_utilization,
    SUM(total_trans_ct) AS transactions,
    SUM(interest_earned) AS interest_earned,
    SUM(annual_fees) AS annual_fees
FROM cc_detail
GROUP BY card_category
ORDER BY total_revenue DESC;

--Revenue by quarter
SELECT 
    qtr,
    SUM(annual_fees + total_trans_amt + interest_earned) AS total_revenue,
    COUNT(*) AS transaction_count
FROM cc_detail
GROUP BY qtr
ORDER BY qtr;

-- Weekly revenue trend
SELECT 
    week_num,
    week_start_date,
    SUM(annual_fees + total_trans_amt + interest_earned) AS weekly_revenue
FROM cc_detail
GROUP BY week_num, week_start_date
ORDER BY week_start_date;

=============================================
SECTION 4: Customer Segmentation Analysis
=============================================

-- Revenue by gender
SELECT 
    cu.gender,
    SUM(cr.annual_fees + cr.total_trans_amt + cr.interest_earned) AS total_revenue
FROM cc_detail cr
JOIN cust_detail cu ON cr.client_num = cu.client_num
GROUP BY cu.gender
ORDER BY total_revenue DESC;

-- Revenue by age group
SELECT
    CASE
        WHEN cu.customer_age <= 30 THEN '20-30'
        WHEN cu.customer_age <= 40 THEN '31-40'
        WHEN cu.customer_age <= 50 THEN '40-50'
        WHEN cu.customer_age <= 60 THEN '50-60'
        ELSE '60+'
    END AS age_group,
    SUM(cr.annual_fees + cr.total_trans_amt + cr.interest_earned) AS total_revenue
FROM cc_detail cr
JOIN cust_detail cu ON cr.client_num = cu.client_num
GROUP BY age_group
ORDER BY total_revenue DESC;

-- Revenue by income group
SELECT 
    CASE
        WHEN cu.income <= 35000 THEN 'Low'
        WHEN cu.income <= 70000 THEN 'Mid'
        ELSE 'High'
    END AS income_group,
    SUM(cr.annual_fees + cr.total_trans_amt + cr.interest_earned) AS total_revenue
FROM cc_detail cr
JOIN cust_detail cu ON cr.client_num = cu.client_num
GROUP BY income_group
ORDER BY total_revenue DESC;

-- Revenue by education level
SELECT 
    cu.education_level,
    SUM(cr.annual_fees + cr.total_trans_amt + cr.interest_earned) AS total_revenue
FROM cc_detail cr
JOIN cust_detail cu ON cr.client_num = cu.client_num
GROUP BY cu.education_level
ORDER BY total_revenue DESC;

-- Revenue & Customer Satisfaction Score by Occupation
SELECT 
    cu.customer_job as occupation,
    SUM(cr.annual_fees + cr.total_trans_amt + cr.interest_earned) AS total_revenue,
    SUM(cu.income) AS total_income,
    ROUND(AVG(cu.cust_satisfaction_score)::NUMERIC, 2) AS avg_css_score
FROM cc_detail cr
JOIN cust_detail cu ON cr.client_num = cu.client_num
GROUP BY cu.customer_job
ORDER BY total_revenue DESC;


=============================================
SECTION 5: Transaction Behaviour Analysis
=============================================
-- Revenue by expenditure type 
SELECT 
    exp_type,
    SUM(annual_fees + total_trans_amt + interest_earned) AS total_revenue
FROM cc_detail
GROUP BY exp_type
ORDER BY total_revenue DESC;

-- Revenue by transaction mode
SELECT 
    use_chip,
    SUM(annual_fees + total_trans_amt + interest_earned) AS total_revenue,
    ROUND(
        SUM(annual_fees + total_trans_amt + interest_earned) * 100.0 /
        SUM(SUM(annual_fees + total_trans_amt + interest_earned)) OVER(), 2
    ) AS percentage
FROM cc_detail
GROUP BY use_chip
ORDER BY total_revenue DESC;

-- Delinquency rate
SELECT 
    COUNT(*) AS total_accounts,
    SUM(CASE WHEN delinquent_acc = '1' THEN 1 ELSE 0 END) AS delinquent_accounts,
    ROUND(
        SUM(CASE WHEN delinquent_acc = '1' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) AS delinquency_rate_pct
FROM cc_detail;

=============================================
SECTION 6: Geographic Analysis
=============================================
-- Top 5 states by revenue 
SELECT 
    cu.state_cd,
    SUM(cr.annual_fees + cr.total_trans_amt + cr.interest_earned) AS total_revenue
FROM cc_detail cr
JOIN cust_detail cu ON cr.client_num = cu.client_num
GROUP BY cu.state_cd
ORDER BY total_revenue DESC
LIMIT 5;

=============================================
SECTION 7: Week-over-Week Revenue Analysis
=============================================

-- WoW revenue change 
WITH weekly_revenue AS (
    SELECT
        week_num,
        week_start_date,
        SUM(annual_fees + total_trans_amt + interest_earned) AS current_week_revenue
    FROM cc_detail
    GROUP BY week_num, week_start_date
),
wow_comparison AS (
    SELECT
        week_num,
        week_start_date,
        current_week_revenue,
        LAG(current_week_revenue) OVER (ORDER BY week_start_date) AS prev_week_revenue
    FROM weekly_revenue
)
SELECT
    week_num,
    week_start_date,
    current_week_revenue,
    prev_week_revenue,
    (current_week_revenue - prev_week_revenue) AS wow_change,
    ROUND(
        (current_week_revenue - prev_week_revenue) * 100.0 / 
        NULLIF(prev_week_revenue, 0), 2
    ) AS wow_change_pct
FROM wow_comparison
ORDER BY week_start_date DESC;

=============================================
SECTION 8: Data Refresh Validation
=============================================

-- Adding new credit card transaction data
COPY cc_detail
FROM 'D:\DA Prep\Projects\SQL + Power bi\Credit Card Finance\cc_add.csv'
DELIMITER ','
CSV HEADER ;

-- Adding new customer data
COPY cust_detail
FROM 'D:\DA Prep\Projects\SQL + Power bi\Credit Card Finance\cust_add.csv'
DELIMITER ','
CSV HEADER ;

-- Row counts after data addition
SELECT 'cc_detail' AS table_name, COUNT(*) AS total_rows FROM cc_detail
UNION ALL
SELECT 'cust_detail', COUNT(*) FROM cust_detail;

SELECT 
    week_num,
    week_start_date,
    COUNT(*) AS records_added,
    SUM(annual_fees + total_trans_amt + interest_earned) AS revenue
FROM cc_detail
WHERE week_start_date = (SELECT MAX(week_start_date) FROM cc_detail)
GROUP BY week_num, week_start_date;
