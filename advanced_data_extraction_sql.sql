/* 
The Corporate Finance team is conducting a mid-year performance audit of global client accounts. 
They need to analyze total transactional revenue, average order size, and the variety of products purchased across different client accounts.
 */

SELECT 
    c.company_name,
    t.billing_currency,
    COUNT(t.transaction_id) AS total_transactions_count,
    COUNT(DISTINCT t.product_category) AS unique_categories_purchased,
    SUM(t.settled_amount) AS raw_total_revenue,
    ROUND(SUM(t.settled_amount), 2) AS rounded_total_revenue,
    ROUND(AVG(t.settled_amount), 2) AS average_transaction_value,
    IFNULL(campaign_owner, 'Unassigned / Open Tier') AS assigned_manager,
    -- Variants: -- NVL(campaign_owner, 'Unassigned') | COALESCE(campaign_owner, 'Unassigned')

    COALESCE(mobile_phone, home_phone, office_phone, 'No Contact Provided') AS primary_contact_number,
    -- Variants: -- Evaluates from left to right, stopping immediately at the first non-null string.

    -- If total_ad_spend is 0, NULLIF turns it into NULL. Any number divided by NULL safely becomes NULL.
    ROUND(total_revenue / NULLIF(total_ad_spend, 0.00), 2) AS return_on_ad_spend_ratio

FROM financial_ledgers AS t
INNER JOIN corporate_clients AS c 
    ON t.client_account_id = c.account_id
WHERE 
    t.transaction_status = 'SETTLED'
    AND c.account_id NOT LIKE 'TEST%'
GROUP BY 
    c.company_name,
    t.billing_currency
HAVING SUM(t.settled_amount) > 100000.00
ORDER BY rounded_total_revenue DESC;

/*
| company_name             | billing_currency | total_transactions_count | unique_categories_purchased | raw_total_revenue | rounded_total_revenue | average_transaction_value |
|--------------------------|------------------|--------------------------|-----------------------------|-------------------|-----------------------|---------------------------|
| Nexus Logistics Corp     | USD              | 142                      | 5                           | 542050.453        | 542050.45             | 3817.26                   |
| Vertex Financials Ltd    | EUR              | 98                       | 3                           | 310400.000        | 310400.00             | 3167.35                   |
| Pacific Retail Alliance  | USD              | 210                      | 7                           | 289150.758        | 289150.76             | 1376.91                   |
| Apex Industrial Holdings | GBP              | 45                       | 2                           | 185000.301        | 185000.30             | 4111.12                   |
| Horizon Tech Solutions   | USD              | 73                       | 4                           | 120450.250        | 120450.25             | 1650.00                   |
*/

/* 
The HR Operations team is migrating employee profiles into a new Human Capital Management (HCM) platform. 
The source data contains messy formatting: inconsistent casing in names, raw email paths, and unformatted system keys.
*/

SELECT 
    UPPER(first_name) AS normalized_first_name, -- LOWER(first_name) | INITCAP(first_name)

    TRIM(last_name) AS cleaned_last_name, -- LTRIM(last_name) | RTRIM(last_name) | BTRIM('xxySmithyyx', 'xy');Result: 'Smith'

    REPLACE(national_id, '-', 'X') AS masked_national_id, -- TRANSLATE(national_id, '123', 'XXX') | REGEXP_REPLACE(national_id, '[0-9]', 'X')

    SUBSTRING(work_email FROM 1 FOR POSITION('@' IN work_email) - 1) AS corporate_handle, 
    -- Variants: -- SUBSTR(work_email, 1, 5) | LEFT(work_email, 8) | RIGHT(work_email, 10)

    LPAD(department_id, 5, '0') AS padded_dept_code,  -- RPAD(department_id, 5, ' ')


    CONCAT(job_title, ' (ID: ', employee_id, ')') AS position_display_label, -- job_title || ' (ID: ' || employee_id || ')'

    LENGTH(comments) AS audit_notes_length -- LEN(comments) | CHAR_LENGTH(comments) | OCTET_LENGTH(comments)

