USE GD1C2025
GO


-- VISTAS
IF OBJECT_ID('LOSGDS.BI_Vista_ComprasPromedio') IS NOT NULL DROP VIEW LOSGDS.BI_Vista_ComprasPromedio;
IF OBJECT_ID('LOSGDS.BI_Vista_ComprasTotal') IS NOT NULL DROP VIEW LOSGDS.BI_Vista_ComprasTotal;
IF OBJECT_ID('HOBBITS11.BI_Vista_CostosEnvio') IS NOT NULL DROP VIEW HOBBITS11.BI_Vista_CostosEnvio;

-- TABLAS DE HECHOS
IF OBJECT_ID('LOSGDS.BI_Hechos_Compras') IS NOT NULL DROP TABLE LOSGDS.BI_Hechos_Compras;

-- DIMENSIONES
IF OBJECT_ID('LOSGDS.BI_Dim_Tiempo') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_Tiempo;
IF OBJECT_ID('LOSGDS.BI_Dim_Ubicacion') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_Ubicacion;
IF OBJECT_ID('LOSGDS.BI_Dim_RangoEtario') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_RangoEtario;
IF OBJECT_ID('LOSGDS.BI_Dim_TipoMaterial') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_TipoMaterial;
IF OBJECT_ID('LOSGDS.BI_Dim_Sucursal') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_Sucursal;

-- PROCEDIMIENTO
IF OBJECT_ID('LOSGDS.MigrarHechosCompras') IS NOT NULL DROP PROCEDURE LOSGDS.MigrarHechosCompras;
GO





--DIMENSIONES
--Creacion de las dimensiones
CREATE TABLE LOSGDS.BI_Dim_Tiempo (
    tiempo_id BIGINT IDENTITY PRIMARY KEY,
    anio INT NOT NULL,
	mes int NOT NULL,
    cuatrimestre NVARCHAR(255) NOT NULL,
)
GO

CREATE TABLE LOSGDS.BI_Dim_Ubicacion (
    ubicacion_id INT IDENTITY PRIMARY KEY,
	provincia_id INT NOT NULL,
	localidad_id INT NOT NULL,
	nombre_provincia NVARCHAR(255) NOT NULL,
	nombre_localidad NVARCHAR(255) NOT NULL
)
GO

CREATE TABLE LOSGDS.BI_Dim_RangoEtario (
    rango_id INT IDENTITY PRIMARY KEY,
    rango_etario_inicio INT,
    rango_etario_fin INT
)
GO


CREATE TABLE LOSGDS.BI_Dim_TipoMaterial (
    id_material BIGINT IDENTITY PRIMARY KEY,
    tipo_material NVARCHAR(50) NOT NULL
)
GO



CREATE TABLE LOSGDS.BI_Dim_Sucursal (
    id_sucursal BIGINT IDENTITY PRIMARY KEY,
    nro_sucursal BIGINT
)
GO


--- Creacion Tablas BI


CREATE TABLE LOSGDS.BI_Hechos_Compras (
    id_tiempo BIGINT NOT NULL,
	id_material BIGINT NOT NULL,
	id_sucursal BIGINT NOT NULL,
	importe_total DECIMAL(18,2) NOT NULL,
	cantidad_total INT NOT NULL,
	FOREIGN KEY (id_material) REFERENCES LOSGDS.BI_Dim_TipoMaterial(id_material),
    FOREIGN KEY (id_tiempo) REFERENCES LOSGDS.BI_Dim_Tiempo(tiempo_id),
	FOREIGN KEY (id_sucursal) REFERENCES LOSGDS.BI_Dim_Sucursal(id_sucursal),
	PRIMARY KEY(id_tiempo,id_material ,id_sucursal)
)
GO


---------- Migracion Dimensiones

-- Migracion BI_Dim_Tiempo
CREATE PROCEDURE LOSGDS.MigrarDimTiempo
AS
BEGIN

    INSERT INTO LOSGDS.BI_Dim_Tiempo
    SELECT DISTINCT 
        YEAR(fecha),
        CASE 
            WHEN MONTH(fecha) BETWEEN 1 AND 4 THEN 'Primer Cuatrimestre'
            WHEN MONTH(fecha) BETWEEN 5 AND 8 THEN 'Segundo Cuatrimestre'
			else 'Tercer Cuatrimestre'
        END,
        MONTH(fecha)
    FROM (
			SELECT fecha as fecha FROM LOSGDS.Compra
			UNION
			SELECT fecha FROM LOSGDS.Envio
			UNION
			SELECT fecha FROM LOSGDS.Pedido
			UNION
			SELECT fecha FROM LOSGDS.Factura
    ) AS fechas
END
GO


-- Migracion BI_Dim_Sucursal
CREATE PROCEDURE LOSGDS.MigrarDimSucursal
AS
BEGIN
    INSERT INTO LOSGDS.BI_Dim_Sucursal
    SELECT DISTINCT 
        s.nro_sucursal 
	FROM LOSGDS.Sucursal s
