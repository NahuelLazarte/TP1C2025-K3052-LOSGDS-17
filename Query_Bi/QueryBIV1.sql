USE GD1C2025

--DIMENSIONES
--Creación de las dimensiones

CREATE TABLE LOSGDS.BI_Hechos_Pedidos(
    id_tiempo BIGINT,
    id_estado_pedido BIGINT , 
	id_sucursal BIGINT,
	id_turno_ventas BIGINT,
    cantidad INT NOT NULL,	
	dias_promedio_facturacion DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (id_tiempo) REFERENCES LOSGDS.BI_Dim_Tiempo(id_tiempo),
    FOREIGN KEY (id_estado_pedido) REFERENCES LOSGDS.BI_Dim_Estado_Pedido(id_estado_pedido),
    FOREIGN KEY (id_sucursal) REFERENCES LOSGDS.BI_Dim_Sucursal(id_sucursal),
	FOREIGN KEY (id_turno_ventas) REFERENCES LOSGDS.BI_Dim_Turno_Ventas(id_turno_ventas),

	PRIMARY KEY(id_tiempo, id_estado_pedido,id_sucursal,id_turno_ventas)
)
GO


CREATE TABLE LOSGDS.BI_Dim_Tiempo (
    id_tiempo BIGINT IDENTITY PRIMARY KEY,
    anio INT NOT NULL,
    mes INT NOT NULL,
    cuatrimestre NVARCHAR(255) NOT NULL
)
GO

CREATE TABLE LOSGDS.BI_Dim_Estado_Pedido(
    id_estado_pedido BIGINT IDENTITY PRIMARY KEY,
    estado_pedido NVARCHAR(255) NOT NULL,
)
GO

CREATE TABLE LOSGDS.BI_Dim_Sucursal(
    id_sucursal BIGINT IDENTITY PRIMARY KEY,
    nro_sucursal BIGINT NOT NULL,
)
GO

CREATE TABLE LOSGDS.BI_Dim_Turno_Ventas(
    id_turno_ventas BIGINT IDENTITY PRIMARY KEY,
    turno_ventas NVARCHAR(255) NOT NULL,
)
GO

CREATE TABLE LOSGDS.BI_Hechos_Compras(
    id_tiempo BIGINT,
    id_sucursal BIGINT,
    monto_compra DECIMAL(18,2),
    FOREIGN KEY (id_tiempo) REFERENCES LOSGDS.BI_Dim_Tiempo(id_tiempo),
    FOREIGN KEY (id_sucursal) REFERENCES LOSGDS.BI_Dim_Sucursal(id_sucursal)
)
GO


/*MIGRACION HECHOS*/
CREATE PROCEDURE HOBBITS11.MigrarDimTiempo
AS
BEGIN
INSERT INTO LOSGDS.BI_Dim_Tiempo (anio, mes, cuatrimestre)
SELECT DISTINCT 
    YEAR(p.pedi_fecha) AS anio,
    MONTH(p.pedi_fecha) AS mes,
    CASE 
        WHEN MONTH(p.pedi_fecha) BETWEEN 1 AND 4 THEN '1º Cuatrimestre'
        WHEN MONTH(p.pedi_fecha) BETWEEN 5 AND 8 THEN '2º Cuatrimestre'
        ELSE '3º Cuatrimestre'
    END AS cuatrimestre
FROM LOSGDS.Pedido p;

INSERT INTO LOSGDS.BI_Dim_Estado_Pedido (estado_pedido)
SELECT DISTINCT estado
FROM LOSGDS.Pedido;
END
GO

CREATE PROCEDURE HOBBITS11.MigrarDimTiempo
AS
BEGIN
INSERT INTO LOSGDS.BI_Dim_Sucursal (nro_sucursal)
SELECT DISTINCT sucu_nro
FROM LOSGDS.Sucursal;
END
GO

CREATE PROCEDURE HOBBITS11.MigrarDimTiempo
AS
BEGIN
INSERT INTO LOSGDS.BI_Dim_Estado_Pedido (estado_pedido)
SELECT DISTINCT estado
FROM LOSGDS.Pedido;


CREATE PROCEDURE HOBBITS11.MigrarDimTiempo
AS
BEGIN
INSERT INTO LOSGDS.BI_Dim_Sucursal (nro_sucursal)
SELECT DISTINCT sucu_nro
FROM LOSGDS.Sucursal;
END
GO

CREATE PROCEDURE HOBBITS11.MigrarDimTiempo
AS
BEGIN
INSERT INTO LOSGDS.BI_Dim_Turno_Ventas (turno_ventas)
SELECT DISTINCT 
    CASE 
        WHEN CAST(FORMAT(pedi_fecha, 'HH:mm') AS TIME) 
		BETWEEN '08:00' AND '13:59' THEN '08:00 - 14:00'
        ELSE '14:00 - 20:00'
    END
