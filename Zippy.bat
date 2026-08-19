@echo off
mode 85,26
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Zippy Encrypter & Decrypter - By ItzBlobbo (Updated to v1.2)

:: ANSI escape character
for /F "delims=" %%e in ('echo prompt $E^| cmd') do set "ESC=%%e"

:: Forcefully delete old icon caches so Windows is forced to build the new orange one
powershell -NoProfile -Command "$old1 = \"$env:APPDATA\ZippyIcon.ico\"; $old2 = \"$env:APPDATA\ZippyIcon_Pix.ico\"; $old3 = \"$env:APPDATA\ZippyIcon_V3.ico\"; if (Test-Path $old1) { Remove-Item $old1 -Force }; if (Test-Path $old2) { Remove-Item $old2 -Force }; if (Test-Path $old3) { Remove-Item $old3 -Force }"

:: Generate Fresh Pixelated Orange Background & White 'Z' Icon
powershell -NoProfile -Command "Add-Type -AssemblyName System.Drawing; $path = \"$env:APPDATA\ZippyIcon_V2.ico\"; $bmp = New-Object System.Drawing.Bitmap 64, 64; $g = [System.Drawing.Graphics]::FromImage($bmp); $g.Clear([System.Drawing.Color]::Orange); $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White); $g.FillRectangle($brush, 12, 12, 40, 10); $g.FillRectangle($brush, 32, 22, 10, 10); $g.FillRectangle($brush, 22, 32, 10, 10); $g.FillRectangle($brush, 12, 42, 40, 10); $g.Dispose(); $hicon = $bmp.GetHicon(); $icon = [System.Drawing.Icon]::FromHandle($hicon); $fs = New-Object System.IO.FileStream($path, [System.IO.FileMode]::Create); $icon.Save($fs); $fs.Close(); $bmp.Dispose();"

:: Register .zippy extension and bind the brand-new icon path
reg add "HKCU\Software\Classes\.zippy" /ve /t REG_SZ /d "ZippyArchive" /f >nul 2>&1
reg add "HKCU\Software\Classes\ZippyArchive" /ve /t REG_SZ /d "Zippy Encrypted Archive" /f >nul 2>&1
reg add "HKCU\Software\Classes\ZippyArchive\DefaultIcon" /ve /t REG_SZ /d "%APPDATA%\ZippyIcon_V2.ico" /f >nul 2>&1

:: Force Windows Explorer to instantly refresh the icon cache
powershell -NoProfile -Command "Add-Type -MemberDefinition '[System.Runtime.InteropServices.DllImport(\"shell32.dll\")] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);' -Name 'Win32' -Namespace 'Shell'; [Shell.Win32]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero);"

:menu
cls
call :header
echo   [1] Encrypt ^& Compress File or Folder
echo   [2] Decrypt ^& Extract Custom Archive (.zippy)
echo   [3] View Archive Contents (View Tool)
echo   [4] Upgrade .zippy Files (v1.1 to v1.2)
echo   [5] Exit
echo.
echo ============================================================
echo.

choice /c 12345 /n /m "Select an option: "
if errorlevel 5 exit /b
if errorlevel 4 goto upgrade
if errorlevel 3 goto viewtool
if errorlevel 2 goto decrypt
if errorlevel 1 goto encrypt

:encrypt
cls
call :header
echo === ENCRYPT ^& COMPRESS ===
echo.
set /p "TARGET=Enter File or Folder Path: "
if not defined TARGET (
    echo.
    echo Error: Target path cannot be empty.
    pause
    goto menu
)
set "TARGET=!TARGET:"=!"
if "!TARGET:~-1!"=="\" set "TARGET=!TARGET:~0,-1!"

if not exist "!TARGET!" (
    echo.
    echo Error: Target path does not exist.
    pause
    goto menu
)

set /p "ALLOW_VIEW=Allow this archive to be previewed in the View Tool? (Y/N): "
if /i "!ALLOW_VIEW!"=="" set "ALLOW_VIEW=Y"