END
GO


-- Migracion BI_Dim_TipoMaterial
CREATE PROCEDURE LOSGDS.MigrarDimTipoMaterial
AS
BEGIN
    INSERT INTO LOSGDS.BI_Dim_TipoMaterial
    SELECT DISTINCT 
        m.tipo 
	FROM LOSGDS.Material m
END
GO


-- Migracion BI_Dim_Ubicacion
CREATE PROCEDURE LOSGDS.MigrarDimUbicacion
AS
BEGIN
    
INSERT INTO LOSGDS.BI_Dim_Ubicacion (provincia_id, localidad_id, nombre_provincia, nombre_localidad)
		SELECT DISTINCT 
			*
		FROM LOSGDS.Proveedor p
		JOIN LOSGDS.Direccion d ON d.id_direccion = p.proveedor_direccion
		JOIN LOSGDS.Localidad l ON l.id_localidad = d.direccion_localidad
		JOIN LOSGDS.Provincia pr ON pr.id_provincia = l.localidad_provincia
	UNION 
		SELECT DISTINCT
		*
		FROM LOSGDS.Sucursal s
		JOIN LOSGDS.Direccion d ON d.id_direccion = s.sucursal_direccion
		JOIN LOSGDS.Localidad l ON l.id_localidad = d.direccion_localidad
		JOIN LOSGDS.Provincia pr ON pr.id_provincia = l.localidad_provincia
	UNION
		SELECT DISTINCT
		*
		FROM LOSGDS.Cliente c
		JOIN LOSGDS.Direccion d ON d.id_direccion = c.cliente_direccion
		JOIN LOSGDS.Localidad l ON l.id_localidad = d.direccion_localidad
		JOIN LOSGDS.Provincia pr ON pr.id_provincia = l.localidad_provincia
END
GO

-- Crear Rangos Etarios BI_Dim_RangoEtario

CREATE PROCEDURE CrearRangosEtarios
AS
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO LOSGDS.BI_Dim_RangoEtario(rango_etario_inicio,rango_etario_fin)
        VALUES
		(NULL,25),
		(25,35),
		(35,50),
		(50,null)
	COMMIT TRANSACTION;
END
GO






---------- Migracion HECHOS

-- Migracion BI_Hechos_Compras

CREATE PROCEDURE LOSGDS.MigrarHechosCompras
AS
BEGIN

    INSERT INTO LOSGDS.BI_Hechos_Compras
		SELECT
			t.tiempo_id,
			tm.id_material,
			id_sucursal,
			SUM(c.total) AS importe_total,
			COUNT(*) AS cantidad
		FROM LOSGDS.Compra c
		JOIN LOSGDS.BI_Dim_Tiempo t ON YEAR(c.fecha) = t.anio AND MONTH(c.fecha) = mes
		JOIN LOSGDS.Detalle_Compra dc ON c.id_compra = dc.det_compra_compra
		JOIN LOSGDS.Material m ON m.id_material = dc.detalle_material
		JOIN LOSGDS.BI_Dim_TipoMaterial tm ON tm.tipo_material = m.tipo
		JOIN LOSGDS.BI_Dim_Sucursal s ON s.nro_sucursal = c.compra_sucursal
		GROUP BY t.tiempo_id, tm.id_material, id_sucursal
END
GO



-- VISTAS



-- 7 Promedio de Compras: importe promedio de compras por mes.

CREATE VIEW LOSGDS.BI_Vista_ComprasPromedio AS
	SELECT 
		t.mes AS mes,
		t.anio AS anio,
		CONVERT(decimal(18,2), c.importe_total / c.cantidad_total) AS importe_promedio
	FROM LOSGDS.BI_Hechos_Compras c
	JOIN LOSGDS.BI_Dim_Tiempo t ON t.tiempo_id = c.id_tiempo 
	GROUP BY t.mes, t.anio
GO


/* 8 Compras por Tipo de Material. Importe total gastado por tipo de material,
sucursal y cuatrimestre. */


CREATE VIEW LOSGDS.BI_Vista_ComprasTotal AS
	SELECT 
		t.cuatrimestre AS cuatrimestre,
		t.anio AS anio,
		tm.tipo_material AS tipoMaterial,
		s.nro_sucursal AS nroSucursal,
		SUM(c.importe_total) AS importeTotal
	FROM LOSGDS.BI_Hechos_Compras c
	JOIN LOSGDS.BI_Dim_Tiempo t ON t.tiempo_id = c.id_tiempo
	JOIN LOSGDS.BI_Dim_TipoMaterial tm ON c.id_material = tm.id_material
	JOIN LOSGDS.BI_Dim_Sucursal s ON s.id_sucursal = c.id_sucursal
	GROUP BY t.cuatrimestre, t.anio
GO

