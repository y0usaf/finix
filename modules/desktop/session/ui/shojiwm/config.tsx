import {
  AppIcon,
  Box,
  Button,
  ClientWindow,
  Image,
  Label,
  COMPOSITOR,
  WindowBorder,
  computed,
  useState,
  type SSDStyle,
  type WaylandWindow,
  ManagedWindow,
  read,
  type DisplayConfigDraft,
  type WindowResizeEvent,
} from "shoji_wm";
import type { CompositionRenderable, ManagedWindowRect } from "shoji_wm/types";
import {
  HybridWindowManager,
  TITLEBAR_HEIGHT,
  TILE_MARGIN,
  WINDOW_BORDER_PX,
  WINDOW_STATE_FULLSCREEN,
  WINDOW_STATE_MINIMIZED,
  WINDOW_STATE_MINIMIZE_VISUAL_IDLE,
  WINDOW_STATE_TILE_DRAGGING,
  WINDOW_STATE_TILED,
  WINDOW_STATE_TABBED,
  WINDOW_STATE_VISIBLE_OUTPUTS,
  WINDOW_STATE_WORKSPACE_VISIBLE,
  WINDOW_STATE_WORKSPACE_OFFSET_Y,
  WINDOW_STATE_WORKSPACE_OPACITY,
  WINDOW_STATE_RECT,
} from "./window-manager";

// ---------------------------------------------------------------------------
// Environment
// ---------------------------------------------------------------------------
COMPOSITOR.env.set("QT_QPA_PLATFORM", "wayland");
COMPOSITOR.env.set("QT_QPA_PLATFORMTHEME", "qt6ct");
COMPOSITOR.env.apply({
  MOZ_ENABLE_WAYLAND: "1",
  SDL_VIDEODRIVER: "wayland",
});

// ---------------------------------------------------------------------------
// HybridWindowManager setup
// ---------------------------------------------------------------------------
const HYBRID_WINDOW_MANAGER = new HybridWindowManager(naturalRootRect);
const HOT_RELOAD_WINDOW_MANAGER_STATE = "config.hybrid-window-manager";

COMPOSITOR.onDisable((event) => {
  if (event.isReloading) {
    const snapshot = HYBRID_WINDOW_MANAGER.snapshot();
    event.persist(HOT_RELOAD_WINDOW_MANAGER_STATE, snapshot);
  }
});

COMPOSITOR.onEnable((event) => {
  if (event.isReloading) {
    const snapshot = event.restore<
      ReturnType<typeof HYBRID_WINDOW_MANAGER.snapshot>
    >(HOT_RELOAD_WINDOW_MANAGER_STATE);
    if (snapshot) {
      HYBRID_WINDOW_MANAGER.restore(snapshot);
    }
  }
});

// ---------------------------------------------------------------------------
// Key bindings — translated from niri/keybindings.nix
// Mod = Alt (per input.nix mod-key), Super = Super
// ---------------------------------------------------------------------------

// Mod+Shift+Slash — show-hotkey-overlay: no shojiwm equivalent
// Mod+Shift+E — quit: built-in Super+Shift+Q (compositor core)
// Mod+O — toggle-overview: no shojiwm equivalent

// Mod+T — spawn terminal
COMPOSITOR.key.bind("terminal", "Alt+T", () => {
  COMPOSITOR.process.spawn({ command: ["sh", "-c", "@@TERMINAL@@"] });
});

// Super+R — spawn launcher
COMPOSITOR.key.bind("launcher", "Super+R", () => {
  COMPOSITOR.process.spawn({ command: ["sh", "-c", "@@LAUNCHER@@"] });
});

// Mod+E — spawn file manager
COMPOSITOR.key.bind("file-manager", "Alt+E", () => {
  COMPOSITOR.process.spawn({ command: ["sh", "-c", "@@FILE_MANAGER@@"] });
});

