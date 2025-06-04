# the SystemStabilityIndex is a value between 0 and 10 (10 most stable)
# this value is calculated based on number of events, process crashes, etc
# data is stored for one month by default, so the average is over the last month
# average for a functioning system is probably ~7.5, sub 3 is something wrong

# see the Reliability Monitor control panel widget for a graphical view w/ events

# query CIM instance Win32_ReliabilityStabilityMetrics
# get the average and min of SystemStabilityIndex property
$StabilityIndex = (
  (Get-CimInstance Win32_ReliabilityStabilityMetrics).SystemStabilityIndex |
    Measure-Object -Average -Minimum |
    Select-Object Average,Minimum
  )

# NinjaRMM limitation - needs to be a fake single, not a double
# also round to 2 decimal places while we're at it
$StabilityIndex.Average = [single][Math]::Round($StabilityIndex.Average, 2)
$StabilityIndex.Minimum = [single][Math]::Round($StabilityIndex.Minimum, 2)

# POST the average and minimum values to NinjaRMM as a custom field
Ninja-Property-Set -Name 'systemStabilityIndexAverage' -Value $StabilityIndex.Average
Ninja-Property-Set -Name 'systemStabilityIndexMinimum' -Value $StabilityIndex.Minimum