set /p "REQ_PASS=Enable password protection? (Y/N): "
if /i "!REQ_PASS!"=="Y" (
    set /p "PASS=Enter Encryption Password: "
    if "!PASS!"=="" (
        echo.
        echo Error: Password cannot be empty.
        pause
        goto menu
    )
) else (
    set "PASS=NONE"
)

set /p "OUTDIR=Enter Destination Folder Path: "
if not defined OUTDIR (
    echo.
    echo Error: Destination path cannot be empty.
    pause
    goto menu
)
set "OUTDIR=!OUTDIR:"=!"
if "!OUTDIR:~-1!"=="\" set "OUTDIR=!OUTDIR:~0,-1!"

echo.
echo Processing... Please wait.
call :loading_bar

if exist "%TEMP%\vault_res.txt" del "%TEMP%\vault_res.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($target, $pass, $outDir, $allowView); Add-Type -AssemblyName System.IO.Compression.FileSystem; if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }; $tempZip = [System.IO.Path]::Combine($outDir, [System.Guid]::NewGuid().ToString() + '.zip'); try { if (Test-Path -Path $target -PathType Container) { [System.IO.Compression.ZipFile]::CreateFromDirectory($target, $tempZip) } else { $archive = [System.IO.Compression.ZipFile]::Open($tempZip, 'Create'); [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $target, [System.IO.Path]::GetFileName($target)) | Out-Null; $archive.Dispose() }; if ($allowView -eq 'N') { $archive = [System.IO.Compression.ZipFile]::Open($tempZip, 'Update'); $archive.CreateEntry('_NOVIEW.flag') | Out-Null; $archive.Dispose() }; $outFile = [System.IO.Path]::Combine($outDir, [System.IO.Path]::GetFileName($target) + '.zippy'); $magic = [Text.Encoding]::ASCII.GetBytes('ZIPPY'); $ver = [byte]2; if ($pass -eq 'NONE') { $encFlag = [byte]0; $fsOut = New-Object System.IO.FileStream($outFile, [System.IO.FileMode]::Create); $fsOut.Write($magic, 0, 5); $fsOut.WriteByte($ver); $fsOut.WriteByte($encFlag); $zipBytes = [System.IO.File]::ReadAllBytes($tempZip); $fsOut.Write($zipBytes, 0, $zipBytes.Length); $fsOut.Position = 0; $sha = [System.Security.Cryptography.SHA256]::Create(); $hash = $sha.ComputeHash($fsOut); $fsOut.Position = $fsOut.Length; $fsOut.Write($hash, 0, 32); $fsOut.Close() } else { $encFlag = [byte]1; $salt = New-Object byte[](16); $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider; $rng.GetBytes($salt); $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($pass, $salt, 100000); $keys = $derive.GetBytes(64); $aesKey = $keys[0..31]; $hmacKey = $keys[32..63]; $aes = [System.Security.Cryptography.Aes]::Create(); $aes.Key = $aesKey; $aes.GenerateIV(); $fsOut = New-Object System.IO.FileStream($outFile, [System.IO.FileMode]::Create); $fsOut.Write($magic, 0, 5); $fsOut.WriteByte($ver); $fsOut.WriteByte($encFlag); $fsOut.Write($salt, 0, 16); $fsOut.Write($aes.IV, 0, 16); $fsIn = New-Object System.IO.FileStream($tempZip, [System.IO.FileMode]::Open); $cs = New-Object System.Security.Cryptography.CryptoStream($fsOut, $aes.CreateEncryptor(), [System.Security.Cryptography.CryptoStreamMode]::Write); $fsIn.CopyTo($cs); $fsIn.Close(); $cs.FlushFinalBlock(); $cs.Close(); $fsOutMac = New-Object System.IO.FileStream($outFile, [System.IO.FileMode]::Open); $hmac = New-Object System.Security.Cryptography.HMACSHA256; $hmac.Key = $hmacKey; $hash = $hmac.ComputeHash($fsOutMac); $fsOutMac.Position = $fsOutMac.Length; $fsOutMac.Write($hash, 0, 32); $fsOutMac.Close() }; Remove-Item $tempZip -Force -ErrorAction SilentlyContinue; Write-Output ('SUCCESS|' + $outFile) } catch { Write-Output ('ERROR:' + $_.Exception.Message) } }" "!TARGET!" "!PASS!" "!OUTDIR!" "!ALLOW_VIEW!" > "%TEMP%\vault_res.txt" 2>&1

