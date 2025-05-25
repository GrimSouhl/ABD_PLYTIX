CREATE OR REPLACE PACKAGE PKG_ADMIN_PRODUCTOS_AVANZADO AS
  FUNCTION F_LISTA_CATEGORIAS_PRODUCTO(
    p_producto_gtin IN PRODUCTO.GTIN%TYPE,
    p_cuenta_id     IN PRODUCTO.CUENTAID%TYPE
  ) RETURN VARCHAR2;
  
  PROCEDURE J_LIMPIA_TRAZA(p_dias IN NUMBER DEFAULT 365);

END PKG_ADMIN_PRODUCTOS_AVANZADO;
/




CREATE OR REPLACE PACKAGE BODY PKG_ADMIN_PRODUCTOS_AVANZADO AS

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
      REGISTRAR_TRAZA(v_unidad, v_mensaje);
      RAISE;
  END F_LISTA_CATEGORIAS_PRODUCTO;
  
  PROCEDURE J_LIMPIA_TRAZA(p_dias IN NUMBER DEFAULT 365)
IS
    v_unidad   VARCHAR2(40) := $$PLSQL_UNIT;
    v_mensaje  VARCHAR2(500);
    v_count    NUMBER;
BEGIN
    -- Contar cuántas entradas serán eliminadas (opcional, para control)
    SELECT COUNT(*) INTO v_count
    FROM TRAZA
    WHERE FECHA < SYSDATE - p_dias;

    -- Eliminar
    DELETE FROM TRAZA
    WHERE FECHA < SYSDATE - p_dias;

    COMMIT;

    -- Registrar limpieza exitosa si se desea
    IF v_count > 0 THEN
        REGISTRAR_TRAZA(v_unidad, 'Limpieza de traza exitosa. ' || v_count || ' registros eliminados.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        v_mensaje := SUBSTR(SQLCODE || ' - ' || SQLERRM, 1, 500);
        REGISTRAR_TRAZA(v_unidad, 'Error en limpieza de traza: ' || v_mensaje);
        RAISE;
END J_LIMPIA_TRAZA;


END PKG_ADMIN_PRODUCTOS_AVANZADO;
/
