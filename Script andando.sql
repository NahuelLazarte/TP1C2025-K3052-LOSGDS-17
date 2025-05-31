CREATE PROCEDURE LOSGDS.MigrarProvincias AS --1
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


--pk provincias
SELECT DISTINCT Sucursal_Provincia AS Provincia 
	FROM gd_esquema.Maestra WHERE Sucursal_Provincia IS NOT NULL
	UNION
	SELECT DISTINCT Cliente_Provincia AS Provincia 
	FROM gd_esquema.Maestra WHERE Cliente_Provincia IS NOT NULL
	UNION
	SELECT DISTINCT Proveedor_Provincia AS Provincia 
	FROM gd_esquema.Maestra WHERE Proveedor_Provincia IS NOT NULL
	ORDER BY Provincia

--24 ok
---------------
CREATE PROCEDURE LOSGDS.MigrarLocalidades AS --2
BEGIN
	INSERT INTO LOSGDS.Localidad
	SELECT DISTINCT 
	p.id_provincia AS Provincia,
	Cliente_Localidad AS Localidad 
	FROM gd_esquema.Maestra 
	left JOIN LOSGDS.Provincia p ON Cliente_Provincia = p.nombre 
	left join LOSGDS.Localidad l ON Cliente_Localidad = l.nombre
	WHERE Cliente_Provincia IS NOT NULL AND Cliente_Localidad IS NOT NULL
	UNION
	SELECT DISTINCT 
	p.id_provincia AS Provincia,
	Proveedor_Localidad AS Localidad 
	FROM gd_esquema.Maestra 
	left JOIN LOSGDS.Provincia p ON Proveedor_Provincia = p.nombre
	left join LOSGDS.Localidad l ON Proveedor_Localidad = l.nombre
	WHERE Proveedor_Localidad IS NOT NULL AND Proveedor_Provincia IS NOT NULL
	UNION
	SELECT DISTINCT 
	p.id_provincia AS Provincia,
	Sucursal_Localidad AS Localidad	
	FROM gd_esquema.Maestra 
	left JOIN LOSGDS.Provincia p ON Sucursal_Provincia = p.nombre 
	left join LOSGDS.Localidad l ON Sucursal_Localidad = l.nombre
	WHERE Sucursal_Localidad IS NOT NULL AND Sucursal_Provincia IS NOT NULL
	ORDER BY Provincia,Localidad
END
GO


--SELECT PARTICULAR lOCALIDAD
select distinct Cliente_Localidad as Localidad--,
from gd_esquema.Maestra
UNION
select distinct Proveedor_Localidad as Localidad--,
from gd_esquema.Maestra
UNION
select distinct Sucursal_Localidad as Localidad--,
from gd_esquema.Maestra
ORDER BY Localidad
--0K
--12268
---------------------


--DIRECCIONES
CREATE PROCEDURE LOSGDS.MigrarDirecciones AS --3
BEGIN
		INSERT INTO LOSGDS.Direccion
		SELECT DISTINCT 
			l.id_localidad AS Localidad,
			Sucursal_Direccion AS Direccion
			FROM gd_esquema.Maestra
			left JOIN LOSGDS.Provincia p ON Sucursal_Provincia = p.nombre
			left JOIN LOSGDS.Localidad l ON Sucursal_Localidad = l.nombre and l.localidad_provincia = p.id_provincia
			WHERE 
			Sucursal_Direccion IS NOT NULL 
			AND Sucursal_Provincia IS NOT NULL 
			AND Sucursal_Localidad IS NOT NULL
		UNION
		SELECT DISTINCT 
			l.id_localidad AS Localidad,
			Cliente_Direccion AS Direccion
			FROM [gd_esquema].[Maestra]
			left JOIN LOSGDS.Provincia p ON Cliente_Provincia = p.nombre
			left JOIN LOSGDS.Localidad l ON Cliente_Localidad = l.nombre and l.localidad_provincia = p.id_provincia
			WHERE Cliente_Direccion IS NOT NULL 
			AND Sucursal_Provincia IS NOT NULL 
			AND Sucursal_Localidad IS NOT NULL
		UNION 
		SELECT DISTINCT 
			l.id_localidad AS Localidad,
			Proveedor_Direccion AS Direccion
			FROM [gd_esquema].[Maestra]
			left JOIN LOSGDS.Provincia p ON p.nombre = Proveedor_Provincia
			left JOIN LOSGDS.Localidad l ON l.nombre = Proveedor_Localidad and l.localidad_provincia = p.id_provincia
			WHERE Proveedor_Direccion IS NOT NULL 
			AND Sucursal_Provincia IS NOT NULL 
			AND Sucursal_Localidad IS NOT NULL
			ORDER BY Localidad,Direccion
