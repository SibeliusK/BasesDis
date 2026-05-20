/* Practica 3 */

/* Nieves Hernandez Efrain
   Rodríguez Escalera Ricardo
   Sánchez Lemus Ulises Mariano */

use covidHistorico2;
EXEC sp_help 'datoscovid';
EXEC sp_spaceused 'datoscovid';

select * from datoscovid;

/* Verificamos que no haya "datos sucios" en la columna */
SELECT FECHA_INGRESO FROM datoscovid WHERE TRY_CONVERT(date, FECHA_INGRESO) IS NULL;

/* Creamos una columna nueva para insertar los datos convertidos */
ALTER TABLE datoscovid ADD FechaIngresoDATE DATE;

/* Hacemos la conversion de datos por bloques */
WHILE 1 = 1
BEGIN
    UPDATE TOP (50000) datoscovid
    SET FechaIngresoDATE =
        TRY_CONVERT(date, FECHA_INGRESO)
    WHERE FechaIngresoDATE IS NULL;

    IF @@ROWCOUNT = 0
        BREAK;
END

/* Verificamos la conversion de datos */
SELECT TOP 100 FECHA_INGRESO, FechaIngresoDATE FROM datoscovid;

/* Creamos los filegroups para cada año*/
ALTER DATABASE covidHistorico2 ADD FILEGROUP FG_2020;

ALTER DATABASE covidHistorico2 ADD FILEGROUP FG_2021;

ALTER DATABASE covidHistorico2 ADD FILEGROUP FG_2022;

/* Agregamos los archivos fisicos */

