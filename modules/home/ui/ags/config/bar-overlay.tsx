import { App, Astal, Gtk } from "astal/gtk3"
import { Variable, exec } from "astal"

// ============================================================================
// QUICKSHELL-STYLE MINIMALIST STYLING
// ============================================================================
const styles = `
* {
    font-size: 14px;
    font-family: monospace;
}

.bar-top, .bar-bottom {
    background: transparent;
}

.bar {
    background: transparent;
    margin: 0;
    padding: 0;
}

.time-block, .date-block {
    background: #2a2a2a;
    border-radius: 0;
    padding: 2px;
    margin: 0;
    color: white;
}

.time-block label, .date-block label {
    background: transparent;
    color: white;
    margin: 0;
    padding: 0;
    text-shadow:
        1px 0 1px black,
        -1px 0 1px black,
        0 1px 1px black,
        0 -1px 1px black;
}
`

// ============================================================================
// TIME AND DATE VARIABLES
// ============================================================================
const time = Variable("").poll(1000, () => exec(["date", "+%H:%M:%S"]))
const date = Variable("").poll(30000, () => exec(["date", "+%d/%m/%y"]))

// ============================================================================
// BAR COMPONENTS
// ============================================================================
function TopBar() {
    return <window
        className="bar-top"
        layer={Astal.Layer.OVERLAY}
        exclusivity={Astal.Exclusivity.IGNORE}
        anchor={Astal.WindowAnchor.TOP}
        application={App}>
        <box className="bar" spacing={8}>
            <box className="time-block">
                <label label={time()} />
            </box>
            <box className="date-block">
                <label label={date()} />
            </box>
        </box>
    </window>
}

function BottomBar() {
    return <window
        className="bar-bottom"
        layer={Astal.Layer.OVERLAY}
        exclusivity={Astal.Exclusivity.IGNORE}
        anchor={Astal.WindowAnchor.BOTTOM}
        application={App}>
        <box className="bar" spacing={8}>
            <box className="time-block">
                <label label={time()} />
            </box>
            <box className="date-block">
                <label label={date()} />
            </box>
        </box>
    </window>
}

// ============================================================================
// APP
// ============================================================================
App.start({
    css: styles,
    main() {
        TopBar()
        BottomBar()
    },
})
