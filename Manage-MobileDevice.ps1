<#
.SYNOPSIS
    Provides the administrative user with the possebility to perform remote actions on the device of a user.
.DESCRIPTION
    This script creates a form that requires a username as input. Based on the specified username it will show the primary mobile devices of the specified 
    username. This provides the administrative user with the option to retire, wipe, lock, or pin reset the primary mobile device of the specified username.
.PARAMETER SiteServer
    The site server with the SMS Provider.
.PARAMETER AllowWipe
    The WIPE button is enabled when this switch is specified.
.NOTES     
    Author: Peter van der Woude
    Contact: pvanderwoude@hotmail.com  
    Date published: 23-06-2015
    Updated: 18-12-2016
    Current version: 1.2
.LINK   
    http://www.petervanderwoude.nl
.EXAMPLE
    Manage-MobileDevice_v12.ps1 -SiteServer CLDSRV02 -AllowWipe
#>
[CmdletBinding()]

Param (
[Parameter(Mandatory=$True, HelpMessage="Specify the site server with the SMS Provider.")]
[String]$SiteServer,
[Parameter(Mandatory=$False, HelpMessage="Specify this switch to enable the WIPE button.")]
[Switch]$AllowWipe
) 

#Get the site code from SMS Provider
Try {
    $SiteCode = (Get-WmiObject -ComputerName $SiteServer -Namespace root/SMS -Class SMS_ProviderLocation -Filter "ProviderForLocalSite='$True'" -ErrorAction Stop).SiteCode
}
Catch {
    Throw "Unable to connect to the SMS Provider location on $SiteServer."
}

#Function to load the form
Function Load-Form {
    $Form.Controls.Add($ButtonClose)
    $Form.Controls.Add($ButtonExecute)
    $Form.Controls.Add($ButtonGet)
    $Form.Controls.Add($ButtonRetire)
    $Form.Controls.Add($ButtonWipe)
    $Form.Controls.Add($ComboBoxAction)
    $Form.Controls.Add($DataGridView)
    $Form.Controls.Add($LinkLabelBlog)
    $Form.Controls.Add($LinkLabelTwitter)
    $Form.Controls.Add($TextBoxUser)
    $Form.Controls.Add($GroupBoxClose)
    $Form.Controls.Add($GroupBoxDevice)
    $Form.Controls.Add($GroupBoxUser)
    $Form.Controls.Add($GroupBoxRemoteActions)
    $Form.Controls.Add($GroupBoxRetireWipe)

	$Form.ShowDialog()
}

#Function to reset the form
Function Reset-Form {
    $ErrorProvider.SetError($TextBoxUser,"")

    If ($DataGridView.RowCount -ne 0) {
        $DataGridView.Rows.Clear()
        $ButtonExecute.Enabled = $False
        $ButtonRetire.Enabled =  $False
        $ButtonWipe.Enabled =  $False
        $ComboBoxAction.Enabled = $False                         
    }
}

