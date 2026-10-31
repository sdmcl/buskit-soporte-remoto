# Descargas en el hosting de agencias

El destino es el hosting de instaladores `sdm.cl`, publicado por FTPS explicito
en `sdm6.dhn.cl:21`, con validacion TLS. No es el servidor `segui-api`.

Carpeta propia: `/public_html/empresas/BUSKIT/soporte-remoto/`.

Publicado el 31 de octubre de 2026. Se comprobaron los siete archivos de la
version por FTPS y HTTPS, los enlaces fijos y el manifiesto propio. Los manifiestos
de Agencia ETM y QueilenBus conservaron exactamente su contenido anterior.

## Enlaces publicos

- MSI: https://sdm.cl/empresas/BUSKIT/soporte-remoto/BUSKIT-Soporte-Remoto.msi
- EXE: https://sdm.cl/empresas/BUSKIT/soporte-remoto/BUSKIT-Soporte-Remoto.exe
- Manifiesto: https://sdm.cl/empresas/BUSKIT/soporte-remoto/latest.json
- Fuentes: https://sdm.cl/empresas/BUSKIT/soporte-remoto/BUSKIT-Soporte-Remoto-source.zip
- Hashes: https://sdm.cl/empresas/BUSKIT/soporte-remoto/SHA256SUMS.txt

El enlace que debe guardar el sistema de pasajes es el MSI fijo de esta lista.
No debe incluir `releases` ni un numero de version. Al publicar otra entrega se
cambia el destino interno de la redireccion; el enlace del sistema de pasajes
permanece igual. La respuesta utiliza `Cache-Control: no-store` para no fijar
en cache el destino de una entrega anterior.

La carpeta raiz redirige al MSI. `.htaccess` mantiene enlaces fijos mediante
redirecciones temporales; los archivos reales se conservan en
`releases/1.5.0-buskit.3/`. El manifiesto identifica esa version como preliminar.
GitHub Releases conserva una segunda descarga de los mismos bytes.

La edicion `1.5.0-buskit.3` incluye el MSI `1.5.3.0` en espanol, con el logo
y los colores de BUSKIT. Instala en `C:\BusKIT\Soporte`; el ejecutable para
integraciones es `C:\BusKIT\Soporte\BUSKITSoporteRemoto.exe`.

La [compilacion 41236312527](https://github.com/sdmcl/buskit-soporte-remoto/actions/runs/41236312527)
comprobo instalacion nueva, reparacion, actualizacion desde el MSI
`1.5.0-buskit.2` y desinstalacion en Windows. Valido ruta fija incluso al pasar
otra por linea de comandos, permisos de la carpeta, servicio activo y automatico,
registro y acceso directo. Tambien comprobo acceso completo, configuracion remota,
contrasena temporal numerica de seis digitos y conservacion de elecciones al
reparar y actualizar. La carpeta de otro sistema BusKIT se conservo. Las seis
operaciones MSI terminaron con codigo 0; el log de actualizacion confirma que
se instalaron los nuevos `librustdesk.dll` y `data/app.so`.

Se verificaron los SHA-256 de los siete archivos en FTPS, HTTPS y GitHub.
La descarga completa usando la URL fija del MSI coincide con:

`b9f6cdad99f781f07ccb96cb20fc3678e7d89589872325238fb7760b84cfd3de`

La entrega incluye Acerca de simplificado, perfil local de tecnico con logo
BUSKIT y nombre editable, y boton de descarga fija en Inicio y Ajustes.
El perfil se activa solo en el PC del tecnico; los equipos clientes no lo
activan por defecto. La guia explica como hacerlo.

Estas pruebas no sustituyen la comprobacion visual del avatar y una conexion
real entre dos equipos con esta nueva edicion, ni la reconexion despues de
reiniciar Windows. La edicion se mantiene marcada como preliminar. La version
anterior y los respaldos del manifiesto y redirecciones se conservaron.

## Publicar otra version

1. Descargar los artefactos verificados a `dist/installer` en la carpeta canonica.
2. Comprobar los SHA-256, la version, el commit de fuentes y las pruebas de entrega.
3. Crear un directorio nuevo `releases/<version>/`. Subir EXE, MSI, fuentes,
   guia, `LICENCE`, `LICENSE-NOTICE.txt` y `SHA256SUMS.txt` mediante FTPS.
4. Subir cada archivo con nombre temporal, descargarlo por FTPS y comparar su
   SHA-256 antes de renombrarlo. No sobrescribir una version anterior diferente.
5. Descargar los archivos definitivos por HTTPS y comprobar nuevamente sus hashes.
6. Actualizar `latest.json` y los destinos de `.htaccess` solamente cuando esten
   verificados todos los archivos. Conservar una copia de ambos antes del cambio.
7. Verificar los enlaces fijos y que los manifiestos de ETM y QueilenBus sigan iguales.

No se cambian los instaladores, manifiestos ni activaciones SQL de otras empresas.
No se modifica Nginx, PM2, UFW ni el servidor RustDesk. No se publican credenciales.
La publicacion de `latest.json` aqui no activa actualizaciones automaticas del cliente.

Los binarios de esta entrega corresponden a
`6282d56463df5264440afd844f75579430c2afbe`, con los mismos hashes de GitHub.
Los cambios de hosting posteriores solo afectan archivos de distribucion y documentos.

## Retirada o vuelta a otra version

Para volver a una version anterior, restaurar sus destinos en `.htaccess` y su
manifiesto, despues de verificar que los archivos siguen disponibles. Para retirar
solo esta publicacion, renombrar su carpeta `soporte-remoto` dentro de BUSKIT;
conservar el contenido para recuperacion. No modificar carpetas de otras empresas.