set "RES="
if exist "%TEMP%\vault_res.txt" (
    set /p RES=<"%TEMP%\vault_res.txt"
    del "%TEMP%\vault_res.txt"
)

if defined RES (
    if "!RES:~0,7!"=="SUCCESS" (
        set "FINAL_OUT=!RES:~8!"
        echo.
        echo Finished^! Vault archive created at:
        echo "!FINAL_OUT!"
    ) else (
        echo.
        echo Failed to encrypt^! 
        echo !RES!
    )
) else (
    echo.
    echo Failed to encrypt^! Process terminated unexpectedly.
)

echo.
pause
goto menu

:decrypt
cls
call :header
echo === DECRYPT ^& EXTRACT ===
echo.
set /p "TARGET=Enter .zippy File Path: "
if not defined TARGET (
    echo.
    echo Error: Target path cannot be empty.
    pause
    goto menu
)
set "TARGET=!TARGET:"=!"
if "!TARGET:~-1!"=="\" set "TARGET=!TARGET:~0,-1!"

if not exist "!TARGET!" (
    echo.
    echo Error: File does not exist.
    pause
    goto menu
)

:: Validate Zippy Format & Encryption State
powershell -NoProfile -Command "$fs = New-Object System.IO.FileStream('!TARGET!', [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read); if ($fs.Length -lt 40) { $fs.Close(); Write-Output 'LEGACY'; exit }; $magic = New-Object byte[](5); $fs.Read($magic, 0, 5) | Out-Null; $magicStr = [Text.Encoding]::ASCII.GetString($magic); if ($magicStr -ne 'ZIPPY') { $fs.Close(); Write-Output 'LEGACY' } else { $ver = $fs.ReadByte(); $enc = $fs.ReadByte(); $fs.Close(); if ($ver -ne 2) { Write-Output 'UNSUPPORTED' } elseif ($enc -eq 1) { Write-Output 'ENCRYPTED' } else { Write-Output 'UNENCRYPTED' } }" > "%TEMP%\vault_check.txt"
set /p CHECK=<"%TEMP%\vault_check.txt"
del "%TEMP%\vault_check.txt"

if "!CHECK!"=="LEGACY" (
    echo.
    echo ERROR: This archive is a v1.1 legacy file. Please use Option [4] Upgrade to update it to v1.2 first!
    pause
    goto menu
)
if "!CHECK!"=="UNSUPPORTED" (
    echo.
    echo ERROR: Unsupported Zippy format version.
    pause
    goto menu
)

if "!CHECK!"=="ENCRYPTED" (
    set /p "PASS=Enter Password: "
    if "!PASS!"=="" (
        echo.
        echo Error: Password cannot be empty.
        pause
        goto menu
    )
) else (
    set "PASS=NONE"
)

set /p "OUTDIR=Enter Destination Folder Path: "
if not defined OUTDIR (
    echo.
    echo Error: Destination path cannot be empty.
    pause
    goto menu
)
set "OUTDIR=!OUTDIR:"=!"
if "!OUTDIR:~-1!"=="\" set "OUTDIR=!OUTDIR:~0,-1!"

echo.
echo Authenticating and Extracting... Please wait.
call :loading_bar

