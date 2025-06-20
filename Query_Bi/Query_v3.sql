USE GD1C2025;
GO


IF OBJECT_ID('LOSGDS.BI_Hechos_Pedidos',  'U') IS NOT NULL DROP TABLE LOSGDS.BI_Hechos_Pedidos;
IF OBJECT_ID('LOSGDS.BI_Hechos_Compras',  'U') IS NOT NULL DROP TABLE LOSGDS.BI_Hechos_Compras;

IF OBJECT_ID('LOSGDS.BI_Dim_Turno_Ventas', 'U') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_Turno_Ventas;
IF OBJECT_ID('LOSGDS.BI_Dim_Sucursal',    'U') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_Sucursal;
IF OBJECT_ID('LOSGDS.BI_Dim_Estado_Pedido','U') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_Estado_Pedido;
IF OBJECT_ID('LOSGDS.BI_Dim_Tiempo',       'U') IS NOT NULL DROP TABLE LOSGDS.BI_Dim_Tiempo;
GO

/****************************************
 2) CREATE TABLE Dimensiones
****************************************/
CREATE TABLE LOSGDS.BI_Dim_Tiempo (
    id_tiempo    BIGINT      IDENTITY,
    anio         INT         NOT NULL,
    mes          INT         NOT NULL,
    cuatrimestre NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_BI_Dim_Tiempo PRIMARY KEY CLUSTERED (id_tiempo)
);
GO

CREATE TABLE LOSGDS.BI_Dim_Estado_Pedido (
    id_estado_pedido BIGINT      IDENTITY,
    estado_pedido    NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_BI_Dim_Estado_Pedido PRIMARY KEY CLUSTERED (id_estado_pedido)
);
GO

CREATE TABLE LOSGDS.BI_Dim_Sucursal (
    id_sucursal  BIGINT      IDENTITY,
    nro_sucursal BIGINT      NOT NULL,
    CONSTRAINT PK_BI_Dim_Sucursal PRIMARY KEY CLUSTERED (id_sucursal)
);
GO

CREATE TABLE LOSGDS.BI_Dim_Turno_Ventas (
    id_turno_ventas BIGINT      IDENTITY,
    turno_ventas    NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_BI_Dim_Turno_Ventas PRIMARY KEY CLUSTERED (id_turno_ventas)
);
GO

/****************************************
 3) CREATE TABLE Hechos
   (dimensiones ya creadas)
****************************************/
CREATE TABLE LOSGDS.BI_Hechos_Pedidos (
    id_tiempo                 BIGINT      NOT NULL,
    id_estado_pedido          BIGINT      NOT NULL,
    id_sucursal               BIGINT      NOT NULL,
    id_turno_ventas           BIGINT      NOT NULL,
    cantidad                  INT         NOT NULL,
    dias_promedio_facturacion DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_BI_Hechos_Pedidos PRIMARY KEY CLUSTERED (
        id_tiempo,
        id_estado_pedido,
        id_sucursal,
        id_turno_ventas
    ),
    CONSTRAINT FK_HP_Tiempo        FOREIGN KEY(id_tiempo)        REFERENCES LOSGDS.BI_Dim_Tiempo(id_tiempo),
    CONSTRAINT FK_HP_EstadoPedido FOREIGN KEY(id_estado_pedido) REFERENCES LOSGDS.BI_Dim_Estado_Pedido(id_estado_pedido),
    CONSTRAINT FK_HP_Sucursal     FOREIGN KEY(id_sucursal)      REFERENCES LOSGDS.BI_Dim_Sucursal(id_sucursal),
    CONSTRAINT FK_HP_TurnoVenta   FOREIGN KEY(id_turno_ventas)  REFERENCES LOSGDS.BI_Dim_Turno_Ventas(id_turno_ventas)
);
GO

CREATE TABLE LOSGDS.BI_Hechos_Compras (
    id_tiempo   BIGINT      NOT NULL,
    id_sucursal BIGINT      NOT NULL,
    monto_compra DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_BI_Hechos_Compras PRIMARY KEY CLUSTERED (id_tiempo, id_sucursal),
    CONSTRAINT FK_HC_Tiempo    FOREIGN KEY(id_tiempo)   REFERENCES LOSGDS.BI_Dim_Tiempo(id_tiempo),
    CONSTRAINT FK_HC_Sucursal  FOREIGN KEY(id_sucursal) REFERENCES LOSGDS.BI_Dim_Sucursal(id_sucursal)
);
GO

