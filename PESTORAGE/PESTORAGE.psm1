﻿Function Get-PEStorageController
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        $iDRACSession
    )

    Process 
    {
        Get-CimInstance -CimSession $iDRACSession -ResourceUri 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/DCIM_ControllerView' -Namespace 'root/dcim'
    }
}

Function Get-PEVirtualDisk 
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        $iDRACSession
    )
    
    Process
    {
        Get-CimInstance -CimSession $iDRACSession -ResourceUri 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/DCIM_VirtualDiskView' -Namespace 'root/dcim'
    }
}

Function Get-PEPhysicalDisk
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        $iDRACSession
    )
    Process {
        Get-CimInstance -CimSession $iDRACSession -ResourceUri 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/DCIM_PhysicalDiskView' -Namespace 'root/dcim'
    }
}

Function Get-PEAvailableDisk
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        $iDRACSession,

        [Parameter()]
        $DiskType,

        [Parameter()]
        $DiskProtocol,

        [Parameter()]
        $DiskEncrypt
    )

    Process 
    {
        Get-CimInstance -CimSession $iDRACSession -ResourceUri 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/DCIM_PhysicalDiskView' -Namespace 'root/dcim'
    }
}

Function Get-PEEnclosure 
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        $iDRACSession
    )
    Process
    {
        Get-CimInstance -CimSession $iDRACSession -ResourceUri 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/DCIM_EnclosureView' -Namespace 'root/dcim'
    }
}

