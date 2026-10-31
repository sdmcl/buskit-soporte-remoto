# BUSKIT Soporte Remoto para Windows

Aplicación de soporte basada en RustDesk 1.5.0, personalizada por BUSKIT.
El mismo cliente permite recibir asistencia y atender varios equipos en ventanas o pestañas independientes.

## Descargar y abrir

Descarga MSI: https://sdm.cl/empresas/BUSKIT/soporte-remoto/BUSKIT-Soporte-Remoto.msi

Descarga EXE: https://sdm.cl/empresas/BUSKIT/soporte-remoto/BUSKIT-Soporte-Remoto.exe

También disponibles en GitHub: https://github.com/sdmcl/buskit-soporte-remoto/releases

- `BUSKIT-Soporte-Remoto.exe`: aplicación portátil; permite instalar el servicio desde su pantalla inicial.
- `BUSKIT-Soporte-Remoto.msi`: instalación administrada para Windows x64.
- `SHA256SUMS.txt`: comprobación de integridad de los archivos de cada versión.

La aplicación ya incorpora el servidor y la clave pública de BUSKIT. No necesitas introducirlos.
Esta edición inicial no dispone de firma Authenticode comercial. Windows puede mostrar “editor desconocido”; no desactives Defender ni las protecciones del equipo. Verifica el origen y el SHA-256 antes de instalar.

## Instalador en español y carpeta fija

Desde la edición `1.5.0-buskit.2`, el MSI muestra el asistente en español, con el logo y los colores de BUSKIT. Instala siempre en:

```text
C:\BusKIT\Soporte\BUSKITSoporteRemoto.exe
```

Los otros sistemas deben abrir esa ruta exacta, también si son aplicaciones de 32 bits. La carpeta es fija en instalaciones normales y silenciosas; no se cambia desde el asistente ni con `INSTALLFOLDER`.

Esta entrega se prepara para instalaciones nuevas: no necesitas mover carpetas ni desinstalar una versión anterior. Usa el MSI como instalador habitual de los clientes.

## Novedades de 1.5.0-buskit.3

La edición `1.5.0-buskit.3` deja **Configuración → Seguridad → Permisos → Acceso completo** seleccionado por defecto. Habilita los permisos disponibles para una sesión autorizada, incluida la modificación remota de configuración. Puede cambiarse después a **Personalizado** o **Compartir pantalla**; para deshabilitar permisos individuales, seleccionar **Personalizado** y desmarcarlos. No elimina el requisito de contraseña o aceptación configurado para conectarse.

También deja la **contraseña temporal numérica de 6 dígitos** como valor predeterminado. El programa la genera para cada equipo; no se incorpora una contraseña compartida ni se cambia la contraseña permanente. La longitud y el uso de números pueden modificarse después.

En **Acerca de** quedan el nombre, versión, fecha de compilación, huella digital e ID. Se retiran el bloque de copyright y lema y los tres enlaces de privacidad, código fuente y licencias. Los documentos de licencia y atribuciones se conservan en la distribución y en el repositorio.

Al actualizar un equipo existente, se respeta una elección guardada explícitamente. Esta opción no define una contraseña ni reemplaza la autenticación de la conexión. Tampoco habilita el permiso independiente para aceptar otras conexiones desde la ventana de permisos.

Estos cambios corresponden a `1.5.0-buskit.3` (MSI `1.5.3.0`). Los equipos con `1.5.0-buskit.2` deben instalar el nuevo MSI; se conservan los ajustes guardados.

### Perfil del técnico y descarga desde la aplicación

Se incluye el botón **Descargar última versión** en **Inicio** y **Ajustes → General → BUSKIT Soporte Remoto**. Abre en el navegador la URL fija del MSI indicada al principio de esta guía. El enlace lleva a la última edición publicada; no instala automáticamente ni cambia según la versión en los sistemas que lo utilizan.

Para identificar al técnico después de instalar esta edición:

1. En el PC desde el que das soporte, abre **Ajustes → General → BUSKIT Soporte Remoto → Perfil del técnico**.
2. Marca **Usar este equipo como técnico BUSKIT**.
3. Conserva **Pablo · Soporte BUSKIT**, o escribe el nombre que verá el cliente, y pulsa **Guardar perfil**.
4. Al iniciar la siguiente conexión, el cliente verá ese nombre y el logo BUSKIT en lugar de la inicial. La imagen se incluye en la aplicación y se transmite con la conexión; no necesita una cuenta Pro ni descargar una imagen externa.