if exist "%TEMP%\vault_res.txt" del "%TEMP%\vault_res.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($vault, $pass, $outDir); Add-Type -AssemblyName System.IO.Compression.FileSystem; $tempZip = [System.IO.Path]::Combine($env:TEMP, [System.Guid]::NewGuid().ToString() + '.zip'); try { $fsIn = New-Object System.IO.FileStream($vault, [System.IO.FileMode]::Open); $magic = New-Object byte[](5); $fsIn.Read($magic, 0, 5) | Out-Null; $ver = $fsIn.ReadByte(); $encFlag = $fsIn.ReadByte(); $tag = New-Object byte[](32); $fsIn.Position = $fsIn.Length - 32; $fsIn.Read($tag, 0, 32) | Out-Null; $fsIn.Position = 0; if ($encFlag -eq 0) { $sha = [System.Security.Cryptography.SHA256]::Create(); $dataToHash = New-Object byte[]($fsIn.Length - 32); $fsIn.Read($dataToHash, 0, $dataToHash.Length) | Out-Null; $computedTag = $sha.ComputeHash($dataToHash); for($i=0;$i-lt 32;$i++){ if($tag[$i] -ne $computedTag[$i]) { throw 'Archive has been modified or corrupted.' } }; $fsOut = New-Object System.IO.FileStream($tempZip, [System.IO.FileMode]::Create); $fsOut.Write($dataToHash, 7, $dataToHash.Length - 7); $fsOut.Close(); $fsIn.Close() } else { $fsIn.Position = 7; $salt = New-Object byte[](16); $fsIn.Read($salt, 0, 16) | Out-Null; $iv = New-Object byte[](16); $fsIn.Read($iv, 0, 16) | Out-Null; $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($pass, $salt, 100000); $keys = $derive.GetBytes(64); $aesKey = $keys[0..31]; $hmacKey = $keys[32..63]; $hmac = New-Object System.Security.Cryptography.HMACSHA256; $hmac.Key = $hmacKey; $dataToHash = New-Object byte[]($fsIn.Length - 32); $fsIn.Position = 0; $fsIn.Read($dataToHash, 0, $dataToHash.Length) | Out-Null; $computedTag = $hmac.ComputeHash($dataToHash); for($i=0;$i-lt 32;$i++){ if($tag[$i] -ne $computedTag[$i]) { throw 'Authentication failed. Wrong password or archive has been modified/corrupted.' } }; $aes = [System.Security.Cryptography.Aes]::Create(); $aes.Key = $aesKey; $aes.IV = $iv; $fsIn.Position = 39; $cipherLen = $fsIn.Length - 39 - 32; $cipherData = New-Object byte[]($cipherLen); $fsIn.Read($cipherData, 0, $cipherLen) | Out-Null; $fsIn.Close(); $msIn = New-Object System.IO.MemoryStream; $msIn.Write($cipherData, 0, $cipherData.Length); $msIn.Position = 0; $fsOut = New-Object System.IO.FileStream($tempZip, [System.IO.FileMode]::Create); $cs = New-Object System.Security.Cryptography.CryptoStream($msIn, $aes.CreateDecryptor(), [System.Security.Cryptography.CryptoStreamMode]::Read); $cs.CopyTo($fsOut); $fsOut.Close(); $cs.Close(); $msIn.Close() }; $baseName = [System.IO.Path]::GetFileNameWithoutExtension($vault); $finalOutDir = [System.IO.Path]::Combine($outDir, $baseName); if (-not (Test-Path $finalOutDir)) { New-Item -ItemType Directory -Path $finalOutDir -Force | Out-Null }; [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $finalOutDir); Remove-Item (Join-Path $finalOutDir '_NOVIEW.flag') -Force -ErrorAction SilentlyContinue; Remove-Item $tempZip -Force -ErrorAction SilentlyContinue; Write-Output ('SUCCESS|' + $finalOutDir) } catch { Write-Output ('ERROR: ' + $_.Exception.Message); if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue } } }" "!TARGET!" "!PASS!" "!OUTDIR!" > "%TEMP%\vault_res.txt" 2>&1

set "RES="
if exist "%TEMP%\vault_res.txt" (
    set /p RES=<"%TEMP%\vault_res.txt"
    del "%TEMP%\vault_res.txt"
)

