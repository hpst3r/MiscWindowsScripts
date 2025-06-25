# enumerate user profiles and translate SIDs to usernames when possible
# handles local, domain (5) and AAD (12) accounts
Function Get-Profiles {

  Get-CimInstance Win32_UserProfile |
  Where-Object SID -match '^S-1-(5|12)-\d{1,2}-\d+-\d+-\d+-.*' |
  ForEach-Object {
    $SID = [System.Security.Principal.SecurityIdentifier]$_.SID
    try {
        $SID.Translate([System.Security.Principal.NTAccount]).Value
    } catch {
        $SID.Value
    }
  }

}
