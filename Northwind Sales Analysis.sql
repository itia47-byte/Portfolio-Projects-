
SELECT
    YEAR(o.OrderDate)  AS OrderYear,
    MONTH(o.OrderDate) AS OrderMonth,
    CAST(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS DECIMAL(12,2)) AS Revenue
FROM Orders o
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY OrderYear, OrderMonth;
GO

SELECT TOP 10
    c.CustomerID,
    c.CompanyName,
    c.Country,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    CAST(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS DECIMAL(12,2)) AS Revenue
FROM Customers c
JOIN Orders o          ON c.CustomerID = o.CustomerID
JOIN [Order Details] od ON o.OrderID   = od.OrderID
GROUP BY c.CustomerID, c.CompanyName, c.Country
ORDER BY Revenue DESC;
GO

WITH ProductRevenue AS (
    SELECT
        cat.CategoryName,
        p.ProductName,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
    FROM [Order Details] od
    JOIN Products p     ON od.ProductID  = p.ProductID
    JOIN Categories cat ON p.CategoryID  = cat.CategoryID
    GROUP BY cat.CategoryName, p.ProductName
),
RankedProducts AS (
    SELECT
        CategoryName,
        ProductName,
        Revenue,
        RANK() OVER (PARTITION BY CategoryName ORDER BY Revenue DESC) AS RevenueRank
    FROM ProductRevenue
)
SELECT
    CategoryName,
    RevenueRank,
    ProductName,
    CAST(Revenue AS DECIMAL(12,2)) AS Revenue
FROM RankedProducts
WHERE RevenueRank <= 5
ORDER BY CategoryName, RevenueRank;
GO

WITH MonthlyRevenue AS (
    SELECT
        DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1) AS MonthStart,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount))     AS Revenue
    FROM Orders o
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)
)
SELECT
    MonthStart,
    CAST(Revenue AS DECIMAL(12,2))                                   AS Revenue,
    CAST(LAG(Revenue) OVER (ORDER BY MonthStart) AS DECIMAL(12,2))   AS PrevMonthRevenue,
    CAST(
        (Revenue - LAG(Revenue) OVER (ORDER BY MonthStart)) * 100.0
        / NULLIF(LAG(Revenue) OVER (ORDER BY MonthStart), 0)
    AS DECIMAL(8,2))                                                 AS MoM_Growth_Pct
FROM MonthlyRevenue
ORDER BY MonthStart;
GO

