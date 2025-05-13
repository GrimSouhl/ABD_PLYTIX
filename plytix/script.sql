--############NIVEL FÍSICO############--------

-----DROP USER PLYTIX CASCADE;
--####1.-CREACION DEL USUARIO Y TABLESPACE
--TABLESPACES
--DESDE SYSTEM
CREATE TABLESPACE TS_PLYTIX DATAFILE 'C:\APP\ALUMNOS\ORADATA\ORCL\plytix.dbf' SIZE 200M AUTOEXTEND ON;
--ALTER DATABASE DATAFILE 'C:\APP\ALUMNOS\ORADATA\ORCL\plytix.dbf' RESIZE 200M;
CREATE TABLESPACE TS_INDICES DATAFILE 'C:\APP\ALUMNOS\ORADATA\ORCL\TS_INDICES.dbf' SIZE 50M AUTOEXTEND ON;

--USER
CREATE USER PLYTIX IDENTIFIED BY USUARIO
DEFAULT TABLESPACE TS_PLYTIX
QUOTA UNLIMITED ON TS_PLYTIX
QUOTA 50M ON TS_INDICES;


GRANT CONNECT, RESOURCE TO PLYTIX;
GRANT CREATE TABLE, CREATE VIEW, CREATE MATERIALIZED VIEW TO PLYTIX;
GRANT CREATE SEQUENCE, CREATE PROCEDURE TO PLYTIX;
GRANT CREATE PUBLIC SYNONYM TO PLYTIX;
GRANT CREATE SEQUENCE TO PLYTIX; --8

----#####SCRIPT DE CREACION DE TALAS Y RELACIONES####-------
--EJECUTAR DESDE PLYTIX-----

-- Generado por Oracle SQL Developer Data Modeler 23.1.0.087.0806
-- Fecha: 2025-04-03

CREATE TABLE activo (
    activoid       VARCHAR2(50 CHAR) NOT NULL,
    activonombre   VARCHAR2(50 CHAR) NOT NULL,
    tamanyo        VARCHAR2(50 CHAR) NOT NULL,
    activotipo     VARCHAR2(50 CHAR),
    url            VARCHAR2(50 CHAR),
    cuentaid       VARCHAR2(50 CHAR) NOT NULL,
    CONSTRAINT activo_pk PRIMARY KEY (activoid, cuentaid)
);

CREATE TABLE atributo (
    atributoid      VARCHAR2(50 CHAR) NOT NULL,
    atributonombre  VARCHAR2(50 CHAR) NOT NULL,
    atributotipo    VARCHAR2(50 CHAR),
    creado          VARCHAR2(50 CHAR) NOT NULL,
    cuentaid        VARCHAR2(50 CHAR),
    cuentaid2       VARCHAR2(50 CHAR) NOT NULL,
    CONSTRAINT atributo_pk PRIMARY KEY (atributoid)
);

CREATE TABLE atributo_producto (
    valor                  VARCHAR2(50 CHAR) NOT NULL,
    producto_gtin          VARCHAR2(50 CHAR) NOT NULL,
    producto_cuentaid      VARCHAR2(50 CHAR) NOT NULL,
    atributo_id            VARCHAR2(50 CHAR) NOT NULL,
    cuentaid               VARCHAR2(50 CHAR) NOT NULL,
    CONSTRAINT atributo_producto_pk PRIMARY KEY (producto_gtin, producto_cuentaid, atributo_id)
);

CREATE TABLE categoria (
    categoriaid      VARCHAR2(50 CHAR) NOT NULL,
    categorianombre  VARCHAR2(50 CHAR) NOT NULL,
    cuentaid         VARCHAR2(50 CHAR) NOT NULL,
    CONSTRAINT categoria_pk PRIMARY KEY (categoriaid, cuentaid)
);

CREATE TABLE categoria_activo (
    caid       VARCHAR2(50 CHAR) NOT NULL,
    nombreca   VARCHAR2(50 CHAR) NOT NULL,
    cuentaid   VARCHAR2(50 CHAR) NOT NULL,
    CONSTRAINT categoria_activo_pk PRIMARY KEY (cuentaid, caid)
);

