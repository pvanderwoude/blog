###################################################################################################################################################################
# Project: Application Approval Manager
# Date: 2-5-2013
# By: Peter van der Woude
# Version: 0.8 Public
# Usage: PowerShell.exe -ExecutionPolicy ByPass .\Approval-Manager.ps1 -CollectionID <CollectionID> -SiteCode <SiteCode> -SiteServer <SiteServer> -EnableAlert
###################################################################################################################################################################
[CmdletBinding()]

param (
[string]$CollectionID,
[string]$SiteCode,
[string]$SiteServer,
[switch]$EnableAlert,
[string]$ApplicationVersion = "Approval Manager v0.8p"
)

#Function to get the users from a specific collection
function Get-UsersFromCM {
    $Users = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.CollectionId -eq $CollectionID} | Select-Object SMSID
    foreach ($User in $Users) {
        $comboBox1.Items.add($User.SMSID)
    }
}

#Function to display the approval requests in a form        
function Show-ApprovalRequest {
    $User = $comboBox1.SelectedItem
    if($checkbox1.Checked) {
        $Requests = Get-WmiObject -Class SMS_UserApplicationRequest -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.User -eq $User} | Where-Object -FilterScript {$_.CurrentState -eq 1} | Select-Object Application,CurrentState,User
	}
	else {
        $Requests = Get-WmiObject -Class SMS_UserApplicationRequest -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.User -eq $User} | Select-Object Application,CurrentState,User
	}

    $Array = New-Object System.Collections.ArrayList
    if ($Requests -eq $null) {
        $dataGridView1.DataSource = $null
	    $form1.refresh()
        [Windows.Forms.MessageBox]::Show(“There are no requests for this user”, “$ApplicationVersion”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
    }
    else {
        for ($i=0; $i -lt @($Requests).Count; $i++) {
	        if ($Requests[$i].CurrentState -eq 1) {
                $Requests[$i].CurrentState = "Pending Approval"
                $checkbox1.Enabled = $true
            }
            elseif ($Requests[$i].CurrentState -eq 2) {
                $Requests[$i].CurrentState = "Cancelled"
            }
            elseif ($Requests[$i].CurrentState -eq 3) {
                $Requests[$i].CurrentState = "Denied"
            }
            elseif ($Requests[$i].CurrentState -eq 4) {
                $Requests[$i].CurrentState = "Approved"
            }
        }
        foreach ($Request in $Requests) {
            $Array.Add($Request)
        }
	    $dataGridView1.DataSource = $Array
        for ($i=0; $i -lt $dataGridView1.ColumnCount; $i++) {
	        $dataGridView1.Columns[$i].width = 161
        }
        $form1.refresh()
    }
}