FROM hr_employee_roster AS emp
INNER JOIN corporate_offices AS off 
    ON emp.office_code = off.office_code
WHERE 
    emp.employment_status = 'ACTIVE'
    -- Direct exact string match filtering
    AND LOWER(off.country_region) = 'emea' -- off.country_region LIKE '%EMEA%' | off.country_region ILIKE 'emea'

GROUP BY 
    first_name, last_name, national_id, work_email, department_id, job_title, employee_id, comments, off.country_region
HAVING 
    LENGTH(comments) > 10
ORDER BY 
    cleaned_last_name ASC;

/*
| normalized_first_name | cleaned_last_name | masked_national_id | corporate_handle | padded_dept_code | position_display_label       | audit_notes_length |
|-----------------------|-------------------|--------------------|------------------|------------------|------------------------------|--------------------|
| JONATHAN              | ADAMS             | ABX882X11          | jadams           | 00410            | HR Specialist (ID: EMP-902)  | 45                 |
| ELENA                 | DIMITROV          | BGX991X00          | edimitrov        | 00102            | Talent Acquisition (ID: 441) | 12                 |
| CHLOE                 | LEFEVRE           | FRX552X32          | clefevre         | 00410            | Compensation Analyst (ID: 12)| 78                 |
| MATEO                 | SILVA             | PTX002X88          | msilva           | 00890            | HR Director (ID: EMP-003)    | 115                |
| ALICIA                | SMITH             | UKX774X12          | asmith           | 00102            | HR Generalist (ID: EMP-114)  | 24                 |
*/

/*
The Logistics Planning and Financial Accounting teams need to track aging cargo shipments and forecast cash flows. 
They require a breakdown of how long items have been in transit, the specific months and quarters things occurred,
 a projection of when automated payment terms will trigger, and a filter that dynamically isolates records from a moving time window.

*/

SELECT 
    shipment_id,
    dispatch_timestamp,
    delivery_timestamp,
    
    CURDATE(),
    
    CAST('2026-06-19' AS DATE) AS date_format, --TO_CHAR() / FORMAT()

    EXTRACT(YEAR FROM dispatch_timestamp) AS calendar_year, 
    -- DATE_PART('month', dispatch_timestamp) | MONTH(dispatch_timestamp) | YEAR(dispatch_timestamp)
    EXTRACT(QUARTER FROM dispatch_timestamp) AS calendar_quarter,

    DATE_TRUNC('month', dispatch_timestamp) AS starting_month_floor,
    -- DATE_TRUNC('day', dispatch_timestamp) | DATE_TRUNC('quarter', dispatch_timestamp)
 
    DATEDIFF(day, dispatch_timestamp, delivery_timestamp) AS total_days_in_transit,
    -- Variants: -- DATEDIFF(hour, dispatch_timestamp, delivery_timestamp) | delivery_timestamp - dispatch_timestamp

    -- 4. Date Arithmetic: Shifting a calendar date forward to find a deadline
    DATEADD(day, 30, delivery_timestamp) AS dynamic_payment_due_date
    -- Variants: -- delivery_timestamp + INTERVAL '30 days' | DATEADD(month, 1, delivery_timestamp)

FROM supply_chain_ledger
WHERE 
    -- 5. Filtering data using fixed historical boundaries
    dispatch_timestamp >= '2026-01-01'
    -- Variants: -- dispatch_timestamp BETWEEN '2026-01-01' AND '2026-06-30'

    -- 6. Dynamically filtering using relative operational windows (e.g., looking back 90 days from right now)
    AND dispatch_timestamp >= DATEADD(day, -90, CURRENT_DATE)
    -- Variants: -- NOW() | CURRENT_TIMESTAMP | GETDATE() | CURRENT_DATE - INTERVAL '90 days'

    -- 7. Isulating records that fall on specific calendar components (e.g., excluding weekends)
    AND EXTRACT(DAYOFWEEK FROM dispatch_timestamp) NOT IN (6, 7);
    -- Variants: -- DAYOFWEEK() ranges vary by dialect (e.g., 1-7 where 1=Sunday or 0-6 where 0=Sunday)

