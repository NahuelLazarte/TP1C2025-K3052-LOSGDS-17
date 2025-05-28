

CREATE PROCEDURE LOSGDS.migrar_Cancelacion_Pedido AS
BEGIN
    INSERT INTO LOSGDS.Cancelacion_Pedido 
        (cancel_ped_pedido, fecha, motivo)
    SELECT DISTINCT
        p.id_pedido,
        m.Pedido_Cancelacion_Fecha,
        m.Pedido_Cancelacion_Motivo
    FROM gd_esquema.Maestra m
    JOIN LOSGDS.Pedido p ON p.nro_pedido = m.Pedido_Numero
    WHERE m.Pedido_Cancelacion_Fecha IS NOT NULL;
END;
GO


CREATE PROCEDURE LOSGDS.migrar_Sucursal AS
BEGIN
    INSERT INTO LOSGDS.Sucursal 
        (sucursal_direccion, mail, telefono)
    SELECT DISTINCT
        d.id_direccion,
        m.Sucursal_mail,
        m.Sucursal_telefono
    FROM gd_esquema.Maestra m
    JOIN LOSGDS.Direccion d ON d.nombre = m.Sucursal_Direccion;
END;
GO


CREATE PROCEDURE LOSGDS.migrar_Compra AS
BEGIN
    INSERT INTO LOSGDS.Compra 
        (numero_compra, compra_sucursal, compra_proveedor, fecha, total)
    SELECT DISTINCT
        m.Compra_Numero,
        s.id_sucursal,
        p.id_proveedor,
        m.Compra_Fecha,
        CASE 
            WHEN m.Compra_Total < 0 THEN NULL 
            ELSE m.Compra_Total 
        END
    FROM gd_esquema.Maestra m
    JOIN LOSGDS.Sucursal s ON s.mail = m.Sucursal_mail AND s.telefono = m.Sucursal_telefono
    JOIN LOSGDS.Proveedor p ON p.cuit = m.Proveedor_Cuit;
END;
GO


CREATE PROCEDURE LOSGDS.migrar_Detalle_Compra AS
BEGIN
    INSERT INTO LOSGDS.Detalle_Compra 
        (det_compra_compra, detalle_material, precio, cantidad, subtotal)
    SELECT DISTINCT
        c.id_compra,
        mat.id_material,
        m.Detalle_Compra_Precio,
        m.Detalle_Compra_Cantidad,
        m.Detalle_Compra_SubTotal
    FROM gd_esquema.Maestra m
    JOIN LOSGDS.Compra c ON c.numero_compra = m.Compra_Numero
    JOIN LOSGDS.Material mat ON mat.material_nombre = m.Material_Nombre AND mat.tipo = m.Material_Tipo;
END;
GO


CREATE PROCEDURE LOSGDS.migrar_Detalle_Pedido AS
BEGIN
    INSERT INTO LOSGDS.Detalle_Pedido 
        (det_ped_sillon, det_ped_pedido, cantidad, precio, subtotal)
    SELECT DISTINCT
        s.cod_sillon,
        p.id_pedido, 
        m.Detalle_Pedido_Cantidad,
        m.Detalle_Pedido_Precio,
        m.Detalle_Pedido_SubTotal
    FROM gd_esquema.Maestra m
    JOIN LOSGDS.Sillon s ON s.sillon_modelo = m.Sillon_Modelo_Codigo
                         AND s.sillon_medida = (
                             SELECT cod_medida
                             FROM LOSGDS.Medida
                             WHERE alto = m.Sillon_Medida_Alto
                               AND ancho = m.Sillon_Medida_Ancho
                               AND profundidad = m.Sillon_Medida_Profundidad
                         )
    JOIN LOSGDS.Pedido p ON p.nro_pedido = m.Pedido_Numero;
END;
GO


------------------------



