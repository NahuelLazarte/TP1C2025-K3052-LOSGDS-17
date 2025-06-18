USE GD1C2025

CREATE TABLE LOSGDS.BI_Hechos_Envios(
	id_tiempo,
	id_ubicacion,
	costo_envios DECIMAL(18,2),
	cumplidos_en_fecha INT,
	total INT
)
CREATE TABLE LOSGDS.BI_Dim_Tiempo(
	id_tiempo,
	anio INT,
	mes INT,
	cuatrimestre NVARCHAR(255)
)

CREATE TABLE LOSGDS.BI_Dim_Ubicacion(
	id_ubicacion BIGINT IDENTITY PRIMARY KEY,
	id_localidad BIGINT,
	id_provincia BIGINT,
	nombre_localidad NVARCHAR(255),
	nombre_provincia NVARCHAR(255)
)
