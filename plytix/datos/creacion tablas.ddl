-- Generado por Oracle SQL Developer Data Modeler 23.1.0.087.0806
--   en:        2025-04-02 09:30:42 CEST
--   sitio:      Oracle Database 11g
--   tipo:      Oracle Database 11g



-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE

CREATE TABLE activos (
    actid           VARCHAR2(15 CHAR) NOT NULL,
    actnombre       VARCHAR2(15 CHAR) NOT NULL,
    tam             VARCHAR2(15 CHAR) NOT NULL,
    acttipo         VARCHAR2(15 CHAR),
    url             VARCHAR2(15 CHAR),
    cuenta_cuentaid VARCHAR2(15 CHAR) NOT NULL
);

ALTER TABLE activos ADD CONSTRAINT activos_pk PRIMARY KEY ( actid,
                                                            cuenta_cuentaid );

CREATE TABLE atributos (
    atributosid     VARCHAR2(15 CHAR) NOT NULL,
    atributosnombre VARCHAR2(15 CHAR) NOT NULL,
    atributostipo   VARCHAR2(15 CHAR),
    creado          VARCHAR2(15 CHAR) NOT NULL,
    cuenta_cuentaid VARCHAR2(15 CHAR)
);

ALTER TABLE atributos ADD CONSTRAINT atributos_pk PRIMARY KEY ( atributosid );

CREATE TABLE atributos_producto (
    valor                    VARCHAR2(15 CHAR) NOT NULL,
    producto_gtin            VARCHAR2(15 CHAR) NOT NULL,
    producto_cuenta_cuentaid VARCHAR2(15 CHAR) NOT NULL,
    atributos_atributosid    VARCHAR2(15 CHAR) NOT NULL
);

ALTER TABLE atributos_producto
    ADD CONSTRAINT atributos_producto_pk PRIMARY KEY ( producto_gtin,
                                                       producto_cuenta_cuentaid,
                                                       atributos_atributosid );

CREATE TABLE categoria (
    categoriaid     VARCHAR2(15 CHAR) NOT NULL,
    categorianombre VARCHAR2(15 CHAR) NOT NULL,
    cuenta_cuentaid VARCHAR2(15 CHAR) NOT NULL
);

ALTER TABLE categoria ADD CONSTRAINT categoria_pk PRIMARY KEY ( categoriaid,
                                                                cuenta_cuentaid );

CREATE TABLE categoria_activos (
    caid            VARCHAR2(15 CHAR) NOT NULL,
    nombreca        VARCHAR2(15 CHAR) NOT NULL,
    cuenta_cuentaid VARCHAR2(15 CHAR) NOT NULL
);

ALTER TABLE categoria_activos ADD CONSTRAINT categoria_activos_pk PRIMARY KEY ( cuenta_cuentaid,
                                                                                caid );

CREATE TABLE cuenta (
    cid                      VARCHAR2(15 CHAR) NOT NULL,
    nombrec                  VARCHAR2(15 CHAR) NOT NULL,
    dirfiscal                VARCHAR2(15 CHAR) NOT NULL,
    nifcuenta                VARCHAR2(15 CHAR) NOT NULL,
    fechaalta                DATE,
    usuario_usid             VARCHAR2(15 CHAR),
    plan_planid              VARCHAR2(15 CHAR) NOT NULL,
    usuario_cuenta_cuentaid2 VARCHAR2(15 CHAR)
);

CREATE UNIQUE INDEX cuenta__idx ON
    cuenta (
        usuario_usid
    ASC,
        usuario_cuenta_cuentaid2
    ASC );

ALTER TABLE cuenta ADD CONSTRAINT cuenta_pk PRIMARY KEY ( cid );

