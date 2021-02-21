<#
.SYNOPSIS
    Show all the information about collections, of which the device is a member.
.DESCRIPTION
    This script creates a form that can be used as a right-click action for a device. It will show information about the collections, deployments, 
    variables, maintenance windows, power management and even the primary user.
.PARAMETER ResourceId 
    The resource id of the device.
.PARAMETER SiteCode
    The site code of the primary site.
.PARAMETER SiteServer
    The site server of the primary site.
.NOTES     
    Author: Peter van der Woude - pvanderwoude@hotmail.com  
    Date published: 01-02-2014  
    Date updated: 07-09-2015
.LINK   
    http://www.petervanderwoude.nl
.EXAMPLE
    Show-CollectionDetails.ps1 -ResourceId 1677724-0 -SiteCode PCP -SiteServer CLDSRV02  
#>
[CmdletBinding()]

param (
[Parameter(Mandatory=$true)][string]$ResourceId,
[Parameter(Mandatory=$true)][string]$SiteCode,
[Parameter(Mandatory=$true)][string]$SiteServer,
[string]$ApplicationVersion = "Show Collection Details v1.1p"
)

#Function to load the form
Function Load-Form {
    $form1.Controls.Add($button1)
	$tabPage1.Controls.Add($dataGridView1)
	$tabPage2.Controls.Add($dataGridView2)
	$tabPage3.Controls.Add($dataGridView3)
	$tabPage4.Controls.Add($dataGridView4)
	$tabPage5.Controls.Add($dataGridView5)
	$tabPage7.Controls.Add($dataGridView6)
	$tabPage8.Controls.Add($dataGridView7)
	$tabPage1.Controls.Add($label1)
	$tabPage2.Controls.Add($label2)
	$tabPage3.Controls.Add($label3)
	$tabPage4.Controls.Add($label4)
	$tabPage5.Controls.Add($label5)
	$tabPage7.Controls.Add($label6)
	$tabPage8.Controls.Add($label7)
	$tabPage6.Controls.Add($label8)
	$form1.Controls.Add($label9)
	$form1.Controls.Add($label10)
	$form1.Controls.Add($linkLabel1)
	$form1.Controls.Add($linkLabel2)
	$form1.Controls.Add($tabControl1)
	$tabPage6.Controls.Add($tabControl2)
	$tabControl1.Controls.Add($tabPage1)
	$tabControl1.Controls.Add($tabPage2)
	$tabControl1.Controls.Add($tabPage3)
	$tabControl1.Controls.Add($tabPage4)
	$tabControl1.Controls.Add($tabPage5)
	$tabControl1.Controls.Add($tabPage6)
	$tabControl2.Controls.Add($tabPage7)
	$tabControl2.Controls.Add($tabPage8)
	$tabPage6.Controls.Add($textBox1)

	$form1.ShowDialog()
}