/*
| shipment_id | dispatch_timestamp  | delivery_timestamp  | calendar_year | calendar_quarter | starting_month_floor | total_days_in_transit | dynamic_payment_due_date |
|-------------|---------------------|---------------------|---------------|------------------|----------------------|-----------------------|--------------------------|
| SHP-1004    | 2026-04-15 08:30:00 | 2026-04-20 14:15:00 | 2026          | 2                | 2026-04-01 00:00:00  | 5                     | 2026-05-20 14:15:00      |
| SHP-1092    | 2026-04-17 11:00:00 | 2026-04-24 09:00:00 | 2026          | 2                | 2026-04-01 00:00:00  | 7                     | 2026-05-24 09:00:00      |
| SHP-1120    | 2026-05-04 16:45:00 | 2026-05-06 10:30:00 | 2026          | 2                | 2026-05-01 00:00:00  | 2                     | 2026-06-05 10:30:00      |
| SHP-1231    | 2026-05-12 07:15:00 | 2026-05-15 18:00:00 | 2026          | 2                | 2026-05-01 00:00:00  | 3                     | 2026-06-14 18:00:00      |
| SHP-1355    | 2026-06-01 13:00:00 | 2026-06-04 11:20:00 | 2026          | 2                | 2026-06-01 00:00:00  | 3                     | 2026-07-04 11:20:00      |
*/

/*
The Operations and Logistics team needs to evaluate warehouse performance, shipping costs, and order bottlenecks. 
The raw table contains mixed data that must be categorized dynamically.
*/

SELECT 
    order_id,
    carrier_name,
    total_weight_kg,
    days_in_transit,


    CASE order_status
        WHEN 'DELIVERED' THEN 'Completed Cycle'
        WHEN 'RETURNED'  THEN 'Reverse Logistics'
        ELSE 'In-Flight / Pending'
    END AS simplified_status, -- COALESCE(order_status, 'Unknown') 
    --| DECODE(order_status, 'DELIVERED', 'Completed Cycle', 'Pending') If the order_status is 'DELIVERED', the function returns 'Completed Cycle'.


    CASE 
        WHEN days_in_transit > 7 AND shipping_mode = 'AIR' THEN 'Critical Delay - Air Break'
        WHEN days_in_transit > 14 OR order_status = 'LOST' THEN 'High Financial Liability'
        ELSE 'Standard Transit Window'
    END AS routing_risk_profile,

    CASE 
        WHEN actual_delivery_date IS NULL THEN 'Action Required: Missing Delivery Timestamp'
        ELSE 'Timestamp Verified'
    END AS data_integrity_flag,
    -- Variants: -- WHEN ISNULL(actual_delivery_date) THEN ... | WHEN actual_delivery_date IS NOT NULL THEN ...

    SUM(CASE 
        WHEN region = 'LATAM' THEN shipping_fee 
        WHEN region = 'EMEA'  THEN shipping_fee * 1.10 -- Simulating a 10% tariff adjustment
        ELSE 0  -- or NUll
    END) AS adjusted_regional_shipping_spend,

    COUNT(CASE 
        WHEN days_in_transit > contractual_sla_days THEN 1 ELSE 0 -- or NUll
    END) AS total_contractual_sla_breaches,

    ROUND(total_weight_kg * ( --CEIL() or FLOOR() TRUNCATE() TRUNC() ABS() MOD() POWER() SQRT() RANDOM()
        CASE 
            WHEN shipping_mode = 'AIR'   THEN 5.50
            WHEN shipping_mode = 'OCEAN' THEN 1.25
            ELSE 2.50
        END
    ), 2) AS calculated_freight_cost_usd


FROM operations_manifest AS manifest
INNER JOIN logistics_carriers AS carrier 
    ON manifest.carrier_id = carrier.id
WHERE 
    manifest.dispatch_year = 2026