FROM LOSGDS.Pedido;
END
GO


CREATE PROCEDURE LOSGDS.MigrarHechosPedidos
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
    SELECT 
        t.id_tiempo,
        ep.id_estado_pedido,
        s.id_sucursal,
        tv.id_turno_ventas,
        COUNT(*) AS cantidad_pedidos,
        AVG(DATEDIFF(DAY, p.pedi_fecha, f.fact_fecha)) AS dias_promedio_facturacion
    FROM LOSGDS.Pedido p
    JOIN LOSGDS.Factura f ON f.fact_pedido = p.pedi_id

    JOIN LOSGDS.BI_Dim_Sucursal s 
        ON s.nro_sucursal = p.pedi_sucursal

    JOIN LOSGDS.BI_Dim_Estado_Pedido ep 
        ON ep.estado_pedido = p.estado

    JOIN LOSGDS.BI_Dim_Tiempo t 
        ON t.anio = YEAR(p.pedi_fecha) AND t.mes = MONTH(p.pedi_fecha)

    JOIN LOSGDS.BI_Dim_Turno_Ventas tv 
        ON tv.turno_ventas = 
            CASE 
                WHEN CAST(FORMAT(p.pedi_fecha, 'HH:mm') AS TIME) BETWEEN '08:00' AND '13:59' THEN '08:00 - 14:00'
                ELSE '14:00 - 20:00'
            END

    GROUP BY 
        t.id_tiempo,
        ep.id_estado_pedido,
        s.id_sucursal,
        tv.id_turno_ventas;
END
GO









/*VISTAS*/

/* 4 Volumen de pedidos:
Cantidad de pedidos registrados por turno, por sucursal
según el mes de cada año.*/

CREATE VIEW LOSGDS.BI_Vista_Volumen_Pedidos AS
SELECT
    t.anio,
    t.mes,
    s.nro_sucursal,
    v.turno_ventas,
    SUM(h.cantidad) AS volumen_pedidos
FROM LOSGDS.BI_Hechos_Pedidos h
JOIN LOSGDS.BI_Dim_Tiempo t ON h.id_tiempo = t.id_tiempo
JOIN LOSGDS.BI_Dim_Sucursal s ON h.id_sucursal = s.id_sucursal
JOIN LOSGDS.BI_Dim_Turno_Ventas v ON h.id_turno_ventas = v.id_turno_ventas
GROUP BY
    t.anio, t.mes, s.nro_sucursal, v.turno_ventas
GO

/*5 Conversión de pedidos: 
Porcentaje de pedidos según estado, por cuatrimestre y sucursal*/
CREATE VIEW LOSGDS.BI_Vista_Conversion_Pedidos AS
SELECT 
    t.anio,
    t.cuatrimestre,
    s.nro_sucursal,
    e.estado_pedido,
    SUM(h.cantidad) AS cantidad_pedidos,
    CAST(SUM(h.cantidad) * 100.0 / 
        NULLIF(SUM(h.cantidad) OVER (PARTITION BY t.anio, t.cuatrimestre, s.id_sucursal),0) AS DECIMAL(5,2)) AS porcentaje
FROM LOSGDS.BI_Hechos_Pedidos h
JOIN LOSGDS.BI_Dim_Tiempo t ON h.id_tiempo = t.id_tiempo
JOIN LOSGDS.BI_Dim_Sucursal s ON h.id_sucursal = s.id_sucursal
JOIN LOSGDS.BI_Dim_Estado_Pedido e ON h.id_estado_pedido = e.id_estado_pedido
GROUP BY
    t.anio, t.cuatrimestre, s.nro_sucursal, s.id_sucursal, e.estado_pedido;
GO

/*6 Tiempo promedio de fabricación: Tiempo promedio que tarda cada sucursal
entre que se registra un pedido y registra la factura para el mismo. Por
cuatrimestre.*/
CREATE VIEW LOSGDS.BI_Vista_Tiempo_Promedio_Fabricacion AS
SELECT 
    t.anio,
    t.cuatrimestre,
    s.nro_sucursal,
    h.dias_promedio_facturacion AS promedio_dias
FROM LOSGDS.BI_Hechos_Pedidos h
JOIN LOSGDS.BI_Dim_Tiempo t ON h.id_tiempo = t.id_tiempo
JOIN LOSGDS.BI_Dim_Sucursal s ON h.id_sucursal = s.id_sucursal
GROUP BY 
    t.anio, t.cuatrimestre, s.nro_sucursal;
GO


