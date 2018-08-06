
Param (
    [Parameter(mandatory = $true)]
    [String]$infile
)

#Import the CSV file
$csv = Import-Csv $infile

#Add fields to capture the number of groups and number of users with access to the folder
$csv | Add-Member -MemberType NoteProperty -Name 'group_count' -Value null
$csv | Add-Member -MemberType NoteProperty -Name 'user_count' -Value null

#Loop through each row in the csv
foreach($row in $csv) {
    
    $filepath = $row.directory
    
    #Get ACLs and Group Names for each folder
    $acls = Get-Acl $filepath
    #$groupNames = Split-Path $acls.Access.IdentityReference -Leaf
    $groupNames = $acls.Access.IdentityReference | ? {$_.Value -like "SCRIPPS\*"} | Split-Path -Leaf

    #Initialize arrays to hold AD Groups and Users
    $groups = @()
    $users = @()
    
    #for each group name in the ACL, drop the AD Group object into the $groups array
    foreach($name in $groupNames) {
        try {
            $groups += Get-ADGroup $name
        }
        catch {$errors}
    }

    #de-dupe groups before looping
    $groups = $groups | Select -Unique

    #for each AD group in the $groups array, recursively enumerate group members of 
    #type 'user' and drop into the $users array
    foreach($group in $groups) {
        try {
        $users += Get-ADGroupMember $group -Recursive |where {$_.objectclass -eq 'user'}
        }
        catch {$errors}
    }

    #de-dupe users
    $users = $users | Select -Unique
    
    #add group and user counts to the table
    $row.group_count = $groups.Count
    $row.user_count = $users.Count
}

#display the table or write it to a csv
#$csv | Format-Table
$csv | Export-Csv -Path 'dar_ad.csv' -NoTypeInformation