--desde plytix
CREATE TABLE TRAZA (
    Fecha Date,
    Usuario VARCHAR2(40),
    Causante VARCHAR2(40),
    Descripcion VARCHAR2(500)
);

--Paquete para funciones auxiliares
CREATE OR REPLACE PACKAGE PKG_PLYTIX_UTIL AS
   PROCEDURE REGISTRA_ERROR(P_MENSAJE IN VARCHAR2, P_DONDE IN VARCHAR2);
END PKG_PLYTIX_UTIL;
/

CREATE OR REPLACE PACKAGE BODY PKG_PLYTIX_UTIL AS
   PROCEDURE REGISTRA_ERROR(P_MENSAJE IN VARCHAR2, P_DONDE IN VARCHAR2) AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO TRAZA VALUES (SYSDATE, USER, P_DONDE, SUBSTR(P_MENSAJE, 1, 500));
      COMMIT;
   END;
END PKG_PLYTIX_UTIL;
/
---------------------------------------------
create or replace PACKAGE PKG_ADMIN_PRODUCTOS AS 

    EXCEPTION_PLAN_NO_ASIGNADO EXCEPTION;
    PRAGMA EXCEPTION_INIT(EXCEPTION_PLAN_NO_ASIGNADO, -20001);

    EXCEPTION_ASOCIACION_DUPLICADA EXCEPTION;
    PRAGMA EXCEPTION_INIT(EXCEPTION_ASOCIACION_DUPLICADA, -20002);

    INVALID_DATA EXCEPTION;
    PRAGMA EXCEPTION_INIT(INVALID_DATA, -20003);
    
    E_USUARIO_YA_EXISTE EXCEPTION;
    PRAGMA EXCEPTION_INIT(E_USUARIO_YA_EXISTE, -20010);

    E_ROL_INVALIDO EXCEPTION;
    PRAGMA EXCEPTION_INIT(E_ROL_INVALIDO, -20011);

    E_ERROR_GENERAL_USUARIO EXCEPTION;
    PRAGMA EXCEPTION_INIT(E_ERROR_GENERAL_USUARIO, -20099);

   -- 3
   FUNCTION F_VALIDAR_ATRIBUTOS_PRODUCTO(
      p_producto_gtin IN PRODUCTO.GTIN%TYPE,
      p_cuenta_id     IN PRODUCTO.CUENTAID%TYPE
   ) RETURN BOOLEAN;


   -- 6
   PROCEDURE P_ASOCIAR_ACTIVO_A_PRODUCTO(
      p_producto_gtin         IN PRODUCTO.GTIN%TYPE,
      p_producto_cuenta_id    IN PRODUCTO.CUENTAID%TYPE,
      p_activo_id             IN ACTIVO.ACTIVOID%TYPE,
      p_activo_cuenta_id      IN ACTIVO.CUENTAID%TYPE
   );


   -- 9
    PROCEDURE P_CREAR_USUARIO( 
        p_usuario IN USUARIO%ROWTYPE, 
        p_rol IN VARCHAR, 
        p_password IN VARCHAR
    );

END;
/



CREATE OR REPLACE
PACKAGE BODY PKG_ADMIN_PRODUCTOS AS
  
