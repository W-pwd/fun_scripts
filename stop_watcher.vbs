Set shell = CreateObject("WScript.Shell")
folder = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
shell.Run "powershell.exe -NoProfile -Command ""Get-CimInstance Win32_Process | ? { $_.CommandLine -like '*" & folder & "watcher.ps1*' } | % { Stop-Process $_.ProcessId -Force }""", 0, False
MsgBox "Watcher stopped.", vbInformation, "The_WATCHER"