CREATE TABLE cuenta (
    cuentaid              VARCHAR2(50 CHAR) NOT NULL,
    nombrecuenta          VARCHAR2(50 CHAR) NOT NULL,
    direccionfiscal       VARCHAR2(50 CHAR) NOT NULL,
    nifcuenta             VARCHAR2(50 CHAR) NOT NULL,
    fechaalta             DATE,
    usuario_usuarioid     VARCHAR2(50 CHAR),
    plan_planid           VARCHAR2(50 CHAR) NOT NULL,
    usuario_cuentaid2     VARCHAR2(50 CHAR),
    usuario_cuentaid      VARCHAR2(50 CHAR),
    CONSTRAINT cuenta_pk PRIMARY KEY (cuentaid)
);

CREATE UNIQUE INDEX cuenta_usuario_idx1 ON cuenta (usuario_usuarioid ASC, usuario_cuentaid2 ASC);
CREATE UNIQUE INDEX cuenta_usuario_idx2 ON cuenta (usuario_usuarioid ASC, usuario_cuentaid ASC);

CREATE TABLE plan (
    planid              VARCHAR2(50 CHAR) NOT NULL,
    producto            VARCHAR2(50 CHAR) NOT NULL,
    activo              VARCHAR2(50 CHAR) NOT NULL,
    almacenamiento      VARCHAR2(50 CHAR) NOT NULL,
    categoriaproducto   VARCHAR2(50 CHAR) NOT NULL,
    categoriaactivo     VARCHAR2(50 CHAR) NOT NULL,
    relaciones          VARCHAR2(50 CHAR) NOT NULL,
    precio              VARCHAR2(50 CHAR) NOT NULL,
    nombre              VARCHAR2(50 CHAR),
    CONSTRAINT plan_pk PRIMARY KEY (planid)
);

CREATE TABLE producto (
    gtin            VARCHAR2(50 CHAR) NOT NULL,
    sku             CHAR(10) NOT NULL,
    productonombre  VARCHAR2(50 CHAR) NOT NULL,
    miniatura       VARCHAR2(50 CHAR),
    textocorto      VARCHAR2(50 CHAR),
    creado          VARCHAR2(50 CHAR) NOT NULL,
    modificado      VARCHAR2(50 CHAR),
    cuentaid        VARCHAR2(50 CHAR) NOT NULL,
    CONSTRAINT producto_pk PRIMARY KEY (gtin, cuentaid)
);

CREATE TABLE relacionado (
    relacionadonombre       VARCHAR2(50 CHAR) NOT NULL,
    sentido                 VARCHAR2(50 CHAR),
    producto_gtin           VARCHAR2(50 CHAR) NOT NULL,
    producto_gtin1          VARCHAR2(50 CHAR) NOT NULL,
    producto_cuentaid       VARCHAR2(50 CHAR) NOT NULL,
    producto_cuentaid1      VARCHAR2(50 CHAR) NOT NULL,
    CONSTRAINT relacionado_pk PRIMARY KEY (producto_gtin, producto_cuentaid, producto_gtin1, producto_cuentaid1)
);

CREATE TABLE rel_cuenta_prod (
    producto_gtin       VARCHAR2(50 CHAR) NOT NULL,
    producto_cuentaid   VARCHAR2(50 CHAR) NOT NULL,
    activos_id          VARCHAR2(50 CHAR) NOT NULL,
    activos_cuentaid    VARCHAR2(50 CHAR) NOT NULL,
    CONSTRAINT rel_cuenta_prod_pk PRIMARY KEY (producto_gtin, producto_cuentaid, activos_id, activos_cuentaid)
);

CREATE TABLE rel_cuenta_plan (
    activos_id             VARCHAR2(50 CHAR) NOT NULL,
    activos_cuentaid       VARCHAR2(50 CHAR) NOT NULL,
    categoria_cuentaid     VARCHAR2(50 CHAR) NOT NULL,
    categoria_caid         VARCHAR2(50 CHAR) NOT NULL,
    CONSTRAINT rel_cuenta_plan_pk PRIMARY KEY (activos_id, activos_cuentaid, categoria_cuentaid, categoria_caid)
);

CREATE TABLE rel_cat_prod (
    categoriaid       VARCHAR2(50 CHAR) NOT NULL,
    categoria_cuentaid VARCHAR2(50 CHAR) NOT NULL,
    producto_gtin     VARCHAR2(50 CHAR) NOT NULL,
    producto_cuentaid VARCHAR2(50 CHAR) NOT NULL,
    CONSTRAINT rel_cat_prod_pk PRIMARY KEY (categoriaid, categoria_cuentaid, producto_gtin, producto_cuentaid)
);

