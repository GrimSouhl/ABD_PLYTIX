CREATE OR REPLACE PACKAGE PKG_ADMIN_PRODUCTOS AS

  -- Funciones
  FUNCTION F_CONTAR_PRODUCTOS_CUENTA (
    p_cuentaid IN NUMBER
  ) RETURN NUMBER;

  -- Procedimientos
  PROCEDURE P_ACTUALIZAR_NOMBRE_PRODUCTO (
    p_producto_gtin    IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id        IN PRODUCTO.CUENTAID%TYPE,
    p_nuevo_nombre     IN PRODUCTO.PRODUCTONOMBRE%TYPE
  );

  PROCEDURE P_ACTUALIZAR_PRODUCTOS (
    p_cuenta_id IN CUENTA.CUENTAID%TYPE
  );

  PROCEDURE P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES (
    p_producto_gtin IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id     IN PRODUCTO.CUENTAID%TYPE
  );

END PKG_ADMIN_PRODUCTOS;
/


CREATE OR REPLACE PACKAGE BODY PKG_ADMIN_PRODUCTOS AS

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
      REGISTRAR_TRAZA(v_unidad, 'Cuenta no accesible o sin productos');
      COMMIT;
      RAISE;

    WHEN OTHERS THEN
      v_mensaje := SUBSTR(SQLCODE || ' - ' || SQLERRM, 1, 500);
      REGISTRAR_TRAZA(v_unidad, v_mensaje);
      COMMIT;
      RAISE;
  END F_CONTAR_PRODUCTOS_CUENTA;

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
        REGISTRAR_TRAZA(v_unidad, 'Producto no accesible o no existe');
        RAISE NO_DATA_FOUND;
    END;

    UPDATE PRODUCTO
    SET PRODUCTONOMBRE = p_nuevo_nombre
    WHERE GTIN = p_producto_gtin
      AND CUENTAID = p_cuenta_id;

    COMMIT;

  EXCEPTION
    WHEN INVALID_DATA THEN
      REGISTRAR_TRAZA(v_unidad, 'Nombre de producto inválido');
      RAISE;

    WHEN OTHERS THEN
      v_mensaje := SUBSTR(SQLCODE || ' - ' || SQLERRM, 1, 500);
      REGISTRAR_TRAZA(v_unidad, v_mensaje);
      RAISE;
  END P_ACTUALIZAR_NOMBRE_PRODUCTO;

  PROCEDURE P_ACTUALIZAR_PRODUCTOS (
    p_cuenta_id IN CUENTA.CUENTAID%TYPE
)
IS
    CURSOR c_ext IS
        SELECT SKU, NOMBRE
        FROM PRODUCTOS_EXT
        WHERE CUENTA_ID = p_cuenta_id;

    v_nombre_actual PRODUCTO.PRODUCTONOMBRE%TYPE;
    v_unidad  VARCHAR2(40) := $$PLSQL_UNIT;
    v_mensaje VARCHAR2(500);
BEGIN
    -- 1. Recorrer PRODUCTOS_EXT
    FOR r IN c_ext LOOP
        BEGIN
            -- Intentar obtener el nombre actual del producto (si existe)
            SELECT PRODUCTONOMBRE INTO v_nombre_actual
            FROM PRODUCTO
            WHERE SKU = r.SKU AND CUENTAID = p_cuenta_id;

            -- Si el nombre ha cambiado, actualizar
            IF v_nombre_actual != r.NOMBRE THEN
                P_ACTUALIZAR_NOMBRE_PRODUCTO(r.SKU, p_cuenta_id, r.NOMBRE);
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Producto no existe, lo insertamos
                INSERT INTO PRODUCTO (SKU, CUENTAID, PRODUCTONOMBRE)
                VALUES (r.SKU, p_cuenta_id, SUBSTR(r.NOMBRE, 1, 100)); -- ajusta el 100 si tu columna tiene otro tamaño
        END;
    END LOOP;

    -- 2. Eliminar productos que ya no están en PRODUCTOS_EXT
    FOR r IN (
        SELECT SKU
        FROM PRODUCTO
        WHERE CUENTAID = p_cuenta_id
          AND SKU NOT IN (
              SELECT SKU FROM PRODUCTOS_EXT WHERE CUENTA_ID = p_cuenta_id
          )
    ) LOOP
        P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES(r.SKU, p_cuenta_id);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        v_mensaje := SUBSTR(SQLCODE || ' - ' || SQLERRM, 1, 500);
        REGISTRAR_TRAZA(v_unidad, v_mensaje);
        RAISE;
  END P_ACTUALIZAR_PRODUCTOS;

  PROCEDURE P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES (
    p_producto_gtin IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id     IN PRODUCTO.CUENTAID%TYPE
  )
  IS
    v_dummy NUMBER;
    v_error_msg VARCHAR2(4000);
  BEGIN
    SELECT 1 INTO v_dummy
    FROM PRODUCTO
    WHERE GTIN = p_producto_gtin
      AND CUENTAID = p_cuenta_id;

    DELETE FROM RELACIONADO
    WHERE PRODUCTO_GTIN = p_producto_gtin
      AND PRODUCTO_CUENTAID = p_cuenta_id;

    DELETE FROM REL_CAT_PROD
    WHERE PRODUCTO_GTIN = p_producto_gtin
      AND PRODUCTO_CUENTAID = p_cuenta_id;

    DELETE FROM REL_CUENTA_PROD
    WHERE PRODUCTO_GTIN = p_producto_gtin
      AND PRODUCTO_CUENTAID = p_cuenta_id;

    DELETE FROM ATRIBUTO_PRODUCTO
    WHERE PRODUCTO_GTIN = p_producto_gtin
      AND PRODUCTO_CUENTAID = p_cuenta_id;

    DELETE FROM PRODUCTO
    WHERE GTIN = p_producto_gtin
      AND CUENTAID = p_cuenta_id;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE;

    WHEN OTHERS THEN
      v_error_msg := 'Error al eliminar producto ' || p_producto_gtin ||
                     ' de cuenta ' || p_cuenta_id || ': ' || SQLERRM;
      DBMS_OUTPUT.PUT_LINE(v_error_msg);
      ROLLBACK;
      RAISE;
  END P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES;

END PKG_ADMIN_PRODUCTOS;
/
