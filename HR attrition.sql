CREATE OR ALTER VIEW vw_employee_attrition AS
SELECT
EmployeeNumber, Age, Gender, MaritalStatus, Department, JobRole,
JobLevel,
MonthlyIncome, BusinessTravel, DistanceFromHome,
JobSatisfaction, EnvironmentSatisfaction, WorkLifeBalance,
YearsAtCompany, YearsSinceLastPromotion,
CASE WHEN CAST(Attrition AS VARCHAR(5)) IN ('1','Yes','True') THEN 'Yes' ELSE 'No' END AS Attrition,
CASE WHEN CAST(Attrition AS VARCHAR(5)) IN ('1','Yes','True') THEN 1 ELSE 0 END AS AttritionFlag,
CASE WHEN CAST(OverTime AS VARCHAR(5)) IN ('1','Yes','True') THEN 'Yes' ELSE 'No' END AS OverTime,
CASE WHEN Age < 30 THEN 'Under 30'
     WHEN Age < 40 THEN '30-39'
     WHEN Age < 50 THEN '40-49'
     ELSE '50+' END AS AgeGroup,
CASE WHEN MonthlyIncome < 3000 THEN 'Low (<3K)'
     WHEN MonthlyIncome < 7000 THEN 'Mid (3K-7K)'
     ELSE 'High (7K+)' END AS IncomeBand,
CASE WHEN YearsAtCompany < 2 THEN '0-1 yrs'
     WHEN YearsAtCompany < 5 THEN '2-4 yrs'
     WHEN YearsAtCompany < 10 THEN '5-9 yrs'
     ELSE '10+ yrs' END AS TenureGroup,
CASE JobSatisfaction WHEN 1 THEN 'Low' WHEN 2 THEN 'Medium'
     WHEN 3 THEN 'High' ELSE 'Very High' END AS JobSatisfactionLabel,
CASE WorkLifeBalance WHEN 1 THEN 'Bad' WHEN 2 THEN 'Good'
     WHEN 3 THEN 'Better' ELSE 'Best' END AS WorkLifeBalanceLabel
FROM employees;

SELECT Department,
COUNT(*) AS Employees,
SUM(AttritionFlag) AS Left_Company,
CAST(100.0 * SUM(AttritionFlag) / COUNT(*) AS DECIMAL(5,2)) AS 
AttritionRatePct
FROM vw_employee_attrition
GROUP BY Department
ORDER BY AttritionRatePct DESC;

WITH role_rates AS (
SELECT Department, JobRole,
COUNT(*) AS Employees,
CAST(100.0 * SUM(AttritionFlag) / COUNT(*) AS DECIMAL(5,2)) AS 
AttritionRatePct
FROM vw_employee_attrition
GROUP BY Department, JobRole
)
SELECT *,
RANK() OVER (PARTITION BY Department ORDER BY AttritionRatePct DESC) 
AS RiskRank
FROM role_rates;

SELECT JobRole,
AVG(CASE WHEN AttritionFlag = 1 THEN MonthlyIncome END) AS 
AvgIncome_Left,
AVG(CASE WHEN AttritionFlag = 0 THEN MonthlyIncome END) AS 
AvgIncome_Stayed
FROM vw_employee_attrition
GROUP BY JobRole
ORDER BY JobRole;

SELECT Department,
SUM(AttritionFlag) AS Left_Company,
SUM(CASE WHEN AttritionFlag = 1 THEN MonthlyIncome * 12 * 0.5 ELSE 0 
END) AS EstReplacementCost
FROM vw_employee_attrition
GROUP BY Department
ORDER BY EstReplacementCost DESC;