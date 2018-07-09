## Lookup relevant account information based on username.
## Infile = a CSV file with a column named "email" that contains an e-mail address.
##          
## Outfile = path to an output CSV that will contain the AD lookup info.

Param (
    [Parameter(mandatory = $true)]
    [String]$infile,
    [Parameter(mandatory = $true)]
    [String]$outfile
)
echo "Infile = $infile"
echo "Outfile = $outfile"
$emaillist = import-csv $infile              ## read infile into buffer

echo "[*]     Lookup Name, SamAccountName,Department,Title Based on *email*"

#loop through each line in the 'email' column of the imported csv
#$e = an individual e-mail address, corresponding to 1 line of the csv
#if $e is not null, use Get-ADUser cmdlet to look up desired fields based on $e = EmailAddress and append it to outfile
foreach($email in $emaillist) {
    $e = $email.email
    if ($e) {
        Get-ADUser -Filter "EmailAddress -Like '*$e*'" -Properties Name,SamAccountName,Department,Title | Select-Object -Property Name,SamAccountName,Department,Title | Export-Csv -Path $outfile -notype -append
    }
}
