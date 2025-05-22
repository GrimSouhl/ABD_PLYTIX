--TESTS:
SET SERVEROUTPUT ON;

--############################################EJ 3####################################################:
--INSERTAMOS DATOS:
INSERT INTO PLAN (
    PLANID, PRODUCTO, ACTIVO, ALMACENAMIENTO,
    CATEGORIAPRODUCTO, CATEGORIAACTIVO, RELACIONES,
    PRECIO, NOMBRE
) VALUES (
    'PLAN1', 'S', 'S', '10GB',
    'Sí', 'Sí', 'Básicas',
    '19.99', 'Plan Básico'
);
INSERT INTO CUENTA (
    CUENTAID, NOMBRECUENTA, DIRECCIONFISCAL, NIFCUENTA, FECHAALTA,
    USUARIO_USUARIOID, PLAN_PLANID, USUARIO_CUENTAID2, USUARIO_CUENTAID
) VALUES (
    'CUENTA01', 'Cuenta Test', 'Dirección 123', 'NIF001', SYSDATE,
    'USER1', 'PLAN1', 'CUENTA01', 'CUENTA01'
);
INSERT INTO PRODUCTO (
    GTIN, SKU, PRODUCTONOMBRE, MINIATURA, TEXTOCORTO,
    CREADO, MODIFICADO, CUENTAID, PUBLICO
) VALUES (
    'GTIN1234567890', 'SKU001', 'Producto Prueba', NULL, NULL,
    TO_CHAR(SYSDATE, 'YYYY-MM-DD'), TO_CHAR(SYSDATE, 'YYYY-MM-DD'), 'CUENTA01', 'Y'
);
INSERT INTO ATRIBUTO (
    ATRIBUTOID, ATRIBUTONOMBRE, ATRIBUTOTIPO, CREADO, CUENTAID, CUENTAID2
) VALUES (
    'ATR01', 'Color', 'Texto', 'SYS', 'CUENTA01', 'CUENTA01'
);
INSERT INTO ATRIBUTO (
    ATRIBUTOID, ATRIBUTONOMBRE, ATRIBUTOTIPO, CREADO, CUENTAID, CUENTAID2
) VALUES (
    'ATR02', 'Tamaño', 'Texto', 'SYS', 'CUENTA01', 'CUENTA01'
);
INSERT INTO ATRIBUTO_PRODUCTO (
    VALOR, PRODUCTO_GTIN, PRODUCTO_CUENTAID, ATRIBUTO_ID, CUENTAID
) VALUES (
    'Rojo', 'GTIN1234567890', 'CUENTA01', 'ATR01', 'CUENTA01'
);
INSERT INTO ATRIBUTO_PRODUCTO (
    VALOR, PRODUCTO_GTIN, PRODUCTO_CUENTAID, ATRIBUTO_ID, CUENTAID
) VALUES (
    'Grande', 'GTIN1234567890', 'CUENTA01', 'ATR02', 'CUENTA01'
);
COMMIT;
--TEST 1: Producto con todos los atributos -> debe devolver TRUE

DECLARE
    v_result BOOLEAN;
BEGIN
    v_result := PKG_ADMIN_PRODUCTOS.F_VALIDAR_ATRIBUTOS_PRODUCTO('GTIN1234567890', 'CUENTA01');
    DBMS_OUTPUT.PUT_LINE('TEST 1 (esperado TRUE): ' || CASE WHEN v_result THEN 'OK' ELSE 'FALLA' END);
END;
/

-- TEST 2: Eliminar un atributo -> debe devolver FALSE
DELETE FROM ATRIBUTO_PRODUCTO 
WHERE PRODUCTO_GTIN = 'GTIN1234567890' AND ATRIBUTO_ID = 'ATR02';
COMMIT;

DECLARE
    v_result BOOLEAN;
BEGIN
    v_result := PKG_ADMIN_PRODUCTOS.F_VALIDAR_ATRIBUTOS_PRODUCTO('GTIN1234567890', 'CUENTA01');
    DBMS_OUTPUT.PUT_LINE('TEST 2 (esperado FALSE): ' || CASE WHEN NOT v_result THEN 'OK' ELSE 'FALLA' END);