if defined RES (
    if "!RES:~0,7!"=="SUCCESS" (
        set "FINAL_OUT=!RES:~8!"
        echo.
        echo Finished^! Files extracted to:
        echo "!FINAL_OUT!"
    ) else (
        echo.
        echo Extraction failed^!
        echo !RES!
    )
) else (
    echo.
    echo Extraction failed^! Process terminated unexpectedly.
)

echo.
pause
goto menu

:viewtool
cls
call :header
echo === VIEW ARCHIVE CONTENTS ===
echo.
set /p "TARGET=Enter .zippy File Path: "
if not defined TARGET (
    echo.
    echo Error: Target path cannot be empty.
    pause
    goto menu
)
set "TARGET=!TARGET:"=!"
if "!TARGET:~-1!"=="\" set "TARGET=!TARGET:~0,-1!"

if not exist "!TARGET!" (
    echo.
    echo Error: File does not exist.
    pause
    goto menu
)

:: Validate Zippy Format & Encryption State
powershell -NoProfile -Command "$fs = New-Object System.IO.FileStream('!TARGET!', [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read); if ($fs.Length -lt 40) { $fs.Close(); Write-Output 'LEGACY'; exit }; $magic = New-Object byte[](5); $fs.Read($magic, 0, 5) | Out-Null; $magicStr = [Text.Encoding]::ASCII.GetString($magic); if ($magicStr -ne 'ZIPPY') { $fs.Close(); Write-Output 'LEGACY' } else { $ver = $fs.ReadByte(); $enc = $fs.ReadByte(); $fs.Close(); if ($ver -ne 2) { Write-Output 'UNSUPPORTED' } elseif ($enc -eq 1) { Write-Output 'ENCRYPTED' } else { Write-Output 'UNENCRYPTED' } }" > "%TEMP%\vault_check.txt"
set /p CHECK=<"%TEMP%\vault_check.txt"
del "%TEMP%\vault_check.txt"

if "!CHECK!"=="LEGACY" (
    echo.
    echo ERROR: This archive is a v1.1 legacy file. Please upgrade it to v1.2 using Option [4] first!
    pause
    goto menu
)
if "!CHECK!"=="UNSUPPORTED" (
    echo.
    echo ERROR: Unsupported Zippy format version.
    pause
    goto menu
)

if "!CHECK!"=="ENCRYPTED" (
    echo [Archive is Password Protected]
    set /p "PASS=Enter Password to view: "
    if "!PASS!"=="" (
        echo.
        echo Error: Password cannot be empty.
        pause
        goto menu
    )
) else (
    set "PASS=NONE"
    echo [Archive is Unlocked - No Password Required]
)

