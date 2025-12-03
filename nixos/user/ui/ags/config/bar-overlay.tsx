import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable, exec, bind, monitorFile } from "astal"
import Tray from "gi://AstalTray"

const GTK_COLORS = "@HOME@/.cache/wallust/gtk-colors.css"

const styles = `
* {
    font-size: 14px;
    font-family: monospace;
}

.bar-top, .bar-bottom {
    background: transparent;
}

.bar-top window,
.bar-bottom window {
    margin: 0;
    padding: 0;
}

.bar {
    background: transparent;
    margin: 0;
    padding: 0;
}

.time-block, .date-block {
    background: @bg;
    border: 0.05em solid @accent;
    padding: 0.15em 0.3em;
    margin: 0;
    color: @fg;
}

.time-block label, .date-block label {
    background: transparent;
    color: @fg;
    font-weight: bold;
    margin: 0;
    padding: 0;
    text-shadow:
        0.07em 0 0.07em @black,
        -0.07em 0 0.07em @black,
        0 0.07em 0.07em @black,
        0 -0.07em 0.07em @black;
}

.tray-block {
    background: @bg;
    border: 0.05em solid @accent;
    padding: 0.15em;
    margin: 0;
}

.tray-item {
    background: transparent;
    border: none;
    padding: 0.15em;
    margin: 0;
    min-width: unset;
    min-height: unset;
    outline: none;
    box-shadow: none;
}

.tray-item:hover {
    background: alpha(@fg, 0.1);
}

.tray-item:focus {
    outline: none;
    box-shadow: none;
}

.tray-item image {
    min-width: 1.15em;
    min-height: 1.15em;
}
`

function loadStyles() {
    App.reset_css()
    App.apply_css(GTK_COLORS)
    App.apply_css(styles)
}

// Watch colors file for changes
monitorFile(GTK_COLORS, () => {
    loadStyles()
})

const time = Variable("").poll(1000, () => exec(["date", "+%H:%M:%S"]))
const date = Variable("").poll(30000, () => exec(["date", "+%d/%m/%y"]))

const tray = Tray.get_default()

function TrayItem({ item }: { item: any }) {
    const handleClick = (self: any, event: Gdk.Event) => {
        const button = event.get_button()[1]
        if (button === Gdk.BUTTON_PRIMARY) {
            item.activate(event.get_coords()[1], event.get_coords()[2])
        }
    }

    return <button
        className="tray-item"
        tooltipMarkup={bind(item, "tooltipMarkup")}
        onButtonPressEvent={handleClick}>
        <icon gIcon={bind(item, "gicon")} />
    </button>
}

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
            <box className="tray-block" spacing={2}>
                {bind(tray, "items").as(items => items.map(item => (
                    <TrayItem key={item.itemId} item={item} />
                )))}
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
            <box className="tray-block" spacing={2}>
                {bind(tray, "items").as(items => items.map(item => (
                    <TrayItem key={item.itemId} item={item} />
                )))}
            </box>
        </box>
    </window>
}

App.start({
    main() {
        loadStyles()
        TopBar()
        BottomBar()
    },
})
