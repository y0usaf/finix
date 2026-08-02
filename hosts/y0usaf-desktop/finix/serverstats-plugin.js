// Server Stats — persistent server performance widget for the Hermes desktop.
// v2: native look — app components (Badge, Separator, Skeleton) + theme vars.
//
// Data: server dashboard plugin API /api/plugins/serverstats/stats via ctx.rest
// (see ~/.hermes/plugins/serverstats/ on y0usaf-server).
import { jsx } from "react/jsx-runtime";
import { useEffect, useState } from "react";
import { PANES_AREA, STATUSBAR_AREAS, Badge, Separator, Skeleton } from "@hermes/plugin-sdk";

const POLL_MS = 4000;

const fmtBytes = (b) =>
  b >= 1 << 30
    ? (b / (1 << 30)).toFixed(1) + "G"
    : b >= 1 << 20
      ? (b / (1 << 20)).toFixed(0) + "M"
      : b + "B";

const fmtUptime = (s) => {
  const d = Math.floor(s / 86400);
  const h = Math.floor((s % 86400) / 3600);
  const m = Math.floor((s % 3600) / 60);
  return d > 0 ? `${d}d ${h}h` : h > 0 ? `${h}h ${m}m` : `${m}m`;
};

async function fetchStats(ctx) {
  try {
    const res = await ctx.rest("/stats", { timeoutMs: 8000 });
    if (!res) return null;
    const body = typeof res === "object" && "data" in res ? res.data : res;
    return body && typeof body === "object" ? body : null;
  } catch (err) {
    return null;
  }
}

function useStats(ctx) {
  const [stats, setStats] = useState(null);
  const [error, setError] = useState(false);
  useEffect(() => {
    let alive = true;
    const tick = async () => {
      const s = await fetchStats(ctx);
      if (!alive) return;
      setStats(s);
      setError(!s);
    };
    tick();
    const t = setInterval(tick, POLL_MS);
    return () => {
      alive = false;
      clearInterval(t);
    };
  }, [ctx]);
  return { stats, error };
}

// ---- native-style building blocks -----------------------------------------

const labelStyle = {
  fontSize: 9,
  letterSpacing: "0.06em",
  textTransform: "uppercase",
  color: "var(--ui-text-quaternary)",
  marginBottom: 3,
  whiteSpace: "nowrap",
};

const valueStyle = {
  fontSize: 12,
  fontVariantNumeric: "tabular-nums",
  color: "var(--ui-text-secondary)",
  whiteSpace: "nowrap",
};

function Col({ label, children, minWidth }) {
  return jsx("div", {
    style: { minWidth: minWidth || 0, display: "flex", flexDirection: "column", justifyContent: "center" },
    children: [jsx("div", { style: labelStyle, children: label }), children],
  });
}

function MiniBar({ pct, width }) {
  return jsx("div", {
    style: {
      width: width || 72,
      height: 3,
      borderRadius: 2,
      background: "var(--ui-stroke-secondary)",
      overflow: "hidden",
      marginTop: 4,
    },
    children: jsx("div", {
      style: {
        width: `${Math.min(100, Math.max(0, pct))}%`,
        height: "100%",
        background: "var(--ui-accent)",
        borderRadius: 2,
      },
    }),
  });
}

function VDivider() {
  return jsx(Separator, {
    orientation: "vertical",
    style: { alignSelf: "stretch", margin: "0 14px" },
  });
}

function SkeletonLine({ w }) {
  return jsx(Skeleton, { style: { width: w || 64, height: 10 } });
}

// ---- content ---------------------------------------------------------------