END
GO 
--20269 ok

--SELECT DE LA MAESTRA DIRECCION
select distinct Cliente_Direccion AS Direccion
from gd_esquema.Maestra
WHERE Cliente_Direccion IS NOT NULL
UNION
select distinct Proveedor_Direccion  AS Direccion
from gd_esquema.Maestra
WHERE Proveedor_Direccion IS NOT NULL
UNION
select distinct Sucursal_Direccion  AS Direccion
from gd_esquema.Maestra
WHERE Sucursal_Direccion IS NOT NULL
ORDER BY Direccion
--20269 OK

----------
CREATE PROCEDURE LOSGDS.MigrarProveedor AS --4
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
	WHERE m.Proveedor_RazonSocial IS NOT NULL
	AND m.Proveedor_Cuit IS NOT NULL
	AND NOT(Proveedor_Provincia IS NULL 
			AND Proveedor_Localidad IS NULL 
			AND id_direccion IS NULL)
	ORDER BY id_direccion 
END
GO --ok

--SELECT DE LA MAESTRA PROVEEDOR
select distinct 
Proveedor_RazonSocial,
Proveedor_Cuit,
Proveedor_Telefono,
Proveedor_Mail
from gd_esquema.Maestra
WHERE Proveedor_RazonSocial IS NOT NULL AND
Proveedor_Cuit IS NOT NULL AND
Proveedor_Telefono IS NOT NULL AND
Proveedor_Mail IS NOT NULL

--OK 10
----------------------

CREATE PROCEDURE LOSGDS.migrar_Compra AS --5
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
        END AS Total
    FROM gd_esquema.Maestra m
    LEFT JOIN LOSGDS.Sucursal s ON s.mail = m.Sucursal_mail
	AND s.telefono = m.Sucursal_telefono and s.nro_sucursal = Sucursal_NroSucursal
    LEFT JOIN LOSGDS.Proveedor p ON p.cuit = m.Proveedor_Cuit 
	AND Proveedor_RazonSocial = p.razon_social
	WHERE m.Sucursal_mail IS NOT NULL AND m.Sucursal_telefono IS NOT NULL
	AND Sucursal_NroSucursal IS NOT NULL AND M.Compra_Fecha IS NOT NULL 
	AND m.Compra_Total IS NOT NULL;
END;
GO--ok 79

--SELECT DE LA MAESTRA Compra
select distinct 
Compra_Numero,
Compra_Fecha,
 CASE 
            WHEN Compra_Total < 0 THEN NULL 
            ELSE Compra_Total 
        END
from gd_esquema.Maestra
WHERE Compra_Numero IS NOT NULL AND
Compra_Fecha IS NOT NULL AND
Compra_Total IS NOT NULL

--79 ok
-----
CREATE PROCEDURE LOSGDS.migrar_Detalle_Compra AS --6
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
    LEFT JOIN LOSGDS.Compra c ON c.numero_compra = m.Compra_Numero
	AND m.Compra_Fecha = c.fecha AND m.Compra_Total = c.total
    LEFT JOIN LOSGDS.Material mat ON m.Material_Descripcion = mat.descripcion
	AND mat.material_nombre = m.Material_Nombre 
	AND mat.tipo = m.Material_Tipo
	WHERE m.Compra_Numero IS NOT NULL AND m.Material_Nombre IS NOT NULL
