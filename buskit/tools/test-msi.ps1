param([Parameter(Mandatory)][string]$MsiPath)
$ErrorActionPreference = 'Stop'
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_OS -ne 'Windows') {
    throw 'Esta prueba instala y desinstala el producto: solo se ejecuta en el runner Windows desechable.'
}
$msi = (Resolve-Path -LiteralPath $MsiPath).Path
$brand = Get-Content (Join-Path $PSScriptRoot '../brand.json') -Raw | ConvertFrom-Json
$appId = $brand.appId
$fixedFolder = Join-Path $env:ProgramFiles $brand.installSubdirectory
$oldFolder = Join-Path $env:ProgramFiles $appId
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
    (Get-Service $appId).WaitForStatus('Running', [TimeSpan]::FromSeconds(20))
    $service = Get-CimInstance Win32_Service -Filter "Name='$appId'"
    if ($service.State -ne 'Running' -or $service.StartMode -ne 'Auto' -or $service.PathName -ne "`"$exe`" --service") {
        throw 'Servicio no activo, no automatico o con ruta incorrecta.'
    }
    $state = Get-ItemProperty -LiteralPath "HKLM:\Software\$appId\InstallState\$appId"
    if ($state.InstallLocation.TrimEnd('\') -ne $fixedFolder) { throw 'Registro de instalacion incorrecto.' }
    $arp = Get-ItemProperty -LiteralPath "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($state.MsiProductCode)"
    if ($arp.DisplayName -ne $brand.name -or $arp.DisplayVersion -ne "$($brand.msiVersion).0") { throw 'Identidad/version MSI incorrecta.' }
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

# A neighbouring application must survive installs, upgrades and removal.
$neighbour = Join-Path $env:ProgramFiles 'BusKIT\OtroSistema\conservar.txt'
New-Item -ItemType Directory -Path (Split-Path $neighbour) -Force | Out-Null
Set-Content -LiteralPath $neighbour -Value 'No pertenece a Soporte'
Invoke-Msi '/i' $msi 'fresh' 'INSTALLFOLDER="C:\Ignored" INSTALLFOLDER_INNER="C:\Ignored\Other" DESKTOPSHORTCUTS=1'
Assert-Installed
Invoke-Msi '/x' $msi 'remove-fresh'
if (Test-Path -LiteralPath $exe) { throw 'La desinstalacion dejo el ejecutable.' }
if (-not (Test-Path -LiteralPath $neighbour)) { throw 'Se modifico la carpeta de otro sistema.' }

$previous = Join-Path $logs.FullName 'previous.msi'
Invoke-WebRequest 'https://sdm.cl/empresas/BUSKIT/soporte-remoto/releases/1.5.0-buskit.1/BUSKIT-Soporte-Remoto.msi' -OutFile $previous
if ((Get-FileHash $previous -Algorithm SHA256).Hash.ToLower() -ne 'd88226743d54ab08eb0db416f639a48e2f17cecda2aefdec2f451d622306628a') { throw 'MSI anterior distinto al publicado.' }
Invoke-Msi '/i' $previous 'previous-install' 'DESKTOPSHORTCUTS=1'
if (-not (Test-Path (Join-Path $oldFolder "$appId.exe"))) { throw 'No se reprodujo la ruta anterior.' }
$oldState = Get-ItemProperty -LiteralPath "HKLM:\Software\$appId\InstallState\$appId"
$configFolder = Join-Path $env:APPDATA "$appId\config"
New-Item -ItemType Directory -Path $configFolder -Force | Out-Null
$sentinel = Join-Path $configFolder 'buskit-migration-check.txt'
Set-Content -LiteralPath $sentinel -Value ([Guid]::NewGuid().ToString())
$configHash = (Get-FileHash $sentinel).Hash
Invoke-Msi '/i' $msi 'upgrade' 'DESKTOPSHORTCUTS=1'
Assert-Installed
if (Test-Path (Join-Path $oldFolder "$appId.exe")) { throw 'Quedo el ejecutable de la instalacion anterior.' }
if (Test-Path -LiteralPath "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($oldState.MsiProductCode)") { throw 'Quedo registrado el MSI anterior.' }
if ((Get-FileHash $sentinel).Hash -ne $configHash) { throw 'La migracion altero los datos locales.' }
Invoke-Msi '/fa' $msi 'repair' 'DESKTOPSHORTCUTS=1'
Assert-Installed
Invoke-Msi '/x' $msi 'remove-upgraded'
if (-not (Test-Path -LiteralPath $neighbour)) { throw 'Se modifico la carpeta de otro sistema.' }
if ((Get-FileHash $sentinel).Hash -ne $configHash) { throw 'La desinstalacion altero los datos locales.' }
Write-Output 'Instalacion nueva, migracion desde 1.5.0.1, reparacion y desinstalacion: OK'
