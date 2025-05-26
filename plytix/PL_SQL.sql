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
    --funciones
    -- 1
   FUNCTION F_OBTENER_PLAN_CUENTA(p_cuenta_id IN CUENTA.CUENTAID%TYPE) 
    RETURN PLAN%ROWTYPE;
    --2
  FUNCTION F_CONTAR_PRODUCTOS_CUENTA (
    p_cuentaid IN NUMBER
  ) RETURN NUMBER;
   -- 3
   FUNCTION F_VALIDAR_ATRIBUTOS_PRODUCTO(
      p_producto_gtin IN PRODUCTO.GTIN%TYPE,
      p_cuenta_id     IN PRODUCTO.CUENTAID%TYPE
   ) RETURN BOOLEAN;
    
--4
    FUNCTION F_NUM_CATEGORIAS_CUENTA(p_cuenta_id IN CUENTA.CUENTAID%TYPE) 
    RETURN NUMBER;
    --5
    
    -- Procedimientos
  PROCEDURE P_ACTUALIZAR_NOMBRE_PRODUCTO (
    p_producto_gtin    IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id        IN PRODUCTO.CUENTAID%TYPE,
    p_nuevo_nombre     IN PRODUCTO.PRODUCTONOMBRE%TYPE
  );
  
   -- 6
   PROCEDURE P_ASOCIAR_ACTIVO_A_PRODUCTO(
      p_producto_gtin         IN PRODUCTO.GTIN%TYPE,
      p_producto_cuenta_id    IN PRODUCTO.CUENTAID%TYPE,
      p_activo_id             IN ACTIVO.ACTIVOID%TYPE,
      p_activo_cuenta_id      IN ACTIVO.CUENTAID%TYPE
   );
    
    --7
    PROCEDURE P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES(
    p_producto_gtin IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id IN PRODUCTO.CUENTAID%TYPE);
   
   -- 8 
     PROCEDURE P_ACTUALIZAR_PRODUCTOS (
    p_cuenta_id IN CUENTA.CUENTAID%TYPE
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
  
  --1
   FUNCTION F_OBTENER_PLAN_CUENTA(p_cuenta_id IN CUENTA.CUENTAID%TYPE)
      RETURN PLAN%ROWTYPE
   IS
      v_plan       PLAN%ROWTYPE;
      v_plan_id    CUENTA.PLAN_PLANID%TYPE;
      v_error_msg  VARCHAR2(4000);
   BEGIN
      -- Obtener el ID del plan asociado a la cuenta
      SELECT PLAN_PLANID INTO v_plan_id
      FROM CUENTA
      WHERE CUENTAID = p_cuenta_id;

      -- Verificar si no tiene plan
      IF v_plan_id IS NULL THEN
         PKG_PLYTIX_UTIL.REGISTRA_ERROR('La cuenta ' || p_cuenta_id || ' no tiene plan asignado' , $$PLSQL_UNIT);
         RAISE EXCEPTION_PLAN_NO_ASIGNADO;
      END IF;

      -- Obtener el plan completo
      SELECT * INTO v_plan
      FROM PLAN
      WHERE PLANID = v_plan_id;

      RETURN v_plan;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         PKG_PLYTIX_UTIL.REGISTRA_ERROR('Cuenta no encontrada: ' || p_cuenta_id , $$PLSQL_UNIT);
         RAISE;
      WHEN OTHERS THEN
       PKG_PLYTIX_UTIL.REGISTRA_ERROR('Error inesperado: ' || SQLERRM , $$PLSQL_UNIT);
         --DBMS_OUTPUT.PUT_LINE(v_error_msg);
         RAISE;
   END F_OBTENER_PLAN_CUENTA;
   
   --2
   
    FUNCTION F_CONTAR_PRODUCTOS_CUENTA (
    p_cuentaid IN NUMBER
  ) RETURN NUMBER
  IS
    v_total_productos NUMBER;
    v_mensaje         VARCHAR2(500);
    v_unidad          VARCHAR2(40) := $$PLSQL_UNIT;
  BEGIN
    SELECT COUNT(*) INTO v_total_productos
    FROM V_ESTANDAR_PRODUCTO
    WHERE CUENTAID = p_cuentaid;

    IF v_total_productos = 0 THEN
      RAISE NO_DATA_FOUND;
    END IF;

    RETURN v_total_productos;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PKG_PLYTIX_UTIL.REGISTRA_ERROR(v_unidad, 'Cuenta no accesible o sin productos');
      RAISE;

    WHEN OTHERS THEN
      v_mensaje := SUBSTR(SQLCODE || ' - ' || SQLERRM, 1, 500);
      PKG_PLYTIX_UTIL.REGISTRA_ERROR(v_unidad, v_mensaje);
      RAISE;
  END F_CONTAR_PRODUCTOS_CUENTA;
  
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

--4
 FUNCTION F_NUM_CATEGORIAS_CUENTA(p_cuenta_id IN CUENTA.CUENTAID%TYPE) 
    RETURN NUMBER
    
    IS
        v_cantidad NUMBER;
    BEGIN
    
        SELECT 1 INTO v_cantidad
        FROM CUENTA
        WHERE CUENTAID = p_cuenta_id;
        
        SELECT COUNT(*) INTO v_cantidad
        FROM CATEGORIA
        WHERE CUENTAID = p_cuenta_id;

        RETURN v_cantidad;
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         PKG_PLYTIX_UTIL.REGISTRA_ERROR('Cuenta no encontrada: ' || p_cuenta_id, $$PLSQL_UNIT);
         RAISE;
    
    END F_NUM_CATEGORIAS_CUENTA;
    
    --5
    PROCEDURE P_ACTUALIZAR_NOMBRE_PRODUCTO (
    p_producto_gtin    IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id        IN PRODUCTO.CUENTAID%TYPE,
    p_nuevo_nombre     IN PRODUCTO.PRODUCTONOMBRE%TYPE
  )
  IS
    v_unidad   VARCHAR2(40) := $$PLSQL_UNIT;
    v_mensaje  VARCHAR2(500);
    INVALID_DATA EXCEPTION;
    PRAGMA EXCEPTION_INIT(INVALID_DATA, -20001);
  BEGIN
    IF p_nuevo_nombre IS NULL OR TRIM(p_nuevo_nombre) = '' THEN
      RAISE INVALID_DATA;
    END IF;

    DECLARE
      v_dummy NUMBER;
    BEGIN
      SELECT 1 INTO v_dummy
      FROM V_ESTANDAR_PRODUCTO
      WHERE GTIN = p_producto_gtin
        AND CUENTAID = p_cuenta_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        PKG_PLYTIX_UTIL.REGISTRA_ERROR(v_unidad, 'Producto no accesible o no existe');
        RAISE NO_DATA_FOUND;
    END;

    UPDATE PRODUCTO
    SET PRODUCTONOMBRE = p_nuevo_nombre
    WHERE GTIN = p_producto_gtin
      AND CUENTAID = p_cuenta_id;

    COMMIT;

  EXCEPTION
    WHEN INVALID_DATA THEN
      PKG_PLYTIX_UTIL.REGISTRA_ERROR(v_unidad, 'Nombre de producto inválido');
      RAISE;

    WHEN OTHERS THEN
      v_mensaje := SUBSTR(SQLCODE || ' - ' || SQLERRM, 1, 500);
      PKG_PLYTIX_UTIL.REGISTRA_ERROR(v_unidad, v_mensaje);
      RAISE;
  END P_ACTUALIZAR_NOMBRE_PRODUCTO;
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
--7
PROCEDURE P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES(
      p_producto_gtin IN PRODUCTO.GTIN%TYPE,
      p_cuenta_id     IN PRODUCTO.CUENTAID%TYPE
   )
   IS
      v_dummy NUMBER;
      v_error_msg VARCHAR2(4000);
   BEGIN
      -- Verificar existencia del producto
      SELECT 1 INTO v_dummy
      FROM PRODUCTO
      WHERE GTIN = p_producto_gtin
        AND CUENTAID = p_cuenta_id;

      -- Orden de eliminación:
      -- 1. RELACIONADO
      DELETE FROM RELACIONADO
      WHERE PRODUCTO_GTIN = p_producto_gtin
        AND PRODUCTO_CUENTAID = p_cuenta_id;

      -- 2. REL_CAT_PROD
      DELETE FROM REL_CAT_PROD
      WHERE PRODUCTO_GTIN = p_producto_gtin
        AND PRODUCTO_CUENTAID = p_cuenta_id;

      -- 3. REL_CUENTA_PRODUCTO
      DELETE FROM REL_CUENTA_PROD
      WHERE PRODUCTO_GTIN = p_producto_gtin
        AND PRODUCTO_CUENTAID = p_cuenta_id;

      -- 4. ATRIBUTO_PRODUCTO
      DELETE FROM ATRIBUTO_PRODUCTO
      WHERE PRODUCTO_GTIN = p_producto_gtin
        AND PRODUCTO_CUENTAID = p_cuenta_id;

      -- 5. PRODUCTO
      DELETE FROM PRODUCTO
      WHERE GTIN = p_producto_gtin
        AND CUENTAID = p_cuenta_id;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         -- Producto no existe ? Propagar excepción directamente
         PKG_PLYTIX_UTIL.REGISTRA_ERROR('El producto no existe' ,  $$PLSQL_UNIT);
         RAISE;

      WHEN OTHERS THEN
         -- Capturar cualquier otro error
         PKG_PLYTIX_UTIL.REGISTRA_ERROR('Error al eliminar producto ' || p_producto_gtin ||
                        ' de cuenta ' || p_cuenta_id,$$PLSQL_UNIT);

         DBMS_OUTPUT.PUT_LINE(v_error_msg);

         ROLLBACK; -- revertir todo si algo falla
         RAISE;
   END P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES;


--8
PROCEDURE P_ACTUALIZAR_PRODUCTOS(p_cuenta_id IN CUENTA.CUENTAID%TYPE)
IS
   v_error_msg VARCHAR2(4000);
BEGIN
   ------------------------------------------------------------------------
   -- 1. Procesar cada producto externo
   ------------------------------------------------------------------------
   FOR r_ext IN (
      SELECT SKU, NOMBRE
      FROM PRODUCTOS_EXT
      WHERE CUENTA_ID = p_cuenta_id
   ) LOOP
      DECLARE
         v_gtin PRODUCTO.GTIN%TYPE;
         v_nombre_actual PRODUCTO.PRODUCTONOMBRE%TYPE;
      BEGIN
         -- Buscar el producto actual en PRODUCTO
         SELECT GTIN, PRODUCTONOMBRE INTO v_gtin, v_nombre_actual
         FROM PRODUCTO
         WHERE SKU = r_ext.SKU AND CUENTAID = p_cuenta_id;
         -- Si el nombre ha cambiado, actualizarlo
         IF UPPER(v_nombre_actual) != UPPER(r_ext.NOMBRE) THEN
         UPDATE PRODUCTO SET PRODUCTONOMBRE = r_ext.NOMBRE
         WHERE SKU = r_ext.SKU 
         AND CUENTAID = p_cuenta_id;
         END IF;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            -- Producto no existe,insertarlo
            INSERT INTO PRODUCTO (
               GTIN,
                SKU,
                PRODUCTONOMBRE,
                CREADO,
                CUENTAID
            ) VALUES (
               NULL,
               SUBSTR(r_ext.SKU,1,10),
               r_ext.NOMBRE,
               SYSDATE,
               p_cuenta_id
               
            );
      END;
   END LOOP;

   ------------------------------------------------------------------------
   -- 2. Eliminar productos que ya no están en PRODUCTO_EXT
   ------------------------------------------------------------------------
   FOR r_prod IN (
      SELECT GTIN
      FROM PRODUCTO
      WHERE CUENTAID = p_cuenta_id
        AND SKU NOT IN (
            SELECT SKU FROM PRODUCTOS_EXT WHERE CUENTA_ID = p_cuenta_id
        )
   ) LOOP
      -- Eliminar producto que ya no está en PRODUCTO_EXT
      P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES(
         p_producto_gtin => r_prod.GTIN,
         p_cuenta_id     => p_cuenta_id
      );
   END LOOP;

EXCEPTION
   WHEN OTHERS THEN
      v_error_msg := 'Error en P_ACTUALIZAR_PRODUCTOS: ' || SQLERRM;
      PKG_PLYTIX_UTIL.REGISTRA_ERROR(v_error_msg,$$PLSQL_UNIT);
     -- DBMS_OUTPUT.PUT_LINE(v_error_msg);
      RAISE;
END P_ACTUALIZAR_PRODUCTOS;
 
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
            IF SQLCODE = -1919 THEN  
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




----PLSQL 2 PARTE

CREATE OR REPLACE PACKAGE PKG_ADMIN_PRODUCTOS_AVANZADO AS
    
    EXCEPTION_PLAN_NO_ASIGNADO EXCEPTION;
    PRAGMA EXCEPTION_INIT(EXCEPTION_PLAN_NO_ASIGNADO, -20001);

    EXCEPTION_ASOCIACION_DUPLICADA EXCEPTION;
    PRAGMA EXCEPTION_INIT(EXCEPTION_ASOCIACION_DUPLICADA, -20002);

    INVALID_DATA EXCEPTION;
    PRAGMA EXCEPTION_INIT(INVALID_DATA, -20003);
    
    FUNCTION F_VALIDAR_PLAN_SUFICIENTE(p_cuenta_id IN CUENTA.CUENTAID%TYPE) 
    RETURN VARCHAR2;
--1

    PROCEDURE P_REPLICAR_ATRIBUTOS(
        p_cuenta_id IN CUENTA.CUENTAID%TYPE, 
        p_producto_gtin_origen IN PRODUCTO.GTIN%TYPE, 
        p_producto_gtin_destino IN PRODUCTO.GTIN%TYPE);
--2
  FUNCTION F_LISTA_CATEGORIAS_PRODUCTO(
    p_producto_gtin IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id     IN PRODUCTO.CUENTAID%TYPE
  ) RETURN VARCHAR2;
  
  --3 
  PROCEDURE P_MIGRAR_PRODUCTOS_A_CATEGORIA(p_cuenta_id IN CUENTA.CUENTAID%TYPE,
    p_categoria_origen_id IN CATEGORIA.CATEGORIAID%TYPE, p_categoria_destino_id IN
    CATEGORIA.CATEGORIAID%TYPE);

END PKG_ADMIN_PRODUCTOS_AVANZADO;
/




CREATE OR REPLACE PACKAGE BODY PKG_ADMIN_PRODUCTOS_AVANZADO AS
    
--1 
FUNCTION F_VALIDAR_PLAN_SUFICIENTE(p_cuenta_id IN CUENTA.CUENTAID%TYPE)
   RETURN VARCHAR2
IS
   v_plan PLAN%ROWTYPE;
   v_error_msg VARCHAR2(4000);

   v_contador_productos        NUMBER;
   v_contador_activos          NUMBER;
   v_contador_cat_producto     NUMBER;
   v_contador_cat_activo       NUMBER;
   v_contador_relaciones       NUMBER;
BEGIN
   -- Obtener el plan desde el otro paquete
   BEGIN
      v_plan := PKG_ADMIN_PRODUCTOS.F_OBTENER_PLAN_CUENTA(p_cuenta_id);
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RAISE;
      WHEN PKG_ADMIN_PRODUCTOS.EXCEPTION_PLAN_NO_ASIGNADO THEN
         RAISE;
   END;

   -- Conteos actuales
   SELECT COUNT(*) INTO v_contador_productos
   FROM PRODUCTO
   WHERE CUENTAID = p_cuenta_id;

   SELECT COUNT(*) INTO v_contador_activos
   FROM ACTIVO
   WHERE CUENTAID = p_cuenta_id;

   SELECT COUNT(*) INTO v_contador_cat_producto
   FROM CATEGORIA
   WHERE CUENTAID = p_cuenta_id;

   SELECT COUNT(*) INTO v_contador_cat_activo
   FROM CATEGORIA_ACTIVO
   WHERE CUENTAID = p_cuenta_id;

   SELECT COUNT(*) INTO v_contador_relaciones
   FROM RELACIONADO
   WHERE PRODUCTO_CUENTAID = p_cuenta_id;

   -- Comparación con límites del plan
   IF v_contador_productos > v_plan.PRODUCTO THEN
      RETURN 'INSUFICIENTE: PRODUCTOS';
   ELSIF v_contador_activos > v_plan.ACTIVO THEN
      RETURN 'INSUFICIENTE: ACTIVOS';
   ELSIF v_contador_cat_producto > v_plan.CATEGORIAPRODUCTO THEN
      RETURN 'INSUFICIENTE: CATEGORIASPRODUCTO';
   ELSIF v_contador_cat_activo > v_plan.CATEGORIAACTIVO THEN
      RETURN 'INSUFICIENTE: CATEGORIAS_ACTIVOS';
   ELSIF v_contador_relaciones > v_plan.RELACIONES THEN
      RETURN 'INSUFICIENTE: RELACIONES';
   ELSE
      RETURN 'SUFICIENTE';
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      v_error_msg := 'Error inesperado en F_VALIDAR_PLAN_SUFICIENTE: ' || SQLERRM;
     PKG_PLYTIX_UTIL.REGISTRA_ERROR(v_error_msg, $$PLSQL_UNIT);
      DBMS_OUTPUT.PUT_LINE(v_error_msg);
      RAISE;
END F_VALIDAR_PLAN_SUFICIENTE;
 

--2
  FUNCTION F_LISTA_CATEGORIAS_PRODUCTO(
    p_producto_gtin IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id     IN PRODUCTO.CUENTAID%TYPE
  ) RETURN VARCHAR2
  IS
    v_unidad   VARCHAR2(40) := $$PLSQL_UNIT;
    v_mensaje  VARCHAR2(500);
    v_lista    VARCHAR2(4000) := '';
    
    CURSOR c_categorias IS
      SELECT C.CATEGORIANOMBRE
      FROM REL_CAT_PROD RCP
      JOIN CATEGORIA C ON RCP.CATEGORIAID = C.CATEGORIAID
                      AND RCP.CATEGORIA_CUENTAID = C.CUENTAID
      WHERE RCP.PRODUCTO_GTIN = p_producto_gtin
        AND RCP.PRODUCTO_CUENTAID = p_cuenta_id;
  BEGIN
    -- Verificar que el producto exista
    DECLARE
      v_dummy NUMBER;
    BEGIN
      SELECT 1 INTO v_dummy
      FROM PRODUCTO
      WHERE GTIN = p_producto_gtin
        AND CUENTAID = p_cuenta_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE NO_DATA_FOUND;
    END;

    -- Recorrer las categorías del producto
    FOR r IN c_categorias LOOP
      v_lista := v_lista || r.CATEGORIANOMBRE || ' ; ';
    END LOOP;

    -- Limpiar la cadena resultante
    IF v_lista IS NULL OR v_lista = '' THEN
      RETURN 'Sin categoría';
    ELSE
      RETURN RTRIM(v_lista, ' ; ');
    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE;
    WHEN OTHERS THEN
      v_mensaje := SUBSTR(SQLCODE || ' - ' || SQLERRM, 1, 500);
       PKG_PLYTIX_UTIL.REGISTRA_ERROR(v_unidad, v_mensaje);
      RAISE;
  END F_LISTA_CATEGORIAS_PRODUCTO;
  
  
  --3
  
  PROCEDURE P_MIGRAR_PRODUCTOS_A_CATEGORIA(p_cuenta_id IN CUENTA.CUENTAID%TYPE,
p_categoria_origen_id IN CATEGORIA.CATEGORIAID%TYPE, p_categoria_destino_id IN
CATEGORIA.CATEGORIAID%TYPE) AS
    CURSOR c_productos IS
          SELECT PC.PRODUCTO_GTIN
          FROM REL_CAT_PROD PC
          WHERE PC.CATEGORIAID = p_categoria_origen_id
            AND EXISTS (
              SELECT 1 FROM PRODUCTO P
              WHERE P.GTIN = PC.PRODUCTO_GTIN
                AND P.CUENTAID = p_cuenta_id
            )
    FOR UPDATE;
    v_cuenta NUMBER;
BEGIN

    DBMS_OUTPUT.PUT_LINE('begin');
    SELECT COUNT(*) INTO V_CUENTA FROM CUENTA WHERE CUENTAID= P_CUENTA_ID ;
    IF V_CUENTA = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;
    
    SELECT COUNT(*) INTO V_CUENTA FROM CATEGORIA WHERE CATEGORIAID = P_CATEGORIA_ORIGEN_ID AND CUENTAID =  P_CUENTA_ID ;
    IF V_CUENTA = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;
    
    SELECT COUNT(*) INTO V_CUENTA FROM CATEGORIA WHERE CATEGORIAID = P_CATEGORIA_DESTINO_ID AND CUENTAID =  P_CUENTA_ID ;
    IF V_CUENTA = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;
 
    FOR PRODUCTO IN C_PRODUCTOS LOOP
      UPDATE REL_CAT_PROD
      SET CATEGORIAID = p_categoria_destino_id
      WHERE PRODUCTO_GTIN = producto.PRODUCTO_GTIN
        AND CATEGORIAID = p_categoria_origen_id
        AND CATEGORIA_CUENTAID = p_cuenta_id
        AND PRODUCTO_CUENTAID = p_cuenta_id;
    END LOOP;
    COMMIT; 
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
          PKG_PLYTIX_UTIL.REGISTRA_ERROR('no data found exception en P_MIGRAR_PRODUCTOS_A_CATEGORIA',$$PLSQL_UNIT);
          ROLLBACK;
          RAISE;
        WHEN OTHERS THEN
         PKG_PLYTIX_UTIL.REGISTRA_ERROR('Error al realizar el proceso',$$PLSQL_UNIT);
          ROLLBACK;
          RAISE;
END P_MIGRAR_PRODUCTOS_A_CATEGORIA;

  --4
    PROCEDURE P_REPLICAR_ATRIBUTOS(
   p_cuenta_id              IN CUENTA.CUENTAID%TYPE,
   p_producto_gtin_origen   IN PRODUCTO.GTIN%TYPE,
   p_producto_gtin_destino  IN PRODUCTO.GTIN%TYPE
)
IS
   -- Cursor para iterar atributos del producto origen
   CURSOR c_atributos_origen IS
      SELECT ATRIBUTO_ID, VALOR
      FROM ATRIBUTO_PRODUCTO
      WHERE PRODUCTO_GTIN = p_producto_gtin_origen
        AND PRODUCTO_CUENTAID = p_cuenta_id;

   -- Variables para control de errores
   v_dummy NUMBER;
   v_error_msg VARCHAR2(4000);
BEGIN
   -- Verificar existencia del producto origen
   SELECT 1 INTO v_dummy
   FROM PRODUCTO
   WHERE GTIN = p_producto_gtin_origen AND CUENTAID = p_cuenta_id;

   -- Verificar existencia del producto destino
   SELECT 1 INTO v_dummy
   FROM PRODUCTO
   WHERE GTIN = p_producto_gtin_destino AND CUENTAID = p_cuenta_id;

   -- Iterar sobre cada atributo del producto origen
   FOR r_atr IN c_atributos_origen LOOP
      -- Verificar si ya existe ese atributo para el producto destino
      SELECT COUNT(*) INTO v_dummy
      FROM ATRIBUTO_PRODUCTO
      WHERE PRODUCTO_GTIN = p_producto_gtin_destino
        AND PRODUCTO_CUENTAID = p_cuenta_id
        AND ATRIBUTO_ID = r_atr.ATRIBUTO_ID;

      IF v_dummy = 0 THEN
         -- Si no existe, insertar
         INSERT INTO ATRIBUTO_PRODUCTO (
            VALOR, PRODUCTO_GTIN, PRODUCTO_CUENTAID, ATRIBUTO_ID, CUENTAID
         ) VALUES (
            r_atr.VALOR, p_producto_gtin_destino, p_cuenta_id, r_atr.ATRIBUTO_ID, p_cuenta_id
         );
      ELSE
         -- Si existe, actualizar el valor
         UPDATE ATRIBUTO_PRODUCTO
         SET VALOR = r_atr.VALOR
         WHERE PRODUCTO_GTIN = p_producto_gtin_destino
           AND PRODUCTO_CUENTAID = p_cuenta_id
           AND ATRIBUTO_ID = r_atr.ATRIBUTO_ID;
      END IF;
   END LOOP;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      PKG_PLYTIX_UTIL.REGISTRA_ERROR('no data found', $$PLSQL_UNIT);
      RAISE;

   WHEN OTHERS THEN
      v_error_msg := 'Error en P_REPLICAR_ATRIBUTOS: ' || SQLERRM;
      PKG_PLYTIX_UTIL.REGISTRA_ERROR(v_error_msg, $$PLSQL_UNIT);
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE(v_error_msg);
      RAISE;
END P_REPLICAR_ATRIBUTOS;

END PKG_ADMIN_PRODUCTOS_AVANZADO;
/






--JOBS

--JOB1

BEGIN
   DBMS_SCHEDULER.CREATE_JOB (
      job_name        => 'LIMPIAR_TRAZA',
      job_type        => 'PLSQL_BLOCK',
      job_action      => 'BEGIN 
                            DELETE FROM TRAZA
                            WHERE FECHA < SYSDATE - INTERVAL ''1'' MINUTE; 
                        END;',
      start_date      => SYSDATE,
      repeat_interval => 'FREQ=MINUTELY; INTERVAL=1', -- cada minuto
      enabled         => TRUE,
      comments        => 'Limpia la tabla TRAZA periódicamente'
   );
END;
/
--COMPROBACIONES:
SELECT job_name, enabled, repeat_interval, next_run_date
FROM USER_SCHEDULER_JOBS
WHERE job_name = 'LIMPIAR_TRAZA';

SELECT log_date, status, error#, additional_info
FROM USER_SCHEDULER_JOB_RUN_DETAILS
WHERE job_name = 'LIMPIAR_TRAZA'
ORDER BY log_date DESC;

--JOB 2


--Actualiza desde la tabla de productos externos los productos de
--la tabla Productos para todas las cuentas de la base de datos llamando a
--P_ACTUALIZAR_PRODUCTOS

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'J_ACTUALIZA_PRODUCTOS',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'DECLARE
                      CURSOR c_cuentas IS SELECT CUENTAID FROM CUENTA;
                    BEGIN
                      FOR r_cuenta IN c_cuentas LOOP
                        P_ACTUALIZAR_PRODUCTOS(r_cuenta.CUENTAID);
                      END LOOP;
                    END;',
    start_date      => SYSDATE,
    repeat_interval => 'FREQ=MINUTELY; INTERVAL=1', -- cada minuto
    enabled         => TRUE,
    comments        => 'actualiza los productos desde la tabla externa para todas las cuentas.' );
END;
/

SELECT job_name, enabled, repeat_interval, next_run_date
FROM USER_SCHEDULER_JOBS
WHERE job_name = 'J_ACTUALIZA_PRODUCTOS';

SELECT log_date, status, error#, additional_info
FROM USER_SCHEDULER_JOB_RUN_DETAILS
WHERE job_name = 'J_ACTUALIZA_PRODUCTOS'
ORDER BY log_date DESC;
--DBMS_SCHEDULER.STOP_JOB ('job1, job2, job3'); 

