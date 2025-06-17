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




/*VISTAS*/

CREATE VIEW volumen_pedidos
SELECT * FROM GD1C2025.LOSGDS

