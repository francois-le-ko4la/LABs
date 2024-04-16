<#
.SYNOPSIS
    Script to automate the installation of SQL Server Express 2019, SQL Server Management Studio (SSMS),
    and restore the AdventureWorks2019 database.

.DESCRIPTION
    This script automates the installation of SQL Server Express 2019 and SQL Server Management Studio (SSMS),
    and restores the AdventureWorks2019 database for testing or development purposes only.

    Prerequisites:
    - Administrator privileges on the machine.
    - Internet connection to download SQL Server Express 2019 and SSMS.
    - PowerShell 5.1 or later.

    DISCLAIMER:
    This script is provided for educational and demonstration purposes only and
    should be used with caution.
    It is your responsibility to review, understand, and modify this script as 
    needed to meet your specific requirements and environment.
    The user remains responsible for reviewing and complying with the licensing
    terms of the products installed by this script.
    This script is not supported under any support program or service. 
    All scripts are provided AS IS without warranty of any kind. 
    The author further disclaims all implied warranties including, without
    limitation, any implied warranties of merchantability or of fitness for a
    particular purpose. 
    The entire risk arising out of the use or performance of the sample scripts
    and documentation remains with you.
    In no event shall its authors, or anyone else involved in the creation,
    production, or delivery of the scripts be liable for any damages whatsoever 
    (including, without limitation, damages for loss of business profits, business
    interruption, loss of business information, or other pecuniary loss) 
    arising out of the use of or inability to use the sample scripts or documentation,
    even if the author has been advised of the possibility of such damages.

    INSTALLATION:
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/francois-le-ko4la/LABs/main/BuildMSSQL.ps1 -UseBasicParsing -OutFile BuildMSSQL.ps1
    .\BuildMSSQL.ps1 -UserMssql "RUBRIK\demo"
    
.PARAMETER None
    This script does not accept any parameters.

.NOTES
    File Name: BuildMSSQL.ps1

.EXAMPLE
    - Edit the file and change variables to fit your needs.
    - Runs the script to install SQL Server Express 2019, SSMS, and restore AdventureWorks2019 database:
        PS C:\> .\BuildMSSQL.ps1

#>

param (
    [string]$UserMssql = "RUBRIK\demo"
)

# Check if PowerShell version is compatible
if ($PSVersionTable.PSVersion.Major -lt 5 -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)) {
    Write-Host "This script requires PowerShell 5.1 or later. Please upgrade your PowerShell version."
    exit 1
}

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as an administrator."
    exit 1
}

# Define variables
$ServerInstance = "localhost\SQLEXPRESS"
$DatabaseName = "AdventureWorks2019"
$MssqlRoot = "C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL"
$AdventureWorkUrl = "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2019.bak"
$MssqlUrl = "https://go.microsoft.com/fwlink/?linkid=866658"
$MssqlBin = "SQL2019-SSEI-Expr.exe"
$SsmsUrl = "https://go.microsoft.com/fwlink/?linkid=2257624&clcid=0x409"
$SsmsBin = "SSMS-Setup-ENU.exe"
$FwLabel = "Rubrik - Allow port"

# Define message severity variables
$info = "info"
$error = "error"
$Context = "BuildMSSQL"