echo.
echo Authenticating and Reading contents...
echo ------------------------------------------------------------

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($vault, $pass); Add-Type -AssemblyName System.IO.Compression.FileSystem; $tempZip = [System.IO.Path]::Combine($env:TEMP, [System.Guid]::NewGuid().ToString() + '.zip'); try { $fsIn = New-Object System.IO.FileStream($vault, [System.IO.FileMode]::Open); $magic = New-Object byte[](5); $fsIn.Read($magic, 0, 5) | Out-Null; $ver = $fsIn.ReadByte(); $encFlag = $fsIn.ReadByte(); $tag = New-Object byte[](32); $fsIn.Position = $fsIn.Length - 32; $fsIn.Read($tag, 0, 32) | Out-Null; $fsIn.Position = 0; if ($encFlag -eq 0) { $sha = [System.Security.Cryptography.SHA256]::Create(); $dataToHash = New-Object byte[]($fsIn.Length - 32); $fsIn.Read($dataToHash, 0, $dataToHash.Length) | Out-Null; $computedTag = $sha.ComputeHash($dataToHash); for($i=0;$i-lt 32;$i++){ if($tag[$i] -ne $computedTag[$i]) { throw 'Archive has been modified or corrupted.' } }; $fsOut = New-Object System.IO.FileStream($tempZip, [System.IO.FileMode]::Create); $fsOut.Write($dataToHash, 7, $dataToHash.Length - 7); $fsOut.Close(); $fsIn.Close() } else { $fsIn.Position = 7; $salt = New-Object byte[](16); $fsIn.Read($salt, 0, 16) | Out-Null; $iv = New-Object byte[](16); $fsIn.Read($iv, 0, 16) | Out-Null; $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($pass, $salt, 100000); $keys = $derive.GetBytes(64); $aesKey = $keys[0..31]; $hmacKey = $keys[32..63]; $hmac = New-Object System.Security.Cryptography.HMACSHA256; $hmac.Key = $hmacKey; $dataToHash = New-Object byte[]($fsIn.Length - 32); $fsIn.Position = 0; $fsIn.Read($dataToHash, 0, $dataToHash.Length) | Out-Null; $computedTag = $hmac.ComputeHash($dataToHash); for($i=0;$i-lt 32;$i++){ if($tag[$i] -ne $computedTag[$i]) { throw 'Authentication failed. Wrong password or archive has been modified/corrupted.' } }; $aes = [System.Security.Cryptography.Aes]::Create(); $aes.Key = $aesKey; $aes.IV = $iv; $fsIn.Position = 39; $cipherLen = $fsIn.Length - 39 - 32; $cipherData = New-Object byte[]($cipherLen); $fsIn.Read($cipherData, 0, $cipherLen) | Out-Null; $fsIn.Close(); $msIn = New-Object System.IO.MemoryStream; $msIn.Write($cipherData, 0, $cipherData.Length); $msIn.Position = 0; $fsOut = New-Object System.IO.FileStream($tempZip, [System.IO.FileMode]::Create); $cs = New-Object System.Security.Cryptography.CryptoStream($msIn, $aes.CreateDecryptor(), [System.Security.Cryptography.CryptoStreamMode]::Read); $cs.CopyTo($fsOut); $fsOut.Close(); $cs.Close(); $msIn.Close() }; $zip = [System.IO.Compression.ZipFile]::OpenRead($tempZip); $noview = $zip.GetEntry('_NOVIEW.flag'); if ($null -ne $noview) { Write-Output 'DENIED: The creator disabled viewing for this archive.' } else { Write-Output '|'; foreach ($entry in $zip.Entries) { if ($entry.Name -ne '_NOVIEW.flag') { Write-Output ('|_ ' + $entry.FullName) } } }; $zip.Dispose(); Remove-Item $tempZip -Force -ErrorAction SilentlyContinue } catch { Write-Output ('ERROR: ' + $_.Exception.Message); if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue } } }" "!TARGET!" "!PASS!"

echo ------------------------------------------------------------
echo.
pause
goto menu

:upgrade
cls
call :header
echo === UPGRADE .ZIPPY FILE (v1.1 to v1.2) ===
echo.
set /p "TARGET=Enter v1.1 .zippy File Path: "
if not defined TARGET (
    echo.
    echo Error: Target path cannot be empty.
    pause
    goto menu
)
set "TARGET=!TARGET:"=!"
if "!TARGET:~-1!"=="\" set "TARGET=!TARGET:~0,-1!"

if not exist "!TARGET!" (
    echo.
    echo Error: File does not exist.
    pause
    goto menu
)

echo.
echo [Authentication Required]
set /p "OLD_PASS=Enter ORIGINAL Password to unlock (leave blank if unencrypted): "

if not "!OLD_PASS!"=="" (
    echo.
    set /p "NEW_PASS=Enter NEW Password for v1.2 archive (leave blank to keep original): "
    if "!NEW_PASS!"=="" set "NEW_PASS=!OLD_PASS!"
) else (
    set "NEW_PASS="
)

echo.
set /p "OUTDIR=Enter Destination Folder Path: "
if not defined OUTDIR (
    echo.
    echo Error: Destination path cannot be empty.
    pause
    goto menu
)
set "OUTDIR=!OUTDIR:"=!"
if "!OUTDIR:~-1!"=="\" set "OUTDIR=!OUTDIR:~0,-1!"

