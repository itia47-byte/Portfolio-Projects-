CREATE VIEW vw_customer_churn AS
SELECT
CustomerId, CreditScore, Geography, Gender, Age, Tenure,
Balance, NumOfProducts, HasCrCard, IsActiveMember, EstimatedSalary, 
Exited,
CASE WHEN Age < 30 THEN '18-29'
WHEN Age < 40 THEN '30-39'
WHEN Age < 50 THEN '40-49'
WHEN Age < 60 THEN '50-59'
ELSE '60+' END AS AgeGroup,
CASE WHEN Balance = 0 THEN 'Zero Balance'
WHEN Balance < 100000 THEN 'Below 100K'
ELSE '100K+' END AS BalanceGroup,
CASE WHEN CreditScore < 580 THEN 'Poor'
WHEN CreditScore < 670 THEN 'Fair'
WHEN CreditScore < 740 THEN 'Good'
ELSE 'Excellent' END AS CreditBand,
CASE WHEN Exited = 1 THEN 'Churned' ELSE 'Retained' END AS ChurnStatus
FROM customers;



SELECT Geography,
COUNT(*) AS Customers,
SUM(Exited) AS Churned,
CAST(100.0 * SUM(Exited) / COUNT(*) AS DECIMAL(5,2)) AS ChurnRatePct
FROM vw_customer_churn
GROUP BY Geography
ORDER BY ChurnRatePct DESC;

WITH ranked AS (
SELECT CustomerId, Geography, Balance,
RANK() OVER (PARTITION BY Geography ORDER BY Balance DESC) AS 
BalanceRank
FROM vw_customer_churn
WHERE Exited = 1
)
SELECT * FROM ranked WHERE BalanceRank <= 5;

SELECT Geography, SUM(Balance) AS BalanceLost
FROM vw_customer_churn
WHERE Exited = 1
GROUP BY Geography;