CREATE TABLE plan (
    planid             VARCHAR2(15 CHAR) NOT NULL,
    productos          VARCHAR2(15 CHAR) NOT NULL,
    activos            VARCHAR2(15 CHAR) NOT NULL,
    almacenamiento     VARCHAR2(15 CHAR) NOT NULL,
    categoriasproducto VARCHAR2(15 CHAR) NOT NULL,
    categoriasactivos  VARCHAR2(15 CHAR) NOT NULL,
    relaciones         VARCHAR2(15 CHAR) NOT NULL,
    precio             VARCHAR2(15 CHAR) NOT NULL
);

ALTER TABLE plan ADD CONSTRAINT plan_pk PRIMARY KEY ( planid );

CREATE TABLE producto (
    gtin            VARCHAR2(15 CHAR) NOT NULL,
    sku             VARCHAR2(10 CHAR) NOT NULL,
    productonombre  VARCHAR2(15 CHAR) NOT NULL,
    miniatura       VARCHAR2(15 CHAR),
    textocorto      VARCHAR2(15 CHAR),
    creado          VARCHAR2(15 CHAR) NOT NULL,
    modificado      VARCHAR2(15 CHAR),
    cuenta_cuentaid VARCHAR2(15 CHAR) NOT NULL
);

ALTER TABLE producto ADD CONSTRAINT producto_pk PRIMARY KEY ( gtin,
                                                              cuenta_cuentaid );

CREATE TABLE relacionado (
    relacionadonombre         VARCHAR2(10 CHAR) NOT NULL,
    sentido                   VARCHAR2(20 CHAR),
    producto_gtin             VARCHAR2(15 CHAR) NOT NULL,
    producto_gtin2            VARCHAR2(15 CHAR) NOT NULL,
    producto_cuenta_cuentaid  VARCHAR2(15 CHAR) NOT NULL,
    producto_cuenta_cuentaid2 VARCHAR2(15 CHAR) NOT NULL
);

ALTER TABLE relacionado
    ADD CONSTRAINT relacionado_pk PRIMARY KEY ( producto_gtin,
                                                producto_cuenta_cuentaid,
                                                producto_gtin2,
                                                producto_cuenta_cuentaid2 );

CREATE TABLE relation_11 (
    producto_gtin           VARCHAR2(15 CHAR) NOT NULL,
    producto_cuentaid       VARCHAR2(15 CHAR) NOT NULL,
    activos_activosid       VARCHAR2(15 CHAR) NOT NULL,
    activos_cuenta_cuentaid VARCHAR2(15 CHAR) NOT NULL
);

ALTER TABLE relation_11
    ADD CONSTRAINT relation_11_pk PRIMARY KEY ( producto_gtin,
                                                producto_cuentaid,
                                                activos_activosid,
                                                activos_cuenta_cuentaid );

CREATE TABLE relation_12 (
    activos_activosid          VARCHAR2(15 CHAR) NOT NULL,
    activos_cuenta_cuentaid    VARCHAR2(15 CHAR) NOT NULL,
    categoria_activos_cuentaid VARCHAR2(15 CHAR) NOT NULL,
    categoria_activos_caid     VARCHAR2(15 CHAR) NOT NULL
);

ALTER TABLE relation_12
    ADD CONSTRAINT relation_12_pk PRIMARY KEY ( activos_activosid,
                                                activos_cuenta_cuentaid,
                                                categoria_activos_cuentaid,
                                                categoria_activos_caid );

CREATE TABLE relation_6 (
    categoria_categoriaid VARCHAR2(15 CHAR) NOT NULL,
    categoria_cuentaid    VARCHAR2(15 CHAR) NOT NULL,
    producto_gtin         VARCHAR2(15 CHAR) NOT NULL,
    producto_cuentaid     VARCHAR2(15 CHAR) NOT NULL
);

ALTER TABLE relation_6
    ADD CONSTRAINT relation_6_pk PRIMARY KEY ( categoria_categoriaid,
                                               categoria_cuentaid,
                                               producto_gtin,
                                               producto_cuentaid );

