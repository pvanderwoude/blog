<#
.SYNOPSIS
    Shows the information about the deployment packages and Software update groups of which asoftware update is a member.
.DESCRIPTION
    This script creates a form that requires a article id, a software update group, or a deployment package as input. Based on the input it will show information about 
    the specific software update, or all the software updates in a software update group, or a deployment package. When used for a software update it will show in which
    software update group and deployment package it exists. When used for a software update group it will show in which deployment packages those updates also exists. 
    When used for a deployment package it will show in which software update groups those updates exist.
.PARAMETER SiteCode
    The site code of the primary site.
.PARAMETER SiteServer
    The site server of the primary site.
.NOTES     
    Author: Peter van der Woude - pvanderwoude@hotmail.com  
    Date published: 19-06-2014  
.LINK   
    http://www.petervanderwoude.nl
.EXAMPLE
    Get-SoftwareUpdateInformation.ps1 -SiteCode PCP -SiteServer CLDSRV02  
#>
[CmdletBinding()]

param (
[string]$SiteCode,
[string]$SiteServer
) 

#Function to load the form
function Load-Form {
    $Form1.Controls.Add($Button1)
    $Form1.Controls.Add($Button2)
    $Form1.Controls.Add($ComboBox1)
    $Form1.Controls.Add($DataGridView1)
    $Form1.Controls.Add($DataGridView2)
    $Form1.Controls.Add($Label1)
    $Form1.Controls.Add($Label2)
    $Form1.Controls.Add($LinkLabel1)
    $Form1.Controls.Add($LinkLabel2)
    $Form1.Controls.Add($TextBox1)
    $Form1.Controls.Add($GroupBox1)
    $Form1.Controls.Add($GroupBox2)
    $Form1.Controls.Add($GroupBox3)
    $ComboBox1.Items.add("Software Update")
    $ComboBox1.Items.add("Deployment Package")
    $ComboBox1.Items.add("Software Update Group")
	$Form1.ShowDialog()
}