// Super+Shift+O — spawn terminal editor
COMPOSITOR.key.bind("terminal-editor", "Super+Shift+O", () => {
  COMPOSITOR.process.spawn({ command: ["sh", "-c", "@@TERMINAL@@ -e @@EDITOR@@"] });
});

// Mod+Q — close focused window
COMPOSITOR.key.bind("close", "Alt+Q", () => {
  HYBRID_WINDOW_MANAGER.closeFocusedWindow();
});

// Mod+F — maximize column → toggle maximize
COMPOSITOR.key.bind("maximize", "Alt+F", () => {
  HYBRID_WINDOW_MANAGER.toggleFocusedWindowMaximize();
});

// Mod+Shift+F — fullscreen window → toggle maximize (closest)
COMPOSITOR.key.bind("fullscreen", "Alt+Shift+F", () => {
  HYBRID_WINDOW_MANAGER.toggleFocusedWindowMaximize();
});

// Super+F — toggle windowed fullscreen → toggle maximize
COMPOSITOR.key.bind("windowed-fullscreen", "Super+F", () => {
  HYBRID_WINDOW_MANAGER.toggleFocusedWindowMaximize();
});

// Mod+Space — center-column: no shojiwm equivalent

// Floating is disabled: Super+Space no longer toggles tile/floating mode.
// (Previously: toggle window floating → toggle tiling)

// Super+T — toggle tabbed/stacking layout (all windows share the viewport,
// only the active tab is visible; cycle with Alt+J/Alt+K).
// Toggles between tabbed and horizontal tiling; from floating enters tabbed.
COMPOSITOR.key.bind("toggle-tabbed", "Super+T", () => {
  HYBRID_WINDOW_MANAGER.toggleCurrentWorkspaceTabbed();
});

// --- Focus navigation ---
// Mod+H — focus column left
COMPOSITOR.key.bind("focus-left", "Alt+H", () => {
  HYBRID_WINDOW_MANAGER.focusTile(-1);
});
// Mod+L — focus column right
COMPOSITOR.key.bind("focus-right", "Alt+L", () => {
  HYBRID_WINDOW_MANAGER.focusTile(1);
});
// Mod+J — focus window down → focusTile(1) (closest)
COMPOSITOR.key.bind("focus-down", "Alt+J", () => {
  HYBRID_WINDOW_MANAGER.focusTile(1);
});
// Mod+K — focus window up → focusTile(-1) (closest)
COMPOSITOR.key.bind("focus-up", "Alt+K", () => {
  HYBRID_WINDOW_MANAGER.focusTile(-1);
});
// Mod+Left — focus column left
COMPOSITOR.key.bind("focus-left-arrow", "Alt+Left", () => {
  HYBRID_WINDOW_MANAGER.focusTile(-1);
});
// Mod+Right — focus column right
COMPOSITOR.key.bind("focus-right-arrow", "Alt+Right", () => {
  HYBRID_WINDOW_MANAGER.focusTile(1);
});
// Mod+Up — focus window up → focusTile(-1) (closest)
COMPOSITOR.key.bind("focus-up-arrow", "Alt+Up", () => {
  HYBRID_WINDOW_MANAGER.focusTile(-1);
});
// Mod+Down — focus window down → focusTile(1) (closest)
COMPOSITOR.key.bind("focus-down-arrow", "Alt+Down", () => {
  HYBRID_WINDOW_MANAGER.focusTile(1);
});

