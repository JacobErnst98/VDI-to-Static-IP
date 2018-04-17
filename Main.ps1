<#
.SYNOPSIS
  Gets all Ip's from every VM in a given VC
.DESCRIPTION
 This will generate a file containing all 

Ips from a given vc in a linux dhcp format 

You must have admin or read only admin role on the VCenter

The errors will be in a diffrent file. 
.INPUTS
  None
.OUTPUTS
  Ip's file
  Errors File
.NOTES

  INFO
    Version:        1.1
    Author:         Jacob Ernst
    Modification Date:  4/17/2018
    Purpose/Change: Sanitise For Git
    Modules:        Vmware* (PowerCLI)

  BUGS
    Some Vms' may be off and go to errors this should not happen


  TODO
   Check vm power state better


#>



#Gui and Asymbly types for the form
Add-Type -AssemblyName System.Windows.Forms



$Static = New-Object system.Windows.Forms.Form
$Static.Text = "VM IPs"
$Static.TopMost = $true
$Static.Width = 349
$Static.Height = 381

$GO = New-Object system.windows.Forms.Button
$GO.Text = "GO"
$GO.Width = 60
$GO.Height = 30
$GO.location = new-object system.drawing.point(134,306)
$GO.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($GO)

$UserL = New-Object system.windows.Forms.Label
$UserL.Text = "User"
$UserL.AutoSize = $true
$UserL.Width = 25
$UserL.Height = 10
$UserL.location = new-object system.drawing.point(149,26)
$UserL.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($UserL)


$PasswdL = New-Object system.windows.Forms.Label
$PasswdL.Text = "Password"
$PasswdL.AutoSize = $true
$PasswdL.Width = 25
$PasswdL.Height = 10
$PasswdL.location = new-object system.drawing.point(135,79)
$PasswdL.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($PasswdL)

$ServerL = New-Object system.windows.Forms.Label
$ServerL.Text = "Server"
$ServerL.AutoSize = $true
$ServerL.Width = 25
$ServerL.Height = 10
$ServerL.location = new-object system.drawing.point(145,124)
$ServerL.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($ServerL)


$OFL = New-Object system.windows.Forms.Label
$OFL.Text = "Output File"
$OFL.AutoSize = $true
$OFL.Width = 25
$OFL.Height = 10
$OFL.location = new-object system.drawing.point(130,173)
$OFL.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($OFL)


$OFEL = New-Object system.windows.Forms.Label
$OFEL.Text = "Output Error File"
$OFEL.AutoSize = $true
$OFEL.Width = 25
$OFEL.Height = 10
$OFEL.location = new-object system.drawing.point(114,212)
$OFEL.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($OFEL)



$vmcount = New-Object system.windows.Forms.Label
$vmcount.Text = "Vm Count"
$vmcount.AutoSize = $true
$vmcount.Width = 25
$vmcount.Height = 10
$vmcount.location = new-object system.drawing.point(136,269)
$vmcount.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($vmcount)


$UserB = New-Object system.windows.Forms.TextBox
$UserB.Width = 212
$UserB.Height = 20
$UserB.location = new-object system.drawing.point(55,45)
$UserB.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($UserB)


$PasswdB = New-Object system.windows.Forms.MaskedTextBox
$PasswdB.Width = 212
$PasswdB.Height = 20
$PasswdB.location = new-object system.drawing.point(55,97)
$PasswdB.Font = "Microsoft Sans Serif,10"
$PasswdB.PasswordChar = '*'
$PasswdB.Visible = "false"
$Static.controls.Add($PasswdB)

$ServerB = New-Object system.windows.Forms.TextBox
$ServerB.Width = 212
$ServerB.Height = 20
$ServerB.location = new-object system.drawing.point(55,144)
$ServerB.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($ServerB)

$OFB = New-Object system.windows.Forms.TextBox
$OFB.Width = 212
$OFB.Height = 20
$OFB.location = new-object system.drawing.point(55,189)
$OFB.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($OFB)

$OFEB = New-Object system.windows.Forms.TextBox
$OFEB.Width = 212
$OFEB.Height = 20
$OFEB.location = new-object system.drawing.point(55,233)
$OFEB.Font = "Microsoft Sans Serif,10"
$Static.controls.Add($OFEB)










#button for 
$GO.Add_click({

#Get user input
	$server = $ServerB.Text
$password = $PasswdB.Text
$user = $UserB.Text

#Connect to server
Connect-VIServer -Server $server -Protocol https -User $user -Password $password;


#get more user input
$fileerr=$OFEB.Text
$file=$OFB.Text

#get a list of esx hosts
$esx = Get-VMHost 
$vmcountnum = 0



#For every host get a list of vms
foreach($esx in (Get-VMHost)){
    $vms = Get-VM -Location $esx
    if($vms){

    #for every vm in the list of vms
      foreach($vm in $vms){
      $vmcountnum = $vmcountnum+1
	 $vmcount.Text=$vmcountnum


# make a custom powershell object to store datafeilds from difgfrent objects
      $stuff = New-Object -TypeName psobject 
      $stuff | Add-Member -MemberType NoteProperty -Name Vmname -Value ($vm| Get-NetworkAdapter | select parent).parent
      $stuff | Add-Member -MemberType NoteProperty -Name Mac -Value ($vm| Get-NetworkAdapter | select macaddress).MacAddress
      $stuff | Add-Member -MemberType NoteProperty -Name ip -Value ($vm| Select @{N="IPAddress";E={@($_.guest.IPAddress[0])}}).IPAddress
      $stuff | Add-Member -MemberType NoteProperty -Name power -Value ($vm.PowerState)
      if ($stuff.power -eq "PoweredOn" ) {
      if ($vm.Guest.IPAddress.Length -lt 3){

      if ($vm.Guest.IPAddress.Length -eq 0){
      #the vm has no ip
      echo "Host reports $($stuff.Vmname) has no ip adress, is vmware tools running? " | Out-File $fileerr -Append
      }
      else{

      #your a good vm echo to the file
      echo "host $($stuff.vmname).ChangeMe.com {
      hardware ethernet $($stuff.Mac);
      fixed-address $($stuff.ip);
}
" | Out-File $file -Append
}
}

#the vm has to many addressess
else{echo "$($stuff.Vmname) has many ip addresses $($vm.Guest.IPAddress)`n" | Out-File $fileerr -Append}
    }
    else{
        #really just a catchall error the vm is off or broken
        echo "error powered off: $($stuff.Vmname)`n" | Out-File $fileerr -Append
    }  
    }
    }
    } 
    })
	$vmcount.Text= "done"
	[void]$Static.ShowDialog()
    
