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

.PARAMETER None
    This script does not accept any parameters.

.NOTES
    File Name: BuildMSSQL.ps1
    Author   : [Your Name]
    Version  : 1.0
    Date     : [Date]

.EXAMPLE
    PS C:\> .\BuildMSSQL.ps1
    # Runs the script to install SQL Server Express 2019, SSMS, and restore AdventureWorks2019 database.

#>

# Check if PowerShell version is compatible
if ($PSVersionTable.PSVersion.Major -lt 5 -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)) {
    Write-Host "This script requires PowerShell 5.1 or later. Please upgrade your PowerShell version."
    exit
}

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as an administrator."
    exit
}

# Define variables
$ServerInstance = "localhost\SQLEXPRESS"
$DatabaseName = "AdventureWorks2019"
$UserMssql = "RUBRIK\demo"
$MssqlRoot = "C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL"
$AdventureWorkUrl = "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2019.bak"
$MssqlUrl = "https://go.microsoft.com/fwlink/?linkid=866658"
$MssqlBin = "SQL2019-SSEI-Expr.exe"
$SsmsUrl = "https://go.microsoft.com/fwlink/?linkid=2257624&clcid=0x409"
$SsmsBin = "SSMS-Setup-ENU.exe"


# Function to install SQL Server Express 2019
function Install-SqlServerExpress2019 {
    Write-Host "Downloading SQL Server Express 2019..."
    $Path = $env:TEMP
    $Installer = $MssqlBin
    $Url = $MssqlUrl
    try {
        Invoke-WebRequest $Url -OutFile "$Path\$Installer" -ErrorAction Stop

        Write-Host "Installing SQL Server Express..."
        Start-Process -FilePath "$Path\$Installer" -Args "/ACTION=INSTALL /IACCEPTSQLSERVERLICENSETERMS /QUIET" -Verb RunAs -Wait
        Remove-Item "$Path\$Installer"
    } catch {
        Write-Host "Failed to download or install SQL Server Express 2019. Error: $_" -ForegroundColor Red
    }
}


# Function to install SQL Server Management Studio (SSMS)
function Install-Ssms {
    Write-Host "Downloading SSMS..."
    $Path = $env:TEMP
    $Installer = $SsmsBin
    $Url = $SsmsUrl
    try {
        Invoke-WebRequest $Url -OutFile "$Path\$Installer" -ErrorAction Stop

        Write-Host "Installing SSMS..."
        Start-Process -FilePath "$Path\$Installer" -Args "/Install /Quiet /NorestartT" -Verb RunAs -Wait
        Remove-Item "$Path\$Installer"
    } catch {
        Write-Host "Failed to download or install SSMS. Error: $_" -ForegroundColor Red
    }
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

    # Download the backup file
    $BackupPath = Join-Path -Path $MssqlRoot -ChildPath "Backup\$DatabaseName.bak"
    try {
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
        Write-Host "Failed to restore the database. Error: $_" -ForegroundColor Red
    }
}


# MAIN
Install-SqlServerExpress2019
Install-Ssms
Restore-Database -ServerInstance $ServerInstance -DatabaseName $DatabaseName -BackupUrl $AdventureWorkUrl -UserMssql $UserMssql -MssqlRoot $MssqlRoot
# Add the user as sysadmin
Invoke-Sqlcmd -ServerInstance $ServerInstance -Query "EXEC sp_addsrvrolemember '$UserMssql', 'sysadmin'" -TrustServerCertificate