#Function to verify the provided user
Function Verify-User {
    Param (
    [String]$UserName
    )
    If($UserName.Length -eq 0) {
        $ErrorProvider.SetError($TextBoxUser, "Please verify the username.") 
        [Windows.Forms.MessageBox]::Show(“Please provide a valid username”, “User Verification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)         
    }
    Else {
        Try {
            #Get the user from WMI
            $User = Get-WmiObject -ComputerName $SiteServer -NameSpace root/SMS/site_$($SiteCode) -Class SMS_R_User -Filter "UserName='$UserName'" -ErrorAction Stop
            If ($User -ne $Null) {
                Return $User.UniqueUserName
            }
            Else {
                $ErrorProvider.SetError($TextBoxUser, "Please verify the username.") 
                [Windows.Forms.MessageBox]::Show(“Please provide an existing username.”, “User Verification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error) 
            }
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Please verify the connection with the specified site server.`n`n>>Failed to verify the username.”, “User Verification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }
}

#Function to get the primary mobile devices of the user
Function Get-MobileDevices {
    Param (
    [String]$UserName
    )
    Reset-Form
    $User = (Verify-User $UserName) -replace "\\","\\"
    If ($User -ne "OK") {
        Try {
            #Get the devices of the user from WMI
            $Devices = Get-WmiObject -ComputerName $SiteServer -Namespace root/SMS/site_$($SiteCode) -Query "SELECT r.* FROM SMS_CM_RES_COLL_SMSDM001 r inner JOIN SMS_UserMachineRelationship m ON r.ResourceID=m.ResourceID WHERE m.UniqueUserName='$User' AND m.Types = 1" -ErrorAction Stop
            If ($Devices -ne $Null) {
                ForEach ($Device in $Devices) {
                    $DataGridView.Rows.Add($Device.Name,(Set-ActiveStatusText $Device.ClientActiveStatus),$Device.ConvertToDateTime($Device.LastActiveTime),$Device.DeviceOS,$Device.SerialNumber,$Device.IMEI,$Device.ResourceID) | Out-Null
                }
            }
            Else {
                $ErrorProvider.SetError($TextBoxUser, "Please verify the username") 
                [Windows.Forms.MessageBox]::Show(“Please provide an user with a primary mobile device.”, “Mobile Device Verification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error) 
            }
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Please verify the connection with the specified site server.`n`n>>Failed to get the mobile devices for the specified user.”, “Mobile Device Verification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }
}

#Function to get lock state
Function Get-LockState {
    Param (
    [String]$MobileDeviceId,
    [String]$MobileDeviceName
    )
    Try {
        #Get the lock state of the device from WMI
        $LockState = Get-WmiObject -ComputerName $SiteServer -NameSpace root/SMS/site_$($SiteCode) -Class SMS_DeviceAction -Filter "Action='Lock' and ResourceID='$MobileDeviceId'" -ErrorAction Stop
        If ($LockState -ne $Null) {
            $LastUpdateTime = $LockState.ConvertToDateTime($LockState.LastUpdateTime)
            $State = Set-StateText $LockState.State
            [Windows.Forms.MessageBox]::Show(“Name: $MobileDeviceName`nResourceId: $MobileDeviceId`nLast Update Time: $LastUpdateTime`nStatus: $State”, “Lock State Information”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information) 
        }
        Else { 
            [Windows.Forms.MessageBox]::Show(“There is no LOCK state information available for the mobile device named $MobileDeviceName.”, “Lock State Information”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information) 
        }
    }
    Catch {
        [Windows.Forms.MessageBox]::Show(“Please verify the connection with the specified site server.`n`n>>Failed to get the LOCK state information for this mobile device.”, “Lock State Information”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
    }
}

#Function to get pin reset state
Function Get-PinResetState {
    Param (
    [String]$MobileDeviceId,
    [String]$MobileDeviceName
    )
    Try {
        #Get the pin reset state of the device from WMI
        $PinResetState = Get-WmiObject -ComputerName $SiteServer -NameSpace root/SMS/site_$($SiteCode) -Class SMS_DeviceAction -Filter "Action='PinReset' and ResourceID='$MobileDeviceId'" -ErrorAction Stop
        If ($PinResetState -ne $Null) {
            #Get a direct reference to the object to get a readable ResponseText
            $PinResetState = [wmi]$PinResetState.__PATH 
            $LastUpdateTime = $PinResetState.ConvertToDateTime($PinResetState.LastUpdateTime)
            $State = Set-StateText $PinResetState.State

            #Get the platform to set a correct PIN value
            $ResourceOS = $DataGridView.CurrentRow.Cells[3].Value
            If ($ResourceOS -notlike "*iOS*") {
                $Pin = $PinResetState.ResponseText
            }
            Else {
                $Pin = "N/A"
            }
            [Windows.Forms.MessageBox]::Show(“Name: $MobileDeviceName`nResourceId: $MobileDeviceId`nLast Update Time: $LastUpdateTime`nStatus: $State`nPin: $Pin”, “PinReset State Information”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information) 
        }
        Else { 
            [Windows.Forms.MessageBox]::Show(“There is no PINRESET state information available for the mobile device named $MobileDeviceName.”, “PinReset State Information”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information) 
        }
    }
    Catch {
        [Windows.Forms.MessageBox]::Show(“Please verify the connection with the specified site server.`n`n>>Failed to get the PINRESET state information for this mobile device.”, “PinReset State Information”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
    }
}

#Function to get sync request state
Function Get-SyncRequestState {
    Param (
    [String]$MobileDeviceId,
    [String]$MobileDeviceName
    )
    Try {
        #Get the sync request state of the device from WMI
        $SyncRequestState = Get-WmiObject -ComputerName $SiteServer -Namespace root/SMS/site_$($SiteCode) -Query "SELECT * FROM SMS_CM_RES_COLL_SMSDM001 WHERE ResourceId='$MobileDeviceId'" -ErrorAction Stop
        $State = $SyncRequestState.SyncNowStatus
        If ($State -ne $Null) {
            $State = Set-SyncStateText $State
            $LastUpdateTime = $SyncRequestState.ConvertToDateTime($SyncRequestState.LastSyncNowRequest)
            [Windows.Forms.MessageBox]::Show(“Name: $MobileDeviceName`nResourceId: $MobileDeviceId`nLast Sync Request Time: $LastUpdateTime`nSync Request State: $State”, “SyncRequest State Information”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
        }
        Else { 
            [Windows.Forms.MessageBox]::Show(“There is no SYNCREQUEST state information available for the mobile device named $MobileDeviceName.”, “SyncRequest State Information”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information) 
        }
    }
    Catch {
        [Windows.Forms.MessageBox]::Show(“Please verify the connection with the specified site server.`n`n>>Failed to get the SYNCREQUEST state information for this mobile device.”, “PinReset State Information”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
    }
}

#Function to switch the active state to something readable
function Set-ActiveStatusText {
    Param(
    [String]$ActiveStatus
    )
    switch ($ActiveStatus) {
        0 {$ActiveStatus = "Inactive"; break;}
        1 {$ActiveStatus = "Active"; break;}
    } 
    Return $ActiveStatus
}

#Function to switch the state to something readable
function Set-StateText {
    param(
    [String]$State
    )
    switch ($State) {
        1 {$State = "Pending"; break;}
        4 {$State = "Succeeded"; break;}
    } 
    Return $State
}

#Function to switch the sync state to something readable
function Set-SyncStateText {
    param(
    [String]$SyncState
    )
    switch ($SyncState) {
        1 {$SyncState = "Pending"; break;}
        2 {$SyncState = "Succeeded"; break;}
    } 
    Return $SyncState
}

#Function to wipe the mobile device
Function Wipe-MobileDevice {
    Param (
    [String]$MobileDeviceId,
    [String]$MobileDeviceName
    )
    $VerIfcation = [Windows.Forms.MessageBox]::Show(“Are you sure that you want to WIPE the mobile device named $($MobileDeviceName)?`n`nWARNING: This action will wipe (factory reset) the mobile device and will retire the mobile device from Configuration Manager.”, “Wipe Verification”, [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
    If ($VerIfcation -eq "Yes") { 
        Try {
            #Invoke the WIPE action on the device via WMI
            Invoke-WmiMethod -ComputerName $SiteServer -Namespace root/SMS/site_$($SiteCode) -Class SMS_DeviceMethods -Name RequestWipe -ArgumentList ($Null,$MobileDeviceId) -ErrorAction Stop
            [Windows.Forms.MessageBox]::Show(“The action to WIPE the mobile device named $MobileDeviceName is successful initiated.”, “Wipe Notification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Please verify the connection with the specified site server.`n`n>>Failed to WIPE the mobile device.”, “Wipe Notification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }
}

#Function to retire the mobile device
Function Retire-MobileDevice {
    Param (
    [String]$MobileDeviceId,
    [String]$MobileDeviceName
    )
    $Verifcation = [Windows.Forms.MessageBox]::Show(“Are you sure that you want to RETIRE the mobile device named $($MobileDeviceName)?`n`nWARNING: This action will wipe the company data from the mobile device and will retire the mobile device from Configuration Manager.”, “Retire Verification”, [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
    If ($Verifcation -eq "Yes") {
        Try {
            #Invoke the RETIRE action on the device via WMI
            Invoke-WmiMethod -ComputerName $SiteServer -Namespace root/SMS/site_$($SiteCode) -Class SMS_DeviceMethods -Name RequestRetire -ArgumentList ($MobileDeviceId) -ErrorAction Stop
            [Windows.Forms.MessageBox]::Show(“The action to RETIRE the mobile device named $MobileDeviceName is successful initiated.”, “Retire Notification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Please verify the connection with the specified site server.`n`n>>Failed to RETIRE the mobile device.”, “Retire Notification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }
}

#Function to request a device sync on the mobile device
Function Sync-MobileDevice {
 Param (
    [String]$MobileDeviceId,
    [String]$MobileDeviceName
    )
    $Verifcation = [Windows.Forms.MessageBox]::Show(“Are you sure that you want to SYNC the mobile device named $($MobileDeviceName)?”, “Sync Verification”, [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
    If ($Verifcation -eq "Yes") {
        Try {
            #Invoke the SYNC action on the device via WMI
            Invoke-WmiMethod -ComputerName $SiteServer -Namespace root/SMS/site_$($SiteCode) -Class SMS_DeviceMethods -Name SyncNow -ArgumentList ($MobileDeviceId) -ErrorAction Stop
            [Windows.Forms.MessageBox]::Show(“The action to SYNC the mobile device named $MobileDeviceName is successful initiated.”, “Sync Notification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Please verify the connection with the specified site server.`n`n>>Failed to SYNC the mobile device.”, “Sync Notification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }
}

#Function to reset pin or to lock the mobile device
Function InvokeAction-MobileDevice {
    Param (
    [String]$MobileDeviceId,
    [String]$MobileDeviceName,
    [ValidateSet("PinReset","Lock")]
    [String]$Action,
    [String]$Type
    )
    $Verifcation = [Windows.Forms.MessageBox]::Show(“Are you sure that you want to $($Action.ToUpper()) the mobile device named $($MobileDeviceName)?”, “$Action Verification”, [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
    If ($Verifcation -eq "Yes") { 
        Try {
            #Invoke the PINRESET or LOCK action on the device via WMI
            Invoke-WmiMethod -ComputerName $SiteServer -Namespace root/SMS/site_$($SiteCode) -Class SMS_DeviceAction -Name InvokeAction -ArgumentList ($Action,$MobileDeviceId,$Type) -ErrorAction Stop
            [Windows.Forms.MessageBox]::Show(“The action to $($Action.ToUpper()) the mobile device named $MobileDeviceName is successful initiated.”, “$Action Notification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Please verify the connection with the specified site server.`n`n>>Failed to $($Action.ToUpper()) the mobile device.”, “$Action Notification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }
}

#Function to execute the selected remote action
Function Execute-RemoteAction {
    Param (
    [String]$RemoteAction
    )

    If ($RemoteAction -eq "Sync Request") {
        Sync-MobileDevice $DataGridView.CurrentRow.Cells[6].Value $DataGridView.CurrentRow.Cells[0].Value
    }
    ElseIf ($RemoteAction -eq "Sync Request State") {
        Get-SyncRequestState $DataGridView.CurrentRow.Cells[6].Value $DataGridView.CurrentRow.Cells[0].Value
    }
    ElseIf ($RemoteAction -eq "Remote Lock") {
        InvokeAction-MobileDevice $DataGridView.CurrentRow.Cells[6].Value $DataGridView.CurrentRow.Cells[0].Value "Lock" 5
    }
    ElseIf ($RemoteAction -eq "Remote Lock State") {
        Get-LockState $DataGridView.CurrentRow.Cells[6].Value $DataGridView.CurrentRow.Cells[0].Value
    }
    ElseIf ($RemoteAction -eq "Reset Passcode") {
        InvokeAction-MobileDevice $DataGridView.CurrentRow.Cells[6].Value $DataGridView.CurrentRow.Cells[0].Value "PinReset" 5
    }
    ElseIf ($RemoteAction -eq "Reset Passcode State") {
        Get-PinResetState $DataGridView.CurrentRow.Cells[6].Value $DataGridView.CurrentRow.Cells[0].Value
    }
    Else {
        $ErrorProvider.SetError($ComboBoxAction, "Please verify the action") 
        [Windows.Forms.MessageBox]::Show(“Please select a valid remote action.”, “Mobile Device Action Verification”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error) 
    }
}

#TextBoxUser MouseHover event to show a tooltip about the required information
$TextBoxUser_MouseHover= {
    $Tip = "Enter the name of the user"
    $ToolTip.SetToolTip($This,$Tip)
}

#ComboBoxAction SelectedIndexChanged event to act based on selection changes
$ComboBoxAction_SelectedIndexChanged= {
    $ErrorProvider.SetError($ComboBoxAction,"")
}

#DataGridView CurrentCellChanged event to enable buttons and combobox items based on the selection
$DataGridView_CurrentCellChanged= {
    $ErrorProvider.SetError($ComboBoxAction,"")
    $ComboBoxAction.Items.Clear()
    $ComboBoxAction.Text = "<Select Remote Action>"
    $arrDeviceActions = @("Sync Request","Sync Request State")

    If ($DataGridView.CurrentRow -ne $Null) {
        $ButtonRetire.Enabled =  $True
        $ButtonExecute.Enabled = $True
        $ComboBoxAction.Enabled = $True

        #Get the platform to add a correct device actions
        $ResourceOS = $DataGridView.CurrentRow.Cells[3].Value
        If ($ResourceOS -notlike "*Windows 10*") {
            $arrDeviceActions = $arrDeviceActions += "Remote Lock","Remote Lock State","Reset Passcode","Reset Passcode State"
        }
        If (($ResourceOS -like "*Windows 10*" -or $ResourceOS -like "*iOS*" -or $ResourceOS -like "*Android*") -and $AllowWipe -eq $True) {
            $ButtonWipe.Enabled =  $True
        }
    }

    ForEach ($strDeviceAction in $arrDeviceActions) {
        $ComboBoxAction.Items.Add($strDeviceAction)
    }
}

#LinkLabelBlog event to open a browser session to my blog
$LinkLabelBlog_OpenLink= {
    [System.Diagnostics.Process]::start($LinkLabelBlog.text)
}

#LinkLabelTwitter OpenLink event to open a browser session to my twitter page
$LinkLabelTwitter_OpenLink= {
    [System.Diagnostics.Process]::start("http://twitter.com/pvanderwoude")
}

#Load Assemblies
[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

#Create ToolTip
$ToolTip = New-Object System.Windows.Forms.ToolTip

#Create ErrorProvider
$ErrorProvider = New-Object System.Windows.Forms.ErrorProvider
$ErrorProvider.BlinkStyle = "NeverBlink"

#Create Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(780,400)  
$Form.MinimumSize = New-Object System.Drawing.Size(780,400)
$Form.MaximumSize = New-Object System.Drawing.Size(780,400)
$Form.SizeGripStyle = "Hide"
$Form.StartPosition = "CenterScreen"
$Form.Text = "Remote Mobile Device Manager"
$Form.ControlBox = $False
$Form.TopMost = $True
$Form.Add_Shown({$Form.Activate(); $TextBoxUser.focus()})

#Create ButtonClose
$ButtonClose = New-Object System.Windows.Forms.Button
$ButtonClose.Location = New-Object System.Drawing.Size(590,295)
$ButtonClose.Size = New-Object System.Drawing.Size(150,23)
$ButtonClose.Text = "Close"
$ButtonClose.add_Click({$Form.Close()})

#Create ButtonExecute
$ButtonExecute = New-Object System.Windows.Forms.Button
$ButtonExecute.Location = New-Object System.Drawing.Size(590,25)
$ButtonExecute.Size = New-Object System.Drawing.Size(150,23)
$ButtonExecute.Text = "Execute Remote Action"
$ButtonExecute.Enabled = $False
$ButtonExecute.add_Click({Execute-RemoteAction $ComboBoxAction.SelectedItem})

#Create ButtonGet
$ButtonGet = New-Object System.Windows.Forms.Button
$ButtonGet.Location = New-Object System.Drawing.Size(170,25)
$ButtonGet.Size = New-Object System.Drawing.Size(150,22)
$ButtonGet.Text = "Get Mobile Devices"
$ButtonGet.add_Click({Get-MobileDevices $TextBoxUser.Text})

#Create ButtonRetire
$ButtonRetire = New-Object System.Windows.Forms.Button
$ButtonRetire.Location = New-Object System.Drawing.Size(20,295)
$ButtonRetire.Size = New-Object System.Drawing.Size(150,23)
$ButtonRetire.Text = "Retire"
$ButtonRetire.Enabled = $False
$ButtonRetire.add_Click({Retire-MobileDevice $DataGridView.CurrentRow.Cells[6].Value $DataGridView.CurrentRow.Cells[0].Value})

#Create ButtonWipe
$ButtonWipe = New-Object System.Windows.Forms.Button
$ButtonWipe.Location = New-Object System.Drawing.Size(170,295)
$ButtonWipe.Size = New-Object System.Drawing.Size(150,23)
$ButtonWipe.Text = "Wipe"
$ButtonWipe.Enabled = $False
$ButtonWipe.add_Click({Wipe-MobileDevice $DataGridView.CurrentRow.Cells[6].Value $DataGridView.CurrentRow.Cells[0].Value})

#Create ComboBoxAction
$ComboBoxAction = New-Object System.Windows.Forms.ComboBox
$ComboBoxAction.Location = New-Object System.Drawing.Size(440,26)
$ComboBoxAction.Size = New-Object System.Drawing.Size(150,25)
$ComboBoxAction.Text = "<Select Remote Action>"
$ComboBoxAction.Enabled = $False
$ComboBoxAction.add_SelectedIndexChanged($ComboBoxAction_SelectedIndexChanged)

#Create DataGriView
$DataGridView = New-Object System.Windows.Forms.DataGridView
$DataGridView.Location = New-Object System.Drawing.Size(20,90)
$DataGridView.Size = New-Object System.Drawing.Size(720,170)
$DataGridView.AllowUserToAddRows = $False
$DataGridView.AllowUserToDeleteRows = $False
$DataGridView.AllowUserToResizeRows = $False
$DataGridView.Anchor = "Top, Bottom, Left, Right"
$DataGridView.BackGroundColor = "White"
$DataGridView.ColumnCount = 7
$DataGridView.ColumnHeadersVisible = $True
$DataGridView.Columns[0].Name = "Name"
$DataGridView.Columns[0].MinimumWidth = 167
$DataGridView.Columns[0].Width = 167
$DataGridView.Columns[1].Name = "Client Activity"
$DataGridView.Columns[1].MinimumWidth = 90
$DataGridView.Columns[1].Width = 90
$DataGridView.Columns[2].Name = "Last Activity"
$DataGridView.Columns[2].MinimumWidth = 130
$DataGridView.Columns[2].Width = 130
$DataGridView.Columns[3].Name = "Operating System"
$DataGridView.Columns[3].MinimumWidth = 130
$DataGridView.Columns[3].Width = 130
$DataGridView.Columns[4].Name = "Serial Number"
$DataGridView.Columns[4].MinimumWidth = 100
$DataGridView.Columns[4].Width = 100
$DataGridView.Columns[5].Name = "IMEI"
$DataGridView.Columns[5].MinimumWidth = 100
$DataGridView.Columns[5].Width = 100
$DataGridView.Columns[6].Name = "Resource ID"
$DataGridView.Columns[6].Visible = $False
$DataGridView.ReadOnly = $True
$DataGridView.RowHeadersVisible = $False
$DataGridView.SelectionMode = "FullRowSelect"
$DataGridView.add_CurrentCellChanged($DataGridView_CurrentCellChanged)

#Create GroupBoxClose
$GroupBoxClose = New-Object System.Windows.Forms.GroupBox
$GroupBoxClose.Location = New-Object System.Drawing.Size(580,280) 
$GroupBoxClose.Size = New-Object System.Drawing.Size(170,50) 

#Create GroupBoxDevice
$GroupBoxDevice = New-Object System.Windows.Forms.GroupBox
$GroupBoxDevice.Location = New-Object System.Drawing.Size(10,70) 
$GroupBoxDevice.Size = New-Object System.Drawing.Size(740,200) 
$GroupBoxDevice.Text = "Mobile Devices"

#Create GroupBoxRemoteActions
$GroupBoxRemoteActions = New-Object System.Windows.Forms.GroupBox
$GroupBoxRemoteActions.Location = New-Object System.Drawing.Size(430,10) 
$GroupBoxRemoteActions.Size = New-Object System.Drawing.Size(320,50) 
$GroupBoxRemoteActions.Text = "Remote Actions"

#Create GroupBoxRetireWipe
$GroupBoxRetireWipe = New-Object System.Windows.Forms.GroupBox
$GroupBoxRetireWipe.Location = New-Object System.Drawing.Size(10,280) 
$GroupBoxRetireWipe.Size = New-Object System.Drawing.Size(320,50) 

#Create GroupBoxUser
$GroupBoxUser = New-Object System.Windows.Forms.GroupBox
$GroupBoxUser.Location = New-Object System.Drawing.Size(10,10) 
$GroupBoxUser.Size = New-Object System.Drawing.Size(320,50) 
$GroupBoxUser.Text = "User"

#Create LinkLabelBlog
$LinkLabelBlog = New-Object System.Windows.Forms.LinkLabel
$LinkLabelBlog.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$LinkLabelBlog.Location = New-Object System.Drawing.Size(20,340) 
$LinkLabelBlog.Size = New-Object System.Drawing.Size(142,23) 
$LinkLabelBlog.Text = "www.petervanderwoude.nl"
$LinkLabelBlog.add_Click($LinkLabelBlog_OpenLink)

#Create LinkLabelTwitter
$LinkLabelTwitter = New-Object System.Windows.Forms.LinkLabel
$LinkLabelTwitter.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$LinkLabelTwitter.Location = New-Object System.Drawing.Size(649,340) 
$LinkLabelTwitter.Size = New-Object System.Drawing.Size(90,23)
$linkLabelTwitter.Text = "@pvanderwoude"
$LinkLabelTwitter.add_Click($LinkLabelTwitter_OpenLink)

#Create TextBoxUser
$TextBoxUser = New-Object System.Windows.Forms.TextBox
$TextBoxUser.Location = New-Object System.Drawing.Size(20,26)
$TextBoxUser.Size = New-Object System.Drawing.Size(150,25)
$TextBoxUser.Text = "<Provide User>"
$TextBoxUser.add_MouseHover($TextBoxUser_MouseHover)

#Load form
Load-Form