// --- Move window/tile ---
// Mod+Shift+H — move column left
COMPOSITOR.key.bind("move-left", "Alt+Shift+H", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedTile(-1);
});
// Mod+Shift+L — move column right
COMPOSITOR.key.bind("move-right", "Alt+Shift+L", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedTile(1);
});
// Mod+Shift+J — move window down → moveFocusedTile(1) (closest)
COMPOSITOR.key.bind("move-down", "Alt+Shift+J", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedTile(1);
});
// Mod+Shift+K — move window up → moveFocusedTile(-1) (closest)
COMPOSITOR.key.bind("move-up", "Alt+Shift+K", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedTile(-1);
});
// Mod+Shift+Left — move column left
COMPOSITOR.key.bind("move-left-arrow", "Alt+Shift+Left", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedTile(-1);
});
// Mod+Shift+Right — move column right
COMPOSITOR.key.bind("move-right-arrow", "Alt+Shift+Right", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedTile(1);
});
// Mod+Shift+Up — move window up → moveFocusedTile(-1) (closest)
COMPOSITOR.key.bind("move-up-arrow", "Alt+Shift+Up", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedTile(-1);
});
// Mod+Shift+Down — move window down → moveFocusedTile(1) (closest)
COMPOSITOR.key.bind("move-down-arrow", "Alt+Shift+Down", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedTile(1);
});

// --- Workspace focus ---
// Mod+Page_Up — focus workspace up
COMPOSITOR.key.bind("workspace-prev-pageup", "Alt+Page_Up", () => {
  HYBRID_WINDOW_MANAGER.switchWorkspace(-1);
});
// Mod+Page_Down — focus workspace down
COMPOSITOR.key.bind("workspace-next-pagedown", "Alt+Page_Down", () => {
  HYBRID_WINDOW_MANAGER.switchWorkspace(1);
});
// Mod+U — focus workspace up
COMPOSITOR.key.bind("workspace-prev-u", "Alt+U", () => {
  HYBRID_WINDOW_MANAGER.switchWorkspace(-1);
});
// Mod+I — focus workspace down
COMPOSITOR.key.bind("workspace-next-i", "Alt+I", () => {
  HYBRID_WINDOW_MANAGER.switchWorkspace(1);
});

// Super+1..9 — focus workspace N
const workspaceKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9"];
for (const key of workspaceKeys) {
  const index = parseInt(key, 10);
  COMPOSITOR.key.bind("workspace-" + key, "Super+" + key, () => {
    const monitor = HYBRID_WINDOW_MANAGER.getCurrentMonitorName();
    HYBRID_WINDOW_MANAGER.activate(monitor, index);
  });
}

// --- Move window to workspace ---
// Mod+Ctrl+Page_Up — move column to workspace up
COMPOSITOR.key.bind("move-workspace-up-pageup", "Alt+Ctrl+Page_Up", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedWindowToWorkspace(-1);
});
// Mod+Ctrl+Page_Down — move column to workspace down
COMPOSITOR.key.bind("move-workspace-down-pagedown", "Alt+Ctrl+Page_Down", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedWindowToWorkspace(1);
});
// Mod+Ctrl+U — move column to workspace up
COMPOSITOR.key.bind("move-workspace-up-u", "Alt+Ctrl+U", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedWindowToWorkspace(-1);
});
// Mod+Ctrl+I — move column to workspace down
COMPOSITOR.key.bind("move-workspace-down-i", "Alt+Ctrl+I", () => {
  HYBRID_WINDOW_MANAGER.moveFocusedWindowToWorkspace(1);
});

// Super+Shift+1..9 — move window to workspace N
for (const key of workspaceKeys) {
  const index = parseInt(key, 10);
  COMPOSITOR.key.bind("move-workspace-" + key, "Super+Shift+" + key, () => {
    const monitor = HYBRID_WINDOW_MANAGER.getCurrentMonitorName();
    const current = HYBRID_WINDOW_MANAGER.getCurrentWorkspace();
    if (current) {
      const direction = index > current.index ? 1 : -1;
      const steps = Math.abs(index - current.index);
      for (let i = 0; i < steps; i++) {
        HYBRID_WINDOW_MANAGER.moveFocusedWindowToWorkspace(direction);
      }
    }
  });
}

// --- Percentage-based column-width presets (mirrors niri preset-column-widths) ---
// Mod+R / Mod+Shift+R cycle the focused tile through preset widths expressed
// as a proportion of the usable display width — the same model niri uses for
// switch-preset-column-width.
const PRESET_WIDTH_PROPORTIONS = [0.33333, 0.5, 0.66667];

