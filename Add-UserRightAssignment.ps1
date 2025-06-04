function Add-UserRightAssignment {
  param(
    [string]$Right,
    [Microsoft.PowerShell.Commands.LocalPrincipal]$User
  )

  try {

    $WorkingDir = (
      Join-Path `
        -Path $env:TEMP `
        -ChildPath (New-Guid)
      )

    if (Test-Path $WorkingDir) {
      
      Remove-Item `
        -Path $WorkingDir `
        -Force `
        -Recurse

    }

    New-Item `
      -ItemType Directory `
      -Path $WorkingDir

    $SecEditExportFile = (Join-Path -Path $WorkingDir -ChildPath 'Export.cfg')

    # export existing database
    & secedit.exe /export /cfg $SecEditExportFile

    # get line to modify
    $ExistingUsers = (
      Select-String `
        -Path $SecEditExportFile `
        -Pattern "(?<=^$($Right) = ).*"
      ).Matches.Value

    # don't make any changes if user already exists
    if ($ExistingUsers -and (($User.SID.Value -in $ExistingUsers) -or ($User.Name -in $ExistingUsers))) {

      Write-Debug -Message `
        "Add-UserRightAssigment: User $($User.SID.Value) already has desired rights. No changes will be made."
      
      return
      
    }

    # if there's stuff where SIDs are, look up local users
    # and convert names to SIDs - or shit no worky
    if ($ExistingUsers) {

      $SIDsFromExistingUsers = (
        $ExistingUsers -split ',' |
        Get-LocalUser |
        ForEach-Object {'*' + $_.SID.Value} |
        Join-String -Separator ','
      ) + ',' # trailing comma for formatting with our SID to be added

    }

    # generate a new minimal config with desired SID
    # extra space on line 4 is OK
    $NewConfigContent = @"
[Unicode]
Unicode=yes
[Privilege Rights]
$($Right) = $($SIDsFromExistingUsers)*$($User.SID.Value)
[Version]
signature="`$CHICAGO`$"
Revision=1
"@
  
    # create a config file
    $NewConfig = (
      New-Item `
        -ItemType File `
        -Path (
          Join-Path `
            -Path $WorkingDir `
            -ChildPath 'NewImport.cfg'
          )
      )

    # set content of config file to minimal gen'd config (mline string above)
    Set-Content `
      -Path $NewConfig `
      -Value $NewConfigContent

    $NewDB = (
      Join-Path `
        -Path $WorkingDir `
        -ChildPath 'NewImport.db'
      )

    # create a temporary database with modified configuration
    & secedit /import /db $NewDB /cfg $NewConfig

    # apply the modified config db to the system config
    & secedit /configure /db $NewDB

  }
  finally {

    # clean up working directory
    Remove-Item `
      -Path $WorkingDir `
      -Force `
      -Recurse

  }

}