--3
  FUNCTION F_VALIDAR_ATRIBUTOS_PRODUCTO(
      p_producto_gtin IN PRODUCTO.GTIN%TYPE,
      p_cuenta_id     IN PRODUCTO.CUENTAID%TYPE
   ) RETURN BOOLEAN IS
   
   CURSOR C_AT IS
    SELECT ATRIBUTOID FROM ATRIBUTO WHERE CUENTAID = P_CUENTA_ID;
    V_EXISTE NUMBER;
  BEGIN
  --comprobamos que el producto existe
    SELECT COUNT(*) INTO V_EXISTE 
    FROM PRODUCTO 
    WHERE GTIN = P_PRODUCTO_GTIN AND CUENTAID = P_CUENTA_ID;
    
    IF V_EXISTE = 0 THEN
      RAISE NO_DATA_FOUND;
    END IF;
    
    FOR atr IN C_AT LOOP
      SELECT COUNT(*) INTO V_EXISTE
      FROM ATRIBUTO_PRODUCTO
      WHERE producto_gtin = p_producto_gtin
        AND producto_cuentaid = p_cuenta_id
        AND atributo_id = atr.atributoid;

      IF V_EXISTE = 0 THEN
         RETURN FALSE;
      END IF;
   END LOOP;
   RETURN TRUE;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      PKG_PLYTIX_UTIL.REGISTRA_ERROR('Producto no encontrado para GTIN=' || p_producto_gtin || ', cuenta=' || p_cuenta_id,$$PLSQL_UNIT);
      RAISE;
   WHEN OTHERS THEN
      PKG_PLYTIX_UTIL.REGISTRA_ERROR(SQLCODE || ' ' || SUBSTR(SQLERRM, 1, 500),$$PLSQL_UNIT);
      RAISE;
  END F_VALIDAR_ATRIBUTOS_PRODUCTO;