WITH MonthlyRevenue AS (
    SELECT
        DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1) AS MonthStart,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount))     AS Revenue
    FROM Orders o
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)
)
SELECT
    MonthStart,
    CAST(Revenue AS DECIMAL(12,2)) AS Revenue,
    CAST(SUM(Revenue) OVER (ORDER BY MonthStart
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
         AS DECIMAL(12,2))         AS RunningTotal,
    CAST(SUM(Revenue) OVER (PARTITION BY YEAR(MonthStart) ORDER BY MonthStart
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
         AS DECIMAL(12,2))         AS YTD_Revenue
FROM MonthlyRevenue
ORDER BY MonthStart;
GO
WITH EmployeeSales AS (
    SELECT
        e.EmployeeID,
        e.FirstName + ' ' + e.LastName AS EmployeeName,
        e.Title,
        COUNT(DISTINCT o.OrderID)      AS TotalOrders,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
    FROM Employees e
    JOIN Orders o          ON e.EmployeeID = o.EmployeeID
    JOIN [Order Details] od ON o.OrderID   = od.OrderID
    GROUP BY e.EmployeeID, e.FirstName, e.LastName, e.Title
)
SELECT
    RANK() OVER (ORDER BY Revenue DESC) AS SalesRank,
    EmployeeName,
    Title,
    TotalOrders,
    CAST(Revenue AS DECIMAL(12,2))                AS Revenue,
    CAST(Revenue / TotalOrders AS DECIMAL(12,2))  AS AvgOrderValue,
    CAST(Revenue * 100.0 / SUM(Revenue) OVER () AS DECIMAL(5,2)) AS RevenueShare_Pct
FROM EmployeeSales
ORDER BY SalesRank;
GO

SELECT
    CASE
        WHEN ShippedDate IS NULL         THEN 'Not Shipped'
        WHEN ShippedDate > RequiredDate  THEN 'Late'
        ELSE 'On Time'
    END                                   AS ShipStatus,
    COUNT(*)                              AS TotalOrders,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS Pct_Of_Orders
FROM Orders
GROUP BY
    CASE
        WHEN ShippedDate IS NULL         THEN 'Not Shipped'
        WHEN ShippedDate > RequiredDate  THEN 'Late'
        ELSE 'On Time'
    END
ORDER BY TotalOrders DESC;
GO
 
-- 7b. Late rate and average days late by shipper
SELECT
    s.CompanyName AS Shipper,
    COUNT(*)      AS ShippedOrders,
    SUM(CASE WHEN o.ShippedDate > o.RequiredDate THEN 1 ELSE 0 END) AS LateOrders,
    CAST(SUM(CASE WHEN o.ShippedDate > o.RequiredDate THEN 1 ELSE 0 END) * 100.0
         / COUNT(*) AS DECIMAL(5,2)) AS Late_Pct,
    AVG(CASE WHEN o.ShippedDate > o.RequiredDate
             THEN DATEDIFF(DAY, o.RequiredDate, o.ShippedDate) END) AS AvgDaysLate
FROM Orders o
JOIN Shippers s ON o.ShipVia = s.ShipperID
WHERE o.ShippedDate IS NOT NULL
GROUP BY s.CompanyName
ORDER BY Late_Pct DESC;
GO

WITH OrderTotals AS (
    SELECT
        o.OrderID,
        o.CustomerID,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS OrderTotal
    FROM Orders o
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY o.OrderID, o.CustomerID
)
SELECT
    c.Country,
    COUNT(ot.OrderID)                          AS TotalOrders,
    CAST(SUM(ot.OrderTotal) AS DECIMAL(12,2))  AS TotalRevenue,
    CAST(AVG(ot.OrderTotal) AS DECIMAL(12,2))  AS AvgOrderValue
FROM OrderTotals ot
JOIN Customers c ON ot.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY AvgOrderValue DESC;
GO

WITH RefDate AS (
    SELECT DATEADD(MONTH, -6, MAX(OrderDate)) AS CutoffDate
    FROM Orders
),
LastOrder AS (
    SELECT
        c.CustomerID,
        c.CompanyName,
        c.Country,
        MAX(o.OrderDate) AS LastOrderDate
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CompanyName, c.Country
)
SELECT
    lo.CustomerID,
    lo.CompanyName,
    lo.Country,
    lo.LastOrderDate,
    CASE WHEN lo.LastOrderDate IS NULL THEN 'Never Ordered'
         ELSE 'Inactive 6+ Months' END AS CustomerStatus
FROM LastOrder lo
CROSS JOIN RefDate r
WHERE lo.LastOrderDate IS NULL
   OR lo.LastOrderDate < r.CutoffDate
ORDER BY lo.LastOrderDate;
GO

WITH CategoryRevenue AS (
    SELECT
        cat.CategoryName,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
    FROM [Order Details] od
    JOIN Products p     ON od.ProductID = p.ProductID
    JOIN Categories cat ON p.CategoryID = cat.CategoryID
    GROUP BY cat.CategoryName
)
SELECT
    CategoryName,
    CAST(Revenue AS DECIMAL(12,2)) AS Revenue,
    CAST(Revenue * 100.0 / SUM(Revenue) OVER () AS DECIMAL(5,2)) AS RevenueShare_Pct
FROM CategoryRevenue
ORDER BY Revenue DESC;
GO
