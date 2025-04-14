/*
Crear una tabla para poder seguir la traza de los errores producidos. La tabla tendrá los siguientes
atributos:
Fecha Date
Usuario VARCHAR2(40)
Causante VARCHAR2(40)
Descripcion VARCHAR2(500)
*/

CREATE TABLE TRAZA (
    Fecha Date,
    Usuario VARCHAR2(40),
    Causante VARCHAR2(40),
    Descripcion VARCHAR2(500)
);

/*
Así, por ejemplo, un procedimiento que capture una excepción podrá ejecutar una sentencia como la
siguiente.
insert into traza values (sysdate,user, $$PLSQL_UNIT,
 SQLCODE||' '||SUBSTR(SQL_ERRM, 1, 500));
$$PLSQL_UNIT devuelve el procedimiento o paquete en ejecución
*/

/*
Crear un paquete PL/SQL (PKG_ADMIN_PRODUCTOS) que contenga funciones y procedimientos
para:
• Gestión de Cuentas y Planes: Facilitar la obtención de información resumida y la validación
de datos relacionados con cuentas y planes.
• Gestión de Productos: Proporcionar herramientas para consultar y manipular información de
productos de manera eficiente.
• Gestión de Activos: Ofrecer funciones para verificar la integridad de los activos asociados a
productos y categorías.
• Gestión de Categorías: Facilitar la consulta de información sobre categorías.
• Gestión de Usuarios: Obtener información de usuarios asociada a las cuentas. 
*/

CREATE OR REPLACE PACKAGE PKG_ADMIN_PRODUCTOS AS 

   FUNCTION F_OBTENER_PLAN_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) 
   RETURN PLAN%ROWTYPE;
   
   FUNCTION F_VALIDAR_ATRIBUTOS_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE) 
   RETURN BOOLEAN;
   
   FUNCTION F_NUM_CATEGORIAS_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) 
   RETURN NUMBER;
    
   FUNCTION F_NUM_CATEGORIAS_CUENTA(p_cuenta_id IN CUENTA.ID%TYPE) 
   RETURN NUMBER;
   
   FUNCTION P_ACTUALIZAR_NOMBRE_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE, p_nuevo_nombre IN PRODUCTO.NOMBRE%TYPE);
   
   FUNCTION P_ASOCIAR_ACTIVO_A_PRODUCTO(p_producto_gtin IN PRODUCTO.GTIN%TYPE, p_producto_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE, 
                                                p_activo_id IN ACTIVOS.ID%TYPE, p_activo_cuenta_id IN ACTIVOS.CUENTA_ID%TYPE);

   FUNCTION P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES(p_producto_gtin IN PRODUCTO.GTIN%TYPE, p_cuenta_id IN PRODUCTO.CUENTA_ID%TYPE);
   
   FUNCTION P_CREAR_USUARIO(p_usuario IN USUARIO%ROWTYPE, p_rol IN VARCHAR, p_password IN VARCHAR);
   
   FUNCTION P_ACTUALIZAR_PRODUCTOS(p_cuenta_id IN CUENTA.ID%TYPE);

END;
/







