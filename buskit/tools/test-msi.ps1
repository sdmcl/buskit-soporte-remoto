param([Parameter(Mandatory)][string]$MsiPath, [string]$PreviousMsiPath)
$ErrorActionPreference = 'Stop'
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_OS -ne 'Windows') {
    throw 'Esta prueba instala y desinstala el producto: solo se ejecuta en el runner Windows desechable.'
}
$msi = (Resolve-Path -LiteralPath $MsiPath).Path
$brand = Get-Content (Join-Path $PSScriptRoot '../brand.json') -Raw | ConvertFrom-Json
$appId = $brand.appId
$fixedFolder = $brand.installDirectory
$exe = Join-Path $fixedFolder "$appId.exe"
$logs = New-Item -ItemType Directory -Path 'dist/msi-validation' -Force
if (Get-Service $appId -ErrorAction SilentlyContinue) { throw 'El runner ya contiene el servicio.' }

function Invoke-Msi([string]$Operation, [string]$Package, [string]$Name, [string]$Extra = '') {
    $log = Join-Path $logs.FullName "$Name.log"
    $process = Start-Process msiexec.exe -ArgumentList "$Operation `"$Package`" /qn /norestart /L*v `"$log`" LAUNCH_TRAY_APP=N $Extra" -Wait -PassThru -WindowStyle Hidden
    if ($process.ExitCode -notin 0,3010) { throw "MSI $Name fallo con codigo $($process.ExitCode); revisar $log" }
}
function Assert-Installed {
    if (-not (Test-Path -LiteralPath $exe)) { throw "Ejecutable ausente en $fixedFolder" }
    $acl = Get-Acl -LiteralPath $fixedFolder
    if (-not $acl.AreAccessRulesProtected) { throw 'La carpeta del servicio hereda permisos de escritura.' }
    $users = $acl.Access | Where-Object { $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value -eq 'S-1-5-32-545' }
    if (-not $users -or ($users | Where-Object { $_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write })) { throw 'Permisos incorrectos en la carpeta del servicio.' }
    (Get-Service $appId).WaitForStatus('Running', [TimeSpan]::FromSeconds(20))
    $service = Get-CimInstance Win32_Service -Filter "Name='$appId'"
    if ($service.State -ne 'Running' -or $service.StartMode -ne 'Auto' -or $service.PathName -ne "`"$exe`" --service") {
        throw 'Servicio no activo, no automatico o con ruta incorrecta.'
    }
    $state = Get-ItemProperty -LiteralPath "HKLM:\Software\$appId\InstallState\$appId"
    if ($state.InstallLocation.TrimEnd('\') -ne $fixedFolder) { throw 'Registro de instalacion incorrecto.' }
    $arp = Get-ItemProperty -LiteralPath "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($state.MsiProductCode)"
    if ($arp.DisplayName -ne $brand.name -or $arp.DisplayVersion -ne "$($brand.msiVersion).0") { throw 'Identidad/version MSI incorrecta.' }
    if ($arp.InstallLocation.TrimEnd('\') -ne $fixedFolder) { throw 'Ruta incorrecta en Aplicaciones instaladas de Windows.' }
    $shortcut = Join-Path ([Environment]::GetFolderPath('CommonDesktopDirectory')) "$($brand.name).lnk"
    if (-not (Test-Path -LiteralPath $shortcut)) { throw 'Falta acceso directo en espanol.' }
    $shell = New-Object -ComObject WScript.Shell
    if ($shell.CreateShortcut($shortcut).TargetPath -ne $exe) { throw 'El acceso directo apunta a otra carpeta.' }
    Write-Output 'Ruta fija, servicio automatico, registro y acceso directo: OK'
}

# Check the actual language and visible welcome text inside the built MSI.
$installer = New-Object -ComObject WindowsInstaller.Installer
$database = $installer.OpenDatabase($msi,0)
$view = $database.OpenView('SELECT `Value` FROM `Property` WHERE `Property` = ''ProductLanguage''')
$view.Execute()
if ($view.Fetch().StringData(1) -ne '3082') { throw 'El MSI no esta en espanol.' }
$view.Close()
$view = $database.OpenView('SELECT `Text` FROM `Control` WHERE `Dialog_` = ''WelcomeDlg'' AND `Control` = ''Description''')
$view.Execute()
if ($view.Fetch().StringData(1) -notmatch 'asistencia remota de BUSKIT') { throw 'Falta la presentacion de BUSKIT.' }
$view.Close()
$database = $null
[GC]::Collect()
[GC]::WaitForPendingFinalizers()

# A neighbouring application must survive installation, repair and removal.
$neighbour = 'C:\BusKIT\OtroSistema\conservar.txt'
New-Item -ItemType Directory -Path (Split-Path $neighbour) -Force | Out-Null
Set-Content -LiteralPath $neighbour -Value 'No pertenece a Soporte'
Invoke-Msi '/i' $msi 'fresh' 'INSTALLFOLDER="C:\Ignored" INSTALLFOLDER_INNER="C:\Ignored\Other" DESKTOPSHORTCUTS=1'
Assert-Installed
$remoteConfig = 'allow-remote-config-modification'
if ((& $exe --option access-mode | Out-String).Trim() -ne 'full') { throw 'Acceso completo no esta seleccionado por defecto.' }
if ((& $exe --option $remoteConfig | Out-String).Trim() -ne 'Y') { throw 'La configuracion remota no esta habilitada por defecto.' }
if ((& $exe --option allow-numeric-one-time-password | Out-String).Trim() -ne 'Y') { throw 'La contrasena temporal no es numerica por defecto.' }
if ((& $exe --option temporary-password-length | Out-String).Trim() -ne '6') { throw 'La contrasena temporal no tiene seis digitos por defecto.' }
& $exe --option access-mode custom | Out-Null
& $exe --option $remoteConfig N | Out-Null
& $exe --option allow-numeric-one-time-password N | Out-Null
& $exe --option temporary-password-length 8 | Out-Null
Invoke-Msi '/fa' $msi 'repair' 'DESKTOPSHORTCUTS=1'
Assert-Installed
if ((& $exe --option access-mode | Out-String).Trim() -ne 'custom') { throw 'No se conservo el modo de permisos personalizado elegido.' }
if ((& $exe --option $remoteConfig | Out-String).Trim() -ne 'N') { throw 'La eleccion de deshabilitar la configuracion remota no se conservo.' }
if ((& $exe --option allow-numeric-one-time-password | Out-String).Trim() -ne 'N') { throw 'No se conservo la contrasena temporal alfanumerica elegida.' }
if ((& $exe --option temporary-password-length | Out-String).Trim() -ne '8') { throw 'No se conservo la longitud elegida para la contrasena temporal.' }
Write-Output 'Valores predeterminados de soporte y preferencias conservadas tras reparar: OK'
Invoke-Msi '/x' $msi 'remove-fresh'
if (Test-Path -LiteralPath $exe) { throw 'La desinstalacion dejo el ejecutable.' }
if (Get-Service $appId -ErrorAction SilentlyContinue) { throw 'La desinstalacion dejo el servicio.' }
if (-not (Test-Path -LiteralPath $neighbour)) { throw 'Se modifico la carpeta de otro sistema.' }
Write-Output 'Instalacion nueva, reparacion y desinstalacion en C:\BusKIT\Soporte: OK'

if ($PreviousMsiPath) {
    $previousMsi = (Resolve-Path -LiteralPath $PreviousMsiPath).Path
    Invoke-Msi '/i' $previousMsi 'previous' 'DESKTOPSHORTCUTS=1'
    (Get-Service $appId).WaitForStatus('Running', [TimeSpan]::FromSeconds(20))
    & $exe --option access-mode view | Out-Null
    & $exe --option $remoteConfig N | Out-Null
    & $exe --option allow-numeric-one-time-password N | Out-Null
    & $exe --option temporary-password-length 8 | Out-Null
    # Exercise the same verified MSI handoff used by the application's Update button.
    $hash = (Get-FileHash -LiteralPath $msi -Algorithm SHA256).Hash.ToLower()
    $bytes = (Get-Item -LiteralPath $msi).Length
    dart --packages=flutter/.dart_tool/package_config.json buskit/tools/test-client-installer.dart $msi $hash $bytes
    $clientExit = $LASTEXITCODE
    if (Test-Path -LiteralPath "$msi.log") {
        Copy-Item -LiteralPath "$msi.log" -Destination (Join-Path $logs.FullName 'upgrade.log')
        Remove-Item -LiteralPath "$msi.log"
    }
    if ($clientExit -ne 0) { throw "La actualizacion iniciada desde el cliente fallo: $clientExit" }
    Assert-Installed
    foreach ($setting in @{
        'access-mode' = 'view'
        'allow-remote-config-modification' = 'N'
        'allow-numeric-one-time-password' = 'N'
        'temporary-password-length' = '8'
    }.GetEnumerator()) {
        if ((& $exe --option $setting.Key | Out-String).Trim() -ne $setting.Value) {
            throw "La actualizacion no conservo la preferencia $($setting.Key)."
        }
    }
    Invoke-Msi '/x' $msi 'remove-upgrade'
    if (Test-Path -LiteralPath $exe) { throw 'La desinstalacion de la actualizacion dejo el ejecutable.' }
    if (Get-Service $appId -ErrorAction SilentlyContinue) { throw 'La desinstalacion de la actualizacion dejo el servicio.' }
    if (-not (Test-Path -LiteralPath $neighbour)) { throw 'La actualizacion modifico otro sistema BusKIT.' }
    Write-Output 'Actualizacion desde el MSI anterior, preferencias conservadas y desinstalacion: OK'
}
