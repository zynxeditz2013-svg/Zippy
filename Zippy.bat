@echo off
mode 85,26
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Zippy Encrypter & Decrypter - By ItzBlobbo

:: ANSI escape character
for /F "delims=" %%e in ('echo prompt $E^| cmd') do set "ESC=%%e"

:: Forcefully delete old icon caches so Windows is forced to build the new orange one
powershell -NoProfile -Command "$old1 = \"$env:APPDATA\ZippyIcon.ico\"; $old2 = \"$env:APPDATA\ZippyIcon_Pix.ico\"; if (Test-Path $old1) { Remove-Item $old1 -Force }; if (Test-Path $old2) { Remove-Item $old2 -Force }"

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
echo   [3] Exit
echo.
echo ============================================================
echo.

choice /c 123 /n /m "Select an option: "
if errorlevel 3 exit /b
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
:: Remove quotation marks and trailing backslashes
set "TARGET=!TARGET:"=!"
if "!TARGET:~-1!"=="\" set "TARGET=!TARGET:~0,-1!"

if not exist "!TARGET!" (
    echo.
    echo Error: Target path does not exist.
    pause
    goto menu
)

set /p "PASS=Enter Encryption Password: "
if "!PASS!"=="" (
    echo.
    echo Error: Password cannot be empty.
    pause
    goto menu
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
echo Compressing and encrypting... Please wait.
call :loading_bar

if exist "%TEMP%\vault_res.txt" del "%TEMP%\vault_res.txt"

:: Process large files safely by keeping temp files in the output directory
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($target, $pass, $outDir); Add-Type -AssemblyName System.IO.Compression.FileSystem; if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }; $tempZip = [System.IO.Path]::Combine($outDir, [System.Guid]::NewGuid().ToString() + '.zip'); try { if (Test-Path -Path $target -PathType Container) { [System.IO.Compression.ZipFile]::CreateFromDirectory($target, $tempZip) } else { $archive = [System.IO.Compression.ZipFile]::Open($tempZip, 'Create'); [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $target, [System.IO.Path]::GetFileName($target)); $archive.Dispose() }; $salt = New-Object byte[](16); $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider; $rng.GetBytes($salt); $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($pass, $salt, 10000); $aes = [System.Security.Cryptography.Aes]::Create(); $aes.Key = $derive.GetBytes(32); $aes.GenerateIV(); $outFile = [System.IO.Path]::Combine($outDir, [System.IO.Path]::GetFileName($target) + '.zippy'); $fsOut = New-Object System.IO.FileStream($outFile, [System.IO.FileMode]::Create); $fsOut.Write($salt, 0, 16); $fsOut.Write($aes.IV, 0, 16); $cs = New-Object System.Security.Cryptography.CryptoStream($fsOut, $aes.CreateEncryptor(), [System.Security.Cryptography.CryptoStreamMode]::Write); $fsIn = New-Object System.IO.FileStream($tempZip, [System.IO.FileMode]::Open); $fsIn.CopyTo($cs); $fsIn.Close(); $cs.FlushFinalBlock(); $cs.Close(); $fsOut.Close(); Remove-Item $tempZip -Force -ErrorAction SilentlyContinue; Write-Host ('SUCCESS|' + $outFile) } catch { Write-Host ('ERROR:' + $_.Exception.Message) } }" "!TARGET!" "!PASS!" "!OUTDIR!" > "%TEMP%\vault_res.txt" 2>&1

set "RES="
if exist "%TEMP%\vault_res.txt" (
    set /p RES=<"%TEMP%\vault_res.txt"
    del "%TEMP%\vault_res.txt"
)

if defined RES (
    if "!RES:~0,7!"=="SUCCESS" (
        set "FINAL_OUT=!RES:~8!"
        echo.
        echo Finished! Vault archive created at:
        echo "!FINAL_OUT!"
    ) else (
        echo.
        echo Failed to encrypt! 
        echo !RES!
    )
) else (
    echo.
    echo Failed to encrypt! Process terminated unexpectedly.
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

set /p "PASS=Enter Password: "
if "!PASS!"=="" (
    echo.
    echo Error: Password cannot be empty.
    pause
    goto menu
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
echo Decrypting and extracting... Please wait.
call :loading_bar

if exist "%TEMP%\vault_res.txt" del "%TEMP%\vault_res.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($vault, $pass, $outDir); Add-Type -AssemblyName System.IO.Compression.FileSystem; if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }; $tempZip = [System.IO.Path]::Combine($outDir, [System.Guid]::NewGuid().ToString() + '.zip'); try { $fsIn = New-Object System.IO.FileStream($vault, [System.IO.FileMode]::Open); $salt = New-Object byte[](16); $fsIn.Read($salt, 0, 16) | Out-Null; $iv = New-Object byte[](16); $fsIn.Read($iv, 0, 16) | Out-Null; $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($pass, $salt, 10000); $aes = [System.Security.Cryptography.Aes]::Create(); $aes.Key = $derive.GetBytes(32); $aes.IV = $iv; $cs = New-Object System.Security.Cryptography.CryptoStream($fsIn, $aes.CreateDecryptor(), [System.Security.Cryptography.CryptoStreamMode]::Read); $fsOut = New-Object System.IO.FileStream($tempZip, [System.IO.FileMode]::Create); $cs.CopyTo($fsOut); $fsOut.Close(); $cs.Close(); $fsIn.Close(); [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $outDir); Remove-Item $tempZip -Force -ErrorAction SilentlyContinue; Write-Host 'SUCCESS' } catch { Write-Host ('ERROR:' + $_.Exception.Message) } }" "!TARGET!" "!PASS!" "!OUTDIR!" > "%TEMP%\vault_res.txt" 2>&1

set "RES="
if exist "%TEMP%\vault_res.txt" (
    set /p RES=<"%TEMP%\vault_res.txt"
    del "%TEMP%\vault_res.txt"
)

if defined RES (
    if "!RES:~0,7!"=="SUCCESS" (
        echo.
        echo Finished! Files extracted to:
        echo "!OUTDIR!"
    ) else (
        echo.
        echo Decryption failed!
        echo !RES!
    )
) else (
    echo.
    echo Decryption failed! Process terminated unexpectedly.
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