END;
/

-- TEST 3: Producto inexistente -> debe lanzar NO_DATA_FOUND y registrar en TRAZA
BEGIN
    DECLARE
        v_result BOOLEAN;
    BEGIN
        v_result := PKG_ADMIN_PRODUCTOS.F_VALIDAR_ATRIBUTOS_PRODUCTO('GTIN_INEXISTENTE', 'CUENTA01');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('TEST 3 (esperado NO_DATA_FOUND): OK');
    END;
END;
/

--Validar que el error se registró en TRAZA
SELECT * FROM TRAZA WHERE DESCRIPCION LIKE '%GTIN_INEXISTENTE%';


--######################################EJ 6 ######################################################

INSERT INTO CUENTA (CUENTAID, NOMBRECUENTA, DIRECCIONFISCAL, NIFCUENTA, FECHAALTA,
    USUARIO_USUARIOID, PLAN_PLANID, USUARIO_CUENTAID2, USUARIO_CUENTAID)
VALUES (
    'CUENTA02', 'Cuenta Test', 'Dirección 123', 'NIF001', SYSDATE,
    'USER2', 'PLAN1', 'CUENTA02', 'CUENTA02'
);

INSERT INTO PRODUCTO (
    GTIN, SKU, PRODUCTONOMBRE, MINIATURA, TEXTOCORTO,
    CREADO, MODIFICADO, CUENTAID, PUBLICO
) VALUES (
    'GTIN1234567890', 'SKU001', 'Producto Prueba', NULL, NULL,
    TO_CHAR(SYSDATE, 'YYYY-MM-DD'), TO_CHAR(SYSDATE, 'YYYY-MM-DD'), 'CUENTA02', 'Y'
);

INSERT INTO ACTIVO (
    ACTIVOID, ACTIVONOMBRE, TAMANYO, ACTIVOTIPO, URL, CUENTAID
) VALUES (
    'ACT01', 'Activo 1', '10MB', 'Imagen', 'http://ejemplo.com/img1.jpg', 'CUENTA02'
);

--ELIMINAMOS ASOCIACION
DELETE FROM REL_CUENTA_PROD
WHERE PRODUCTO_GTIN = 'GTIN1234567890'
  AND PRODUCTO_CUENTAID = 'CUENTA02'
  AND ACTIVOS_ID = 'ACT01'
  AND ACTIVOS_CUENTAID = 'CUENTA02';

COMMIT;
-- TEST 1: Asociación correcta (debe INSERTAR con éxito)
BEGIN
    PKG_ADMIN_PRODUCTOS.P_ASOCIAR_ACTIVO_A_PRODUCTO(
        p_producto_gtin => 'GTIN1234567890',
        p_producto_cuenta_id => 'CUENTA02',
        p_activo_id => 'ACT01',
        p_activo_cuenta_id => 'CUENTA02'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 1 (esperado OK): OK');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 1 (esperado OK): FALLA - ' || SQLERRM);
END;
/