CREATE TABLE usuario (
    usid             VARCHAR2(15 CHAR) NOT NULL,
    nombreu          VARCHAR2(15 CHAR) NOT NULL,
    avatar           VARCHAR2(15 CHAR),
    email            VARCHAR2(15 CHAR) NOT NULL,
    telefono         VARCHAR2(15 CHAR) NOT NULL,
    cuenta_cuentaid2 VARCHAR2(15 CHAR) NOT NULL,
    cuenta_cid       VARCHAR2(15 CHAR)
);

CREATE UNIQUE INDEX usuario__idx ON
    usuario (
        cuenta_cid
    ASC );

ALTER TABLE usuario ADD CONSTRAINT usuario_pk PRIMARY KEY ( usid,
                                                            cuenta_cuentaid2 );

ALTER TABLE activos
    ADD CONSTRAINT activos_cuenta_fk FOREIGN KEY ( cuenta_cuentaid )
        REFERENCES cuenta ( cid );

ALTER TABLE atributos
    ADD CONSTRAINT atributos_cuenta_fk FOREIGN KEY ( cuenta_cuentaid )
        REFERENCES cuenta ( cid );

--  ERROR: FK name length exceeds maximum allowed length(30) --corregido
ALTER TABLE atributos_producto
    ADD CONSTRAINT at_prod_at_fk FOREIGN KEY ( atributos_atributosid )
        REFERENCES atributos ( atributosid );

ALTER TABLE atributos_producto
    ADD CONSTRAINT atributos_producto_producto_fk FOREIGN KEY ( producto_gtin,
                                                                producto_cuenta_cuentaid )
        REFERENCES producto ( gtin,
                              cuenta_cuentaid );

ALTER TABLE categoria_activos
    ADD CONSTRAINT categoria_activos_cuenta_fk FOREIGN KEY ( cuenta_cuentaid )
        REFERENCES cuenta ( cid );

ALTER TABLE categoria
    ADD CONSTRAINT categoria_cuenta_fk FOREIGN KEY ( cuenta_cuentaid )
        REFERENCES cuenta ( cid );

ALTER TABLE cuenta
    ADD CONSTRAINT cuenta_plan_fk FOREIGN KEY ( plan_planid )
        REFERENCES plan ( planid );

ALTER TABLE cuenta
    ADD CONSTRAINT cuenta_usuario_fk FOREIGN KEY ( usuario_usid,
                                                   usuario_cuenta_cuentaid2 )
        REFERENCES usuario ( usid,
                             cuenta_cuentaid2 );

ALTER TABLE producto
    ADD CONSTRAINT producto_cuenta_fk FOREIGN KEY ( cuenta_cuentaid )
        REFERENCES cuenta ( cid );

ALTER TABLE relacionado
    ADD CONSTRAINT relacionado_producto_fk FOREIGN KEY ( producto_gtin,
                                                         producto_cuenta_cuentaid )
        REFERENCES producto ( gtin,
                              cuenta_cuentaid );

ALTER TABLE relacionado
    ADD CONSTRAINT relacionado_producto_fkv2 FOREIGN KEY ( producto_gtin2,
                                                           producto_cuenta_cuentaid2 )
        REFERENCES producto ( gtin,
                              cuenta_cuentaid );

ALTER TABLE relation_11
    ADD CONSTRAINT relation_11_activos_fk FOREIGN KEY ( activos_activosid,
                                                        activos_cuenta_cuentaid )
        REFERENCES activos ( actid,
                             cuenta_cuentaid );

ALTER TABLE relation_11
    ADD CONSTRAINT relation_11_producto_fk FOREIGN KEY ( producto_gtin,
                                                         producto_cuentaid )
        REFERENCES producto ( gtin,
                              cuenta_cuentaid );

ALTER TABLE relation_12
    ADD CONSTRAINT relation_12_activos_fk FOREIGN KEY ( activos_activosid,
                                                        activos_cuenta_cuentaid )
        REFERENCES activos ( actid,
                             cuenta_cuentaid );

