param([Parameter(Mandatory)][string]$MsiPath)
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
Invoke-Msi '/fa' $msi 'repair' 'DESKTOPSHORTCUTS=1'
Assert-Installed
Invoke-Msi '/x' $msi 'remove-fresh'
if (Test-Path -LiteralPath $exe) { throw 'La desinstalacion dejo el ejecutable.' }
if (Get-Service $appId -ErrorAction SilentlyContinue) { throw 'La desinstalacion dejo el servicio.' }
if (-not (Test-Path -LiteralPath $neighbour)) { throw 'Se modifico la carpeta de otro sistema.' }
Write-Output 'Instalacion nueva, reparacion y desinstalacion en C:\BusKIT\Soporte: OK'