Function Clear-PERAIDConfiguration 
{
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="High",
        DefaultParameterSetName='General'
    )]

    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false,
                   ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        $iDRACSession,

        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false,
                   ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        $InstanceID,

        [Parameter(ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        [ValidateSet('None','PowerCycle','Graceful','Forced')]
        $RebootType = 'None',

        [Parameter(ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        [String] $StartTime = 'TIME_NOW',

        [Parameter(ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        [String] $UntilTime,

        [Parameter(ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        [Switch] $Force,

        [Parameter(ParameterSetName='Wait')]
        [Switch] $Wait,

        [Parameter(ParameterSetName='Passthru')]
        [Switch] $Passthru
    )

    Begin 
    {
        $properties= @{SystemCreationClassName="DCIM_ComputerSystem";SystemName="DCIM:ComputerSystem";CreationClassName="DCIM_RAIDService";Name="DCIM:RAIDService";}
        $instance = New-CimInstance -ClassName DCIM_RAIDService -Namespace root/dcim -ClientOnly -Key @($properties.keys) -Property $properties        
        if ($Force) 
        {
            $ConfirmPreference = 'None'
        }
    }

    Process 
    {
        if ($PSCmdlet.ShouldProcess($InstanceID, 'Clear Configuration')) 
        {
            $output = Invoke-CimMethod -InputObject $instance -MethodName ResetConfig -CimSession $idracsession -Arguments @{'Target'=$InstanceID}
            if ($output.ReturnValue -eq 0) 
            {
                if ($Output.RebootRequired -eq 'Yes') {
                    $RebootRequired = $true
                    if ($RebootType -eq 'None') 
                    {
                        Write-Warning 'A job will be scheduled but a reboot is required to complete the task. However, reboot type has been set to None. Manually power Cycle the target system to complete this job.'
                    } 
                    else 
                    {
                        Write-Warning "A job will be scheduled and a system reboot ($RebootType) will be initiated to complete the task"
                    }
                }
                else 
                {
                    $RebootRequired = $false
                    if ($RebootType -ne 'None') 
                    {
                        Write-Warning "System reboot is not required to complete the task. However, Reboot type is set to $RebootType. A reboot will be initiated to complete the task"
                    }
                }
            
                if ($PSCmdlet.ParameterSetName -eq 'Passthru') 
                {
                    New-PETargetedConfigurationJob -iDRACSession $idracsession -InstanceID $InstanceID -StartTime $StartTime -UntilTime $UntilTime -RebootType $RebootType -RebootRequired $RebootRequired -Passthru
                } 
                elseif ($PSCmdlet.ParameterSetName -eq 'Wait') 
                {
                    New-PETargetedConfigurationJob -iDRACSession $idracsession -InstanceID $InstanceID -StartTime $StartTime -UntilTime $UntilTime -RebootType $RebootType -RebootRequired $RebootRequired -Wait
                } 
                else 
                {
                    New-PETargetedConfigurationJob -iDRACSession $idracsession -InstanceID $InstanceID -StartTime $StartTime -UntilTime $UntilTime -RebootType $RebootType -RebootRequired $RebootRequired
                }
            }
            else 
            {
                $output
            }
        }
    }
}

Function New-PETargetedConfigurationJob 
{
    [CmdletBinding(DefaultParameterSetName='General')]

    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false,
                   ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        $iDRACSession,

        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false,
                   ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        $InstanceID,

        [Parameter(ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        [ValidateSet('None','PowerCycle','Graceful','Forced')]
        $RebootType = 'None',

        [Parameter(ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        [Bool]$RebootRequired,

        [Parameter(ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        [ValidateSet('Staged','Realtime')]
        [String] $JobType = 'Realtime',

        [Parameter(ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        [String] $StartTime = 'TIME_NOW',

        [Parameter(ParameterSetName='General')]
        [Parameter(ParameterSetName='Passthru')]
        [Parameter(ParameterSetName='Wait')]
        [String] $UntilTime,

        [Parameter(ParameterSetName='Wait')]
        [Switch] $Wait,

        [Parameter(ParameterSetName='Passthru')]
        [Switch] $Passthru
    )

    Begin 
    {
        $properties= @{SystemCreationClassName="DCIM_ComputerSystem";SystemName="DCIM:ComputerSystem";CreationClassName="DCIM_RAIDService";Name="DCIM:RAIDService";}
        $instance = New-CimInstance -ClassName DCIM_RAIDService -Namespace root/dcim -ClientOnly -Key @($properties.keys) -Property $properties        
        $Parameters = @{
            Target = $InstanceID
            ScheduledStartTime = $StartTime
            Realtime = [Jobtype]$JobType -as [int]
        }

        if (-not ($RebootType -eq 'None')) 
        {
            $Parameters.Add('RebootJobType',([ConfigJobRebootType]$RebootType -as [int]))
        }

        if ($UntilTime) 
        {
            $Parameters.Add('UntilTime',$UntilTime)
        }
        $Parameters
    }

    Process 
    {
        $Job = Invoke-CimMethod -InputObject $instance -MethodName CreateTargetedConfigJob -CimSession $idracsession -Arguments $Parameters
        if ($Job.ReturnValue -eq 4096) 
        {
            if ($PSCmdlet.ParameterSetName -eq 'Passthru') 
            {
                $Job
            } 
            elseif ($PSCmdlet.ParameterSetName -eq 'Wait') 
            {
                Write-Verbose 'Starting configuration job ...'
                Wait-PEConfigurationJob -JobID $Job.Job.EndpointReference.InstanceID -Activity 'Performing RAID Configuration ..'                
            }
        } 
        else 
        {
            Write-Error $Job.Message
        }
    }
}

Function Clear-PEForeignConfiguration 
{
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="High"
    )]

    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        $iDRACSession,

        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        $InstanceID
    )

    Begin 
    {
        $properties= @{SystemCreationClassName="DCIM_ComputerSystem";SystemName="DCIM:ComputerSystem";CreationClassName="DCIM_RAIDService";Name="DCIM:RAIDService";}
        $instance = New-CimInstance -ClassName DCIM_RAIDService -Namespace root/dcim -ClientOnly -Key @($properties.keys) -Property $properties        
    }

    Process 
    {
        Invoke-CimMethod -InputObject $instance -MethodName ClearForeignConfig -CimSession $idracsession -Arguments @{'Target'=$InstanceID}
        New-PETargetedConfigurationJob -InstanceID $InstanceID -iDRACSession $iDRACSession
    }
}

Function New-PEJobQueue 
{
    [CmdletBinding()]

    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        $iDRACSession,
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        [string]$JobID,

        [Parameter()]
        [string]$StartTimeInterval ='TIME_NOW',

        [Parameter()]
        [string]$UntilTime
    )

    Begin 
    {
        $properties= @{SystemCreationClassName="DCIM_ComputerSystem";SystemName="Idrac";CreationClassName="DCIM_JobService";Name="JobService";}
        $instance = New-CimInstance -ClassName DCIM_JobService -Namespace root/dcim -ClientOnly -Key @($properties.keys) -Property $properties        
        $Parameters = @{
            JobArray = $JobID
            StartTimeInterval = $StartTimeInterval
        }

        if ($UntilTime) 
        {
            $Parameters.Add('UntilTime',$UntilTime)
        }
    }

    Process 
    {
        $Job = Invoke-CimMethod -InputObject $instance -MethodName SetupJobQueue -CimSession $idracsession -Arguments $Parameters
        $Job
        #if ($Job.ReturnValue -eq 0) {
        #    Write-Verbose "New job created with an ID - $($Job.Job.EndpointReference.InstanceID)"
        #} else {
        #    $Job
        #}
    }
}

Function Remove-PEVirtualDisk 
{
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="High"
    )]

    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        $iDRACSession,

        [Parameter(Mandatory, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        $InstanceID
    )

    Begin 
    {
        $properties= @{SystemCreationClassName="DCIM_ComputerSystem";SystemName="DCIM:ComputerSystem";CreationClassName="DCIM_RAIDService";Name="DCIM:RAIDService";}
        $instance = New-CimInstance -ClassName DCIM_RAIDService -Namespace root/dcim -ClientOnly -Key @($properties.keys) -Property $properties        
    }

    Process 
    {
        Invoke-CimMethod -InputObject $instance -MethodName DeleteVirtualDisk -CimSession $idracsession -Arguments @{'Target'=$InstanceID}
    }
}

Export-ModuleMember -Function *