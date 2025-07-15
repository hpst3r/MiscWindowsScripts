# Combine CSV files

function Combine-CsvFiles {
  param (
    $Path,
    $OutputFile
  )

  $Files = Get-ChildItem -Path $Path -Filter *.csv

  for ($i = 0; $i -lt $Files.Length; $i++) {

    if ($i -eq 0) {

      Write-Host "Writing first file $($Files[$i].FullName) to output $($OutputFile) with header."

      Import-CSV -Path $Files[$i].FullName |
        Export-CSV -Path $OutputFile

    } else {

      Write-Host "Writing file $($Files[$i].FullName) to output $($OutputFile) append, without header."

      Import-CSV -Path $Files[$i].FullName |
        Export-CSV -Path $OutputFile -Append -NoTypeInformation

    }

  }

}