GROUP BY 
    order_id, carrier_name, total_weight_kg, days_in_transit, order_status, 
    shipping_mode, actual_delivery_date, region, shipping_fee, contractual_sla_days
HAVING 
    (CASE WHEN order_status = 'DELIVERED' THEN days_in_transit ELSE 0 END) >= 0
ORDER BY 
    calculated_freight_cost_usd DESC;

/*
| order_id | carrier_name | total_weight_kg | days_in_transit | simplified_status   | routing_risk_profile     | data_integrity_flag                       | adjusted_regional_shipping_spend | total_contractual_sla_breaches | calculated_freight_cost_usd |
|----------|--------------|-----------------|-----------------|---------------------|--------------------------|-------------------------------------------|----------------------------------|--------------------------------|-----------------------------|
| ORD-8831 | EXP-DHL      | 1200.50         | 9               | Completed Cycle     | Critical Delay - Air Break| Timestamp Verified                        | 4500.00                          | 1                              | 6602.75                     |
| ORD-1102 | EXP-FEDEX    | 4500.00         | 15              | Completed Cycle     | High Financial Liability | Timestamp Verified                        | 0.00                             | 1                              | 5625.00                     |
| ORD-9942 | CARRIER-ONE  | 250.00          | 3               | In-Flight / Pending | Standard Transit Window  | Action Required: Missing Delivery Timestamp| 350.25                           | 0                              | 625.00                      |
| ORD-4412 | EXP-UPS      | 85.25           | 2               | Reverse Logistics   | Standard Transit Window  | Timestamp Verified                        | 137.50                           | 0                              | 213.13                      |
| ORD-0031 | LOCAL-TRUCK  | 12.00           | 1               | Completed Cycle     | Standard Transit Window  | Timestamp Verified                        | 0.00                             | 0                              | 30.00                       |
*/

/*
The Distribution and Planning team needs to cross-reference daily warehouse dispatches against inventory thresholds to pinpoint reorder issues.
*/

SELECT 
    core_sales.product_id,
    core_sales.total_units_sold,
    inv.warehouse_id,
    inv.available_stock,
    all_products_avg.avg_warehouse_stock
FROM (
    -- 1. Derived Table (Subquery in FROM): Pre-aggregating and filtering sales data
    SELECT 
        product_id, 
        SUM(quantity) AS total_units_sold
    FROM order_line_items
    WHERE order_status = 'FULFILLED'
    GROUP BY product_id
) AS core_sales

-- 2. Multi-Condition JOIN: Merging on both keys AND non-key logic directly in the ON clause
INNER JOIN warehouse_inventory AS inv 
    ON core_sales.product_id = inv.product_id
    AND inv.stock_status = 'ACTIVE' 
    -- Variants: -- Adding conditions like: AND inv.available_stock > 0

-- 3. JOINing a Subquery: Bringing in pre-calculated warehouse macro metrics
INNER JOIN (
    SELECT 
        warehouse_id, 
        ROUND(AVG(available_stock), 0) AS avg_warehouse_stock
    FROM warehouse_inventory
    GROUP BY warehouse_id
) AS all_products_avg 
    ON inv.warehouse_id = all_products_avg.warehouse_id

-- 4. Self-JOIN: Comparing the warehouse table to itself to find safety stock variances
INNER JOIN warehouse_inventory AS safety_check
    ON inv.product_id = safety_check.product_id
    AND inv.warehouse_id = safety_check.warehouse_id
WHERE 
    inv.available_stock < safety_check.safety_threshold;

/*
| product_id | total_units_sold | warehouse_id | available_stock | avg_warehouse_stock |
|------------|------------------|--------------|-----------------|---------------------|
| PROD-0012  | 850              | WH-EAST-01   | 15              | 420                 |
| PROD-0045  | 1200             | WH-EAST-01   | 45              | 420                 |
| PROD-0911  | 340              | WH-WEST-02   | 8               | 185                 |
| PROD-0322  | 610              | WH-CENT-03   | 50              | 615                 |
| PROD-0077  | 2100             | WH-WEST-02   | 12              | 185                 |
*/

