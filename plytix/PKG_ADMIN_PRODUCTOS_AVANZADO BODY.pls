create or replace PACKAGE BODY PKG_ADMIN_PRODUCTOS_AVANZADO AS

    

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
      INSERT INTO TRAZA (FECHA, USUARIO, CAUSANTE, DESCRIPCION)
      VALUES (SYSDATE, USER, 'F_VALIDAR_PLAN_SUFICIENTE', v_error_msg);
      DBMS_OUTPUT.PUT_LINE(v_error_msg);
      RAISE;
END F_VALIDAR_PLAN_SUFICIENTE;
    
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
      -- Producto no encontrado
      RAISE;

   WHEN OTHERS THEN
      v_error_msg := 'Error en P_REPLICAR_ATRIBUTOS: ' || SQLERRM;
      INSERT INTO TRAZA (FECHA, USUARIO, CAUSANTE, DESCRIPCION)
      VALUES (SYSDATE, USER, 'P_REPLICAR_ATRIBUTOS', v_error_msg);
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE(v_error_msg);
      RAISE;
END P_REPLICAR_ATRIBUTOS;


END;
