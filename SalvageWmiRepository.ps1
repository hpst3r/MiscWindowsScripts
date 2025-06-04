# https://techcommunity.microsoft.com/blog/askperf/wmi-rebuilding-the-wmi-repository/373846
# stubbins right now, needs some attention

# wmi repository is located at %windir%\System32\wbem\repository

# check the repository
& winmgmt /verifyrepository

# salvage (replace inconsistent parts of the repository only)
& winmgmt /salvagerepository

# caution: this will reset the winmgmt repository to its initial state
# & winmgmt /resetrepository