/*

La Consulta a optimizar fue la solucion 1, generada por IA (chatgpt)
Argumentos:

1.-Problemas de optimización
Subconsulta innecesaria (T2)

T2 devuelve un solo valor.
No necesitas hacer un JOIN contra una tabla derivada.

Eso obliga al optimizador a materializar un conjunto intermedio.

2.-COUNT(DISTINCT) es costoso

COUNT(DISTINCT) obliga a:

Ordenar

Hacer hash aggregation

Si el volumen de datos es grande, se vuelve pesado.

3.- Filtros dentro de join 

se tiene esto:
and c.calif >= 6 
and i.numEmpleado = 'P0000001'


Eso funciona, pero semánticamente deberían ir en WHERE.
SQL Server puede optimizarlo igual, pero es mejor práctica separarlo.




*/


SELECT a.boleta
FROM Escuela.Alumno a
WHERE NOT EXISTS (
    SELECT 1
    FROM Escuela.Imparte i
    WHERE i.numEmpleado = 'P0000001'
    AND NOT EXISTS (
        SELECT 1
        FROM Escuela.Cursa c
        WHERE c.boleta = a.boleta
        AND c.clave = i.clave
        AND c.idGrupo = i.idGrupo
        AND c.Semestre = i.semestre
        AND c.calif >= 6
    )
);
