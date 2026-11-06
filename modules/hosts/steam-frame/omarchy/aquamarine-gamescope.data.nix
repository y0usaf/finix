{
  add,
  del,
  git,
  section,
  ...
}: [
  (git "src/backend/Wayland.cpp" "8905adc..c6de7cc 100644" [
    (section 122 "bool Aquamarine::CWaylandBackend::start() {" [
      "            initSeat();"
      "        } else if (NAME == \"xdg_wm_base\") {"
      "            TRACE(backend->log(AQ_LOG_TRACE, std::format(\"  > binding to global: {} (version {}) with id {}\", name, 6, id)));"
      (del "            waylandState.xdg = makeShared<CCXdgWmBase>((wl_proxy*)wl_registry_bind((wl_registry*)waylandState.registry->resource(), id, &xdg_wm_base_interface, 6));")
      (add "            waylandState.xdg = makeShared<CCXdgWmBase>((wl_proxy*)wl_registry_bind((wl_registry*)waylandState.registry->resource(), id, &xdg_wm_base_interface, std::min(version, 6u)));")
      "            initShell();"
      "        } else if (NAME == \"wl_compositor\") {"
      "            TRACE(backend->log(AQ_LOG_TRACE, std::format(\"  > binding to global: {} (version {}) with id {}\", name, 6, id)));"
      (del "            waylandState.compositor = makeShared<CCWlCompositor>((wl_proxy*)wl_registry_bind((wl_registry*)waylandState.registry->resource(), id, &wl_compositor_interface, 6));")
      (add "            waylandState.compositor = makeShared<CCWlCompositor>((wl_proxy*)wl_registry_bind((wl_registry*)waylandState.registry->resource(), id, &wl_compositor_interface, std::min(version, 6u)));")
      "        } else if (NAME == \"wl_shm\") {"
      "            TRACE(backend->log(AQ_LOG_TRACE, std::format(\"  > binding to global: {} (version {}) with id {}\", name, 1, id)));"
      "            waylandState.shm = makeShared<CCWlShm>((wl_proxy*)wl_registry_bind((wl_registry*)waylandState.registry->resource(), id, &wl_shm_interface, 1));"
    ])
    (section 541 "Aquamarine::CWaylandOutput::CWaylandOutput(const std::string& name_, Hyprutils::" [
      "    waylandState.xdgToplevel->setConfigure([this](CCXdgToplevel* r, int32_t w, int32_t h, wl_array* arr) {"
      "        backend->backend->log(AQ_LOG_DEBUG, std::format(\"Output {}: configure toplevel with {}x{}\", name, w, h));"
      "        if (w == 0 || h == 0) {"
      (del "            backend->backend->log(AQ_LOG_DEBUG, std::format(\"Output {}: w/h is 0, sending default hardcoded 1280x720\", name));")
      (del "            w = 1280;")
      (del "            h = 720;")
      (add "            if (waylandState.surfaceSize.x > 0 && waylandState.surfaceSize.y > 0) {")
      (add "                w = waylandState.surfaceSize.x;")
      (add "                h = waylandState.surfaceSize.y;")
      (add "            } else {")
      (add "                backend->backend->log(AQ_LOG_DEBUG, std::format(\"Output {}: w/h is 0, sending default hardcoded 1280x720\", name));")
      (add "                w = 1280;")
      (add "                h = 720;")
      (add "            }")
      "        }"
      "        events.state.emit(SStateEvent{.size = {w, h}});"
      "        // Kick off the first frame synchronously: the consumer expects events.frame in"
    ])
    (section 567 "Aquamarine::CWaylandOutput::CWaylandOutput(const std::string& name_, Hyprutils::" [
      ""
      "    inputRegion->sendDestroy();"
      ""
      (add "    wl_display_flush(backend->waylandState.display);")
      (add "")
      "    backend->backend->log(AQ_LOG_DEBUG, std::format(\"Output {}: initialized\", name));"
      "}"
      ""
    ])
  ])
]
