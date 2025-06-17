USE GD1C2025;
GO

--Petición: Actualicen el nuke en caso que agreguen o cambien cosas en las craciones, migraciones, etc.

-- 1. DROP CONSTRAINTS 

-- BI_Hechos_Facturacion
ALTER TABLE LOSGDS.BI_Hechos_Facturacion DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Facturacion__id_tiempo;
ALTER TABLE LOSGDS.BI_Hechos_Facturacion DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Facturacion__id_ubicacion;
ALTER TABLE LOSGDS.BI_Hechos_Facturacion DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Facturacion__id_sucursal;
ALTER TABLE LOSGDS.BI_Hechos_Facturacion DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Facturacion__id_rango_etario;
ALTER TABLE LOSGDS.BI_Hechos_Facturacion DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Facturacion__id_modelo_sillon;

-- BI_Hechos_Compras
ALTER TABLE LOSGDS.BI_Hechos_Compras DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Compras__id_tiempo;
ALTER TABLE LOSGDS.BI_Hechos_Compras DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Compras__id_material;
ALTER TABLE LOSGDS.BI_Hechos_Compras DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Compras__id_sucursal;

-- BI_Hechos_Envios
ALTER TABLE LOSGDS.BI_Hechos_Envios DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Envios__id_tiempo;
ALTER TABLE LOSGDS.BI_Hechos_Envios DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Envios__id_ubicacion;

-- BI_Hechos_Pedidos
ALTER TABLE LOSGDS.BI_Hechos_Pedidos DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Pedidos__id_tiempo;
ALTER TABLE LOSGDS.BI_Hechos_Pedidos DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Pedidos__id_estado_pedido;
ALTER TABLE LOSGDS.BI_Hechos_Pedidos DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Pedidos__id_sucursal;
ALTER TABLE LOSGDS.BI_Hechos_Pedidos DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Pedidos__id_turno_ventas;

-- 2. DROP TABLAS DE HECHOS (primero para evitar errores de FK)

DROP TABLE IF EXISTS LOSGDS.BI_Hechos_Facturacion;
DROP TABLE IF EXISTS LOSGDS.BI_Hechos_Compras;
DROP TABLE IF EXISTS LOSGDS.BI_Hechos_Envios;
DROP TABLE IF EXISTS LOSGDS.BI_Hechos_Pedidos;

-- 3. DROP TABLAS DE DIMENSIONES (seguras de eliminar en este orden)

DROP TABLE IF EXISTS LOSGDS.BI_Dim_Modelo_Sillon;
DROP TABLE IF EXISTS LOSGDS.BI_Dim_Sucursal;
DROP TABLE IF EXISTS LOSGDS.BI_Dim_Ubicacion;
DROP TABLE IF EXISTS LOSGDS.BI_Dim_Tiempo;
DROP TABLE IF EXISTS LOSGDS.BI_Dim_TipoMaterial;
DROP TABLE IF EXISTS LOSGDS.BI_Dim_Rango_Etario_Cliente;
DROP TABLE IF EXISTS LOSGDS.BI_Dim_RangoEtario;
DROP TABLE IF EXISTS LOSGDS.BI_Dim_Estado_Pedido;
DROP TABLE IF EXISTS LOSGDS.BI_Dim_Turno_Ventas;

-- 4. DROP PROCEDIMIENTOS almacenados relacionados al BI

DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += 'DROP PROCEDURE IF EXISTS LOSGDS.' + QUOTENAME(name) + ';' + CHAR(13)
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'LOSGDS'
  AND (
    name LIKE 'Migrar%' OR
    name LIKE 'CrearRangos%' OR
    name LIKE '%Hechos%' OR
    name LIKE '%Dim%'
);
EXEC sp_executesql @sql;