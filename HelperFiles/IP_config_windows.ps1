param (
    [Parameter(Mandatory=$true)][string]$ip_address,
    [Parameter(Mandatory=$true)][string]$prefixLength,
    [Parameter(Mandatory=$true)][string]$gateway,
    [string]$dns1 = "",
    [string]$dns2 = ""
)

# Get the network adapter
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1

if ($adapter -eq $null) {
    Write-Host "No active network adapter found."
    exit 1
}

# Remove existing IP address
Remove-NetIPAddress -InterfaceIndex $adapter.ifIndex -Confirm:$false

# Remove existing default gateway
Remove-NetRoute -InterfaceIndex $adapter.ifIndex -Confirm:$false

# Convert the subnet mask string to a byte array
$bytes = [System.Net.IPAddress]::Parse($subnetMask).GetAddressBytes()

# Set new IP address , Gateway and subnet mask
New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $ip_address -PrefixLength $prefixLength -DefaultGateway $gateway

# Set DNS servers
if ($dns1 -ne "") {
    if ($dns2 -ne "") {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dns1, $dns2
    } else {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dns1
    }
}

Write-Host "IP configuration updated successfully."

# Display new IP configuration
# Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex | Format-List IPAddress, DefaultGateway, DNSServer