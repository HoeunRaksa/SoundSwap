param([string]$fontPath)
Add-Type -AssemblyName PresentationCore
try {
    $font = New-Object System.Windows.Media.GlyphTypeface($fontPath)
    $family = ""
    $weight = $font.Weight.ToString()
    $style = $font.Style.ToString()
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
    
    $obj = @{
        path = $fontPath
        family = $family
        weight = $weight
        style = $style
    }
    $obj | ConvertTo-Json
} catch {
    # Ignore errors
}
