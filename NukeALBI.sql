USE GD1C2025;
GO

--Petición: Actualicen el nuke en caso que agreguen o cambien cosas en las craciones, migraciones, etc.

-- 1. DROP CONSTRAINTS 

-- BI_Hechos_Facturacion
IF OBJECT_ID('LOSGDS.BI_Hechos_Facturacion', 'U') IS NOT NULL
BEGIN
    ALTER TABLE LOSGDS.BI_Hechos_Facturacion DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Facturacion__id_tiempo;
    ALTER TABLE LOSGDS.BI_Hechos_Facturacion DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Facturacion__id_ubicacion;
    ALTER TABLE LOSGDS.BI_Hechos_Facturacion DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Facturacion__id_sucursal;
    ALTER TABLE LOSGDS.BI_Hechos_Facturacion DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Facturacion__id_rango_etario;
    ALTER TABLE LOSGDS.BI_Hechos_Facturacion DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Facturacion__id_modelo_sillon;
END

-- BI_Hechos_Compras
IF OBJECT_ID('LOSGDS.BI_Hechos_Compras', 'U') IS NOT NULL
BEGIN
	ALTER TABLE LOSGDS.BI_Hechos_Compras DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Compras__id_tiempo;
	ALTER TABLE LOSGDS.BI_Hechos_Compras DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Compras__id_material;
	ALTER TABLE LOSGDS.BI_Hechos_Compras DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Compras__id_sucursal;
END

-- BI_Hechos_Envios
IF OBJECT_ID('LOSGDS.BI_Hechos_Envios', 'U') IS NOT NULL
BEGIN
	ALTER TABLE LOSGDS.BI_Hechos_Envios DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Envios__id_tiempo;
	ALTER TABLE LOSGDS.BI_Hechos_Envios DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Envios__id_ubicacion;
END

-- BI_Hechos_Pedidos
IF OBJECT_ID('LOSGDS.BI_Hechos_Pedidos', 'U') IS NOT NULL
BEGIN
	ALTER TABLE LOSGDS.BI_Hechos_Pedidos DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Pedidos__id_tiempo;
	ALTER TABLE LOSGDS.BI_Hechos_Pedidos DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Pedidos__id_estado_pedido;
	ALTER TABLE LOSGDS.BI_Hechos_Pedidos DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Pedidos__id_sucursal;
	ALTER TABLE LOSGDS.BI_Hechos_Pedidos DROP CONSTRAINT IF EXISTS FK__BI_Hechos_Pedidos__id_turno_ventas;
END

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
DECLARE @sqlProcedures NVARCHAR(MAX) = N'';
SELECT @sqlProcedures += 'DROP PROCEDURE IF EXISTS LOSGDS.' + QUOTENAME(name) + ';' + CHAR(13)
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'LOSGDS'
  AND (
    name LIKE 'Migrar%' OR
    name LIKE 'CrearRangos%' OR
    name LIKE '%Hechos%' OR
    name LIKE '%Dim%'
);
EXEC sp_executesql @sqlProcedures;

-- 5. DROP VISTAS (si existieran)
DECLARE @sqlViews NVARCHAR(MAX) = N'';
SELECT @sqlViews += 'DROP VIEW IF EXISTS LOSGDS.' + QUOTENAME(name) + ';' + CHAR(13)
FROM sys.views
WHERE SCHEMA_NAME(schema_id) = 'LOSGDS';
EXEC sp_executesql @sqlViews;

-- 6. DROP FUNCIONES escalares y de tabla
DECLARE @sqlFuncs NVARCHAR(MAX) = N'';
SELECT @sqlFuncs += 'DROP FUNCTION IF EXISTS LOSGDS.' + QUOTENAME(name) + ';' + CHAR(13)
FROM sys.objects
WHERE SCHEMA_NAME(schema_id) = 'LOSGDS' AND type IN ('FN', 'IF', 'TF');
EXEC sp_executesql @sqlFuncs;