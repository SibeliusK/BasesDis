use AdventureWorks2022;

--Consultas Originales
 
-- 1
SELECT p.Name AS Producto, sod.OrderQty, soh.OrderDate, c.Name AS Cliente
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
WHERE YEAR(soh.OrderDate) = 2014 AND p.ListPrice > 1000;
 
-- 2
SELECT e.NationalIDNumber, p.FirstName, p.LastName, edh.DepartmentID,
       (SELECT AVG(rh.Rate) FROM HumanResources.EmployeePayHistory rh 
        WHERE rh.BusinessEntityID = e.BusinessEntityID) as PromedioSalario
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
WHERE edh.EndDate IS NULL;
 
-- 3
SELECT sod.SalesOrderID, p.ProductID, p.Name
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
WHERE psc.ProductCategoryID = 1 OR psc.ProductCategoryID = 2 OR psc.ProductCategoryID = 3 OR p.ListPrice > 500;
 
-- 4
SELECT YEAR(soh.OrderDate) AS Año, MONTH(soh.OrderDate) AS Mes,
       COUNT(*) AS TotalPedidos, SUM(sod.LineTotal) AS TotalVentas
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate);
 
-- 5
SELECT p.ProductID, p.Name, pc.Name AS Categoria
FROM Production.Product p
JOIN Production.ProductSubcategory pc ON p.ProductSubcategoryID = pc.ProductSubcategoryID
WHERE p.Name LIKE '%brake%' OR pc.Name LIKE '%road%';
 
-- 6
SELECT c.CustomerID, c.Name, COUNT(*) AS TotalPedidos
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
WHERE UPPER(c.Name) LIKE 'A%'
GROUP BY c.CustomerID, c.Name;
 
-- 7
SELECT TOP 100 sod.SalesOrderDetailID, sod.OrderQty, sod.UnitPrice, soh.OrderDate
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
ORDER BY soh.ShipDate DESC, sod.OrderQty DESC, sod.UnitPrice DESC;
 
-- 8
SELECT p.ProductID, p.Name, SUM(sod.OrderQty) AS TotalVendido
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod 
    ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh 
    ON sod.SalesOrderID = soh.SalesOrderID
WHERE soh.OrderDate >= '2014-01-01'
GROUP BY p.ProductID, p.Name
HAVING SUM(sod.OrderQty) > 100;

-- 9
SELECT p.ProductID, p.Name,
       (SELECT COUNT(*) FROM Sales.SalesOrderDetail sod WHERE sod.ProductID = p.ProductID) AS VecesVendido,
       (SELECT SUM(sod.OrderQty * sod.UnitPrice) FROM Sales.SalesOrderDetail sod WHERE sod.ProductID = p.ProductID) AS Ingresos
FROM Production.Product p
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
WHERE psc.ProductCategoryID = 3;
 
-- 10
SELECT c.Name AS Cliente, p.Name AS Producto, 
       SUM(sod.OrderQty) AS Cantidad, SUM(sod.LineTotal) AS Total,
       DATEDIFF(day, soh.OrderDate, soh.ShipDate) AS DiasEnvio
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE DATEDIFF(day, soh.OrderDate, soh.ShipDate) > 5
  AND DATEPART(quarter, soh.OrderDate) = 2
  AND sod.LineTotal > 1000
GROUP BY c.Name, p.Name, soh.OrderDate, soh.ShipDate
ORDER BY Total DESC;

--Optimizacion de consultas

CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

set statistics io on;
set statistics time on;

--1
CREATE NONCLUSTERED INDEX IX_SalesOrderHeader_OrderDate
ON Sales.SalesOrderHeader (OrderDate)
INCLUDE (CustomerID);

SELECT 
    p.Name AS Producto, 
    sod.OrderQty, 
    soh.OrderDate, 
    COALESCE(pe.FirstName + ' ' + pe.LastName, s.Name) AS Cliente
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod 
    ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh 
    ON sod.SalesOrderID = soh.SalesOrderID
JOIN Sales.Customer c 
    ON soh.CustomerID = c.CustomerID
LEFT JOIN Person.Person pe 
    ON c.PersonID = pe.BusinessEntityID
LEFT JOIN Sales.Store s 
    ON c.StoreID = s.BusinessEntityID
WHERE 
    soh.OrderDate >= '20140101' 
    AND soh.OrderDate < '20150101'
    AND p.ListPrice > 1000;

--2
SELECT 
    e.NationalIDNumber, 
    p.FirstName, 
    p.LastName, 
    edh.DepartmentID,
    AVG(rh.Rate) AS PromedioSalario
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
LEFT JOIN HumanResources.EmployeePayHistory rh ON e.BusinessEntityID = rh.BusinessEntityID
WHERE edh.EndDate IS NULL
GROUP BY 
    e.NationalIDNumber, 
    p.FirstName, 
    p.LastName, 
    edh.DepartmentID;

SELECT sod.SalesOrderID, p.ProductID, p.Name
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE p.CategoryID = 1 OR p.CategoryID = 2 OR p.CategoryID = 3 OR p.ListPrice > 500;