END;
GO --404

--SELECT DE LA MAESTRA det_compra
select distinct 
Detalle_Compra_Precio,
Detalle_Compra_Cantidad,
Detalle_Compra_SubTotal
from gd_esquema.Maestra
WHERE Detalle_Compra_Precio IS NOT NULL AND
Detalle_Compra_Cantidad IS NOT NULL AND
Detalle_Compra_SubTotal IS NOT NULL
-- 404


-------------------------------------
CREATE PROCEDURE LOSGDS.migrar_Material AS --7
BEGIN
    INSERT INTO LOSGDS.Material (descripcion, material_nombre, precio, tipo)
    SELECT DISTINCT
        Material_Descripcion, 
        Material_Nombre,
        Material_Precio,
        Material_Tipo
    FROM gd_esquema.Maestra
    WHERE Material_Descripcion IS NOT NULL AND
	Material_Nombre IS NOT NULL AND
	Material_Precio IS NOT NULL AND
	Material_Tipo IS NOT NULL
END;
GO
--OK9

--SELECT DE LA MAESTRA Material
select distinct 
Material_Descripcion,
Material_Nombre,
Material_Precio,
Material_Tipo
from gd_esquema.Maestra
WHERE Material_Descripcion IS NOT NULL AND
Material_Nombre IS NOT NULL AND
Material_Precio IS NOT NULL AND
Material_Tipo is not null
------------------- OK 9

CREATE PROCEDURE LOSGDS.migrar_Tela AS --8
BEGIN
    INSERT INTO LOSGDS.Tela (color, textura, tela_material)
    SELECT DISTINCT 
        m.Tela_Color,
        m.Tela_Textura,
        mat.id_material
    FROM GD1C2025.gd_esquema.Maestra m
    LEFT JOIN LOSGDS.Material mat
        ON mat.tipo = m.Material_Tipo
        AND mat.material_nombre = m.Material_Nombre
        AND mat.descripcion = m.Material_Descripcion
        AND mat.precio = m.Material_Precio
    WHERE m.Material_Tipo = 'Tela';
END;
GO

--
--SELECT DE LA MAESTRA Tela
select distinct 
Tela_Color,
Tela_Textura
from gd_esquema.Maestra
WHERE Tela_Textura IS NOT  NULL AND
Tela_Color IS NOT NULL
--ok 3
----------------

CREATE PROCEDURE LOSGDS.migrar_Madera AS --9
BEGIN
    INSERT INTO LOSGDS.Madera (color, dureza, madera_material)
    SELECT DISTINCT 
        m.Madera_Color,
        m.Madera_Dureza,
        mat.id_material
    FROM GD1C2025.gd_esquema.Maestra m
    LEFT JOIN LOSGDS.Material mat ON mat.tipo = m.Material_Tipo
        AND mat.material_nombre = m.Material_Nombre
        AND mat.descripcion = m.Material_Descripcion
        AND mat.precio = m.Material_Precio
--ver pdf
END;
GO --ok 2

--SELECT DE LA MAESTRA madera
select distinct
Madera_Color,
Madera_Dureza
from gd_esquema.Maestra
--ok 2
--------------------

CREATE PROCEDURE LOSGDS.migrar_Relleno_Sillon AS --10
BEGIN
    INSERT INTO LOSGDS.Relleno_Sillon (densidad, relleno_material)
    SELECT DISTINCT 
        m.Relleno_Densidad,
        mat.id_material
    FROM GD1C2025.gd_esquema.Maestra m
    left JOIN LOSGDS.Material mat
        ON mat.tipo = m.Material_Tipo
        AND mat.material_nombre = m.Material_Nombre
        AND mat.descripcion = m.Material_Descripcion
        AND mat.precio = m.Material_Precio
END;
GO
--4 ok
--SELECT DE LA MAESTRA relleson sillon
select distinct
Relleno_Densidad
from gd_esquema.Maestra
--4


