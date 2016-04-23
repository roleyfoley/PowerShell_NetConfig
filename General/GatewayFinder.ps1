# Gateway Locator and Router adder 
# In our network configuration either the first or last usable host address is used as the Gateway IP. 
# This script will calculate what the gateway would be based on the IP configuration of the local server
# 
# Written by: mf2201 - 23/04/2016

Param 
(
	[Parameter(Mandatory=$true)][string]$IPCidr,
    [Parameter(Mandatory=$true)][string]$GWLocation
)

$GWLocation = $GWLocation.ToLower()

switch ($GWLocation) {
    "first" { 
        $BinaryFill = "0" 
        $BinaryEnd = "1" 
     }
     "last" {
        $BinaryFill = "1"
        $BinaryEnd = "0"
     } 
}       

# Split IP into IP and Mask
$IPAddress = $IPCidr.Split('/')[0]
$CidrMask = $IPCidr.Split('/')[1]

if ( $IPAddress -eq $null -or $CidrMask -eq $null -or $CidrMask -NotIn 8..32  ) {
	throw "IP Address invalid - Check that you have submitted the IP in CIDR format"
}  

# Convert the IP to Binary 
$HostBinary = ([Convert]::toString(([IPAddress][String]([IPAddress]$($IPAddress)).Address).Address,2)).PadLeft(32, "0") 

if ($HostBinary -eq $null) {
	throw "Invalid IP Address"
}

#Split the Binary IP into Network/Host based on the Interfaces subnet mask - Keep the Network Binary part (the First part of the string)
$NetworkId = ($HostBinary | Where {$_ -match "^(.{$($CidrMask)})"} | ForEach{ [PSCustomObject]@{ 'BinaryNet' = $Matches[0] } }).BinaryNet

# Since Network ID +1 = 1st Address and Broadcast -1 = Last Usable address filling the Network ID with 1's or 0's and doing the opposite for the last bit will give you the IP in Binary 
While ( $NetworkId.Length -le 30 ) {
    $NetworkId = [String]$NetworkId + $BinaryFill
}  

if ($NetworkId.Length -eq 31) {
    $NetworkId = [string]$NetworkId + $BinaryEnd
}

# Convert the Binary IP back into Dotted Quad 
$GatewayDetails = New-Object psobject
$GatewayDetails | Add-Member -MemberType NoteProperty -Name IP -Value $IPAddress
$GatewayDetails | Add-Member -MemberType NoteProperty -Name CidrMask -Value $CidrMask
$GatewayDetails | Add-Member -MemberType NoteProperty -Name Gateway -Value $(([System.Net.IPAddress]"$([System.Convert]::ToInt64($NetworkId,2))").IPAddressToString)

return $GatewayDetails