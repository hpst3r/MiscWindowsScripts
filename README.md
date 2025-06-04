# Miscellaneous Windows scripts

Miscellaneous PowerShell scripts and functions for doing various things on
Windows clients and servers.

No particular order to the madness here - just a small handful of general
snippets that don't have anything I wouldn't want on display.

## 4624.ps1

Quick script thrown together to query AD for ID 4624 "logon" events,
probably written during a time of panic.

## Add-UserRightAssignment.ps1

PowerShell script wrapping Secedit to add user right assignments via script.

## Combine-CSV.ps1

Quick script to combine "n" comma-separated value files into one.
Useful if you have several dozen month-to-month files and would like one aggregate.

## CompactOS.ps1

Very quick wrapper around compact /compactos:always to prevent output from
clogging up RMM logs. I typically run this on machines with low disk but it
can also improve performance on spinning disks.

## Get-LocalGroupMembers.ps1

Quick script to push local group membership info to RMM.

## Install-Teams.ps1

PowerShell wrapper for the Teams Bootstrapper utility.
Run it elevated (SYSTEM from RMM) and it'll install Teams for every user on the box.
See Microsoft Learn: [learn.microsoft.com/new-teams-bulk-install-client](https://learn.microsoft.com/en-us/microsoftteams/new-teams-bulk-install-client).

## Install-WingetPackage.ps1

Quick PowerShell wrapper for calling Winget from SYSTEM context,
where it's not on the PATH. This works.. sometimes. Apps don't expect SYSTEM.

## KB5002623Remediation.ps1

Relevant blog post is [at wporter.org, here](https://wporter.org/quick-and-dirty-install-kb5002623-fix-for-office-2016-crashing-after-kb5002700-installation-via-executable-patch/).
Quick script to download and install KB5002700 and KB5002623 for Office 2016.

## LogonEventThing.ps1

Looks like a better version of "4624.ps1". They were in different repos,
so I either duplicated them at some point, or 4624 grew up.
I'll leave em as-is for now.

## New-StartupApp.ps1

PowerShell snippet to register an executable as a 'Startup App' by creating
a Start Menu\Programs\Startup shortcut via COM object.

## PrinterCleanup.ps1

I think I dropped this into RMM to remove every variation of an old printer
in an Entra-only environment at one point. I would usually do this via GPO.

## Remove-SentinelOne.ps1

Run SentinelOne cleaner or call the uninstaller via script. Had a lot of
S1 installs bite the dust, so this gets a workout.

## Remove-WingetPackage.ps1

SYSTEM counterpart to Install-WingetPackage above.

## SalvageWmiRepository.ps1

This is just a stub at the time of writing.
I still need to figure out how to use these tools.

## Set-OldContextMenu.ps1

I think this is a little piece ripped out of my setup script. Quite a few
people complained about the new W11 context menu (I agree with them),
so I wound up using this reg tweak often enough to drop the script in RMM.

## Set-ShowFileExtensions.ps1

I think this is pending me figuring out how to deal with every hive.
Sooner or later.

## Set-UPNSuffix.ps1

I use this to rearrange UPN suffixes for hybrid AD join environments.
UPN is usually something.local not domain.com, and that needs to change
or SSO won't work, so I need to change it, or SSO won't work.

## Stop-DisconnectedSessions.ps1

I have no idea what I wrote this for. I think it's quite old.
It was probably set to run via Task Scheduler.

## Update-DNSARecord.ps1

Little helper to bulk-set DNS A records on a Windows DNS server.