-- TEST 2: Asociación duplicada (debe lanzar EXCEPTION_ASOCIACION_DUPLICADA)
BEGIN
    PKG_ADMIN_PRODUCTOS.P_ASOCIAR_ACTIVO_A_PRODUCTO(
        p_producto_gtin => 'GTIN1234567890',
        p_producto_cuenta_id => 'CUENTA02',
        p_activo_id => 'ACT01',
        p_activo_cuenta_id => 'CUENTA02'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 2 (esperado EXCEPTION_ASOCIACION_DUPLICADA): FALLA');
EXCEPTION
    WHEN PKG_ADMIN_PRODUCTOS.EXCEPTION_ASOCIACION_DUPLICADA THEN
        DBMS_OUTPUT.PUT_LINE('TEST 2 (esperado EXCEPTION_ASOCIACION_DUPLICADA): OK');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 2: FALLA inesperada - ' || SQLERRM);
END;
/

-- TEST 3: Activo inexistente (debe lanzar NO_DATA_FOUND)
BEGIN
    PKG_ADMIN_PRODUCTOS.P_ASOCIAR_ACTIVO_A_PRODUCTO(
        p_producto_gtin => 'GTIN1234567890',
        p_producto_cuenta_id => 'CUENTA02',
        p_activo_id => 'ACT_INEXISTENTE',
        p_activo_cuenta_id => 'CUENTA02'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 3 (esperado NO_DATA_FOUND): FALLA');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('TEST 3 (esperado NO_DATA_FOUND): OK');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 3: FALLA inesperada - ' || SQLERRM);
END;
/

-- TEST 4: Producto inexistente (debe lanzar NO_DATA_FOUND)
BEGIN
    PKG_ADMIN_PRODUCTOS.P_ASOCIAR_ACTIVO_A_PRODUCTO(
        p_producto_gtin => 'GTIN_NO_EXISTE',
        p_producto_cuenta_id => 'CUENTA02',
        p_activo_id => 'ACT01',
        p_activo_cuenta_id => 'CUENTA02'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 4 (esperado NO_DATA_FOUND): FALLA');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('TEST 4 (esperado NO_DATA_FOUND): OK');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 4: FALLA inesperada - ' || SQLERRM);
END;
/

-- VALIDAR INSERT CORRECTO
SELECT * FROM REL_CUENTA_PROD WHERE PRODUCTO_GTIN = 'GTIN1234567890';

-- VALIDAR QUE LOS ERRORES SE REGISTRARON
SELECT * FROM TRAZA WHERE DESCRIPCION LIKE '%Producto o activo no encontrado%'
   OR DESCRIPCION LIKE '%Asociación duplicada%';

DELETE FROM TRAZA;
SELECT * FROM TRAZA ORDER BY FECHA DESC;

--###################################    9   ###############################333

-- Crear plan y cuenta necesarias
BEGIN
    FOR r IN (
        SELECT avatar FROM USUARIO WHERE USUARIOID IN ('TST_USR_001', 'TST_USR_002', 'TST_USR_004')
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP USER ' || r.avatar || ' CASCADE';
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- Si no existe, ignorar
        END;
    END LOOP;
END;
/

-- 2. Borrar registros de prueba de la tabla USUARIO
DELETE FROM USUARIO
WHERE USUARIOID IN (
    'TST_USR_001', 'TST_USR_002', 'TST_USR_003', 'TST_USR_004'
);

-- 3. Borrar registro de prueba de la tabla CUENTA
DELETE FROM CUENTA
WHERE CUENTAID = 'CUENTA_TST';

-- 4. Borrar registro de prueba de la tabla PLAN
DELETE FROM PLAN
WHERE PLANID = 'PLAN_TST';

COMMIT;

INSERT INTO PLAN (
    PLANID, PRODUCTO, ACTIVO, ALMACENAMIENTO,
    CATEGORIAPRODUCTO, CATEGORIAACTIVO, RELACIONES,
    PRECIO, NOMBRE
) VALUES (
    'PLAN_TST', 'S', 'S', '5GB',
    'Sí', 'Sí', 'Básicas',
    '9.99', 'Plan Test Usuario'
);

INSERT INTO CUENTA (
    CUENTAID, NOMBRECUENTA, DIRECCIONFISCAL, NIFCUENTA, FECHAALTA,
    USUARIO_USUARIOID, PLAN_PLANID, USUARIO_CUENTAID2, USUARIO_CUENTAID
) VALUES (
    'CUENTA_TST', 'Cuenta Test Usuario', 'Calle Falsa 123', 'NIF_TST', SYSDATE,
    NULL, 'PLAN_TST', 'CUENTA_TST', 'CUENTA_TST'
);

-- TEST 1: Usuario válido y rol válido (debe funcionar)
DECLARE
    v_usuario USUARIO%ROWTYPE;
BEGIN
    v_usuario.usuarioid := 'TST_USR_001';
    v_usuario.nombreusuario := 'Test Usuario 1';
    v_usuario.avatar := 'TST_AVATAR_001';
    v_usuario.email := 'testuser001@ejemplo.com';
    v_usuario.telefono := '600000001';
    v_usuario.cuentaid := 'CUENTA_TST';
    v_usuario.cuentaid_alt := 'CUENTA_TST';

    PKG_ADMIN_PRODUCTOS.P_CREAR_USUARIO(
        p_usuario => v_usuario,
        p_rol => 'PLYTIX_ROL_ESTANDAR',
        p_password => 'Pass001'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 1 (esperado OK): OK');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 1 (esperado OK): FALLA - ' || SQLERRM);
END;
/

-- TEST 2: Usuario ya existe (debe lanzar E_USUARIO_YA_EXISTE)
DECLARE
    v_usuario USUARIO%ROWTYPE;
BEGIN
    v_usuario.usuarioid := 'TST_USR_001'; -- Ya insertado en TEST 1
    v_usuario.nombreusuario := 'Test Usuario Duplicado';
    v_usuario.avatar := 'TST_AVATAR_002';
    v_usuario.email := 'duplicado@ejemplo.com';
    v_usuario.telefono := '600000002';
    v_usuario.cuentaid := 'CUENTA_TST';
    v_usuario.cuentaid_alt := 'CUENTA_TST';

    PKG_ADMIN_PRODUCTOS.P_CREAR_USUARIO(
        p_usuario => v_usuario,
        p_rol => 'PLYTIX_ROL_ESTANDAR',
        p_password => 'Pass002'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 2 (esperado E_USUARIO_YA_EXISTE): FALLA');
EXCEPTION
    WHEN PKG_ADMIN_PRODUCTOS.E_USUARIO_YA_EXISTE THEN
        DBMS_OUTPUT.PUT_LINE('TEST 2 (esperado E_USUARIO_YA_EXISTE): OK');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 2: FALLA inesperada - ' || SQLERRM);
END;
/

-- TEST 3: Rol inválido (debe lanzar E_ROL_INVALIDO)
DECLARE
    v_usuario USUARIO%ROWTYPE;
BEGIN
    v_usuario.usuarioid := 'TST_USR_003';
    v_usuario.nombreusuario := 'Test Usuario Rol Invalido';
    v_usuario.avatar := 'TST_AVATAR_003';
    v_usuario.email := 'rolinvalido@ejemplo.com';
    v_usuario.telefono := '600000003';
    v_usuario.cuentaid := 'CUENTA_TST';
    v_usuario.cuentaid_alt := 'CUENTA_TST';

    PKG_ADMIN_PRODUCTOS.P_CREAR_USUARIO(
        p_usuario => v_usuario,
        p_rol => 'MAL_ROL',
        p_password => 'Pass003'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 3 (esperado E_ROL_INVALIDO): FALLA');
EXCEPTION
    WHEN PKG_ADMIN_PRODUCTOS.E_ROL_INVALIDO THEN
        DBMS_OUTPUT.PUT_LINE('TEST 3 (esperado E_ROL_INVALIDO): OK');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 3: FALLA inesperada - ' || SQLERRM);
END;
/

-- TEST 4: Cuenta inexistente (esperado: FK ORA-02291 capturada como error general)
DECLARE
    v_usuario USUARIO%ROWTYPE;
BEGIN
    v_usuario.usuarioid := 'TST_USR_004';
    v_usuario.nombreusuario := 'Cuenta Inexistente';
    v_usuario.avatar := 'TST_AVATAR_004';
    v_usuario.email := 'cuentanoexiste@ejemplo.com';
    v_usuario.telefono := '600000004';
    v_usuario.cuentaid := 'CUENTA_FAKE';
    v_usuario.cuentaid_alt := 'CUENTA_FAKE';

    PKG_ADMIN_PRODUCTOS.P_CREAR_USUARIO(
        p_usuario => v_usuario,
        p_rol => 'PLYTIX_ROL_ESTANDAR',
        p_password => 'Pass004'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 4 (esperado ORA-02291 FK FAIL): FALLA');
EXCEPTION
    WHEN PKG_ADMIN_PRODUCTOS.E_ERROR_GENERAL_USUARIO THEN
        DBMS_OUTPUT.PUT_LINE('TEST 4 (esperado ORA-02291 FK FAIL): OK');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 4: FALLA inesperada - ' || SQLERRM);
END;
/


SELECT USUARIOID, AVATAR FROM USUARIO WHERE USUARIOID LIKE 'TST_USR%';

SELECT * FROM TRAZA 
WHERE FECHA >= SYSDATE - 1 
ORDER BY FECHA DESC;