/****************************************
 3) CREATE PROCEDURES (migraciones)
****************************************/
-- 3.1 Migrar Dim_Tiempo
CREATE PROCEDURE LOSGDS.MigrarDimTiempo
AS
BEGIN
    INSERT INTO LOSGDS.BI_Dim_Tiempo (anio, mes, cuatrimestre)
    SELECT DISTINCT 
        YEAR(p.fecha) AS anio,
        MONTH(p.fecha) AS mes,
        CASE 
            WHEN MONTH(p.fecha) BETWEEN 1 AND 4 THEN '1º Cuatrimestre'
            WHEN MONTH(p.fecha) BETWEEN 5 AND 8 THEN '2º Cuatrimestre'
            ELSE '3º Cuatrimestre'
        END
    FROM LOSGDS.Pedido p
    WHERE p.fecha IS NOT NULL;
END;
GO

-- 3.2 Migrar Dim_Estado_Pedido
CREATE PROCEDURE LOSGDS.MigrarDimEstadoPedido
AS
BEGIN
    INSERT INTO LOSGDS.BI_Dim_Estado_Pedido (estado_pedido)
    SELECT DISTINCT p.estado
    FROM LOSGDS.Pedido p
    WHERE p.estado IS NOT NULL;
END;
GO

-- 3.3 Migrar Dim_Sucursal
CREATE PROCEDURE LOSGDS.MigrarDimSucursal
AS
BEGIN
    INSERT INTO LOSGDS.BI_Dim_Sucursal (nro_sucursal)
    SELECT DISTINCT s.nro_sucursal
    FROM LOSGDS.Sucursal s
    WHERE s.nro_sucursal IS NOT NULL;
END;
GO

-- 3.4 Migrar Dim_Turno_Ventas
CREATE PROCEDURE LOSGDS.MigrarDimTurnoVentas
AS
BEGIN
    INSERT INTO LOSGDS.BI_Dim_Turno_Ventas (turno_ventas)
    SELECT DISTINCT 
        CASE 
            WHEN CAST(FORMAT(p.fecha, 'HH:mm') AS TIME) BETWEEN '08:00' AND '13:59' THEN '08:00 - 14:00'
            ELSE '14:00 - 20:00'
        END
    FROM LOSGDS.Pedido p
    WHERE p.fecha IS NOT NULL;
END;
GO

-- 3.5 Migrar Hechos_Pedidos
CREATE  PROCEDURE LOSGDS.MigrarHechosPedidos
AS
BEGIN
    INSERT INTO LOSGDS.BI_Hechos_Pedidos (
        id_tiempo,
        id_estado_pedido,
        id_sucursal,
        id_turno_ventas,
        cantidad,
        dias_promedio_facturacion
    )
    SELECT  p.fecha,
	 f.fecha,
        dt.id_tiempo,
        dep.id_estado_pedido,
        ds.id_sucursal,
        dtv.id_turno_ventas,
        COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    ISNULL(AVG(DATEDIFF(DAY, p.fecha, f.fecha)), 0) AS dias_promedio_facturacion
    FROM LOSGDS.Pedido p
    JOIN LOSGDS.Detalle_Pedido dp           ON dp.det_ped_pedido = p.id_pedido
    JOIN LOSGDS.Detalle_Factura df          ON df.det_fact_det_pedido = dp.id_det_pedido
    JOIN LOSGDS.Factura f                   ON f.id_factura = df.det_fact_factura
    JOIN LOSGDS.Sucursal s                  ON p.pedido_sucursal = s.id_sucursal
    JOIN LOSGDS.BI_Dim_Sucursal ds          ON ds.nro_sucursal = s.nro_sucursal
    JOIN LOSGDS.BI_Dim_Estado_Pedido dep    ON dep.estado_pedido = p.estado
    JOIN LOSGDS.BI_Dim_Tiempo dt            ON dt.anio = YEAR(p.fecha) AND dt.mes = MONTH(p.fecha)
    JOIN LOSGDS.BI_Dim_Turno_Ventas dtv     ON dtv.turno_ventas = 
		CASE 
            WHEN CAST(FORMAT(p.fecha, 'HH:mm') AS TIME) BETWEEN '08:00' AND '13:59'
                THEN '08:00 - 14:00'
            ELSE '14:00 - 20:00'
        END 
	WHERE p.fecha IS NOT NULL AND  f.fecha IS NOT NULL-- AND f.fecha >= p.fecha
    GROUP BY 
        dt.id_tiempo,
        dep.id_estado_pedido,
        ds.id_sucursal,
        dtv.id_turno_ventas