function cycleFocusedTileWidth(direction: 1 | -1): void {
  const workspace = HYBRID_WINDOW_MANAGER.getCurrentWorkspace();
  if (!workspace || !workspace.isTiled) {
    return;
  }
  const focused = workspace.focusedWindow();
  if (!focused || !workspace.shouldTile(focused)) {
    return;
  }

  const monitorName = HYBRID_WINDOW_MANAGER.getCurrentMonitorName();
  const usable = COMPOSITOR.layer.usableArea(monitorName);
  if (!usable) {
    return;
  }

  // The tile viewport is inset by TILE_MARGIN on every side (see
  // Workspace.tileViewportRect()), and managed-window rects include a
  // WINDOW_BORDER_PX frame on each side. Preset proportions (1/3, 1/2, 2/3)
  // are fractions of the *available tiling width*, not the raw usable-area
  // width — otherwise a window set to "50%" comes out slightly wider than
  // half the visible region because the margins and border overhead were not
  // subtracted first.
  const tilingWidth = usable.width - TILE_MARGIN * 2;
  const currentRect = focused.state[WINDOW_STATE_RECT]();
  const currentWidth = read(currentRect.width);

  // Find the closest preset to the current width, then advance.
  let closestIndex = 0;
  let closestDelta = Infinity;
  for (let i = 0; i < PRESET_WIDTH_PROPORTIONS.length; i++) {
    const presetWidth = tilingWidth * PRESET_WIDTH_PROPORTIONS[i];
    const delta = Math.abs(presetWidth - currentWidth);
    if (delta < closestDelta) {
      closestDelta = delta;
      closestIndex = i;
    }
  }

  const nextIndex =
    (closestIndex + direction + PRESET_WIDTH_PROPORTIONS.length) %
    PRESET_WIDTH_PROPORTIONS.length;
  // The target is the managed-rect width (includes border). This is what
  // Workspace.resizeTile() stores in tileWidthByWindowId and what
  // applyLayout() positions, so the width must already contain the border.
  const targetWidth = Math.round(
    tilingWidth * PRESET_WIDTH_PROPORTIONS[nextIndex],
  );

  // Synthesize a WindowResizeEvent so we can reuse the upstream
  // Workspace.resizeTile(), which clamps to min/max constraints, unmaximizes
  // if needed, and calls applyLayout() — the same path as a drag-resize.
  const rect = focused.state[WINDOW_STATE_RECT]();
  const event: WindowResizeEvent = {
    window: focused,
    source: "ssd",
    phase: "update",
    edges: { left: false, right: true, top: false, bottom: false },
    startPointer: { x: 0, y: 0 },
    currentPointer: { x: 0, y: 0 },
    delta: { x: 0, y: 0 },
    startRect: {
      x: read(rect.x),
      y: read(rect.y),
      width: read(rect.width),
      height: read(rect.height),
    },
    currentRect: {
      x: read(rect.x),
      y: read(rect.y),
      width: targetWidth,
      height: read(rect.height),
    },
    outputName: monitorName,
    timestamp: Date.now(),
  };
  workspace.resizeTile(event);
}

// Mod+R — cycle focused column to next preset width (wider)
COMPOSITOR.key.bind("resize-preset-next", "Alt+R", () => {
  cycleFocusedTileWidth(1);
});
// Mod+Shift+R — cycle focused column to previous preset width (narrower)
COMPOSITOR.key.bind("resize-preset-prev", "Alt+Shift+R", () => {
  cycleFocusedTileWidth(-1);
});
// Mod+Comma — consume-window-into-column: no shojiwm equivalent
// Mod+Period — expel-window-from-column: no shojiwm equivalent
// Mod+BracketLeft — consume-or-expel-window-left: no shojiwm equivalent
// Mod+BracketRight — consume-or-expel-window-right: no shojiwm equivalent

