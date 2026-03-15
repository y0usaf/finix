{config}:
if config.networking.hostName == "y0usaf-laptop"
then ''
  def fanspeed [percentage: string] {
    ^asusctl fan-curve -m quiet -D $"30c:($percentage),40c:($percentage),50c:($percentage),60c:($percentage),70c:($percentage),80c:($percentage),90c:($percentage),100c:($percentage)" -e true -f gpu
    ^asusctl fan-curve -m quiet -D $"30c:($percentage),40c:($percentage),50c:($percentage),60c:($percentage),70c:($percentage),80c:($percentage),90c:($percentage),100c:($percentage)" -e true -f cpu
  }
''
else ""
