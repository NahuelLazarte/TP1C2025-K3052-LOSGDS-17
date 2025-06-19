USE GD1C2025

IF OBJECT_ID('LOSGDS.BI_Dim_Tiempo') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_Tiempo;
IF OBJECT_ID('LOSGDS.BI_Dim_Ubicacion') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_Ubicacion;
IF OBJECT_ID('LOSGDS.BI_Hechos_Envios') IS NOT NULL DROP TABLE LOSGDS.BI_Hechos_Envios;
--Nahuel
CREATE TABLE LOSGDS.BI_Dim_Tiempo(
	id_tiempo BIGINT IDENTITY PRIMARY KEY,
	anio INT,
	mes INT,
	cuatrimestre NVARCHAR(255)
)

--Nahuel
CREATE TABLE LOSGDS.BI_Dim_Ubicacion(
	id_ubicacion BIGINT IDENTITY PRIMARY KEY,
	id_localidad BIGINT,
	id_provincia BIGINT,
	nombre_localidad NVARCHAR(255),
	nombre_provincia NVARCHAR(255)
)

--Nahuel
CREATE TABLE LOSGDS.BI_Hechos_Envios(
	id_tiempo BIGINT,
	id_ubicacion BIGINT,
	costo_envio_promedio DECIMAL(18,2),
	cumplidos_en_fecha INT,
	cantidad_envios INT,
	CONSTRAINT PK_HechosEnvios PRIMARY KEY (id_tiempo, id_ubicacion),
	CONSTRAINT FK_HechosEnvios_Tiempo FOREIGN KEY (id_tiempo) REFERENCES LOSGDS.BI_Dim_Tiempo(id_tiempo),
	CONSTRAINT FK_HechosEnvios_Ubicacion FOREIGN KEY (id_ubicacion) REFERENCES LOSGDS.BI_Dim_Ubicacion(id_ubicacion)
)


CREATE PROCEDURE LOSGDS.MigrarDimTiempo
AS
BEGIN

    INSERT INTO LOSGDS.BI_Dim_Tiempo (anio,mes,cuatrimestre)
    SELECT DISTINCT 
        YEAR(e.fecha),
        MONTH(e.fecha),
		CASE 
            WHEN MONTH(e.fecha) BETWEEN 1 AND 4 THEN 'Primer Cuatrimestre'
            WHEN MONTH(e.fecha) BETWEEN 5 AND 8 THEN 'Segundo Cuatrimestre'
			else 'Tercer Cuatrimestre'
        END
    FROM  LOSGDS.Envio e
END
GO

CREATE PROCEDURE LOSGDS.MigrarDimUbicacion
AS
BEGIN

    INSERT INTO LOSGDS.BI_Dim_Ubicacion (id_localidad,id_provincia,nombre_localidad,nombre_provincia)
    SELECT DISTINCT 
    l.id_localidad,
	prov.id_provincia,
	l.nombre,
	prov.nombre
    FROM  LOSGDS.Envio e
	INNER JOIN LOSGDS.Factura f
	ON f.id_factura = e.envio_factura
	INNER JOIN LOSGDS.Cliente c
	ON c.id_cliente = f.fact_cliente
	INNER JOIN LOSGDS.Direccion d
	ON d.id_direccion = c.cliente_direccion
	INNER JOIN LOSGDS.Localidad l
	ON l.id_localidad = d.direccion_localidad
	INNER JOIN LOSGDS.Provincia prov
	ON prov.id_provincia = l.localidad_provincia
END
GO

--hay que ir al cliente y de ahí sacar la ubicación de ese cliente
--y de cliente ir a ubicacion


/*
son varios envios para una ubicación y un tiempo determinado. 
Pero deben tener el mismo costo. Para eso hay que ver la cantidad, 
cumplidos en fecha y calcular el costo promedio
*/


CREATE PROCEDURE LOSGDS.MigrarHechosEnvios
AS
BEGIN

    INSERT INTO LOSGDS.BI_Hechos_Envios (id_tiempo,id_ubicacion,costo_envio_promedio,cumplidos_en_fecha,cantidad_envios)
    SELECT  
	dt.id_tiempo, 
	du.id_ubicacion,
	AVG(e.total),
	SUM( CASE 
			WHEN e.fecha_programada = e.fecha THEN 1
			ELSE 0
		 END
	),
	COUNT(*) AS cantidad_envios
    FROM  LOSGDS.Envio e
	INNER JOIN LOSGDS.BI_Dim_Tiempo dt
	ON dt.anio = YEAR(e.fecha)
	AND dt.mes = MONTH(e.fecha)
	AND dt.cuatrimestre = 
		CASE 
            WHEN MONTH(e.fecha) BETWEEN 1 AND 4 THEN 'Primer Cuatrimestre'
            WHEN MONTH(e.fecha) BETWEEN 5 AND 8 THEN 'Segundo Cuatrimestre'
			else 'Tercer Cuatrimestre'
        END


	INNER JOIN LOSGDS.Factura f
	ON f.id_factura = e.envio_factura
	INNER JOIN LOSGDS.Cliente c
	ON c.id_cliente = f.fact_cliente
	INNER JOIN LOSGDS.Direccion d
	ON d.id_direccion = c.cliente_direccion
	INNER JOIN LOSGDS.Localidad l
	ON l.id_localidad = d.direccion_localidad
	INNER JOIN LOSGDS.Provincia prov
	ON prov.id_provincia = l.localidad_provincia
	INNER JOIN LOSGDS.BI_Dim_Ubicacion du
	ON du.id_localidad = l.id_localidad
	AND du.id_provincia = prov.id_provincia
	GROUP BY
	dt.id_tiempo, du.id_ubicacion
	ORDER BY cantidad_envios
END
GO


BEGIN TRANSACTION
	EXEC LOSGDS.MigrarDimTiempo
COMMIT TRANSACTION

BEGIN TRANSACTION
	EXEC LOSGDS.MigrarDimUbicacion
COMMIT TRANSACTION

BEGIN TRANSACTION
	EXEC LOSGDS.MigrarHechosEnvios
COMMIT TRANSACTION

DROP PROCEDURE LOSGDS.MigrarDimTiempo
DROP PROCEDURE LOSGDS.MigrarDimUbicacion
DROP PROCEDURE LOSGDS.MigrarHechosEnvios