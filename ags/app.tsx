import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable, exec } from "astal"
import { Hyprland } from "astal/hyprland"


// AGS v2 styles (converted from v1 CSS)
const styles = `
/* Base font size */
* {
    font-size: 14px;
    font-family: monospace;
}

/* System Stats Widget Styles */
.system-stats-window {
    background: transparent;
}

.system-stats {
    background: transparent;
    padding: 0.5em;
    margin: 0.5em;
    font-family: monospace;
    font-size: 1rem;
}

.system-stats * {
    margin: 0;
    padding: 0;
    background: transparent;
    border: none;
    box-shadow: none;
    text-shadow: 
        0.05rem 0 0.05rem #000000,
        -0.05rem 0 0.05rem #000000,
        0 0.05rem 0.05rem #000000,
        0 -0.05rem 0.05rem #000000,
        0.05rem 0.05rem 0.05rem #000000,
        -0.05rem 0.05rem 0.05rem #000000,
        0.05rem -0.05rem 0.05rem #000000,
        -0.05rem -0.05rem 0.05rem #000000;
    font-family: inherit;
    font-size: inherit;
    font-weight: inherit;
    color: inherit;
}

/* Rainbow color assignments */
.stats-time { color: #ff0000; }     /* Red */
.stats-date { color: #ff8800; }     /* Orange */
.stats-shell { color: #ffff00; }    /* Yellow */
.stats-uptime { color: #00ff00; }   /* Green */
.stats-pkgs { color: #00ff88; }     /* Blue-Green */
.stats-memory { color: #00ffff; }   /* Cyan */
.stats-cpu { color: #0088ff; }      /* Blue */
.stats-gpu { color: #ff00ff; }      /* Magenta */
.stats-colors { color: #ffffff; }   /* White */
.stats-white { color: #ffffff; }    /* White */
.stats-red { color: #ff0000; }
.stats-orange { color: #ff8800; }
.stats-yellow { color: #ffff00; }
.stats-green { color: #00ff00; }
.stats-blue-green { color: #00ff88; }
.stats-cyan { color: #00ffff; }
.stats-blue { color: #0088ff; }
.stats-magenta { color: #ff00ff; }

/* Workspaces Widget Styles */
.workspaces-top, .workspaces-bottom {
    background: transparent;
}

.workspaces {
    background: transparent;
    margin: 0;
    padding: 0;
}

.workspaces *,
.workspaces {
    margin: 0;
    padding: 0;
    background: transparent;
    border: none;
    box-shadow: none;
    color: white;
}

.workspace-btn {
    margin: 0;
    padding: 0;
    background-color: #222;
    border-radius: 0;
    min-width: 20px;
    min-height: 20px;
}

.workspace-btn label {
    background: transparent;
    color: rgba(255, 255, 255, 0.4);
    font-size: 0.6rem;
    padding: 0.1em;
}

.workspace-btn.active label {
    color: rgba(255, 255, 255, 1.0);
}

.workspace-btn.occupied label {
    color: rgba(255, 255, 255, 0.8);
}

.workspace-btn.inactive label {
    color: rgba(255, 255, 255, 0.5);
}

.workspace-btn.urgent label {
    color: #ff5555;
}
`

// Safe command execution helper for AGS v2
function safeExec(command: string, defaultValue: string = 'N/A'): string {
    try {
        const result = exec(["bash", "-c", command]);
        return result.trim() || defaultValue;
    } catch (error) {
        console.log(`Failed to execute command: ${command}`, error);
        return defaultValue;
    }
}

// System stats variables with fixed commands for AGS v2
const cpuTemp = Variable('N/A').poll(1000, () => {
    return safeExec("sensors 2>/dev/null | grep -E 'Tctl|Package id 0' | head -1 | awk '{print $2}' | sed 's/+//' || echo 'N/A'");
});

const gpuTemp = Variable('N/A').poll(1000, () => {
    const temp = safeExec("which nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo 'N/A'");
    return temp !== 'N/A' && temp !== '' ? temp + '°C' : 'N/A';
});

const memoryInfo = Variable({ used: 'N/A', total: 'N/A' }).poll(1000, () => {
    try {
        const output = exec(["bash", "-c", "free -h | grep '^Mem:'"]);
        const ramInfo = output.split(/\s+/);
        return { used: ramInfo[2] || 'N/A', total: ramInfo[1] || 'N/A' };
    } catch {
        return { used: 'N/A', total: 'N/A' };
    }
});

const currentTime = Variable('00:00:00').poll(1000, () => {
    return safeExec('date "+%H:%M:%S"');
});

const currentDate = Variable('00/00/00').poll(1000, () => {
    return safeExec('date "+%d/%m/%y"');
});

const uptime = Variable('N/A').poll(60000, () => {
    return safeExec("uptime | sed 's/.*up \\([^,]*\\).*/\\1/' | xargs").trim();
});

const packageCount = Variable('N/A').poll(300000, () => {
    return safeExec("which nix-store >/dev/null 2>&1 && nix-store -q --requisites /run/current-system/sw 2>/dev/null | wc -l || echo 'N/A'").trim();
});

const shellName = Variable('N/A').poll(60000, () => {
    return safeExec("basename \"$SHELL\"");
});