DROP PROCEDURE LOSGDS.migrar_Detalle_Factura
CREATE PROCEDURE LOSGDS.migrar_Detalle_Factura AS
BEGIN
    INSERT INTO LOSGDS.Detalle_Factura (det_fact_factura, det_fact_det_pedido, precio, cantidad, subtotal)
    SELECT DISTINCT                
        f.id_factura,                      
        dp.id_det_pedido,                 
        m.Detalle_Pedido_Precio,           
        m.Detalle_Pedido_Cantidad,         
        m.Detalle_Pedido_SubTotal          
    FROM GD1C2025.gd_esquema.Maestra m
	JOIN LOSGDS.Pedido p ON p.nro_pedido = m.Pedido_Numero
    JOIN LOSGDS.Detalle_Pedido dp ON p.id_pedido = dp.id_det_pedido	
    JOIN LOSGDS.Factura f
        ON f.fact_numero = m.Factura_Numero
        --AND f.fecha = m.Factura_Fecha
	WHERE Detalle_Factura_Precio IS NOT NULL AND
	Detalle_Factura_Cantidad IS NOT NULL AND
	Detalle_Factura_SubTotal IS NOT NULL
END;
GO
--840
--SELECT DE LA MAESTRA detalle factura
select distinct 
Detalle_Factura_Precio,
Detalle_Factura_Cantidad,
Detalle_Factura_SubTotal
from gd_esquema.Maestra
WHERE Detalle_Factura_Precio IS NOT NULL AND
Detalle_Factura_Cantidad IS NOT NULL AND
Detalle_Factura_SubTotal IS NOT NULL
--840

----------------------
CREATE PROCEDURE LOSGDS.migrar_Sillon AS --12
BEGIN
    INSERT INTO LOSGDS.Sillon (cod_sillon, sillon_modelo, sillon_medida)
    SELECT DISTINCT
        m.Sillon_Codigo,
        m.Sillon_Modelo_Codigo,
        med.cod_medida
    FROM gd_esquema.Maestra m
    left JOIN LOSGDS.Medida med
        ON med.alto = m.Sillon_Medida_Alto
        AND med.ancho = m.Sillon_Medida_Ancho
        AND med.profundidad = m.Sillon_Medida_Profundidad
        AND med.precio = m.Sillon_Medida_Precio
    WHERE m.Sillon_Codigo IS NOT NULL
END;
GO --ok

--SELECT DE LA MAESTRA Sillon
select distinct 
Detalle_Factura_Precio,
Detalle_Factura_Cantidad,
Detalle_Factura_SubTotal
from gd_esquema.Maestra
WHERE Detalle_Factura_Precio IS NOT NULL AND
Detalle_Factura_Cantidad IS NOT NULL AND
Detalle_Factura_SubTotal IS NOT NULL
--840


---------------
--medida
CREATE PROCEDURE LOSGDS.migrar_Medida AS --13
BEGIN
    INSERT INTO LOSGDS.Medida 
        (alto, ancho, profundidad, precio)
    SELECT DISTINCT
        Sillon_Medida_Alto, 
        Sillon_Medida_Ancho,
        Sillon_Medida_Profundidad,
        Sillon_Medida_Precio
    FROM gd_esquema.Maestra
    WHERE Sillon_Codigo IS NOT NULL
END;
GO --OK


--SELECT DE LA MAESTRA medida
select distinct 
Sillon_Medida_Alto,
Sillon_Medida_Ancho,
Sillon_Medida_Profundidad,
Sillon_Medida_Precio
from gd_esquema.Maestra
--ver pdf si es IS ES CON NULL
----------------------
--modelo

CREATE PROCEDURE LOSGDS.migrar_Modelo AS --14
BEGIN
    INSERT INTO LOSGDS.Modelo 
        (cod_modelo, modelo, descripcion, precio)
    SELECT DISTINCT
        Sillon_Modelo_Codigo,
        Sillon_Modelo, 
        Sillon_Modelo_Descripcion,
        Sillon_Modelo_Precio
    FROM gd_esquema.Maestra
    WHERE Sillon_Modelo_Codigo IS NOT NULL
