## Iterate through $afile displaying values that also appear in $bfile
## afile = a CSV file with 1 column of data.
##          
## bfile = a CSV file with 1 column of data.

Param (
    [Parameter(mandatory = $true)]
    [String]$afile,
    [Parameter(mandatory = $true)]
    [String]$bfile
)
##print $afile and $bfile
echo "afile = $afile"
echo "bfile = $bfile"

##load afile and bfile into variables a and b with a stock header
$a = import-csv $afile -header sam
$b = import-csv $bfile -header sam

##tell 'em what you're gonna do
echo "[*]     Display entries in afile that also appear in bfile."

##then do it
##iterate through each in $a
##pipe $b through a where clause checking if any line matches the current line in $a
##if so, print the entry
foreach($line in $a) {
    $b | where {$_.sam -eq $line.sam} | % sam
}
