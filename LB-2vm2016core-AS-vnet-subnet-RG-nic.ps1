$1ResourceGroupName = "RG-WebMAT"
$1Location = "EastUS"
$1vmName = "WebMAT"
$1ImageName = "MicrosoftWindowsServer:WindowsServer:2016-Datacenter-Server-Core:latest"
$1VirtualNetworkName = "WebMATVNET"
$1SubnetName = "WebMATVNET"
$1PublicIpAddressName = "WebMATPIP"
$1Size = "Standard_B1s"


New-AzResourceGroup `
  -ResourceGroupName $1ResourceGroupName `
  -Location $1Location


$1publicIP = New-AzPublicIpAddress `
  -ResourceGroupName $1ResourceGroupName `
  -Location $1Location `
  -AllocationMethod "Static" `
  -Name $1PublicIpAddressName


$1frontendIP = New-AzLoadBalancerFrontendIpConfig `
  -Name "WebMATFEPool" `
  -PublicIpAddress $1publicIP

$1backendPool = New-AzLoadBalancerBackendAddressPoolConfig `
  -Name "WebMATBEPool"

$1lb = New-AzLoadBalancer `
  -ResourceGroupName $1ResourceGroupName `
  -Name "WebMATLB" `
  -Location $1Location `
  -FrontendIpConfiguration $1frontendIP `
  -BackendAddressPool $1backendPool


Add-AzLoadBalancerProbeConfig `
  -Name "Sonda1" `
  -LoadBalancer $1lb `
  -Protocol tcp `
  -Port 80 `
  -IntervalInSeconds 15 `
  -ProbeCount 2

Set-AzLoadBalancer -LoadBalancer $1lb

$1probe = Get-AzLoadBalancerProbeConfig -LoadBalancer $1lb -Name "Sonda1"

Add-AzLoadBalancerRuleConfig `
  -Name "WebMATLB" `
  -LoadBalancer $1lb `
  -FrontendIpConfiguration $1lb.FrontendIpConfigurations[0] `
  -BackendAddressPool $1lb.BackendAddressPools[0] `
  -Protocol Tcp `
  -FrontendPort 80 `
  -BackendPort 80 `
  -Probe $1probe

Set-AzLoadBalancer -LoadBalancer $1lb


$1subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name $1SubnetName `
  -AddressPrefix 192.168.1.0/24

$1vnet = New-AzVirtualNetwork `
  -ResourceGroupName $1ResourceGroupName `
  -Location $1Location `
  -Name $1VirtualNetworkName `
  -AddressPrefix 192.168.0.0/16 `
  -Subnet $1subnetConfig

for ($i=1; $i -le 2; $i++)
{
   New-AzNetworkInterface `
     -ResourceGroupName $1ResourceGroupName `
     -Name "$1vmName$i" `
     -Location $1Location `
     -Subnet $1vnet.Subnets[0] `
     -LoadBalancerBackendAddressPool $1lb.BackendAddressPools[0]
}


$1availabilitySet = New-AzAvailabilitySet `
  -ResourceGroupName $1ResourceGroupName `
  -Name "WebMATAS" `
  -Location $1Location `
  -Sku aligned `
  -PlatformFaultDomainCount 2 `
  -PlatformUpdateDomainCount 2

# Introducimos credenciales

$1cred = Get-Credential

for ($i=1; $i -le 2; $i++)
  {
    
    $2vmName = $1vmName + $i

    New-AzVM `
      -ResourceGroupName $1ResourceGroupName `
      -Name $2vmName `
      -Location $1location `
      -ImageName $1ImageName `
      -AvailabilitySetName "WebMATAS" `
      -Credential $1cred `
      -Size $1Size `
      -OpenPorts 80,3389

  

    }
  
