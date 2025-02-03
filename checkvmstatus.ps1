# Login to Azure
#Connect-AzAccount

# Get all VMs in the subscription
$allVMs = Get-AzVM

# Initialize results array
$results = @()

foreach ($vm in $allVMs) {
    try {
        Write-Host "Processing VM: $($vm.Name) in Resource Group: $($vm.ResourceGroupName)"

        # Get CPU percentage metric for the past 1 month (grouped by 1 day)
        $metricData = Get-AzMetric -ResourceId $vm.Id `
                                   -MetricName "Percentage CPU" `
                                   -StartTime (Get-Date).AddMonths(-2) `
                                   -EndTime (Get-Date) `
                                   -TimeGrain ([TimeSpan]::FromDays(1)) `
                                   -DetailedOutput

        # Check if there are metrics available
        if ($metricData.Data -eq $null -or $metricData.Data.Count -eq 0) {
            Write-Host "No metrics found for VM: $($vm.Name)"
            continue
        }

        # Group metric values by day of the week and calculate the average CPU usage
        $metricsGroupedByDay = $metricData.Data | Group-Object { $_.TimeStamp.DayOfWeek }
        foreach ($group in $metricsGroupedByDay) {
            $day = $group.Name
            $values = $group.Group | Where-Object { $_.Average -ne $null } | Select-Object -ExpandProperty Average

            if ($values -and $values.Count -gt 0) {
                $averageUsage = ($values | Measure-Object -Sum).Sum / $values.Count
            } else {
                $averageUsage = "No Data"
            }

            # Add to the results
            $results += [PSCustomObject]@{
                VMName         = $vm.Name
                ResourceGroup  = $vm.ResourceGroupName
                Weekday        = $day
                AverageUsage   = $averageUsage
            }
        }
    } catch {
        Write-Host "Error processing VM: $($vm.Name). Details: $_"
    }
}

# Export results to a CSV file
$reportFilePath = "VM_Weekday_CPU_Usage_Report1.csv"
$results | Sort-Object VMName, Weekday | Export-Csv -Path $reportFilePath -NoTypeInformation -Force

Write-Host "Report saved to $reportFilePath"