CREATE PROCEDURE LOSGDS.MigrarProvincias AS
BEGIN
    INSERT INTO LOSGDS.Provincia
    SELECT DISTINCT Sucursal_Provincia AS Provincia 
    FROM gd_esquema.Maestra WHERE Sucursal_Provincia IS NOT NULL
    UNION
    SELECT DISTINCT Cliente_Provincia AS Provincia 
    FROM gd_esquema.Maestra WHERE Cliente_Provincia IS NOT NULL
    UNION
    SELECT DISTINCT Proveedor_Provincia AS Provincia 
    FROM gd_esquema.Maestra WHERE Proveedor_Provincia IS NOT NULL
    ORDER BY Provincia
END
GO

CREATE PROCEDURE LOSGDS.MigrarLocalidades AS
BEGIN
    INSERT INTO LOSGDS.Localidad
    SELECT DISTINCT 
    p.id_provincia AS Provincia,
    Cliente_Localidad AS Localidad 
    FROM gd_esquema.Maestra 
    JOIN LOSGDS.Provincia p ON p.nombre = Cliente_Provincia
    WHERE NOT (Cliente_Provincia IS NULL AND Cliente_Localidad IS NULL)
    UNION
    SELECT DISTINCT 
    p.id_provincia AS Provincia,
    Proveedor_Localidad AS Localidad 
    FROM gd_esquema.Maestra 
    JOIN LOSGDS.Provincia p ON p.nombre = Proveedor_Provincia
    WHERE NOT (Proveedor_Localidad IS NULL AND Proveedor_Provincia IS NULL)
    UNION
    SELECT DISTINCT 
    p.id_provincia AS Provincia,
    Sucursal_Localidad AS Localidad
    FROM gd_esquema.Maestra 
    JOIN LOSGDS.Provincia p ON p.nombre = Sucursal_Provincia
    WHERE NOT(Sucursal_Localidad IS NULL AND Sucursal_Provincia IS NULL)
    ORDER BY p.id_provincia, Localidad
END
GO

CREATE PROCEDURE LOSGDS.MigrarDirecciones AS
BEGIN
        INSERT INTO LOSGDS.Direccion
        SELECT DISTINCT 
            l.id_localidad AS Localidad,
            Sucursal_Direccion AS Direccion
            FROM gd_esquema.Maestra
            LEFT JOIN LOSGDS.Provincia p ON Sucursal_Provincia = p.nombre
            LEFT JOIN LOSGDS.Localidad l ON Sucursal_Localidad = l.nombre and l.localidad_provincia = p.id_provincia
            WHERE NOT (Sucursal_Provincia IS NULL AND Sucursal_Localidad IS NULL)
        UNION
        SELECT DISTINCT 
            l.id_localidad AS Localidad,
            Cliente_Direccion AS Direccion
            FROM [gd_esquema].[Maestra]
            LEFT JOIN LOSGDS.Provincia p ON Cliente_Provincia = p.nombre
            LEFT JOIN LOSGDS.Localidad l ON Cliente_Localidad = l.nombre and l.localidad_provincia = p.id_provincia
            WHERE NOT (Cliente_Provincia IS NULL AND Cliente_Localidad IS NULL)
        UNION 
        SELECT DISTINCT 
            l.id_localidad AS Localidad,
            Proveedor_Direccion AS Direccion
            FROM [gd_esquema].[Maestra]
            LEFT JOIN LOSGDS.Provincia p ON p.nombre = Proveedor_Provincia
            LEFT JOIN LOSGDS.Localidad l ON l.nombre = Proveedor_Localidad and l.localidad_provincia = p.id_provincia
            WHERE NOT (Proveedor_Provincia IS NULL AND Proveedor_Localidad IS NULL)
            ORDER BY Localidad,Direccion
END
GO 