/*
The internal compliance and financial audit team needs to pull a highly specific batch of invoices. 
They are searching for transactions that present clear risk indicators (such as manual overrides or missing system IDs), 
fall within certain structural cost brackets, and belong to vendors flagged during external vendor evaluations.
*/

SELECT 
    invoice_id,
    vendor_name,
    total_amount,
    approval_status
FROM vendor_invoices
WHERE 
  
    total_amount > 5000.00  -- >= | < | <= | != | <>
   
    AND total_amount BETWEEN 5000.00 AND 250000.00 -- total_amount NOT BETWEEN 5000.00 AND 250000.00

    AND (
        approval_status = 'PENDING' 
        OR approval_status = 'MANUAL_OVERRIDE'
    )

    AND vendor_name LIKE 'GLOBAL%' -- '%GLOBAL%', '%GLOBAL', ILIKE 'global%' (Case-Insensitive)
    AND vendor_name NOT LIKE '%TEST%'

    AND tax_identifier_code IS NOT NULL -- IS NULL

    AND payment_terms_code IN ('NET_30', 'NET_60', 'DUE_ON_RECEIPT') -- payment_terms_code NOT IN ('NET_90', 'INT_FEE')

    -- 7. Dynamic List Filtering via an Independent Subquery (Uncorrelated Scalar/List Subquery)
    AND vendor_id IN (
        SELECT id 
        FROM flagged_risk_vendors 
        WHERE risk_score_rating = 'CRITICAL'
    );

/*
| invoice_id | vendor_name              | total_amount | approval_status |
|------------|--------------------------|--------------|-----------------|
| INV-2026-A | GLOBAL LOGISTICS SERVICES| 45200.50     | PENDING         |
| INV-2026-F | GLOBAL FREIGHT CORP      | 128000.00    | MANUAL_OVERRIDE |
| INV-2026-M | GLOBAL SUPPLY NETWORKS   | 7150.00      | PENDING         |
| INV-2026-R | GLOBAL ENERGY SOLUTION   | 215000.00    | MANUAL_OVERRIDE |
| INV-2026-X | GLOBAL PACKAGING LTD     | 18450.00     | PENDING         |
*/

/*
The Corporate Operations and Finance team needs to identify locations that are lagging in production output. 
To analyze this without hardcoding benchmarks, they need to dynamically calculate global averages, isolate regional records, 
evaluate historical operational thresholds, and cross-reference records against an independent list of high-risk facility codes.
*/

SELECT 
    outer_fac.facility_id,
    outer_fac.facility_name,
    outer_fac.regional_cluster,
    outer_fac.monthly_operating_cost,


    (
        SELECT ROUND(AVG(monthly_operating_cost), 2) 
        FROM manufacturing_facilities
        WHERE operational_status = 'ACTIVE'
    ) AS global_average_operating_cost,

    (
        SELECT SUM(total_dispatches)
        FROM logistics_manifests AS inner_log
        WHERE inner_log.origin_facility_id = outer_fac.facility_id
    ) AS total_facility_dispatches

FROM (

    SELECT * FROM manufacturing_facilities
    WHERE operational_status = 'ACTIVE'
      AND regulatory_compliance_pass = TRUE
) AS outer_fac

WHERE 

    outer_fac.location_country_code IN (
        SELECT country_code 
        FROM risk_assessment_ledger 
        WHERE tariff_risk_tier = 'HIGH'
    )

    AND EXISTS (
        SELECT 1 
        FROM incident_logs AS inner_inc 
        WHERE inner_inc.facility_id = outer_fac.facility_id 
          AND inner_inc.severity_level = 'CRITICAL'
    )

    AND outer_fac.monthly_operating_cost > (
        SELECT AVG(monthly_operating_cost) 
        FROM manufacturing_facilities
    )

GROUP BY 
    outer_fac.facility_id, outer_fac.facility_name, 
    outer_fac.regional_cluster, outer_fac.monthly_operating_cost, outer_fac.location_country_code

