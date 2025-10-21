{config}:
{
  clauded = "claude --dangerously-skip-permissions";
  grep = "rg --color auto";
  dir = "dir --color=auto";
  egrep = "rg --color auto";
  fgrep = "rg -F --color auto";
}
// (
  if config.hardware.nvidia.enable
  then {
    gpupower = "sudo nvidia-smi -pl";
  }
  else {}
)
