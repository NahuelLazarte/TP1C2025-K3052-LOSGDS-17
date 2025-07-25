USE GD1C2025
GO

---CREACION DE SCHEMA---
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'LOSGDS')
BEGIN
    EXEC('CREATE SCHEMA LOSGDS')
END
GO

---DROP DE TABLAS---
IF OBJECT_ID('LOSGDS.SillonXMaterial', 'U') IS NOT NULL DROP TABLE LOSGDS.SillonXMaterial;
IF OBJECT_ID('LOSGDS.Detalle_Factura', 'U') IS NOT NULL DROP TABLE LOSGDS.Detalle_Factura;
IF OBJECT_ID('LOSGDS.Envio', 'U') IS NOT NULL DROP TABLE LOSGDS.Envio;
IF OBJECT_ID('LOSGDS.Factura', 'U') IS NOT NULL DROP TABLE LOSGDS.Factura;
IF OBJECT_ID('LOSGDS.Cancelacion_Pedido', 'U') IS NOT NULL DROP TABLE LOSGDS.Cancelacion_Pedido;
IF OBJECT_ID('LOSGDS.Detalle_Pedido', 'U') IS NOT NULL DROP TABLE LOSGDS.Detalle_Pedido;
IF OBJECT_ID('LOSGDS.Pedido', 'U') IS NOT NULL DROP TABLE LOSGDS.Pedido;
IF OBJECT_ID('LOSGDS.Cliente', 'U') IS NOT NULL DROP TABLE LOSGDS.Cliente;
IF OBJECT_ID('LOSGDS.Sillon', 'U') IS NOT NULL DROP TABLE LOSGDS.Sillon;
IF OBJECT_ID('LOSGDS.Medida', 'U') IS NOT NULL DROP TABLE LOSGDS.Medida;
IF OBJECT_ID('LOSGDS.Modelo', 'U') IS NOT NULL DROP TABLE LOSGDS.Modelo;
IF OBJECT_ID('LOSGDS.Relleno_Sillon', 'U') IS NOT NULL DROP TABLE LOSGDS.Relleno_Sillon;
IF OBJECT_ID('LOSGDS.Madera', 'U') IS NOT NULL DROP TABLE LOSGDS.Madera;
IF OBJECT_ID('LOSGDS.Tela', 'U') IS NOT NULL DROP TABLE LOSGDS.Tela;
IF OBJECT_ID('LOSGDS.Material', 'U') IS NOT NULL DROP TABLE LOSGDS.Material;
IF OBJECT_ID('LOSGDS.Detalle_Compra', 'U') IS NOT NULL DROP TABLE LOSGDS.Detalle_Compra;
IF OBJECT_ID('LOSGDS.Compra', 'U') IS NOT NULL DROP TABLE LOSGDS.Compra;
IF OBJECT_ID('LOSGDS.Proveedor', 'U') IS NOT NULL DROP TABLE LOSGDS.Proveedor;
IF OBJECT_ID('LOSGDS.Sucursal', 'U') IS NOT NULL DROP TABLE LOSGDS.Sucursal;
IF OBJECT_ID('LOSGDS.Direccion', 'U') IS NOT NULL DROP TABLE LOSGDS.Direccion;
IF OBJECT_ID('LOSGDS.Localidad', 'U') IS NOT NULL DROP TABLE LOSGDS.Localidad;
IF OBJECT_ID('LOSGDS.Provincia', 'U') IS NOT NULL DROP TABLE LOSGDS.Provincia;

CREATE TABLE LOSGDS.Provincia (
    id_provincia BIGINT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(255)
)

CREATE TABLE LOSGDS.Localidad (
    id_localidad BIGINT IDENTITY(1,1) PRIMARY KEY,
    localidad_provincia BIGINT NOT NULL,
    nombre NVARCHAR(255),
    CONSTRAINT fk_localidad_provincia FOREIGN KEY(localidad_provincia)
        REFERENCES LOSGDS.Provincia(id_provincia)
)

CREATE TABLE LOSGDS.Direccion (
    id_direccion BIGINT IDENTITY(1,1) PRIMARY KEY,
    direccion_localidad BIGINT NOT NULL,
    nombre NVARCHAR(255),
    CONSTRAINT fk_direccion_localidad FOREIGN KEY(direccion_localidad) 
        REFERENCES LOSGDS.Localidad(id_localidad)
)

CREATE TABLE LOSGDS.Proveedor (
    id_proveedor BIGINT IDENTITY(1,1) PRIMARY KEY,
    proveedor_direccion BIGINT NOT NULL,
    razon_social NVARCHAR(255),
    cuit NVARCHAR(255),
    telefono NVARCHAR(255),
    mail NVARCHAR(255),
    CONSTRAINT fk_proveedor_direccion FOREIGN KEY(proveedor_direccion) 
        REFERENCES LOSGDS.Direccion(id_direccion)
)

