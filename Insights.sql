--Top 5 accounts that generated most revenue

SELECT TOP 5 account, SUM(close_value) AS TotalRevenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY account
ORDER BY TotalRevenue DESC;

--Top 5 agents that generated most revenue

SELECT TOP 5 sales_agent, SUM(close_value) AS TotalRevenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY sales_agent
ORDER BY TotalRevenue DESC;

--Best selling series of products

SELECT TOP 3 p.series, SUM(sp.close_value) AS TotalRevenue
FROM sales_pipeline sp
JOIN products p ON sp.product = p.product
WHERE sp.deal_stage = 'Won'
GROUP BY p.series
ORDER BY TotalRevenue DESC;


--Top 5 best selling products

SELECT TOP 5 product, SUM(close_value) AS TotalRevenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY TotalRevenue DESC;

--Most commonly sold products

SELECT TOP 5 product, COUNT(product) AS ProductCount
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY ProductCount DESC;

--Products where most deals were lost

SELECT TOP 5 product, COUNT(*) AS DealsLost
FROM sales_pipeline
WHERE deal_stage = 'Lost'
GROUP BY product
ORDER BY DealsLost DESC;

--Agents who lost most deals

SELECT TOP 5 sales_agent, COUNT(*) AS DealsLost
FROM sales_pipeline
WHERE deal_stage = 'Lost'
GROUP BY sales_agent
ORDER BY DealsLost DESC;

--Accounts with the most deals won

SELECT TOP 5 account, COUNT(*) AS WonDeals
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY account
ORDER BY WonDeals DESC;

--Accounts with most deals lost

SELECT TOP 5 account, COUNT(*) AS LostDeals
FROM sales_pipeline
WHERE deal_stage = 'Lost'
GROUP BY account
ORDER BY LostDeals DESC;

--Managers responsible for most revenue

SELECT TOP 3 st.manager, SUM(sp.close_value) AS TotalRevenue
FROM sales_pipeline sp
JOIN sales_teams st ON sp.sales_agent = st.sales_agent
WHERE sp.deal_stage = 'Won'
GROUP BY st.manager
ORDER BY TotalRevenue DESC;

--Sectors generating most revenue

SELECT TOP 3 a.sector, SUM(sp.close_value) AS TotalRevenue
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
WHERE sp.deal_stage = 'Won'
GROUP BY a.sector
ORDER BY TotalRevenue DESC;

--Top 5 countries where most revenue is coming from

SELECT TOP 5 a.office_location, SUM(sp.close_value) AS TotalRevenue
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
WHERE sp.deal_stage = 'Won'
GROUP BY a.office_location
ORDER BY TotalRevenue DESC;

--Regional office revenue and best performing agent in the office

WITH OfficeRevenue AS (
    SELECT st.regional_office, st.sales_agent, SUM(sp.close_value) AS Revenue
    FROM sales_pipeline sp
    JOIN sales_teams st ON sp.sales_agent = st.sales_agent
    WHERE sp.deal_stage = 'Won'
    GROUP BY st.regional_office, st.sales_agent
),
RankedAgents AS (
    SELECT regional_office, sales_agent, Revenue,
    ROW_NUMBER() OVER (PARTITION BY regional_office ORDER BY Revenue DESC) AS rn
    FROM OfficeRevenue
)
SELECT regional_office, SUM(Revenue) AS TotalOfficeRevenue,
MAX(CASE WHEN rn = 1 THEN sales_agent ELSE NULL END) AS TopAgent,
MAX(CASE WHEN rn = 1 THEN Revenue ELSE NULL END) AS TopAgentRevenue
FROM RankedAgents
GROUP BY regional_office;

--Conversion Rates of sales agents

 WITH AgentDeals AS (
    SELECT 
        sales_agent,
        SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS DealsWon,
        COUNT(*) AS TotalDeals
    FROM 
        sales_pipeline
    GROUP BY 
        sales_agent
)
SELECT 
    sales_agent,
    DealsWon,
    TotalDeals,
    CAST(DealsWon AS FLOAT) / TotalDeals AS ConversionRate
FROM 
    AgentDeals
ORDER BY 
    ConversionRate DESC, DealsWon DESC;

--Agents with the best revenue in the retail sector

SELECT TOP 5 sp.sales_agent, SUM(sp.close_value) AS TotalRevenue
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
WHERE a.sector = 'retail' AND sp.deal_stage = 'Won'
GROUP BY sp.sales_agent
ORDER BY TotalRevenue DESC;

