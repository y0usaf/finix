{
  CreateObject,
  Err,
  Replace,
  WScript,
  assign,
  blank,
  call,
  comment,
  dim,
  dot,
  if',
  onErrorResumeNext,
  optionExplicit,
  set,
  str,
  ...
}: ({
  sh,
  wav,
  cmd,
  code,
}: [
  (comment "Chime hidden player launcher (Windows).")
  (comment "")
  (comment "Run with wscript.exe (a GUI-subsystem host: no console window of its own).")
  (comment "It runs PowerShell hidden (window style 0 from creation, so not even a")
  (comment "flash) and waits for playback. PowerShell is a console-subsystem program,")
  (comment "so spawning it directly pops a console box on every chime; -WindowStyle")
  (comment "Hidden only hides it after it appears.")
  (comment "")
  (comment "Usage: wscript.exe //Nologo play.vbs <wav-file>")
  (comment "Exit code is PowerShell's; it never shows an error dialog.")
  blank
  optionExplicit
  onErrorResumeNext
  blank
  (if' [(dot WScript "Arguments.Count") "=" 0] [
    (call (dot WScript "Quit") [1])
  ])
  blank
  (dim [sh wav cmd])
  (set sh (call CreateObject [(str "WScript.Shell")]))
  (if' [(dot Err "Number") "<>" 0] [
    (call (dot WScript "Quit") [1])
  ])
  blank
  (assign wav (call (dot WScript "Arguments") [0]))
  (assign wav (call Replace [wav (str "'") (str "''")]))
  (assign cmd [(str "powershell -NoProfile -NonInteractive -WindowStyle Hidden -Command \"(New-Object Media.SoundPlayer '") "&" wav "&" (str "').PlaySync()\"")])
  blank
  (dim [code])
  (assign code (call (dot sh "Run") [cmd 0 true]))
  (if' [(dot Err "Number") "<>" 0] [
    (call (dot WScript "Quit") [1])
  ])
  (call (dot WScript "Quit") [code])
])
