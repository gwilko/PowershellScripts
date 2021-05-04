###########################################
#
# get a list of all the clients on the network
# Author: Graeme Wilkinson
# Date:   27th July 2017
# \_(ツ)_/
###########################################

# netsh dhcp server \\serverdhcp1 scope 10.182.251.128 show clients 1

"ServerName,IPAddress,MAC,Date" | Out-File "C:\graeme\dhcp\RawDHCPdump.txt"
"ServerName,IPAddress,MAC,Date" | Out-File "C:\graeme\dhcp\DHCPClients.txt"


function Get-DHCP-Clients ($dhcpservername, $dhcpserverscope){
    # for testing $dhcpservername = "server1"
    # for testing $dhcpserverscope = "10.202.128.0"
    $clientinscope = @()
    $clientinscope = netsh dhcp server \\$dhcpservername scope $dhcpserverscope show clients 1
    # split the output into usable parts
    # $clientinscope
    #$loopthrough = 1
    foreach ($l in $clientinscope){
        #$loopthrough
        $DeviceName = " "
        $IPAddress = " "
        $MAC = " "
        $DHCPDate = " "
        $unit1 = ($l.Split("-"))[0]
        $unit2 = ($unit1.Split(" "))[0]
        # if the line starts with an IP address then process it
        if ($unit2 -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){
            $l | Add-Content "C:\graeme\dhcp\RawDHCPdump.txt"
            $IPAddress = ($l.Split("-"))[0]
            # Write-Output "IP Addres is: $IPAddress"
            # doesn't work $e = ($l.Split(" ")|Where-Object {$_ -ne " "})
            #Write-Output "e1 is: $e[1], e2 is: $e[2], e3 is: $e[3], e4 is: $e[4], e5 is: $e[5], e6 is: $e[6], "
            # $MAC = ($l.substring(34,17))
            $MAC = [regex]::Match($l,"([a-z0-9]{2}-){5}[a-z0-9]{2}")
            $MAC = $MAC.Value
            # Write-Output "MAC is: $MAC"
            $DHCPDate = $l.substring(56,21)
            #if test bit is NEVER or INACTIVE then or it's a date
            if (($DHCPDate -eq "NEVER EXPIRES        ") -or ($DHCPDate -eq "INACTIVE             ")){
                $DeviceName = ($l.substring(82,($l.Length)-82))
                #$DHCPDate + "in the never inact bit"
            }else{
                #$DHCPDate + "in the else bit"
                $DeviceName = ($l.substring(84,($l.Length)-84))
                $DHCPDate = [regex]::Match($l,"([0-9]{1,2}/){2}[0-9]{4} ([0-9]{1,2}:){2}[0-9]{1,2} [AP]M")
                $DHCPDate = $DHCPDate.Value
            }
            # *********** doesn't append, it overwrites
            $DeviceName.Trim() + "," + $IPAddress.Trim() + "," + $MAC.Trim() + "," + $DHCPDate.Trim() | Add-Content "C:\graeme\dhcp\DHCPClients.txt"
            #$lines | Out-File "C:\graeme\dhcp\DHCPExport2.txt"
            # $l.Length
            #$DeviceName = ($l.Split(" "))[6]
            #Write-Output "Device Name using 6 is: $DeviceName"
            #$DeviceName = ($l.Split(" "))[7]
            #Write-Output "Device Name using 7 is: $DeviceName"
            # $DeviceName.Trim() + "," + $IPAddress.Trim() + "," + $MAC.Trim()
            # $IPAddress.Trim() + "," + $MAC.Trim() + ","
        }
        #$loopthrough ++
    }
}

# get a list of dhcp servers
$dhcpservers = @()
Write-Output "running netsh to get all the dhcp servers"
$dhcpservers = (netsh dhcp show server)
$dhcpservernames = @()

# "ServerName,IPAddress,MAC,Date" | Out-File "C:\graeme\dhcp\DHCPClients.txt"
# "ServerName,IPAddress,MAC,Date" | Out-File "C:\graeme\dhcp\RawDHCPdump.txt"
# run through each line and pull out server names
# this is here for testing 
#   $line3 = $dhcpservers[3]

Write-Output "looping through the output and pulling out server names"
$i2 = 1
foreach ($line3 in $dhcpservers){
    $l3 = $line3.split('.')
    $l4 = $l3[0].split('[')
    $l5 = $l4[1]
    $l5 = $l5 -replace '=',''
    $l6 = @()
    $l6 = $l5.split(']')
    $dhcpservernames += $l6[0] | Where-Object {$_ -ne ""}
    "found " + $i2 + " dhcp servers"
    $i2 ++
}

# this is a better way to do arrays but I have not used it yet
#$outItems = New-Object System.Collections.Generic.List[System.Object]
#$outItems.Add(1)
#$outItems.Add("hi")

# we have a list of dhcp servers in the $dhcpservernames array
$lines = @()
#$errorlines = @()
#$server = $dhcpservernames
# $server = "server1"
Write-Output "checking what scopes each dhcp server has"
foreach ($server in $dhcpservernames){
    $server
    # this line is for testing so I can run the inside of this loop against 1 device
    #      $server = 'serverdhcp1'
    $a = (netsh dhcp server \\$server show scope)
    #start by looking for lines where there is IP present
    foreach ($i in $a){
        if ($i -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){
                $lines += $server + "-" + $i.Trim()
        }
    }
}

$listofdhcpscopes = @()
# $l = $lines[1]

# clean up the list of dhcp scopes on servers
$iterations = 1
foreach ($l in $lines){
    $iterations
    $t1 = ($l.Split("-"))[1]
    $test = ($t1.Split(" "))[0]
    if ($test -eq "Unable"){
        $Srvr = ($l.Split("-"))[0]
        $listofdhcpscopes +=  $Srvr.Trim() + ",Unable to determine the DHCP Server version"
    }else{
        $Srvr = ($l.Split("-"))[0]
        $Scope = ($l.Split("-"))[1]
        $SubNetMask = ($l.Split("-"))[2]
        $State = ($l.Split("-"))[3]
        $ScopeName = ($l.Split("-"))[4]
        $listofdhcpscopes += $Srvr.Trim() + "," + $Scope.Trim() + "," + $SubNetMask.Trim() + "," + $State.Trim() + "," + $ScopeName.Trim()
        # for each scope go and get a list of devices on it
        # if the scope is active therefore in use then work out what is in it
        if ($State.Trim() -eq "Active"){
            Get-DHCP-Clients $Srvr.Trim() $Scope.Trim()
            #$Srvr = $Srvr.Trim()
            #$Scope= $Scope.Trim()
            #$a = (netsh dhcp server \\$Srvr scope $Scope show clients 1)
        }
    }
    $iterations ++
}

# $csvfile | sort-object Subnet | Out-File "C:\graeme\dhcp\DHCPExport.csv"

# $lines | Out-File "C:\graeme\dhcp\DHCPExport2.txt"
$listofdhcpscopes | Out-File "C:\graeme\dhcp\DHCPExport.txt"

#$server = "serverdhcp1"

#netsh dhcp show server
#netsh dhcp server \\$server show scope
#netsh dhcp server \\serverdhcp1 scope 10.20.20.0 show clients 1


