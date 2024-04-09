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

Install-SQLServerExpress2019