function StatsTable({ stats }) {
  const mem = stats.mem || {};
  const load = stats.load || {};
  const disk = stats.disk_persist;
  const procs = stats.top_procs ? stats.top_procs.slice(0, 3) : [];

  return jsx("div", {
    style: { display: "flex", alignItems: "center", height: "100%" },
    children: [
      jsx(Col, {
        label: "CPU",
        children: jsx(Badge, {
          style: { fontVariantNumeric: "tabular-nums" },
          children: `${stats.cpu_percent ?? "–"}%`,
        }),
      }),
      VDivider(),
      jsx(Col, {
        label: "LOAD 1/5/15",
        children: jsx("div", {
          style: valueStyle,
          children: `${(load["1"] ?? "–").toString()} / ${(load["5"] ?? "–").toString()} / ${(load["15"] ?? "–").toString()}`,
        }),
      }),
      VDivider(),
      jsx(Col, {
        label: "MEMORY",
        children: [
          jsx("div", {
            style: valueStyle,
            children: `${fmtBytes(mem.used ?? 0)} / ${fmtBytes(mem.total ?? 0)} · ${mem.percent ?? "–"}%`,
          }),
          jsx(MiniBar, { pct: mem.percent ?? 0 }),
        ],
      }),
      VDivider(),
      jsx(Col, {
        label: "DISK /persist",
        children: [
          jsx("div", {
            style: valueStyle,
            children: disk ? `${fmtBytes(disk.used)} / ${fmtBytes(disk.total)} · ${disk.percent}%` : "–",
          }),
          jsx(MiniBar, { pct: disk ? disk.percent : 0 }),
        ],
      }),
      VDivider(),
      jsx(Col, {
        label: "TOP RSS",
        children: procs.map((p) =>
          jsx("div", {
            key: p.pid,
            style: { display: "flex", gap: 8, fontSize: 11, lineHeight: "15px", fontVariantNumeric: "tabular-nums" },
            children: [
              jsx("span", {
                style: { color: "var(--ui-text-secondary)", maxWidth: 110, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" },
                children: p.name,
              }),
              jsx("span", { style: { color: "var(--ui-text-quaternary)" }, children: fmtBytes(p.rss) }),
            ],
          }),
        ),
      }),
      VDivider(),
      jsx(Col, {
        label: "HOST",
        minWidth: 90,
        children: [
          jsx("div", {
            style: { display: "flex", alignItems: "center", gap: 5 },
            children: [
              jsx("span", {
                style: { width: 7, height: 7, borderRadius: "50%", background: "var(--ui-accent)", display: "inline-block" },
              }),
              jsx("span", { style: valueStyle, children: stats.host || "–" }),
            ],
          }),
          jsx("div", { style: { ...valueStyle, fontSize: 11, color: "var(--ui-text-quaternary)", marginTop: 2 }, children: `up ${fmtUptime(stats.uptime_s ?? 0)} · ${stats.cores ?? "–"} cores` }),
        ],
      }),
    ],
  });
}

function ServerStatsPane({ ctx }) {
  const { stats, error } = useStats(ctx);
  if (error) {
    return jsx("div", {
      style: { color: "var(--ui-text-secondary)", fontSize: 12, fontFamily: "monospace", padding: "6px 2px" },
      children: "serverstats: offline — check ~/.hermes/plugins/serverstats on y0usaf-server",
    });
  }
  if (!stats) {
    return jsx("div", {
      style: { display: "flex", alignItems: "center", gap: 16, height: "100%" },
      children: [1, 2, 3, 4, 5].map((i) => jsx(SkeletonLine, { key: i, w: 64 })),
    });
  }
  return jsx(StatsTable, { stats });
}

function StatusChip({ ctx }) {
  const { stats, error } = useStats(ctx);
  const mem = stats ? stats.mem : null;
  const text =
    error || !stats ? "srv ●—" : `srv ${stats.cpu_percent}% · ${fmtBytes(mem.used)}/${fmtBytes(mem.total)}`;
  return jsx("span", {
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 4,
      fontSize: 11,
      padding: "0 6px",
      color: "var(--ui-text-secondary)",
      fontVariantNumeric: "tabular-nums",
      whiteSpace: "nowrap",
    },
    children: [
      jsx("span", {
        style: {
          width: 7,
          height: 7,
          borderRadius: "50%",
          background: error ? "var(--ui-text-quaternary)" : "var(--ui-accent)",
          display: "inline-block",
        },
      }),
      text,
    ],
  });
}

export default {
  id: "serverstats",
  name: "Server Stats",
  register(ctx) {
    ctx.register({
      id: "serverstats-status",
      area: STATUSBAR_AREAS.right,
      order: 100,
      render: () => jsx(StatusChip, { ctx }),
    });

    ctx.register({
      id: "serverstats-pane",
      area: PANES_AREA,
      title: "Server Stats",
      order: 50,
      data: {
        placement: "bottom",
        dock: { pane: "workspace", pos: "bottom" },
        height: "88px",
      },
      render: () => jsx(ServerStatsPane, { ctx }),
    });
  },
};
