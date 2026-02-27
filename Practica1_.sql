use AdventureWorks2022
/* drop database AdventureWorks2022
tablas a utilizar: sales.salesOrderHeader, Sales.SalesOrderDetail, Production.Product,
HumanResources.Employee, Person.Person, sales.salesterritory */

go
select revisionnumber,Status,customerID from AdventureWorks2022.sales.SalesOrderHeader as soh
join sales.salesorderdetail sod
on soh.salesOrderID = sod.SalesOrderID



-- sales.salesorderdetail tiene el campo SalesOrderID 
-- sales.salesorderheader tiene el campo SalesOrderID



SELECT  AVG(ListPrice) as PromedioPrecio FROM AdventureWorks2022.Production.Product 


--Ejemplos en clase
go  
select name, cant
from Production.product p
join (select top 10 productid, sum(orderqty) cant
              from sales.SalesOrderDetail sod
			  group by productid
              order by cant desc) as T
on p.ProductID = t.ProductID


go 
select soh.SalesOrderID, sod.ProductID, sod.OrderQty, soh.CustomerID
from sales.SalesOrderHeader soh join sales.SalesOrderDetail sod
on soh.SalesOrderID = sod.SalesOrderID
where year(OrderDate) = '2014'

/* ############## Ejercicio 1 ##############*/
--10 productos más vendidos en 2014, mostrando nombre del producto,
--cantidad total vendida

-- OrderDate esta en Sales.SalesOrderHeader
go
select name, cant
from Production.product p
join (select top 10 productid, sum(orderqty) as cant
              from sales.SalesOrderDetail sod
              join Sales.SalesOrderHeader soh
              on sod.SalesOrderID = soh.SalesOrderID
              WHERE year(OrderDate) ='2014'
			  group by productid
              order by cant desc) as T
on p.ProductID = t.ProductID

--Agregando precio unitario promedio (AVG(UnitPrice)) 
-- y filtrando solo productos con ListPrice > 1000:
-- ListPrice en Production.product

go
select name, cant, PrecioPromedio
from Production.product p
join (select top 10 sod.productid, sum(orderqty) as cant,
              avg(sod.UnitPrice) as PrecioPromedio
              from sales.SalesOrderDetail sod
              join Sales.SalesOrderHeader soh
              on sod.SalesOrderID = soh.SalesOrderID
              join Production.product p2
              on sod.ProductID = p2.ProductID
              WHERE year(OrderDate) ='2014'
              and p2.ListPrice > 1000
			  group by sod.productid
              order by cant desc) as T
on p.ProductID = t.ProductID


/*########### Ejercicio 2 ############# */

--Listar empleados que han vendido más que el promedio de ventas por empleado en
--el territorio 'Northwest'.
--El territorio esta en sales.salesTerritory 

--obtener ventas totales, promediar y mostrar a vendedores mayores a eso en el territorio de Northwest

go
select *
from AdventureWorks2022.person.person

-- **** Promedio general de ventas de los empleados en Northwest
-- INNER JOIN devuelve únicamente los registros que tienen coincidencia en ambas tablas.

SELECT 
    AVG(soh.TotalDue) AS PromedioGeneralVentas
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory st 
    ON soh.TerritoryID = st.TerritoryID
WHERE st.Name = 'Northwest'
AND soh.SalesPersonID IS NOT NULL;
-- 26172.6823


/*sales.salesOrderHeader en salespersonID guarda qué vendedor hizo la orden 
& HumanResources.employee , BusinessEntityID  es la llave primaria del empleado*/


select p.FirstName + p.LastName as nombreEmpleado, sum(soh.TotalDue) as TotalDVentas
    from sales.SalesOrderHeader as soh
    join sales.SalesTerritory as st
    on soh.TerritoryID = st.TerritoryID
    join HumanResources.Employee as he
    on soh.SalesPersonID = he.BusinessEntityID 
    join person.person as p
    on he.BusinessEntityID = p.BusinessEntityID
    where st.name ='Northwest'
    group by
        p.FirstName, p.LastName
    Having sum(soh.TotalDue) > (        -- condicion de ventas en northwest 
        select avg (TotalDVentas)
        from(
            select sum (soh2.TotalDue) as TotalDVentas 
            from sales.SalesOrderHeader as soh2
            join sales.salesterritory as st2
            on soh2.TerritoryID = st2.TerritoryID
            where st2.name = 'Northwest'
            and soh2.SalesPersonID is not null
            group by soh2.SalesPersonID
        ) as PromedioVentas 
    )
order by TotalDVentas desc;


-- opcion con CTE (Common table expresion) WITH