CREATE TABLE usuario (
    usuarioid        VARCHAR2(50 CHAR) NOT NULL,
    nombreusuario    VARCHAR2(50 CHAR) NOT NULL,
    avatar           VARCHAR2(50 CHAR),
    email            VARCHAR2(50 CHAR) NOT NULL,
    telefono         VARCHAR2(50 CHAR) NOT NULL,
    cuentaid         VARCHAR2(50 CHAR) NOT NULL,
    cuentaid_alt     VARCHAR2(50 CHAR),
    CONSTRAINT usuario_pk PRIMARY KEY (usuarioid, cuentaid)
);

CREATE UNIQUE INDEX usuario_idx ON usuario (cuentaid_alt ASC);

-- Relaciones (FKs)

ALTER TABLE activo
    ADD CONSTRAINT fk_activo_cuenta FOREIGN KEY (cuentaid) REFERENCES cuenta (cuentaid);

ALTER TABLE atributo
    ADD CONSTRAINT fk_atributo_cuenta1 FOREIGN KEY (cuentaid) REFERENCES cuenta (cuentaid);
ALTER TABLE atributo
    ADD CONSTRAINT fk_atributo_cuenta2 FOREIGN KEY (cuentaid2) REFERENCES cuenta (cuentaid);

ALTER TABLE atributo_producto
    ADD CONSTRAINT fk_attr_prod_atributo FOREIGN KEY (atributo_id) REFERENCES atributo (atributoid);
ALTER TABLE atributo_producto
    ADD CONSTRAINT fk_attr_prod_producto FOREIGN KEY (producto_gtin, producto_cuentaid) REFERENCES producto (gtin, cuentaid);

ALTER TABLE categoria
    ADD CONSTRAINT fk_categoria_cuenta FOREIGN KEY (cuentaid) REFERENCES cuenta (cuentaid);

ALTER TABLE categoria_activo
    ADD CONSTRAINT fk_cat_activo_cuenta FOREIGN KEY (cuentaid) REFERENCES cuenta (cuentaid);

ALTER TABLE cuenta
    ADD CONSTRAINT fk_cuenta_plan FOREIGN KEY (plan_planid) REFERENCES plan (planid);

ALTER TABLE producto
    ADD CONSTRAINT fk_producto_cuenta FOREIGN KEY (cuentaid) REFERENCES cuenta (cuentaid);

ALTER TABLE relacionado
    ADD CONSTRAINT fk_relacionado_prod1 FOREIGN KEY (producto_gtin, producto_cuentaid) REFERENCES producto (gtin, cuentaid);
ALTER TABLE relacionado
    ADD CONSTRAINT fk_relacionado_prod2 FOREIGN KEY (producto_gtin1, producto_cuentaid1) REFERENCES producto (gtin, cuentaid);

ALTER TABLE rel_cuenta_prod
    ADD CONSTRAINT fk_rcp_activo FOREIGN KEY (activos_id, activos_cuentaid) REFERENCES activo (activoid, cuentaid);
ALTER TABLE rel_cuenta_prod
    ADD CONSTRAINT fk_rcp_producto FOREIGN KEY (producto_gtin, producto_cuentaid) REFERENCES producto (gtin, cuentaid);

ALTER TABLE rel_cuenta_plan
    ADD CONSTRAINT fk_rcplan_activo FOREIGN KEY (activos_id, activos_cuentaid) REFERENCES activo (activoid, cuentaid);
ALTER TABLE rel_cuenta_plan
    ADD CONSTRAINT fk_rcplan_cat_activo FOREIGN KEY (categoria_cuentaid, categoria_caid) REFERENCES categoria_activo (cuentaid, caid);

ALTER TABLE rel_cat_prod
    ADD CONSTRAINT fk_rcprod_categoria FOREIGN KEY (categoriaid, categoria_cuentaid) REFERENCES categoria (categoriaid, cuentaid);
ALTER TABLE rel_cat_prod
    ADD CONSTRAINT fk_rcprod_prod FOREIGN KEY (producto_gtin, producto_cuentaid) REFERENCES producto (gtin, cuentaid);