END;
GO--ok

-------------------------
--ENVIO
CREATE PROCEDURE LOSGDS.MigrarEnvio --15
AS
BEGIN
    INSERT INTO LOSGDS.Envio
    SELECT
        m.Envio_Numero,
        f.id_factura,
        m.Envio_Fecha_Programada,
        m.Envio_Fecha,
        m.Envio_ImporteTraslado,
        m.Envio_ImporteSubida,
        m.Envio_Total
    FROM gd_esquema.Maestra m
    LEFT JOIN LOSGDS.Factura f ON m.Factura_Numero = f.fact_numero
    WHERE m.Envio_Numero IS NOT NULL AND m.Factura_Numero IS NOT NULL
END
GO
--OK


--SELECT DE LA MAESTRA Envio
---------------------


select * from gd_esquema.Maestra

-------------------
CREATE PROCEDURE LOSGDS.migrar_Pedido AS --16
BEGIN
    INSERT INTO LOSGDS.Pedido 
        (pedido_sucursal, pedido_cliente, nro_pedido, fecha, total, estado)
    SELECT DISTINCT
        s.id_sucursal,
        c.id_cliente,
        m.Pedido_Numero,
        m.Pedido_Fecha,
        m.Pedido_Total,
        m.Pedido_Estado
    FROM gd_esquema.Maestra m
    LEFT JOIN LOSGDS.Sucursal s ON s.nro_sucursal = m.Sucursal_NroSucursal
	AND s.mail = m.Sucursal_mail
    LEFT JOIN LOSGDS.Cliente c ON  c.nombre = m.Cliente_Nombre and c.dni = m.Cliente_Dni
    WHERE m.Sucursal_NroSucursal IS NOT NULL 
	AND c.id_cliente is not null and
	m.Pedido_Numero IS NOT NULL AND
        m.Pedido_Total IS NOT NULL AND
        m.Pedido_Estado IS NOT NULL 
	END --esta bien?
GO



CREATE PROCEDURE LOSGDS.MigrarCliente AS -- 17 | Bien | 20509
BEGIN
    INSERT INTO LOSGDS.Cliente
    SELECT DISTINCT
        d.id_direccion,
        m.Cliente_Dni,
        m.Cliente_Nombre,
        m.Cliente_Apellido,
        m.Cliente_FechaNacimiento,
        m.Cliente_Mail,
        m.Cliente_Telefono
    FROM gd_esquema.Maestra m
    LEFT JOIN LOSGDS.Provincia p ON Cliente_Provincia = p.nombre 
    LEFT JOIN LOSGDS.Localidad l ON Cliente_Localidad  = l.nombre AND l.localidad_provincia = p.id_provincia
    LEFT JOIN LOSGDS.Direccion d ON Cliente_Direccion = d.nombre--ESTE ES EL PROBLEMA QUE COMPARA BIGITN CON ID DIRECCION
    WHERE m.Cliente_Provincia IS NOT NULL
    AND m.Cliente_Localidad IS NOT NULL
    AND Cliente_Direccion IS NOT NULL 
    ORDER BY id_direccion 
END
GO




-- Procedimiento para migrar sillones (modificado para usar JOIN con Medida)
CREATE PROCEDURE LOSGDS.migrar_Sillon AS --18
BEGIN
    INSERT INTO LOSGDS.Sillon (cod_sillon, sillon_modelo, sillon_medida)
    SELECT DISTINCT
        m.Sillon_Codigo,
        m.Sillon_Modelo_Codigo,
        med.cod_medida
    FROM gd_esquema.Maestra m
    INNER JOIN LOSGDS.Medida med
        ON med.alto = m.Sillon_Medida_Alto
        AND med.ancho = m.Sillon_Medida_Ancho
        AND med.profundidad = m.Sillon_Medida_Profundidad
        AND med.precio = m.Sillon_Medida_Precio
    WHERE m.Sillon_Codigo IS NOT NULL