END
GO


/****************************************
 4) EJECUCIÓN de migraciones
****************************************/
BEGIN TRANSACTION;
    EXECUTE LOSGDS.MigrarDimTiempo;
    EXECUTE LOSGDS.MigrarDimEstadoPedido;
    EXECUTE LOSGDS.MigrarDimSucursal;
    EXECUTE LOSGDS.MigrarDimTurnoVentas;
    EXECUTE LOSGDS.MigrarHechosPedidos;
COMMIT;
GO

/****************************************
 5) CREATE VIEWS (indicadores)
****************************************/
-- 4. Volumen de pedidos
CREATE VIEW LOSGDS.BI_Vista_Volumen_Pedidos AS
SELECT
    t.anio,
    t.mes,
    s.nro_sucursal,
    v.turno_ventas,
    SUM(h.cantidad) AS volumen_pedidos
FROM LOSGDS.BI_Hechos_Pedidos h
JOIN LOSGDS.BI_Dim_Tiempo t         ON h.id_tiempo     = t.id_tiempo
JOIN LOSGDS.BI_Dim_Sucursal s       ON h.id_sucursal   = s.id_sucursal
JOIN LOSGDS.BI_Dim_Turno_Ventas v   ON h.id_turno_ventas = v.id_turno_ventas
GROUP BY t.anio, t.mes, s.nro_sucursal, v.turno_ventas;
GO

-- 5. Conversión de pedidos
CREATE VIEW LOSGDS.BI_Vista_Conversion_Pedidos AS
SELECT 
    t.anio,
    t.cuatrimestre,
    s.nro_sucursal,
    e.estado_pedido,
    SUM(h.cantidad) AS cantidad_pedidos,
    CAST(
        SUM(h.cantidad) * 100.0 /
        NULLIF((
            SELECT SUM(h2.cantidad)
            FROM LOSGDS.BI_Hechos_Pedidos h2
            JOIN LOSGDS.BI_Dim_Tiempo t2 ON h2.id_tiempo = t2.id_tiempo
            WHERE t2.anio = t.anio
              AND t2.cuatrimestre = t.cuatrimestre
              AND h2.id_sucursal = s.id_sucursal
        ), 0)
    AS DECIMAL(5,2)) AS porcentaje
FROM LOSGDS.BI_Hechos_Pedidos h
JOIN LOSGDS.BI_Dim_Tiempo         t ON h.id_tiempo = t.id_tiempo
JOIN LOSGDS.BI_Dim_Sucursal       s ON h.id_sucursal = s.id_sucursal
JOIN LOSGDS.BI_Dim_Estado_Pedido  e ON h.id_estado_pedido = e.id_estado_pedido
GROUP BY t.anio, t.cuatrimestre, s.nro_sucursal, s.id_sucursal, e.estado_pedido;
GO

-- 6. Tiempo promedio fabricación
CREATE VIEW LOSGDS.BI_Vista_Tiempo_Promedio_Fabricacion AS
SELECT 
    t.anio,
    t.cuatrimestre,
    s.nro_sucursal,
    ISNULL(AVG(CASE 
                  WHEN h.dias_promedio_facturacion >= 0 
                  THEN h.dias_promedio_facturacion 
                  ELSE NULL 
              END), 0) AS promedio_dias