ALTER TABLE usuario
    ADD CONSTRAINT fk_usuario_cuenta FOREIGN KEY (cuentaid) REFERENCES cuenta (cuentaid);

--#########################################---------

--VERIFICACIONES
SELECT TABLESPACE_NAME FROM DBA_TABLESPACES 
WHERE TABLESPACE_NAME IN ('TS_PLYTIX', 'TS_INDICES');

SELECT USERNAME, DEFAULT_TABLESPACE 
FROM DBA_USERS WHERE USERNAME = 'PLYTIX';

SELECT *
FROM DBA_DATA_FILES 
WHERE TABLESPACE_NAME IN ('TS_PLYTIX', 'TS_INDICES');


--2

select * from ALL_INDEXES WHERE OWNER = 'PLYTIX';
--FUNCION QUE VA METIENDO LOAS INDEXES EN EL TABLESPACE TS_INDICES
BEGIN
   FOR rec IN (SELECT INDEX_NAME
               FROM ALL_INDEXES
               WHERE OWNER = 'PLYTIX' AND TABLESPACE_NAME IS NOT NULL) 
   LOOP
      EXECUTE IMMEDIATE 'ALTER INDEX PLYTIX.' || rec.INDEX_NAME || ' REBUILD TABLESPACE TS_INDICES';
   END LOOP;
END;
/
--CHECKEAMOS
select * from ALL_INDEXES WHERE TABLESPACE_NAME = 'TS_INDICES';

--3 IMPORTACION DE DATOS

    
--4

--DESDE SYSTEM:
create or replace directory directorio_ext as 'C:\app\alumnos\admin\orcl\dpdump';

grant read, write on directory directorio_ext to PLYTIX;

SELECT * FROM ALL_DIRECTORIES;


--DESDE PLYTIX:
CREATE table productos_ext
 ( 
    SKU CHAR(50),
    NOMBRE VARCHAR2(50),
    TEXTOCORTO VARCHAR2(50),
    CREADO VARCHAR2(50),
    CUENTA_ID VARCHAR2(50)
)
ORGANIZATION EXTERNAL (
     TYPE ORACLE_LOADER
     DEFAULT DIRECTORY DIRECTORIO_EXT
     ACCESS PARAMETERS (
         RECORDS DELIMITED BY NEWLINE
         SKIP 1
         CHARACTERSET UTF8
         FIELDS TERMINATED BY ';'
         OPTIONALLY ENCLOSED BY '"'
         MISSING FIELD VALUES ARE NULL
             (
                 SKU CHAR(50),
                 NOMBRE CHAR(50),
                 TEXTOCORTO CHAR(50),
                 creado CHAR(50) DATE_FORMAT DATE MASK "dd/mm/yyyy",
                 cuenta_id CHAR(50)
             )
         )
     LOCATION ('productos.csv')
);

--COMPROBAMOS QUE LA TABLA SE CREO Y TIENE DATOS:
SELECT * FROM productos_ext;

SELECT TABLE_NAME FROM ALL_EXTERNAL_TABLES;

SELECT * FROM user_external_tables where table_name = 'PRODUCTOS_EXT';

--5 INDICES--

CREATE INDEX idx_usuario_email ON USUARIO(email) TABLESPACE TS_INDICES;

CREATE INDEX idx_usuario_telefono ON USUARIO(telefono) TABLESPACE TS_INDICES;

SELECT * FROM ALL_INDEXES WHERE TABLESPACE_NAME= 'TS_INDICES';

CREATE INDEX idx_usuario_nombre_upper 
ON USUARIO(UPPER(nombreusuario)) 
TABLESPACE TS_INDICES;

--¿En qué tablespace reside la tabla USUARIO? ¿Y los índices? (compruébelo consultando el diccionario de datos)
--TS_INDICES
select * from user_indexes where table_name = 'USUARIO';


CREATE BITMAP INDEX idx_usuario_tipo_cuenta 
ON USUARIO(CUENTAID) 
TABLESPACE TS_INDICES;


--6 VISTA MARERIALLIZADA

CREATE MATERIALIZED VIEW VM_PRODUCTOS
TABLESPACE TS_PLYTIX
BUILD IMMEDIATE
REFRESH FORCE
START WITH TRUNC(SYSDATE) + 1
NEXT TRUNC(SYSDATE + 1)
AS
SELECT * FROM PRODUCTO;