#Function to display the pending approval requests in a popup
function Get-PendingApprovalRequest {
    $Array = New-Object System.Collections.ArrayList
    $Users = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.CollectionId -eq $CollectionID} | Select-Object SMSID
    foreach ($User in $Users) {
        $Requests = Get-WmiObject -Class SMS_UserApplicationRequest -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.User -eq $User.SMSID} | Where-Object -FilterScript {$_.CurrentState -eq 1} | Select-Object Application,CurrentState,User
        foreach ($Request in $Requests) {
            $Array.Add($Request)
        }
    }
    if ($Array.Count -le 0) {
        [Windows.Forms.MessageBox]::Show(“There are no requests pending approval”, “$ApplicationVersion”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
    }
    else {
        $TempPendingUsers = ""
        $PendingUsers = "The following users have pending approval requests: `n"
        for ($i=0; $i -lt $Array.Count; $i++) {
            if ($TempPendingUsers -ne $Array[$i].User) {
                $TempPendingUsers = $Array[$i].User
                $PendingUsers = "$PendingUsers $TempPendingUsers `n"
            }
        }
        [Windows.Forms.MessageBox]::Show(“$PendingUsers", “$ApplicationVersion”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
    }
}

#Function to approve/deny the approval request
function Set-ApprovalRequest {
    param (
    [string]$Action
    )
    $User = $comboBox1.SelectedItem
    $Index = $dataGridView1.CurrentCell.RowIndex
    if($checkbox1.Checked) {
        $Requests = Get-WmiObject -Class SMS_UserApplicationRequest -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.User -eq $User} | Where-Object -FilterScript {$_.CurrentState -eq 1} | Select-Object Application,CurrentState,User
	}
	else {
        $Requests = Get-WmiObject -Class SMS_UserApplicationRequest -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.User -eq $User} | Select-Object Application,CurrentState,User
	}

	if (($ApplName=$Requests[$Index].Application)) {
        	if ($Requests[$Index].CurrentState -eq 3) {
                [Windows.Forms.MessageBox]::Show(“This request is already denied”, “$ApplicationVersion”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
            }
            elseif ($Requests[$Index].CurrentState -eq 2) {
                [Windows.Forms.MessageBox]::Show(“This request is already cancelled”, “$ApplicationVersion”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
            }
            elseif ($Requests[$Index].CurrentState -eq 4) {
                [Windows.Forms.MessageBox]::Show(“This request is already approved”, “$ApplicationVersion”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
            }
            else {
                If ($Action -eq "Approve") {
                    $ApplAppr = Get-WmiObject -Class SMS_UserApplicationRequest -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.User -eq $User} | Where-Object -FilterScript {$_.Application -eq $ApplName}
                    $ApplAppr.Approve('Request approved')
                }
                else {
                    $ApplAppr = Get-WmiObject -Class SMS_UserApplicationRequest -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object -FilterScript {$_.User -eq $User} | Where-Object -FilterScript {$_.Application -eq $ApplName}
                    $ApplAppr.Deny('Request denied')
                }                   
            }
	}
}

#Generated Form Function
function GenerateForm {
    ########################################################################
    # Code Generated By: SAPIEN Technologies PrimalForms (Community Edition) v1.0.10.0
    # Generated On: 5-3-2013 13:04
    # Generated By: Peter van der Woude
    ########################################################################

    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

    $form1 = New-Object System.Windows.Forms.Form
    $button1 = New-Object System.Windows.Forms.Button
    $button2 = New-Object System.Windows.Forms.Button
    $button3 = New-Object System.Windows.Forms.Button
    $checkBox1 = New-Object System.Windows.Forms.CheckBox
    $comboBox1 = New-Object System.Windows.Forms.ComboBox
    $dataGridView1 = New-Object System.Windows.Forms.DataGridView
    $label1 = New-Object System.Windows.Forms.Label
    $label2 = New-Object System.Windows.Forms.Label
    $label3 = New-Object System.Windows.Forms.Label
    $linkLabel1 = New-Object System.Windows.Forms.LinkLabel
    $linkLabel2 = New-Object System.Windows.Forms.LinkLabel
    $timer1 = New-Object System.Windows.Forms.Timer
    $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

    $button1_OnClick= {
        $Action = "Approve"
        Set-ApprovalRequest $Action 
        Show-ApprovalRequest
    }

    $button2_OnClick= {
        $timer1.Enabled = $false
	    $form1.Close()
    }

    $button3_OnClick= {
        $Action = "Deny"
        Set-ApprovalRequest $Action
        Show-ApprovalRequest
    }

    $checkbox1_OnStateChanged= {
		Show-ApprovalRequest
    }

    $comboBox1_OnChange= {
        $checkbox1.Checked = $false
        $checkbox1.Enabled = $false
        Show-ApprovalRequest
    }

    $linkLabel1_OpenLink= {
        [system.Diagnostics.Process]::start($linkLabel1.text)
    }

    $linkLabel2_OpenLink= {
        [system.Diagnostics.Process]::start("http://twitter.com/pvanderwoude")
    }

    $timer1_OnTick= {
        $timer1.Enabled = $false
        Get-PendingApprovalRequest 
        $timer1.Enabled = $true
    }

    $OnLoadForm_UpdateGrid= {
        Get-UsersFromCM
    }

    #Create form1
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 554
    $System_Drawing_Size.Width = 554
    $form1.ClientSize = $System_Drawing_Size
    $form1.DataBindings.DefaultDataSourceUpdateMode = 0
    $form1.Name = "form1"
    $form1.Text = "$ApplicationVersion - P.T. van der Woude"

    #Create button1
    $button1.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 496
    $button1.Location = $System_Drawing_Point
    $button1.Name = "button1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 150
    $button1.Size = $System_Drawing_Size
    $button1.TabIndex = 0
    $button1.Text = "Approve"
    $button1.UseVisualStyleBackColor = $True
    $button1.add_Click($button1_OnClick)
    $form1.Controls.Add($button1)

    #Create button2
    $button2.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 392
    $System_Drawing_Point.Y = 496
    $button2.Location = $System_Drawing_Point
    $button2.Name = "button2"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 150
    $button2.Size = $System_Drawing_Size
    $button2.TabIndex = 1
    $button2.Text = "Close"
    $button2.UseVisualStyleBackColor = $True
    $button2.add_Click($button2_OnClick)
    $form1.Controls.Add($button2)

    #Create button3
    $button3.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 205
    $System_Drawing_Point.Y = 496
    $button3.Location = $System_Drawing_Point
    $button3.Name = "button3"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 150
    $button3.Size = $System_Drawing_Size
    $button3.TabIndex = 2
    $button3.Text = "Deny"
    $button3.UseVisualStyleBackColor = $True
    $button3.add_Click($button3_OnClick)
    $form1.Controls.Add($button3)

    #Create checkbox1
    $checkBox1.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 39
    $checkBox1.Location = $System_Drawing_Point
    $checkBox1.Name = "checkBox1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 24
    $System_Drawing_Size.Width = 253
    $checkBox1.Size = $System_Drawing_Size
    $checkBox1.TabIndex = 3
    $checkBox1.Text = "Show only applications waiting for approval"
    $checkBox1.UseVisualStyleBackColor = $True
    $checkbox1.Enabled = $false
    $checkbox1.Add_CheckStateChanged($checkbox1_OnStateChanged)
    $form1.Controls.Add($checkBox1)

    #Create combobox1
    $comboBox1.DataBindings.DefaultDataSourceUpdateMode = 0
    $comboBox1.FormattingEnabled = $True
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 366
    $System_Drawing_Point.Y = 39
    $comboBox1.Location = $System_Drawing_Point
    $comboBox1.Name = "comboBox1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 17
    $System_Drawing_Size.Width = 175
    $comboBox1.Size = $System_Drawing_Size
    $comboBox1.Text = "Select user:"
    $comboBox1.TabIndex = 0
    $comboBox1.Add_SelectedIndexChanged($comboBox1_OnChange)
    $form1.Controls.Add($comboBox1)

    #Create $dataGridView1
    $dataGridView1.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 69
    $dataGridView1.Location = $System_Drawing_Point
    $dataGridView1.MultiSelect = $false
    $dataGridView1.Name = "dataGridView1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 419
    $System_Drawing_Size.Width = 528
    $dataGridView1.ReadOnly = $True
    $dataGridView1.SelectionMode = 'FullRowSelect'
    $dataGridView1.Size = $System_Drawing_Size
    $dataGridView1.TabIndex = 2
    $form1.Controls.Add($dataGridView1)
    
    #Create label1
    $label1.DataBindings.DefaultDataSourceUpdateMode = 0
    $label1.Font = New-Object System.Drawing.Font("Tahoma",14.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 13
    $label1.Location = $System_Drawing_Point
    $label1.Name = "label1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 253
    $label1.Size = $System_Drawing_Size
    $label1.TabIndex = 5
    $label1.Text = "Approval Manager"
    $form1.Controls.Add($label1)

    #Create label2
    $label2.DataBindings.DefaultDataSourceUpdateMode = 0
    $label2.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 12
    $System_Drawing_Point.Y = 529
    $label2.Location = $System_Drawing_Point
    $label2.Name = "label2"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 48
    $label2.Size = $System_Drawing_Size
    $label2.TabIndex = 1
    $label2.Text = "My blog:"
    $form1.Controls.Add($label2)
        
    #Create label3
    $label3.DataBindings.DefaultDataSourceUpdateMode = 0
    $label3.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 335
    $System_Drawing_Point.Y = 529
    $label3.Location = $System_Drawing_Point
    $label3.Name = "label3"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 117
    $label3.Size = $System_Drawing_Size
    $label3.TabIndex = 2
    $label3.Text = "Follow me on twitter:"
    $form1.Controls.Add($label3)

    #Create linkLabel1
    $linkLabel1.DataBindings.DefaultDataSourceUpdateMode = 0
    $linkLabel1.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 63
    $System_Drawing_Point.Y = 529
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
    $System_Drawing_Point.X = 449
    $System_Drawing_Point.Y = 529
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

    #Create timer1 (and enable when the EnableAlert parameter is supplied)
    $timer1.Interval = 3600000 #Current interval is set to 3600 minutes (=1 hour)
    $timer1.add_Tick($timer1_OnTick)
    if ($EnableAlert -eq $True)
    {
        $timer1.Enabled = $true
    }

    $InitialFormWindowState = $form1.WindowState

    $form1.add_Load($OnLoadForm_UpdateGrid)
    $form1.ShowDialog()| Out-Null
}
GenerateForm