// --- Application spawns ---
// Mod+1 — spawn IDE
COMPOSITOR.key.bind("ide", "Alt+1", () => {
  COMPOSITOR.process.spawn({ command: ["sh", "-c", "@@IDE@@"] });
});
// Mod+2 — spawn browser
COMPOSITOR.key.bind("browser", "Alt+2", () => {
  COMPOSITOR.process.spawn({ command: ["sh", "-c", "@@BROWSER@@"] });
});
// Mod+3 — spawn discord
COMPOSITOR.key.bind("discord", "Alt+3", () => {
  COMPOSITOR.process.spawn({ command: ["sh", "-c", "@@DISCORD@@ --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime --disable-gpu"] });
});
// Mod+4 — spawn steam
COMPOSITOR.key.bind("steam", "Alt+4", () => {
  COMPOSITOR.process.spawn({ command: ["steam"] });
});
// Mod+5 — spawn obs
COMPOSITOR.key.bind("obs", "Alt+5", () => {
  COMPOSITOR.process.spawn({ command: ["obs"] });
});

// --- Screenshots ---
// Mod+G — screenshot region
COMPOSITOR.key.bind("screenshot", "Alt+G", () => {
  COMPOSITOR.process.spawn({ command: "grim -g \"$(slurp)\" - | wl-copy" });
});
// Mod+Shift+G — screenshot full screen
COMPOSITOR.key.bind("screenshot-full", "Alt+Shift+G", () => {
  COMPOSITOR.process.spawn({ command: "grim - | wl-copy" });
});

// Alt+grave — color picker: niri-specific (niri msg pick-color), skipped

// Mod+Shift+C — wallpaper shuffle
COMPOSITOR.key.bind("wallpaper-shuffle", "Alt+Shift+C", () => {
  COMPOSITOR.process.spawn({
    command: ["sh", "-c", "killall swaybg; swaybg -i $(find @@WALLPAPER_PATH@@ -type f | shuf -n 1) -m fill &"],
  });
});

