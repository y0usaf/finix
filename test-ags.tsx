import { App, Astal } from "astal/gtk3"

function TestWindow() {
    return <window
        layer={Astal.Layer.OVERLAY}
        exclusivity={Astal.Exclusivity.IGNORE}
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT}
        application={App}>
        <label label="TEST AGS OVERLAY" />
    </window>
}

App.start({
    main() {
        TestWindow()
    },
})