El perfil viene desactivado en las instalaciones nuevas. Déjalo desactivado en los equipos que reciben asistencia. Es una preferencia local del usuario de Windows, no una cuenta ni un permiso adicional. Para volver a la identificación habitual, desmarca la opción y guarda el perfil. No modifica sesiones que ya estén abiertas.

## Asistencia con una persona presente

1. El cliente abre la aplicación y espera el estado **Listo**.
2. Comparte su ID con el técnico de BUSKIT.
3. El técnico abre su propia aplicación, introduce ese ID y conecta.
4. El cliente autoriza la solicitud o comunica su contraseña temporal por un canal de confianza.
5. El cliente puede terminar la sesión en cualquier momento.

## Acceso desatendido con contraseña propia del equipo

Esta función está disponible sin RustDesk Pro. Debe configurarse previamente en el Windows de destino, con autorización de su responsable.

1. Instala el MSI, o pulsa **Instalar** en la aplicación portátil, y acepta la elevación de Windows con una cuenta administradora. El servicio debe iniciar automáticamente con Windows.
2. Abre **Configuración → Seguridad** y desbloquea los ajustes si Windows lo solicita.
3. En **Contraseña**, selecciona **Usar contraseña permanente** y establece una contraseña larga y única para ese equipo. También existe **Usar ambas contraseñas**, que conserva la temporal para atención presencial.
4. Selecciona **Aceptar sesiones a través de contraseña** (o **Aceptar sesiones a través de ambos** si quieres permitir también la autorización manual). “Ambos” admite contraseña o clic; no exige los dos a la vez.
5. No actives la restricción de recibir conexiones solo cuando esté abierta la ventana. Mantén encendido y conectado el equipo; un PC suspendido o apagado no podrá atender una sesión normal.
6. Anota el ID del equipo y guarda su contraseña en un gestor de contraseñas, separada del código fuente y de la lista de clientes.
7. Desde el equipo del técnico, conecta a ese ID con la contraseña permanente.
8. Valida con una persona presente: conexión, cierre de ventana, bloqueo de Windows y reinicio. Comprueba que el servicio vuelve a **Listo** y que puedes reconectar antes de considerar terminada la instalación.

La contraseña no se distribuye en el instalador ni se define en el servidor Linux. Esta versión no fuerza contraseñas permanentes por defecto. No hay una contraseña maestra para todos los clientes.

Para retirar el acceso: cambia/elimina la contraseña permanente, vuelve a autorización manual o desinstala el programa. Si recuerdas la contraseña en el PC del técnico, protege también ese equipo y su sesión de Windows.

## Varias sesiones

Desde la pantalla principal, conecta al primer ID y luego al segundo. Cada sesión se identifica por su equipo y puede abrirse en una ventana independiente. La edición OSS no impone una licencia por puesto; la capacidad real depende del ancho de banda y los equipos.

## Datos de red incorporados

| Campo | Valor |
| --- | --- |
| Servidor ID | `190.110.124.99:21116` |
| Servidor relay | `190.110.124.99:21117` |
| Clave pública | `8EynR+X5Es5POkXAgJgE8qp2DWlhLqHT3SUHeVUz6WQ=` |
| Servidor API | Vacío; servidor OSS |

La clave anterior es pública y autentica el servidor; **no es una contraseña de acceso al escritorio**. El servidor necesita TCP 21115–21117 y UDP 21116. No necesitas abrir puertos entrantes en los routers de los clientes para la conexión normal mediante relay.

## Datos locales y actualizaciones

La identidad técnica del servicio y del MSI es `BUSKITSoporteRemoto`, con configuración independiente de RustDesk. La ventana principal muestra **BUSKIT Soporte Remoto**. Conserva los archivos de configuración privados en el equipo; no los publiques en incidencias.

Las actualizaciones de esta primera versión se descargan manualmente desde el hosting de BUSKIT o GitHub Releases. La actualización automática del RustDesk original está desactivada para conservar la personalización y el servidor configurado.

No se incluyen cuentas centrales, agenda sincronizada ni consola Pro. Se conservan el historial local, control remoto, transferencia de archivos y funciones nativas compatibles. Esta compilación inicial no empaqueta controladores opcionales de pantalla virtual ni impresión remota.

Documentación técnica oficial del acceso desatendido: https://rustdesk.com/docs/en/self-host/client-configuration/advanced-settings/