--Sector wise revenue generation

SELECT 
    a.sector, 
    a.account, 
    SUM(sp.close_value) AS TotalRevenue
FROM 
    accounts a
JOIN 
    sales_pipeline sp ON a.account = sp.account
WHERE 
    sp.deal_stage = 'Won'
GROUP BY 
    a.sector, a.account
ORDER BY 
    a.sector, TotalRevenue DESC;

--Most deals in retail sector from United States

SELECT TOP 1 a.account, COUNT(*) AS WonDeals
FROM accounts a
JOIN sales_pipeline sp ON a.account = sp.account
WHERE a.sector = 'Retail'
  AND a.office_location = 'United States'
  AND sp.deal_stage = 'Won'
GROUP BY a.account
ORDER BY WonDeals DESC;

--Best performing sales agent from each regional office

WITH AgentWins AS (
    SELECT 
        st.regional_office,
        st.sales_agent,
        COUNT(*) AS WonDeals
    FROM 
        sales_pipeline sp
    JOIN 
        sales_teams st ON sp.sales_agent = st.sales_agent
    WHERE 
        sp.deal_stage = 'Won'
    GROUP BY 
        st.regional_office, st.sales_agent
),
RankedAgents AS (
    SELECT 
        regional_office,
        sales_agent,
        WonDeals,
        ROW_NUMBER() OVER (PARTITION BY regional_office ORDER BY WonDeals DESC) AS Rank
    FROM 
        AgentWins
)
SELECT 
    regional_office,
    sales_agent,
    WonDeals
FROM 
    RankedAgents
WHERE 
    Rank = 1;


--Most deals closed by agent from each office location (Account)

WITH AgentWins AS (
    SELECT 
        a.office_location, -- Using office location as country from the accounts table
        sp.sales_agent,
        COUNT(*) AS WonDeals
    FROM 
        sales_pipeline sp
    JOIN 
        accounts a ON sp.account = a.account
    WHERE 
        sp.deal_stage = 'Won'
    GROUP BY 
        a.office_location, sp.sales_agent
),
RankedAgents AS (
    SELECT 
        office_location,
        sales_agent,
        WonDeals,
        ROW_NUMBER() OVER (PARTITION BY office_location ORDER BY WonDeals DESC) AS Rank
    FROM 
        AgentWins
)
SELECT 
    office_location, -- This represents the country
    sales_agent,
    WonDeals
FROM 
    RankedAgents
WHERE 
    Rank = 1;

--Best performing sales agent for every month

WITH MonthlyWins AS (
    SELECT 
        FORMAT(close_date, 'yyyy-MM') AS YearMonth, -- Groups by year and month
        sales_agent,
        COUNT(*) AS WonDeals
    FROM 
        sales_pipeline
    WHERE 
        deal_stage = 'Won'
    GROUP BY 
        FORMAT(close_date, 'yyyy-MM'), sales_agent
),
RankedAgents AS (
    SELECT 
        YearMonth,
        sales_agent,
        WonDeals,
        RANK() OVER (PARTITION BY YearMonth ORDER BY WonDeals DESC) AS Rank
    FROM 
        MonthlyWins
)
SELECT 
    YearMonth,
    sales_agent,
    WonDeals
FROM 
    RankedAgents
WHERE 
    Rank = 1
ORDER BY 
    YearMonth;

--List of deals won monthly

SELECT 
    FORMAT(close_date, 'yyyy-MM') AS YearMonth, -- Groups by year and month
    COUNT(*) AS WonDeals
FROM 
    sales_pipeline
WHERE 
    deal_stage = 'Won'
GROUP BY 
    FORMAT(close_date, 'yyyy-MM')
ORDER BY 
    WonDeals DESC;


SELECT 
    YearMonth,
    product,
    MaxSales AS TotalSales
FROM (
    SELECT 
        FORMAT(close_date, 'yyyy-MM') AS YearMonth,
        product,
        SUM(close_value) AS Sales,
        MAX(SUM(close_value)) OVER (PARTITION BY FORMAT(close_date, 'yyyy-MM')) AS MaxSales
    FROM 
        sales_pipeline
    WHERE 
        deal_stage = 'Won'
    GROUP BY 
        FORMAT(close_date, 'yyyy-MM'), product
) AS MonthlySales
WHERE 
    Sales = MaxSales
ORDER BY 
    YearMonth;








