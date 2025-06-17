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
			id_material,
			id_sucursal,
			SUM(c.total),
			COUNT(*)
		FROM LOSGDS.Compra c
		JOIN LOSGDS.BI_Dim_Tiempo t ON YEAR(c.fecha) = t.anio AND MONTH(c.fecha) = mes
		--JOIN LOSGDS.BI_Dim_TipoMaterial tm ON tm.id_material = c.
		--GROUP BY subrubro_id, tiempo_id, marca_id
END
GO




CREATE PROCEDURE LOSGDS.MigrarHechosPublicaciones
AS
BEGIN

    INSERT INTO HOBBITS11.BI_Hechos_Publicaciones

	SELECT
	subrubro_id,
	tiempo_id,
	marca_id,
	SUM(publ_stock),
	SUM(DATEDIFF(DAY, publ_fecha_inicio, publ_fecha_fin)),
	count(*)
	FROM HOBBITS11.Publicacion
	JOIN HOBBITS11.Producto ON prod_id = publ_producto
	JOIN HOBBITS11.BI_Dim_RubroSubRubro ON prod_subr = subrubro_id
	JOIN HOBBITS11.BI_Dim_Tiempo ON YEAR(publ_fecha_inicio) = anio AND MONTH(publ_fecha_inicio) = mes
	JOIN HOBBITS11.BI_Dim_Marca on prod_marca = marca_id
	GROUP BY subrubro_id, tiempo_id, marca_id
	
END
GO