--7 SINÓNIMOS--

--SELECT * FROM VM_PRODUCTOS;
CREATE OR REPLACE PUBLIC SYNONYM S_PRODUCTOS FOR VM_PRODUCTOS;
SELECT * FROM S_PRODUCTOS;


--8--

--GRANT CREATE SEQUENCE TO PLYTIX;

CREATE SEQUENCE SEQ_PRODUCTOS
    START WITH 1
    INCREMENT BY 1
    NOCACHE --NO GUARDA EN CACHE
    NOCYCLE; --NO SE REINICIA AL LLEGAR AL MAX
    
CREATE OR REPLACE TRIGGER TR_PRODUCTOS
BEFORE INSERT ON PRODUCTO
FOR EACH ROW
DECLARE
    --CUENTIDACT VARCHAR2;
    --
    --CUENTAIDCAT VARCHAR2;
    --CUENTAIDPROD VARCHAR2;
BEGIN
    IF :new.GTIN IS NULL THEN
        :new.GTIN := SEQ_PRODUCTOS.NEXTVAL;
    END IF;
    --AÑADIDO:
    --SELECT CUENTAID INTO CUENTIDACT FROM USUARIO WHERE NOMBREUSUARIO = USER;
   -- :NEW.CUENTAID :=CUENTIDACT;
    --UN PRODUCTO SOLO PUEDEE SER  DE UNA CAT DE SU MISMA CUENTA
    --SELECT CUENTAID INTO CUENTAIDCAT FROM CATEGORIA
    
    
END TR_PRODUCTOS;
/
INSERT INTO PRODUCTO (SKU, PRODUCTONOMBRE, TEXTOCORTO, CREADO, CUENTAID)
SELECT TRIM(SKU),NOMBRE,TEXTOCORTO,CREADO, CUENTA_ID
FROM PRODUCTOS_EXT;                                                                        -----------------------------------------------------------------DUDA
--FROM 
SELECT * FROM S_PRODUCTOS;



--###############Nivel físico 2º parte------------------###############################################
/*: Tiene control total sobre todas las tablas de Plytix y es responsable
de la seguridad (TDE y VPD). Puede crear, modificar y eliminar cuentas, usuarios, productos,
activos y planes*/

--GRANT CREATE USER TO PLYTIX; 
--GRANT CREATE ROLE TO PLYTIX;

CREATE USER ADMIN_PLYTIX IDENTIFIED BY USUARIO 
    DEFAULT TABLESPACE TS_PLYTIX 
    QUOTA 50M ON TS_PLYTIX;
--USUARIO ADMIN    
CREATE ROLE PLYTIX_ADMIN;

grant administer key management to plytix_admin; -------
GRANT SELECT,INSERT, DELETE, UPDATE ON PLYTIX.CUENTA TO PLYTIX_ADMIN;
GRANT SELECT,INSERT, DELETE, UPDATE ON PLYTIX.USUARIO TO PLYTIX_ADMIN;
GRANT SELECT,INSERT, DELETE, UPDATE ON PLYTIX.PRODUCTO TO PLYTIX_ADMIN;
GRANT SELECT,INSERT, DELETE, UPDATE ON PLYTIX.ACTIVO TO PLYTIX_ADMIN;
GRANT SELECT,INSERT, DELETE, UPDATE ON PLYTIX.PLAN TO PLYTIX_ADMIN;
GRANT CONNECT TO PLYTIX_ADMIN;

GRANT PLYTIX_ADMIN TO ADMIN_PLYTIX;

--desde admin_plytix
select * from plytix.cuenta;
select * from plytix.producto;
select * from PLYTIX.ACTIVO;
select * from PLYTIX.PLAN;
select * from PLYTIX.USUARIO;


--USUARIO ESTANDAR------------------------------------------------------

CREATE USER anagarcia IDENTIFIED BY usuario 
    DEFAULT TABLESPACE TS_PLYTIX 
    QUOTA 50M ON TS_PLYTIX;
GRANT CONNECT TO anagarcia;

CREATE ROLE PLYTIX_ROL_ESTANDAR;

GRANT PLYTIX_ROL_ESTANDAR to anagarcia;

create or replace view v_estandar_producto as 
    select * from plytix.producto
    where cuentaid = (select cuentaid from plytix.usuario where avatar = user)
    with check option 
    ;