CREATE TABLE LOSGDS.Sucursal (
    id_sucursal BIGINT PRIMARY KEY, -- Viene de la tabla por eso no tiene IDENTITY
    sucursal_direccion BIGINT NOT NULL,
    mail NVARCHAR(255),
    telefono NVARCHAR(255),
    CONSTRAINT fk_sucursal_direccion FOREIGN KEY (sucursal_direccion) 
        REFERENCES LOSGDS.Direccion(id_direccion)
)

CREATE TABLE LOSGDS.Compra (
    id_compra BIGINT IDENTITY(1,1) PRIMARY KEY,
    numero_compra DECIMAL(18,0) NOT NULL,
    compra_sucursal BIGINT NOT NULL,
    compra_proveedor BIGINT NOT NULL,
    fecha DATETIME2(6),
    total DECIMAL(18,2),
    CONSTRAINT fk_compra_sucursal FOREIGN KEY (compra_sucursal) REFERENCES LOSGDS.Sucursal(id_sucursal),
    CONSTRAINT fk_compra_proveedor FOREIGN KEY (compra_proveedor) REFERENCES LOSGDS.Proveedor(id_proveedor)
)

-- Nahuel
CREATE TABLE LOSGDS.Material (
    id_material BIGINT IDENTITY(1,1) PRIMARY KEY,
    descripcion NVARCHAR(255),
    material_nombre NVARCHAR(255),
    precio DECIMAL(38,2),
    tipo NVARCHAR(255)
)

CREATE TABLE LOSGDS.Detalle_Compra (
    id_det_compra BIGINT IDENTITY(1,1) PRIMARY KEY,
    det_compra_compra BIGINT NOT NULL,
    detalle_material BIGINT NOT NULL,
    precio DECIMAL(18,2),
    cantidad DECIMAL(18,2),
    subtotal DECIMAL(18,2),
    CONSTRAINT fk_det_compra_compra FOREIGN KEY (det_compra_compra) REFERENCES LOSGDS.Compra(id_compra),
    CONSTRAINT fk_detalle_material FOREIGN KEY (detalle_material) REFERENCES LOSGDS.Material(id_material)
)

-- Nahuel
CREATE TABLE LOSGDS.Modelo (
    cod_modelo BIGINT PRIMARY KEY, -- Viene de la tabla por eso no tiene IDENTITY
    modelo NVARCHAR(255),
    descripcion NVARCHAR(255),
    precio DECIMAL(18,2)
)

-- Nahuel
CREATE TABLE LOSGDS.Medida (
    cod_medida BIGINT IDENTITY(1,1) PRIMARY KEY,
    alto DECIMAL(18,2),
    ancho DECIMAL(18,2),
    profundidad DECIMAL(18,2),
    precio DECIMAL(18,2)
)

-- Nahuel
CREATE TABLE LOSGDS.Sillon (
    cod_sillon BIGINT PRIMARY KEY, -- Viene de la tabla por eso no tiene IDENTITY
    sillon_modelo BIGINT NOT NULL,
    sillon_medida BIGINT NOT NULL,
    CONSTRAINT fk_sillon_modelo FOREIGN KEY (sillon_modelo) 
        REFERENCES LOSGDS.Modelo (cod_modelo),
    CONSTRAINT fk_sillon_medida FOREIGN KEY (sillon_medida) 
        REFERENCES LOSGDS.Medida (cod_medida)
)

CREATE TABLE LOSGDS.Cliente (
    id_cliente BIGINT IDENTITY(1,1) PRIMARY KEY,
    cliente_direccion BIGINT NOT NULL,
    dni BIGINT,
    nombre NVARCHAR(255),
    apellido NVARCHAR(255),
    fecha_nacimiento DATETIME2(6),
    mail NVARCHAR(255),
    telefono NVARCHAR(255),
    CONSTRAINT fk_cliente_direccion FOREIGN KEY (cliente_direccion)
        REFERENCES LOSGDS.Direccion(id_direccion)
)

CREATE TABLE LOSGDS.Pedido (
    id_pedido BIGINT IDENTITY(1,1) PRIMARY KEY,
    nro_pedido DECIMAL(18,0),
    pedido_sucursal BIGINT NOT NULL,
    pedido_cliente BIGINT NOT NULL,
    fecha DATETIME2(6),
    total DECIMAL(18,2),
    estado NVARCHAR(255),
    cancelacion_fecha DATETIME2(6),
    cancelacion_motivo NVARCHAR(255),
    CONSTRAINT fk_pedido_sucursal FOREIGN KEY (pedido_sucursal)
        REFERENCES LOSGDS.Sucursal(id_sucursal),
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (pedido_cliente)
        REFERENCES LOSGDS.Cliente(id_cliente)
)

