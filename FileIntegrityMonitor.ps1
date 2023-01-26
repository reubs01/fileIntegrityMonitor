Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-If-Already-Exists() {
    $baselineExists = Test-Path -Path .\baseline.txt
    #Checking if baseline exists

    if ($baselineExists) {
    #Delete it (if true)
    Remove-Item -Path .\baseline.txt
    }
}

Write-Host ""
Write-Host "What would you like to do?"
Write-Host ""
Write-Host "A) Collect new baseline?"
Write-Host "B) Begin monitoring files with saved baseline?"
Write-Host ""

$response = Read-Host -Prompt "Please enter 'A' or 'B'"
Write-Host ""


if ($response -eq "A".ToUpper()) {
    #Delete baseline if it already exists
    Erase-Baseline-If-Already-Exists

    #Calculate hash from the target files and store in baseline.txt
    
    #Collect all files in the target folder

    

    $files = Get-ChildItem -Path .\test_files

    #For each file, calculate the hash, and write to baseline.txt (creating the new baseline)

    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-file -FilePath .\baseline.txt -Append
    }
}


elseif ($response -eq "B".ToUpper()) {

    $fileHashDictionary = @{}

    #Load file|hash from baseline.txt and store them in a dictionary

    $filePathsAndHashes = Get-Content -Path .\baseline.txt
    
    foreach ($f in $filePathsAndHashes) {
        $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1]) 
    }
    

    #Begin (continously) monitoring files with the saved baseline

    while ($true) {
        Start-Sleep -Seconds 5
        
        $files = Get-ChildItem -Path .\test_files

        #For each file, calculate the hash, and write to baseline.txt
        foreach ($f in $files) {

            $hash = Calculate-File-Hash $f.FullName
            #"$($hash.Path)|$($hash.Hash)" | Out-file -FilePath .\test_files\baseline.txt -Append

            #Notify if a new file has been created
            if ($fileHashDictionary[$hash.Path] -eq $null) {

                #A new file has been created (that does not exist in the dictionary)!
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green

            }
            else {

                #Notify if a new file has been changed
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {

                    #The file has not changed
                }
                else {
                    #The file has been comprimised, notify the user
                    Write-Host "$($hash.Path) has changed" -ForegroundColor Yellow
                }
            }
        }

        foreach ($key in $fileHashDictionary.Keys) {
            $baseLineFileStillExists = Test-Path -Path $key
            if (-Not $baseLineFileStillExists) {
                #One of the baseline files must have been deleted. Notify the user
                Write-Host "$($key) has been deleted" -ForegroundColor Red
            }
        }
    }
}