grant select,update, insert, delete on v_estandar_producto to PLYTIX_ROL_ESTANDAR;
create or replace view v_estandar_usuario as 
    select * from plytix.USUARIO
    where cuentaid = (select cuentaid from usuario where avatar = user)
    with check option 
    ;
grant select,update, insert, delete on v_estandar_usuario to plytix_rol_estandar;
create or replace view v_estandar_activo as 
    select * from plytix.ACTIVO
    where cuentaid = (select cuentaid from usuario where avatar = user)
    with check option 
    ;
grant select,update, insert, delete on v_estandar_activo to plytix_rol_estandar;
create or replace view v_estandar_atributo as 
    select * from plytix.atributo
    where cuentaid = (select cuentaid from usuario where avatar = user)
    with check option 
    ;   
grant select,update, insert, delete on v_estandar_atributo to plytix_rol_estandar;

select * from dba_role_privs where grantee = 'anagarcia';
create or replace view v_estandar_plan as 
    SELECT P.* 
        FROM plytix.usuario U
        JOIN plytix.cuenta C ON U.cuentaid = C.cuentaid
        JOIN plytix.plan P ON C.plan_planid = P.planid
        WHERE U.avatar = user
    with check option 
; 
    
grant select on v_estandar_plan to PLYTIX_ROL_ESTANDAR;
            



------------------------------------------------------------------------------------
--gestor de cuentas
/*Accede y administra la tabla Cuenta. Puede modificar los datos de las
cuentas (Nombre, DirecciónFiscal, NIF, etc.). No tiene acceso a datos sensibles de Usuario (Email,
Teléfono).
*/ 
CREATE ROLE PLYTIX_GESTOR_CUENTAS;

CREATE OR REPLACE VIEW V_GESTOR_CUENTAS AS
  SELECT USUARIOID, NOMBREUSUARIO, AVATAR, CUENTAID,CUENTAID_ALT FROM USUARIO
;
grant select,update, insert, delete on V_GESTOR_CUENTAS to PLYTIX_GESTOR_CUENTAS;
grant select,update, insert, delete on PLAN TO PLYTIX_GESTOR_CUENTAS;

/*
Planificador de Servicios: Administra la tabla Plan y sus relaciones (Productos, Activos,
CategoríasProducto, CategoríasActivos). Puede definir planes y modificar los elementos que los
componen.
*/
CREATE ROLE PLYTIX_PLANIFICADOR;
grant select,update, insert, delete on PLAN TO PLYTIX_PLANIFICADOR; 


GRANT DELETE TO PLYTIX;
--desde plytix
SELECT * 
FROM ALL_TAB_PRIVS
WHERE GRANTEE = 'ADMIN_PLYTIX';

SELECT * 
FROM USER_TAB_PRIVS
WHERE GRANTEE = 'PLYTIX';


GRANT INSERT, SELECT, UPDATE, DELETE ON PLYTIX.PRODUCTO TO USUARIO_ESTANDAR;


ALTER TABLE PRODUCTO ADD PUBLICO CHAR(1) DEFAULT 'S';

CREATE OR REPLACE VIEW V_PRODUCTO_PUBLICO AS SELECT * FROM PRODUCTO WHERE PUBLICO = 'S' WITH READ ONLY;


GRANT INSERT, SELECT, UPDATE, DELETE ON PLYTIX.ACTIVO TO USUARIO_ESTANDAR;
GRANT INSERT, SELECT, UPDATE, DELETE ON PLYTIX.CATEGORIA_ACTIVO TO USUARIO_ESTANDAR;

GRANT INSERT, SELECT, UPDATE, DELETE ON PLYTIX.CATEGORIA TO USUARIO_ESTANDAR;
GRANT INSERT, SELECT, UPDATE, DELETE ON PLYTIX.REL_CAT_PROD TO USUARIO_ESTANDAR;


GRANT INSERT, SELECT, UPDATE, DELETE ON PLYTIX.RELACIONADO TO USUARIO_ESTANDAR;

GRANT INSERT, SELECT, UPDATE, DELETE ON PLYTIX.ATRIBUTO TO USUARIO_ESTANDAR;
GRANT INSERT, SELECT, UPDATE, DELETE ON PLYTIX.ATRIBUTO_PRODUCTO TO USUARIO_ESTANDAR;