WITH VentasPorEmpleado AS (
    SELECT 
        soh.SalesPersonID,
        SUM(soh.TotalDue) AS TotalVentas
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesTerritory st
        ON soh.TerritoryID = st.TerritoryID
    WHERE st.Name = 'Northwest'
      AND soh.SalesPersonID IS NOT NULL
    GROUP BY soh.SalesPersonID
)

SELECT 
    p.FirstName + p.LastName AS NombreEmpleado,
    v.TotalVentas
FROM VentasPorEmpleado v
JOIN HumanResources.Employee e
    ON v.SalesPersonID = e.BusinessEntityID
JOIN Person.Person p
    ON e.BusinessEntityID = p.BusinessEntityID
WHERE v.TotalVentas > (
        SELECT AVG(TotalVentas)
        FROM VentasPorEmpleado
)
ORDER BY v.TotalVentas DESC;



/*########## Ejercicio 3 ############# */
--Calcula ventas totales por territorio y año, mostrando solo aquellos con más de 5 órdenes
--y ventas > $1,000,000, ordenado por ventas descendente.

--Después agregar desviación estandar de ventas 





SELECT 
    st.Name AS Territorio,
    YEAR(soh.OrderDate) AS Anio,
    COUNT(soh.SalesOrderID) AS NumeroOrdenes,
    SUM(soh.TotalDue) AS VentasTotales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY 
    st.Name,
    YEAR(soh.OrderDate)
HAVING 
    COUNT(soh.SalesOrderID) > 5
    AND SUM(soh.TotalDue) > 1000000
ORDER BY 
    VentasTotales DESC;


-- **** Agregando desviacion estandar 


SELECT 
    st.Name AS Territorio,
    YEAR(soh.OrderDate) AS Anio,
    COUNT(soh.SalesOrderID) AS NumeroOrdenes,
    SUM(soh.TotalDue) AS VentasTotales,
    STDEV(soh.TotalDue) AS DesviacionEstandarVentas
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY 
    st.Name,
    YEAR(soh.OrderDate)
HAVING 
    COUNT(soh.SalesOrderID) > 5
    AND SUM(soh.TotalDue) > 1000000
ORDER BY 
    VentasTotales DESC;




/*########## Ejercicio 4 ############# */
-- Buscar vendedores que han vendido todos los productos de la categoria "Bikes"
-- Cambia a categoría "Clothing" (ID=4).
-- Contar cuántos productos por categoría maneja cada vendedor



SELECT 
    p.FirstName + ' ' + p.LastName AS NombreVendedor
FROM HumanResources.Employee e
JOIN Person.Person p
    ON e.BusinessEntityID = p.BusinessEntityID
WHERE NOT EXISTS (

    -- Productos Bikes que NO ha vendido este vendedor
    SELECT pr.ProductID
    FROM Production.Product pr
    JOIN Production.ProductSubcategory ps
        ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE pc.Name = 'Bikes'
      AND NOT EXISTS (
            SELECT 1
            FROM Sales.SalesOrderDetail sod
            JOIN Sales.SalesOrderHeader soh
                ON sod.SalesOrderID = soh.SalesOrderID
            WHERE soh.SalesPersonID = e.BusinessEntityID
              AND sod.ProductID = pr.ProductID
      )
)
ORDER BY NombreVendedor;


--**** Cambiando a clothing


SELECT 
    p.FirstName + ' ' + p.LastName AS NombreVendedor
FROM HumanResources.Employee e
JOIN Person.Person p
    ON e.BusinessEntityID = p.BusinessEntityID
WHERE NOT EXISTS (

    -- Productos de la categoría Clothing que NO ha vendido este vendedor
    SELECT pr.ProductID
    FROM Production.Product pr
    JOIN Production.ProductSubcategory ps
        ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
    WHERE ps.ProductCategoryID = 4
      AND NOT EXISTS (
            SELECT 1
            FROM Sales.SalesOrderDetail sod
            JOIN Sales.SalesOrderHeader soh
                ON sod.SalesOrderID = soh.SalesOrderID
            WHERE soh.SalesPersonID = e.BusinessEntityID
              AND sod.ProductID = pr.ProductID
      )
)
ORDER BY NombreVendedor;





/*######### Ejercicio 5 ############## */

select top 1
    p.productID,
    p.name as producto,
    p.ProductNumber,
    sum(sod.OrderQty * sod.UnitPrice) as ValorTotal
from SV_SELF.AdventureWorks2022.Production.product p
inner join Sales.SalesOrderDetail sod on p.ProductID = sod.ProductID
group by p.ProductID, p.Name, p.ProductNumber
order by sum(sod.OrderQty * sod.UnitPrice) desc;