HAVING 

    SUM(outer_fac.monthly_operating_cost) < (
        SELECT SUM(emergency_funding_cap) 
        FROM corporate_budget_caps 
        WHERE fiscal_year = 2026
    )
ORDER BY 
    outer_fac.monthly_operating_cost DESC;

/*
| facility_id | facility_name       | regional_cluster | monthly_operating_cost | global_average_operating_cost | total_facility_dispatches |
|-------------|---------------------|------------------|------------------------|-------------------------------|----------------------------|
| FAC-9902    | Monterrey Logistics | LATAM            | 145000.00              | 89200.50                      | 1240                       |
| FAC-1104    | Shenzhen Assembly   | APAC             | 132000.00              | 89200.50                      | 3100                       |
| FAC-4412    | Frankfurt Freight   | EMEA             | 115500.50              | 89200.50                      | 850                        |
| FAC-0031    | São Paulo Plant     | LATAM            | 98000.00               | 89200.50                      | 410                        |
| FAC-7732    | Veracruz Shipping   | LATAM            | 91000.00               | 89200.50                      | 620                        |
*/

/*
The Fulfillment Operations team needs a real-time list of outstanding corporate orders to coordinate warehouse picking queues.
*/

SELECT 
    order_id,
    shipping_tier,
    cargo_weight_kg,
    order_date,
    destination_country
FROM warehouse_order_queue
WHERE 
    fulfillment_status = 'PENDING'

-- 1. Multi-Column Ordering with explicit directional keywords (ASC / DESC)
ORDER BY --ORDER BY 2 ASC, 3 DESC, 4 ASC;
    shipping_tier ASC,       -- Rule 1: Alphabetical priority ('Express' before 'Standard')
    cargo_weight_kg DESC,    -- Rule 2: Heaviest items first to clear warehouse floor space
    order_date ASC;          -- Rule 3: Tie-breaker using First-In, First-Out (FIFO) chronological aging
    cargo_weight_kg DESC NULLS LAST; -- or NULLS FIRST

/*
| order_id | shipping_tier | cargo_weight_kg | order_date | destination_country |
|----------|---------------|-----------------|------------|---------------------|
| ORD-9941 | Express       | 4500.00         | 2026-06-18 | Costa Rica          |
| ORD-1102 | Express       | 1200.50         | 2026-06-17 | United States       |
| ORD-3342 | Express       | 1200.50         | 2026-06-19 | Panama              |
| ORD-0041 | Express       | 85.00           | 2026-06-15 | Canada              |
| ORD-8851 | Standard      | 9800.00         | 2026-06-16 | Mexico              |
| ORD-2239 | Standard      | 340.00          | 2026-06-17 | Colombia            |
| ORD-7711 | Standard      | 15.25           | 2026-06-14 | Brazil              |
*/

/*
The Corporate Audit and Operations teams need to reconcile transactional data across multiple legacy platforms (Platform A and Platform B). 
They want to combine customer datasets completely, check for duplicates, find overlapping corporate clients,
 and isolate records that exist in one ledger but are missing from the other.
*/

-- 1. UNION ALL: Combines both datasets completely, including any duplicate rows. 
-- This is highly optimized because it does not perform a distinct sorting pass under the hood.
SELECT customer_id, company_name, billing_country FROM platform_a_clients
UNION ALL
SELECT customer_id, company_name, billing_country FROM platform_b_clients;
-- Variants: Used when you need an absolute master volume log where duplicate entries are expected or required.


-- 2. UNION: Combines both datasets but strips out any duplicate rows, returning only unique records.
SELECT customer_id, company_name, billing_country FROM platform_a_clients
UNION
SELECT customer_id, company_name, billing_country FROM platform_b_clients;
-- Variants: Performs an implicit DISTINCT operation, making it heavier on database memory/CPU.


-- 3. INTERSECT: Extracts only the overlapping rows that exist in BOTH tables.
SELECT customer_id, company_name, billing_country FROM platform_a_clients
INTERSECT
SELECT customer_id, company_name, billing_country FROM platform_b_clients;
-- Variants: Excellent for finding shared accounts or multi-platform active users.