FROM LOSGDS.BI_Hechos_Pedidos h
JOIN LOSGDS.BI_Dim_Tiempo    t ON h.id_tiempo   = t.id_tiempo
JOIN LOSGDS.BI_Dim_Sucursal  s ON h.id_sucursal = s.id_sucursal
GROUP BY t.anio, t.cuatrimestre, s.nro_sucursal;
GO

/****************************************
 6) DROP PROCEDURES (limpieza final)
****************************************/
IF OBJECT_ID('LOSGDS.MigrarDimTiempo', 'P')        IS NOT NULL DROP PROCEDURE LOSGDS.MigrarDimTiempo;
IF OBJECT_ID('LOSGDS.MigrarDimEstadoPedido', 'P')  IS NOT NULL DROP PROCEDURE LOSGDS.MigrarDimEstadoPedido;
IF OBJECT_ID('LOSGDS.MigrarDimSucursal', 'P')      IS NOT NULL DROP PROCEDURE LOSGDS.MigrarDimSucursal;
IF OBJECT_ID('LOSGDS.MigrarDimTurnoVentas', 'P')   IS NOT NULL DROP PROCEDURE LOSGDS.MigrarDimTurnoVentas;
IF OBJECT_ID('LOSGDS.MigrarHechosPedidos', 'P')    IS NOT NULL DROP PROCEDURE LOSGDS.MigrarHechosPedidos;
GO

-- DROP de VISTAS del modelo BI
IF OBJECT_ID('LOSGDS.BI_Vista_Volumen_Pedidos', 'V') IS NOT NULL
    DROP VIEW LOSGDS.BI_Vista_Volumen_Pedidos;
GO

IF OBJECT_ID('LOSGDS.BI_Vista_Conversion_Pedidos', 'V') IS NOT NULL
    DROP VIEW LOSGDS.BI_Vista_Conversion_Pedidos;
GO

IF OBJECT_ID('LOSGDS.BI_Vista_Tiempo_Promedio_Fabricacion', 'V') IS NOT NULL
    DROP VIEW LOSGDS.BI_Vista_Tiempo_Promedio_Fabricacion;
GO

/*
(19 rows affected)

(2 rows affected)

(9 rows affected)

(2 rows affected)

(678 rows affected)
-- Volumen de pedidos
SELECT TOP 10 * FROM LOSGDS.BI_Vista_Volumen_Pedidos;

-- Conversión de pedidos
SELECT TOP 10 * FROM LOSGDS.BI_Vista_Conversion_Pedidos;

-- Tiempo promedio de fabricación
SELECT TOP 10 * FROM LOSGDS.BI_Vista_Tiempo_Promedio_Fabricacion;*/

/*
SELECT DISTINCT Factura_Fecha, Pedido_Fecha,
    CASE 
        WHEN CAST(FORMAT(Pedido_Fecha, 'HH:mm') AS TIME) BETWEEN '08:00' AND '13:59'
            THEN '08:00 - 14:00'
        ELSE '14:00 - 20:00'
    END AS turno
FROM gd_esquema.Maestra
WHERE 
    Pedido_Fecha IS NOT NULL AND 
    Factura_Fecha IS NOT NULL AND 
    Factura_Fecha >= Pedido_Fecha;
--10372 fact y ped

SELECT 
    Sucursal_NroSucursal,
    CASE 
        WHEN CAST(FORMAT(Pedido_Fecha, 'HH:mm') AS TIME) BETWEEN '08:00' AND '13:59'
            THEN '08:00 - 14:00'
        ELSE '14:00 - 20:00'
    END AS turno,
    COUNT(DISTINCT Pedido_Numero) AS cantidad_pedidos,
    AVG(DATEDIFF(DAY, Pedido_Fecha, Factura_Fecha)) AS dias_promedio_facturacion
FROM gd_esquema.Maestra
WHERE 
    Pedido_Fecha IS NOT NULL AND 
    Factura_Fecha IS NOT NULL AND 
    Factura_Fecha >= Pedido_Fecha
GROUP BY 
    Sucursal_NroSucursal,
    CASE 
        WHEN CAST(FORMAT(Pedido_Fecha, 'HH:mm') AS TIME) BETWEEN '08:00' AND '13:59'
            THEN '08:00 - 14:00'
        ELSE '14:00 - 20:00'
    END;
	*/
