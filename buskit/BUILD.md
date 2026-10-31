# Compilación y mantenimiento

Base: RustDesk `1.5.0`, commit `fada664df7a294d1d1a9ca3e7cd3637069122f17`.
Submódulo `libs/hbb_common`: `229b904508364c8997aad0fb5af57effac859f60`.

Carpeta canónica de trabajo: `C:\dev\buskit\Buses_BusKIT\soporte_remoto`.
Rama inicial: `feat/buskit-soporte-remoto`. `main` publica la línea entregada.

## Recursos de marca

`buskit/brand.json` centraliza el nombre, edición y conexión pública.
`buskit/brand/source` conserva los vectores oficiales sin modificar.

```powershell
cd buskit/tools
npm ci --ignore-scripts
npm run build
```

Genera los SVG/PNG/ICO, constantes Rust/Dart y recursos Flutter/Windows. El descriptor usa Segoe UI; para reproducir exactamente los PNG usa Windows con esa fuente. Al cambiar la versión, alinea también los metadatos de empaquetado en el workflow y revisa los recursos de versión de Windows. La versión base del protocolo sigue siendo 1.5.0; la edición BUSKIT se muestra aparte.

## Windows x64

Ejecutar **Actions → BUSKIT Windows x64 → Run workflow**. Se usan runners estándar públicos Ubuntu 22.04 y Windows 2022; no se usan runners de pago, Pro ni servicios de firma.

El flujo genera el puente Flutter/Rust, compila el auxiliar de ventanas fijado por upstream, instala las bibliotecas nativas con vcpkg y compila Rust 1.75 + Flutter 3.24.5. Después crea EXE portátil, MSI y un paquete de fuentes con el submódulo incluido. Las acciones se fijan por SHA. El motor Flutter especial sigue la URL de release usada por upstream y registra su SHA-256 en el log; esa dependencia mutable impide prometer una compilación idéntica bit a bit.

Los workflows originales que publican para otras plataformas se conservan en `buskit/upstream-workflows` fuera de la ruta ejecutable. Los workflows auxiliares reutilizados solo admiten `workflow_call`.

El workflow solo crea un artefacto temporal. Descargarlo a `dist/installer` en la carpeta canónica, verificar SHA-256, iniciar el EXE, comprobar marca/conexión y probar el MSI en un Windows de ensayo antes de publicar una versión estable. Una compilación correcta no prueba una sesión entre dos equipos.

El MSI se compila con cultura `es-es`, gráficos de `buskit/brand/installer-*.png` y carpeta fija `C:\BusKIT\Soporte`. `brand.json` define la edición y `msiVersion`: la edición 1.5.0-buskit.2 usa MSI 1.5.2.0. Se incrementa uno de los tres primeros campos porque Windows Installer ignora el cuarto al detectar actualizaciones. Se conserva el UpgradeCode derivado de `BUSKITSoporteRemoto.exe` y se permite detectar el paquete anterior en inglés.

`buskit/tools/test-msi.ps1` se ejecuta exclusivamente en el runner Windows desechable: instalación nueva con intentos de cambiar la ruta, reparación y desinstalación. Comprueba idioma, textos, servicio automático, accesos directos, registro, permisos de la carpeta del servicio y conservación de una aplicación vecina bajo BusKIT. Los logs quedan en el artefacto `BUSKIT-MSI-validation`. Esta prueba no sustituye una sesión remota real ni la validación de contraseña y reinicio en el PC del cliente.

Hay cambios de preferencias y de Acerca de preparados sin compilar ni publicar. La versión y el MSI continúan en `1.5.0-buskit.2` / `1.5.2.0`. La prueba ampliada queda preparada para consultar los valores iniciales de configuración remota (`Y`), contraseña temporal numérica (`Y`) y longitud (`6`); luego cambia los tres y comprueba que conserva esas elecciones después de reparar y reiniciar el servicio. Estas comprobaciones nuevas no se han ejecutado todavía.

El 31 de octubre de 2026, Pablo confirmó que la instalación y las pruebas de la edición `1.5.0-buskit.2` fueron exitosas, y aportó una captura de una sesión remota conectada. Esa confirmación corresponde a esa edición; no se infiere de ella una prueba específica de reinicio.

## Publicación

Publicar Releases con EXE, MSI, fuentes completas, `LICENCE`, guía y `SHA256SUMS.txt`. Conservar siempre el tag/commit correspondiente a cada binario y las instrucciones para construirlo, conforme a AGPL-3.0.

No añadir contraseñas de clientes, llaves privadas, configuraciones locales, credenciales SSH ni archivos de datos del servidor al repositorio. `brand.json` contiene solo la clave pública.

## Superficie de regresión

- `src/buskit.rs`: inicialización de nombre técnico, servidor, clave pública, idioma y opciones OSS. Activa `hide-powered-by-me` para ocultar la leyenda promocional en todas las interfaces; conserva los avisos legales. No modifica el protocolo ni autenticación de contraseñas.
- Los cambios pendientes en `src/buskit.rs` añaden `access-mode=full`, `allow-remote-config-modification=Y`, `allow-numeric-one-time-password=Y` y `temporary-password-length=6` a los valores predeterminados que leen la interfaz y el servicio. La configuración guardada conserva prioridad, incluido un modo de acceso personalizado. No se usa una opción forzada ni se modifica el manejo compartido de permisos o generación de contraseñas. `buskit/tools/test-msi.ps1` comprueba estos valores y la persistencia de la elección del usuario tras reparar; su ejecución queda pendiente de la próxima compilación autorizada.
- El cambio pendiente en `flutter/lib/desktop/pages/desktop_setting_page.dart` afecta únicamente a Acerca de: retira el bloque de copyright y lema y los enlaces de privacidad, código fuente y licencias. Conserva nombre, versión, fecha de compilación, huella digital e ID. No se altera el resto de los ajustes ni los documentos de licencia y atribuciones incluidos en la distribución.
- `src/common.rs` y `src/lib.rs`: un enlace de inicio y registro del módulo.
- `src/flutter.rs`, `src/flutter_ffi.rs`, `src/core_main.rs`: nombre visible y búsqueda de la ventana coherentes; servicios, directorios y URI usan el identificador sin espacios.
- `src/lang.rs`: sustitución del nombre visible en textos; atribución RustDesk preservada.
- Flutter `common.dart`, ajustes y recursos: colores, logo, iconos, versión BUSKIT y enlaces de fuente/privacidad. La pantalla principal limita el área desplazable del panel izquierdo para que la instalación siga accesible con logo y nombres largos; el aviso abrevia únicamente el nombre a BUSKIT.
- Recursos Windows y portable: metadatos e iconos del producto. MSI utiliza el empaquetado upstream con identidad independiente.
- `src/platform/windows.rs`: la instalación desde el EXE propone la ruta fija C:/BusKIT/Soporte; la lectura de instalaciones existentes conserva su ruta registrada. MSI y EXE protegen la carpeta del servicio: administradores y SYSTEM pueden modificarla, usuarios normales pueden leer y ejecutar. No se cambian los permisos de la carpeta compartida BusKIT ni de otros sistemas.
- `res/msi/Package`: ruta fija, asistente español, gráficos BUSKIT, nombre visible y actualización desde el MSI anterior. Servicio y configuración conservan el identificador técnico. Se oculta la opción de impresora porque esta distribución no incluye ese controlador.

No se modifica `libs/hbb_common`, captura de pantalla, cifrado, transporte, teclado, contraseña permanente o motor de sesiones. No se modifica el servidor Linux ni ningún proceso de seguimiento/GPS al compilar este cliente.