END;
GO

CREATE PROCEDURE LOSGDS.migrar_SillonXMaterial AS --19
BEGIN
    INSERT INTO LOSGDS.SillonXMaterial (cod_sillon, id_material)
    SELECT DISTINCT
        s.cod_sillon,
        mat.id_material
    FROM gd_esquema.Maestra m
	INNER JOIN LOSGDS.Sillon s
		ON s.cod_sillon = m.Sillon_Codigo
    INNER JOIN LOSGDS.Material mat
        ON mat.tipo = m.Material_Tipo
        AND mat.material_nombre = m.Material_Nombre
        AND mat.descripcion = m.Material_Descripcion
        AND mat.precio = m.Material_Precio
    WHERE m.Sillon_Codigo IS NOT NULL;
END;
GO

CREATE PROCEDURE LOSGDS.migrar_Sucursal AS --20
BEGIN
    INSERT INTO LOSGDS.Sucursal 
        (nro_sucursal, sucursal_direccion, mail, telefono)
    SELECT DISTINCT
        m.Sucursal_NroSucursal,
        d.id_direccion,
        m.Sucursal_mail,
        m.Sucursal_telefono
    FROM gd_esquema.Maestra m
    LEFT JOIN LOSGDS.Direccion d ON d.nombre = m.Sucursal_Direccion
	WHERE d.id_direccion IS NOT NULL AND m.Sucursal_NroSucursal IS NOT NULL AND m.Sucursal_Direccion IS NOT NULL;
END;
GO

 
CREATE PROCEDURE LOSGDS.MigrarFactura AS -- 21 | Bien | 17408
BEGIN
    INSERT INTO LOSGDS.Factura
		(fact_cliente,fact_sucursal, fact_numero, fecha, total)
    SELECT DISTINCT
        c.id_cliente,
        s.id_sucursal,
        m.Factura_Numero,
        m.Factura_Fecha,
        m.Factura_Total
    FROM gd_esquema.Maestra m
    LEFT JOIN LOSGDS.Sucursal s ON Sucursal_NroSucursal = s.nro_sucursal
    LEFT JOIN LOSGDS.Cliente c ON Cliente_Dni = c.dni AND Cliente_Apellido = c.apellido 
    AND Cliente_Nombre =c.nombre and Cliente_FechaNacimiento = c.fecha_nacimiento
    WHERE Cliente_Dni IS NOT NULL AND m.Sucursal_NroSucursal IS NOT NULL
    AND Cliente_Apellido IS NOT NULL
    AND Cliente_Nombre IS NOT NULL 
	AND m.Factura_Numero IS NOT NULL
    AND Cliente_FechaNacimiento IS NOT NULL 
END
GO

CREATE PROCEDURE LOSGDS.migrar_Cancelacion_Pedido AS -- 22 | Bien | 1925
BEGIN
    INSERT INTO LOSGDS.Cancelacion_Pedido 
        (cancel_ped_pedido, fecha, motivo)
    SELECT DISTINCT
        p.id_pedido,
        m.Pedido_Cancelacion_Fecha,
        m.Pedido_Cancelacion_Motivo
    FROM gd_esquema.Maestra m
    LEFT JOIN LOSGDS.Pedido p ON p.nro_pedido = m.Pedido_Numero
    WHERE m.Pedido_Cancelacion_Fecha IS NOT NULL AND m.Pedido_Cancelacion_Motivo IS NOT NULL;
END;
GO

DROP PROCEDURE LOSGDS.migrar_Detalle_Pedido
CREATE PROCEDURE LOSGDS.migrar_Detalle_Pedido AS --23
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
    LEFT JOIN LOSGDS.Sillon s ON s.cod_sillon = m.Sillon_Codigo
    LEFT JOIN LOSGDS.Pedido p ON p.nro_pedido = m.Pedido_Numero
	WHERE s.cod_sillon IS NOT NULL AND p.id_pedido IS NOT NULL 
		AND m.Pedido_Numero IS NOT NULL AND m.Sillon_Modelo_Codigo IS NOT NULL
