# BUSKIT Soporte Remoto para Windows

Aplicación de soporte basada en RustDesk 1.5.0, personalizada por BUSKIT.
El mismo cliente permite recibir asistencia y atender varios equipos en ventanas o pestañas independientes.

## Descargar y abrir

Descargas oficiales de este proyecto: https://github.com/sdmcl/buskit-soporte-remoto/releases

- `BUSKIT-Soporte-Remoto.exe`: aplicación portátil; permite instalar el servicio desde su pantalla inicial.
- `BUSKIT-Soporte-Remoto.msi`: instalación administrada para Windows x64.
- `SHA256SUMS.txt`: comprobación de integridad de los archivos de cada versión.

La aplicación ya incorpora el servidor y la clave pública de BUSKIT. No necesitas introducirlos.
Esta edición inicial no dispone de firma Authenticode comercial. Windows puede mostrar “editor desconocido”; no desactives Defender ni las protecciones del equipo. Verifica el origen y el SHA-256 antes de instalar.

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
4. En el modo de aceptación de conexiones selecciona **Contraseña** (o **Contraseña y clic** si quieres permitir también la autorización manual). “Contraseña y clic” admite cualquiera de los dos métodos; no exige ambos a la vez.
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

La identidad técnica es `BUSKITSoporteRemoto`, con configuración independiente de RustDesk. Los nombres visibles del producto llevan espacios. Conserva los archivos de configuración privados en el equipo; no los publiques en incidencias.

Las actualizaciones de esta primera versión se descargan manualmente desde las Releases de BUSKIT. La actualización automática del RustDesk original está desactivada para conservar la personalización y el servidor configurado.

No se incluyen cuentas centrales, agenda sincronizada ni consola Pro. Se conservan el historial local, control remoto, transferencia de archivos y funciones nativas compatibles. Esta compilación inicial no empaqueta controladores opcionales de pantalla virtual ni impresión remota.

Documentación técnica oficial del acceso desatendido: https://rustdesk.com/docs/en/self-host/client-configuration/advanced-settings/
