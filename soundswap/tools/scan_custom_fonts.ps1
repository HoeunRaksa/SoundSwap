Add-Type -AssemblyName PresentationCore

$fontsDirs = @(
    "C:\Users\hoeun\AppData\Local\Microsoft\Windows\Fonts",
    "C:\Windows\Fonts"
)

$results = @()
$seenFamilies = @{}

foreach ($dir in $fontsDirs) {
    if (Test-Path $dir) {
        $files = Get-ChildItem -Path $dir -Include *.ttf,*.otf -Recurse -File
        foreach ($file in $files) {
            try {
                $font = New-Object System.Windows.Media.GlyphTypeface($file.FullName)
                
                $family = ""
                foreach ($k in $font.Win32FamilyNames.Keys) {
                    if ($k.Language -eq "en-us" -or $k.Language -eq "en-US" -or $k.IetfLanguageTag -eq "en-US") {
                        $family = $font.Win32FamilyNames[$k]
                        break
                    }
                }
                if ($family -eq "") {
                    foreach ($k in $font.Win32FamilyNames.Keys) {
                        $family = $font.Win32FamilyNames[$k]
                        break
                    }
                }
                
                $weightStr = $font.Weight.ToString()
                $styleStr = $font.Style.ToString()

                # Determine if we should include it
                $isCustom = ($dir -like "*AppData*")
                $isKhmer = ($family -match "(?i)(Khmer|AKbalthom|SN Kh|Siemreap|Taprom|Battambang|Moul|Hanuman|Suwannaphum|Kantumruy|Preahvihear|Fasthand|Kdam Thmor|Bokor|Chenla|Metal|Angkor|Odor Mean Chey|Dangrek|Content|Freesia|Koulen|Krona One|Nokora|Bayon)")
                
                if ($isCustom -or $isKhmer) {
                    # Skip common system fonts that end up in AppData for some reason (if any)
                    $skip = $false
                    $sysFonts = "Arial", "Calibri", "Segoe UI", "Times New Roman", "Consolas", "Courier New", "Tahoma", "Verdana", "Microsoft Sans Serif", "Malgun Gothic"
                    foreach ($sys in $sysFonts) {
                        if ($family -eq $sys) { $skip = $true }
                    }
                    if (-not $skip) {
                        $results += @{
                            path = $file.FullName
                            fileName = $file.Name
                            family = $family
                            weight = $weightStr
                            style = $styleStr
                        }
                    }
                }
            } catch {
                # Ignore errors reading file
            }
        }
    }
}

$results | ConvertTo-Json -Depth 3 | Out-File -FilePath "D:\SoundSwap\soundswap\tools\scanned_fonts.json" -Encoding utf8