END;
GO

--- MIGRAR PEDIDO
 SELECT DISTINCT
        m.Pedido_Numero,
        m.Pedido_Fecha,
        m.Pedido_Total,
        m.Pedido_Estado
    FROM gd_esquema.Maestra m
    WHERE 
	 m.Pedido_Numero IS NOT NULL and
        m.Pedido_Fecha IS NOT NULL and
        m.Pedido_Total IS NOT NULL and
        m.Pedido_Estado IS NOT NULL
--20509

--------------------





BEGIN TRANSACTION
    EXECUTE LOSGDS.MigrarProvincias -- 24
    EXECUTE LOSGDS.MigrarLocalidades -- 24536
    EXECUTE LOSGDS.MigrarDirecciones -- 41056
    EXECUTE LOSGDS.migrar_Modelo -- 7
	EXECUTE LOSGDS.migrar_Medida -- 4
	EXECUTE LOSGDS.migrar_Sillon --72166
	EXECUTE LOSGDS.migrar_Material -- 9 
    EXECUTE LOSGDS.migrar_Tela -- 3
	EXECUTE LOSGDS.migrar_Madera -- 10
	EXECUTE LOSGDS.migrar_Relleno_Sillon -- 10
	EXECUTE LOSGDS.migrar_SillonXMaterial -- 216498 | Deberia ser estimado 649,494 ?
	EXECUTE LOSGDS.MigrarCliente -- 42066
    EXECUTE LOSGDS.migrar_Sucursal -- 18
    EXECUTE LOSGDS.MigrarFactura -- 71408
    EXECUTE LOSGDS.MigrarEnvio -- 71408
    EXECUTE LOSGDS.migrar_Pedido -- 84132 
    EXECUTE LOSGDS.migrar_Cancelacion_Pedido -- 12724
    EXECUTE LOSGDS.migrar_Detalle_Pedido -- 296076
    EXECUTE LOSGDS.migrar_Detalle_Factura -- 2105600 ROWS
	EXECUTE LOSGDS.MigrarProveedor -- 20
    EXECUTE LOSGDS.migrar_Compra -- 316
	EXECUTE LOSGDS.migrar_Detalle_Compra --2844
COMMIT TRANSACTION



---Drop de procedures---
DROP PROCEDURE LOSGDS.MigrarProvincias
DROP PROCEDURE LOSGDS.MigrarLocalidades
DROP PROCEDURE LOSGDS.MigrarDirecciones
DROP PROCEDURE LOSGDS.MigrarProveedor
DROP PROCEDURE LOSGDS.migrar_Modelo
DROP PROCEDURE LOSGDS.migrar_Medida
DROP PROCEDURE LOSGDS.migrar_Sillon
DROP PROCEDURE LOSGDS.migrar_Material
DROP PROCEDURE LOSGDS.migrar_Tela
DROP PROCEDURE LOSGDS.migrar_Madera
DROP PROCEDURE LOSGDS.migrar_Relleno_Sillon
DROP PROCEDURE LOSGDS.migrar_SillonXMaterial
DROP PROCEDURE LOSGDS.migrar_Detalle_Factura
DROP PROCEDURE LOSGDS.migrar_Sucursal
DROP PROCEDURE LOSGDS.migrar_Compra
DROP PROCEDURE LOSGDS.migrar_Detalle_Compra
DROP PROCEDURE LOSGDS.migrar_Detalle_Pedido
DROP PROCEDURE LOSGDS.migrar_Cancelacion_Pedido
DROP PROCEDURE LOSGDS.MigrarFactura
DROP PROCEDURE LOSGDS.MigrarCliente
DROP PROCEDURE LOSGDS.migrar_Pedido
DROP PROCEDURE LOSGDS.MigrarEnvio



