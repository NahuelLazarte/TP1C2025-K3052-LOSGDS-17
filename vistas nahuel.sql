USE GD1C2025

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
	costo_envios DECIMAL(18,2),
	cumplidos_en_fecha INT,
	total INT,
	CONSTRAINT PK_HechosEnvios PRIMARY KEY (id_tiempo, id_ubicacion),
	CONSTRAINT FK_HechosEnvios_Tiempo FOREIGN KEY (id_tiempo) REFERENCES LOSGDS.BI_Dim_Tiempo(id_tiempo),
	CONSTRAINT FK_HechosEnvios_Ubicacion FOREIGN KEY (id_ubicacion) REFERENCES LOSGDS.BI_Dim_Ubicacion(id_ubicacion)
)


CREATE PROCEDURE LOSGDS.MigrarDimTiempo
AS
BEGIN

    INSERT INTO LOSGDS.BI_Dim_Tiempo (anio,mes,cuatrimestre)
    SELECT DISTINCT 
        YEAR(p.fecha),
        MONTH(p.fecha),
		CASE 
            WHEN MONTH(p.fecha) BETWEEN 1 AND 4 THEN 'Primer Cuatrimestre'
            WHEN MONTH(p.fecha) BETWEEN 5 AND 8 THEN 'Segundo Cuatrimestre'
			else 'Tercer Cuatrimestre'
        END
    FROM  LOSGDS.Pedido p
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
    FROM  LOSGDS.Pedido p
	INNER JOIN LOSGDS.Cliente c
	ON c.id_cliente = p.pedido_cliente
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
BEGIN TRANSACTION
	EXEC LOSGDS.MigrarDimTiempo
COMMIT TRANSACTION

BEGIN TRANSACTION
	EXEC LOSGDS.MigrarDimUbicacion
COMMIT TRANSACTION