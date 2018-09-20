<#
.SYNOPSIS
Get information about the physical disks and volumes on a system.
 
.DESCRIPTION
Get details about the physical disks and the volumes located on
those disks, to make it easier to identify corresponding vSphere
storage (VMDKs).
 
.EXAMPLE
 
PS C:\> .\Get-DiskInfo.ps1
 
.NOTES
    Author: Geoff Duke <Geoffrey.Duke@uvm.edu>
    Based on http://bit.ly/XowLns and http://bit.ly/XeIqFh
#>
 
Set-PSDebug -Strict
 
Function Main {
 
    $diskdrives = get-wmiobject Win32_DiskDrive | sort Index
 
    $colSize = @{Name='Size';Expression={Get-HRSize $_.Size}}

    $totalVolumeSize = 0;
    $totalVolumeFree = 0;
 
    foreach ( $disk in $diskdrives ) {
 




        $scsi_details = 'SCSI ' + $disk.SCSIBus         + ':' +
                                  $disk.SCSILogicalUnit + ':' +
                                  $disk.SCSIPort        + ':' +
                                  $disk.SCSITargetID
        
        $DiskSig = $disk.Signature
        
        write $( 'Disk ' + $disk.Index + ' - ' + $scsi_details +
                 ' - ' + ( Get-HRSize $disk.size) + ' - Disk Signature: ' + [convert]::tostring($DiskSig, 16)) 
 
        $part_query = 'ASSOCIATORS OF {Win32_DiskDrive.DeviceID="' +
                      $disk.DeviceID.replace('\','\\') +
                      '"} WHERE AssocClass=Win32_DiskDriveToDiskPartition'
 
        $partitions = @( get-wmiobject -query $part_query | 
                         sort StartingOffset )
        foreach ($partition in $partitions) {
 
            $vol_query = 'ASSOCIATORS OF {Win32_DiskPartition.DeviceID="' +
                         $partition.DeviceID +
                         '"} WHERE AssocClass=Win32_LogicalDiskToPartition'
            $volumes   = @(get-wmiobject -query $vol_query)
 
            write $( '    Partition ' + $partition.Index + '  ' +
                     ( Get-HRSize $partition.Size) + '  ' +
                     $partition.Type
                   )
 
            foreach ( $volume in $volumes) {
                
                
                write $( '        ' + $volume.name + 
                         ' [' + $volume.FileSystem + '][' + $Volume.VolumeName +'] ' + 
                         ( Get-HRSize $volume.Size ) + ' ( ' +
                         ( Get-HRSize $volume.FreeSpace ) + ' free )'
                       )

                       $totalvolumeSize += $volume.Size;
                       $totalVolumeFree += $volume.FreeSpace;
 
            } # end foreach vol
 
        } # end foreach part
 
        write ''
 
    } # end foreach disk
 
 write ("Total Volume Size: " + [math]::Round($totalvolumeSize/1GB,2)  + " GB")
 write ("Total Volume Free: " + [math]::Round($totalVolumeFree/1GB,2)  + " GB")

}
 
#--------------------------------------------------------------------
function Get-HRSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [INT64] $bytes
    )
    process {
        if     ( $bytes -gt 1pb ) { "{0:N2} PB" -f ($bytes / 1pb) }
        elseif ( $bytes -gt 1tb ) { "{0:N2} TB" -f ($bytes / 1tb) }
        elseif ( $bytes -gt 1gb ) { "{0:N2} GB" -f ($bytes / 1gb) }
        elseif ( $bytes -gt 1mb ) { "{0:N2} MB" -f ($bytes / 1mb) }
        elseif ( $bytes -gt 1kb ) { "{0:N2} KB" -f ($bytes / 1kb) }
        else   { "{0:N} Bytes" -f $bytes }
    }
} # End Function:Get-HRSize
 
Main


