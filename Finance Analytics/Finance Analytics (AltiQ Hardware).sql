-- As a product owner, I want to generate a report of individual product sales (aggregated on a monthly basis at the product code level) for Croma India customer for FY=2021 so that I can track individual
-- product sales and run further product analytics on it in excel.
-- The report should have the following fields,
-- 1. Month
-- 2. Product Name
-- 3. Variant
-- 4. Sold Quantity
-- 5. Gross Price Per Item
-- 6. Gross Price Total

# Check Croma Market
select * from dim_customer where customer like "%croma%";

# Search for transations related to that customer code
select * from fact_sales_monthly where customer_code = '90002002';

-- We want this for "Financinal year" are dates in this database is "Calendar Dates"
-- Convert Calendar Dates --> Financinal Year
select * from fact_sales_monthly where customer_code = '90002002' and Year(date) = 2021 order by date desc;
select * from fact_sales_monthly where customer_code = '90002002' and Year(date_add(date,Interval 4 Month)) = 2021 order by date desc;

# Go to functions and right click itget_fiscal_year (CHECK DOCUMENTATION)
select * from fact_sales_monthly where customer_code = '90002002' and get_fiscal_year(date)=2021 order by date asc;

# So far we have retrieved month and sold quantity

# Now I'll show how you will retrieve PRODCUT NAME and VARIANT an GROSS PRICE and GROSS PRICE TOTAL
select f.date,f.product_code,p.product, p.variant,f.sold_quantity, g.gross_price, round(gross_price * sold_quantity,2) as gross_price_total  from fact_sales_monthly f 
join gdb041.dim_product p on f.product_code = p.product_code 
join gdb041.fact_gross_price g on g.product_code = f.product_code and g.fiscal_year = get_fiscal_year(f.date)  
WHERE customer_code=90002002 AND get_fiscal_year(f.date)=2021;

# Generate Total Gross sales  amount to Croma in this month
SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
select f.date,sum(g.gross_price*sold_quantity) as total_gross_price from 
fact_sales_monthly f join fact_gross_price g on f.product_code = g.product_code and 
g.fiscal_year = get_fiscal_year(f.date)
where customer_code = '90002002' 
group by f.date
order by f.date asc


-- Exercise: Yearly Sales Report
-- Generate a yearly report for Croma India where there are two columns

-- 1. Fiscal Year
-- 2. Total Gross Sales amount In that year from Croma

select g.fiscal_year, sum(gross_price*sold_quantity) as yearly_gross_sales from fact_sales_monthly f join fact_gross_price g 
on f.product_code = g.product_code and g.fiscal_year = get_fiscal_year(f.date)
where customer_code = '90002002'
group by fiscal_year

# I did almost everything correct but I was getting an error in group by since I must use an aggregated column like "SUM"

-- Stored Procedures: Monthly Gross Sales Report
# Now my manager might ask me to make the same report for different customer e.g(Amazon, Ebay, etc) but this is really repetative
# so I use something called stored procedures
-- Right-click on the stored procedure on the left panel


-- Stored Procedure: Market Badge
-- Create a stored proc that can determine the market badge based on the following logic,
-- If total sold quantity > 5 million that market is considered Gold else it is Silver
-- My input will be,
-- • market
-- • fiscal year
-- Output
-- • market badge

-- Instance --
# India, 2021 -- GOLD
select market,sum(sold_quantity) as total_quantity from fact_sales_monthly f join dim_customer d on f.customer_code = d.customer_code
where get_fiscal_year(f.date) = 2021 and  market = 'South Korea'
group by market

# Nect step: Create a stored procedure out of it