-- 4. EXCEPT / MINUS: Isolates rows that exist in the first table but are missing from the second table.
SELECT customer_id, company_name, billing_country FROM platform_a_clients
EXCEPT
SELECT customer_id, company_name, billing_country FROM platform_b_clients;


/*
The Corporate Finance team needs a multi-level structural summary of freight costs across regional distribution networks.
Instead of running three separate queries to extract the granular city totals, country totals, and the grand total, 
they require a single unified dataset that rolls these layers up automatically.
*/
SELECT 
    operating_region,
    distribution_hub_city,
    COUNT(shipment_id) AS total_shipments_dispatched,
    ROUND(SUM(freight_cost_usd), 2) AS total_freight_spend_usd
FROM operational_shipments
WHERE 
    shipment_year = 2026
-- Grouping with ROLLUP creates hierarchical sub-totals from left to right (Region -> City -> Grand Total)
GROUP BY ROLLUP (operating_region, distribution_hub_city); -- GROUP BY operating_region, distribution_hub_city WITH ROLLUP

/*
| operating_region | distribution_hub_city | total_shipments_dispatched | total_freight_spend_usd |
|------------------|-----------------------|----------------------------|-------------------------|
| LATAM            | Alajuela              | 120                        | 45000.00                |
| LATAM            | San Jose              | 340                        | 125000.50               |
| LATAM            | NULL                  | 460                        | 170000.50               | <-- Subtotal for LATAM Region
| NA               | Chicago               | 510                        | 310000.00               |
| NA               | Houston               | 280                        | 145000.75               |
| NA               | NULL                  | 790                        | 455000.75               | <-- Subtotal for NA Region
| NULL             | NULL                  | 1250                       | 625001.25               | <-- GRAND TOTAL (All Regions & Cities)
*/

/*
The Finance planning team wants to see a running comparison of individual store expenses against their regional department averages, 
alongside a direct mathematical variance column to catch over-budget facilities.
*/

WITH regional_finance_cohort AS (
    SELECT 
        department_id,
        facility_id,
        monthly_expense,
        
        -- 1. Standard Aggregation Over a Partition (Static comparative benchmark)
        AVG(monthly_expense) OVER(PARTITION BY department_id) AS dept_average_expense,
        
        -- 2. Arithmetic directly using Window Functions (Subtracting the partition baseline)
        monthly_expense - AVG(monthly_expense) OVER(PARTITION BY department_id) AS expense_variance_from_avg,
        
        -- 3. Running Totals (Adding an ORDER BY clause inside the window frames it as a running metric)
        SUM(monthly_expense) OVER(PARTITION BY department_id ORDER BY monthly_expense ASC) AS cumulative_dept_spend,

        -- 4. Extremum tracking within the group
        MAX(monthly_expense) OVER(PARTITION BY department_id) AS peak_dept_expense
        
        -- Inline Comments on Variations:
        -- COUNT(monthly_expense) OVER(PARTITION BY department_id) | To find size of cohort
        -- MIN(monthly_expense) OVER(PARTITION BY department_id)   | To find floor baseline
)
SELECT 
    department_id,
    facility_id,
    monthly_expense,
    ROUND(dept_average_expense, 2) AS dept_average_expense,
    ROUND(expense_variance_from_avg, 2) AS expense_variance_from_avg,
    ROUND(cumulative_dept_spend, 2) AS cumulative_dept_spend,
    peak_dept_expense
FROM regional_finance_cohort;
    
/*
| department_id | facility_id | monthly_expense | dept_average_expense | expense_variance_from_avg | cumulative_dept_spend | peak_dept_expense |
|---------------|-------------|-----------------|----------------------|---------------------------|-----------------------|-------------------|
| DEPT-OPS      | FAC-01      | 10000.00        | 15000.00             | -5000.00                  | 10000.00              | 22000.00          |
| DEPT-OPS      | FAC-02      | 13000.00        | 15000.00             | -2000.00                  | 23000.00              | 22000.00          |
| DEPT-OPS      | FAC-03      | 22000.00        | 15000.00             | 7000.00                   | 45000.00              | 22000.00          |
| DEPT-SALES    | FAC-04      | 5000.00         | 7500.00              | -2500.00                  | 5000.00               | 10000.00          |
| DEPT-SALES    | FAC-05      | 10000.00        | 7500.00              | 2500.00                   | 15000.00              | 10000.00          |
*/

