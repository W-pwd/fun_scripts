Set shell = CreateObject("WScript.Shell")

folder = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
script = folder & "watcher.ps1"

shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & script & """ -WatcherName ""The_WATCHER""", 0, False 