echo.
echo Upgrading archive format... Please wait.
call :loading_bar

if exist "%TEMP%\vault_res.txt" del "%TEMP%\vault_res.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($vault, $oldPass, $newPass, $outDir); $ErrorActionPreference = 'Stop'; try { if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }; $bytes = [System.IO.File]::ReadAllBytes($vault); if ($bytes.Length -lt 10) { throw 'File is too small to be a valid archive.' }; $zipBytes = $null; $isEncrypted = $false; $magicStr = [Text.Encoding]::ASCII.GetString($bytes[0..4]); if ($bytes[0] -eq 80 -and $bytes[1] -eq 75) { $zipBytes = $bytes; $isEncrypted = $false } elseif ($magicStr -eq 'ZIPPY') { $ver = $bytes[5]; if ($ver -eq 2) { throw 'This archive is already version 1.2.' }; if ($ver -eq 1) { $enc = $bytes[6]; if ($enc -eq 0) { $zipBytes = $bytes[7..($bytes.Length-1)]; $isEncrypted = $false } else { $isEncrypted = $true; if ([string]::IsNullOrEmpty($oldPass)) { throw 'Original password is required to unlock this v1.1 archive.' }; $salt = $bytes[7..22]; $iv = $bytes[23..38]; $cipherData = $bytes[39..($bytes.Length-1)]; $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($oldPass, $salt, 100000); $keys = $derive.GetBytes(64); $aesKey = $keys[0..31]; $aes = [System.Security.Cryptography.Aes]::Create(); $aes.Key = $aesKey; $aes.IV = $iv; $msIn = New-Object System.IO.MemoryStream; $msIn.Write($cipherData, 0, $cipherData.Length); $msIn.Position = 0; $msOut = New-Object System.IO.MemoryStream; $cs = New-Object System.Security.Cryptography.CryptoStream($msIn, $aes.CreateDecryptor(), [System.Security.Cryptography.CryptoStreamMode]::Read); $cs.CopyTo($msOut); $cs.Close(); $msIn.Close(); $zipBytes = $msOut.ToArray(); $msOut.Close() } } else { throw 'Unknown archive version.' } } else { $isEncrypted = $true; if ([string]::IsNullOrEmpty($oldPass)) { throw 'Original password required for headerless legacy archive.' }; $salt = $bytes[0..15]; $iv = $bytes[16..31]; $cipherData = $bytes[32..($bytes.Length-1)]; $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($oldPass, $salt, 100000); $keys = $derive.GetBytes(64); $aesKey = $keys[0..31]; $aes = [System.Security.Cryptography.Aes]::Create(); $aes.Key = $aesKey; $aes.IV = $iv; $msIn = New-Object System.IO.MemoryStream; $msIn.Write($cipherData, 0, $cipherData.Length); $msIn.Position = 0; $msOut = New-Object System.IO.MemoryStream; try { $cs = New-Object System.Security.Cryptography.CryptoStream($msIn, $aes.CreateDecryptor(), [System.Security.Cryptography.CryptoStreamMode]::Read); $cs.CopyTo($msOut); $cs.Close(); } catch { throw 'Incorrect password or corrupted legacy data stream.' }; $msIn.Close(); $zipBytes = $msOut.ToArray(); $msOut.Close() }; $name = [System.IO.Path]::GetFileNameWithoutExtension($vault); $newOut = [System.IO.Path]::Combine($outDir, $name + '_v1.2.zippy'); $magic = [Text.Encoding]::ASCII.GetBytes('ZIPPY'); $newVer = [byte]2; if (-not $isEncrypted) { $encFlag = [byte]0; $fsOut = New-Object System.IO.FileStream($newOut, [System.IO.FileMode]::Create); $fsOut.Write($magic, 0, 5); $fsOut.WriteByte($newVer); $fsOut.WriteByte($encFlag); $fsOut.Write($zipBytes, 0, $zipBytes.Length); $fsOut.Position = 0; $sha = [System.Security.Cryptography.SHA256]::Create(); $hash = $sha.ComputeHash($fsOut); $fsOut.Position = $fsOut.Length; $fsOut.Write($hash, 0, 32); $fsOut.Close() } else { $encFlag = [byte]1; $salt = New-Object byte[](16); $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider; $rng.GetBytes($salt); $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($newPass, $salt, 100000); $keys = $derive.GetBytes(64); $aesKey = $keys[0..31]; $hmacKey = $keys[32..63]; $aes = [System.Security.Cryptography.Aes]::Create(); $aes.Key = $aesKey; $aes.GenerateIV(); $fsOut = New-Object System.IO.FileStream($newOut, [System.IO.FileMode]::Create); $fsOut.Write($magic, 0, 5); $fsOut.WriteByte($newVer); $fsOut.WriteByte($encFlag); $fsOut.Write($salt, 0, 16); $fsOut.Write($aes.IV, 0, 16); $msZip = New-Object System.IO.MemoryStream; $msZip.Write($zipBytes, 0, $zipBytes.Length); $msZip.Position = 0; $cs = New-Object System.Security.Cryptography.CryptoStream($fsOut, $aes.CreateEncryptor(), [System.Security.Cryptography.CryptoStreamMode]::Write); $msZip.CopyTo($cs); $msZip.Close(); $cs.FlushFinalBlock(); $cs.Close(); $fsOutMac = New-Object System.IO.FileStream($newOut, [System.IO.FileMode]::Open); $hmac = New-Object System.Security.Cryptography.HMACSHA256; $hmac.Key = $hmacKey; $hash = $hmac.ComputeHash($fsOutMac); $fsOutMac.Position = $fsOutMac.Length; $fsOutMac.Write($hash, 0, 32); $fsOutMac.Close() }; Write-Output ('SUCCESS|' + $newOut) } catch { Write-Output ('ERROR: ' + $_.Exception.Message) } }" "!TARGET!" "!OLD_PASS!" "!NEW_PASS!" "!OUTDIR!" > "%TEMP%\vault_res.txt" 2>&1

