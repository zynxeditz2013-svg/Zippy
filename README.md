# Zippy 1.1
![Alt Text](https://i.postimg.cc/hj9GvzvC/Screenshot-2026-08-19-082156.png)
Zippy is a Script Made by ItzBlobbo that runs in your terminal which can encrypt anything into a .zippy file which cannot be opened or extracted by any other app only zippy has the ability to Decrypt it with the correct password. Making protective file sharing easier and more secure.

# How to Install?
Simply run this command in a Administrator Command Prompt
```cmd
powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/zynxeditz2013-svg/Zippy/main/Zippy.bat -OutFile C:\Windows\System32\zippy.bat; Write-Host 'Zippy installed successfully! Type zippy to run it.'"
```
Then simply in any terminal window run:
```cmd
zippy
```
Note: If you installed the previous version of Zippy and want to install the latest version:
```cmd
Remove-Item C:\Windows\System32\zippy.bat -Force; Write-Host 'Zippy uninstalled successfully.'
```
Then run the install command again
```cmd
powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/zynxeditz2013-svg/Zippy/main/Zippy.bat -OutFile C:\Windows\System32\zippy.bat; Write-Host 'Zippy installed successfully! Type zippy to run it.'"
```
Then simply run Zippy
```cmd
zippy
```



# How to use?
## How to Encrypt?
1. Select Encrypt and then select your file.
2. Now Choose appropriate password for it. (This is what you are going to use to access the file)
3. Now simply select a output location.

## How to Decrypt?
1. Select Decrypt and select the .zippy file.
2. Now Put the Correct Password.
3. Now simply select a output location to extract the file.

## How to view file?
1.Select the View function and select the .zippy file.
2.If the archive is password-protected, enter the password to preview its contents.

Note: if the archive's creator disabled previewing when it was made, View will refuse to list its contents regardless of password.
