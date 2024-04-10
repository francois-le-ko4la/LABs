function Install-SQLServerExpress2019 {
    Write-Host "Downloading SQL Server Express 2019..."
    $Path = $env:TEMP
    $Installer = "SQL2019-SSEI-Expr.exe"
    $URL = "https://go.microsoft.com/fwlink/?linkid=866658"
    Invoke-WebRequest $URL -OutFile $Path\$Installer

    Write-Host "Installing SQL Server Express..."
    Start-Process -FilePath $Path\$Installer -Args "/ACTION=INSTALL /IACCEPTSQLSERVERLICENSETERMS /QUIET" -Verb RunAs -Wait
    Remove-Item $Path\$Installer
}

function Install-MSSP {
    Write-Host "Downloading MSSP..."
    $Path = $env:TEMP
    $Installer = "SSMS-Setup-ENU.exe"
    $URL = "https://go.microsoft.com/fwlink/?linkid=2257624&clcid=0x409"
    Invoke-WebRequest $URL -OutFile $Path\$Installer

    Write-Host "Installing MSSP..."
    Start-Process -FilePath $Path\$Installer -Args "/Install /Quiet /NorestartT" -Verb RunAs -Wait
    Remove-Item $Path\$Installer
}

Install-SQLServerExpress2019
Install-MSSP

$AdventureWork="https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2019.bak"
$backupPath = "C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\Backup\AdventureWorksLT2019.bak"
Invoke-WebRequest -Uri $AdventureWork -OutFile $backupPath


Install-Module -Name SqlServer -Force -AllowClobber
Import-Module SqlServer

$serverInstance = "localhost\SQLEXPRESS"
$server = New-Object Microsoft.SqlServer.Management.Smo.Server($serverInstance)
$server.Databases
Invoke-Sqlcmd -ServerInstance $serverInstance -Query "EXEC sp_addsrvrolemember 'RUBRIK\demo', 'sysadmin'" -TrustServerCertificate

$sqlQuery_restore_db = @"
USE master;
GO
DECLARE @BackupPath NVARCHAR(500) = 'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\backup\AdventureWorksLT2019.bak';

IF DB_ID('AdventureWorks2019') IS NOT NULL
BEGIN
    ALTER DATABASE AdventureWorks2019 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AdventureWorks2019;
END

RESTORE DATABASE AdventureWorks2019
FROM DISK = @BackupPath
WITH MOVE 'AdventureWorks2019_Data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\AdventureWorksLT2019.mdf',
     MOVE 'AdventureWorks2019_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\AdventureWorksLT2019.ldf',
     REPLACE;
ALTER DATABASE AdventureWorks2019 SET RECOVERY Full
"@
Invoke-Sqlcmd -ServerInstance $serverInstance -Query $sqlQuery_restore_db -TrustServerCertificate

