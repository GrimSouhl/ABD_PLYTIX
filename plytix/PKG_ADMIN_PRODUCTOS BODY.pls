create or replace PACKAGE BODY PKG_ADMIN_PRODUCTOS AS 

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
         INSERT INTO TRAZA (FECHA, USUARIO, CAUSANTE, DESCRIPCION)
         VALUES (SYSDATE, USER, 'F_OBTENER_PLAN_CUENTA',
                 'La cuenta ' || p_cuenta_id || ' no tiene plan asignado');
         COMMIT;
         RAISE EXCEPTION_PLAN_NO_ASIGNADO;
      END IF;

      -- Obtener el plan completo
      SELECT * INTO v_plan
      FROM PLAN
      WHERE PLANID = v_plan_id;

      RETURN v_plan;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         INSERT INTO TRAZA (FECHA, USUARIO, CAUSANTE, DESCRIPCION)
         VALUES (SYSDATE, USER, 'F_OBTENER_PLAN_CUENTA',
                 'Cuenta no encontrada: ' || p_cuenta_id);
         COMMIT;
         RAISE;

      WHEN EXCEPTION_PLAN_NO_ASIGNADO THEN
         RAISE;

      WHEN OTHERS THEN
         v_error_msg := 'Error inesperado: ' || SQLERRM;
         INSERT INTO TRAZA (FECHA, USUARIO, CAUSANTE, DESCRIPCION)
         VALUES (SYSDATE, USER, 'F_OBTENER_PLAN_CUENTA', v_error_msg);
         COMMIT;
         DBMS_OUTPUT.PUT_LINE(v_error_msg);
         RAISE;
   END F_OBTENER_PLAN_CUENTA;
    
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
         INSERT INTO TRAZA (FECHA, USUARIO, CAUSANTE, DESCRIPCION)
         VALUES (SYSDATE, USER, 'F_OBTENER_PLAN_CUENTA',
                 'Cuenta no encontrada: ' || p_cuenta_id);
         COMMIT;
         RAISE;
    
    END F_NUM_CATEGORIAS_CUENTA;
    
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
         RAISE;

      WHEN OTHERS THEN
         -- Capturar cualquier otro error
         v_error_msg := 'Error al eliminar producto ' || p_producto_gtin ||
                        ' de cuenta ' || p_cuenta_id || ': ' || SQLERRM;

         DBMS_OUTPUT.PUT_LINE(v_error_msg);

         ROLLBACK; -- ? revertir todo si algo falla
         RAISE;
   END P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES;
    
END PKG_ADMIN_PRODUCTOS;