CREATE PROCEDURE LOSGDS.MigrarProveedor AS
BEGIN
    INSERT INTO LOSGDS.Proveedor
	SELECT DISTINCT
		d.id_direccion,
		m.Proveedor_RazonSocial,
		m.Proveedor_Cuit,
		m.Proveedor_Telefono,
		m.Proveedor_Mail
    FROM gd_esquema.Maestra m
    LEFT JOIN LOSGDS.Provincia p ON Proveedor_Provincia = p.nombre 
    LEFT JOIN LOSGDS.Localidad l ON Proveedor_Localidad = l.nombre AND l.localidad_provincia = p.id_provincia
    LEFT JOIN LOSGDS.Direccion d ON Proveedor_Direccion = d.nombre
    WHERE NOT (Proveedor_Provincia IS NULL 
            AND Proveedor_Localidad IS NULL 
            AND id_direccion IS NULL
            AND m.Proveedor_RazonSocial IS NULL
            AND m.Proveedor_Cuit IS NULL)
    ORDER BY d.id_direccion
END




---Migracion de datos---
BEGIN TRANSACTION
	EXECUTE LOSGDS.MigrarProvincias
    EXECUTE LOSGDS.MigrarLocalidades
    EXECUTE LOSGDS.MigrarDirecciones
	EXECUTE LOSGDS.MigrarProveedor
	EXECUTE LOSGDS.migrar_Sucursal
	EXECUTE LOSGDS.migrar_Compra
	--EXECUTE LOSGDS.migrar_Material
	EXECUTE LOSGDS.migrar_Detalle_Compra
	--EXECUTE LOSGDS.migrar_Modelo
	--EXECUTE LOSGDS.migrar_Medida
	--EXECUTE LOSGDS.migrar_Sillon
	--EXECUTE LOSGDS.migrar_Cliente
	--EXECUTE LOSGDS.migrar_Pedido
	EXECUTE LOSGDS.migrar_Detalle_Pedido
	EXECUTE LOSGDS.migrar_Cancelacion_Pedido
	--EXECUTE LOSGDS.migrar_Factura
	--EXECUTE LOSGDS.migrar_Envio
	--EXECUTE LOSGDS.migrar_Detalle_Factura
	--EXECUTE LOSGDS.migrar_SillonXMaterial
	--EXECUTE LOSGDS.migrar_Tela
	--EXECUTE LOSGDS.migrar_Relleno_Sillon
	--EXECUTE LOSGDS.migrar_Madera
COMMIT TRANSACTION


---Drop de procedures---
DROP PROCEDURE LOSGDS.MigrarProvincias
DROP PROCEDURE LOSGDS.MigrarLocalidades
DROP PROCEDURE LOSGDS.MigrarDirecciones
DROP PROCEDURE LOSGDS.MigrarProveedor
DROP PROCEDURE LOSGDS.migrar_Sucursal
DROP PROCEDURE LOSGDS.migrar_Compra
--DROP PROCEDURE LOSGDS.migrar_Material
DROP PROCEDURE LOSGDS.migrar_Detalle_Compra
--DROP PROCEDURE LOSGDS.migrar_Modelo
--DROP PROCEDURE LOSGDS.migrar_Medida
--DROP PROCEDURE LOSGDS.migrar_Sillon
--DROP PROCEDURE LOSGDS.migrar_Cliente
--DROP PROCEDURE LOSGDS.migrar_Pedido
DROP PROCEDURE LOSGDS.migrar_Detalle_Pedido
DROP PROCEDURE LOSGDS.migrar_Cancelacion_Pedido
--DROP PROCEDURE LOSGDS.migrar_Factura
--DROP PROCEDURE LOSGDS.migrar_Envio
--DROP PROCEDURE LOSGDS.migrar_Detalle_Factura
--DROP PROCEDURE LOSGDS.migrar_SillonXMaterial
--DROP PROCEDURE LOSGDS.migrar_Tela
--DROP PROCEDURE LOSGDS.migrar_Relleno_Sillon
--DROP PROCEDURE LOSGDS.migrar_Madera