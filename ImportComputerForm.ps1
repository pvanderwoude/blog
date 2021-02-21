################################################################################################################################################
# Project: Import Computer Form
# Date: 2-5-2013 (Updated: 9-10-2013)
# By: Peter van der Woude
# Version: 0.9 Public
# Usage: PowerShell.exe -ExecutionPolicy ByPass .\ImportComputerForm.ps1 -Container <Container> -Collection <Collection> -SiteCode <SiteCode> -SiteServer <SiteServer>
################################################################################################################################################
[CmdletBinding()]

param (
[string]$Container,
[string]$Collection,
[string]$SiteCode,
[string]$SiteServer,
[string]$ApplicationVersion = "Import Computer Form v0.9p"
)

#Function to add the user names the combobox
function Set-UserNames {
    $CollectionId = (Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "Name='$Collection'").CollectionId
    $UserNames = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionId='$CollectionId'"
    foreach ($UserName in $UserNames) {
        $comboBox2.Items.add($UserName.SMSID)
    }
}

#Function to the collection names to the combobox
function Set-CollectionNames {
    $ContainerNodeId = (Get-WmiObject -Class SMS_ObjectContainerNode -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "Name='$Container'").ContainerNodeId
    $Ids = Get-WmiObject -Class SMS_ObjectContainerItem -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ContainerNodeID='$ContainerNodeID'"
    foreach ($Id in $Ids) {
        $CollectionId = $Id.InstanceKey
        $CollectionName = (Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'").Name
        $comboBox1.Items.add($CollectionName)
    }
}

#Function to import the new computer
function Import-NewComputer {
    param (
    [string]$ResourceName,
    [string]$MACAddress
    )
    Invoke-WmiMethod -Namespace root/SMS/site_$($SiteCode) -Class SMS_Site -Name ImportMachineEntry -ArgumentList @($null, $null, $null, $null, $null, $null, $MACAddress, $null, $ResourceName, $True, $null, $null) -ComputerName $SiteServer
    Invoke-WmiMethod -Path "root/SMS/site_$($SiteCode):SMS_Collection.CollectionId='SMS00001'" -Name RequestRefresh -ComputerName $SiteServer #Update the default All Systems collection.
}

#Function to add a direct membership rule
function Add-DirectMembershipRule {
     param (
    [string]$ResourceName,
    [string]$CollectionName
    )
    $NewDirectMembershipRule = ([WMIClass]"\\$SiteServer\root\SMS\Site_$($SiteCode):SMS_CollectionRuleDirect").CreateInstance()
    $NewDirectMembershipRule.ResourceClassName = "SMS_R_SYSTEM"
    $NewDirectMembershipRule.ResourceID = (Get-WmiObject -Class SMS_R_System -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "Name='$ResourceName'").ResourceId
    $NewDirectMembershipRule.Rulename = $ResourceName
 
    $DeploymentCollection = Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "Name='$CollectionName'"
    $DeploymentCollection.AddMemberShipRule($NewDirectMembershipRule)
}

#Function to add a User-Device Affinity
function Add-UserDeviceAffinity {
    param(
    [string]$ResourceName,
    [string]$UserName
    )
    $ResourceID = (Get-WmiObject -Class SMS_R_System -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "Name='$ResourceName'").ResourceId    
    Invoke-WmiMethod -Namespace root/SMS/site_$($SiteCode) -Class SMS_UserMachineRelationship -Name CreateRelationship -ArgumentList @($ResourceID, 2, 1, $UserName) -ComputerName $SiteServer
}

#Function to add a machine variable
function Add-MachineVariables {
	param (
    [string]$ResourceName,
    [string]$VariableName,
    [string]$VariableValue
    )
	
	$ResourceID = (Get-WmiObject -Class SMS_R_System -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "Name='$ResourceName'").ResourceId
	
	$MachineSettings = Get-WMIObject -computername $SiteServer -Namespace "root\SMS\site_$($siteCode)" -class "SMS_MachineSettings" -Filter "ResourceID='$ResourceID'"
	If (!$MachineSettings) {
		$NewMachineSettingsInstance = $([wmiclass]"\\$SiteServer\Root\SMS\Site_$($SiteCode):SMS_MachineSettings").CreateInstance()
		$NewMachineSettingsInstance.ResourceID = $ResourceID
		$NewMachineSettingsInstance.SourceSite = $SiteCode
		$NewMachineSettingsInstance.LocaleID = 1033
		$NewMachineSettingsInstance.psbase
		$NewMachineSettingsInstance.psbase.Put()
		$MachineSettings += $NewMachineSettingsInstance
	}

	$MachineSettings.psbase.Get()
	$MachineVariable = $([wmiclass]"\\$SiteServer\Root\SMS\Site_$($SiteCode):SMS_MachineVariable").CreateInstance()
	$MachineVariable.Name = $VariableName
	$MachineVariable.Value = $VariableValue
	$MachineVariable.IsMasked = [Int]$($MachineVariable.IsMasked)
	[System.Management.ManagementBaseObject[]]$MachineVariables += $MachineVariable
	$MachineSettings.MachineVariables = $MachineVariables
	$MachineSettings.psbase.Put()
}

#Generated Form Function
function GenerateForm {
    ########################################################################
    # Code Generated By: SAPIEN Technologies PrimalForms (Community Edition) v1.0.10.0
    # Generated On: 25-4-2013 21:40
    # Generated By: Peter van der Woude
    ########################################################################

    [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null

    $button1 = New-Object System.Windows.Forms.Button
    $button2 = New-Object System.Windows.Forms.Button
    $checkBox1 = New-Object System.Windows.Forms.CheckBox
    $checkBox2 = New-Object System.Windows.Forms.CheckBox
    $comboBox1 = New-Object System.Windows.Forms.ComboBox
    $comboBox2 = New-Object System.Windows.Forms.ComboBox
    $errorProvider1 = New-Object System.Windows.Forms.ErrorProvider
    $form1 = New-Object System.Windows.Forms.Form
    $label1 = New-Object System.Windows.Forms.Label
    $label2 = New-Object System.Windows.Forms.Label
    $label3 = New-Object System.Windows.Forms.Label
    $label4 = New-Object System.Windows.Forms.Label
    $label5 = New-Object System.Windows.Forms.Label
    $label6 = New-Object System.Windows.Forms.Label
    $label7 = New-Object System.Windows.Forms.Label
    $label8 = New-Object System.Windows.Forms.Label
    $linkLabel1 = New-Object System.Windows.Forms.LinkLabel
    $linkLabel2 = New-Object System.Windows.Forms.LinkLabel
    $maskedTextBox1 = New-Object System.Windows.Forms.MaskedTextBox
    $textBox1 = New-Object System.Windows.Forms.TextBox
    $textBox2 = New-Object System.Windows.Forms.TextBox
    $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

    $button1_OnClick= {
        Try {
            $errorProvider1.Clear()
            $errorProvider1.BlinkStyle = "NeverBlink"

            #Import the new computer
            if($textBox1.Text.Length -eq 0 -or $maskedTextBox1.Text.Length -lt 17 -or $comboBox1.SelectedItem -eq $null -or ($comboBox2.SelectedItem -eq $null -and $checkbox1.Checked)) {
                if($textBox1.Text.Length -eq 0) {
                    $errorProvider1.SetError($textBox1, "Please enter a valid computer name")           
                }
                if ($maskedTextBox1.Text.Length -lt 17) {
                    $errorProvider1.SetError($maskedTextBox1, "Please enter a valid MAC address")
                }
                if ($comboBox1.SelectedItem -eq $null) {
                    $errorProvider1.SetError($comboBox1, "Please select a valid collection")
                }
                if ($comboBox2.SelectedItem -eq $null -and $checkbox1.Checked) {
                    $errorProvider1.SetError($comboBox2, "Please select a valid user name")
                }
                if ($textBox1.Text.Length -eq 0 -and $checkbox2.Checked) {
                    $errorProvider1.SetError($textBox2, "Please enter a valid inventory number")
                }
            }
            else {
                $ResourceName = $textBox1.Text.ToUpper()
                $MACAddress = $maskedTextBox1.Text.ToUpper()
                $CollectionName = $comboBox1.SelectedItem
                Import-NewComputer $ResourceName $MACAddress
                Add-DirectMembershipRule $ResourceName $CollectionName
            
                if($checkbox1.Checked) {
                    $UserName = $comboBox2.SelectedItem
                    Add-UserDeviceAffinity $ResourceName $UserName
                    [Windows.Forms.MessageBox]::Show(“Successfully imported $ResourceName, with MAC Address '$MACAddress' and Primary User '$UserName', to Collection '$CollectionName'”, “$ApplicationVersion”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
                }
                else {
                    [Windows.Forms.MessageBox]::Show(“Successfully imported $ResourceName, with MAC Address $MACAddress, to collection $CollectionName”, “$ApplicationVersion”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
                }

                if($checkbox2.Checked) {
                    $InventoryNumber = $textBox2.Text
                    Add-MachineVariables $ResourceName "InventoryNumber" $InventoryNumber
                    Write-Host $InventoryNumber
                }

                #Reset the form
                $textbox1.Text = ""
                $maskedTextBox1.Text = ""
                $comboBox1.Text = "Select Collection:"
                $comboBox2.Text = "Select Prmary User:"
            }
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“There was an error importing $ResourceName, with MAC Address $MACAddress, to collection $CollectionName”, “$ApplicationVersion”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }

    $button2_OnClick= {
	    $form1.Close()
    }

    $checkbox1_OnStateChanged= {
        if($checkbox1.Checked) {
		    $comboBox2.Enabled = $True
            $label5.Enabled = $True
            $button1.Text = "Import and Add Primary User"
        }
        else {
            $comboBox2.Enabled = $False
            $label5.Enabled = $False
            $button1.Text = "Import"
        }
    }

    $checkbox2_OnStateChanged= {
        if($checkbox2.Checked) {
		    $textBox2.Enabled = $True
            $label6.Enabled = $True
        }
        else {
            $textBox2.Enabled = $False
            $label6.Enabled = $False
        }
    }

    $OnLoadForm_UpdateGrid= {
        Set-CollectionNames
        Set-UserNames
    }

    $OnLoadForm_StateCorrection= {
	    $form1.WindowState = $InitialFormWindowState
    }
    
    #Create form1
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 242
    $System_Drawing_Size.Width = 550
    $form1.ClientSize = $System_Drawing_Size
    $form1.DataBindings.DefaultDataSourceUpdateMode = 0
    $form1.Name = "form1"
    $form1.Text = "$ApplicationVersion - P.T. van der Woude"
    $form1.add_Load($handler_form1_Load)

    #Create button1
    $button1.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 15
    $System_Drawing_Point.Y = 183
    $button1.Location = $System_Drawing_Point
    $button1.Name = "button1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 250
    $button1.Size = $System_Drawing_Size
    $button1.TabIndex = 4
    $button1.Text = "Import"
    $button1.UseVisualStyleBackColor = $True
    $button1.add_Click($button1_OnClick)
    $form1.Controls.Add($button1)

    #Create button2
    $button2.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 285
    $System_Drawing_Point.Y = 183
    $button2.Location = $System_Drawing_Point
    $button2.Name = "button2"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 250
    $button2.Size = $System_Drawing_Size
    $button2.TabIndex = 5
    $button2.Text = "Close"
    $button2.UseVisualStyleBackColor = $True
    $button2.add_Click($button2_OnClick)
    $form1.Controls.Add($button2)

    #Create checkbox1
    $checkBox1.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 15
    $System_Drawing_Point.Y = 130
    $checkBox1.Location = $System_Drawing_Point
    $checkBox1.Name = "checkBox1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 21
    $System_Drawing_Size.Width = 21
    $checkBox1.Size = $System_Drawing_Size
    $checkBox1.TabIndex = 3
    $checkBox1.UseVisualStyleBackColor = $True
    $checkbox1.Enabled = $True
    $checkbox1.Add_CheckStateChanged($checkbox1_OnStateChanged)
    $form1.Controls.Add($checkBox1)

    #Create checkbox2
    $checkBox2.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 15
    $System_Drawing_Point.Y = 156
    $checkBox2.Location = $System_Drawing_Point
    $checkBox2.Name = "checkBox1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 21
    $System_Drawing_Size.Width = 21
    $checkBox2.Size = $System_Drawing_Size
    $checkBox2.TabIndex = 3
    $checkBox2.UseVisualStyleBackColor = $True
    $checkbox2.Enabled = $True
    $checkbox2.Add_CheckStateChanged($checkbox2_OnStateChanged)
    $form1.Controls.Add($checkBox2)

    #Create comboBox1
    $comboBox1.DataBindings.DefaultDataSourceUpdateMode = 0
    $comboBox1.FormattingEnabled = $True
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 285
    $System_Drawing_Point.Y = 104
    $comboBox1.Location = $System_Drawing_Point
    $comboBox1.Name = "comboBox1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 21
    $System_Drawing_Size.Width = 250
    $comboBox1.Size = $System_Drawing_Size
    $comboBox1.TabIndex = 0
    $comboBox1.Text = "Select Collection:"
    $form1.Controls.Add($comboBox1)

    #Create comboBox2
    $comboBox2.DataBindings.DefaultDataSourceUpdateMode = 0
    $comboBox2.FormattingEnabled = $True
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 285
    $System_Drawing_Point.Y = 130
    $comboBox2.Location = $System_Drawing_Point
    $comboBox2.Name = "comboBox2"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 21
    $System_Drawing_Size.Width = 250
    $comboBox2.Size = $System_Drawing_Size
    $comboBox2.TabIndex = 0
    $comboBox2.Text = "Select Primary User:"
    $comboBox2.Enabled = $False
    $form1.Controls.Add($comboBox2)

    #Create label1
    $label1.DataBindings.DefaultDataSourceUpdateMode = 0
    $label1.Font = New-Object System.Drawing.Font("Tahoma",14.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 15
    $System_Drawing_Point.Y = 13
    $label1.Location = $System_Drawing_Point
    $label1.Name = "label1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 266
    $label1.Size = $System_Drawing_Size
    $label1.TabIndex = 3
    $label1.Text = "Import Computer Information"
    $form1.Controls.Add($label1)

    #Create label2
    $label2.DataBindings.DefaultDataSourceUpdateMode = 0
    $label2.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 15
    $System_Drawing_Point.Y = 52
    $label2.Location = $System_Drawing_Point
    $label2.Name = "label2"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 20
    $System_Drawing_Size.Width = 100
    $label2.Size = $System_Drawing_Size
    $label2.TabIndex = 6
    $label2.Text = "Computer name:"
    $form1.Controls.Add($label2)

    #Create label3
    $label3.DataBindings.DefaultDataSourceUpdateMode = 0
    $label3.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 15
    $System_Drawing_Point.Y = 78
    $label3.Location = $System_Drawing_Point
    $label3.Name = "label3"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 20
    $System_Drawing_Size.Width = 100
    $label3.Size = $System_Drawing_Size
    $label3.TabIndex = 7
    $label3.Text = "MAC address:"
    $form1.Controls.Add($label3)

    #Create label4
    $label4.DataBindings.DefaultDataSourceUpdateMode = 0
    $label4.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 15
    $System_Drawing_Point.Y = 104
    $label4.Location = $System_Drawing_Point
    $label4.Name = "label4"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 21
    $System_Drawing_Size.Width = 150
    $label4.Size = $System_Drawing_Size
    $label4.TabIndex = 8
    $label4.Text = "OS Deployment Collection:"
    $form1.Controls.Add($label4)

    #Create label5
    $label5.DataBindings.DefaultDataSourceUpdateMode = 0
    $label5.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 34
    $System_Drawing_Point.Y = 130
    $label5.Location = $System_Drawing_Point
    $label5.Name = "label5"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 21
    $System_Drawing_Size.Width = 150
    $label5.Size = $System_Drawing_Size
    $label5.TabIndex = 8
    $label5.Text = "Primary User:"
    $label5.Enabled = $False
    $form1.Controls.Add($label5)

    #Create label6
    $label6.DataBindings.DefaultDataSourceUpdateMode = 0
    $label6.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 34
    $System_Drawing_Point.Y = 156
    $label6.Location = $System_Drawing_Point
    $label6.Name = "label6"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 21
    $System_Drawing_Size.Width = 150
    $label6.Size = $System_Drawing_Size
    $label6.TabIndex = 8
    $label6.Text = "Inventory Number:"
    $label6.Enabled = $False
    $form1.Controls.Add($label6)

    #Create label7
    $label7.DataBindings.DefaultDataSourceUpdateMode = 0
    $label7.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 15
    $System_Drawing_Point.Y = 217
    $label7.Location = $System_Drawing_Point
    $label7.Name = "label7"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 48
    $label7.Size = $System_Drawing_Size
    $label7.TabIndex = 1
    $label7.Text = "My blog:"
    $form1.Controls.Add($label7)
        
    #Create label8
    $label8.DataBindings.DefaultDataSourceUpdateMode = 0
    $label8.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 335
    $System_Drawing_Point.Y = 217
    $label8.Location = $System_Drawing_Point
    $label8.Name = "label8"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 111
    $label8.Size = $System_Drawing_Size
    $label8.TabIndex = 2
    $label8.Text = "Follow me on twitter:"
    $form1.Controls.Add($label8)

    #Create linkLabel1
    $linkLabel1.DataBindings.DefaultDataSourceUpdateMode = 0
    $linkLabel1.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 63
    $System_Drawing_Point.Y = 217
    $linkLabel1.Location = $System_Drawing_Point
    $linkLabel1.Name = "linkLabel1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 142
    $linkLabel1.Size = $System_Drawing_Size
    $linkLabel1.TabIndex = 0
    $linkLabel1.TabStop = $True
    $linkLabel1.Text = "www.petervanderwoude.nl"
    $linkLabel1.add_click($linkLabel1_OpenLink)
    $form1.Controls.Add($linkLabel1)

    #Create linkLabel2
    $linkLabel2.DataBindings.DefaultDataSourceUpdateMode = 0
    $linkLabel2.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 444
    $System_Drawing_Point.Y = 217
    $linkLabel2.Location = $System_Drawing_Point
    $linkLabel2.Name = "linkLabel2"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 90
    $linkLabel2.Size = $System_Drawing_Size
    $linkLabel2.TabIndex = 3
    $linkLabel2.TabStop = $True
    $linkLabel2.Text = "@pvanderwoude"
    $linkLabel1.add_click($linkLabel2_OpenLink)
    $form1.Controls.Add($linkLabel2)

    #Create maskedTextBox1
    $maskedTextBox1.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 285
    $System_Drawing_Point.Y = 78
    $maskedTextBox1.Location = $System_Drawing_Point
    $maskedTextBox1.Name = "maskedTextBox1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 20
    $System_Drawing_Size.Width = 250
    $maskedTextBox1.Size = $System_Drawing_Size
    $maskedTextBox1.TabIndex = 2
    $maskedTextBox1.Mask = "CC:CC:CC:CC:CC:CC"
    $form1.Controls.Add($maskedTextBox1)

    #Create textBox1
    $textBox1.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 285
    $System_Drawing_Point.Y = 52
    $textBox1.Location = $System_Drawing_Point
    $textBox1.Name = "textBox1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 20
    $System_Drawing_Size.Width = 250
    $textBox1.Size = $System_Drawing_Size
    $textBox1.TabIndex = 1
    $form1.Controls.Add($textBox1)

    #Create textBox2
    $textBox2.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 285
    $System_Drawing_Point.Y = 156
    $textBox2.Location = $System_Drawing_Point
    $textBox2.Name = "textBox2"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 20
    $System_Drawing_Size.Width = 250
    $textBox2.Size = $System_Drawing_Size
    $textBox2.TabIndex = 1
    $textBox2.Enabled = $False
    $form1.Controls.Add($textBox2)

    $InitialFormWindowState = $form1.WindowState

    $form1.add_Load($OnLoadForm_UpdateGrid)
    $form1.ShowDialog()| Out-Null
}
GenerateForm