--  ERROR: FK name length exceeds maximum allowed length(30) --corregido
ALTER TABLE relation_12
    ADD CONSTRAINT rel_12_categ_act_fk FOREIGN KEY ( categoria_activos_cuentaid,
                                                                  categoria_activos_caid )
        REFERENCES categoria_activos ( cuenta_cuentaid,
                                       caid );

ALTER TABLE relation_6
    ADD CONSTRAINT relation_6_categoria_fk FOREIGN KEY ( categoria_categoriaid,
                                                         categoria_cuentaid )
        REFERENCES categoria ( categoriaid,
                               cuenta_cuentaid );

ALTER TABLE relation_6
    ADD CONSTRAINT relation_6_producto_fk FOREIGN KEY ( producto_gtin,
                                                        producto_cuentaid )
        REFERENCES producto ( gtin,
                              cuenta_cuentaid );

ALTER TABLE usuario
    ADD CONSTRAINT usuario_cuenta_fk FOREIGN KEY ( cuenta_cuentaid2 )
        REFERENCES cuenta ( cid );

ALTER TABLE usuario
    ADD CONSTRAINT usuario_cuenta_fkv2 FOREIGN KEY ( cuenta_cid )
        REFERENCES cuenta ( cid );



-- Informe de Resumen de Oracle SQL Developer Data Modeler: 
-- 
-- CREATE TABLE                            13
-- CREATE INDEX                             2
-- ALTER TABLE                             32
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                           0
-- ALTER TRIGGER                            0
-- CREATE COLLECTION TYPE                   0
-- CREATE STRUCTURED TYPE                   0
-- CREATE STRUCTURED TYPE BODY              0
-- CREATE CLUSTER                           0
-- CREATE CONTEXT                           0
-- CREATE DATABASE                          0
-- CREATE DIMENSION                         0
-- CREATE DIRECTORY                         0
-- CREATE DISK GROUP                        0
-- CREATE ROLE                              0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE SEQUENCE                          0
-- CREATE MATERIALIZED VIEW                 0
-- CREATE MATERIALIZED VIEW LOG             0
-- CREATE SYNONYM                           0
-- CREATE TABLESPACE                        0
-- CREATE USER                              0
-- 
-- DROP TABLESPACE                          0
-- DROP DATABASE                            0
-- 
-- REDACTION POLICY                         0
-- 
-- ORDS DROP SCHEMA                         0
-- ORDS ENABLE SCHEMA                       0
-- ORDS ENABLE OBJECT                       0
-- 
-- ERRORS                                   2
-- WARNINGS                                 0




---CAMBIOS:
ALTER TABLE PLAN 
    ADD NOMBRE VARCHAR2(15 CHAR);
    
ALTER TABLE CUENTA
    MODIFY nombrec                  VARCHAR2(50 CHAR) ;
ALTER TABLE CUENTA
    MODIFY dirfiscal                VARCHAR2(50 CHAR) ;
  
  
ALTER TABLE USUARIO
    MODIFY NOMBREU                 VARCHAR2(50 CHAR) ;
ALTER TABLE USUARIO 
    MODIFY AVATAR               VARCHAR2(50 CHAR) ;
ALTER TABLE USUARIO
    MODIFY EMAIL              VARCHAR2(50 CHAR) ;
ALTER TABLE USUARIO
    MODIFY TELEFONO             VARCHAR2(50 CHAR) ;
    
ALTER TABLE USUARIO
    MODIFY cuenta_cuentaid2 NULL;
    
ALTER TABLE PRODUCTO 
    MODIFY SKU CHAR(10) ;
ALTER TABLE PRODUCTO 
    MODIFY PRODUCTONOMBRE VARCHAR2(50) ;
ALTER TABLE PRODUCTO 
    MODIFY TEXTOCORTO VARCHAR2(50) ;
ALTER TABLE PRODUCTO 
    MODIFY  CREADO VARCHAR2(50) ;
    
    
ALTER TABLE PRODUCTO 
    MODIFY  CUENTA_CUENTAID VARCHAR2(15) ;