/*
The Operations team needs to run a competitive analysis on shipping carrier processing times. 
They want to test all three major SQL ranking functions side-by-side to observe how each handles identical/tied metric values.
*/

WITH logistical_performance_ranking AS (
    SELECT 
        region_key,
        carrier_name,
        days_to_ship,
        
        -- 1. ROW_NUMBER: Strictly sequential integers. Never leaves gaps, assigns unique arbitrary values to ties.
        ROW_NUMBER() OVER(PARTITION BY region_key ORDER BY days_to_ship ASC) AS row_num_sequence,
        
        -- 2. RANK: Skips ranks if a tie occurs. (e.g., if two items tie for 1st place, the next rank is 3rd).
        RANK() OVER(PARTITION BY region_key ORDER BY days_to_ship ASC) AS rank_with_gaps,
        
        -- 3. DENSE_RANK: Never skips a rank if a tie occurs. (e.g., if two items tie for 1st place, the next rank is 2nd).
        DENSE_RANK() OVER(PARTITION BY region_key ORDER BY days_to_ship ASC) AS dense_rank_continuous

FROM warehouse_dispatch_logs
)
SELECT 
    region_key,
    carrier_name,
    days_to_ship,
    row_num_sequence,
    rank_with_gaps,
    dense_rank_continuous
FROM logistical_performance_ranking;

/*
| region_key | carrier_name | days_to_ship | row_num_sequence | rank_with_gaps | dense_rank_continuous |
|------------|--------------|--------------|------------------|----------------|-----------------------|
| LATAM      | DHL_EXPRESS  | 1            | 1                | 1              | 1                     |
| LATAM      | FEDEX_AIR    | 3            | 2                | 2              | 2                     | -- Tie start
| LATAM      | UPS_GROUND   | 3            | 3                | 2              | 2                     | -- Tie end
| LATAM      | LOCAL_POST   | 5            | 4                | 4              | 3                     | <-- Observe Rank 4 vs Dense 3!
| NA         | DHL_EXPRESS  | 2            | 1                | 1              | 1                     |
| NA         | FEDEX_AIR    | 4            | 2                | 2              | 2                     |
*/

/*
The Finance and Operations teams need to look at sequential ordering trends. 
They want to check the previous order's value to calculate velocity, preview the next upcoming order value for logistics prep, 
and benchmark everything against the absolute first and last orders placed by that customer.
*/

WITH customer_order_sequencing AS (
    SELECT 
        customer_id,
        order_date,
        order_amount,
        
        -- 1. LAG: Pulls a value from the PREVIOUS row in the partition
        LAG(order_amount, 1, 0.00) OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS previous_order_amount, -- LAG(order_amount, 2) | Shifts back by exactly 2 rows instead of 1
        
        -- 2. LEAD: Pulls a value from the NEXT row in the partition
        LEAD(order_amount, 1) OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS next_order_amount,
        
        -- 3. FIRST_VALUE: Grabs the absolute earliest value inside the window partition
        FIRST_VALUE(order_amount) OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS initial_historical_purchase,
        
        -- 4. LAST_VALUE: Grabs the latest value. 
        -- CRITICAL: Requires explicit frame modification (ROWS BETWEEN) because the default frame stops at the current row!
        LAST_VALUE(order_amount) OVER(
            PARTITION BY customer_id 
            ORDER BY order_date ASC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS ultimate_historical_purchase


        
)
SELECT 
    customer_id,
    order_date,
    order_amount,
    previous_order_amount,
    next_order_amount,
    initial_historical_purchase,
    ultimate_historical_purchase
FROM customer_order_sequencing;