--3
CREATE NONCLUSTERED INDEX IX_Product_Category_Price 
ON Production.Product(ProductSubcategoryID, ListPrice) 
INCLUDE (Name);

SELECT 
    sod.SalesOrderID, 
    p.ProductID, 
    p.Name
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
WHERE psc.ProductCategoryID IN (1, 2, 3) 
   OR p.ListPrice > 500;

--4
CREATE NONCLUSTERED INDEX IX_SalesOrderDetail_SalesOrderID_LineTotal 
ON Sales.SalesOrderDetail(SalesOrderID) 
INCLUDE (LineTotal);

CREATE NONCLUSTERED INDEX IX_SalesOrderHeader_OrderDate 
ON Sales.SalesOrderHeader(OrderDate);

SELECT YEAR(soh.OrderDate) AS Año, MONTH(soh.OrderDate) AS Mes,
       COUNT(*) AS TotalPedidos, SUM(sod.LineTotal) AS TotalVentas
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate);

--6
SELECT 
    c.CustomerID, 
    COALESCE(pe.FirstName + ' ' + pe.LastName, s.Name) AS Cliente,
    COUNT(*) AS TotalPedidos
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID
LEFT JOIN Person.Person pe 
    ON c.PersonID = pe.BusinessEntityID
LEFT JOIN Sales.Store s 
    ON c.StoreID = s.BusinessEntityID
WHERE 
    (pe.FirstName + ' ' + pe.LastName LIKE 'A%' OR s.Name LIKE 'A%')
GROUP BY 
    c.CustomerID, 
    COALESCE(pe.FirstName + ' ' + pe.LastName, s.Name);

--7
CREATE NONCLUSTERED INDEX IX_ShipDate_Order
ON Sales.SalesOrderHeader (ShipDate DESC)
INCLUDE (SalesOrderID, OrderDate);

CREATE NONCLUSTERED INDEX IX_SalesOrderDetail_Order
ON Sales.SalesOrderDetail (SalesOrderID, OrderQty DESC, UnitPrice DESC)
INCLUDE (SalesOrderDetailID);

SELECT TOP 100 sod.SalesOrderDetailID, sod.OrderQty, sod.UnitPrice, soh.OrderDate
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
ORDER BY soh.ShipDate DESC, sod.OrderQty DESC, sod.UnitPrice DESC;

--8
CREATE NONCLUSTERED INDEX IX_SOD_Product
ON Sales.SalesOrderDetail (ProductID)
INCLUDE (OrderQty);

CREATE NONCLUSTERED INDEX IX_SOH_OrderDate
ON Sales.SalesOrderHeader (OrderDate)
INCLUDE (SalesOrderID);

SELECT p.ProductID, p.Name, SUM(sod.OrderQty) AS TotalVendido
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE soh.OrderDate >= '2014-01-01'
GROUP BY p.ProductID, p.Name
HAVING SUM(sod.OrderQty) > 100;

--9
CREATE NONCLUSTERED INDEX IX_SOD_Product_Aggregate
ON Sales.SalesOrderDetail (ProductID)
INCLUDE (OrderQty, UnitPrice, SalesOrderDetailID);

SELECT p.ProductID, p.Name,
       COUNT(sod.SalesOrderDetailID) AS VecesVendido,
       SUM(sod.OrderQty * sod.UnitPrice) AS Ingresos
FROM Production.Product p
JOIN Production.ProductSubcategory psc 
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Sales.SalesOrderDetail sod 
    ON p.ProductID = sod.ProductID
WHERE psc.ProductCategoryID = 3
GROUP BY p.ProductID, p.Name;

--10
CREATE NONCLUSTERED INDEX IX_SalesOrderDetail_Optimizado
ON Sales.SalesOrderDetail (LineTotal)
INCLUDE (OrderQty, ProductID, SalesOrderID);

SELECT 
    COALESCE(pe.FirstName + ' ' + pe.LastName, s.Name) AS Cliente, 
    p.Name AS Producto, 
    SUM(sod.OrderQty) AS Cantidad, 
    SUM(sod.LineTotal) AS Total,
    DATEDIFF(day, soh.OrderDate, soh.ShipDate) AS DiasEnvio
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c 
    ON soh.CustomerID = c.CustomerID
JOIN Sales.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
LEFT JOIN Person.Person pe 
    ON c.PersonID = pe.BusinessEntityID
LEFT JOIN Sales.Store s 
    ON c.StoreID = s.BusinessEntityID
WHERE 
    soh.ShipDate > DATEADD(day, 5, soh.OrderDate)
    AND soh.OrderDate >= '20140101' 
    AND soh.OrderDate < '20140701'
    AND sod.LineTotal > 1000
GROUP BY 
    c.CustomerID,
    p.ProductID,
    COALESCE(pe.FirstName + ' ' + pe.LastName, s.Name), 
    p.Name, 
    soh.OrderDate, 
    soh.ShipDate
ORDER BY Total DESC;