#Set the resource name
$ResourceName = (Get-WmiObject -Class SMS_R_System -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ResourceId='$ResourceId'").Name

#Function to switch the featuretype of a deployment to something readable
function Set-DeploymentFeatureTypeText {
    param (
    [String]$DeploymentFeatureType
    )
    switch ($DeploymentFeatureType) {
        1 {$DeploymentFeatureTypeText = "Application"; break;}
        2 {$DeploymentFeatureTypeText = "Program"; break;}
        3 {$DeploymentFeatureTypeText = "Mobile Program"; break;}
        4 {$DeploymentFeatureTypeText = "Script"; break;}
        5 {$DeploymentFeatureTypeText = "Software Update"; break;}
        6 {$DeploymentFeatureTypeText = "Baseline"; break;}
        7 {$DeploymentFeatureTypeText = "Task Sequence"; break;}
        8 {$DeploymentFeatureTypeText = "Content Distribution"; break;}
        9 {$DeploymentFeatureTypeText = "Distribution Point Group"; break;}
        10{$DeploymentFeatureTypeText = "Distribution Point Health"; break;}
        11{$DeploymentFeatureTypeText = "Configuration Policy"; break;}        
    }
    Return $DeploymentFeatureTypeText
}

#Function to switch the type of a maintenance window to something readable
function Set-MaintenanceWindowTypeText {
    param(
    [String]$MaintenanceWindowType
    )
    switch ($MaintenanceWindowType) {
        1 {$MaintenanceWindowTypeText = "General"; break;}
        4 {$MaintenanceWindowTypeText = "Software Updates"; break;}
        5 {$MaintenanceWindowTypeText = "OSD"; break;}
    } 
    Return $MaintenanceWindowTypeText
}

#Function to switch the recurrence of a maintenance window to something readable
function Set-MaintenanceWindowRecurrenceText {
    param(
    [String]$MaintenanceWindowRecurrence
    )
    switch ($MaintenanceWindowRecurrence) {
        1 {$MaintenanceWindowRecurrenceText = "None"; break;}
        2 {$MaintenanceWindowRecurrenceText = "Daily"; break;}
        3 {$MaintenanceWindowRecurrenceText = "Weekly"; break;}
        4 {$MaintenanceWindowRecurrenceText = "Monthly By Weekday"; break;}
        5 {$MaintenanceWindowRecurrenceText = "Monthly By Date"; break;}
    } 
    Return $MaintenanceWindowRecurrenceText
}

#Function to switch the day of a maintenance window to something readable
function Set-DayNameText {
    param(
    [String]$DayNumber
    )
    Switch ($DayNumber) {
        1 {$DayNameText = "Sunday"; break;}
        2 {$DayNameText = "Monday"; break;}
        3 {$DayNameText = "Tuesday"; break;}
        4 {$DayNameText = "Wednesday"; break;}
        5 {$DayNameText = "Thursday"; break;}
        6 {$DayNameText = "Friday"; break;}
        7 {$DayNameText = "Saturday"; break;}
    }
    Return $DayNameText
}

#Function to switch the week of a maintenance window to something readable
function Set-WeekOrderText {
    param(
    [String]$WeekOrderNumber
    )
    Switch ($WeekOrderNumber) {
        0 {$WeekOrderText = "Last"; break;}
        1 {$WeekOrderText = "First"; break;}
        2 {$WeekOrderText = "Second"; break;}
        3 {$WeekOrderText = "Third"; break;}
        4 {$WeekOrderText = "Fourth"; break;}
    }
    Return $WeekOrderText
}

#Function to switch the schedule of a maintenance window to something readable
function Set-ScheduleStringText {
    param(
    [string]$ScheduleString
    )
    $WMIConnection = [WMIClass]"\\$SiteServer\root\SMS\Site_$($SiteCode):SMS_ScheduleMethods"
    $ScheduleMethod = "ReadFromString"
    $String = $WMIConnection.psbase.GetMethodParameters($ScheduleMethod)
    $String.StringData = $ScheduleString
    $ScheduleData = $WMIConnection.psbase.InvokeMethod($ScheduleMethod,$String,$null)
    $ScheduleClass = $ScheduleData.TokenData
    switch($ScheduleClass[0].__CLASS) {
        "SMS_ST_RecurWeekly" {$ContentValidationShedule = "Occurs every $($ScheduleClass[0].ForNumberOfWeeks) weeks on $(Set-DayNameText $ScheduleClass[0].Day)"; break;}
        "SMS_ST_RecurInterval" {$ContentValidationShedule = "Occurs every $($ScheduleClass[0].DaySpan) days"; break;} 
        "SMS_ST_RecurMonthlyByDate" {
            if($ScheduleClass[0].MonthDay -eq 0) {
                $ContentValidationShedule = "Occurs the last day of every month"
            ;break;}
            else {
                $ContentValidationShedule = "Occurs day $($ScheduleClass[0].MonthDay) of every $($ScheduleClass[0].ForNumberOfMonths) months"
            ;break;}
        }             
        "SMS_ST_RecurMonthlyByWeekday" {$ContentValidationShedule = "Occurs the $(Set-WeekOrderText $ScheduleClass[0].WeekOrder) $(Set-DayNameText $ScheduleClass[0].Day) of every $($ScheduleClass[0].ForNumberOfMonths) months"; break;}
        "SMS_ST_NonRecurring" {$ContentValidationShedule = "Occurs on $([System.Management.ManagementDateTimeConverter]::ToDateTime($ScheduleClass[0].StartTime))"; break;}
    }
    Return $ContentValidationShedule 
}

#Function to get the deployment state of an application deployment
function Get-AppDeploymentSate {
    param (
    [string]$AssignmentID
    )
    $DeploymentState = Get-WmiObject -Class SMS_AppDeploymentAssetDetails -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "MachineId='$ResourceId' and AssignmentID='$AssignmentID'"
    if ($DeploymentState -eq $null) {
        $Compliancy = "No Information"
    }
    else {
        switch ($DeploymentState.StatusType) {
            1 {$Compliancy = "Success"; break;}
            2 {$Compliancy = "In Progress"; break;}
            3 {$Compliancy = "Requirements Not Met"; break;}
            4 {$Compliancy = "Unknown"; break;}
            default {$Compliancy = "Error"}
        }
    }
    Return $Compliancy
}

#Function to get the deployment state of a package deployment
function Get-ClassicDeploymentSate {
    param (
    [string]$PackageName
    )
    $DeploymentState = Get-WmiObject -Class SMS_ClassicDeploymentAssetDetails -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "DeviceId='$ResourceId' and PackageName='$PackageName'"
    if ($DeploymentState -eq $null) {
        $Compliancy = "No Information"
    }
    else {
        switch ($DeploymentState.StatusType) {
            1 {$Compliancy = "Success"; break;}
            2 {$Compliancy = "In Progress"; break;}
            3 {$Compliancy = "Requirements Not Met"; break;}
            4 {$Compliancy = "Unknown"; break;}
            default {$Compliancy = "Error"}
        }
    }
    Return $Compliancy
}

#Function to get the deployment state of a software update deployment
function Get-SUMDeploymentSate {
    param (
    [string]$AssignmentID
    )
    $DeploymentState = Get-WmiObject -Class SMS_SUMDeploymentAssetDetails -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ResourceId='$ResourceId' and AssignmentID='$AssignmentID'"
    if ($DeploymentState -eq $null) {
        $Compliancy = "No Information"
    }
    else {
        switch ($DeploymentState.StatusType) {
            1 {$Compliancy = "Compliant"; break;}
            2 {$Compliancy = "In Progress"; break;}
            3 {$Compliancy = "Requirements Not Met"; break;}
            4 {$Compliancy = "Unknown"; break;}
            default {$Compliancy = "Error"}
        }
    }
    Return $Compliancy
}

#Function to get the deployment state of a compliance settings deployment
function Get-DCMDeploymentSate {
    param (
    [string]$DCMName
    )
    $DeploymentState = Get-WmiObject -Class SMS_DCMDeploymentCompliantAssetDetails -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "AssetId='$ResourceId' and BLName='$DCMName'"
    if ($DeploymentState -eq $null) {
        $DeploymentState = Get-WmiObject -Class SMS_DCMDeploymentNonCompliantAssetDetails -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "AssetId='$ResourceId' and BLName='$DCMName'"
        if ($DeploymentState -eq $null) {
            $Compliancy = "No Information"
        }
        else {
            switch ($DeploymentState.StatusType) {
                1 {$Compliancy = "Compliant"; break;}
                2 {$Compliancy = "In Progress"; break;}
                3 {$Compliancy = "Non-Compliant"; break;}
                4 {$Compliancy = "Unknown"; break;}
                default {$Compliancy = "Error"}
            }
        }
    }
    else {
        switch ($DeploymentState.StatusType) {
            1 {$Compliancy = "Compliant"; break;}
            2 {$Compliancy = "In Progress"; break;}
            3 {$Compliancy = "Non-Compliant"; break;}
            4 {$Compliancy = "Unknown"; break;}
            default {$Compliancy = "Error"}
        }
    }
    Return $Compliancy
}

#Function to get the deployment state of an antimalware policy deployment
function Get-AntiMalwareDeploymentSate {
    param (
    [string]$SettingsName
    )
    $DeploymentState = Get-WmiObject -Class SMS_G_SYSTEM_AmPolicyStatus -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ResourceId='$ResourceId' and Name='$SettingsName'"
    if ($DeploymentState -eq $null) {
        $Compliancy = "No Information"
    }
    else {
        if ($DeploymentState.ErrorCode -eq 0) {
            $Compliancy = "Compliant"
        }
        else {
            $Compliancy = "Error"
        }
    }
    Return $Compliancy
}

#Function to show the deployments targeted to the collections of the primary user
function Show-PrimaryUserDeployments {
    $WorkArray = New-Object System.Collections.ArrayList
    $SortArray = New-Object System.Collections.ArrayList
    $DataArray = New-Object System.Collections.ArrayList

    if ($dataGridView7.RowCount -ne 0) {
        $dataGridView7.Rows.Clear()
    }

    $IsActive = "True"
    #$UserDeviceRelation = Get-WmiObject -Class SMS_UserMachineRelationship -Namespace root\SMS\Site_$($SiteCode) -ComputerName $SiteServer -Filter "IsActive='$IsActive' and ResourceId='$ResourceId'"
    $UserDeviceRelations = Get-WmiObject -Class SMS_UserMachineRelationship -Namespace root\SMS\Site_$($SiteCode) -ComputerName $SiteServer | Where-Object {$_.IsActive -eq $IsActive -and $_.ResourceId -eq $ResourceId}
    if ($UserDeviceRelations.Types -ne $null) {
        foreach ($UserDeviceRelation in $UserDeviceRelations) { 
            if ($UserDeviceRelation.Types -ne $null) {
                $PrimaryUser = $UserDeviceRelation.UniqueUserName
                $Collections = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object {$_.SMSID -eq $PrimaryUser}
                foreach ($Collection in $Collections) {
                    $CollectionId = $Collection.CollectionId
                    $CollectionInfo = Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
                    $Deployments = Get-WmiObject -Class SMS_DeploymentSummary -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
                    $Settings = Get-WmiObject -Class SMS_ClientSettingsAssignment -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
                    if ($Deployments -eq $null -and $Settings -eq $null) {
                        $dataGridView7.Rows.Add($CollectionInfo.Name,"N/A","N/A","N/A") | Out-Null
                    }
                    else {
                        if ($Deployments -ne $null) {
                            foreach ($Deployment in $Deployments) {
                                switch ($Deployment.FeatureType) {
                                    1 {$DeploymentState = Get-AppDeploymentSate $Deployment.AssignmentID; break;}
                                    2 {$DeploymentState = Get-ClassicDeploymentSate $Deployment.SoftwareName; break;}
                                    3 {$DeploymentState = Get-AppDeploymentSate $Deployment.AssignmentID; break;}
                                    4 {$DeploymentState = Get-AppDeploymentSate $Deployment.AssignmentID; break;}
                                    6 {$DeploymentState = Get-DCMDeploymentSate $Deployment.SoftwareName; break;}
                                    11{$DeploymentState = Get-DCMDeploymentSate $Deployment.SoftwareName; break;}
                                    default {$DeploymentState = "N/A"}
                                }                 
                                $dataGridView7.Rows.Add($CollectionInfo.Name,$Deployment.SoftwareName,$DeploymentState,(Set-DeploymentFeatureTypeText($Deployment.FeatureType))) | Out-Null
                            }
                        }
                        if($Settings -ne $null) {
                            $SettingsId = $Settings.ClientSettingsId
                            $SettingsName = (Get-WmiObject -Class SMS_ClientSettings -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "SettingsId='$SettingsId'").Name
                            $dataGridView7.Rows.Add($CollectionInfo.Name,$SettingsName,"N/A","Client Settings") | Out-Null
                        }
                    }  
                }
                $textBox1.Text = $PrimaryUser
            }
        }
    }
    else {
        $textBox1.Text = "Not configured"
    }
}

#Function to show the collections of the primary user
function Show-PrimaryUserGeneralInformation {
    $WorkArray = New-Object System.Collections.ArrayList
    $SortArray = New-Object System.Collections.ArrayList
    $DataArray = New-Object System.Collections.ArrayList

    if ($dataGridView6.RowCount -ne 0) {
        $dataGridView6.Rows.Clear()
    }

    $IsActive = "True"
    #$UserDeviceRelation = Get-WmiObject -Class SMS_UserMachineRelationship -Namespace root\SMS\Site_$($SiteCode) -ComputerName $SiteServer -Filter "IsActive='$IsActive' and ResourceId='$ResourceId'"
    $UserDeviceRelations = Get-WmiObject -Class SMS_UserMachineRelationship -Namespace root\SMS\Site_$($SiteCode) -ComputerName $SiteServer | Where-Object {$_.IsActive -eq $IsActive -and $_.ResourceId -eq $ResourceId}
    if ($UserDeviceRelations.Types -ne $null) {
        foreach ($UserDeviceRelation in $UserDeviceRelations) { 
            if ($UserDeviceRelation.Types -ne $null) {
                $PrimaryUser = $UserDeviceRelation.UniqueUserName
                $Collections = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer | Where-Object {$_.SMSID -eq $PrimaryUser}
                #$Collections = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "SMSID='$PrimaryUser'"
                foreach ($Collection in $Collections) {
                    $CollectionId = $Collection.CollectionId
                    $CollectionInfo = Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
                    if ($CollectionInfo.LimitToCollectionName -eq $null) {
                        $CollectionInfo.LimitToCollectionName = "N/A"
                    }
                    $dataGridView6.Rows.Add($CollectionInfo.Name,$CollectionId,$CollectionInfo.LimitToCollectionName,[System.Management.ManagementDateTimeConverter]::ToDateTime($CollectionInfo.LastRefreshTime),[System.Management.ManagementDateTimeConverter]::ToDateTime($CollectionInfo.LastMemberChangeTime)) | Out-Null     
                }
                $textBox1.Text = $PrimaryUser
            }
        }
    }
    else {
        $textBox1.Text = "Not configured"
    }
}

#Function to show the power settings targeted to the collections of the device
function Show-PowerManagementSettings {
    $WorkArray = New-Object System.Collections.ArrayList
    $SortArray = New-Object System.Collections.ArrayList
    $DataArray = New-Object System.Collections.ArrayList

    if ($dataGridView5.RowCount -ne 0) {
        $dataGridView5.Rows.Clear()
    }

    $Ids = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ResourceId='$ResourceId'"
    foreach ($Id in $Ids) {
        $CollectionId = $Id.CollectionId
        $CollectionName = Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
        $CollectionSettings = Get-WmiObject -Class SMS_CollectionSettings -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionId='$CollectionId'"
        if($CollectionSettings -eq $null) {
            $dataGridView5.Rows.Add($CollectionName.Name,"N/A","N/A","N/A","N/A","N/A") | Out-Null
        }
        else {
            foreach($CollectionSetting in $CollectionSettings) {
                $CollectionSetting.Get()
                if(!$CollectionSetting.PowerConfigs) {
                    $dataGridView5.Rows.Add($CollectionName.Name,"N/A","N/A","N/A","N/A","N/A") | Out-Null
                }
                else {
                    foreach($PowerConfig in $CollectionSetting.PowerConfigs) {      
                        if ($PowerConfig.DurationInSec -ne 0) {
                            [datetime]$StartTime = $PowerConfig.PeakStartTimeHoursMin
                            [datetime]$EndTime = $StartTime.AddHours($PowerConfig.DurationInSec/3600)
                            $NPWorkXML=[xml]$PowerConfig.NonPeakPowerPlan
                            $PWorkXML=[xml]$PowerConfig.PeakPowerPlan
                            $NPPowerSchemeName=$NPWorkXML.PowerScheme.Name
                            $PPowerSchemeName=$PWorkXML.PowerScheme.Name
                            if ($PowerConfig.WakeUpTimeHoursMin -eq "") {
                                $PowerConfig.WakeUpTimeHoursMin = "Never"
                            }
                            $dataGridView5.Rows.Add($CollectionName.Name,$NPPowerSchemeName,$PPowerSchemeName,$StartTime.ToString("HH:mm"),$EndTime.ToString("HH:mm"),$PowerConfig.WakeUpTimeHoursMin) | Out-Null
                        }
                        else {
                            $dataGridView5.Rows.Add($CollectionName.Name,"Never","Never","Never","Never","Never") | Out-Null
                        }
                    }
                }      
            } 
        }
    }
}

#Function to show the maintenance windows targeted to the collections of the device
function Show-MaintenanceWindows {
    $WorkArray = New-Object System.Collections.ArrayList
    $SortArray = New-Object System.Collections.ArrayList
    $DataArray = New-Object System.Collections.ArrayList

    if ($dataGridView4.RowCount -ne 0) {
        $dataGridView4.Rows.Clear()
    }

    $Ids = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ResourceId='$ResourceId'"
    foreach ($Id in $Ids) {
        $CollectionId = $Id.CollectionId
        $CollectionName = Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
        $CollectionSettings = Get-WmiObject -Class SMS_CollectionSettings -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionId='$CollectionId'"
        if($CollectionSettings -eq $null) {
            $dataGridView4.Rows.Add($CollectionName.Name,"N/A","N/A","N/A","N/A","N/A","N/A","N/A") | Out-Null
        }
        else {
            foreach($CollectionSetting in $CollectionSettings) {
                $CollectionSetting.Get()
                if(!$CollectionSetting.ServiceWindows) {
                    $dataGridView4.Rows.Add($CollectionName.Name,"N/A","N/A","N/A","N/A","N/A","N/A","N/A") | Out-Null
                }
                else {
                    foreach($MaintenancWindow in $CollectionSetting.ServiceWindows) {      
                        if($MaintenancWindow.Count -ne 0){
                            $dataGridView4.Rows.Add($CollectionName.Name,[System.Management.ManagementDateTimeConverter]::ToDateTime($MaintenancWindow.StartTime),$MaintenancWindow.Name,"$($MaintenancWindow.Duration) minutes",(Set-MaintenanceWindowRecurrenceText($MaintenancWindow.RecurrenceType)),(Set-ScheduleStringText($MaintenancWindow.ServiceWindowSchedules)),(Set-MaintenanceWindowTypeText($MaintenancWindow.ServiceWindowType)),$MaintenancWindow.IsEnabled) | Out-Null
                        }
                    }
                }      
            } 
        }
    }
}

#Function to show the variables targeted to the collections of the device (and to the device)
function Show-Variables {
    $WorkArray = New-Object System.Collections.ArrayList
    $SortArray = New-Object System.Collections.ArrayList
    $DataArray = New-Object System.Collections.ArrayList

    if ($dataGridView3.RowCount -ne 0) {
        $dataGridView3.Rows.Clear()
    }

    $Ids = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ResourceId='$ResourceId'"
    foreach ($Id in $Ids) {
        $CollectionId = $Id.CollectionId
        $CollectionName = Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
        $Settings = Get-WmiObject -Class SMS_CollectionSettings -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionId='$CollectionId'"
        if($Settings -eq $null) {
            $dataGridView3.Rows.Add($CollectionName.Name,"N/A","N/A","N/A") | Out-Null
        }
        else {
            [wmi]$CollectionSettings = "$($Settings.__PATH)"
            $CollectionVariables = $CollectionSettings.CollectionVariables
            if(!$CollectionVariables) {
                $dataGridView3.Rows.Add($CollectionName.Name,"N/A","N/A","N/A") | Out-Null
            }
            else {
                foreach($CollectionVariable in $CollectionVariables) {
                    $dataGridView3.Rows.Add($CollectionName.Name,$CollectionVariable.Name,$CollectionVariable.Value,"Collection Variable") | Out-Null
                }
            }     
        }
    }
    $MachineSettings = Get-WmiObject -Class SMS_MachineSettings -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ResourceId='$ResourceId'"
    if($MachineSettings -ne $null) {
        [wmi]$MachineSettings = "$($MachineSettings.__PATH)"
        $MachineVariables = $MachineSettings.MachineVariables
        if($MachineVariables) {
            foreach($MachineVariable in $MachineVariables) {
                $dataGridView3.Rows.Add("N/A",$MachineVariable.Name,$MachineVariable.Value,"Machine Variable") | Out-Null
            }
        }
    }
}

#Function to show the deployments targeted to the collections of the device
function Show-Deployments {
    $WorkArray = New-Object System.Collections.ArrayList
    $SortArray = New-Object System.Collections.ArrayList
    $DataArray = New-Object System.Collections.ArrayList

    if ($dataGridView2.RowCount -ne 0) {
        $dataGridView2.Rows.Clear()
    }

    $Ids = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ResourceId='$ResourceId'"
    foreach ($Id in $Ids) {
        $CollectionId = $Id.CollectionId
        $CollectionNameObj = Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
        $Deployments = Get-WmiObject -Class SMS_DeploymentSummary -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
        $Settings = Get-WmiObject -Class SMS_ClientSettingsAssignment -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
        if ($Deployments -eq $null -and $Settings -eq $null) {
            $dataGridView2.Rows.Add($CollectionNameObj.Name,"N/A","N/A","N/A") | Out-Null
        }
	    else {
            if ($Deployments -ne $null) {
                foreach ($Deployment in $Deployments) {
                    switch ($Deployment.FeatureType) {
                        1 {$DeploymentState = Get-AppDeploymentSate $Deployment.AssignmentID; break;}
                        2 {$DeploymentState = Get-ClassicDeploymentSate $Deployment.SoftwareName; break;}
                        3 {$DeploymentState = Get-AppDeploymentSate $Deployment.AssignmentID; break;}
                        4 {$DeploymentState = Get-AppDeploymentSate $Deployment.AssignmentID; break;}
                        5 {$DeploymentState = Get-SUMDeploymentSate $Deployment.AssignmentID; break;}
                        6 {$DeploymentState = Get-DCMDeploymentSate $Deployment.SoftwareName; break;}
                        7 {$DeploymentState = Get-ClassicDeploymentSate $Deployment.SoftwareName; break;}
                        11{$DeploymentState = Get-DCMDeploymentSate $Deployment.SoftwareName; break;}
                        default {$DeploymentState = "N/A"}
                    }
                    $dataGridView2.Rows.Add($Deployment.CollectionName,$Deployment.SoftwareName,$DeploymentState,(Set-DeploymentFeatureTypeText($Deployment.FeatureType))) | Out-Null
                }
            }
            if($Settings -ne $null) {
                $FeatureType = "Client Settings"
                $SettingsId = $Settings.ClientSettingsId
                $SettingsName = Get-WmiObject -Class SMS_ClientSettings -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "SettingsId='$SettingsId'"
                $DeploymentState = "N/A"
                if ($SettingsName -eq $null) {
                    $FeatureType = "Antimalware Settings"
                    $SettingsName = Get-WmiObject -Class SMS_AntimalwareSettings -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "SettingsId='$SettingsId'"
                    $DeploymentState = Get-AntiMalwareDeploymentSate $SettingsName.Name
                }
                $dataGridView2.Rows.Add($CollectionNameObj.Name,$SettingsName.Name,$DeploymentState,$FeatureType) | Out-Null
            }
        }
    }
}

#Function to show the collections of the device
function Show-GeneralInformation {
    $WorkArray = New-Object System.Collections.ArrayList
    $SortArray = New-Object System.Collections.ArrayList
    $DataArray = New-Object System.Collections.ArrayList    
    
    if ($dataGridView1.RowCount -ne 0) {
        $dataGridView1.Rows.Clear()
    }

    $Ids = Get-WmiObject -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "ResourceId='$ResourceId'"
    foreach ($Id in $Ids) {
        $CollectionId = $Id.CollectionId
        $CollectionNames = Get-WmiObject -Class SMS_Collection -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Filter "CollectionID='$CollectionId'"
        foreach ($CollectionName in $CollectionNames) {
            if ($CollectionName.LimitToCollectionName -eq $null) {
                $CollectionName.LimitToCollectionName = "N/A"
            }
            $dataGridView1.Rows.Add($CollectionName.Name,$CollectionId,$CollectionName.LimitToCollectionName,[System.Management.ManagementDateTimeConverter]::ToDateTime($CollectionName.LastRefreshTime),[System.Management.ManagementDateTimeConverter]::ToDateTime($CollectionName.LastMemberChangeTime)) | Out-Null
        }
    }
}

#Action of button1
$button1_OnClick= {
	$form1.Close()
}

#Action of linkLabel1    
$linkLabel1_OpenLink= {
    [system.Diagnostics.Process]::start($linkLabel1.text)
}

#Action of linkLabel2
$linkLabel2_OpenLink= {
    [system.Diagnostics.Process]::start("http://twitter.com/pvanderwoude")
}

#Action during the load of the form
$OnLoadForm_UpdateGrid= {
    Show-GeneralInformation
}

#Action during the switching of tabControl1
$tabControl1_SelectedIndexChanged= {
    if($tabControl1.SelectedTab -eq $tabPage1) {
        Show-GeneralInformation
    }
    elseif($tabControl1.SelectedTab -eq $tabPage2) {
        Show-Deployments    
    }
    elseif($tabControl1.SelectedTab -eq $tabPage3) {
        Show-Variables
    }
    elseif($tabControl1.SelectedTab -eq $tabPage4) {
        Show-MaintenanceWindows
    }
    elseif($tabControl1.SelectedTab -eq $tabPage5) {
        Show-PowerManagementSettings
    }
    else {
        Show-PrimaryUserGeneralInformation
    }
}

#Action during the switching of tabControl2
$tabControl2_SelectedIndexChanged= {
    if($tabControl2.SelectedTab -eq $tabPage7) {
        Show-PrimaryUserGeneralInformation
    }      
    else {
        Show-PrimaryUserDeployments
    }
}

#Load Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

#Create form1
$form1 = New-Object System.Windows.Forms.Form
$form1.ClientSize = New-Object System.Drawing.Size(542,408)
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$form1.Name = "form1"
$form1.Text = "$ResourceName Collection Details"
$form1.add_Load($OnLoadForm_UpdateGrid)

#Create button1
$button1 = New-Object System.Windows.Forms.Button
$button1.Location = New-Object System.Drawing.Size(381,354)
$button1.Size = New-Object System.Drawing.Size(150,23)
$button1.TabIndex = 1
$button1.Text = "Close"
$button1.add_Click($button1_OnClick)

#Create dataGridView1
$dataGridView1 = New-Object System.Windows.Forms.DataGridView
$dataGridView1.AllowUserToAddRows = $False
$dataGridView1.AllowUserToDeleteRows = $False
$dataGridView1.AllowUserToResizeRows = $False
$dataGridView1.BackGroundColor = "White"
$dataGridView1.ColumnCount = 5
$dataGridView1.ColumnHeadersVisible = $True
$dataGridView1.Columns[0].Name = "Collection Name"
$dataGridView1.Columns[0].MinimumWidth = 100
$dataGridView1.Columns[0].Width = 100
$dataGridView1.Columns[1].Name = "Collection Id"
$dataGridView1.Columns[1].MinimumWidth = 100
$dataGridView1.Columns[1].Width = 100
$dataGridView1.Columns[2].Name = "Limiting Collection"
$dataGridView1.Columns[2].MinimumWidth = 100
$dataGridView1.Columns[2].Width = 100
$dataGridView1.Columns[3].Name = "Last Update"
$dataGridView1.Columns[3].MinimumWidth = 100
$dataGridView1.Columns[3].Width = 100
$dataGridView1.Columns[4].Name = "Last Membership Change"
$dataGridView1.Columns[4].MinimumWidth = 100
$dataGridView1.Columns[4].Width = 100
$dataGridView1.Location = New-Object System.Drawing.Size(2,50)
$dataGridView1.ReadOnly = $True
$dataGridView1.RowHeadersVisible = $False
$dataGridView1.SelectionMode = 'FullRowSelect'
$dataGridView1.Size = New-Object System.Drawing.Size(505,255)
$dataGridView1.TabIndex = 2  

#Create dataGridView2
$dataGridView2 = New-Object System.Windows.Forms.DataGridView
$dataGridView2.AllowUserToAddRows = $False
$dataGridView2.AllowUserToDeleteRows = $False
$dataGridView2.AllowUserToResizeRows = $False
$dataGridView2.BackGroundColor = "White"
$dataGridView2.ColumnCount = 4
$dataGridView2.ColumnHeadersVisible = $True
$dataGridView2.Columns[0].Name = "Collection Name"
$dataGridView2.Columns[0].MinimumWidth = 125
$dataGridView2.Columns[0].Width = 125
$dataGridView2.Columns[1].Name = "Deployment Name"
$dataGridView2.Columns[1].MinimumWidth = 125
$dataGridView2.Columns[1].Width = 125
$dataGridView2.Columns[2].Name = "Deployment State"
$dataGridView2.Columns[2].MinimumWidth = 125
$dataGridView2.Columns[2].Width = 125
$dataGridView2.Columns[3].Name = "Deployment Type"
$dataGridView2.Columns[3].MinimumWidth = 125
$dataGridView2.Columns[3].Width = 125
$dataGridView2.Location = New-Object System.Drawing.Size(2,50)
$dataGridView2.ReadOnly = $True
$dataGridView2.RowHeadersVisible = $False
$dataGridView2.SelectionMode = 'FullRowSelect'
$dataGridView2.Size = New-Object System.Drawing.Size(505,255)
$dataGridView2.TabIndex = 2

#Create dataGridView3
$dataGridView3 = New-Object System.Windows.Forms.DataGridView
$dataGridView3.AllowUserToAddRows = $False
$dataGridView3.AllowUserToDeleteRows = $False
$dataGridView3.AllowUserToResizeRows = $False
$dataGridView3.BackGroundColor = "White"
$dataGridView3.ColumnCount = 4
$dataGridView3.ColumnHeadersVisible = $True
$dataGridView3.Columns[0].Name = "Collection Name"
$dataGridView3.Columns[0].MinimumWidth = 125
$dataGridView3.Columns[0].Width = 125
$dataGridView3.Columns[1].Name = "Variable Name"
$dataGridView3.Columns[1].MinimumWidth = 125
$dataGridView3.Columns[1].Width = 125
$dataGridView3.Columns[2].Name = "Variable Value"
$dataGridView3.Columns[2].MinimumWidth = 125
$dataGridView3.Columns[2].Width = 125
$dataGridView3.Columns[3].Name = "Variable Type"
$dataGridView3.Columns[3].MinimumWidth = 125
$dataGridView3.Columns[3].Width = 125
$dataGridView3.Location = New-Object System.Drawing.Size(2,50)
$dataGridView3.ReadOnly = $True
$dataGridView3.RowHeadersVisible = $False
$dataGridView3.SelectionMode = 'FullRowSelect'
$dataGridView3.Size = New-Object System.Drawing.Size(505,255)
$dataGridView3.TabIndex = 2

#Create dataGridView4
$dataGridView4 = New-Object System.Windows.Forms.DataGridView
$dataGridView4.AllowUserToAddRows = $False
$dataGridView4.AllowUserToDeleteRows = $False
$dataGridView4.AllowUserToResizeRows = $False
$dataGridView4.BackGroundColor = "White"
$dataGridView4.ColumnCount = 8
$dataGridView4.ColumnHeadersVisible = $True
$dataGridView4.Columns[0].Name = "Collection Name"
$dataGridView4.Columns[0].MinimumWidth = 100
$dataGridView4.Columns[0].Width = 100
$dataGridView4.Columns[1].Name = "MW Name"
$dataGridView4.Columns[1].MinimumWidth = 100
$dataGridView4.Columns[1].Width = 100
$dataGridView4.Columns[2].Name = "MW StartTime"
$dataGridView4.Columns[2].MinimumWidth = 100
$dataGridView4.Columns[2].Width = 100
$dataGridView4.Columns[3].Name = "MW Duration"
$dataGridView4.Columns[3].MinimumWidth = 100
$dataGridView4.Columns[3].Width = 100
$dataGridView4.Columns[4].Name = "MW Recurrence"
$dataGridView4.Columns[4].MinimumWidth = 100
$dataGridView4.Columns[4].Width = 100
$dataGridView4.Columns[5].Name = "MW Schedule"
$dataGridView4.Columns[5].MinimumWidth = 100
$dataGridView4.Columns[5].Width = 100
$dataGridView4.Columns[6].Name = "MW Type"
$dataGridView4.Columns[6].MinimumWidth = 100
$dataGridView4.Columns[6].Width = 100
$dataGridView4.Columns[7].Name = "MW Enabled"
$dataGridView4.Columns[7].MinimumWidth = 100
$dataGridView4.Columns[7].Width = 100
$dataGridView4.Location = New-Object System.Drawing.Size(2,50)
$dataGridView4.ReadOnly = $True
$dataGridView4.RowHeadersVisible = $False
$dataGridView4.SelectionMode = 'FullRowSelect'
$dataGridView4.Size = New-Object System.Drawing.Size(505,255)
$dataGridView4.TabIndex = 2

#Create dataGridView5
$dataGridView5 = New-Object System.Windows.Forms.DataGridView
$dataGridView5.AllowUserToAddRows = $False
$dataGridView5.AllowUserToDeleteRows = $False
$dataGridView5.AllowUserToResizeRows = $False
$dataGridView5.BackGroundColor = "White"
$dataGridView5.ColumnCount = 6
$dataGridView5.ColumnHeadersVisible = $True
$dataGridView5.Columns[0].Name = "Collection Name"
$dataGridView5.Columns[0].MinimumWidth = 100
$dataGridView5.Columns[0].Width = 100
$dataGridView5.Columns[1].Name = "Non-Peak Power Plan"
$dataGridView5.Columns[1].MinimumWidth = 100
$dataGridView5.Columns[1].Width = 100
$dataGridView5.Columns[2].Name = "Peak Power Plan"
$dataGridView5.Columns[2].MinimumWidth = 100
$dataGridView5.Columns[2].Width = 100
$dataGridView5.Columns[3].Name = "Peak Start Time"
$dataGridView5.Columns[3].MinimumWidth = 100
$dataGridView5.Columns[3].Width = 100
$dataGridView5.Columns[4].Name = "Peak End Time"
$dataGridView5.Columns[4].MinimumWidth = 100
$dataGridView5.Columns[4].Width = 100
$dataGridView5.Columns[5].Name = "Wake-Up Time"
$dataGridView5.Columns[5].MinimumWidth = 100
$dataGridView5.Columns[5].Width = 100
$dataGridView5.Location = New-Object System.Drawing.Size(2,50)
$dataGridView5.ReadOnly = $True
$dataGridView5.RowHeadersVisible = $False
$dataGridView5.SelectionMode = 'FullRowSelect'
$dataGridView5.Size = New-Object System.Drawing.Size(505,255)
$dataGridView5.TabIndex = 2

#Create dataGridView6
$dataGridView6 = New-Object System.Windows.Forms.DataGridView
$dataGridView6.AllowUserToAddRows = $False
$dataGridView6.AllowUserToDeleteRows = $False
$dataGridView6.AllowUserToResizeRows = $False
$dataGridView6.BackGroundColor = "White"
$dataGridView6.ColumnCount = 5
$dataGridView6.ColumnHeadersVisible = $True
$dataGridView6.Columns[0].Name = "Collection Name"
$dataGridView6.Columns[0].MinimumWidth = 100
$dataGridView6.Columns[0].Width = 100
$dataGridView6.Columns[1].Name = "Collection Id"
$dataGridView6.Columns[1].MinimumWidth = 100
$dataGridView6.Columns[1].Width = 100
$dataGridView6.Columns[2].Name = "Limiting Collection"
$dataGridView6.Columns[2].MinimumWidth = 100
$dataGridView6.Columns[2].Width = 100
$dataGridView6.Columns[3].Name = "Last Update"
$dataGridView6.Columns[3].MinimumWidth = 100
$dataGridView6.Columns[3].Width = 100
$dataGridView6.Columns[4].Name = "Last Membership Change"
$dataGridView6.Columns[4].MinimumWidth = 100
$dataGridView6.Columns[4].Width = 100
$dataGridView6.Location = New-Object System.Drawing.Size(2,50)
$dataGridView6.ReadOnly = $True
$dataGridView6.RowHeadersVisible = $False
$dataGridView6.SelectionMode = 'FullRowSelect'
$dataGridView6.Size = New-Object System.Drawing.Size(496,194)
$dataGridView6.TabIndex = 2

#Create dataGridView7
$dataGridView7 = New-Object System.Windows.Forms.DataGridView
$dataGridView7.AllowUserToAddRows = $False
$dataGridView7.AllowUserToDeleteRows = $False
$dataGridView7.AllowUserToResizeRows = $False
$dataGridView7.BackGroundColor = "White"
$dataGridView7.ColumnCount = 4
$dataGridView7.ColumnHeadersVisible = $True
$dataGridView7.Columns[0].Name = "Collection Name"
$dataGridView7.Columns[0].MinimumWidth = 125
$dataGridView7.Columns[0].Width = 125
$dataGridView7.Columns[1].Name = "Deployment Name"
$dataGridView7.Columns[1].MinimumWidth = 125
$dataGridView7.Columns[1].Width = 125
$dataGridView7.Columns[2].Name = "Deployment State"
$dataGridView7.Columns[2].MinimumWidth = 125
$dataGridView7.Columns[2].Width = 125
$dataGridView7.Columns[3].Name = "Deployment Type"
$dataGridView7.Columns[3].MinimumWidth = 125
$dataGridView7.Columns[3].Width = 125
$dataGridView7.Location = New-Object System.Drawing.Size(2,50)
$dataGridView7.ReadOnly = $True
$dataGridView7.RowHeadersVisible = $False
$dataGridView7.SelectionMode = 'FullRowSelect'
$dataGridView7.Size = New-Object System.Drawing.Size(496,194)
$dataGridView7.TabIndex = 2
    
#Create label1
$label1 = New-Object System.Windows.Forms.Label
$label1.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$label1.Location = New-Object System.Drawing.Point(2,13)
$label1.Size = New-Object System.Drawing.Point(505,46)
$label1.TabIndex = 0
$label1.Text = "This tab shows an overview of all collections, of which the device is a member, including general information about the Collections."
    
#Create label2
$label2 = New-Object System.Windows.Forms.Label
$label2.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$label2.Location = New-Object System.Drawing.Point(2,13)
$label2.Size = New-Object System.Drawing.Point(505,46)
$label2.TabIndex = 0
$label2.Text = "This tab shows an overview of all collections, of which the device is a member, including the names, statusses and types of the targeted Deployments."

#Create label3
$label3 = New-Object System.Windows.Forms.Label
$label3.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$label3.Location = New-Object System.Drawing.Point(2,13)
$label3.Size = New-Object System.Drawing.Point(505,46)
$label3.TabIndex = 0
$label3.Text = "This tab shows an overview of all collections, of which the device is a member, including the names, values and types of the configured Variables."

#Create label4
$label4 = New-Object System.Windows.Forms.Label
$label4.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$label4.Location = New-Object System.Drawing.Point(2,13)
$label4.Size = New-Object System.Drawing.Point(505,46)
$label4.TabIndex = 0
$label4.Text = "This tab shows an overview of all collections, of which the device is a member, including the names, start times, durations, recurrences, schedules and types of the configured MW."

#Create label5
$label5 = New-Object System.Windows.Forms.Label
$label5.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$label5.Location = New-Object System.Drawing.Point(2,13)
$label5.Size = New-Object System.Drawing.Point(505,46)
$label5.TabIndex = 0
$label5.Text = "This tab shows an overview of all collections, of which the device is a member, including the (non-)peak power plan, peak start and end time and the wake-up time."

#Create label6
$label6 = New-Object System.Windows.Forms.Label
$label6.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$label6.Location = New-Object System.Drawing.Point(2,13)
$label6.Size = New-Object System.Drawing.Point(496,46)
$label6.TabIndex = 0
$label6.Text = "This tab shows an overview of all collections, of which the primary user, of the device, is a member, including general information about the Collections."
    
#Create label7
$label7 = New-Object System.Windows.Forms.Label
$label7.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$label7.Location = New-Object System.Drawing.Point(2,13)
$label7.Size = New-Object System.Drawing.Point(496,46)
$label7.TabIndex = 0
$label7.Text = "This tab shows an overview of all collections, of which the primary user, of the device, is a member, including the names, statusses and types of the targeted Deployments."

#Create label8
$label8 = New-Object System.Windows.Forms.Label
$label8.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$label8.Location = New-Object System.Drawing.Point(274,13)
$label8.Size = New-Object System.Drawing.Point(76,23)
$label8.TabIndex = 0
$label8.Text = "Primary User:"

#Create label9
$label9 = New-Object System.Windows.Forms.Label
$label9.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$label9.Location = New-Object System.Drawing.Point(12,382)
$label9.Size = New-Object System.Drawing.Point(48,23)
$label9.TabIndex = 1
$label9.Text = "My blog:"   
        
#Create label10
$label10 = New-Object System.Windows.Forms.Label
$label10.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$label10.Location = New-Object System.Drawing.Point(329,382)
$label10.Size = New-Object System.Drawing.Point(117,23)
$label10.TabIndex = 2
$label10.Text = "Follow me on twitter:"
    
#Create linkLabel1
$linkLabel1 = New-Object System.Windows.Forms.LinkLabel
$linkLabel1.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$linkLabel1.Location = New-Object System.Drawing.Point(63,382)
$linkLabel1.Size = New-Object System.Drawing.Point(142,23)
$linkLabel1.TabIndex = 0
$linkLabel1.TabStop = $True
$linkLabel1.Text = "www.petervanderwoude.nl"
$linkLabel1.add_click($linkLabel1_OpenLink)

#Create linkLabel2
$linkLabel2 = New-Object System.Windows.Forms.LinkLabel
$linkLabel2.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$linkLabel2.Location = New-Object System.Drawing.Point(443,382)
$linkLabel2.Size = New-Object System.Drawing.Point(90,23)
$linkLabel2.TabIndex = 3
$linkLabel2.TabStop = $True
$linkLabel2.Text = "@pvanderwoude"
$linkLabel1.add_click($linkLabel2_OpenLink)
    
#Create tabControl1
$tabControl1 = New-Object System.Windows.Forms.TabControl
$tabControl1.Location = New-Object System.Drawing.Point(13,13)
$tabControl1.SelectedIndex = 0
$tabControl1.Size = New-Object System.Drawing.Point(516,332)
$tabControl1.TabIndex = 0
$tabControl1.add_click($tabControl1_SelectedIndexChanged)

#Create tabControl2
$tabControl2 = New-Object System.Windows.Forms.TabControl
$tabControl2.Location = New-Object System.Drawing.Point(1,35)
$tabControl2.SelectedIndex = 0
$tabControl2.Size = New-Object System.Drawing.Point(507,271)
$tabControl2.TabIndex = 0
$tabControl2.add_click($tabControl2_SelectedIndexChanged)

#Create tabPage1
$tabPage1 = New-Object System.Windows.Forms.TabPage
$tabPage1.Location = New-Object System.Drawing.Point(4,22)
$tabPage1.Padding = New-Object System.Windows.Forms.Padding (3,3,3,3)
$tabPage1.Size = New-Object System.Drawing.Point(508,279)
$tabPage1.TabIndex = 0
$tabPage1.Text = "General"
$tabPage1.UseVisualStyleBackColor = $True

#Create tabPage2
$tabPage2 = New-Object System.Windows.Forms.TabPage
$tabPage2.Location = New-Object System.Drawing.Point(4,22)
$tabPage2.Padding = New-Object System.Windows.Forms.Padding (3,3,3,3)
$tabPage2.Size = New-Object System.Drawing.Point(508,279)
$tabPage2.TabIndex = 1
$tabPage2.Text = "Deployments"
$tabPage2.UseVisualStyleBackColor = $True

#Create tabPage3
$tabPage3 = New-Object System.Windows.Forms.TabPage
$tabPage3.Location = New-Object System.Drawing.Point(4,22)
$tabPage3.Padding = New-Object System.Windows.Forms.Padding (3,3,3,3)
$tabPage3.Size = New-Object System.Drawing.Point(508,279)
$tabPage3.TabIndex = 2
$tabPage3.Text = "Variables"
$tabPage3.UseVisualStyleBackColor = $True
    
#Create tabPage4
$tabPage4 = New-Object System.Windows.Forms.TabPage
$tabPage4.Location = New-Object System.Drawing.Point(4,22)
$tabPage4.Padding = New-Object System.Windows.Forms.Padding (3,3,3,3)
$tabPage4.Size = New-Object System.Drawing.Point(508,279)
$tabPage4.TabIndex = 3
$tabPage4.Text = "Maintenance Windows"
$tabPage4.UseVisualStyleBackColor = $True
    
#Create tabPage5
$tabPage5 = New-Object System.Windows.Forms.TabPage
$tabPage5.Location = New-Object System.Drawing.Point(4,22)
$tabPage5.Padding = New-Object System.Windows.Forms.Padding (3,3,3,3)
$tabPage5.Size = New-Object System.Drawing.Point(508,279)
$tabPage5.TabIndex = 4
$tabPage5.Text = "Power Management"
$tabPage5.UseVisualStyleBackColor = $True

#Create tabPage6
$tabPage6 = New-Object System.Windows.Forms.TabPage
$tabPage6.Location = New-Object System.Drawing.Point(4,22)
$tabPage6.Padding = New-Object System.Windows.Forms.Padding (3,3,3,3)
$tabPage6.Size = New-Object System.Drawing.Point(508,279)
$tabPage6.TabIndex = 4
$tabPage6.Text = "Primary User"
$tabPage6.UseVisualStyleBackColor = $True
    
#Create tabPage7
$tabPage7 = New-Object System.Windows.Forms.TabPage
$tabPage7.Location = New-Object System.Drawing.Point(4,22)
$tabPage7.Padding = New-Object System.Windows.Forms.Padding (3,3,3,3)
$tabPage7.Size = New-Object System.Drawing.Point(508,279)
$tabPage7.TabIndex = 4
$tabPage7.Text = "General"
$tabPage7.UseVisualStyleBackColor = $True

#Create tabPage8
$tabPage8 = New-Object System.Windows.Forms.TabPage
$tabPage8.Location = New-Object System.Drawing.Point(4,22)
$tabPage8.Padding = New-Object System.Windows.Forms.Padding (3,3,3,3)
$tabPage8.Size = New-Object System.Drawing.Point(508,279)
$tabPage8.TabIndex = 4
$tabPage8.Text = "Deployments"
$tabPage8.UseVisualStyleBackColor = $True
    
#Create textBox1
$textBox1 = New-Object System.Windows.Forms.TextBox
$textBox1.Location = New-Object System.Drawing.Point(362,13)
$textBox1.Size = New-Object System.Drawing.Point(145,20)
$textBox1.TabIndex = 1
$textBox1.Enabled = $False

$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
$InitialFormWindowState = $form1.WindowState

#Load form
Load-Form