--6
  PROCEDURE P_ASOCIAR_ACTIVO_A_PRODUCTO(
      p_producto_gtin         IN PRODUCTO.GTIN%TYPE,
      p_producto_cuenta_id    IN PRODUCTO.CUENTAID%TYPE,
      p_activo_id             IN ACTIVO.ACTIVOID%TYPE,
      p_activo_cuenta_id      IN ACTIVO.CUENTAID%TYPE
   ) AS
    v_producto_existe NUMBER;
    v_activo_existe NUMBER;
    v_asociacion_existe NUMBER;
    
  BEGIN
    --verificamos si el producto existe:
    SELECT COUNT(*) INTO v_producto_existe
    FROM PRODUCTO
    WHERE GTIN = p_producto_gtin AND CUENTAID = P_PRODUCTO_CUENTA_ID;
    IF V_PRODUCTO_EXISTE = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;
    
    --VERIFICAMOS SI EL ACTIVO EXISTE:
    SELECT COUNT(*) INTO V_ACTIVO_EXISTE
    FROM ACTIVO
    WHERE ACTIVOID = P_ACTIVO_ID AND CUENTAID = P_ACTIVO_CUENTA_ID;
    IF V_ACTIVO_EXISTE = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;
    
    --VERIFICAMOS SI YA HAY ASOCIACION PREVIA
    SELECT COUNT(*) INTO V_ASOCIACION_EXISTE
    FROM REL_CUENTA_PROD 
    WHERE PRODUCTO_GTIN = P_PRODUCTO_GTIN
    AND PRODUCTO_CUENTAID = P_PRODUCTO_CUENTA_ID
    AND ACTIVOS_ID = P_ACTIVO_ID
    AND ACTIVOS_CUENTAID = P_ACTIVO_CUENTA_ID;
    IF V_ASOCIACION_EXISTE > 0 THEN 
        RAISE EXCEPTION_ASOCIACION_DUPLICADA;
    END IF;
    
    INSERT INTO REL_CUENTA_PROD ( PRODUCTO_GTIN, PRODUCTO_CUENTAID, ACTIVOS_ID, ACTIVOS_CUENTAID)
        VALUES ( P_PRODUCTO_GTIN, P_PRODUCTO_CUENTA_ID, P_ACTIVO_ID, P_ACTIVO_CUENTA_ID);
   
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_PLYTIX_UTIL.REGISTRA_ERROR('Producto o activo no encontrado', $$PLSQL_UNIT);
            RAISE;
        WHEN EXCEPTION_ASOCIACION_DUPLICADA THEN
            PKG_PLYTIX_UTIL.REGISTRA_ERROR('Asociación duplicada: ' || SQLCODE || ' - ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
        WHEN OTHERS THEN
            PKG_PLYTIX_UTIL.REGISTRA_ERROR('Error inesperado: ' || SQLCODE || ' - ' || SQLERRM, $$PLSQL_UNIT);
            RAISE;
  END P_ASOCIAR_ACTIVO_A_PRODUCTO;


--9
 PROCEDURE P_CREAR_USUARIO(
    p_usuario  IN USUARIO%ROWTYPE,
    p_rol      IN VARCHAR,
    p_password IN VARCHAR
) IS
    v_usuario_creado BOOLEAN := FALSE;
BEGIN
    -- Crear usuario en la base de datos
    EXECUTE IMMEDIATE 
        'CREATE USER ' || p_usuario.avatar ||
        ' IDENTIFIED BY "' || p_password || '" ' ||
        'DEFAULT TABLESPACE TS_PLYTIX ' ||
        'QUOTA UNLIMITED ON TS_PLYTIX ' ||
        'QUOTA 50M ON TS_INDICES';

    v_usuario_creado := TRUE;

    -- Asignar rol al usuario
    BEGIN
        EXECUTE IMMEDIATE 
            'GRANT ' || p_rol || ' TO ' || p_usuario.avatar;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -1919 THEN  -- ORA-01919: el rol no existe
                RAISE E_ROL_INVALIDO;
            ELSE
                RAISE;
            END IF;
    END;

    -- Insertar en la tabla USUARIO
    BEGIN
        INSERT INTO USUARIO (
            USUARIOID, NOMBREUSUARIO, AVATAR, EMAIL, TELEFONO, CUENTAID, CUENTAID_ALT
        ) VALUES (
            p_usuario.usuarioid, p_usuario.nombreusuario, p_usuario.avatar,
            p_usuario.email, p_usuario.telefono, p_usuario.cuentaid, p_usuario.cuentaid_alt
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -1 THEN  -- ORA-00001: violación de clave única
                RAISE E_USUARIO_YA_EXISTE;
            ELSE
                RAISE;
            END IF;
    END;

    EXCEPTION
        WHEN E_USUARIO_YA_EXISTE THEN
            PKG_PLYTIX_UTIL.REGISTRA_ERROR('Usuario ya existe: ' || p_usuario.usuarioid, $$PLSQL_UNIT);
            IF v_usuario_creado THEN
                BEGIN
                    EXECUTE IMMEDIATE 'DROP USER ' || p_usuario.avatar || ' CASCADE';
                EXCEPTION
                    WHEN OTHERS THEN
                        PKG_PLYTIX_UTIL.REGISTRA_ERROR('Error al eliminar usuario creado: ' || SQLERRM, $$PLSQL_UNIT);
                END;
            END IF;
            RAISE;

    WHEN E_ROL_INVALIDO THEN
        PKG_PLYTIX_UTIL.REGISTRA_ERROR('Rol inválido: ' || p_rol, $$PLSQL_UNIT);
        IF v_usuario_creado THEN
            BEGIN
                EXECUTE IMMEDIATE 'DROP USER ' || p_usuario.avatar || ' CASCADE';
            EXCEPTION
                WHEN OTHERS THEN
                    PKG_PLYTIX_UTIL.REGISTRA_ERROR('Error al eliminar usuario por rol inválido: ' || SQLERRM, $$PLSQL_UNIT);
            END;
        END IF;
        RAISE;

    WHEN OTHERS THEN
        PKG_PLYTIX_UTIL.REGISTRA_ERROR('Error inesperado: ' || SQLERRM, $$PLSQL_UNIT);
        IF v_usuario_creado THEN
            BEGIN
                EXECUTE IMMEDIATE 'DROP USER ' || p_usuario.avatar || ' CASCADE';
            EXCEPTION
                WHEN OTHERS THEN
                    PKG_PLYTIX_UTIL.REGISTRA_ERROR('Error al eliminar usuario tras error general: ' || SQLERRM, $$PLSQL_UNIT);
            END;
        END IF;
        RAISE E_ERROR_GENERAL_USUARIO;
    END P_CREAR_USUARIO;
END PKG_ADMIN_PRODUCTOS;
/