// Hyprland workspaces using native Astal bindings
const hypr = Hyprland.get_default()
const workspaces = Variable.derive([hypr, "workspaces"], () => hypr.workspaces)
const activeWorkspace = Variable.derive([hypr, "focusedWorkspace"], () => hypr.focusedWorkspace?.id || 1)

// System Stats Widget Component
function SystemStats() {
    const labels = ['time', 'date', 'shell', 'uptime', 'pkgs', 'memory', 'cpu', 'gpu', 'colors'];
    const longestLabel = Math.max(...labels.map(l => l.length));
    
    function padLabel(label: string): string {
        return label + ' '.repeat(longestLabel - label.length);
    }
    
    function horizontalBorder(char1: string, char2: string, char3: string): string {
        return char1 + "─".repeat(longestLabel + 4) + char3;
    }

    return <window
        className="system-stats-window"
        layer={Astal.Layer.BOTTOM}
        exclusivity={Astal.Exclusivity.IGNORE}
        application={App}>
        <box className="system-stats" vertical>
            {/* AGS Logo */}
            <label 
                className="stats-white"
                label="   _  ___      ____  ____&#10;  / |/ (_)_ __/ __ \/ __/&#10; /    / /\ \ / /_/ /\ \  &#10;/_/|_/_//_\_\\____/___/  "
            />
            
            {/* Top border */}
            <label 
                className="stats-white"
                halign={Gtk.Align.START}
                label={horizontalBorder("╭", "─", "╮")}
            />
            
            {/* Stats rows */}
            {labels.map(currentLabel => 
                <box key={currentLabel}>
                    <label className="stats-white" halign={Gtk.Align.START} label="│ " />
                    <label className={`stats-${currentLabel}`} halign={Gtk.Align.START} label="• " />
                    <label className="stats-white" halign={Gtk.Align.START} label={`${padLabel(currentLabel)} │ `} />
                    <label 
                        className={`stats-${currentLabel}`}
                        halign={Gtk.Align.START}
                        label={(() => {
                            switch(currentLabel) {
                                case 'time': return currentTime();
                                case 'date': return currentDate();
                                case 'shell': return shellName();
                                case 'uptime': return uptime();
                                case 'pkgs': return packageCount();
                                case 'memory': return `${memoryInfo().used} | ${memoryInfo().total}`;
                                case 'cpu': return cpuTemp();
                                case 'gpu': return gpuTemp();
                                case 'colors': return "";
                                default: return "";
                            }
                        })()}
                    />
                    {/* Color dots for colors row */}
                    {currentLabel === 'colors' && [
                        <label key="red" className="stats-red" label="• " />,
                        <label key="orange" className="stats-orange" label="• " />,
                        <label key="yellow" className="stats-yellow" label="• " />,
                        <label key="green" className="stats-green" label="• " />,
                        <label key="blue-green" className="stats-blue-green" label="• " />,
                        <label key="cyan" className="stats-cyan" label="• " />,
                        <label key="blue" className="stats-blue" label="• " />,
                        <label key="magenta" className="stats-magenta" label="• " />,
                        <label key="white" className="stats-white" label="• " />
                    ]}
                </box>
            )}
            
            {/* Bottom border */}
            <label 
                className="stats-white"
                halign={Gtk.Align.START}
                label={horizontalBorder("╰", "─", "╯")}
            />
        </box>
    </window>
}

// Workspaces Widget Component
function WorkspacesWidget(position: 'top' | 'bottom') {
    const anchor = position === 'top' 
        ? Astal.WindowAnchor.TOP
        : Astal.WindowAnchor.BOTTOM;

    return <window
        className={`workspaces-${position}`}
        layer={Astal.Layer.OVERLAY}
        exclusivity={Astal.Exclusivity.IGNORE}
        anchor={anchor}
        application={App}>
        <box className="workspaces">
            {workspaces.bind().as(ws => {
                const active = activeWorkspace.get();
                const visibleWorkspaces: number[] = [];
                
                // Add active workspace
                if (active) {
                    visibleWorkspaces.push(active);
                }
                
                // Add occupied workspaces from native Hyprland data
                if (Array.isArray(ws)) {
                    ws.forEach((workspace: any) => {
                        if (workspace.windows > 0 && !visibleWorkspaces.includes(workspace.id)) {
                            visibleWorkspaces.push(workspace.id);
                        }
                    });
                }
                
                visibleWorkspaces.sort((a, b) => a - b);
                
                return visibleWorkspaces.map(id => {
                    const isActive = active === id;
                    const isOccupied = Array.isArray(ws) && ws.some((workspace: any) => workspace.id === id && workspace.windows > 0);
                    
                    return <button
                        key={id}
                        className={`workspace-btn ${isActive ? 'active' : ''} ${isOccupied ? 'occupied' : ''}`}
                        onClicked={() => {
                            hypr.dispatch("workspace", id.toString());
                        }}>
                        <label label={id.toString()} />
                    </button>
                });
            })}
        </box>
    </window>
}

// Main app configuration
App.start({
    css: styles,
    main() {
        // Create system stats window
        SystemStats();
        
        // Create workspace widgets
        WorkspacesWidget('top');
        WorkspacesWidget('bottom');
    },
}) 