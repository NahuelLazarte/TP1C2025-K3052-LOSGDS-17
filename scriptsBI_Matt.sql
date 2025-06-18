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
    rango_etario_inicio INT,
    rango_etario_fin INT
)
GO



CREATE TABLE LOSGDS.BI_Dim_Sucursal (
    id_sucursal BIGINT IDENTITY PRIMARY KEY,
    nro_sucursal BIGINT
)
GO

CREATE TABLE LOSGDS.BI_Dim_Modelo_Sillon (
    id_modelo_sillon BIGINT PRIMARY KEY,
    nombre NVARCHAR(255),
    descripcion NVARCHAR(255)
);
GO


--- Creacion Tablas BI

CREATE TABLE LOSGDS.BI_Hechos_Facturacion (
    id_tiempo BIGINT NOT NULL,
    id_ubicacion BIGINT NOT NULL,
    id_sucursal BIGINT NOT NULL,
    id_rango_etario BIGINT NOT NULL,
    id_modelo_sillon BIGINT NOT NULL,
	cantidad_facturas INT NOT NULL,
    total DECIMAL(18,2) NOT NULL,
    PRIMARY KEY (id_tiempo, id_ubicacion, id_sucursal, id_rango_etario, id_modelo_sillon),
    FOREIGN KEY (id_tiempo) REFERENCES LOSGDS.BI_Dim_Tiempo(id_tiempo),
    FOREIGN KEY (id_ubicacion) REFERENCES LOSGDS.BI_Dim_Ubicacion(id_ubicacion),
    FOREIGN KEY (id_sucursal) REFERENCES LOSGDS.BI_Dim_Sucursal(id_sucursal),
    FOREIGN KEY (id_rango_etario) REFERENCES LOSGDS.BI_Dim_Rango_Etario_Cliente(id_rango_etario),
    FOREIGN KEY (id_modelo_sillon) REFERENCES LOSGDS.BI_Dim_Modelo_Sillon(id_modelo_sillon)
);
GO


--Migración de las dimensiones

CREATE PROCEDURE LOSGDS.MigrarDimSucursal
AS
BEGIN
    INSERT INTO LOSGDS.BI_Dim_Sucursal
    SELECT DISTINCT 
        s.nro_sucursal
	FROM LOSGDS.Sucursal s
END
GO


CREATE PROCEDURE MigrarDimUbicacion
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

CREATE PROCEDURE LOSGDS.MigrarDimTiempo
AS
BEGIN
    INSERT INTO LOSGDS.BI_Dim_Tiempo (anio, cuatrimestre, mes)
    SELECT DISTINCT 
        YEAR(fecha),
        CASE 
            WHEN MONTH(fecha) BETWEEN 1 AND 4 THEN 'Primer Cuatrimestre'
            WHEN MONTH(fecha) BETWEEN 5 AND 8 THEN 'Segundo Cuatrimestre'
            ELSE 'Tercer Cuatrimestre'
        END,
        MONTH(fecha)
    FROM (
        SELECT fecha FROM LOSGDS.Factura
        UNION
        SELECT fecha FROM LOSGDS.Compra
        UNION
        SELECT fecha FROM LOSGDS.Pedido
        UNION
        SELECT fecha_programada FROM LOSGDS.Envio
    ) AS fechas
END
GO


CREATE PROCEDURE LOSGDS.MigrarDimModeloSillon
AS
BEGIN
    INSERT INTO LOSGDS.BI_Dim_Modelo_Sillon (id_modelo_sillon, nombre, descripcion)
    SELECT 
        cod_modelo,
        modelo,
        descripcion
    FROM LOSGDS.Modelo
END
GO

-- Migracion de los Hechos

CREATE PROCEDURE LOSGDS.MigrarHechosFacturacion
AS
BEGIN
    INSERT INTO LOSGDS.BI_Hechos_Facturacion (
        id_tiempo,
        id_ubicacion,
        id_sucursal,
        id_rango_etario,
        id_modelo_sillon,
		cantidad_facturas,
        total
    )
    SELECT 
        t.id_tiempo,
        u.id_ubicacion,
        s.id_sucursal,
        r.id_rango_etario,
        mo.cod_modelo,
		COUNT(DISTINCT f.id_factura) AS cantidad_facturas,
        SUM(df.subtotal) AS total
    FROM LOSGDS.Detalle_Factura df
    JOIN LOSGDS.Factura f ON f.id_factura = df.det_fact_factura
    JOIN LOSGDS.Detalle_Pedido dp ON dp.id_det_pedido = df.det_fact_det_pedido
    JOIN LOSGDS.Pedido p ON p.id_pedido = dp.det_ped_pedido
    JOIN LOSGDS.Cliente c ON c.id_cliente = p.pedido_cliente
    JOIN LOSGDS.Sillon si ON si.cod_sillon = dp.det_ped_sillon
    JOIN LOSGDS.Modelo mo ON mo.cod_modelo = si.sillon_modelo
    JOIN LOSGDS.Sucursal s ON s.id_sucursal = f.fact_sucursal
    JOIN LOSGDS.Direccion d ON d.id_direccion = s.sucursal_direccion
    JOIN LOSGDS.Localidad l ON l.id_localidad = d.direccion_localidad
    JOIN LOSGDS.Provincia pr ON pr.id_provincia = l.localidad_provincia
    JOIN LOSGDS.BI_Dim_Ubicacion u ON u.id_localidad = l.id_localidad AND u.id_provincia = pr.id_provincia
    JOIN LOSGDS.BI_Dim_Tiempo t ON t.anio = YEAR(f.fecha) AND t.mes = MONTH(f.fecha)
    JOIN LOSGDS.BI_Dim_Rango_Etario_Cliente r 
        ON DATEDIFF(YEAR, c.fecha_nacimiento, f.fecha) BETWEEN r.rango_etario_inicio AND r.rango_etario_fin
    GROUP BY 
        t.id_tiempo,
        u.id_ubicacion,
        s.id_sucursal,
        r.id_rango_etario,
        mo.cod_modelo
END
GO