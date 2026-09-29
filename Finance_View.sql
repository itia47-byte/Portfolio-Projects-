SELECT
    d.FullDateAlternateKey  AS [Date],
    dg.DepartmentGroupName  AS Department,
    a.AccountDescription    AS Account,
    a.AccountType,
    s.ScenarioName          AS Scenario,
    f.Amount
FROM dbo.FactFinance f
JOIN dbo.DimDate d             ON f.DateKey = d.DateKey
JOIN dbo.DimDepartmentGroup dg ON f.DepartmentGroupKey = dg.DepartmentGroupKey
JOIN dbo.DimAccount a          ON f.AccountKey = a.AccountKey
JOIN dbo.DimScenario s         ON f.ScenarioKey = s.ScenarioKey
WHERE s.ScenarioName IN ('Actual', 'Budget')
  AND a.AccountType IN ('Revenue', 'Expenditures');