set "RES="
if exist "%TEMP%\vault_res.txt" (
    set /p RES=<"%TEMP%\vault_res.txt"
    del "%TEMP%\vault_res.txt"
)

if defined RES (
    if "!RES:~0,7!"=="SUCCESS" (
        set "FINAL_OUT=!RES:~8!"
        echo.
        echo Finished^! Upgraded archive created as:
        echo "!FINAL_OUT!"
    ) else (
        echo.
        echo Upgrade failed^!
        echo !RES!
    )
) else (
    echo.
    echo Upgrade failed^! Process terminated unexpectedly.
)

echo.
pause
goto menu
:header
echo.
echo %ESC%[38;5;166m ███████╗██╗██████╗ ██████╗ ██╗   ██╗
echo %ESC%[38;5;172m ╚══███╔╝██║██╔══██╗██╔══██╗╚██╗ ██╔╝
echo %ESC%[38;5;173m   ███╔╝ ██║██████╔╝██████╔╝ ╚████╔╝
echo %ESC%[38;5;208m  ███╔╝  ██║██╔═══╝ ██╔═══╝   ╚██╔╝
echo %ESC%[38;5;209m ███████╗██║██║     ██║        ██║
echo %ESC%[38;5;215m ╚══════╝╚═╝╚═╝     ╚═╝        ╚═╝
echo %ESC%[38;5;215m --------------v1.2--------------
echo %ESC%[0m
echo.
exit /b

:loading_bar
<nul set /p="%ESC%[38;5;166m["
for %%C in (166 172 173 208 209 215) do (
    <nul set /p="%ESC%[38;5;%%Cm█████"
    powershell -nop -c "Start-Sleep -Milliseconds 150"
)
echo %ESC%[0m]
echo.
exit /b