# Function to log messages
function Log-Message {
    param (
        [string]$Severity,
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"    
    if ($Severity -eq $info) {
        Write-Host "$Timestamp - $Context - info - $Message"
    } elseif ($Severity -eq $error) {
        Write-Host "$Timestamp - $Context - error - $Message" -ForegroundColor Red
    }
}


# Function to check if a reboot is required
function Check-RebootRequired {
    $RebootRequired = $false
    $HKLM = 2147483650 # HKEY_LOCAL_MACHINE

    $AutoRestartKey = "SYSTEM\CurrentControlSet\Control\Session Manager"
    $AutoRestartValue = "PendingFileRenameOperations"

    try {
        $PendingFileRenameOperations = Get-ItemProperty -Path "HKLM:\$AutoRestartKey" -Name $AutoRestartValue -ErrorAction Stop
        if ($PendingFileRenameOperations -ne $null) {
            $RebootRequired = $true
        }
    } catch {
        # No PendingFileRenameOperations key found
        $RebootRequired = $false
    }

    return $RebootRequired
}


# Function to check if MSSQL is installed
function Check-MSSQLInstalled {
    $sqlServices = Get-Service | Where-Object { $_.DisplayName -like "SQL Server*" }
    if ($sqlServices) {
        return $true
    } else {
        return $false
    }
}


# Function to check if SSMS is installed
function Check-SSMSInstalled {
    $ssmsDisplayName = "Microsoft SQL Server Management Studio"

    # Get a list of installed applications
    $installedApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
                     Select-Object DisplayName, UninstallString |
                     Where-Object { $_.DisplayName -like "*$ssmsDisplayName*" }

    if ($installedApps) {
        return $true
    } else {
        return $false
    }
}


# Function to install SQL Server Express 2019
function Install-SqlServerExpress2019 {
    if (Check-MSSQLInstalled) {
        Log-Message $info "Microsoft SQL Server is already installed on this system. No changes made."
    }
    Log-Message $info "Downloading SQL Server Express 2019..."
    $Path = $env:TEMP
    $Installer = $MssqlBin
    $Url = $MssqlUrl
    try {
        # Test if the installer file already exists
        if (Test-Path -Path $Path\$Installer) {
            Write-Host "SQL Server Express 2019 installer already exists. Skipping download."
        } else {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest $Url -OutFile "$Path\$Installer" -ErrorAction Stop
        }
        Log-Message $info "Installing SQL Server Express..."
        $InstallArgs = "/ACTION=INSTALL", "/IACCEPTSQLSERVERLICENSETERMS", "/QUIET"
        Start-Process -FilePath "$Path\$Installer" -ArgumentList $InstallArgs -Verb RunAs -Wait
    } catch {
        Log-Message $error "Failed to download or install SQL Server Express 2019. Error: $_"
        return $false
    }
    return $true
}


# Function to install SQL Server Management Studio (SSMS)
function Install-Ssms {
    if (Check-SSMSInstalled) {
        Log-Message $info "SSMS is already installed on this system. No changes made."
        return $true
    }
    Log-Message $info "Downloading SSMS..."
    $Path = $env:TEMP
    $Installer = $SsmsBin
    $Url = $SsmsUrl
    try {
        # Test if the installer file already exists
        if (Test-Path -Path $Path\$Installer) {
            Write-Host "SSMS installer already exists. Skipping download."
        } else {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest $Url -OutFile "$Path\$Installer" -ErrorAction Stop
        }
        Log-Message $info "Installing SSMS..."
        Start-Process -FilePath "$Path\$Installer" -Args "/Install /Quiet /NorestartT" -Verb RunAs -Wait
    } catch {
        Log-Message $error "Failed to download or install SSMS. Error: $_"
        return $false
    }
    return $true
}


# Function to restore the database
function Restore-Database {
    param (
        [string]$ServerInstance,
        [string]$DatabaseName,
        [string]$BackupUrl,
        [string]$UserMssql,
        [string]$MssqlRoot
    )

    Log-Message $info "Restoring test database..."
    # Install powershell lib
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name SqlServer -Scope CurrentUser
    Import-Module -Name SqlServer
    # Download the backup file
    $BackupPath = Join-Path -Path $MssqlRoot -ChildPath "Backup\$DatabaseName.bak"
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $BackupUrl -OutFile $BackupPath -ErrorAction Stop

        # Restore script
        $SqlQueryRestoreDb = @"
        USE master;
        GO
        DECLARE @BackupPath NVARCHAR(500) = '$BackupPath';

        IF DB_ID('$DatabaseName') IS NOT NULL
        BEGIN
            ALTER DATABASE $DatabaseName SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
            DROP DATABASE $DatabaseName;
        END

        RESTORE DATABASE $DatabaseName
        FROM DISK = @BackupPath
        WITH MOVE 'AdventureWorksLT2019_Data' TO '$MssqlRoot\DATA\$DatabaseName.mdf',
             MOVE 'AdventureWorksLT2019_Log' TO '$MssqlRoot\DATA\$DatabaseName.ldf',
             REPLACE;
        ALTER DATABASE $DatabaseName SET RECOVERY Full
"@
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $SqlQueryRestoreDb -TrustServerCertificate
    } catch {
        Log-Message $error "Failed to restore the database. Error: $_"
        return $false
    }
    return $true
}


# Function to add user account
function Add-UserAccount {
    param (
        [string]$UserMssql
    )

    try {
        Log-Message $info "Adding user account $UserMssql as sysadmin..."
        # Add the user as sysadmin
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Query "EXEC sp_addsrvrolemember '$UserMssql', 'sysadmin'" -TrustServerCertificate
    } catch {
        Log-Message $error "Failed to add user account $UserMssql as sysadmin. Error: $_"
        return $false
    }
    return $true
}


# Function to check if a port is already allowed in the firewall
function Check-FirewallPortClosed {
    param (
        [int]$Port
    )

    # Get all firewall rules
    $firewallRules = Get-NetFirewallRule

    # Check if any rule exists for the specified port
    $portRule = $firewallRules | Where-Object { $_.DisplayName -eq "$FwLabel $Port" }

    if ($portRule) {
        return $false
    } else {
        return $true
    }
}


# Function to add a firewall rule for a single port
function Add-FirewallRuleSinglePort {
    param (
        [int]$Port
    )

    try {
        if (Check-FirewallPortClosed -Port $Port) {
            New-NetFirewallRule -DisplayName "$FwLabel $Port" -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow -ErrorAction Stop
            Log-Message $info "Firewall rule for port $Port added successfully."
        } else {
            Log-Message $info "Firewall rule for port $Port already exists. No changes made."
        }
    } catch {
        Log-Message $error "Error occurred while adding firewall rule: $_"
        return $false
    }
    return $true
}


# function to add Firewall rules
function Add-FirewallRule {
    param(
        [int]$Port1,
        [int]$Port2
    )

    try {
        if ((Add-FirewallRuleSinglePort -Port $Port1) -and (Add-FirewallRuleSinglePort -Port $Port2)) {
            return $true
        } else {
            return $false
        }
    } catch {
        Log-Message $error "Error occurred while adding firewall rules: $_"
        return $false
    }
}


# MAIN
if (Check-RebootRequired) {
    Log-Message $error "A computer restart is required. Please restart your computer and try again."
    exit 1
}

Log-Message $info "Rubrik account defined: $UserMssql"

if (-not (Install-SqlServerExpress2019)) {
    Log-Message $error "Failed to install SQL Server Express 2019. Exiting script."
    exit 1
}

if (-not (Install-Ssms)) {
    Log-Message $error "Failed to install SSMS 2019. Exiting script."
    exit 1
}

if (-not (Restore-Database -ServerInstance $ServerInstance -DatabaseName $DatabaseName -BackupUrl $AdventureWorkUrl -UserMssql $UserMssql -MssqlRoot $MssqlRoot)) {
    Log-Message $error "Failed to recover the database. Exiting script."
    exit 1
}

if (-not (Add-UserAccount -UserMssql $UserMssql)) {
    Log-Message $error "Failed to add user account $UserMssql as sysadmin. Exiting script."
    exit 1
}

if (-not (Add-FirewallRule -Port1 12800 -Port2 12801)) {
    Log-Message $error "Failed to add firewall rules."
    exit 1
}
