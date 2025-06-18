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