#Function to get the software update group membership of updates
function Get-SoftwareUpdateGroupMembership {
    param (
    [array]$Updates
    )  
    foreach ($Update in $Updates) {
        $UpdateCIID = $Update.CI_ID
        $UpdateGroupNames = (Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT DISTINCT ALI.* from SMS_AuthorizationList ALI `
            JOIN SMS_CIRelation CIR on ALI.CI_ID = CIR.fromCIID WHERE CIR.ToCIID='$UpdateCIID'").LocalizedDisplayName
        if ($UpdateGroupNames -ne $null) {
            foreach ($Name in $UpdateGroupNames) {
                $UpdateGroupName = $Name
                $DataGridView1.Rows.Add($UpdateGroupName,$Update.ArticleId,$Update.LocalizedDisplayName) | Out-Null
            }
        }
        else {
            $UpdateGroupName = "<NoSoftwareUpdateGroup>"
            $DataGridView1.Rows.Add($UpdateGroupName,$Update.ArticleId,$Update.LocalizedDisplayName) | Out-Null
        }        
    }
}

#Function to get the deployment package membership of updates
function Get-DeploymentPackageMembership {
    param (
    [array]$Updates
    )
    foreach ($Update in $Updates) {
        $UpdateCIID = $Update.CI_ID
        $UpdatePackageNames = (Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT DISTINCT sup.* FROM SMS_SoftwareUpdatesPackage AS sup `
            JOIN SMS_PackageToContent AS pc ON sup.PackageID=pc.PackageID JOIN SMS_CIToContent AS cc ON pc.ContentID = cc.ContentID WHERE CC.CI_ID='$UpdateCIID'").Name
        if ($UpdatePackageNames -ne $null) {
            foreach ($UpdatePackageName in $UpdatePackageNames) {
                $DataGridView2.Rows.Add($UpdatePackageName,$Update.ArticleId,$Update.LocalizedDisplayName) | Out-Null
            }
        }
        else {
            $UpdatePackageName = "<NoDeploymentPackage>"
            $DataGridView2.Rows.Add($UpdatePackageName,$Update.ArticleId,$Update.LocalizedDisplayName) | Out-Null
        }
    }
}

#Function to get the members of a software update group
function Get-SoftwareUpdateGroupMembers {
    param (
    [string]$Group
    )
    $UpdateGroupCIID = (Get-WmiObject -ComputerName $SiteServer -Namespace root/SMS/site_$($SiteCode) -Class SMS_AuthorizationList -Filter "LocalizedDisplayName='$Group'").CI_ID
    $Updates = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT upd.* FROM SMS_SoftwareUpdate upd, SMS_CIRelation cr WHERE cr.FromCIID='$UpdateGroupCIID' AND cr.RelationType=1 AND upd.CI_ID=cr.ToCIID"
    if ($Updates -ne $null) {
        foreach ($Update in $Updates) {
            $DataGridView1.Rows.Add($Group,$Update.ArticleId,$Update.LocalizedDisplayName) | Out-Null
        }
    }
    else {
    }
    return $Updates
}

#Function to get the members of a deployment package
function Get-DeploymentPackageMembers {
    param (
    [string]$Package
    )
    $UpdatePackageID = (Get-WmiObject -ComputerName $SiteServer -Namespace root/SMS/site_$($SiteCode) -Class SMS_SoftwareUpdatesPackage -Filter "Name='$Package'").PackageID
    $Updates = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT DISTINCT su.* FROM SMS_SoftwareUpdate AS su JOIN SMS_CIToContent AS cc `
        ON  SU.CI_ID = CC.CI_ID JOIN SMS_PackageToContent AS pc ON pc.ContentID=cc.ContentID  WHERE  pc.PackageID='$UpdatePackageID' AND su.IsContentProvisioned=1"
    if ($Updates -ne $null) { 
        foreach ($Update in $Updates) {
            $DataGridView2.Rows.Add($Package,$Update.ArticleId,$Update.LocalizedDisplayName) | Out-Null
        }
    }
    else {
    }
    return $Updates
}

#Button1 OnClick event
$Button1_OnClick= {
	$Form1.Close()
}

#Button2 OnClick event
$Button2_OnClick= {
    Try {
        if ($DataGridView1 -ne $null) {
            $DataGridView1.Rows.Clear()
            $DataGridView2.Rows.Clear()
            $Form1.Refresh()
        }   
        
        $ErrorProvider1.SetError($TextBox1,"")
        $ErrorProvider1.SetError($ComboBox1,"")

        if($TextBox1.Text.Length -eq 0 -or $ComboBox1.SelectedItem -eq $null) {
            if($TextBox1.Text.Length -eq 0) {
                $ErrorProvider1.SetError($TextBox1, "Please provide a valid name")           
            }
            if ($ComboBox1.SelectedItem -eq $null) {
                $ErrorProvider1.SetError($ComboBox1, "Please select a valid type")
            }
        }
        else {
            $Name = $TextBox1.Text
            $Type = $ComboBox1.SelectedItem

            if ($Type -eq "Software Update") {
                $GroupBox1.Text = "Software Update Group"
                $GroupBox2.Text = "Deployment Package"
                $TextBox1.Enabled = $false
                $ComboBox1.Enabled = $false

                $Updates = Get-WmiObject -ComputerName $SiteServer -Namespace root/SMS/site_$($SiteCode) -Class SMS_SoftwareUpdate -Filter "ArticleID='$Name'"
                if ($Updates -ne $null) {
                    Get-SoftwareUpdateGroupMembership $Updates
                    Get-DeploymentPackageMembership $Updates
                }
                else {
                    $ErrorProvider1.SetError($TextBox1, "Please provide a valid article id of a software update")
                }
                $ComboBox1.Enabled = $true
                $TextBox1.Enabled = $true
            }
            elseif ($Type -eq "Software Update Group") {
                $GroupBox1.Text = "Software Update Group: $Name"
                $GroupBox2.Text = "Deployment Package"
                $TextBox1.Enabled = $false
                $ComboBox1.Enabled = $false

                $Updates = Get-SoftwareUpdateGroupMembers $Name
                if ($Updates -ne $null) {
                    Get-DeploymentPackageMembership $Updates
                }
                else {
                    $ErrorProvider1.SetError($TextBox1, "Please provide a valid name of a software update group")
                }
                $ComboBox1.Enabled = $true
                $TextBox1.Enabled = $true
            }
            elseif ($Type -eq "Deployment Package") {
                $GroupBox1.Text = "Software Update Group"
                $GroupBox2.Text = "Deployment Package: $Name"
                $TextBox1.Enabled = $false
                $ComboBox1.Enabled = $false

                $Updates = Get-DeploymentPackageMembers $Name
                if ($Updates -ne $null) {
                    Get-SoftwareUpdateGroupMembership $Updates
                }
                else {
                    $ErrorProvider1.SetError($TextBox1, "Please provide a valid name of a deployment package")
                }
                $ComboBox1.Enabled = $true
                $TextBox1.Enabled = $true
            }
        }
    }
    Catch {
        [Windows.Forms.MessageBox]::Show(“Please provide a valid combination of a name and type”, “Software Update Information”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
    }
}

#LinkLabel1 event
$LinkLabel1_OpenLink= {
    [System.Diagnostics.Process]::start($LinkLabel1.text)
}

#LinkLabel2 event
$LinkLabel2_OpenLink= {
    [System.Diagnostics.Process]::start("http://twitter.com/pvanderwoude")
}

#Load Assemblies
[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

#Create ErrorProvider
$ErrorProvider1 = New-Object System.Windows.Forms.ErrorProvider
$ErrorProvider1.BlinkStyle = "NeverBlink"

#Create Form1
$Form1 = New-Object System.Windows.Forms.Form    
$Form1.Size = New-Object System.Drawing.Size(700,590)  
$Form1.MinimumSize = New-Object System.Drawing.Size(700,590)
$Form1.MaximumSize = New-Object System.Drawing.Size(700,590)
$Form1.SizeGripStyle = "Hide"
$Form1.Text = "Software Update Information"
$Form1.ControlBox = $true
$Form1.TopMost = $true

#Create Button1
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Size(510,490)
$Button1.Size = New-Object System.Drawing.Size(150,25)
$Button1.Text = "Close"
$Button1.add_Click($Button1_OnClick)

#Create Button2
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Location = New-Object System.Drawing.Size(510,30)
$Button2.Size = New-Object System.Drawing.Size(150,25)
$Button2.Text = "Execute"
$Button2.add_Click($Button2_OnClick)

#Create ComboBox1
$ComboBox1 = New-Object System.Windows.Forms.ComboBox
$ComboBox1.Location = New-Object System.Drawing.Size(255,30)
$ComboBox1.Size = New-Object System.Drawing.Size(150,25)
$comboBox1.Text = "<Select Type>"

#Create DataGriView1
$DataGridView1 = New-Object System.Windows.Forms.DataGridView
$DataGridView1.Location = New-Object System.Drawing.Size(20,95)
$DataGridView1.Size = New-Object System.Drawing.Size(640,170)
$DataGridView1.ColumnCount = 3
$DataGridView1.ColumnHeadersVisible = $true
$DataGridView1.Columns[0].Name = "Software Update Group"
$DataGridView1.Columns[0].AutoSizeMode = "Fill"
$DataGridView1.Columns[1].Name = "Article ID"
$DataGridView1.Columns[1].AutoSizeMode = "Fill"
$DataGridView1.Columns[2].Name = "Software Update"
$DataGridView1.Columns[2].AutoSizeMode = "Fill"
$DataGridView1.AllowUserToAddRows = $false
$DataGridView1.AllowUserToDeleteRows = $false
$DataGridView1.ReadOnly = $True
$DataGridView1.ColumnHeadersHeightSizeMode = "DisableResizing"
$DataGridView1.RowHeadersWidthSizeMode = "DisableResizing"
$DataGridView1.SelectionMode = "FullRowSelect"

#Create DataGridView2
$DataGridView2 = New-Object System.Windows.Forms.DataGridView
$DataGridView2.Location = New-Object System.Drawing.Size(20,305)
$DataGridView2.Size = New-Object System.Drawing.Size(640,170)
$DataGridView2.ColumnCount = 3
$DataGridView2.ColumnHeadersVisible = $true
$DataGridView2.Columns[0].Name = "Deployment Package"
$DataGridView2.Columns[0].AutoSizeMode = "Fill"
$DataGridView2.Columns[1].Name = "Article ID"
$DataGridView2.Columns[1].AutoSizeMode = "Fill"
$DataGridView2.Columns[2].Name = "Software Update"
$DataGridView2.Columns[2].AutoSizeMode = "Fill"
$DataGridView2.AllowUserToAddRows = $false
$DataGridView2.AllowUserToDeleteRows = $false
$DataGridView2.ReadOnly = $True
$DataGridView2.ColumnHeadersHeightSizeMode = "DisableResizing"
$DataGridView2.RowHeadersWidthSizeMode = "DisableResizing"
$DataGridView2.SelectionMode = "FullRowSelect"

#Create Groupbox1
$GroupBox1 = New-Object System.Windows.Forms.GroupBox
$GroupBox1.Location = New-Object System.Drawing.Size(10,75) 
$GroupBox1.Size = New-Object System.Drawing.Size(660,200) 
$GroupBox1.Text = "Software Update Group"

#Create GroupBox2
$GroupBox2 = New-Object System.Windows.Forms.GroupBox
$GroupBox2.Location = New-Object System.Drawing.Size(10,285) 
$GroupBox2.Size = New-Object System.Drawing.Size(660,200) 
$GroupBox2.Text = "Deployment Package"

#Create GroupBox3
$GroupBox3 = New-Object System.Windows.Forms.GroupBox
$GroupBox3.Location = New-Object System.Drawing.Size(10,10) 
$GroupBox3.Size = New-Object System.Drawing.Size(660,55) 
$GroupBox3.Text = "Required Information"

#Create Label1
$Label1 = New-Object System.Windows.Forms.Label
$Label1.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$Label1.Location = New-Object System.Drawing.Size(20,530) 
$Label1.Size = New-Object System.Drawing.Size(48,23)
$Label1.Text = "My blog:"
        
#Create Label2
$Label2 = New-Object System.Windows.Forms.Label
$Label2.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$Label2.Location = New-Object System.Drawing.Size(460,530) 
$Label2.Size = New-Object System.Drawing.Size(111,23)
$Label2.Text = "Follow me on twitter:"

#Create LinkLabel1
$LinkLabel1 = New-Object System.Windows.Forms.LinkLabel
$LinkLabel1.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$LinkLabel1.Location = New-Object System.Drawing.Size(68,530) 
$LinkLabel1.Size = New-Object System.Drawing.Size(142,23) 
$LinkLabel1.Text = "www.petervanderwoude.nl"
$LinkLabel1.add_click($LinkLabel1_OpenLink)

#Create LinkLabel2
$LinkLabel2 = New-Object System.Windows.Forms.LinkLabel
$LinkLabel2.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$LinkLabel2.Location = New-Object System.Drawing.Size(569,530) 
$LinkLabel2.Size = New-Object System.Drawing.Size(90,23)
$linkLabel2.Text = "@pvanderwoude"
$LinkLabel2.add_click($LinkLabel2_OpenLink)

#Create TextBox1
$TextBox1 = New-Object System.Windows.Forms.TextBox
$TextBox1.Location = New-Object System.Drawing.Size(20,30)
$TextBox1.Size = New-Object System.Drawing.Size(150,25)
$TextBox1.Text = "<Provide Name>"

#Load form
Load-Form
