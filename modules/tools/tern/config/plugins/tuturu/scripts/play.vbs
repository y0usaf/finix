' Chime hidden player launcher (Windows).
'
' Run with wscript.exe (a GUI-subsystem host: no console window of its own).
' It runs PowerShell hidden (window style 0 from creation, so not even a
' flash) and waits for playback. PowerShell is a console-subsystem program,
' so spawning it directly pops a console box on every chime; -WindowStyle
' Hidden only hides it after it appears.
'
' Usage: wscript.exe //Nologo play.vbs <wav-file>
' Exit code is PowerShell's; it never shows an error dialog.

Option Explicit
On Error Resume Next

If WScript.Arguments.Count = 0 Then
	WScript.Quit 1
End If

Dim sh, wav, cmd
Set sh = CreateObject("WScript.Shell")
If Err.Number <> 0 Then
	WScript.Quit 1
End If

wav = WScript.Arguments(0)
wav = Replace(wav, "'", "''")
cmd = "powershell -NoProfile -NonInteractive -WindowStyle Hidden -Command ""(New-Object Media.SoundPlayer '" & wav & "').PlaySync()"""

Dim code
code = sh.Run(cmd, 0, True)
If Err.Number <> 0 Then
	WScript.Quit 1
End If
WScript.Quit code
