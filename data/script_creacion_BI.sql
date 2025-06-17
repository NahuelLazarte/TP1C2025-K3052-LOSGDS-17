USE GD1C2025
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
    rango_etario NVARCHAR(50) NOT NULL
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




-- Migracion BI_Hechos_Publicaciones

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