/* Archivo 2020 */
ALTER DATABASE covidHistorico2
ADD FILE
(
    NAME = COVID_2020,
    FILENAME = 'C:\SQLData\COVID_2020.ndf',
    SIZE = 5MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP FG_2020;

/* Archivo 2021 */
ALTER DATABASE covidHistorico2
ADD FILE
(
    NAME = COVID_2021,
    FILENAME = 'C:\SQLData\COVID_2021.ndf',
    SIZE = 5MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP FG_2021;

/* Archivo 2022 */
ALTER DATABASE covidHistorico2
ADD FILE
(
    NAME = COVID_2022,
    FILENAME = 'C:\SQLData\COVID_2022.ndf',
    SIZE = 5MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP FG_2022;

/* Creamos la funcion de particion por rangos */
CREATE PARTITION FUNCTION PF_COVID_YEAR (DATE) AS RANGE RIGHT
FOR VALUES ('2021-01-01', '2022-01-01', '2023-01-01');

/* Creamos esquema de particion */
CREATE PARTITION SCHEME PS_COVID_YEAR
AS PARTITION PF_COVID_YEAR
TO (FG_2020, FG_2021, FG_2022, [PRIMARY]);

/* Creacion de tabla particionada*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[datoscovid_particionado]
(
	[FECHA_ACTUALIZACION] [nvarchar](15) NULL,
	[ID_REGISTRO] [varchar](15) NOT NULL,
	[ORIGEN] [int] NULL,
	[SECTOR] [int] NULL,
	[ENTIDAD_UM] [nvarchar](15) NULL,
	[SEXO] [int] NULL,
	[ENTIDAD_NAC] [nvarchar](15) NULL,
	[ENTIDAD_RES] [nvarchar](15) NULL,
	[MUNICIPIO_RES] [nvarchar](15) NULL,
	[TIPO_PACIENTE] [int] NULL,
	[FECHA_INGRESO] [nvarchar](15) NULL,
	[FECHA_SINTOMAS] [nvarchar](15) NULL,
	[FECHA_DEF] [nvarchar](15) NULL,
	[INTUBADO] [int] NULL,
	[NEUMONIA] [int] NULL,
	[EDAD] [nvarchar](7) NULL,
	[NACIONALIDAD] [int] NULL,
	[EMBARAZO] [int] NULL,
	[HABLA_LENGUA_INDIG] [int] NULL,
	[INDIGENA] [int] NULL,
	[DIABETES] [int] NULL,
	[EPOC] [int] NULL,
	[ASMA] [int] NULL,
	[INMUSUPR] [int] NULL,
	[HIPERTENSION] [int] NULL,
	[OTRA_COM] [int] NULL,
	[CARDIOVASCULAR] [int] NULL,
	[OBESIDAD] [int] NULL,
	[RENAL_CRONICA] [int] NULL,
	[TABAQUISMO] [int] NULL,
	[OTRO_CASO] [int] NULL,
	[TOMA_MUESTRA_LAB] [int] NULL,
	[RESULTADO_LAB] [int] NULL,
	[TOMA_MUESTRA_ANTIGENO] [int] NULL,
	[RESULTADO_ANTIGENO] [int] NULL,
	[CLASIFICACION_FINAL] [int] NULL,
	[MIGRANTE] [int] NULL,
	[PAIS_NACIONALIDAD] [nvarchar](50) NULL,
	[PAIS_ORIGEN] [nvarchar](50) NULL,
	[UCI] [nvarchar](50) NULL,

	[FechaIngresoDATE] [date] NOT NULL,

	CONSTRAINT [PK_ID_REGISTRO_PART] 
	PRIMARY KEY CLUSTERED
	(
		[ID_REGISTRO] ASC,
		[FechaIngresoDATE] ASC
	)
	WITH
	(
		PAD_INDEX = OFF,
		STATISTICS_NORECOMPUTE = OFF,
		IGNORE_DUP_KEY = OFF,
		ALLOW_ROW_LOCKS = ON,
		ALLOW_PAGE_LOCKS = ON,
		OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
	)
	ON PS_COVID_YEAR(FechaIngresoDATE)

)
ON PS_COVID_YEAR(FechaIngresoDATE);
GO

/* Insertar datos en la tabla particionada */

/* 2020 */
INSERT INTO datoscovid_particionado
SELECT *
FROM datoscovid
WHERE FechaIngresoDATE >= '2020-01-01'
AND FechaIngresoDATE < '2021-01-01';

/* 2021 */
INSERT INTO datoscovid_particionado
SELECT *
FROM datoscovid
WHERE FechaIngresoDATE >= '2021-01-01'
AND FechaIngresoDATE < '2022-01-01';

/* 2022 */
INSERT INTO datoscovid_particionado
SELECT *
FROM datoscovid
WHERE FechaIngresoDATE >= '2022-01-01'
AND FechaIngresoDATE < '2023-01-01';

/* Verificamos particiones */
SELECT
    $PARTITION.PF_COVID_YEAR(FechaIngresoDATE) AS Particion,
    COUNT(*) AS Registros
FROM datoscovid_particionado
GROUP BY $PARTITION.PF_COVID_YEAR(FechaIngresoDATE)
ORDER BY Particion;

/* Verificamos filegroups */
SELECT
    fg.name AS Filegroup,
    df.name AS Archivo,
    df.physical_name
FROM sys.filegroups fg
JOIN sys.database_files df
ON fg.data_space_id = df.data_space_id;

/* Verificamos que la tabla realmente está particionada */
SELECT
    t.name AS Tabla,
    i.name AS Indice,
    ps.name AS PartitionScheme
FROM sys.indexes i
JOIN sys.partition_schemes ps
    ON i.data_space_id = ps.data_space_id
JOIN sys.tables t
    ON i.object_id = t.object_id
WHERE t.name = 'datoscovid_particionado';

/* Consultas por año */

/* 2020 */
SELECT COUNT(*)
FROM datoscovid_particionado
WHERE FechaIngresoDATE >= '2020-01-01'
AND FechaIngresoDATE < '2021-01-01';

/* 2021 */
SELECT COUNT(*)
FROM datoscovid_particionado
WHERE FechaIngresoDATE >= '2021-01-01'
AND FechaIngresoDATE < '2022-01-01';

/* 2022 */
SELECT COUNT(*)
FROM datoscovid_particionado
WHERE FechaIngresoDATE >= '2022-01-01'
AND FechaIngresoDATE < '2023-01-01';