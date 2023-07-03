$Host.UI.RawUI.ForegroundColor = "Cyan"
chcp 65001
$script_path = $MyInvocation.MyCommand.Path

$admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not$admin)
{
    Write-Host "The script need to be run as administrator. Right-click on the script file and select 'Run as administrator'." -ForegroundColor Red
    Exit
}

$startupTime = (Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime
if ($startupTime.TotalMinutes -lt 3)
{
    $delay = New-TimeSpan -Seconds ((3*60) - $startupTime.TotalSeconds)
    Write-Host "For some reason, the script is running too early. Waiting " + $delay.ToString("mm\:ss") + " before continuing..." -ForegroundColor Red
    Start-Sleep -Seconds $delay.TotalSeconds
}

function installIDE()
{
    # URL de telechargement de l'installateur de PhpStorm
    $installerUrl = "https://download.jetbrains.com/webide/PhpStorm-2023.1.exe"
    $configUrl = "./silent.config"
    $configPath = "$env:TEMP\silent.config"
    $arguments = "/S /CONFIG=$configPath"

    # Rechercher le dossier d'installation de PhpStorm
    $installPath = Get-ChildItem -Path "C:\" -Filter "PhpStorm*" -Directory -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 | Select-Object -ExpandProperty FullName

    # Verifier si PhpStorm est installe
    if ($installPath)
    {
        Write-Host "PhpStorm is already installed on this system."
    }
    else
    {
        Write-Host "PhpStorm is not installed on this system."
        Write-Host "Did you want to install PhpStorm ? (o/n)" -ForegroundColor DarkYellow -NoNewline
        $confirm = Read-Host -Prompt " "
        if ($confirm -eq "o" -or $confirm -eq "O" -or $confirm -eq "Y" -or $confirm -eq "y")
        {
            Write-Host "PhpStorm is not installed on this system. Downloading the latest version..."
            # Telecharger l'installateur de PhpStorm
            Invoke-WebRequest -Uri $installerUrl -OutFile "$env:USERPROFILE\Downloads\PhpStorm-2022.3.3.exe" -UseBasicParsing
            Invoke-WebRequest -Uri $configUrl -OutFile $configPath -UseBasicParsing -TimeoutSec 120

            # Installer PhpStorm
            Start-Process "$env:USERPROFILE\Downloads\PhpStorm-2022.3.3.exe" -ArgumentList $arguments -Wait
            Write-Host "PhpStorm has been installed successfully."

            # Supprimer le fichier d'installation de PhpStorm
            Remove-Item "$env:USERPROFILE\Downloads\PhpStorm-2022.3.3.exe"
        }
        else
        {
            Write-Host "No action has been performed." -ForegroundColor DarkYellow
        }
    }


    # URL de telechargement de l'installateur de VS Code
    $installerUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"

    # Rechercher le dossier d'installation de VS Code par defaut
    $installPath = "${env:LOCALAPPDATA}\Programs\Microsoft VS Code"

    # Chemin complet de l'executable de VS Code
    $vsCodePath = Join-Path -Path $installPath -ChildPath "Code.exe"

    # Verifier si VS Code est installe
    if (Test-Path $vsCodePath)
    {
        Write-Host "Visual Studio Code is already installed on this system."
    }

    # Telecharger et installer VS Code si necessaire
    if (!(Test-Path $vsCodePath))
    {
        Write-Host "Do you want to install Visual Studio Code ? (o/n)" -ForegroundColor DarkYellow -NoNewline
        $confirm = Read-Host -Prompt " "
        if ($confirm -eq "o" -or $confirm -eq "O" -or $confirm -eq "Y" -or $confirm -eq "y")
        {
            Write-Host "Visual Studio Code is not installed on this system. Downloading the latest version..."
            # Telecharger l'installateur de VS Code
            Invoke-WebRequest -Uri $installerUrl -OutFile "$env:USERPROFILE\Downloads\vscode-setup.exe"

            $arguments = "/silent /mergetasks=`"addcontextmenufiles,addcontextmenufolders,!runcode`""

            # Installer VS Code
            Start-Process "$env:USERPROFILE\Downloads\vscode-setup.exe" -ArgumentList $arguments -Wait
            Write-Host "Visual Studio Code has been installed successfully."

            # Supprimer le fichier d'installation de VS Code
            Remove-Item "$env:USERPROFILE\Downloads\vscode-setup.exe"
        }
        else
        {
            Write-Host "No action has been performed." -ForegroundColor DarkYellow
        }
    }
}

function section($title, $withPipe = $true, $color = "Yellow", $char = "-")
{
    if ($withPipe)
    {
        $title = "| " + $title + " |"
    }
    $padLength = if ($title.Length -gt 100)
    {
        80
    }
    else
    {
        $title.Length
    }
    $Host.UI.RawUI.ForegroundColor = $color
    Write-Host ""
    Write-Host "".PadRight($padLength, $char)
    Write-Host $title
    Write-Host "".PadRight($padLength, $char)
    Write-Host ""
    $Host.UI.RawUI.ForegroundColor = "Cyan"
}

function result($result, $color = "Green")
{
    $Host.UI.RawUI.ForegroundColor = $color
    Write-Host $result
    $Host.UI.RawUI.ForegroundColor = "Cyan"
}

function separator()
{
    Write-Host "".PadRight(80, "-")
}

function restartWSL()
{
    Write-Host "Restarting the Ubuntu-22.04 distribution..." -ForegroundColor DarkYellow
    wsl --terminate Ubuntu-22.04
    Start-Sleep -Seconds 5
    Write-Host "Restarting the Ubuntu-22.04 distribution was successful." -ForegroundColor Green
}

Write-Host "Welcome $env:USERNAME !" -ForegroundColor Green
Write-Host ""
Write-Host "This script will install WSL 2, Docker Desktop and Docker Compose on your Windows machine." -ForegroundColor Yellow
Write-Host ""
Write-Host "Please read carefully the instructions before continuing." -ForegroundColor Red
Write-Host ""
Write-Host "This script has been tested on Windows 11 Pro" -ForegroundColor Yellow

section "The script will install the following components"
Write-Host " - PhpStorm and/or Visual Studio Code (optional)"
Write-Host " - Windows Subsystem for Linux"
Write-Host " - Virtual Machine Platform"
Write-Host " - Linux Kernel Update Package"
Write-Host " - Docker Desktop (with Docker Compose)"
Write-Host " - WSL version 2"
Write-Host " - Ubuntu 22.04 LTS"

section "The following components will be installed on your WSL Ubuntu 22.04 LTS machine"
Write-Host " - Taskfile"
Write-Host " - Base for projects (traefik, mailpit, keycloak, strapi, etc.)"
Write-Host " - The projects that you will choose"
Write-Host ""
Write-Host ""
Write-Host "If you already have a WSL Ubuntu 22.04 LTS, the script will ask you if you want to delete and reinstall it."
Write-Host ""
Write-Host ""
Write-Host "Please press any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

section "IDE Installation"
Write-Host "Do you want to install PhpStorm and/or Visual Studio Code ? (y/n)" -ForegroundColor DarkYellow -NoNewline

$confirm = Read-Host -Prompt " "
if ($confirm -eq "o" -or $confirm -eq "O" -or $confirm -eq "Y" -or $confirm -eq "y")
{
    installIDE
}
else
{
    Write-Host "No action has been performed." -ForegroundColor DarkYellow
}

section "Verification of Windows compatibility with WSL 2"
# Verifier si le Windows Installer est compatible avec WSL 2
$os_version = [Environment]::OSVersion.Version
$is_x64 = [Environment]::Is64BitOperatingSystem

if (($os_version -ge (New-Object System.Version("10.0.18362.0")) -and $os_version -lt (New-Object System.Version("11.0"))) -or ($os_version -ge (New-Object System.Version("10.0.19041.0")) -and $is_x64))
{
    Write-Host "Windows is compatible with WSL 2." -ForegroundColor Green
}
else
{
    Write-Host "Windows is not compatible with WSL 2. Please update your Windows version." -ForegroundColor Red
    exit
}

section "Verification of the installation of Windows Subsystem for Linux"

$need_restart = $false

# Verifier si WSL est installe
$wsl_installed = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

if ($wsl_installed.State -eq "Enabled")
{
    Write-Host "WSL is already installed." -ForegroundColor Green
}
else
{
    Write-Host "WSL is not installed, installing WSL..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    Write-Host "WSL was installed." -ForegroundColor Green
    $need_restart = $true
}

section "Verification of the installation of Virtual Machine Platform"

# Verifier si Virtual Machine Platform est installe
$virtual_machine_platform_installed = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

if ($virtual_machine_platform_installed.State -eq "Enabled")
{
    Write-Host "Virtual Machine Platform is already installed." -ForegroundColor Green
}
else
{
    Write-Host "Virtual Machine Platform is not installed, installing Virtual Machine Platform..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    Write-Host "Virtual Machine Platform was installed." -ForegroundColor Green
    $need_restart = $true
}

section "Verification of the installation of Linux Kernel Update Package"

# Verifier si Linux Kernel Update Package est installe
$linux_kernel_update_package_installed = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

if ($linux_kernel_update_package_installed.State -eq "Enabled")
{
    Write-Host "Linux Kernel Update Package is already installed." -ForegroundColor Green
}
else
{
    Write-Host "Linux Kernel Update Package is not installed, installing Linux Kernel Update Package..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    Write-Host "Linux Kernel Update Package was installed." -ForegroundColor Green
    $need_restart = $true
}

if ($need_restart)
{
    Write-Host "Please restart your PC, to finish installation of WSL" -ForegroundColor DarkYellow
    Read-Host -Prompt "Please save your work and press any key to restart your PC..."
    Write-Host "Restarting your PC in 5 seconds..." -ForegroundColor DarkYellow
    Start-Sleep -Seconds 5
    Restart-Computer -Force
    Exit
}

section "Updating WSL"
wsl --update
Write-Host "WSL has been updated." -ForegroundColor Green

section "Updating WSL to version 2"
wsl --set-default-version 2
Write-Host "WSL has been updated to version 2." -ForegroundColor Green

section "Verification of the installation of Docker Desktop"

# Verifier si Docker Desktop est installe
$docker_desktop_installed = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName | Where-Object { $_.DisplayName -eq "Docker Desktop" }

if ($docker_desktop_installed)
{
    Write-Host "Docker Desktop is already installed." -ForegroundColor Green
}
else
{
    Write-Host "Docker Desktop is not installed, downloading Docker Desktop..." -ForegroundColor Yellow
    $docker_desktop_url = "https://desktop.docker.com/win/stable/amd64/Docker%20Desktop%20Installer.exe"
    $docker_desktop_file = "Docker Desktop Installer.exe"
    $docker_desktop_path = "$env:USERPROFILE\Downloads\$docker_desktop_file"
    $docker_desktop_installer = New-Object System.Net.WebClient
    $docker_desktop_installer.DownloadFile($docker_desktop_url, $docker_desktop_path)
    Write-Host "Docker Desktop is downloaded. Installing Docker Desktop..." -ForegroundColor Yellow
    Start-Process $docker_desktop_path -ArgumentList "install --quiet" -Wait
    Write-Host "Docker Desktop was installed. Please restart your PC, to finish installation of Docker Desktop" -ForegroundColor DarkYellow
    Exit
}

# Waiting for Docker Desktop to start and start it if it's not running
Write-Host "Verification of the running state of Docker Desktop..." -ForegroundColor Yellow
$docker_desktop_start_time = Get-Date
$docker_desktop_start_timeout = 60
$docker_started_by_script = $false
$docker_desktop_running = $false
$dockerExePath = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, InstallLocation | Where-Object { $_.DisplayName -eq "Docker Desktop" } | Select-Object -ExpandProperty InstallLocation
$dockerExePath = $dockerExePath + "\Docker Desktop.exe"

function runAndcheckDockerIsRunning()
{
    while ($true)
    {
        $docker_desktop_running = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
        if ($docker_desktop_running)
        {
            Write-Host "Docker Desktop is running." -ForegroundColor Green
            break
        }
        else
        {
            if ((Get-Date).Subtract($docker_desktop_start_time).TotalSeconds -gt $docker_desktop_start_timeout)
            {
                Write-Host "Docker Desktop did not start in time. 60 seconds have passed." -ForegroundColor Red
                exit
            }
            if (-not$docker_started_by_script)
            {
                Write-Host "Docker Desktop is not running, starting Docker Desktop..." -ForegroundColor Yellow
                Start-Process $dockerExePath
                $docker_started_by_script = $true
            }

            Write-Host "Docker Desktop is not running, waiting 5 seconds..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds 5
        }
    }

    section "Verification of the state of the Docker Desktop service"

    # Waiting for service
    $docker_desktop_start_time = Get-Date
    $docker_desktop_start_timeout = 60
    $docker_desktop_started = $false

    while (-not$docker_desktop_started)
    {
        $docker_desktop_started = Get-Service -Name "Docker Desktop Service" | Select-Object -ExpandProperty Status "Running"
        if (-not$docker_desktop_started)
        {
            if ((Get-Date).Subtract($docker_desktop_start_time).TotalSeconds -gt $docker_desktop_start_timeout)
            {
                Write-Host "Docker Desktop service did not start in time. 60 seconds have passed." -ForegroundColor Red
                exit
            }
            Write-Host "Docker Desktop service is not running, waiting 5 seconds..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds 5
        }
        else
        {
            Write-Host "Docker Desktop service is running." -ForegroundColor Green
        }
    }
}

runAndcheckDockerIsRunning

function activeDaemon()
{
    $dockerDesktopSettingFilePath = "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"
    if (-not(Test-Path $dockerDesktopSettingFilePath))
    {
        $dockerDesktopSettingFilePath = "$env:USERPROFILE\AppData\Local\Docker\settings.json"
        if (-not(Test-Path $dockerDesktopSettingFilePath))
        {
            Write-Host "Configuration file of Docker Desktop was not found, please enable the Daemon TCP in the Docker Desktop settings by clicking on 'Expose daemon on tcp://localhost:2375 without TLS'." -ForegroundColor Red
            Read-Host -Prompt "Press any key to continue..."
        }
    }

    # Verifier si la Cle "exposeDockerAPIOnTCP2375" est presente dans le fichier de configuration de Docker Desktop et si elle est a "true"
    $docker_desktop_api_exposed = Get-Content $dockerDesktopSettingFilePath | Select-String -Pattern "exposeDockerAPIOnTCP2375" | Select-Object -ExpandProperty Line | Select-String -Pattern "true" | Select-Object -ExpandProperty Line

    if ($docker_desktop_api_exposed)
    {
        Write-Host "The exposeDockerAPIOnTCP2375 key is present in the Docker Desktop configuration file and is set to true." -ForegroundColor Green
    }
    else
    {
        Write-Host "The exposeDockerAPIOnTCP2375 key is not present in the Docker Desktop configuration file or is set to false." -ForegroundColor Yellow
        Write-Host "Modification of the Docker Desktop configuration file..." -ForegroundColor Yellow
        $dockerDesktopSettingFileContent = Get-Content $dockerDesktopSettingFilePath
        $dockerDesktopSettingFileContent = $dockerDesktopSettingFileContent -replace '"exposeDockerAPIOnTCP2375": false', '"exposeDockerAPIOnTCP2375": true'
        $dockerDesktopSettingFileContent | Set-Content $dockerDesktopSettingFilePath
        Write-Host "Docker Desktop configuration file was modified." -ForegroundColor Green
        Write-Host "Restarting Docker Desktop..." -ForegroundColor Yellow
        Restart-Service -Name "Docker Desktop Service"
        # Fermer Docker Desktop
        Stop-Process -Name "Docker Desktop"
        # Attendre que Docker Desktop soit ferme
        $docker_desktop_running = $true
        $docker_service_running = $true
        while ($docker_desktop_running -and $docker_service_running)
        {
            $docker_desktop_running = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
            $docker_service_running = Get-Service -Name "Docker Desktop Service" | Select-Object -ExpandProperty Status "Running"
            if ($docker_desktop_running -or $docker_service_running)
            {
                Write-Host "Docker Desktop or the Docker Desktop service is still running, waiting 1 second..." -ForegroundColor DarkYellow
                Start-Sleep -Seconds 1
            }
            else
            {
                Write-Host "Docker Desktop and the Docker Desktop service are not running." -ForegroundColor Green
            }
        }
        runAndcheckDockerIsRunning
        Write-Host "Docker Desktop was restarted." -ForegroundColor Green
    }
}

section "Verification of the state of the Docker Desktop Daemon TCP"

# Verifier si le Daemon TCP est expose sur le port 2375 avec un appel a l'API de Docker Desktop
$docker_desktop_api_exposed = $false
$docker_desktop_api_exposed_timeout = 60
$docker_desktop_api_exposed_start_time = Get-Date
$docker_desktop_api_exposed_url = "http://localhost:2375/version"
$procedeedActivation = $false

while (-not$docker_desktop_api_exposed)
{
    try
    {
        $docker_desktop_api_exposed = Invoke-WebRequest -Uri $docker_desktop_api_exposed_url -UseBasicParsing -TimeoutSec 5
    }
    catch
    {
        if ((Get-Date).Subtract($docker_desktop_api_exposed_start_time).TotalSeconds -gt $docker_desktop_api_exposed_timeout)
        {
            Write-Host "Docker Desktop API was not exposed in time. 60 seconds have passed." -ForegroundColor Red
            exit
        }
        if (-not$procedeedActivation)
        {
            Write-Host "Attempt to activate the Docker Desktop Daemon TCP..." -ForegroundColor Yellow
            activeDaemon
            $docker_desktop_api_exposed_timeout = 60
            $procedeedActivation = $true
        }
        Write-Host "Docker Desktop API is not exposed, waiting 5 seconds..." -ForegroundColor DarkYellow
        Start-Sleep -Seconds 5
    }
}

Write-Host "Docker Desktop API is exposed." -ForegroundColor Green

section "Verification of WSL 2 Installation"

# Verifier si WSL 2 est installe et l'installer si necessaire
$wsl_installed = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux | Select-Object -ExpandProperty State

if ($wsl_installed -ne "Enabled")
{
    Write-Host "First installation of WSL 2 was not done, please restart your computer and run the script again." -ForegroundColor Red
    Exit
}
else
{
    Write-Host "WSL 2 is installed." -ForegroundColor Green
}

$distro = "Ubuntu-22.04"
section "Verification of the $distro distribution installation"

# Vérifier si la distribution Ubuntu est installée
$resultat = wsl.exe -d $distro -e sh -c "whoami" 2>&1

if ($LASTEXITCODE -eq 0)
{
    Write-Host "$distro is installed." -ForegroundColor Green

    Write-Host "No modification will be made in addition from this script." -ForegroundColor DarkYellow
    section "WARNING" $true "red" "!"
    Write-Host "The next action will delete the $distro distribution. If you have important files in the $distro distribution, please save them before continuing." -ForegroundColor Red
    section "WARNING" $true "red" "!"
    Write-Host "Do you want to delete the $distro distribution and restart the script to reinitialize the distribution? (o/n)" -ForegroundColor DarkYellow -NoNewline
    $confirm = Read-Host -Prompt " "
    if ($confirm -eq "o" -or $confirm -eq "O" -or $confirm -eq "Y" -or $confirm -eq "y")
    {
        Write-Host "Deleting the $distro distribution..." -ForegroundColor DarkYellow
        wsl.exe --unregister Ubuntu-22.04
        Write-Host "Deleting the $distro distribution was successful." -ForegroundColor Green
        Write-Host "PLEASE RESTART YOUR COMPUTER AND RUN THE SCRIPT AGAIN." -ForegroundColor DarkYellow
    }
    else
    {
        Write-Host "No action has been performed." -ForegroundColor DarkYellow
    }
    Exit
}
else
{
    Write-Host "$distro is not installed." -ForegroundColor DarkYellow
    Write-Host "Downloading $distro..." -ForegroundColor DarkYellow
    wsl.exe --install -d Ubuntu-22.04 --no-launch
    Write-Host "Downloading $distro was successful." -ForegroundColor Green
    Write-Host "Installation of $distro..." -ForegroundColor DarkYellow
    Write-Host ""
    section "WARNING" $true "red" "!"
    Write-Host "The identifiers you are going to enter are absolutely necessary for the daily use of the Ubuntu distribution, please enter them carefully and do not forget them." -ForegroundColor DarkRed
    section "WARNING" $true "red" "!"
    Write-Host ""
    ubuntu2204.exe install
    Write-Host "Installation of $distro was successful." -ForegroundColor Green
}

section "Update of $distro packages"
wsl -d Ubuntu-22.04 -u root -e sh -c "apt update && sudo apt upgrade -y"

Write-Host "Update of $distro packages was successful." -ForegroundColor Green

# Installer Taskfile
section "Installation of Taskfile"
$taskfile_installed = wsl -d Ubuntu-22.04 -e sh -c "task --version"

if ($taskfile_installed | Select-String "Task version")
{
    Write-Host "Taskfile is already installed." -ForegroundColor Green
}
else
{
    # Install taskfile in /usr/local/bin
    wsl -d Ubuntu-22.04 -u root -e sh -c "cd ~ && curl -sL https://taskfile.dev/install.sh | sh"
    wsl -d Ubuntu-22.04 -u root -e sh -c "cd ~ && sudo mv ./bin/task /usr/local/bin/task && sudo chmod +x /usr/local/bin/task && sudo chown root:root /usr/local/bin/task && sudo chmod 755 /usr/local/bin/task && rm -rf ./bin"
    Write-Host "Taskfile installation was successful." -ForegroundColor Green
    restartWSL
    $taskfile_installed = wsl -d Ubuntu-22.04 -e sh -c "task --version"
    if ($taskfile_installed | Select-String "Task version")
    {
        Write-Host "Taskfile is installed." -ForegroundColor Green
    }
    else
    {
        Write-Host "Taskfile installation failed. Please restart the script or install Taskfile manually by following the instructions on https://taskfile.dev/installation/#get-the-binary" -ForegroundColor Red
        exit
    }
}

# Créer une clé SSH pour l'utilisateur si elle n'existe pas
section "Verification of the SSH key"
$ssh_key_content = wsl -d Ubuntu-22.04 -e sh -c "cat ~/.ssh/id_rsa.pub" 2>&1

if ($LASTEXITCODE -eq 0)
{
    Write-Host "SSH key already exists." -ForegroundColor Green
}
else
{
    Write-Host "SSH key does not exist." -ForegroundColor DarkYellow
    Write-Host "Creating SSH key..." -ForegroundColor DarkYellow
    wsl -d Ubuntu-22.04 -e sh -c "ssh-keygen -N '' -f ~/.ssh/id_rsa -q && chmod 600 ~/.ssh/id_rsa && chmod 644 ~/.ssh/id_rsa.pub"
}

$ssh_key_content = wsl -d Ubuntu-22.04 -e sh -c "cat ~/.ssh/id_rsa.pub" 2>&1

Write-Host ""
Write-Host ""

Write-Host "It remains for you to launch your IDE and open the folder of your project."

Write-Host ""

Write-Host "Keep in mind that you have to configure the environment variables in the .env.local files of the projects." -ForegroundColor DarkYellow

Write-Host ""

Write-Host "When you have configured the environment variables, you can start the containers with the 'task start' command in the project folder." -ForegroundColor DarkYellow

Write-Host ""

Write-Host "Did you want to install FISH ? (o/n)" -ForegroundColor DarkYellow -NoNewline
$response = Read-Host -Prompt " "

if ($response -eq "Y" -or $response -eq "y" -or $response -eq "O" -or $response -eq "o")
{
    section "Installing FISH"
    Write-Host "Installing FISH..." -ForegroundColor DarkYellow
    wsl -d Ubuntu-22.04 -u root -e sh -c "sudo apt-get install fish powerline jq -y"
    Write-Host "FISH installation was successful." -ForegroundColor Green

    Write-Host "Installing Oh My Fish..." -ForegroundColor DarkYellow
    wsl -d Ubuntu-22.04 -e sh -c "curl -L https://github.com/oh-my-fish/oh-my-fish/raw/master/bin/install > install && chmod +x install && ./install --noninteractive && rm ./install" 2>&1
    Write-Host "Oh My Fish installation was successful." -ForegroundColor Green

    Write-Host "Set FISH as default shell..." -ForegroundColor DarkYellow
    Write-Host "Please enter your Ubuntu password." -ForegroundColor DarkYellow
    wsl -d Ubuntu-22.04 -e sh -c "chsh -s /usr/bin/fish"
    Write-Host "FISH is now the default shell." -ForegroundColor Green

    restartWSL

    Write-Host "Set 'agnoster' theme..." -ForegroundColor DarkYellow
    wsl -d Ubuntu-22.04 -e fish -c "omf install agnoster"
    Write-Host "Theme 'agnoster' is now set." -ForegroundColor Green

    section "Install powerline fonts on Windows"

    $font = (New-Object System.Drawing.Text.InstalledFontCollection).Families | Where-Object { $_.Name -eq "DejaVu Sans Mono for Powerline" }
    if ($font)
    {
        Write-Host "DejaVu Sans Mono font is already installed on this system." -ForegroundColor Green
    }
    else
    {
        Write-Host "Extracting powerline fonts..." -ForegroundColor DarkYellow
        Expand-Archive -Path ".\fonts.zip" -DestinationPath ".\fonts" -Force
        Write-Host "Powerline fonts extraction was successful." -ForegroundColor Green

        Write-Host "Installing DejaVu Sans Mono fonts..." -ForegroundColor DarkYellow
        Start-Process -FilePath "powershell.exe" -ArgumentList ".\fonts\install.ps1" -Wait
        Remove-Item ".\fonts.zip"
        Remove-Item ".\fonts" -Recurse
        Write-Host "Powerline fonts installation was successful." -ForegroundColor Green
    }

    section "Windows Terminal"
    $terminal_is_installed = Get-AppxPackage -Name "Microsoft.WindowsTerminal"

    if ($terminal_is_installed)
    {
        Write-Host "Windows Terminal is already installed on this system." -ForegroundColor Green
    }
    else
    {
        Write-Host "Windows Terminal is not installed on this system." -ForegroundColor DarkYellow
        Write-Host "I recommand you to install it, please go to the following link: https://aka.ms/terminal" -ForegroundColor DarkYellow
        Read-Host -Prompt "Press enter to continue..."
    }

    Write-Host "Setting the font in the Windows Terminal..." -ForegroundColor DarkYellow
    $json = Get-Content -Path "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" | ConvertFrom-Json
    try
    {
        $json.fontFace = "DejaVu Sans Mono for Powerline"
        $json.fontWeight = "normal"
        $json.font.size = 13
        $json | ConvertTo-Json | Set-Content -Path "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    }
    catch
    {
        Write-Host "An error occurred while setting the font in the Windows Terminal." -ForegroundColor Red
        Write-Host "Please set the font manually in the Windows Terminal settings." -ForegroundColor Red
        Write-Host "The font to set is 'DejaVu Sans Mono for Powerline'." -ForegroundColor Red
    }
}
else
{
    Write-Host "FISH installation was skipped." -ForegroundColor Green
}

$user = wsl -d Ubuntu-22.04 -e sh -c "whoami"
section "Chown all files to $user"
Write-Host "Changing the owner of all files to $user..." -ForegroundColor DarkYellow
$cmd = 'chown -R ' + $user + ': .'
wsl -d Ubuntu-22.04 -u root -e sh -c $cmd
Write-Host "Changing the owner of all files was successful." -ForegroundColor Green

Write-Host "Fix docker rights" -ForegroundColor DarkYellow
wsl -d Ubuntu-22.04 -e sh -c "sudo addgroup --system docker"
wsl -d Ubuntu-22.04 -e sh -c "sudo adduser $USER docker"
wsl -d Ubuntu-22.04 -e sh -c "sudo chown root:docker"
wsl -d Ubuntu-22.04 -e sh -c "sudo /var/run/docker.sock chmod g+w /var/run/docker.sock"
Write-Host "Fix docker rights was successful..."

Write-Host ""
Write-Host ""

section "WARNING" $true "red" "!"
Write-Host "If docker is not accessible from WSL, please go to Docker Desktop settings and check in 'Resources' that 'WSL Integration' is enabled for default distro and Ubuntu-22.04." -ForegroundColor DarkYellow
section "WARNING" $true "red" "!"

Write-Host ""
Write-Host ""

Write-Host "That's it $env:USERNAME, you're ready to code!" -ForegroundColor Green

Write-Host "Have a nice day!" -ForegroundColor Green
