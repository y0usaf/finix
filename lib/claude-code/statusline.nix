{pkgs}:
pkgs.writeShellApplication {
  name = "statusline";
  runtimeInputs = [pkgs.jq pkgs.git pkgs.ncurses pkgs.bun];
  checkPhase = "";
  text = ''
    DATA=$(cat);COLS=$(tput cols 2>/dev/null||echo 120)
    eval "$(jq -r '
      def pct:try(if(.context_window.remaining_percentage//null)!=null then 100-(.context_window.remaining_percentage|floor)
        elif(.context_window.context_window_size//0)>0 then((.context_window.current_usage.input_tokens//0)+(.context_window.current_usage.cache_creation_input_tokens//0)+(.context_window.current_usage.cache_read_input_tokens//0))*100/(.context_window.context_window_size)|floor
        else 0 end)catch 0;
      @sh"MODEL=\(.model.display_name//\"Claude\") MODEL_ID=\(try(.model.id//\"unknown\")catch\"unknown\") DIR=\(.cwd//\"~\"|split(\"/\")|last) PCT=\(pct) CTX_K=\((.context_window.context_window_size//200000)/1000) DUR_MS=\(.cost.total_duration_ms//0) AGENT=\(.agent.name//\"\") MODE=\(.mode//\"\") SCOST=\(.cost.total_cost_usd//0)"'<<<"$DATA")"
    CF="$HOME/.claude/cost-cache.json"
    _cfr(){ local d;d=$(bunx ccusage daily --since "$(date +%Y%m01)" --json 2>/dev/null)||return
      jq --arg d "$(date +%Y-%m-%d)" --arg w "$(date -d'last monday' +%Y-%m-%d 2>/dev/null||date +%Y-%m-%d)" \
        '{d:[.daily[]|select(.date==$d)|.totalCost]|add//0,w:[.daily[]|select(.date>=$w)|.totalCost]|add//0,m:[.daily[].totalCost]|add//0}'<<<"$d" \
        >"''${CF}.tmp"&&mv "''${CF}.tmp" "$CF";}
    CA=9999;[ -f "$CF" ]&&CA=$(($(date +%s)-$(stat -c%Y "$CF" 2>/dev/null||echo 0)))
    ((CA>=60))&&{ ((CA>300))&&{ _cfr 2>/dev/null||true;}||{ (_cfr 2>/dev/null||true)&disown 2>/dev/null;};}
    read -r F_S F_D F_W F_M < <(jq -r --argjson s "''${SCOST:-0}" '
      def fc:if.<0.01 then"$0"elif.<10 then"$\(.*100|round/100)"elif.<100 then"$\(.*10|round/10)"else"$\(round)"end;
      "\($s|fc) \(.d//0|fc) \(.w//0|fc) \(.m//0|fc)"' "$CF" 2>/dev/null||echo '$0 $0 $0 $0')
    R=$'\033[0m' B=$'\033[1m'
    B1=$'\033[0;48;5;4m' F1=$'\033[38;5;0m' D1=$'\033[38;5;8m'
    B2=$'\033[0;48;5;0m' F2=$'\033[38;5;7m' D2=$'\033[38;5;4m'
    cG=$'\033[0;48;5;0;38;5;2m' cY=$'\033[0;48;5;0;38;5;3m' cR=$'\033[0;48;5;0;38;5;1m' cM=$'\033[0;48;5;0;38;5;5m'
    case "$MODEL_ID" in *opus*)TI=$'\xee\xb5\xa2';;*sonnet*)TI=$'\xee\xb8\xb4';;*haiku*)TI=$'\xee\x9f\x95';;*)TI=$'\xef\x84\x91';;esac
    BR=$(git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null)||BR=""
    GS=""
    [ -n "$BR" ]&&{
      read -r s m u < <(paste -d' ' <(git diff --cached --numstat 2>/dev/null|wc -l) <(git diff --numstat 2>/dev/null|wc -l) <(git ls-files --others --exclude-standard 2>/dev/null|wc -l)|tr -s ' ')
      ((''${s:-0}>0))&&GS="+$s";((''${m:-0}>0))&&GS="''${GS:+$GS }!$m";((''${u:-0}>0))&&GS="''${GS:+$GS }?$u";}
    TS=$((DUR_MS/1000));TH=$((TS/3600));TM=$(((TS%3600)/60));TSC=$((TS%60))
    ((TH>0))&&TMS="''${TH}h''${TM}m"||{ ((TM>0))&&TMS="''${TM}m''${TSC}s"||TMS="''${TSC}s";}
    TV=$((TH*34));((TV>80))&&TC=$cR||{ ((TV>50))&&TC=$cY||TC=$cG;}
    ((PCT>80))&&CC=$cR||{ ((PCT>50))&&CC=$cY||CC=$cG;}
    BAR="";f=$((PCT/10));((PCT>0&&f==0))&&f=1;((f>10))&&f=10
    for((i=0;i<f;i++));do BAR+="''${CC}▰";done;for((i=f;i<10;i++));do BAR+="''${D2}▱";done
    S="''${D1}│''${B1}" S2="''${D2}│''${B2}"
    _v(){ printf "%b" "$1"|sed $'s/\033\\[[0-9;]*m//g'|tr -d '\n'|LC_ALL=en_US.UTF-8 wc -m|tr -d ' ';}
    # Segment A: model+dir (L1) vs context bar (L2)
    A1=" ''${F1}''${B}''${TI} ''${MODEL}''${B1}  ''${F1}\xef\x81\xbb ''${DIR}''${B1} "
    A2=" ''${BAR} ''${CC}''${PCT}%''${B2}''${D2}/''${CTX_K}k "
    # Segment B: git (L1) vs time (L2)
    B1S=" ''${F1}\xee\x82\xa0 ''${BR}''${B1}";[ -n "$GS" ]&&B1S+=" ''${F1}''${GS}''${B1}"
    [ -z "$BR" ]&&B1S=""
    [ -n "$AGENT" ]&&B1S+="  ''${F1}''${AGENT}''${B1}"
    [ -n "$MODE" ]&&B1S+="  ''${F1}''${B}''${MODE}''${B1}"
    B1S+=" "
    B2S=" ''${TC}\xef\x80\x97 ''${TMS}''${B2} "
    # Segment C: S/D costs (L1) vs W/M costs (L2)
    C1=" ''${D1}S:''${F1}''${F_S}''${B1} ''${D1}D:''${F1}''${F_D}''${B1} "
    C2="";[ -f "$CF" ]&&C2=" ''${cM}W:''${F2}''${F_W} ''${cM}M:''${F2}''${F_M}''${B2} "
    # Measure and pad each segment pair
    WA1=$(_v "$A1");WA2=$(_v "$A2");WA=$((WA1>WA2?WA1:WA2))
    WB1=$(_v "$B1S");WB2=$(_v "$B2S");WB=$((WB1>WB2?WB1:WB2))
    WC1=$(_v "$C1");WC2=$(_v "$C2");WC=$((WC1>WC2?WC1:WC2))
    pad(){ (($1>0))&&printf '%*s' "$1" ""||:;}
    # Center each segment: split padding into left+right halves
    cx(){ _d=$(($1-$2));echo "$((_d/2)) $((_d-_d/2))";}
    read -r la1 ra1 < <(cx $WA $(_v "$A1"));read -r la2 ra2 < <(cx $WA $(_v "$A2"))
    read -r lb1 rb1 < <(cx $WB $(_v "$B1S"));read -r lb2 rb2 < <(cx $WB $(_v "$B2S"))
    read -r lc1 rc1 < <(cx $WC $(_v "$C1"));read -r lc2 rc2 < <(cx $WC $(_v "$C2"))
    L1="''${B1}$(pad $la1)''${A1}$(pad $ra1)''${S}$(pad $lb1)''${B1S}$(pad $rb1)''${S}$(pad $lc1)''${C1}$(pad $rc1)"
    L2="''${B2}$(pad $la2)''${A2}$(pad $ra2)''${S2}$(pad $lb2)''${B2S}$(pad $rb2)''${S2}$(pad $lc2)''${C2}$(pad $rc2)"
    printf '\033]1;%s\007' "''${DIR:-Claude}" >/dev/tty 2>/dev/null||true
    echo -e "''${L1}\033[K''${R}"
    echo -e "''${L2}\033[K''${R}"
  '';
}
