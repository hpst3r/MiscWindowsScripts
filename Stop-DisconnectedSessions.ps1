# query active sessions

foreach ($line in (QUERY SESSION)) {

  if ($line -match "SESSIONNAME") { Continue } # skip header line

  # PS C:\WINDOWS\system32> query session
  #    SESSIONNAME               USERNAME                 ID  STATE   TYPE        DEVICE
  #    services                                            0  Disc
  #   >rdp-tcp#0                 nltest                    1  Active
  #    console                                             3  Conn
  #    rdp-tcp                                         65536  Listen

  # couldn't think of a better way to do it, this SUCKS
  # create an object from each session
  $UserSession = New-Object PsObject -Property @{

      SessionName = $line.Substring(1,25).Trim()
      UserName = $line.Substring(27,21).Trim()
      SessionId = $line.Substring(48,6).Trim() # this depends on max 6 digit integer SID
      SessionState = $line.Substring(56,8).Trim()

  }

  # log out user if they have a session that is not "services" that reports Disconnected

  if (( -Not ($UserSession.SessionName -match "services")) -and ($UserSession.SessionState -match "Disc")) {

    logoff.exe $UserSession.SessionId

  }

}