// --- Hardware/media keys ---
// XF86MonBrightnessUp
COMPOSITOR.key.bind("brightness-up", "XF86MonBrightnessUp", () => {
  COMPOSITOR.process.spawn({ command: ["brightnessctl", "set", "5%+"] });
});
// XF86MonBrightnessDown
COMPOSITOR.key.bind("brightness-down", "XF86MonBrightnessDown", () => {
  COMPOSITOR.process.spawn({ command: ["brightnessctl", "set", "5%-"] });
});
// XF86AudioRaiseVolume
COMPOSITOR.key.bind("volume-up", "XF86AudioRaiseVolume", () => {
  COMPOSITOR.process.spawn({ command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"] });
});
// XF86AudioLowerVolume
COMPOSITOR.key.bind("volume-down", "XF86AudioLowerVolume", () => {
  COMPOSITOR.process.spawn({ command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"] });
});
// XF86AudioMute
COMPOSITOR.key.bind("volume-mute", "XF86AudioMute", () => {
  COMPOSITOR.process.spawn({ command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] });
});
// XF86AudioPlay
COMPOSITOR.key.bind("media-play", "XF86AudioPlay", () => {
  COMPOSITOR.process.spawn({ command: ["playerctl", "play-pause"] });
});
// XF86AudioNext
COMPOSITOR.key.bind("media-next", "XF86AudioNext", () => {
  COMPOSITOR.process.spawn({ command: ["playerctl", "next"] });
});
// XF86AudioPrev
COMPOSITOR.key.bind("media-prev", "XF86AudioPrev", () => {
  COMPOSITOR.process.spawn({ command: ["playerctl", "previous"] });
});

// Mod+6 — output on: niri-specific (niri msg output), skipped
// Mod+7 — output off: niri-specific (niri msg output), skipped

// Exit: built-in Super+Shift+Q (hard-coded in compositor core)
// Reload: built-in Super+Shift+R (hard-coded in compositor core)

// ---------------------------------------------------------------------------
// Output configuration
// ---------------------------------------------------------------------------
COMPOSITOR.output.configure((_context) => {
  const display: DisplayConfigDraft = {};
  for (const output of _context.connected) {
    display[output.name] = {
      mode: "extend",
      resolution: "best",
      position: "auto",
      scale: 1.0,
    };
  }
  return display;
});

// ---------------------------------------------------------------------------
// Input configuration
// ---------------------------------------------------------------------------
COMPOSITOR.input.configure((input, _context) => {
  input.global = {
    touchpad: {
      tapToClick: true,
      naturalScroll: true,
      scrollMethod: "twoFinger",
      disableWhileTyping: true,
      scrollFactor: 0.3,
    },
    pointer: {
      pointerAccel: 0.0,
      accelProfile: "flat",
    },
    keyboard: {
      repeatRate: 60,
      repeatDelay: 250,
    },
  };
});

// Allow Super+drag to move windows
COMPOSITOR.pointer.bindWindowMoveModifier("Super");


// ---------------------------------------------------------------------------
// Event wiring: connect compositor events to the HybridWindowManager
// ---------------------------------------------------------------------------
COMPOSITOR.event.onOpen((window) => {
  HYBRID_WINDOW_MANAGER.onOpen(window);
});
COMPOSITOR.event.onFirstCommit((window) => {
  HYBRID_WINDOW_MANAGER.onFirstCommit(window);
});
COMPOSITOR.event.onStartClose((window) => {
  HYBRID_WINDOW_MANAGER.onStartClose(window);
});
COMPOSITOR.event.onClose((window) => {
  HYBRID_WINDOW_MANAGER.onClose(window);
});
COMPOSITOR.event.onFocus((window, focused) => {
  HYBRID_WINDOW_MANAGER.onFocus(window, focused);
  if (focused) {
    HYBRID_WINDOW_MANAGER.recordFocus(window.id);
  }
});
COMPOSITOR.event.onPointerMoveAsync((event) => {
  HYBRID_WINDOW_MANAGER.onPointerMove(event);
});
COMPOSITOR.event.onGestureSwipeAsync((event) => {
  HYBRID_WINDOW_MANAGER.onGestureSwipe(event);
});
COMPOSITOR.event.onOutputChange((event) => {
  HYBRID_WINDOW_MANAGER.onOutputChange(event);
});
COMPOSITOR.event.onCreateLayer(() => {
  HYBRID_WINDOW_MANAGER.refreshUsableAreaLayouts();
});
COMPOSITOR.event.onUpdateLayer(() => {
  HYBRID_WINDOW_MANAGER.refreshUsableAreaLayouts();
});
COMPOSITOR.event.onDestroyLayer(() => {
  HYBRID_WINDOW_MANAGER.refreshUsableAreaLayouts();
});
COMPOSITOR.event.onWindowResize((event) => {
  HYBRID_WINDOW_MANAGER.onWindowResize(event);
});
COMPOSITOR.event.onWindowMove((event) => {
  HYBRID_WINDOW_MANAGER.onWindowMove(event);
});
COMPOSITOR.event.onWindowMaximizeRequest((event) => {
  HYBRID_WINDOW_MANAGER.onWindowMaximizeRequest(event);
});
COMPOSITOR.event.onWindowMinimizeRequest((event) => {
  HYBRID_WINDOW_MANAGER.onWindowMinimizeRequest(event);
});
COMPOSITOR.event.onWindowFullscreenRequest((event) => {
  HYBRID_WINDOW_MANAGER.onWindowFullscreenRequest(event);
});
COMPOSITOR.event.onWindowActivateRequest((event) => {
  HYBRID_WINDOW_MANAGER.onWindowActivateRequest(event);
});

// ---------------------------------------------------------------------------
// Natural root rect: the managed window rect that includes border + titlebar
// ---------------------------------------------------------------------------
function naturalRootRect(window: WaylandWindow): ManagedWindowRect {
  const client = window.position;
  return {
    x: client.x - WINDOW_BORDER_PX,
    y: client.y - TITLEBAR_HEIGHT - WINDOW_BORDER_PX,
    width: client.width + WINDOW_BORDER_PX * 2,
    height: client.height + TITLEBAR_HEIGHT + WINDOW_BORDER_PX * 2,
  };
}

// ---------------------------------------------------------------------------
// Window composition
// ---------------------------------------------------------------------------
COMPOSITOR.window.composition = (window: WaylandWindow) => {
  const workspaceVisible = window.state[WINDOW_STATE_WORKSPACE_VISIBLE];
  const workspaceOffsetY = window.state[WINDOW_STATE_WORKSPACE_OFFSET_Y];
  const workspaceOpacity = window.state[WINDOW_STATE_WORKSPACE_OPACITY];
  const tileDragging = window.state[WINDOW_STATE_TILE_DRAGGING];
  const managedRect = computed(() => {
    const rect = window.state[WINDOW_STATE_RECT]();
    return {
      x: read(rect.x),
      y: read(rect.y) + workspaceOffsetY(),
      width: read(rect.width),
      height: read(rect.height),
    };
  });
  const forceRectSize = computed(
    () => window.isResizable() && !window.isTransient(),
  );
  const tiled = computed(
    () => window.state[WINDOW_STATE_TILED](),
  );
  const minimizeVisualIdle = window.state[WINDOW_STATE_MINIMIZE_VISUAL_IDLE];
  const inactive = computed(
    () => minimizeVisualIdle() || (!workspaceVisible() && !tileDragging()),
  );

  const borderColor = window.isFocused((focused) =>
    focused ? "#d7ba7d" : "#4f5666",
  );
  const titlebarBackground = window.isFocused((focused) =>
    focused ? "#1f243080" : "#2a2f3a80",
  );
  const titleColor = window.isFocused((focused) =>
    focused ? "#f5f7fa" : "#c9d1d9",
  );

  const titlebarStyle: SSDStyle = {
    height: TITLEBAR_HEIGHT,
    paddingX: 8,
    gap: 8,
    alignItems: "center",
    background: titlebarBackground,
  };

  const appIcon = (
    <AppIcon icon={window.icon} style={{ width: 16, height: 16 }} />
  );
  const label = (
    <Label
      text={window.title}
      style={{
        color: titleColor,
        fontSize: 13,
        fontWeight: 600,
        flexGrow: 1,
        flexShrink: 1,
        minWidth: 0,
      }}
    />
  );
  const minimizeButton = <MinimizeButton window={window} />;
  const maximizeButton = <MaximizeButton window={window} />;
  const closeButton = <CloseButton window={window} />;

  // Titlebar with app icon, label, and window buttons; plain client surface.
  const innerComponents = (
    <Box direction="column">
      <Box direction="row" style={titlebarStyle}>
        {appIcon}
        {label}
        {minimizeButton}
        {maximizeButton}
        {closeButton}
      </Box>
      <ClientWindow />
    </Box>
  );

  // Fullscreen: drop all chrome (titlebar, border, rounded corners) and let
  // the client surface fill its managed rect edge to edge. The rect is set to
  // the whole output by onWindowFullscreenRequest. Rendering nothing but the
  // bare ClientWindow is also what lets the tty backend promote the client
  // buffer to the primary plane (direct scanout).
  if (window.state[WINDOW_STATE_FULLSCREEN]()) {
    return (
      <ManagedWindow
        rect={managedRect}
        zIndex={HYBRID_WINDOW_MANAGER.getWindowZIndex(window)}
        visibleOutputs={window.state[WINDOW_STATE_VISIBLE_OUTPUTS]}
        opacity={workspaceOpacity}
        forceRectSize={forceRectSize}
        tiled={tiled}
        idle={inactive}
        interactive={inactive((value) => !value)}
        allowTearing={true}
      >
        <ClientWindow />
      </ManagedWindow>
    );
  }

  return (
    <ManagedWindow
      rect={managedRect}
      zIndex={HYBRID_WINDOW_MANAGER.getWindowZIndex(window)}
      visibleOutputs={window.state[WINDOW_STATE_VISIBLE_OUTPUTS]}
      opacity={workspaceOpacity}
      forceRectSize={forceRectSize}
      tiled={tiled}
      idle={inactive}
      interactive={inactive((value) => !value)}
    >
      <WindowBorder
        style={{
          border: { px: WINDOW_BORDER_PX, color: borderColor },
          borderRadius: 10,
          background: "#10131900",
          padding: 0,
          paddingX: 0,
          paddingRight: 0,
        }}
        interaction={{
          resizeHitArea: {
            edgePx: 8,
            cornerPx: 14,
          },
        }}
      >
        <Box direction="row">{innerComponents}</Box>
      </WindowBorder>
    </ManagedWindow>
  );
};

// ---------------------------------------------------------------------------
// Window buttons (titlebar)
// ---------------------------------------------------------------------------
const CloseButton = ({ window }: { window: WaylandWindow }) => {
  const [hover, setHover] = useState(false);
  const borderColor = hover((h) => (h ? "#00000000" : "#F0808030"));

  let icon: CompositionRenderable | null = null;
  if (hover()) {
    icon = (
      <Image
        src="./assets/x.svg"
        style={{
          width: 16,
          height: 16,
          position: "absolute",
          zIndex: 1,
          pointerEvents: "none",
        }}
      />
    );
  }

  return (
    <Box style={{ position: "relative", flexShrink: 0 }}>
      <Button
        onHoverChange={setHover}
        style={{
          width: 16,
          height: 16,
          borderRadius: 8,
          background: "#FFFFFF20",
          border: { px: 1, color: borderColor },
        }}
        onClick={() => window.close()}
      />
      {icon}
    </Box>
  );
};

const MaximizeButton = ({ window }: { window: WaylandWindow }) => {
  const [hover, setHover] = useState(false);

  const borderColor = computed(() => {
    if (!window.isResizable()) return "#00000000";
    return hover() ? "#00000000" : "#00BFFF30";
  });
  const shouldHover = computed(() => hover() && window.isResizable());

  let icon: CompositionRenderable | null = null;
  if (shouldHover()) {
    const src = window.isMaximized((maximized) =>
      maximized ? "./assets/minimize-2.svg" : "./assets/maximize-2.svg",
    );
    icon = (
      <Image
        src={src}
        style={{
          width: 16,
          height: 16,
          position: "absolute",
          zIndex: 1,
          pointerEvents: "none",
        }}
      />
    );
  }

  return (
    <Box style={{ position: "relative", flexShrink: 0 }}>
      <Button
        onHoverChange={setHover}
        style={{
          width: 16,
          height: 16,
          borderRadius: 8,
          background: "#FFFFFF20",
          border: { px: 1, color: borderColor },
        }}
        onClick={() => {
          if (!read(window.isResizable)) return;
          if (read(window.isMaximized)) {
            window.unmaximize();
          } else {
            window.maximize();
          }
        }}
      />
      {icon}
    </Box>
  );
};

const MinimizeButton = ({ window }: { window: WaylandWindow }) => {
  const [hover, setHover] = useState(false);
  const borderColor = hover((h) => (h ? "#00000000" : "#F8FF7530"));

  let icon: CompositionRenderable | null = null;
  if (hover()) {
    icon = (
      <Image
        src="./assets/minus.svg"
        style={{
          width: 16,
          height: 16,
          position: "absolute",
          zIndex: 1,
          pointerEvents: "none",
        }}
      />
    );
  }

  return (
    <Box style={{ position: "relative", flexShrink: 0 }}>
      <Button
        onHoverChange={setHover}
        style={{
          width: 16,
          height: 16,
          borderRadius: 8,
          background: "#FFFFFF20",
          border: { px: 1, color: borderColor },
        }}
        onClick={() => window.minimize()}
      />
      {icon}
    </Box>
  );
};
