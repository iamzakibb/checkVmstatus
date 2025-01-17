# Function to check if the VM is in use
function Check-VMStatus {
    param (
        [string]$ResourceGroupName,
        [string]$VMName
    )
    # Get the power state of the VM
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
    $powerState = $vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' } | Select-Object -ExpandProperty Code

    # Output the power state
    Write-Output "Current Power State of VM '$VMName': $powerState"

    # Return whether the VM is running
    return $powerState -eq "PowerState/running"
}

# Function to shut down the VM if it's not in use
function Shutdown-VMIfNotInUse {
    param (
        [string]$ResourceGroupName,
        [string]$VMName
    )
    # Check the VM status
    $isRunning = Check-VMStatus -ResourceGroupName $ResourceGroupName -VMName $VMName

    if (-not $isRunning) {
        Write-Output "VM '$VMName' is not in use. Initiating shutdown..."
        Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force
        Write-Output "VM '$VMName' has been shut down."
    } else {
        Write-Output "VM '$VMName' is currently in use and will not be shut down."
    }
}

# Example usage
$ResourceGroupName = "YourResourceGroupName"  # Replace with your resource group name
$VMName = "YourVMName"  # Replace with your VM name

Shutdown-VMIfNotInUse -ResourceGroupName $ResourceGroupName -VMName $VMName