CREATE TABLE LOSGDS.Detalle_Pedido (
    id_det_pedido BIGINT IDENTITY(1,1) PRIMARY KEY,
    det_ped_sillon BIGINT NOT NULL,
    det_ped_pedido BIGINT NOT NULL,
    cantidad BIGINT,
    precio DECIMAL(18,2),
    subtotal DECIMAL(18,2),
    CONSTRAINT fk_det_ped_sillon FOREIGN KEY (det_ped_sillon) REFERENCES LOSGDS.Sillon(cod_sillon),
    CONSTRAINT fk_det_ped_pedido FOREIGN KEY (det_ped_pedido) REFERENCES LOSGDS.Pedido(id_pedido)
)

CREATE TABLE LOSGDS.Cancelacion_Pedido (
    id_cancel_pedido BIGINT IDENTITY(1,1) PRIMARY KEY,
    cancel_ped_pedido BIGINT NOT NULL,
    fecha DATETIME2(6),
    motivo NVARCHAR(255),
    CONSTRAINT fk_cancel_ped_pedido FOREIGN KEY (cancel_ped_pedido) REFERENCES LOSGDS.Pedido(id_pedido)
)

CREATE TABLE LOSGDS.Factura (
    id_factura BIGINT IDENTITY(1,1) PRIMARY KEY,
    fact_cliente BIGINT NOT NULL,
    fact_sucursal BIGINT NOT NULL,
    fact_numero BIGINT NOT NULL,
    fecha DATETIME2(6),
    total DECIMAL(38,2),
    CONSTRAINT fk_fact_cliente FOREIGN KEY (fact_cliente)
        REFERENCES LOSGDS.Cliente(id_cliente),
    CONSTRAINT fk_fact_sucursal FOREIGN KEY (fact_sucursal)
        REFERENCES LOSGDS.Sucursal(id_sucursal)
)

CREATE TABLE LOSGDS.Envio (
    envio_nro BIGINT IDENTITY(1,1) PRIMARY KEY,
    numero DECIMAL(18,0),
    envio_factura BIGINT NOT NULL,
    fecha_programada DATETIME2(6),
    fecha DATETIME2(6),
    importe_traslado DECIMAL(18,2),
    importe_subida DECIMAL(18,2),
    total DECIMAL(18,2),
    CONSTRAINT fk_envio_factura FOREIGN KEY (envio_factura)
        REFERENCES LOSGDS.Factura(id_factura)
)

CREATE TABLE LOSGDS.Detalle_Factura (
    id_det_fact BIGINT IDENTITY(1,1) PRIMARY KEY,
    det_fact_factura BIGINT NOT NULL,
    det_fact_det_pedido BIGINT NOT NULL,
    precio DECIMAL(18,2),
    cantidad DECIMAL(18,0),
    subtotal DECIMAL(18,2),
    CONSTRAINT fk_det_fact_factura FOREIGN KEY (det_fact_factura)
        REFERENCES LOSGDS.Factura(id_factura),
    CONSTRAINT fk_det_fact_det_pedido FOREIGN KEY (det_fact_det_pedido)
        REFERENCES LOSGDS.Detalle_Pedido(id_det_pedido)
)

-- Nahuel
CREATE TABLE LOSGDS.SillonXMaterial (
    cod_sillon BIGINT NOT NULL,
    id_material BIGINT NOT NULL,
    PRIMARY KEY (cod_sillon, id_material),
    CONSTRAINT fk_cod_sillon FOREIGN KEY (cod_sillon) 
        REFERENCES LOSGDS.Sillon (cod_sillon),
    CONSTRAINT fk_id_material FOREIGN KEY (id_material) 
        REFERENCES LOSGDS.Material (id_material)
)

-- Nahuel
CREATE TABLE LOSGDS.Tela (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    color NVARCHAR(255),
    textura NVARCHAR(255),
    tela_material BIGINT NOT NULL,
    CONSTRAINT fk_tela_material FOREIGN KEY (tela_material) 
        REFERENCES LOSGDS.Material (id_material)
)

-- Nahuel
CREATE TABLE LOSGDS.Relleno_Sillon (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    densidad DECIMAL(38,2),
    relleno_material BIGINT NOT NULL,
    CONSTRAINT fk_relleno_material FOREIGN KEY (relleno_material) 
        REFERENCES LOSGDS.Material (id_material)
)

-- Nahuel
CREATE TABLE LOSGDS.Madera (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    color NVARCHAR(255),
    dureza NVARCHAR(255),
    madera_material BIGINT NOT NULL,
    CONSTRAINT fk_madera_material FOREIGN KEY (madera_material) 
        REFERENCES LOSGDS.Material (id_material)
)
