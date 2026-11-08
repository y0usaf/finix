// ==UserScript==
// @name            Undiscord
// @description     Delete matching Discord messages and optionally remove your own reactions
// @version         5.2.8
// @author          victornpb, SuicidaI-Idol, y0usaf
// @homepageURL     https://github.com/y0usaf/undiscord
// @supportURL      https://github.com/y0usaf/undiscord/issues
// @match           https://*.discord.com/app
// @match           https://*.discord.com/channels/*
// @match           https://*.discord.com/login
// @license         MIT
// @namespace       https://github.com/victornpb/deleteDiscordMessages
// @icon            https://victornpb.github.io/undiscord/images/icon128.png
// @contributionURL https://www.buymeacoffee.com/vitim
// @grant           none
// @attribution     Original project (https://github.com/victornpb/undiscord)
// ==/UserScript==
(function () {
   'use strict';

   /* rollup-plugin-baked-env */
   const VERSION = "5.2.8";

   var themeCss = (`
/* undiscord window */
#undiscord.browser { box-shadow: var(--shadow-border), var(--shadow-high); border: 1px solid var(--border-subtle); overflow: hidden; }
#undiscord.container,
#undiscord .container { background-color: var(--background-surface-high); border-radius: 8px; box-sizing: border-box; cursor: default; flex-direction: column; }
#undiscord .header { background-color: var(--background-tertiary); height: 48px; align-items: center; min-height: 48px; padding: 0 16px; display: flex; color: var(--header-secondary); cursor: grab; }
#undiscord .header .icon { color: var(--interactive-normal); margin-right: 8px; flex-shrink: 0; width: 24; height: 24; }
#undiscord .header .icon:hover { color: var(--interactive-hover); }
#undiscord .header h3 { font-size: 16px; line-height: 20px; font-weight: 500; font-family: var(--font-display); color: var(--header-primary); flex-shrink: 0; margin-right: 16px; }
#undiscord .spacer { flex-grow: 1; }
#undiscord .header .vert-divider { width: 1px; height: 24px; background-color: var(--background-modifier-accent); margin-right: 16px; flex-shrink: 0; }
#undiscord legend,
#undiscord label { color: var(--header-secondary); font-size: 12px; line-height: 16px; font-weight: 500; text-transform: uppercase; cursor: default; font-family: var(--font-display); margin-bottom: 8px; }
#undiscord .multiInput { display: flex; align-items: center; font-size: 16px; box-sizing: border-box; width: 100%; border-radius: 3px; color: var(--text-default); background-color: var(--input-background); border: none; transition: border-color 0.2s ease-in-out 0s; }
#undiscord .multiInput :first-child { flex-grow: 1; }
#undiscord .multiInput button:last-child { margin-right: 4px; }
#undiscord .input { font-size: 16px; width: 100%; transition: border-color 0.2s ease-in-out 0s; padding: 10px; height: 44px; background-color: var(--input-background); border: 1px solid var(--input-border); border-radius: 8px; box-sizing: border-box; color: var(--text-default); }
#undiscord fieldset { margin-top: 16px; }
#undiscord .input-wrapper { display: flex; align-items: center; font-size: 16px; box-sizing: border-box; width: 100%; border-radius: 3px; color: var(--text-default); background-color: var(--input-background); border: none; transition: border-color 0.2s ease-in-out 0s; }
#undiscord input[type="text"],
#undiscord input[type="search"],
#undiscord input[type="password"],
#undiscord input[type="datetime-local"],
#undiscord input[type="number"],
#undiscord input[type="range"] { background-color: var(--input-background); border: 1px solid var(--input-border); border-radius: 8px; box-sizing: border-box; color: var(--text-default); font-size: 16px; height: 44px; padding: 12px 10px; transition: border-color .2s ease-in-out; width: 100%; }
#undiscord .divider,
#undiscord hr { border: none; margin-bottom: 24px; padding-bottom: 4px; border-bottom: 1px solid var(--background-modifier-accent); }
#undiscord .sectionDescription { margin-bottom: 16px; color: var(--header-secondary); font-size: 14px; line-height: 20px; font-weight: 400; }
#undiscord a { color: var(--text-link); text-decoration: none; }
#undiscord .btn,
#undiscord button { position: relative; display: flex; -webkit-box-pack: center; justify-content: center; -webkit-box-align: center; align-items: center; box-sizing: border-box; background: none; border: none; border-radius: 3px; font-size: 14px; font-weight: 500; line-height: 16px; padding: 2px 16px; user-select: none; /* sizeSmall */     width: 60px; height: 32px; min-width: 60px; min-height: 32px; /* lookFilled colorPrimary */     color: rgb(255, 255, 255); background-color: var(--button-secondary-background); }
#undiscord .sizeMedium { width: 96px; height: 38px; min-width: 96px; min-height: 38px; }
#undiscord .sizeMedium.icon { width: 38px; min-width: 38px; }
#undiscord sup { vertical-align: top; }
/* lookFilled colorPrimary */
#undiscord .accent { background-color: var(--brand-experiment); }
#undiscord .danger { background-color: var(--button-danger-background); }
#undiscord .positive { background-color: var(--button-positive-background); }
#undiscord .info { font-size: 12px; line-height: 16px; padding: 8px 10px; color: var(--text-muted); }
/* Scrollbar */
#undiscord .scroll::-webkit-scrollbar { width: 8px; height: 8px; }
#undiscord .scroll::-webkit-scrollbar-corner { background-color: transparent; }
#undiscord .scroll::-webkit-scrollbar-thumb { background-clip: padding-box; border: 2px solid transparent; border-radius: 4px; background-color: var(--scrollbar-thin-thumb); min-height: 40px; }
#undiscord .scroll::-webkit-scrollbar-track { border-color: var(--scrollbar-thin-track); background-color: var(--scrollbar-thin-track); border: 2px solid var(--scrollbar-thin-track); }
/* fade scrollbar */
#undiscord .scroll::-webkit-scrollbar-thumb,
#undiscord .scroll::-webkit-scrollbar-track { visibility: hidden; }
#undiscord .scroll:hover::-webkit-scrollbar-thumb,
#undiscord .scroll:hover::-webkit-scrollbar-track { visibility: visible; }
/**** functional classes ****/
#undiscord.redact .priv { display: none !important; }
#undiscord.redact x:not(:active) { color: transparent !important; background-color: var(--primary-700) !important; cursor: default; user-select: none; }
#undiscord.redact x:hover { position: relative; }
#undiscord.redact x:hover::after { content: "Redacted information (Streamer mode: ON)"; position: absolute; display: inline-block; top: -32px; left: -20px; padding: 4px; width: 150px; font-size: 8pt; text-align: center; white-space: pre-wrap; background-color: var(--background-floating); -webkit-box-shadow: var(--elevation-high); box-shadow: var(--elevation-high); color: var(--text-default); border-radius: 5px; pointer-events: none; }
#undiscord.redact [priv] { -webkit-text-security: disc !important; }
#undiscord :disabled { opacity: 0.6; cursor: not-allowed; }
/**** layout and utility classes ****/
#undiscord,
#undiscord * { box-sizing: border-box; }
#undiscord .col { display: flex; flex-direction: column; }
#undiscord .row { display: flex; flex-direction: row; align-items: center; }
#undiscord .mb1 { margin-bottom: 8px; }
#undiscord .log { margin-bottom: 0.25em; }
#undiscord:not(.verbose) .log:not(.log-del) { white-space: pre-wrap; overflow-wrap: anywhere; }
#undiscord .log-debug { color: inherit; }
#undiscord .log-info { color: #00b0f4; }
#undiscord .log-verb { color: #72767d; }
#undiscord .log-warn { color: #faa61a; }
#undiscord .log-error { color: #f04747; }
#undiscord .log-success { color: #43b581; }
`);

   var mainCss = (`
/**** Undiscord Button ****/
#undicord-btn { position: relative; width: auto; height: 24px; margin: 0 8px; cursor: pointer; color: var(--interactive-normal); flex: 0 0 auto; }
#undicord-btn progress { position: absolute; top: 23px; left: -4px; width: 32px; height: 12px; display: none; }
#undicord-btn.running { color: var(--button-danger-background) !important; }
#undicord-btn.running progress { display: block; }
/**** Undiscord Interface ****/
#undiscord { position: fixed; z-index: 100; top: 58px; right: 10px; display: flex; flex-direction: column; width: 940px; height: 80vh; min-width: 720px; max-width: 100vw; min-height: 448px; max-height: 100vh; color: var(--text-normal); border-radius: 4px; background-color: var(--background-secondary); box-shadow: var(--elevation-stroke), var(--elevation-high); will-change: top, left, width, height; }
#undiscord .header .icon { cursor: pointer; }
#undiscord .window-body { height: calc(100% - 48px); }
#undiscord .sidebar { overflow: hidden scroll; overflow-y: auto; width: 270px; min-width: 250px; height: 100%; max-height: 100%; padding: 8px; background: var(--bg-overlay-4, var(--background-base-lowest)); }
#undiscord .sidebar legend,
#undiscord .sidebar label { display: block; width: 100%; }
#undiscord .main { display: flex; max-width: calc(100% - 250px); background-color: var(--bg-overlay-chat, var(--background-base-lower)); flex-grow: 1; }
#undiscord.hide-sidebar .sidebar { display: none; }
#undiscord.hide-sidebar .main { max-width: 100%; }
#undiscord #logArea { font-family: Consolas, Liberation Mono, Menlo, Courier, monospace; font-size: 0.75rem; overflow: auto; padding: 10px; user-select: text; flex-grow: 1; flex-grow: 1; cursor: auto; }
#undiscord .tbar { padding: 8px; background-color: var(--bg-overlay-2, var(--__header-bar-background)); }
#undiscord .tbar button { margin-right: 4px; margin-bottom: 4px; }
#undiscord .tbar .preScanStatus {
  display: none;
  margin: 0 0 4px;
  font-size: 12px;
  line-height: 16px;
  color: var(--u-muted);
  text-align: center;
  width: 100%;
  align-self: center;
}
#undiscord .tbar .progressRow { gap: 8px; align-items: center; justify-content: flex-start; padding: 2px 0 0; width: 100%; }
#undiscord .tbar .progressRow #progressBar { flex: 1 1 auto; width: auto; min-width: 0; margin-top: 0; }
#undiscord #progressBarPercent {
  width: 56px;
  min-width: 56px;
  flex: 0 0 auto;
  font-size: 13px;
  font-weight: 700;
  line-height: 1;
  font-variant-numeric: tabular-nums;
  text-align: center;
  color: var(--u-text);
}
#undiscord .footer { cursor: se-resize; padding-right: 30px; }
#undiscord .footer #progressPercent { padding: 0 1em; font-size: small; color: var(--interactive-muted); flex-grow: 1; }
.resize-handle { position: absolute; bottom: -15px; right: -15px; width: 30px; height: 30px; transform: rotate(-45deg); background: repeating-linear-gradient(0, var(--background-modifier-accent), var(--background-modifier-accent) 1px, transparent 2px, transparent 4px); cursor: nwse-resize; }
/**** Elements ****/
#undiscord summary { font-size: 16px; font-weight: 500; line-height: 20px; position: relative; overflow: hidden; margin-bottom: 2px; padding: 6px 10px; cursor: pointer; white-space: nowrap; text-overflow: ellipsis; color: var(--interactive-normal); border-radius: 4px; flex-shrink: 0; }
#undiscord fieldset { padding-left: 8px; }
#undiscord legend a { float: right; text-transform: initial; }
#undiscord progress { height: 8px; margin-top: 4px; flex-grow: 1; }
#undiscord .importJson { display: flex; flex-direction: row; }
#undiscord .importJson button { margin-left: 5px; width: fit-content; }
`);
var undiscordUiCss = (`
/* ===== Undiscord: UI palette stable (does not depend on Discord theme) ===== */
#undiscord{
  --u-bg: #0f1115;
  --u-panel: #151822;
  --u-panel2: #10131a;
  --u-border: rgba(255,255,255,.10);
  --u-text: rgba(255,255,255,.92);
  --u-muted: rgba(255,255,255,.65);
  --u-link: #7ab7ff;
  --u-btn: #2b3245;
  --u-btn-hover: #3a4460;
  --u-danger: #b83b3b;
  --u-danger-hover: #d04b4b;
  --u-input: #0c0f15;
  --u-focus: rgba(122,183,255,.35);
  /* Compact deleted-log global scale (date, text, avatar, etc.) */
  --u-compact-scale: 1.05;

  background: var(--u-bg) !important;
  color: var(--u-text) !important;
  border: 1px solid var(--u-border) !important;
  border-radius: 10px !important;
  box-shadow: 0 16px 60px rgba(0,0,0,.55) !important;
}

/* Header */
#undiscord .header{
  background: var(--u-panel) !important;
  color: var(--u-text) !important;
  border-bottom: 1px solid var(--u-border) !important;
}
#undiscord .header h3{ color: var(--u-text) !important; }
#undiscord .header span{ color: var(--u-muted) !important; }
#undiscord .header .vert-divider{ background: var(--u-border) !important; }
#undiscord .header .icon{ color: var(--u-muted) !important; }
#undiscord .header .icon:hover{ color: var(--u-text) !important; }

/* Layout */
#undiscord .sidebar{
  background: linear-gradient(180deg, rgba(255,255,255,.03), rgba(255,255,255,.01)) , var(--u-panel2) !important;
  border-right: 1px solid var(--u-border) !important;
  padding: 12px 10px !important;
}
#undiscord .sidebar details{
  background: rgba(255,255,255,.02);
  border: 1px solid rgba(255,255,255,.06);
  border-radius: 10px;
  padding: 6px 6px 4px;
  margin-bottom: 10px;
}
#undiscord .sidebar summary{
  color: var(--u-text) !important;
  background: rgba(255,255,255,.03);
  border: 1px solid rgba(255,255,255,.06);
  border-radius: 8px;
  padding: 6px 10px;
}
#undiscord .sidebar summary:hover{
  background: rgba(255,255,255,.05);
}
#undiscord .sidebar fieldset{
  padding-left: 6px;
  margin-top: 10px;
}
#undiscord .sidebar hr{
  margin: 10px 0;
  border-bottom: 1px solid rgba(255,255,255,.08);
}
#undiscord .sidebar .sectionDescription{
  font-size: 12px;
  line-height: 16px;
}
#undiscord .sidebar .input,
#undiscord .sidebar input[type="text"],
#undiscord .sidebar input[type="search"],
#undiscord .sidebar input[type="password"],
#undiscord .sidebar input[type="datetime-local"],
#undiscord .sidebar input[type="number"]{
  height: 38px !important;
  font-size: 14px !important;
  padding: 8px 10px !important;
}
#undiscord .sidebar input[type="checkbox"]{
  height: auto !important;
  width: auto !important;
  margin-right: 8px;
  padding: 0 !important;
}
#undiscord .main{
  background: var(--u-bg) !important;
}

/* Texts */
#undiscord summary{ color: var(--u-text) !important; }
#undiscord legend,
#undiscord label{ color: var(--u-muted) !important; }
#undiscord .sectionDescription{ color: var(--u-muted) !important; }
#undiscord .info{ color: var(--u-muted) !important; }
#undiscord a{ color: var(--u-link) !important; }

/* Inputs */
#undiscord input,
#undiscord .input,
#undiscord input[type="text"],
#undiscord input[type="search"],
#undiscord input[type="password"],
#undiscord input[type="datetime-local"],
#undiscord input[type="number"]{
  background: var(--u-input) !important;
  color: var(--u-text) !important;
  border: 1px solid var(--u-border) !important;
  border-radius: 10px !important;
}
#undiscord input:focus{
  outline: none !important;
  box-shadow: 0 0 0 3px var(--u-focus) !important;
  border-color: rgba(122,183,255,.6) !important;
}

/* Buttons */
#undiscord button{
  background: var(--u-btn) !important;
  color: var(--u-text) !important;
  border: 1px solid var(--u-border) !important;
  border-radius: 10px !important;
}
#undiscord button:hover{
  background: var(--u-btn-hover) !important;
}
#undiscord button.danger{
  background: var(--u-danger) !important;
  border-color: rgba(255,255,255,.12) !important;
}
#undiscord button.danger:hover{
  background: var(--u-danger-hover) !important;
}

/* Toolbars */
#undiscord .tbar{
  background: var(--u-panel) !important;
  border-bottom: 1px solid var(--u-border) !important;
}
#undiscord .tbar > .row:first-child{
  position: relative;
  padding-right: 112px;
  min-height: 38px;
}
#undiscord #stop{
  position: absolute;
  right: 0;
  top: 0;
  z-index: 4;
}
#undiscord .tbar.footer{
  border-top: 1px solid var(--u-border) !important;
  border-bottom: none !important;
}

/* Conversation badge */
#undiscord .channelBadge,
#undiscord .convBadge{
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 0 10px;
  margin-right: 6px;
  margin-bottom: 4px;
  border-radius: 999px;
  background: rgba(255,255,255,.06);
  border: 1px solid rgba(255,255,255,.12);
  height: 38px;
  box-sizing: border-box;
  max-width: 280px;
  overflow: hidden;
}
#undiscord .channelBadge{
  max-width: 220px;
}
#undiscord .convBadge img{
  width: 28px;
  height: 28px;
  border-radius: 999px;
  flex: 0 0 auto;
  box-shadow: 0 0 0 1px rgba(255,255,255,.18);
}
#undiscord .channelBadge .channelHash{
  font-size: 14px;
  font-weight: 700;
  color: var(--u-muted) !important;
}
#undiscord .channelBadge .channelName,
#undiscord .convBadge .convName{
  font-size: 14px;
  font-weight: 600;
  color: var(--u-text) !important;
  padding-right: 2px;
  white-space: nowrap;
  text-overflow: ellipsis;
  overflow: hidden;
}
#undiscord .allChannelsToggle{
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-right: 8px;
  margin-bottom: 4px;
  padding: 0 10px;
  height: 38px;
  border-radius: 999px;
  border: 1px solid rgba(255,255,255,.12);
  background: rgba(255,255,255,.04);
  color: var(--u-muted);
  font-size: 12px;
  text-transform: none;
  white-space: nowrap;
}
#undiscord .allChannelsToggle input{
  margin: 0;
}
#undiscord.verbose .convBadge{
  display: none !important;
}
#undiscord.verbose .channelBadge{
  display: none !important;
}
#undiscord.verbose .allChannelsToggle{
  display: none !important;
}

/* Log */
#undiscord #logArea{
  background: transparent !important;
  color: var(--u-text) !important;
}
#undiscord .log-warn{ color: #ffcc66 !important; }
#undiscord .log-error{ color: #ff6b6b !important; }
#undiscord .log-success{ color: #6bff95 !important; }
#undiscord .log-info{ color: #78d6ff !important; }
#undiscord .log-verb{ color: rgba(255,255,255,.55) !important; }

/* Progress */
#undiscord progress{
  appearance: none !important;
  -webkit-appearance: none !important;
  -moz-appearance: none !important;
  background: rgba(255,255,255,.08) !important;
  border: 1px solid rgba(255,255,255,.12) !important;
  border-radius: 999px !important;
  overflow: hidden !important;
  height: 10px !important;
}
#undiscord progress::-webkit-progress-bar{
  background: rgba(255,255,255,.08) !important;
  border-radius: 999px !important;
}
#undiscord progress::-webkit-progress-value{
  background: linear-gradient(90deg, #4c9aff, #66b4ff) !important;
  border-radius: 999px !important;
}
#undiscord #progressBarPercent{
  color: rgba(255,255,255,.92) !important;
  background: none !important;
  border: none !important;
}
/* Hide authorID */
#undiscord.hide-author #authorId,
#undiscord.hide-author #authorId.priv {
  -webkit-text-security: disc !important;
  text-security: disc !important;
}

/* Hide message text (compact + verbose log UIs) */
#undiscord .msgHidden { display: none; color: var(--u-muted) !important; font-style: italic; }
#undiscord.hide-text .msgText { display: none; }
#undiscord.hide-text .msgHidden { display: inline; }

/* Hide author identity in logs (compact: avatar + display name; verbose: author id) */
#undiscord .authorHidden { display: none; color: var(--u-muted) !important; font-style: italic; }
#undiscord.hide-author .authorText { display: none; }
#undiscord.hide-author .authorHidden { display: inline; }
#undiscord.hide-author img.authorAvatar { display: none !important; }

/* Compact-mode polish when hiding */
#undiscord.hide-author:not(.verbose) .log-del{
  grid-template-columns: calc(88px * var(--u-compact-scale)) minmax(0, 1fr) auto;
  column-gap: calc(10px * var(--u-compact-scale));
}
#undiscord.hide-author:not(.verbose) .log-del img.authorAvatar{ display: none !important; }
#undiscord.hide-author:not(.verbose) .log-del .head{ display: none; }
#undiscord.hide-author:not(.verbose) .log-del .txt{ min-width: 0; }
#undiscord.hide-author:not(.verbose) .log-del .content{ margin-top: 2px; }
#undiscord.hide-text:not(.verbose) .log-del .msgHidden{
  display: inline-block;
  padding: 1px 8px;
  border-radius: 999px;
  border: 1px solid rgba(255,255,255,.10);
  background: rgba(255,255,255,.04);
  white-space: nowrap;
  word-break: normal;
  overflow-wrap: normal;
}
/* ===== FINISHED STATE ===== */
#undiscord.finished #progressBar::-webkit-progress-value { background: #2ecc71 !important; }
#undiscord.finished #progressBar { border-radius: 999px !important; }

#undiscord.finished #undicord-btn progress::-webkit-progress-value { background: #2ecc71 !important; }

/* Firefox */
#undiscord.finished #progressBar::-moz-progress-bar { background: #2ecc71 !important; }
#undiscord.finished #undicord-btn progress::-moz-progress-bar { background: #2ecc71 !important; }

/* Outcome message */
#undiscord .doneBanner{
  display:block;
  margin-top: 6px;
  padding: 8px 10px;
  border-radius: 10px;
  border: 1px solid rgba(46, 204, 113, .35);
  background: rgba(46, 204, 113, .10);
  color: rgba(255,255,255,.9);
  font-size: 13px;
}
#undiscord .doneBanner[hidden]{ display:none; }
#undiscord .doneBanner[data-tone="warning"]{ border-color:rgba(255,204,102,.5); background:rgba(255,204,102,.12); }
#undiscord .doneBanner[data-tone="error"]{ border-color:rgba(255,107,107,.5); background:rgba(255,107,107,.12); }
#undiscord .doneBanner[data-tone="info"]{ border-color:rgba(122,183,255,.5); background:rgba(122,183,255,.12); }

/* Hide Author ID redaction (independent from Streamer mode) */
#undiscord.hide-author x.priv-author:not(:active) {
  color: transparent !important;
  background-color: var(--primary-700) !important;
  cursor: default;
  user-select: none;
}
#undiscord.hide-author x.priv-author:hover {
  position: relative;
}
#undiscord.hide-author x.priv-author:hover::after {
  content: "Redacted Author ID (Hide Author ID/Text: ON)";
  position: absolute;
  display: inline-block;
  top: -32px;
  left: -20px;
  padding: 4px;
  width: 150px;
  font-size: 8pt;
  text-align: center;
  white-space: pre-wrap;
  background-color: var(--background-floating);
  box-shadow: var(--elevation-high);
  color: var(--text-default);
  border-radius: 5px;
  pointer-events: none;
}

/* ===== VERBOSE LOG MODE ===== */
#undiscord.verbose{
  --v-bg: #0b0f17;
  --v-panel: #0f1522;
  --v-panel-2: #121a2b;
  --v-border: rgba(122,183,255,.25);
  --v-text: rgba(232,240,255,.95);
  --v-muted: rgba(170,190,220,.75);
  --v-accent: #7ab7ff;
  --v-accent-2: #7ee7c6;
  background: radial-gradient(1200px 600px at 80% -10%, rgba(122,183,255,.18), transparent 60%), var(--v-bg) !important;
  border-color: var(--v-border) !important;
  color: var(--v-text) !important;
  box-shadow: 0 20px 70px rgba(0,0,0,.6) !important;
}
#undiscord.verbose .header{
  background: linear-gradient(135deg, rgba(122,183,255,.18), rgba(126,231,198,.12)) !important;
  border-bottom: 1px solid var(--v-border) !important;
}
#undiscord.verbose .header h3,
#undiscord.verbose .header,
#undiscord.verbose .header .icon{
  color: var(--v-text) !important;
}
#undiscord.verbose.hide-sidebar .main{
  max-width: 100% !important;
}
#undiscord.verbose .main{
  background: var(--v-panel) !important;
}
#undiscord.verbose .tbar{
  background: var(--v-panel-2) !important;
  border-bottom: 1px solid var(--v-border) !important;
}
#undiscord.verbose #logArea{
  padding: 8px !important;
  background: #0a0f18 !important;
  border-top: 1px solid var(--v-border) !important;
  font-size: 11.5px !important;
  line-height: 1.3 !important;
  font-family: "JetBrains Mono", "IBM Plex Mono", "Fira Code", Menlo, Consolas, "Liberation Mono", monospace !important;
}
#undiscord.verbose .log{
  margin-bottom: 0 !important;
}
#undiscord.verbose .log-vrow{
  display: grid;
  grid-template-columns: max-content max-content 1fr;
  gap: 2px;
  align-items: center;
  padding: 1px 6px;
  margin: 0 0 1px;
  border-radius: 3px;
  background: rgba(255,255,255,.02);
  border: 1px solid rgba(255,255,255,.06);
}
#undiscord.verbose .log-vrow .vtime{
  grid-column: 1;
  white-space: nowrap;
  color: var(--v-muted);
  font-size: 10px;
  line-height: 1.2;
}
#undiscord.verbose .log-vrow .vbadge{
  grid-column: 2;
  justify-self: center;
  margin: 0 4px;
  text-transform: uppercase;
  font-size: 9px;
  font-weight: 700;
  letter-spacing: .04em;
  padding: 1px 5px;
  border-radius: 999px;
  background: rgba(122,183,255,.12);
  color: var(--v-accent);
  border: 1px solid rgba(122,183,255,.25);
  line-height: 1.2;
}
#undiscord.verbose .log-vrow.log-info .vbadge{ color: #7ab7ff; border-color: rgba(122,183,255,.35); }
#undiscord.verbose .log-vrow.log-warn .vbadge{ color: #ffb454; border-color: rgba(255,180,84,.35); background: rgba(255,180,84,.12); }
#undiscord.verbose .log-vrow.log-error .vbadge{ color: #ff6b6b; border-color: rgba(255,107,107,.35); background: rgba(255,107,107,.12); }
#undiscord.verbose .log-vrow.log-success .vbadge{ color: #7ee7c6; border-color: rgba(126,231,198,.35); background: rgba(126,231,198,.12); }
#undiscord.verbose .log-vrow.log-verb .vbadge{ color: #b4c6e7; border-color: rgba(180,198,231,.35); background: rgba(180,198,231,.12); }
#undiscord.verbose .log-vrow .vmsg{
  grid-column: 3;
  color: var(--v-text);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  word-break: break-word;
  line-height: 1.3;
}

#undiscord:not(.verbose) .log-del{
  display: grid;
  grid-template-columns: calc(88px * var(--u-compact-scale)) calc(27px * var(--u-compact-scale)) minmax(0, 1fr) auto;
  gap: calc(8px * var(--u-compact-scale));
  padding: calc(8px * var(--u-compact-scale)) calc(12px * var(--u-compact-scale));
  margin: 0 0 2px;
  border-radius: 8px;
  background: rgba(255,255,255,.03);
  border: 1px solid rgba(255,255,255,.08);
  align-items: flex-start;
}
#undiscord:not(.verbose) .log-del:last-child{ margin-bottom: 0; }
#undiscord:not(.verbose) .log-del .stamp{
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0px;
  min-width: calc(88px * var(--u-compact-scale));
  white-space: nowrap;
  padding: calc(4px * var(--u-compact-scale)) calc(6px * var(--u-compact-scale));
  border-radius: 6px;
  background: rgba(255,255,255,.04);
  border: 1px solid rgba(255,255,255,.08);
}
#undiscord:not(.verbose) .log-del img{
  width: calc(27px * var(--u-compact-scale));
  height: calc(27px * var(--u-compact-scale));
  border-radius: 999px;
  flex: 0 0 auto;
  box-shadow: 0 0 0 1px rgba(255,255,255,.18);
  margin-top: 2px;
}
#undiscord:not(.verbose) .log-del .head{
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 4px;
}
#undiscord:not(.verbose) .log-del .lineChannel{
  display: inline-flex;
  align-items: center;
  max-width: 220px;
  padding: 1px 8px;
  border-radius: 999px;
  border: 1px solid rgba(255,255,255,.12);
  background: rgba(255,255,255,.05);
  color: rgba(255,255,255,.78);
  font-size: calc(11.5px * var(--u-compact-scale));
  white-space: nowrap;
  text-overflow: ellipsis;
  overflow: hidden;
}
#undiscord:not(.verbose) .log-del .date{
  display: flex;
  flex-direction: column;
  gap: 1px;
  padding: 0;
  background: none;
  border: none;
  font-size: calc(11.75px * var(--u-compact-scale));
  color: rgba(255,255,255,.82);
  letter-spacing: .02em;
}
#undiscord:not(.verbose) .log-del .date .d{
  text-transform: uppercase;
  opacity: .9;
}
#undiscord:not(.verbose) .log-del .date .t{
  opacity: .7;
}
#undiscord:not(.verbose) .log-del .author{
  font-size: calc(13.75px * var(--u-compact-scale));
  color: rgba(255,255,255,.92);
  font-weight: 600;
  white-space: nowrap;
  text-overflow: ellipsis;
  overflow: hidden;
}
#undiscord:not(.verbose) .log-del .meta{
  font-size: calc(11.75px * var(--u-compact-scale));
  color: rgba(255,255,255,.62);
  letter-spacing: .02em;
  white-space: nowrap;
  padding: 4px 8px;
  border-radius: 6px;
  background: rgba(255,255,255,.04);
  border: 1px solid rgba(255,255,255,.08);
  align-self: center;
  text-align: right;
}
#undiscord:not(.verbose) .log-del .content{
  font-size: calc(13px * var(--u-compact-scale));
  line-height: 1.35;
  color: rgba(255,255,255,.92);
}
#undiscord:not(.verbose) .log-del .content .msgText{
  font-size: calc(13px * var(--u-compact-scale));
}
#undiscord:not(.verbose) .log-del .txt{
  white-space: normal;
  overflow-wrap: anywhere;
  word-break: break-word;
  min-width: 0;
}
#undiscord:not(.verbose) .log-del .attachments{
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 6px;
}
#undiscord:not(.verbose) .log-del .attachments img{
  width: 120px;
  height: 120px;
  object-fit: cover;
  border-radius: 8px;
  border: 1px solid rgba(255,255,255,.12);
  margin-top: 0;
  box-shadow: none;
}
#undiscord:not(.verbose) .log-del .attachments video{
  width: 220px;
  max-width: 100%;
  border-radius: 8px;
  border: 1px solid rgba(255,255,255,.12);
  background: #000;
}
#undiscord:not(.verbose) .log-del .attachments audio{
  width: 220px;
  max-width: 100%;
}
#undiscord:not(.verbose) .log-del .attachments .file{
  display: inline-flex;
  align-items: center;
  padding: 6px 10px;
  border-radius: 8px;
  border: 1px solid rgba(255,255,255,.12);
  background: rgba(255,255,255,.04);
  color: var(--u-link);
  text-decoration: none;
  max-width: 260px;
  white-space: nowrap;
  text-overflow: ellipsis;
  overflow: hidden;
}

`);

   var dragCss = (`
[name^="grab-"] { position: absolute; --size: 6px; --corner-size: 16px; --offset: -1px; z-index: 9; }
[name^="grab-"]:hover{ background: rgba(128,128,128,0.1); }
[name="grab-t"] { top: 0px; left: var(--corner-size); right: var(--corner-size); height: var(--size); margin-top: var(--offset); cursor: ns-resize; }
[name="grab-r"] { top: var(--corner-size); bottom: var(--corner-size); right: 0px; width: var(--size); margin-right: var(--offset);
  cursor: ew-resize; }
[name="grab-b"] { bottom: 0px; left: var(--corner-size); right: var(--corner-size); height: var(--size); margin-bottom: var(--offset); cursor: ns-resize; }
[name="grab-l"] { top: var(--corner-size); bottom: var(--corner-size); left: 0px; width: var(--size); margin-left: var(--offset); cursor: ew-resize; }
[name="grab-tl"] { top: 0px; left: 0px; width: var(--corner-size); height: var(--corner-size); margin-top: var(--offset); margin-left: var(--offset); cursor: nwse-resize; }
[name="grab-tr"] { top: 0px; right: 0px; width: var(--corner-size); height: var(--corner-size); margin-top: var(--offset); margin-right: var(--offset); cursor: nesw-resize; }
[name="grab-br"] { bottom: 0px; right: 0px; width: var(--corner-size); height: var(--corner-size); margin-bottom: var(--offset); margin-right: var(--offset); cursor: nwse-resize; }
[name="grab-bl"] { bottom: 0px; left: 0px; width: var(--corner-size); height: var(--corner-size); margin-bottom: var(--offset); margin-left: var(--offset); cursor: nesw-resize; }
`);

   var buttonHtml = (`
<div id="undicord-btn" tabindex="0" role="button" aria-label="Delete Messages" title="Delete Messages with Undiscord">
    <svg aria-hidden="false" width="24" height="24" viewBox="0 0 24 24">
        <path fill="currentColor" d="M15 3.999V2H9V3.999H3V5.999H21V3.999H15Z"></path>
        <path fill="currentColor" d="M5 6.99902V18.999C5 20.101 5.897 20.999 7 20.999H17C18.103 20.999 19 20.101 19 18.999V6.99902H5ZM11 17H9V11H11V17ZM15 17H13V11H15V17Z"></path>
    </svg>
    <progress></progress>
</div>
`);

   var undiscordTemplate = (`
<div id="undiscord" class="browser container hide-sidebar" style="display:none;">

    <div class="header">
        <svg class="icon" aria-hidden="false" width="24" height="24" viewBox="0 0 24 24">
            <path fill="currentColor" d="M15 3.999V2H9V3.999H3V5.999H21V3.999H15Z"></path>
            <path fill="currentColor"
                d="M5 6.99902V18.999C5 20.101 5.897 20.999 7 20.999H17C18.103 20.999 19 20.101 19 18.999V6.99902H5ZM11 17H9V11H11V17ZM15 17H13V11H15V17Z">
            </path>
        </svg>
        <h3>Undiscord</h3>
        <div class="vert-divider"></div>
        <span> Messages and reactions</span>
        <div class="spacer"></div>
        <div id="hide" class="icon" aria-label="Close" role="button" tabindex="0">
            <svg aria-hidden="false" width="24" height="24" viewBox="0 0 24 24">
                <path fill="currentColor"
                    d="M18.4 4L12 10.4L5.6 4L4 5.6L10.4 12L4 18.4L5.6 20L12 13.6L18.4 20L20 18.4L13.6 12L20 5.6L18.4 4Z">
                </path>
            </svg>
        </div>
    </div>
    <div class="window-body" style="display: flex; flex-direction: row;">
        <div class="sidebar scroll">
            <details>
                <summary>General</summary>
                <fieldset>
                    <legend>
                        Author ID (message deletion only)
                        <a href="{{WIKI}}/authorId" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="multiInput">
                        <div class="input-wrapper">
                            <input class="input" id="authorId" type="text" placeholder="Numeric user ID" priv>
                        </div>
                        <button id="getAuthor">me</button>
                    </div>
                </fieldset>
                <hr>
                <fieldset>
                    <legend>
                        Server ID
                        <a href="{{WIKI}}/guildId" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="multiInput">
                        <div class="input-wrapper">
                            <input class="input" id="guildId" type="text" placeholder="Numeric server ID or @me" priv>
                        </div>
                        <button id="getGuild">current</button>
                    </div>
                </fieldset>
                <fieldset>
                    <legend>
                        Channel ID
                        <a href="{{WIKI}}/channelId" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="multiInput mb1">
                        <div class="input-wrapper">
                            <input class="input" id="channelId" type="text" priv>
                        </div>
                        <button id="getChannel">current</button>
                    </div>
                    <div class="sectionDescription">
                        <label class="row"><input id="includeNsfw" type="checkbox">Include NSFW channels</label>
                    </div>
                </fieldset>
            </details>
            <details>
                <summary>Wipe Archive</summary>
                <fieldset>
                    <legend>
                        Import index.json
                        <a href="{{WIKI}}/importJson" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="input-wrapper">
                        <input type="file" id="importJsonInput" accept="application/json,.json" style="width:100%";>
                    </div>
                    <div class="sectionDescription">
                        <br>
                        After requesting your data from discord, you can import it here.<br>
                        Select the "messages/index.json" file from the discord archive.
                    </div>
                </fieldset>
            </details>
            <hr>
            <details>
                <summary>Filter</summary>
                <fieldset>
                    <legend>
                        Search
                        <a href="{{WIKI}}/filters" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="input-wrapper">
                        <input id="search" type="text" placeholder="Containing text" priv>
                    </div>
                    <div class="sectionDescription">
                        Only process messages that contain the text
                    </div>
                    <div class="sectionDescription">
                        <label><input id="hasLink" type="checkbox">has: link</label>
                    </div>
                    <div class="sectionDescription">
                        <label><input id="hasFile" type="checkbox">has: file</label>
                    </div>
                    <div class="sectionDescription">
                        <label><input id="includePinned" type="checkbox" checked>Include pinned</label>
                    </div>
                </fieldset>
                <hr>
                <fieldset>
                    <legend>
                        Pattern
                        <a href="{{WIKI}}/pattern" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="sectionDescription">
                        Only process messages that match the regular expression
                    </div>
                    <div class="input-wrapper">
                        <span class="info">/</span>
                        <input id="pattern" type="text" placeholder="regular expression" priv>
                        <span class="info">/</span>
                    </div>
                </fieldset>
            </details>
            <details>
                <summary>Messages interval</summary>
                <fieldset>
                    <legend>
                        Interval of messages
                        <a href="{{WIKI}}/messageId" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="multiInput mb1">
                        <div class="input-wrapper">
                            <input id="minId" type="text" placeholder="After a message" priv>
                        </div>
                        <button id="pickMessageAfter">Pick</button>
                    </div>
                    <div class="multiInput">
                        <div class="input-wrapper">
                            <input id="maxId" type="text" placeholder="Before a message" priv>
                        </div>
                        <button id="pickMessageBefore">Pick</button>
                    </div>
                    <div class="sectionDescription">
                        Specify an interval to delete messages.
                    </div>
                </fieldset>
            </details>
            <details>
                <summary>Date interval</summary>
                <fieldset>
                    <legend>
                        After date
                        <a href="{{WIKI}}/dateRange" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="input-wrapper mb1">
                        <input id="minDate" type="datetime-local" title="Messages posted AFTER this date">
                    </div>
                    <legend>
                        Before date
                        <a href="{{WIKI}}/dateRange" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="input-wrapper">
                        <input id="maxDate" type="datetime-local" title="Messages posted BEFORE this date">
                    </div>
                    <div class="sectionDescription">
                        Delete messages that were posted between the two dates.
                    </div>
                    <div class="sectionDescription">
                        * Filtering by date doesn't work if you use the "Messages interval".
                    </div>
                </fieldset>
            </details>
            <hr>
            <details>
                <summary>Advanced settings</summary>
                <fieldset>
                    <legend>
                        History page delay
                        <a href="{{WIKI}}/delay" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="input-wrapper">
                        <input id="searchDelay" type="range" value="1000" step="100" min="100" max="60000">
                        <div id="searchDelayValue"></div>
                    </div>
                </fieldset>
                <fieldset>
                    <legend>
                        Action delay
                        <a href="{{WIKI}}/delay" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="input-wrapper">
                        <input id="deleteDelay" type="range" value="1000" step="50" min="50" max="10000">
                        <div id="deleteDelayValue"></div>
                    </div>
                    <br>
                    <div class="sectionDescription">
                        Minimum delay before each message deletion or reaction removal.
                        Discord cooldowns can make the actual wait longer.
                    </div>
                </fieldset>
                <hr>
                <fieldset>
                    <legend>
                        Authorization Token
                        <a href="{{WIKI}}/authToken" title="Help" target="_blank" rel="noopener noreferrer">help</a>
                    </legend>
                    <div class="multiInput">
                        <div class="input-wrapper">
                            <input class="input" id="token" type="password" autocomplete="off" priv>
                        </div>
                        <button id="getToken">fill</button>
                    </div>
                </fieldset>
            </details>
            <hr>
            <details>
                <summary>Display options</summary>
                <fieldset>
                    <div class="sectionDescription">
                        <label class="row"><input id="redact" type="checkbox"> Streamer mode</label>
                    </div>
                    <div class="sectionDescription">
                        <label class="row"><input id="hideAuthorText" type="checkbox"> Hide Author ID/Text</label>
                    </div>
                    <div class="sectionDescription">
                        <label class="row"><input id="hideMessageText" type="checkbox"> Hide message text</label>
                    </div>
                    <div class="sectionDescription">
                        <label class="row"><input id="verboseMode" type="checkbox"> Verbose console</label>
                    </div>
                    <div class="sectionDescription">
                        <label class="row"><input id="previewMode" type="checkbox"> Preview mode (no changes)</label>
                    </div>
                </fieldset>
            </details>
            <hr>
            <div></div>
            <div class="info">
                Undiscord {{VERSION}}
                <br> victornpb
            </div>
        </div>
        <div class="main col">
          <div class="tbar col">
            <div class="row">
              <button id="toggleSidebar" class="sizeMedium" title="Show options" aria-label="Show options">Options</button>
              <div id="convBadge" class="convBadge" style="display:none;">
                  <img id="convAvatar" class="convAvatar" alt="">
                  <span id="convName" class="convName"></span>
              </div>
              <div id="channelBadge" class="channelBadge" style="display:none;">
                  <span class="channelHash">#</span>
                  <span id="channelName" class="channelName"></span>
              </div>
              <label class="allChannelsToggle" style="display:none;">
                <input id="deleteAllChannels" type="checkbox"> Scan all channels
              </label>
              <button id="start" class="sizeMedium danger" style="width: 150px;" title="Start the selected actions">Start</button>
              <button id="stop" class="sizeMedium" title="Stop the current run" disabled>Stop</button>
              <button id="clear" class="sizeMedium">Clear log</button>
            </div>
            <div class="row" style="flex-wrap: wrap; gap: 12px;">
              <label class="row"><input id="deleteMessages" type="checkbox" checked>Delete matching messages</label>
              <label class="row"><input id="removeReactions" type="checkbox">Remove my reactions</label>
            </div>
            <div class="sectionDescription">
              Reactions use the signed-in account, on any author's matching messages. Uncheck message deletion to only unreact.
            </div>

            <div id="preScanStatus" class="preScanStatus"></div>
            <div class="row progressRow">
              <progress id="progressBar" style="display:none;"></progress>
              <span id="progressBarPercent" style="display:none;">0%</span>
            </div>

            <div class="doneBanner" id="doneBanner" role="status" aria-live="polite" hidden></div>
          </div>

            <pre id="logArea" class="logarea scroll">
              <div class="log log-static" style="background: var(--background-mentioned); padding: .5em;">
                Reads accessible history from newest to oldest, including pages without matching messages.<br>
                Totals are discovered while scanning. Message deletion uses Author ID; reaction removal uses your signed-in account and ignores Author ID. All other filters apply to both.
              </div>
              <center class="log log-static">
                <div>Star <a href="{{HOME}}" target="_blank" rel="noopener noreferrer">this project</a> on GitHub!</div>
                <div><a href="{{HOME}}/issues" target="_blank" rel="noopener noreferrer">Issues or help</a></div>
              </center>
            </pre>

            <div class="tbar footer row">
                <div id="progressPercent"></div>
                <span class="spacer"></span>
                <label>
                    <input id="autoScroll" type="checkbox" checked> Auto scroll
                </label>
                <div class="resize-handle"></div>
            </div>
        </div>
    </div>
</div>

`);

  const log = {
    debug() { return logFn ? logFn('debug', arguments) : console.debug.apply(console, arguments); },
    info() { return logFn ? logFn('info', arguments) : console.info.apply(console, arguments); },
    verb() { return logFn ? logFn('verb', arguments) : console.log.apply(console, arguments); },
    warn() { return logFn ? logFn('warn', arguments) : console.warn.apply(console, arguments); },
    error() { return logFn ? logFn('error', arguments) : console.error.apply(console, arguments); },
    success() { return logFn ? logFn('success', arguments) : console.info.apply(console, arguments); },

    // ✅ dedicated delete line for compact mode
    del() { return logFn ? logFn('del', arguments) : console.log.apply(console, arguments); },
  };


   var logFn; // custom console.log function
   const setLogFn = (fn) => logFn = fn;
  const logStore = {
    compact: [],
    verbose: [],
  };

   // Helpers
   const msToHMS = s => `${s / 3.6e6 | 0}h ${(s % 3.6e6) / 6e4 | 0}m ${(s % 6e4) / 1000 | 0}s`;
  const escapeHTML = html => String(html).replace(/[&<"']/g, m => ({ '&': '&amp;', '<': '&lt;', '"': '&quot;', '\'': '&#039;' })[m]);
   const ask = async msg => new Promise(resolve => setTimeout(() => resolve(window.confirm(msg)), 10));
   function toSnowflake(value) {
     const text = String(value).trim();
     if (/^\d{1,21}$/.test(text)) return text;
     const timestamp = Date.parse(text);
     if (!Number.isFinite(timestamp)) throw new Error('Invalid date or message ID.');
     return (BigInt(Math.max(0, timestamp - 1420070400000)) << 22n).toString();
   }
   const replaceInterpolations = (str, obj, removeMissing = false) => str.replace(/\{\{([\w_]+)\}\}/g, (m, key) => obj[key] || (removeMissing ? '' : m));


  class DiscordRequestError extends Error {
    constructor(message, status = 0, code = 0) {
      super(message);
      this.name = 'DiscordRequestError';
      this.status = status;
      this.code = code;
    }
  }

  class UndiscordCore {
    options = {
      authToken: null,
      authorId: null,
      guildId: null,
      channelId: null,
      minId: null,
      maxId: null,
      content: null,
      hasLink: false,
      hasFile: false,
      includeNsfw: false,
      includePinned: true,
      pattern: null,
      previewMode: false,
      deleteMessages: true,
      removeReactions: false,
      searchDelay: 1000,
      deleteDelay: 1000,
      maxNetworkRetries: 8,
      networkRetryBaseDelay: 1000,
    };

    state = this.createState();
    stats = this.createStats();
    onStart = undefined;
    onProgress = undefined;
    onStop = undefined;
    _controller = null;
    _filters = null;
    _confirmed = false;
    _batchRunning = false;
    // Cooldowns belong to the client, not a run: Stop/Start must not bypass them.
    _routeBuckets = new Map();
    _rateLimitUntil = new Map();
    _globalRateLimitUntil = 0;

    createState() {
      return {
        running: false,
        phase: 'IDLE',
        endReason: null,
        errorMessage: '',
        delCount: 0,
        previewCount: 0,
        failCount: 0,
        alreadyGoneCount: 0,
        reactionCount: 0,
        reactionRemovedCount: 0,
        reactionPreviewCount: 0,
        reactionFailCount: 0,
        reactionGoneCount: 0,
        scannedCount: 0,
        matchedCount: 0,
        skippedCount: 0,
        nonDeletableCount: 0,
        channelIndex: 0,
        channelCount: 0,
        channelFailures: [],
        discoveryIssues: [],
      };
    }

    createStats() {
      return {
        startTime: null,
        endTime: null,
        lastPing: null,
        avgPing: null,
        throttledCount: 0,
        throttledTotalTime: 0,
        pendingWaitUntilTs: 0,
      };
    }

    parseSnowflake(value, label, allowZero = false) {
      if (typeof value !== 'string' || !/^\d+$/.test(value)) {
        throw new Error(`${label} must be a decimal snowflake string.`);
      }
      const id = BigInt(value);
      if (id === 0n && !allowZero) throw new Error(`${label} must not be zero.`);
      if (id > 18446744073709551615n) throw new Error(`${label} exceeds the snowflake range.`);
      return id;
    }

    compileFilters() {
      const options = this.options;
      const authorId = options.authorId;
      if (!options.deleteMessages && !options.removeReactions) {
        throw new Error('Select message deletion, reaction removal, or both.');
      }
      if (options.deleteMessages) this.parseSnowflake(authorId, 'Author ID');
      const parseBound = (value, label) => {
        if (value === null || value === undefined || value === '') return null;
        return this.parseSnowflake(String(toSnowflake(value)), label, true);
      };
      const minId = parseBound(options.minId, 'Minimum ID/date');
      const maxId = parseBound(options.maxId, 'Maximum ID/date');
      if (minId !== null && maxId !== null && minId >= maxId) {
        throw new Error('Minimum ID/date must be earlier than maximum ID/date.');
      }
      if (options.content !== null && typeof options.content !== 'string') {
        throw new Error('Text filter must be a string.');
      }
      if (options.pattern !== null && typeof options.pattern !== 'string') {
        throw new Error('Regex filter must be a string.');
      }
      let pattern = null;
      if (options.pattern) {
        try {
          pattern = new RegExp(options.pattern, 'i');
        } catch (error) {
          throw new Error(`Invalid regular expression: ${error.message}`);
        }
      }
      for (const key of ['searchDelay', 'deleteDelay', 'networkRetryBaseDelay']) {
        const value = options[key] ?? 1000;
        if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) {
          throw new Error(`${key} must be a finite, nonnegative number of milliseconds.`);
        }
        options[key] = value;
      }
      if (!Number.isInteger(options.maxNetworkRetries) || options.maxNetworkRetries < 0) {
        throw new Error('maxNetworkRetries must be a nonnegative integer.');
      }
      return {
        authorId,
        minId,
        maxId,
        content: (options.content || '').toLowerCase(),
        hasLink: Boolean(options.hasLink),
        hasFile: Boolean(options.hasFile),
        includePinned: Boolean(options.includePinned),
        previewMode: Boolean(options.previewMode),
        deleteMessages: Boolean(options.deleteMessages),
        removeReactions: Boolean(options.removeReactions),
        pattern,
      };
    }

    begin() {
      if (this.state.running) throw new Error('The previous run is still draining.');
      this.state = this.createState();
      this.stats = this.createStats();
      this._controller = new AbortController();
      this._filters = null;
      this._confirmed = false;
      this._batchRunning = false;
      this.state.running = true;
      this.state.phase = 'PREPARING';
      this.stats.startTime = new Date();
      this.onStart?.(this.state, this.stats);
    }

    checkRunning() {
      if (!this.state.running || !this._controller || this._controller.signal.aborted) {
        throw new DOMException('Operation stopped.', 'AbortError');
      }
    }

    progress() {
      this.onProgress?.(this.state, this.stats);
    }

    stop() {
      if (!this.state.running) return;
      this.state.endReason = 'STOPPED';
      this.state.phase = 'STOPPING';
      this._controller.abort();
      this.progress();
    }

    hasIncompleteWork() {
      return this.state.failCount > 0 || this.state.reactionFailCount > 0 || this.state.nonDeletableCount > 0 ||
        this.state.channelFailures.length > 0 || this.state.discoveryIssues.length > 0;
    }

    finish(reason) {
      if (!this.state.running) return;
      if (this._batchRunning) throw new Error('Cannot finish before the batch has drained.');
      if (!['DONE', 'PARTIAL', 'ERROR', 'STOPPED'].includes(reason)) {
        throw new Error('Invalid run completion reason.');
      }
      this.state.endReason = this.state.endReason === 'STOPPED' ? 'STOPPED' :
        reason === 'DONE' && this.hasIncompleteWork() ? 'PARTIAL' : reason;
      this._controller.abort();
      this.state.running = false;
      this.state.phase = 'IDLE';
      this.stats.endTime = new Date();
      this.stats.pendingWaitUntilTs = 0;
      this.onStop?.(this.state, this.stats);
    }

    async waitWithTracking(ms) {
      this.checkRunning();
      if (!Number.isFinite(ms) || ms < 0) throw new Error('Invalid wait duration.');
      if (ms === 0) return;
      const signal = this._controller.signal;
      const deadline = Date.now() + ms;
      this.stats.pendingWaitUntilTs = deadline;
      this.progress();
      try {
        await new Promise((resolve, reject) => {
          let timer;
          const abort = () => {
            clearTimeout(timer);
            signal.removeEventListener('abort', abort);
            reject(new DOMException('Operation stopped.', 'AbortError'));
          };
          const tick = () => {
            const remaining = deadline - Date.now();
            if (remaining > 0) {
              timer = setTimeout(tick, Math.min(remaining, 2147483647));
            } else {
              signal.removeEventListener('abort', abort);
              resolve();
            }
          };
          signal.addEventListener('abort', abort, { once: true });
          if (signal.aborted) abort();
          else tick();
        });
      } finally {
        this.stats.pendingWaitUntilTs = 0;
        this.progress();
      }
      this.checkRunning();
    }

    retryAfterMs(response, body, receivedAt = Date.now()) {
      const secondsToMs = value => {
        if (typeof value === 'string') {
          value = value.trim();
          if (!/^(?:\d+\.?\d*|\.\d+)$/.test(value)) return null;
          value = Number(value);
        }
        if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) return null;
        const ms = value * 1000;
        return Number.isFinite(ms) ? ms : null;
      };
      const serverDate = Date.parse(response.headers.get('Date') || '');
      const now = Number.isFinite(serverDate) ? serverDate : receivedAt;
      let delay = secondsToMs(body?.retry_after) ?? 0;
      const retryAfter = response.headers.get('Retry-After');
      const retrySeconds = secondsToMs(retryAfter);
      if (retrySeconds !== null) {
        delay = Math.max(delay, retrySeconds);
      } else if (retryAfter && /[a-z]/i.test(retryAfter)) {
        const retryDate = Date.parse(retryAfter);
        if (Number.isFinite(retryDate)) delay = Math.max(delay, retryDate - now);
      }
      // Relative reset avoids client clock skew; use the absolute reset only as fallback.
      const resetAfter = secondsToMs(response.headers.get('X-RateLimit-Reset-After'));
      const resetAt = resetAfter === null ? secondsToMs(response.headers.get('X-RateLimit-Reset')) : null;
      delay = Math.max(delay, resetAfter ?? (resetAt === null ? 0 : resetAt - now));
      return Math.ceil(delay);
    }

    retryBackoffMs(attempt, base = this.options.networkRetryBaseDelay) {
      const exponential = Math.min(30000, Math.max(1, base) * 2 ** Math.min(attempt - 1, 30));
      return Math.ceil(exponential + 1 + Math.random() * Math.min(1000, exponential * 0.2));
    }

    recordResponseCooldown(response, body, route, major, receivedAt, localBackoff) {
      const retryAfter = this.retryAfterMs(response, body, receivedAt);
      const bucketHash = response.headers.get('X-RateLimit-Bucket')?.trim();
      if (bucketHash) this._routeBuckets.set(route, `bucket:${bucketHash}:${major}`);
      const bucket = this._routeBuckets.get(route);
      const global = body?.global === true ||
        response.headers.get('X-RateLimit-Global')?.trim().toLowerCase() === 'true' ||
        response.headers.get('X-RateLimit-Scope')?.trim().toLowerCase() === 'global';
      const remaining = response.headers.get('X-RateLimit-Remaining')?.trim();
      const exhausted = remaining !== undefined && /^\d+$/.test(remaining) && Number(remaining) === 0;
      const transient = response.status >= 500 && response.status <= 599;
      if (response.status === 429 || (retryAfter > 0 && (transient || (response.ok && exhausted)))) {
        const deadline = receivedAt + Math.max(retryAfter, localBackoff);
        if (global) {
          this._globalRateLimitUntil = Math.max(this._globalRateLimitUntil, deadline);
        } else {
          this._rateLimitUntil.set(route, Math.max(this._rateLimitUntil.get(route) || 0, deadline));
          if (bucket) this._rateLimitUntil.set(bucket, Math.max(this._rateLimitUntil.get(bucket) || 0, deadline));
        }
      }
      return receivedAt + retryAfter;
    }

    async waitForRateLimit(route, method, path) {
      while (true) {
        this.checkRunning();
        const bucket = this._routeBuckets.get(route);
        const routeUntil = Math.max(this._rateLimitUntil.get(route) || 0, this._rateLimitUntil.get(bucket) || 0);
        const deadline = Math.max(this._globalRateLimitUntil, routeUntil);
        const delay = Math.ceil(deadline - Date.now());
        if (delay <= 0) return;
        const scope = this._globalRateLimitUntil >= routeUntil ? 'global' : 'route';
        log.warn(`${method} ${path}: ${scope} rate limit cooldown; waiting ${delay}ms before the same request.`);
        const started = Date.now();
        try {
          await this.waitWithTracking(delay);
        } finally {
          this.stats.throttledTotalTime += Math.max(0, Date.now() - started);
          this.progress();
        }
      }
    }

    async request(path, { method = 'GET' } = {}) {
      this.checkRunning();
      if (typeof path !== 'string' || !/^\/[a-z]/.test(path) || path.includes('://') || path.includes('#')) {
        throw new Error('Discord requests require a relative API path.');
      }
      if (!this.options.authToken || typeof this.options.authToken !== 'string') {
        throw new Error('An authorization token is required before requesting Discord.');
      }
      const pathname = path.split('?')[0];
      const major = pathname.match(/^\/(channels|guilds)\/(\d+)(?:\/|$)/)?.[0].replace(/\/$/, '') || '';
      // Keep channel/guild IDs and @me; normalize nonmajor IDs and reaction emoji, and omit queries.
      const normalized = pathname.replace(/\d+/g, (id, offset) => offset < major.length ? id : ':id')
        .replace(/(\/reactions\/)[^/]+/g, '$1:emoji');
      const route = `${method} ${normalized}`;
      let retries = 0;
      let rateRetries = 0;
      while (true) {
        await this.waitForRateLimit(route, method, path);
        this.checkRunning();
        let response;
        let text;
        let readError = null;
        let receivedAt = 0;
        let retryUntil = 0;
        let rateBackoff = 0;
        const started = Date.now();
        try {
          response = await fetch(`https://discord.com/api/v9${path}`, {
            method,
            headers: { Authorization: this.options.authToken },
            signal: this._controller.signal,
          });
          receivedAt = Date.now();
          if (response.status === 429) {
            rateBackoff = this.retryBackoffMs(++rateRetries, 1000);
            this.stats.throttledCount++;
          }
          // Retain received headers even if Stop aborts before the body can be read.
          retryUntil = this.recordResponseCooldown(response, null, route, major, receivedAt, rateBackoff);
          this.checkRunning();
          text = response.status === 204 ? '' : await response.text();
          this.checkRunning();
        } catch (error) {
          this.checkRunning();
          if (error.name === 'AbortError') throw error;
          readError = error;
        } finally {
          this.stats.lastPing = Date.now() - started;
          this.stats.avgPing = this.stats.avgPing === null ? this.stats.lastPing :
            this.stats.avgPing * 0.9 + this.stats.lastPing * 0.1;
        }

        let body = null;
        let malformed = false;
        if (text) {
          try {
            body = JSON.parse(text);
          } catch {
            malformed = true;
          }
        }
        // Body hints can extend, but never restart or shorten, the received header cooldown.
        if (response) {
          retryUntil = this.recordResponseCooldown(response, body, route, major, receivedAt, rateBackoff);
          if (response.status === 429) {
            this.progress();
            continue;
          }
        }

        if (!response || (response.ok && readError)) {
          if (retries >= this.options.maxNetworkRetries) {
            throw new DiscordRequestError(
              `${method} ${path}: network/body read failed after ${retries + 1} transient failures.`,
              response?.status || 0,
            );
          }
          const delay = Math.max(retryUntil - Date.now(), this.retryBackoffMs(++retries));
          log.warn(`${method} ${path}: network/body read failure; retry ${retries}/${this.options.maxNetworkRetries} in ${delay}ms.`);
          await this.waitWithTracking(delay);
          continue;
        }
        if (response.ok) {
          const expectedStatus = method === 'DELETE' ? 204 : 200;
          if (response.status !== expectedStatus) {
            throw new DiscordRequestError(`${method} ${path}: unexpected HTTP ${response.status}; the operation was not confirmed complete.`, response.status);
          }
          if (response.status !== 204 && (!text || malformed)) {
            throw new DiscordRequestError(`${method} ${path}: HTTP ${response.status} contained invalid JSON.`, response.status);
          }
          this.checkRunning();
          return body;
        }
        const code = body && Number.isInteger(body.code) ? body.code : 0;
        const error = new DiscordRequestError(
          `${method} ${path}: HTTP ${response.status}${code ? ` (Discord code ${code})` : ''}.`,
          response.status,
          code,
        );
        if (response.status === 401) throw error;
        if (response.status >= 500 && response.status <= 599 && retries < this.options.maxNetworkRetries) {
          const delay = Math.max(retryUntil - Date.now(), this.retryBackoffMs(++retries));
          log.warn(`${error.message} Retrying ${retries}/${this.options.maxNetworkRetries} in ${delay}ms.`);
          await this.waitWithTracking(delay);
          continue;
        }
        throw error;
      }
    }

    parseOwnReactions(message) {
      if (message.reactions === undefined) return null;
      if (!Array.isArray(message.reactions)) {
        throw new Error(`Message ${message.id} has malformed reaction data.`);
      }
      let own = null;
      for (const reaction of message.reactions) {
        if (!reaction || typeof reaction.me !== 'boolean' || typeof reaction.me_burst !== 'boolean') {
          throw new Error(`Message ${message.id} has invalid own-reaction flags.`);
        }
        if (!reaction.me && !reaction.me_burst) continue;
        const emoji = reaction.emoji;
        if (!emoji || (emoji.name !== null && typeof emoji.name !== 'string')) {
          throw new Error(`Message ${message.id} has an own reaction without valid emoji metadata.`);
        }
        let identifier;
        if (emoji.id == null) {
          if (!emoji.name) throw new Error(`Message ${message.id} has an unnamed Unicode reaction.`);
          identifier = emoji.name;
        } else {
          this.parseSnowflake(emoji.id, `Emoji ID for message ${message.id}`);
          // Match discord.js's name:id serialization for null-name emoji; Discord errors remain visible.
          identifier = `${emoji.name}:${emoji.id}`;
        }
        const encoded = encodeURIComponent(identifier);
        if (own === null) own = [];
        if (reaction.me) own.push({ emoji: encoded, burst: false });
        if (reaction.me_burst) own.push({ emoji: encoded, burst: true });
      }
      return own;
    }

    parsePage(raw, channelId, before) {
      if (!Array.isArray(raw) || raw.length > 100) throw new Error('History response is not a valid page of up to 100 messages.');
      const seen = new Set();
      let oldest = null;
      const messages = raw.map(message => {
        if (!message || typeof message !== 'object') throw new Error('History page contains an invalid message.');
        const id = this.parseSnowflake(message.id, 'Message ID');
        this.parseSnowflake(message.author?.id, `Author ID for message ${message.id}`);
        if (message.channel_id !== channelId || typeof message.content !== 'string' ||
            !Number.isInteger(message.type) || message.type < 0 || typeof message.pinned !== 'boolean' ||
            !Array.isArray(message.attachments) || !Array.isArray(message.embeds)) {
          throw new Error(`Message ${message.id} has malformed history data or the wrong channel.`);
        }
        if (seen.has(message.id)) throw new Error(`History page repeats message ${message.id}.`);
        if (before !== null && id >= before) throw new Error(`History cursor did not advance at message ${message.id}.`);
        seen.add(message.id);
        if (oldest === null || id < oldest) oldest = id;
        return { message, id, ownReactions: this._filters.removeReactions ? this.parseOwnReactions(message) : null };
      });
      return { messages, oldest };
    }

    matches(message, id) {
      const filters = this._filters;
      if (filters.minId !== null && id <= filters.minId) return false;
      if (filters.maxId !== null && id >= filters.maxId) return false;
      if (!filters.includePinned && message.pinned) return false;
      if (filters.content && !message.content.toLowerCase().includes(filters.content)) return false;
      if (filters.hasFile && message.attachments.length === 0) return false;
      if (filters.hasLink && !/https?:\/\/[^\s]+/i.test(message.content)) return false;
      if (filters.pattern && !filters.pattern.test(message.content)) return false;
      return true;
    }

    logMessage(message, channel, preview) {
      log.del({
        author: message.author,
        meta: preview ? `[PREVIEW — NOT DELETED #${this.state.previewCount}]` : `[DELETED #${this.state.delCount}]`,
        content: message.content,
        timestamp: message.timestamp,
        channelId: channel.id,
        channelName: channel.name || '',
        showChannel: this.state.channelCount > 1,
        attachments: message.attachments,
        embeds: message.embeds,
      });
    }

    async confirmDeletion(channels) {
      this.checkRunning();
      if (this._confirmed || this._filters.previewMode || channels.length === 0) return;
      const filters = this._filters;
      const scope = channels.map(channel => `${channel?.name || 'Channel'} (${channel?.id || 'invalid ID'})`).join('\n');
      const answer = await ask(
        (filters.deleteMessages ? `Permanently delete matching messages by author ${filters.authorId}?` : 'Message deletion: off.') +
        (filters.removeReactions
          ? '\nRemove the signed-in account’s own reactions from matching messages by any author? Author ID does not restrict reaction removal.'
          : '\nReaction removal: off.') +
        `\nScope: ${channels.length} selected channel(s), server/DM ${this.options.guildId || '@me'}:\n${scope}` +
        `\n\nText contains (case-insensitive): ${filters.content || '[any]'}` +
        `\nRegex (case-insensitive): ${this.options.pattern || '[none]'}` +
        `\nAfter ID/date (exclusive): ${this.options.minId || '[unbounded]'}` +
        `\nBefore ID/date (exclusive): ${this.options.maxId || '[unbounded]'}` +
        `\nRequires link: ${filters.hasLink ? 'yes' : 'no'}; requires file: ${filters.hasFile ? 'yes' : 'no'}` +
        `\nPinned messages: ${filters.includePinned ? 'included' : 'excluded'}` +
        `\nNSFW channels: ${this.options.includeNsfw ? 'included' : 'excluded during discovery'}` +
        '\n\nThe total is unknown until raw history has been scanned. Deleted messages cannot be restored; removed reactions are not restored automatically.',
      );
      this.checkRunning();
      if (!answer) {
        this.stop();
        this.checkRunning();
      }
      this._confirmed = true;
    }

    async deleteMatchingMessage(message, channel) {
      this.state.matchedCount++;
      if ((message.type >= 1 && message.type <= 5) || message.type === 21) {
        this.state.nonDeletableCount++;
        log.warn(`Matching message ${message.id} in channel ${channel.id} has nondeletable type ${message.type}; it was not deleted.`);
        this.progress();
        return false;
      }
      if (this._filters.previewMode) {
        this.state.previewCount++;
        this.logMessage(message, channel, true);
        this.progress();
        return true;
      }
      this.checkRunning();
      this.state.phase = 'DELETING';
      this.progress();
      await this.waitWithTracking(this.options.deleteDelay);
      try {
        await this.request(`/channels/${channel.id}/messages/${message.id}`, { method: 'DELETE' });
        this.checkRunning();
        this.state.delCount++;
        this.logMessage(message, channel, false);
        return true;
      } catch (error) {
        if (error.name === 'AbortError') throw error;
        if (error instanceof DiscordRequestError && error.status === 404 && error.code === 10008) {
          this.state.alreadyGoneCount++;
          log.warn(`Message ${message.id} in channel ${channel.id} is already unavailable (Discord code 10008).`);
          return true;
        }
        this.state.failCount++;
        log.error(`Failed to delete message ${message.id} in channel ${channel.id}: ${error.message}`);
        if (error instanceof DiscordRequestError && error.status === 401) throw error;
        return false;
      } finally {
        this.progress();
      }
    }

    async removeOwnReactions(reactions, message, channel) {
      this.state.reactionCount += reactions.length;
      for (let index = 0; index < reactions.length; index++) {
        this.checkRunning();
        const reaction = reactions[index];
        const description = `your ${reaction.burst ? 'super' : 'normal'} reaction ${reaction.emoji} on message ${message.id} in channel ${channel.id}`;
        if (this._filters.previewMode) {
          this.state.reactionPreviewCount++;
          log.info(`Preview only: would remove ${description}; no change made.`);
          this.progress();
          continue;
        }
        this.state.phase = 'UNREACTING';
        this.progress();
        await this.waitWithTracking(this.options.deleteDelay);
        // The client uses a reaction-type path segment for bursts; normal reactions use the documented route.
        const suffix = reaction.burst ? '/1/@me' : '/@me';
        try {
          await this.request(`/channels/${channel.id}/messages/${message.id}/reactions/${reaction.emoji}${suffix}`, { method: 'DELETE' });
          this.checkRunning();
          this.state.reactionRemovedCount++;
          log.success(`Removed ${description}.`);
        } catch (error) {
          if (error.name === 'AbortError') throw error;
          if (error instanceof DiscordRequestError && error.status === 404 && error.code === 10008) {
            this.state.reactionGoneCount += reactions.length - index;
            log.warn(`Message ${message.id} in channel ${channel.id} is already unavailable; its remaining own reactions were not counted as removed.`);
            return;
          }
          this.state.reactionFailCount++;
          log.error(`Failed to remove ${description}: ${error.message}`);
          if (error instanceof DiscordRequestError && error.status === 401) throw error;
        } finally {
          this.progress();
        }
      }
    }

    async scanChannel(channel) {
      this.parseSnowflake(channel?.id, 'Channel ID');
      this.options.channelId = channel.id;
      let before = this._filters.maxId;
      while (true) {
        this.checkRunning();
        this.state.phase = 'SCANNING';
        this.progress();
        await this.waitWithTracking(this.options.searchDelay);
        const path = `/channels/${channel.id}/messages?limit=100${before === null ? '' : `&before=${before}`}`;
        const raw = await this.request(path);
        this.checkRunning();
        const { messages, oldest } = this.parsePage(raw, channel.id, before);
        this.state.scannedCount += messages.length;
        this.progress();
        if (messages.length === 0) return;

        for (const { message, id, ownReactions } of messages) {
          this.checkRunning();
          if (!this.matches(message, id)) {
            this.state.skippedCount++;
            continue;
          }
          const deleteMessage = this._filters.deleteMessages && message.author.id === this._filters.authorId;
          // Deleting a message also removes its reactions; do not spend extra requests on them.
          if (deleteMessage && await this.deleteMatchingMessage(message, channel)) continue;
          if (ownReactions) {
            await this.removeOwnReactions(ownReactions, message, channel);
          } else if (!deleteMessage) {
            this.state.skippedCount++;
          }
        }
        this.progress();
        if (this._filters.minId !== null && oldest <= this._filters.minId) return;
        before = oldest;
      }
    }

    async runBatch(channels) {
      this.checkRunning();
      if (this._batchRunning) throw new Error('A channel batch is already running.');
      if (!Array.isArray(channels)) throw new Error('Channel batch must be an array.');
      if (this._filters === null) this._filters = this.compileFilters();
      this._batchRunning = true;
      this.state.channelCount = channels.length;
      try {
        await this.confirmDeletion(channels);
        this.checkRunning();
        for (let index = 0; index < channels.length; index++) {
          this.checkRunning();
          this.state.channelIndex = index + 1;
          const channel = channels[index];
          try {
            await this.scanChannel(channel);
          } catch (error) {
            if (error.name === 'AbortError') throw error;
            const failure = `Channel ${channel?.id || `(job ${index + 1})`}: ${error.message}`;
            this.state.channelFailures.push(failure);
            log.error(failure);
            if (error instanceof DiscordRequestError && error.status === 401) {
              for (let pending = index + 1; pending < channels.length; pending++) {
                const skipped = `Channel ${channels[pending]?.id || `(job ${pending + 1})`}: not scanned because authorization failed (HTTP 401).`;
                this.state.channelFailures.push(skipped);
                log.error(skipped);
              }
              throw error;
            }
          }
          this.progress();
        }
        this.checkRunning();
        return this.hasIncompleteWork() ? 'PARTIAL' : 'DONE';
      } finally {
        this._batchRunning = false;
      }
    }
  }

   const MOVE = 0;
   const RESIZE_T = 1;
   const RESIZE_B = 2;
   const RESIZE_L = 4;
   const RESIZE_R = 8;
   const RESIZE_TL = RESIZE_T + RESIZE_L;
   const RESIZE_TR = RESIZE_T + RESIZE_R;
   const RESIZE_BL = RESIZE_B + RESIZE_L;
   const RESIZE_BR = RESIZE_B + RESIZE_R;

   /**
    * Make an element draggable/resizable
    * @author Victor N. wwww.vitim.us
    */
   class DragResize {
     constructor({ elm, moveHandle, options }) {
       this.options = defaultArgs({
         enabledDrag: true,
         enabledResize: true,
         minWidth: 200,
         maxWidth: Infinity,
         minHeight: 100,
         maxHeight: Infinity,
         dragAllowX: true,
         dragAllowY: true,
         resizeAllowX: true,
         resizeAllowY: true,
         draggingClass: 'drag',
         useMouseEvents: true,
         useTouchEvents: true,
         createHandlers: true,
       }, options);
       Object.assign(this, options);
       options = undefined;

       elm.style.position = 'fixed';

       this.drag_m = new Draggable(elm, moveHandle, MOVE, this.options);

       if (this.options.createHandlers) {
         this.el_t = createElement('div', { name: 'grab-t' }, elm);
         this.drag_t = new Draggable(elm, this.el_t, RESIZE_T, this.options);
         this.el_r = createElement('div', { name: 'grab-r' }, elm);
         this.drag_r = new Draggable(elm, this.el_r, RESIZE_R, this.options);
         this.el_b = createElement('div', { name: 'grab-b' }, elm);
         this.drag_b = new Draggable(elm, this.el_b, RESIZE_B, this.options);
         this.el_l = createElement('div', { name: 'grab-l' }, elm);
         this.drag_l = new Draggable(elm, this.el_l, RESIZE_L, this.options);
         this.el_tl = createElement('div', { name: 'grab-tl' }, elm);
         this.drag_tl = new Draggable(elm, this.el_tl, RESIZE_TL, this.options);
         this.el_tr = createElement('div', { name: 'grab-tr' }, elm);
         this.drag_tr = new Draggable(elm, this.el_tr, RESIZE_TR, this.options);
         this.el_br = createElement('div', { name: 'grab-br' }, elm);
         this.drag_br = new Draggable(elm, this.el_br, RESIZE_BR, this.options);
         this.el_bl = createElement('div', { name: 'grab-bl' }, elm);
         this.drag_bl = new Draggable(elm, this.el_bl, RESIZE_BL, this.options);
       }
     }
   }

   class Draggable {
     constructor(targetElm, handleElm, op, options) {
       Object.assign(this, options);
       options = undefined;

       this._targetElm = targetElm;
       this._handleElm = handleElm;

       let vw = window.innerWidth;
       let vh = window.innerHeight;
       let initialX, initialY, initialT, initialL, initialW, initialH;

       const clamp = (value, min, max) => value < min ? min : value > max ? max : value;

       const moveOp = (x, y) => {
         const deltaX = (x - initialX);
         const deltaY = (y - initialY);
         const t = clamp(initialT + deltaY, 0, vh - initialH);
         const l = clamp(initialL + deltaX, 0, vw - initialW);
         this._targetElm.style.top = t + 'px';
         this._targetElm.style.left = l + 'px';
       };

       const resizeOp = (x, y) => {
         x = clamp(x, 0, vw);
         y = clamp(y, 0, vh);
         const deltaX = (x - initialX);
         const deltaY = (y - initialY);
         const resizeDirX = (op & RESIZE_L) ? -1 : 1;
         const resizeDirY = (op & RESIZE_T) ? -1 : 1;
         const deltaXMax = (this.maxWidth - initialW);
         const deltaXMin = (this.minWidth - initialW);
         const deltaYMax = (this.maxHeight - initialH);
         const deltaYMin = (this.minHeight - initialH);
         const t = initialT + clamp(deltaY * resizeDirY, deltaYMin, deltaYMax) * resizeDirY;
         const l = initialL + clamp(deltaX * resizeDirX, deltaXMin, deltaXMax) * resizeDirX;
         const w = initialW + clamp(deltaX * resizeDirX, deltaXMin, deltaXMax);
         const h = initialH + clamp(deltaY * resizeDirY, deltaYMin, deltaYMax);
         if (op & RESIZE_T) { // resize ↑
           this._targetElm.style.top = t + 'px';
           this._targetElm.style.height = h + 'px';
         }
         if (op & RESIZE_B) { // resize ↓
           this._targetElm.style.height = h + 'px';
         }
         if (op & RESIZE_L) { // resize ←
           this._targetElm.style.left = l + 'px';
           this._targetElm.style.width = w + 'px';
         }
         if (op & RESIZE_R) { // resize →
           this._targetElm.style.width = w + 'px';
         }
       };

       let operation = op === MOVE ? moveOp : resizeOp;

       function dragStartHandler(e) {
         const touch = e.type === 'touchstart';
         if ((e.buttons === 1 || e.which === 1) || touch) {
           e.preventDefault();
           const x = touch ? e.touches[0].clientX : e.clientX;
           const y = touch ? e.touches[0].clientY : e.clientY;
           initialX = x;
           initialY = y;
           vw = window.innerWidth;
           vh = window.innerHeight;
           initialT = this._targetElm.offsetTop;
           initialL = this._targetElm.offsetLeft;
           initialW = this._targetElm.clientWidth;
           initialH = this._targetElm.clientHeight;
           if (this.useMouseEvents) {
             document.addEventListener('mousemove', this._dragMoveHandler);
             document.addEventListener('mouseup', this._dragEndHandler);
           }
           if (this.useTouchEvents) {
             document.addEventListener('touchmove', this._dragMoveHandler, { passive: false });
             document.addEventListener('touchend', this._dragEndHandler);
           }
           this._targetElm.classList.add(this.draggingClass);
         }
       }

       function dragMoveHandler(e) {
         e.preventDefault();
         let x, y;
         const touch = e.type === 'touchmove';
         if (touch) {
           const t = e.touches[0];
           x = t.clientX;
           y = t.clientY;
         } else { //mouse
           // If the button is not down, dispatch a "fake" mouse up event, to stop listening to mousemove
           // This happens when the mouseup is not captured (outside the browser)
           if ((e.buttons || e.which) !== 1) {
             this._dragEndHandler();
             return;
           }
           x = e.clientX;
           y = e.clientY;
         }
         // perform drag / resize operation
         operation(x, y);
       }

       function dragEndHandler(e) {
         if (this.useMouseEvents) {
           document.removeEventListener('mousemove', this._dragMoveHandler);
           document.removeEventListener('mouseup', this._dragEndHandler);
         }
         if (this.useTouchEvents) {
           document.removeEventListener('touchmove', this._dragMoveHandler);
           document.removeEventListener('touchend', this._dragEndHandler);
         }
         this._targetElm.classList.remove(this.draggingClass);
       }

       // We need to bind the handlers to this instance
       this._dragStartHandler = dragStartHandler.bind(this);
       this._dragMoveHandler = dragMoveHandler.bind(this);
       this._dragEndHandler = dragEndHandler.bind(this);

       this.enable();
     }

     /** Turn on the drag and drop of the instance */
     enable() {
       this.destroy(); // prevent events from getting binded twice
       if (this.useMouseEvents) this._handleElm.addEventListener('mousedown', this._dragStartHandler);
       if (this.useTouchEvents) this._handleElm.addEventListener('touchstart', this._dragStartHandler, { passive: false });
     }

     /** Teardown all events bound to the document and elements. You can resurrect this instance by calling enable() */
     destroy() {
       this._targetElm.classList.remove(this.draggingClass);
       if (this.useMouseEvents) {
         this._handleElm.removeEventListener('mousedown', this._dragStartHandler);
         document.removeEventListener('mousemove', this._dragMoveHandler);
         document.removeEventListener('mouseup', this._dragEndHandler);
       }
       if (this.useTouchEvents) {
         this._handleElm.removeEventListener('touchstart', this._dragStartHandler);
         document.removeEventListener('touchmove', this._dragMoveHandler);
         document.removeEventListener('touchend', this._dragEndHandler);
       }
     }
   }

   function createElement(tag='div', attrs, parent) {
     const elm = document.createElement(tag);
     if (attrs) Object.entries(attrs).forEach(([k, v]) => elm.setAttribute(k, v));
     if (parent) parent.appendChild(elm);
     return elm;
   }

   function defaultArgs(defaults, options) {
     function isObj(x) { return x !== null && typeof x === 'object'; }
     function hasOwn(obj, prop) { return Object.prototype.hasOwnProperty.call(obj, prop); }
     if (isObj(options)) for (let prop in defaults) {
       if (hasOwn(defaults, prop) && hasOwn(options, prop) && options[prop] !== undefined) {
         if (isObj(defaults[prop])) defaultArgs(defaults[prop], options[prop]);
         else defaults[prop] = options[prop];
       }
     }
     return defaults;
   }

   function createElm(html) {
     const temp = document.createElement('div');
     temp.innerHTML = html;
     return temp.removeChild(temp.firstElementChild);
   }

   function insertCss(css) {
     const style = document.createElement('style');
     style.appendChild(document.createTextNode(css));
     document.head.appendChild(style);
     return style;
   }

   const messagePickerCss = `
body.undiscord-pick-message [data-list-id="chat-messages"] {
  background-color: var(--background-secondary-alt);
  box-shadow: inset 0 0 0px 2px var(--button-outline-brand-border);
}

body.undiscord-pick-message [id^="message-content-"]:hover {
  cursor: pointer;
  cursor: cell;
  background: var(--background-message-automod-hover);
}
body.undiscord-pick-message [id^="message-content-"]:hover::after {
  position: absolute;
  top: calc(50% - 11px);
  left: 4px;
  z-index: 1;
  width: 65px;
  height: 22px;
  line-height: 22px;
  font-family: var(--font-display);
  background-color: var(--button-secondary-background);
  color: var(--header-secondary);
  font-size: 12px;
  font-weight: 500;
  text-transform: uppercase;
  text-align: center;
  border-radius: 3px;
  content: 'This 👉';
}
body.undiscord-pick-message.before [id^="message-content-"]:hover::after {
  content: 'Before 👆';
}
body.undiscord-pick-message.after [id^="message-content-"]:hover::after {
  content: 'After 👇';
}
`;

   const messagePicker = {
     init() {
       insertCss(messagePickerCss);
     },
     grab(auxiliary) {
       return new Promise((resolve, reject) => {
         document.body.classList.add('undiscord-pick-message');
         if (auxiliary) document.body.classList.add(auxiliary);
         function clickHandler(e) {
           const message = e.target.closest('[id^="message-content-"]');
           if (message) {
             e.preventDefault();
             e.stopPropagation();
             e.stopImmediatePropagation();
             if (auxiliary) document.body.classList.remove(auxiliary);
             document.body.classList.remove('undiscord-pick-message');
             document.removeEventListener('click', clickHandler);
             try {
               resolve(message.id.match(/message-content-(\d+)/)[1]);
             } catch (e) {
               resolve(null);
             }
           }
         }
         document.addEventListener('click', clickHandler);
       });
     }
   };
   window.messagePicker = messagePicker;

   function getTokenFromWebpack(globalObj) {
     const chunkKeys = Object.keys(globalObj).filter(
       k => k.startsWith('webpackChunk') && Array.isArray(globalObj[k])
     );

     let req = null;
     let foundKey = null;
     for (const key of chunkKeys) {
       const chunk = globalObj[key];
       if (!chunk || typeof chunk.push !== 'function') continue;
       try {
         const tokenId = `__undiscord__${Date.now()}`;
         chunk.push([[tokenId], {}, r => { req = r; }]);
         if (req?.c) {
           foundKey = key;
           break;
         }
       } catch {}
     }

     if (!req && typeof globalObj.__webpack_require__ === 'function' && globalObj.__webpack_require__.c) {
       req = globalObj.__webpack_require__;
       foundKey = '__webpack_require__';
     }

     if (!req?.c) throw new Error('webpack require not found');

     const modules = Object.values(req.c);
     const mod = modules.find(m =>
       m?.exports?.default?.getToken ||
       m?.exports?.getToken
     );

     if (!mod) {
       throw new Error(`getToken module not found (chunk=${foundKey || 'unknown'})`);
     }

     if (mod?.exports?.default?.getToken) return mod.exports.default.getToken();
     if (mod?.exports?.getToken) return mod.exports.getToken();
     throw new Error('getToken export not callable');
   }

  function normalizeTokenCandidate(raw) {
    if (typeof raw !== 'string') return '';
    const s = raw.trim();
    if (!s) return '';
    try {
      const parsed = JSON.parse(s);
      return typeof parsed === 'string' ? parsed : '';
    } catch {
      // In some builds/storage states token can already be plain text.
      return s.replace(/^"|"$/g, '');
    }
  }

   function getTokenFromPageContext() {
     return new Promise((resolve, reject) => {
       const reqId = `undiscord_token_${Date.now()}_${Math.random().toString(36).slice(2)}`;
       const timeoutMs = 10000;
       let done = false;

       function cleanup() {
         if (done) return;
         done = true;
         window.removeEventListener('message', onMessage);
       }

       function onMessage(event) {
         if (event.source !== window) return;
         const data = event.data;
         if (!data || data.source !== 'undiscord' || data.id !== reqId) return;
         cleanup();
         if (data.error) {
           reject(new Error(data.error));
         } else {
           resolve(data.token || '');
         }
       }

       window.addEventListener('message', onMessage);

       const script = document.createElement('script');
       script.textContent = `(function(){try{
  var globalObj = window;
  var chunkKeys = Object.keys(globalObj).filter(function(k){return k.indexOf('webpackChunk')===0 && Array.isArray(globalObj[k]);});
  var req = null;
  var foundKey = null;
  for (var i=0;i<chunkKeys.length;i++){
    var key = chunkKeys[i];
    var chunk = globalObj[key];
    if (!chunk || typeof chunk.push !== 'function') continue;
    try {
      var tokenId = '__undiscord__' + Date.now();
      chunk.push([[tokenId], {}, function(r){ req = r; }]);
      if (req && req.c){ foundKey = key; break; }
    } catch(e){}
  }
  if (!req && typeof globalObj.__webpack_require__ === 'function' && globalObj.__webpack_require__.c){
    req = globalObj.__webpack_require__;
    foundKey = '__webpack_require__';
  }
  if (!req || !req.c) throw new Error('webpack require not found');
  var modules = Object.values(req.c);
  var mod = modules.find(function(m){ return (m && m.exports && m.exports.default && m.exports.default.getToken) || (m && m.exports && m.exports.getToken); });
  if (!mod) throw new Error('getToken module not found (chunk=' + (foundKey || 'unknown') + ')');
  var token = null;
  if (mod.exports && mod.exports.default && mod.exports.default.getToken) token = mod.exports.default.getToken();
  else if (mod.exports && mod.exports.getToken) token = mod.exports.getToken();
  else throw new Error('getToken export not callable');
  window.postMessage({source:'undiscord', id:'${reqId}', token: token}, '*');
}catch(e){
  window.postMessage({source:'undiscord', id:'${reqId}', error: String(e && (e.message || e))}, '*');
}})();`;
      script.onerror = () => {
        cleanup();
        reject(new Error('page-context script injection blocked or failed'));
      };
       (document.head || document.documentElement).appendChild(script);
       script.remove();

       setTimeout(() => {
         cleanup();
         reject(new Error('token request timeout'));
       }, timeoutMs);
     });
   }

   function getTokenFromClassicWebpackPush() {
     const chunk = window.webpackChunkdiscord_app;
     if (!Array.isArray(chunk) || typeof chunk.push !== 'function') {
       throw new Error('webpackChunkdiscord_app is not available');
     }

     let modules = [];
     chunk.push([['__undiscord__classic__'], {}, (e) => {
       modules = [];
       for (const c in e.c) modules.push(e.c[c]);
     }]);

     const mod = modules.find(m =>
       m?.exports?.default?.getToken !== void 0 ||
       m?.exports?.getToken !== void 0
     );
     if (!mod) throw new Error('classic webpack push: getToken module not found');

     if (mod?.exports?.default?.getToken) return mod.exports.default.getToken();
     if (mod?.exports?.getToken) return mod.exports.getToken();
     throw new Error('classic webpack push: getToken export not callable');
   }

   async function getToken() {
     window.dispatchEvent(new Event('beforeunload'));
     const LS = document.body.appendChild(document.createElement('iframe')).contentWindow.localStorage;

    const storageToken = normalizeTokenCandidate(LS.token);
    if (storageToken) return storageToken;

    log.info('Could not automatically detect Authorization Token in local storage!');
    log.info('Attempting to grab token using webpack');

    const attempts = [];

    try {
      const t = getTokenFromWebpack(window);
      if (t) return t;
      attempts.push('getTokenFromWebpack: empty token');
    } catch (err) {
      attempts.push(`getTokenFromWebpack: ${String(err?.message || err)}`);
      log.warn('Generic webpack token extraction failed, trying classic webpack push...', err);
    }

    try {
      const t = getTokenFromClassicWebpackPush();
      if (t) return t;
      attempts.push('getTokenFromClassicWebpackPush: empty token');
    } catch (errClassic) {
      attempts.push(`getTokenFromClassicWebpackPush: ${String(errClassic?.message || errClassic)}`);
      log.warn('Classic webpack push token extraction failed in content world, trying page context...', errClassic);
    }

    try {
      const t = await getTokenFromPageContext();
      if (t) return t;
      attempts.push('getTokenFromPageContext: empty token');
    } catch (err2) {
      attempts.push(`getTokenFromPageContext: ${String(err2?.message || err2)}`);
      log.warn('Page-context token extraction failed.', err2);
    }

    const chunkKeys = Object.keys(window).filter(k => k.startsWith('webpackChunk'));
    log.debug('Token extraction attempts:', attempts);
    log.debug('webpackChunk keys detected:', chunkKeys);
    throw new Error('token auto-detection failed');
   }

   function getAuthorId() {
     const LS = document.body.appendChild(document.createElement('iframe')).contentWindow.localStorage;
     return JSON.parse(LS.user_id_cache);
   }

  function getGuildId({ silent = false } = {}) {
    const m = location.href.match(/channels\/([\w@]+)\/(\d+)/);
    if (m) return m[1];
    if (!silent) alert('Could not find the Guild ID!\nPlease make sure you are on a Server or DM.');
    return null;
  }

  function getChannelId({ silent = false } = {}) {
    const m = location.href.match(/channels\/([\w@]+)\/(\d+)/);
    if (m) return m[2];
    if (!silent) alert('Could not find the Channel ID!\nPlease make sure you are on a Channel or DM.');
    return null;
  }


  function parseChannelIdsInput(value) {
    const ids = new Set();
    for (const token of String(value).split(/[\s,;]+/).filter(Boolean)) {
      const link = token.match(/^https:\/\/(?:[a-z]+\.)?discord(?:app)?\.com\/channels\/(?:@me|\d+)\/(\d{17,21})(?:\/\d+)?\/?(?:[?#].*)?$/);
      const mention = token.match(/^<#(\d{17,21})>$/);
      const id = link ? link[1] : mention ? mention[1] : token;
      if (!/^\d{17,21}$/.test(id)) throw new Error('Channel IDs must be valid IDs, channel mentions, or Discord channel links.');
      ids.add(id);
    }
    return Array.from(ids);
  }


  async function getServerMessageChannels(guildId, core, { channelIds = [], allChannels = false, onProgress = () => {} } = {}) {
    const issues = [];
    const channels = new Map();
    const known = new Map();
    const guildLists = new Map();
    const scope = new Map();
    const parents = new Map();
    const threadTypes = new Set([10, 11, 12]);
    const historyTypes = new Set([0, 1, 2, 3, 5, 10, 11, 12, 13]);
    const archiveParentTypes = new Set([0, 5, 15, 16]);
    const includeNsfw = !!core.options.includeNsfw;

    function id(value, label) {
      if (typeof value !== 'string' || !/^[1-9]\d{0,19}$/.test(value) || BigInt(value) > 18446744073709551615n) {
        throw new Error(`${label} must be a numeric snowflake string.`);
      }
      return value;
    }

    const gid = guildId === '@me' ? '@me' : id(guildId, 'Guild ID');
    if (!Array.isArray(channelIds)) throw new Error('Channel IDs must be an array.');
    if (allChannels && gid === '@me') throw new Error('All-channels discovery requires a guild ID, not @me.');

    function progress(text) {
      core.checkRunning();
      onProgress(text);
      core.checkRunning();
    }

    function report(context, error) {
      if (error?.name === 'AbortError' || error?.status === 401) throw error;
      core.checkRunning();
      const detail = error instanceof Error ? error.message : String(error);
      const message = `${context}: ${detail}`;
      issues.push(message);
      log.warn(message);
    }

    // Keep archive metadata until pagination has consumed it; public/private cursors are timestamps, not IDs.
    function parseChannel(raw, { expectedGuild = '', expectedId = '', expectedParent = '', requireThread = false, inferGuild = false } = {}) {
      if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw new Error('Invalid channel metadata.');
      const channelId = id(raw.id, 'Returned channel ID');
      if (expectedId && channelId !== expectedId) throw new Error(`Returned channel ${channelId} does not match ${expectedId}.`);
      if (!Number.isInteger(raw.type) || raw.type < 0) throw new Error(`Invalid type for channel ${channelId}.`);
      const isThread = threadTypes.has(raw.type);
      if (requireThread && !isThread) throw new Error(`Channel ${channelId} is not a thread.`);
      const isDm = raw.type === 1 || raw.type === 3;
      // Guild-scoped endpoints establish the guild even if the optional guild_id field is omitted.
      const channelGuild = raw.guild_id == null ? (isDm || !inferGuild ? '' : expectedGuild) : id(raw.guild_id, 'Returned guild ID');
      if (!isDm && !channelGuild) throw new Error(`Missing guild metadata for channel ${channelId}.`);
      if (isDm && channelGuild) throw new Error(`DM channel ${channelId} unexpectedly has a guild.`);
      if (expectedGuild && channelGuild !== expectedGuild) throw new Error(`Channel ${channelId} belongs to a different guild.`);
      const parentId = raw.parent_id == null ? '' : id(raw.parent_id, 'Returned parent ID');
      if (isThread && !parentId) throw new Error(`Missing parent for thread ${channelId}.`);
      if (expectedParent && parentId !== expectedParent) throw new Error(`Thread ${channelId} belongs to a different parent.`);
      if (raw.name != null && typeof raw.name !== 'string') throw new Error(`Invalid channel name for ${channelId}.`);
      if (raw.nsfw != null && typeof raw.nsfw !== 'boolean') throw new Error(`Invalid NSFW metadata for ${channelId}.`);
      let archiveTimestamp = '';
      let archiveTime = null;
      if (isThread) {
        archiveTimestamp = raw.thread_metadata?.archive_timestamp;
        if (typeof archiveTimestamp !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/.test(archiveTimestamp) || !Number.isFinite(Date.parse(archiveTimestamp))) {
          throw new Error(`Missing or invalid archive timestamp for thread ${channelId}.`);
        }
        archiveTime = Date.parse(archiveTimestamp);
      }
      const result = {
        channel: { id: channelId, type: raw.type, name: raw.name || '', guild_id: channelGuild, parent_id: parentId },
        nsfw: raw.nsfw === true,
        archiveTimestamp,
        archiveTime,
      };
      known.set(channelId, result);
      return result;
    }

    async function resolveChannel(channelId, expectedGuild = '') {
      const cached = known.get(channelId);
      if (cached) {
        if (expectedGuild && cached.channel.guild_id !== expectedGuild) throw new Error(`Channel ${channelId} belongs to a different guild.`);
        return cached;
      }
      core.checkRunning();
      const raw = await core.request(`/channels/${channelId}`);
      core.checkRunning();
      return parseChannel(raw, { expectedId: channelId, expectedGuild });
    }

    async function listGuildChannels(channelGuild) {
      if (guildLists.has(channelGuild)) return guildLists.get(channelGuild);
      const result = [];
      guildLists.set(channelGuild, result);
      progress(`Discovering channels in guild ${channelGuild}…`);
      try {
        const raw = await core.request(`/guilds/${channelGuild}/channels`);
        core.checkRunning();
        if (!Array.isArray(raw)) throw new Error('The guild channel list is not an array.');
        for (const entry of raw) {
          try {
            result.push(parseChannel(entry, { expectedGuild: channelGuild, inferGuild: true }));
          } catch (error) {
            report(`Guild ${channelGuild} channel metadata`, error);
          }
        }
      } catch (error) {
        report(`Could not enumerate guild ${channelGuild}`, error);
      }
      return result;
    }

    async function addScope(info) {
      core.checkRunning();
      const channel = info.channel;
      if (scope.has(channel.id)) return;
      scope.set(channel.id, info);
      if (channel.type !== 4 || gid === '@me') return;
      const siblings = await listGuildChannels(channel.guild_id);
      for (const child of siblings) {
        if (child.channel.parent_id === channel.id) await addScope(child);
      }
    }

    async function addHistory(info) {
      core.checkRunning();
      const channel = info.channel;
      if (!includeNsfw) {
        if (info.nsfw) {
          log.info(`Skipping NSFW channel ${channel.name || channel.id} because Include NSFW is disabled.`);
          return;
        }
        if (threadTypes.has(channel.type)) {
          try {
            const parent = await resolveChannel(channel.parent_id, channel.guild_id);
            if (!archiveParentTypes.has(parent.channel.type)) throw new Error(`Invalid parent type for thread ${channel.id}.`);
            if (parent.nsfw) {
              log.info(`Skipping thread ${channel.name || channel.id} in NSFW parent ${parent.channel.name || parent.channel.id} because Include NSFW is disabled.`);
              return;
            }
          } catch (error) {
            report(`Could not determine NSFW eligibility for thread ${channel.id}`, error);
            return;
          }
        }
      }
      channels.set(channel.id, channel);
    }

    if (allChannels) {
      for (const info of await listGuildChannels(gid)) scope.set(info.channel.id, info);
    } else {
      const selected = new Set();
      for (const value of channelIds) {
        try {
          selected.add(id(value, 'Selected channel ID'));
        } catch (error) {
          report('Invalid channel selection', error);
        }
      }
      if (!selected.size && !issues.length) throw new Error('Select at least one channel.');
      let index = 0;
      for (const channelId of selected) {
        progress(`Resolving selected channel ${++index}/${selected.size}: ${channelId}…`);
        try {
          await addScope(await resolveChannel(channelId, gid === '@me' ? '' : gid));
        } catch (error) {
          report(`Could not resolve selected channel ${channelId}`, error);
        }
      }
    }

    for (const info of scope.values()) {
      core.checkRunning();
      const channel = info.channel;
      if (!includeNsfw && info.nsfw) {
        log.info(`Skipping NSFW channel ${channel.name || channel.id} because Include NSFW is disabled.`);
        continue;
      }
      if (historyTypes.has(channel.type)) await addHistory(info);
      // @me imports are exact-ID selections, even when a selected ID resolves to a guild channel.
      if (gid !== '@me' && archiveParentTypes.has(channel.type)) parents.set(channel.id, info);
      if (gid === '@me' && (channel.type === 4 || channel.type === 15 || channel.type === 16)) {
        report(`Selected container ${channel.id}`, new Error('An @me import selects exact channel IDs; select this container in its guild to expand its children.'));
      } else if (!historyTypes.has(channel.type) && channel.type !== 4 && !archiveParentTypes.has(channel.type)) {
        report(`Unsupported channel ${channel.id}`, new Error(`Channel type ${channel.type} cannot be scanned for message history.`));
      }
    }

    if (gid !== '@me' && (allChannels || parents.size)) {
      progress(`Discovering active threads in guild ${gid}…`);
      try {
        const raw = await core.request(`/guilds/${gid}/threads/active`);
        core.checkRunning();
        if (!raw || !Array.isArray(raw.threads)) throw new Error('Invalid active-thread response.');
        for (const entry of raw.threads) {
          try {
            const info = parseChannel(entry, { expectedGuild: gid, requireThread: true, inferGuild: true });
            if (allChannels || parents.has(info.channel.parent_id)) await addHistory(info);
          } catch (error) {
            report(`Guild ${gid} active-thread metadata`, error);
          }
        }
      } catch (error) {
        report(`Could not enumerate active threads in guild ${gid}`, error);
      }
    }

    async function scanArchive(parent, kind) {
      const channel = parent.channel;
      const joined = kind === 'joined private';
      const privateThreads = kind !== 'public';
      const endpoint = joined ? 'users/@me/threads/archived/private' : `threads/archived/${kind}`;
      let before = '';
      let beforeTime = null;
      const cursors = new Set();
      let page = 0;
      try {
        while (true) {
          progress(`Discovering ${kind} archived threads in ${channel.name || channel.id}, page ${++page}…`);
          const query = `limit=100${before ? `&before=${encodeURIComponent(before)}` : ''}`;
          const raw = await core.request(`/channels/${channel.id}/${endpoint}?${query}`);
          core.checkRunning();
          if (!raw || !Array.isArray(raw.threads) || typeof raw.has_more !== 'boolean') throw new Error('Invalid archived-thread response.');
          let last = null;
          for (const entry of raw.threads) {
            last = null;
            try {
              const info = parseChannel(entry, { expectedGuild: channel.guild_id, expectedParent: channel.id, requireThread: true, inferGuild: true });
              const expectedType = privateThreads ? 12 : (channel.type === 5 ? 10 : 11);
              if (info.channel.type !== expectedType) throw new Error(`Unexpected thread type ${info.channel.type} in ${kind} archive.`);
              last = info;
              await addHistory(info);
            } catch (error) {
              report(`Channel ${channel.id} ${kind} archive metadata`, error);
            }
          }
          if (!raw.has_more) return true;
          if (!last) throw new Error('The archive claims more pages but supplies no usable final thread cursor.');
          const next = joined ? last.channel.id : last.archiveTimestamp;
          const movedForward = before && (joined ? BigInt(next) >= BigInt(before) : last.archiveTime > beforeTime);
          if (cursors.has(next) || movedForward) throw new Error('Archived-thread pagination did not advance; discovery is incomplete.');
          cursors.add(next);
          before = next;
          beforeTime = last.archiveTime;
          await core.waitWithTracking(120);
        }
      } catch (error) {
        if (error?.name === 'AbortError' || error?.status === 401) throw error;
        core.checkRunning();
        if (kind === 'private' && error?.status === 403) {
          log.info(`Channel ${channel.name || channel.id}: all-private archive access is restricted; enumerating joined private threads only. Nonjoined restricted threads are not covered.`);
        } else {
          report(`Could not fully enumerate ${kind} archives in channel ${channel.id}`, error);
        }
        return false;
      }
    }

    for (const parent of parents.values()) {
      core.checkRunning();
      await scanArchive(parent, 'public');
      // Announcement, forum, and media parents do not support private threads.
      if (parent.channel.type === 0) {
        const completePrivateListing = await scanArchive(parent, 'private');
        if (!completePrivateListing) await scanArchive(parent, 'joined private');
      }
    }
    progress(`Discovery complete: ${channels.size} message channels; ${issues.length} discovery issue(s).`);
    return { channels: Array.from(channels.values()), issues };
  }






   async function fillToken() {
     try {
       return await getToken();
     } catch (err) {
       // Discord changes frequently; auto token extraction is brittle and may stop working.
       log.warn('Could not automatically detect Authorization Token (Discord likely changed how it stores/exposes it).');
       log.info('Please enter the token manually in the "Advanced settings" section.');
       log.debug('Auto-detection failure details:', err);
     }
     return '';
   }

   const PREFIX = '[UNDISCORD]';

   // -------------------------- User interface ------------------------------- //

   // links
   const HOME = 'https://github.com/y0usaf/undiscord';
   const WIKI = 'https://github.com/victornpb/undiscord/wiki';

   const undiscordCore = new UndiscordCore();
   messagePicker.init();

   const ui = {
     undiscordWindow: null,
     undiscordBtn: null,
     logArea: null,
     autoScroll: null,

     // progress handler
     progressMain: null,
     progressIcon: null,
     progressBarPercent: null,
     percent: null,

    verboseMode: null,
    previewMode: null,
    hideAuthorText: null,
    hideMessageText: null,
    redact: null,
    channelBadge: null,
    channelName: null,
    convBadge: null,
    convName: null,
    convAvatar: null,
    deleteAllChannels: null,
    preScanStatus: null,
   };
   const $ = s => ui.undiscordWindow.querySelector(s);

   function initUI() {

     insertCss(themeCss);
     insertCss(mainCss);
     insertCss(dragCss);
    insertCss(undiscordUiCss);

     // create undiscord window
     const undiscordUI = replaceInterpolations(undiscordTemplate, {
       VERSION,
       HOME,
       WIKI,
     });
     ui.undiscordWindow = createElm(undiscordUI);
     document.body.appendChild(ui.undiscordWindow);

    // ---------- Auto update IDs on conversation change ----------
    function isUndiscordOpen() {
      return ui.undiscordWindow && ui.undiscordWindow.style.display !== 'none';
    }

    let lastRoute = location.pathname;
    let requestButtonRemount = () => {};

    function onConversationChange() {
      const route = location.pathname;
      if (route !== lastRoute) {
        lastRoute = route;
        if (isUndiscordOpen() && !undiscordCore.state.running) {
          safeAutofillFields();
        }
      }
      updateDeleteAllToggleVisibility();
      scheduleConversationBadgeUpdate();
    }


    // Hook navigation SPA Discord
    (function hookDiscordNavigation() {
      const push = history.pushState;
      const replace = history.replaceState;

      history.pushState = function () {
        const r = push.apply(this, arguments);
        queueMicrotask(() => {
          onConversationChange();
          requestButtonRemount();
        });
        return r;
      };

      history.replaceState = function () {
        const r = replace.apply(this, arguments);
        queueMicrotask(onConversationChange);
        return r;
      };

      window.addEventListener('popstate', onConversationChange);
    })();
    const chatObserver = new MutationObserver(() => {
      onConversationChange();
    });

    const appMount = document.querySelector('#app-mount');
    if (appMount) {
      chatObserver.observe(appMount, {
        childList: true,
        subtree: false
      });
    }

     // enable drag and resize on undiscord window
     new DragResize({ elm: ui.undiscordWindow, moveHandle: $('.header') });

     // create undiscord Trash icon
     ui.undiscordBtn = createElm(buttonHtml);
     ui.undiscordBtn.onclick = toggleWindow;

    // ====== ROBUST MOUNT (language-free, without patch history) ======
    (function mountUndiscordButtonRobust(btn, onRouteMaybeChanged) {
      const ROOT_SEL = '#app-mount';
      const BTN_ID = 'undicord-btn';

      // Ensure a stable id (useful to avoid duplicates)
      if (!btn.id) btn.id = BTN_ID;

      function isVisible(el) {
        if (!el) return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0 && r.bottom > 0 && r.right > 0;
      }

      function findTopCombobox() {
        // Discord often has multiple comboboxes. Pick the highest visible one.
        const all = Array.from(document.querySelectorAll(
          `${ROOT_SEL} [role="combobox"][contenteditable="true"]`
        ));
        const visible = all.filter(isVisible);
        if (!visible.length) return null;
        visible.sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top);
        return visible[0];
      }

      function findToolbarFrom(el) {
        // Walk up to a "top" container that contains many buttons
        let p = el;
        for (let i = 0; i < 40 && p; i++) {
          if (p.nodeType === 1) {
            const top = p.getBoundingClientRect().top;
            if (top <= 180) {
              const buttons = p.querySelectorAll?.('[role="button"]').length || 0;
              const hasCombo = !!p.querySelector?.('[role="combobox"][contenteditable="true"]');
              // "toolbar" heuristic
              if (buttons >= 3 && hasCombo) return p;
            }
          }
          p = p.parentElement;
        }
        return null;
      }

      function findSearchBlock(combobox, toolbar) {
        // Find a block that contains the combobox + at least 1 svg (search/clear)
        let p = combobox;
        for (let i = 0; i < 18 && p && p !== toolbar; i++) {
          if (toolbar.contains(p)) {
            const hasSvg = !!p.querySelector?.('svg');
            const hasCombo = !!p.querySelector?.('[role="combobox"][contenteditable="true"]');
            if (hasSvg && hasCombo) return p;
          }
          p = p.parentElement;
        }
        return null;
      }

      function ensureMounted() {
        const root = document.querySelector(ROOT_SEL);
        if (!root) return false;

        const combobox = findTopCombobox();
        if (!combobox) return false;

        const toolbar = findToolbarFrom(combobox);
        if (!toolbar) return false;

        // If already in this toolbar, just ensure styling
        if (toolbar.contains(btn)) {
          btn.style.order = '9999';
          btn.style.marginLeft = '8px';
          btn.style.flex = '0 0 auto';
          return true;
        }

        const searchBlock = findSearchBlock(combobox, toolbar);

        // Insert after the most "top-level" search block under the toolbar
        if (searchBlock) {
          let top = searchBlock;
          while (top.parentElement && top.parentElement !== toolbar) top = top.parentElement;
          top.insertAdjacentElement('afterend', btn);
        } else {
          toolbar.appendChild(btn);
        }

        btn.style.order = '9999';
        btn.style.marginLeft = '8px';
        btn.style.flex = '0 0 auto';
        return true;
      }

      // Anti-spam scheduler
      let scheduled = false;
      const schedule = () => {
        if (scheduled) return;
        scheduled = true;
        requestAnimationFrame(() => {
          scheduled = false;

          const ok = ensureMounted();
          // Optional: auto-refresh fields when Discord changes view
          if (ok && typeof onRouteMaybeChanged === 'function') onRouteMaybeChanged();
        });
      };
      requestButtonRemount = schedule;

      // Observe DOM (Discord = SPA, everything shows up in the DOM)
      const root = document.querySelector(ROOT_SEL);
      if (!root) return;

      // Broad observer, throttled by schedule()
      const obs = new MutationObserver(schedule);
      obs.observe(root, { childList: true, subtree: true });

      // Initial mount
      schedule();
    })(ui.undiscordBtn, onConversationChange);


    function safeAutofillFields() {
      if (undiscordCore?.state?.running) return;

      try {
        const v = getAuthorId();
        if (v) $('input#authorId').value = v;
      } catch {}

      try {
        const v = getGuildId({ silent: true });
        if (v) $('input#guildId').value = v;
      } catch {}

      try {
        const v = getChannelId({ silent: true });
        if (v) $('input#channelId').value = v;
      } catch {}

      updateDeleteAllToggleVisibility();
    }

    function isVisible(el) {
      if (!el) return false;
      const r = el.getBoundingClientRect();
      return r.width > 0 && r.height > 0 && r.bottom > 0 && r.right > 0;
    }

    function isValidDiscordAvatarUrl(url) {
      if (!url || typeof url !== 'string') return false;
      return /https:\/\/(cdn|media)\.discord(app)?\.com\/(avatars|embed\/avatars|icons|guilds|users)\//.test(url);
    }

    function normalizeConvName(text) {
      return String(text || '')
        .trim();
    }

    function hashToHue(input) {
      const s = String(input || '');
      let h = 0;
      for (let i = 0; i < s.length; i++) {
        h = ((h << 5) - h + s.charCodeAt(i)) | 0;
      }
      return Math.abs(h) % 360;
    }

    function makeInitials(label) {
      const text = normalizeConvName(label).replace(/\s+/g, ' ');
      if (!text) return '?';
      // Preserve Discord acronym as-is when available (e.g. "Sdc").
      if (!text.includes(' ') && /^[A-Za-z0-9]{2,4}$/.test(text)) return text;
      const words = text.split(' ').filter(Boolean);
      if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
      const compact = words[0].replace(/[^A-Za-z0-9]/g, '');
      if (!compact) return '?';
      return compact.slice(0, 2).toUpperCase();
    }

    function makeGuildFallbackAvatarDataUrl(label) {
      const initials = makeInitials(label);
      const hue = hashToHue(label || initials);
      const bg1 = `hsl(${hue}, 68%, 40%)`;
      const bg2 = `hsl(${(hue + 28) % 360}, 65%, 30%)`;
      const svg =
        `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">` +
        `<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">` +
        `<stop offset="0%" stop-color="${bg1}"/><stop offset="100%" stop-color="${bg2}"/></linearGradient></defs>` +
        `<rect width="64" height="64" rx="32" fill="url(#g)"/>` +
        `<text x="50%" y="54%" text-anchor="middle" dominant-baseline="middle" font-family="system-ui,Segoe UI,Arial" font-size="24" font-weight="700" fill="white">${escapeHTML(initials)}</text>` +
        `</svg>`;
      return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
    }

    function parseGuildIdFromListItemId(listItemId) {
      const m = String(listItemId || '').match(/^guildsnav___(\d+)$/);
      return m ? m[1] : '';
    }

    function getGuildInfoFromNavItem(item) {
      if (!item) return { guildId: '', name: '', avatar: '' };

      const guildId = parseGuildIdFromListItemId(item.getAttribute('data-list-item-id'));
      if (!guildId) return { guildId: '', name: '', avatar: '' };

      const hidden = item.querySelector('.hiddenVisually_b18fe2');
      const dnd = item.closest('[data-dnd-name]')?.getAttribute('data-dnd-name') || '';
      const name = normalizeConvName(hidden?.textContent || dnd || '');
      const acronym = normalizeConvName(
        item.querySelector('[class*="acronym"]')?.textContent || ''
      );

      const img = item.querySelector('img.icon__6e9f8, img[aria-hidden="true"]');
      const avatar = img?.src && isValidDiscordAvatarUrl(img.src)
        ? img.src
        // Prefer Discord's displayed acronym (e.g. "Sdc") when no icon exists.
        : makeGuildFallbackAvatarDataUrl(acronym || name || guildId);

      return { guildId, name: isGenericConversationLabel(name) ? '' : name, avatar };
    }

    function getSelectedGuildInfoFromNav() {
      const selected = Array.from(document.querySelectorAll(
        '#app-mount [data-list-item-id^="guildsnav___"][aria-selected="true"]'
      )).find((el) => !!parseGuildIdFromListItemId(el.getAttribute('data-list-item-id')));

      return getGuildInfoFromNavItem(selected);
    }

    function getGuildInfoFromNavById(guildId) {
      const gid = String(guildId || '').trim();
      if (!gid || gid === '@me') return { guildId: '', name: '', avatar: '' };

      const item = document.querySelector(
        `#app-mount [data-list-item-id="guildsnav___${gid}"]`
      );
      return getGuildInfoFromNavItem(item);
    }

    function isGenericConversationLabel(text) {
      const t = normalizeConvName(text);
      return !t || /^[#@]?$/.test(t) || /^\d+$/.test(t);
    }

    function extractNameFromContainer(container) {
      if (!container) return '';
      const nameHost = container.querySelector('[class*="name__"] [class*="overflowTooltip"]')
        || container.querySelector('[class*="overflowTooltip"]')
        || container.querySelector('[data-text-variant]')
        || container;
      if (!nameHost) return '';

      const clone = nameHost.cloneNode(true);
      clone.querySelectorAll(
        '[class*="chiplet"], [class*="clanTag"], [class*="tagText"], [class*="badge"], [class*="hiddenVisually"], img, svg'
      ).forEach(n => n.remove());

      const name = normalizeConvName(clone.textContent || '');
      return isGenericConversationLabel(name) ? '' : name;
    }

    function getConversationInfoFromDom(channelId, guildId) {
      let name = '';
      let avatar = '';

      // For guilds, use server icon as avatar but keep channel name as title.
      if (guildId && guildId !== '@me') {
        const byId = getGuildInfoFromNavById(guildId);
        if (byId.avatar) avatar = byId.avatar;

        // Fallback: selected guild entry if direct lookup misses temporarily.
        if (!avatar) {
          const selected = getSelectedGuildInfoFromNav();
          if (selected.guildId === String(guildId)) {
            if (!avatar && selected.avatar) avatar = selected.avatar;
          }
        }
      }

      const header = Array.from(document.querySelectorAll('#app-mount header')).find(isVisible) || null;
      if (header) {
        // Prefer DM header content first to avoid generic header fallback while scrolling.
        const dmTitle = header.querySelector('.children__9293f .titleWrapper__9293f h1 span:not([class*="hiddenVisually"])')
          || header.querySelector('[class*="children__"] [class*="titleWrapper__"] h1 span:not([class*="hiddenVisually"])');
        if (dmTitle) {
          const dmName = normalizeConvName(dmTitle.textContent || '');
          if (!isGenericConversationLabel(dmName)) name = dmName;
        }
        const dmAvatar = header.querySelector('.children__9293f [class*="avatarStack"] img')
          || header.querySelector('[class*="children__"] [class*="avatarStack"] img');
        if (dmAvatar?.src && isValidDiscordAvatarUrl(dmAvatar.src)) avatar = dmAvatar.src;

        const heading = header.querySelector('h1, h2, [role="heading"]');
        if (!name) name = extractNameFromContainer(heading || header);
      }

      // Try exact conversation row from sidebar (works without token in many layouts)
      if ((!name || !avatar) && channelId) {
        const hrefPart = `/channels/${guildId || '@me'}/${channelId}`;
        const row = Array.from(document.querySelectorAll(`#app-mount a[href*="${hrefPart}"]`)).find(isVisible) || null;
        if (row) {
          name = name || extractNameFromContainer(row);
          const rowImg = Array.from(row.querySelectorAll('img')).find(i => isValidDiscordAvatarUrl(i.src));
          if (rowImg?.src) avatar = avatar || rowImg.src;
        }
      }

      if (!name) {
        const selected = Array.from(document.querySelectorAll('#app-mount [aria-selected="true"]')).find(isVisible) || null;
        if (selected) {
          name = extractNameFromContainer(selected);

          const img = Array.from(selected.querySelectorAll('img')).find(i => isValidDiscordAvatarUrl(i.src));
          if (img?.src) avatar = img.src;
        }
      }

      if (!avatar) {
        const header = Array.from(document.querySelectorAll('#app-mount header')).find(isVisible) || null;
        const img = header ? Array.from(header.querySelectorAll('img')).find(i => isValidDiscordAvatarUrl(i.src)) : null;
        if (img?.src) avatar = img.src;
      }

      return { name, avatar };
    }

    function getChannelNameFromSidebarById(channelId, guildId) {
      const cid = String(channelId || '').trim();
      if (!cid) return '';
      const gid = String(guildId || '').trim();
      const selectors = [
        `#app-mount a[data-list-item-id="channels___${cid}"]`,
        gid ? `#app-mount a[href="/channels/${gid}/${cid}"]` : '',
      ].filter(Boolean);
      for (const selector of selectors) {
        const anchor = document.querySelector(selector);
        if (!anchor) continue;
        const nameNode = anchor.querySelector('[class*="name__2ea32"], [class*="name__"]');
        const name = normalizeConvName(nameNode?.textContent || '');
        if (name && !isGenericConversationLabel(name)) return name;
      }
      return '';
    }

    function getAuthTokenForConv() {
      try {
        const v = $('input#token')?.value?.trim();
        if (v) return v;
      } catch {}
      try {
        const v = undiscordCore?.options?.authToken;
        if (typeof v === 'string' && v.trim()) return v.trim();
      } catch {}
      return '';
    }

    async function fetchSelfUserId(token) {
      const r = await fetch('https://discord.com/api/v9/users/@me', {
        headers: { Authorization: token }
      });
      if (!r.ok) throw new Error('GET /users/@me failed: ' + r.status);
      const me = await r.json();
      return me?.id || '';
    }

    function cdnDefaultAvatarUrl(userId, discriminator, size = 32) {
      try {
        const disc = String(discriminator ?? '0');
        if (disc === '0') {
          const mod = Number(BigInt(userId) >> 22n) % 6;
          return `https://cdn.discordapp.com/embed/avatars/${mod}.png?size=${size}`;
        }
        const idx = parseInt(disc, 10) % 5;
        return `https://cdn.discordapp.com/embed/avatars/${idx}.png?size=${size}`;
      } catch {
        return `https://cdn.discordapp.com/embed/avatars/0.png?size=${size}`;
      }
    }

    const convCache = new Map();
    let convFetchPromise = null;
    async function fetchConversationInfoFromApi(channelId) {
      const token = getAuthTokenForConv();
      if (!token || !channelId) return null;
      const key = `ch:${channelId}`;
      if (convCache.has(key)) return convCache.get(key);
      if (convFetchPromise) return convFetchPromise;

      convFetchPromise = (async () => {
        try {
          const [chResp, selfId] = await Promise.all([
            fetch(`https://discord.com/api/v9/channels/${channelId}`, { headers: { Authorization: token } }),
            fetchSelfUserId(token)
          ]);
          if (!chResp.ok) return null;
          const data = await chResp.json();
          const recips = Array.isArray(data?.recipients) ? data.recipients : [];
          let other = null;
          if (selfId) other = recips.find(r => r?.id && r.id !== selfId) || null;
          if (!other && recips.length) other = recips[0];

          const name = normalizeConvName(other?.global_name || other?.username || data?.name || '');
          let avatar = '';
          if (other?.id) {
            if (other?.avatar) {
              const ext = String(other.avatar).startsWith('a_') ? 'gif' : 'png';
              avatar = `https://cdn.discordapp.com/avatars/${other.id}/${other.avatar}.${ext}?size=32`;
            } else {
              avatar = cdnDefaultAvatarUrl(other.id, other?.discriminator ?? '0', 32);
            }
          }
          const info = { name, avatar };
          convCache.set(key, info);
          return info;
        } catch {
          return null;
        } finally {
          convFetchPromise = null;
        }
      })();

      return convFetchPromise;
    }

    const convStable = { name: '', avatar: '' };
    let badgeTimer = null;
    let lastBadgeRunAt = 0;
    const BADGE_MIN_INTERVAL_MS = 250;
    let lastBadgeWarnNoTokenAt = 0;
    function scheduleConversationBadgeUpdate(delayMs = 0) {
      clearTimeout(badgeTimer);
      badgeTimer = setTimeout(() => {
        const elapsed = Date.now() - lastBadgeRunAt;
        if (elapsed < BADGE_MIN_INTERVAL_MS) {
          return scheduleConversationBadgeUpdate(BADGE_MIN_INTERVAL_MS - elapsed);
        }
        lastBadgeRunAt = Date.now();
        updateConversationBadgeNow();
      }, Math.max(0, delayMs));
    }

    function updateConversationBadgeNow() {
      if (!ui.channelBadge || !ui.channelName || !ui.convBadge || !ui.convName || !ui.convAvatar) return;

      const inputChannelId = $('input#channelId')?.value?.trim() || getChannelId({ silent: true }) || '';
      const runningChannelId = undiscordCore?.state?.running
        ? String(undiscordCore?.options?.channelId || '').trim()
        : '';
      const activeChannelId = runningChannelId || inputChannelId;
      const guildId = $('input#guildId')?.value?.trim() || getGuildId({ silent: true }) || '';
      const isDm = guildId === '@me';
      const deleteAllChannels = !isDm && !!ui.deleteAllChannels?.checked;

      if (!activeChannelId && !guildId) {
        ui.channelBadge.style.display = 'none';
        ui.convBadge.style.display = 'none';
        return;
      }

      if (!isDm) {
        const guildInfo = getGuildInfoFromNavById(guildId) || { name: '', avatar: '' };
        const guildName = normalizeConvName(guildInfo?.name || '');
        const serverName = guildName || `Server ${guildId}`;
        const serverAvatar = guildInfo?.avatar || makeGuildFallbackAvatarDataUrl(serverName || guildId || 'Server');

        ui.convBadge.style.display = '';
        ui.convName.textContent = serverName;
        ui.convAvatar.src = serverAvatar;
        ui.convAvatar.style.display = '';

        if (deleteAllChannels) {
          ui.channelBadge.style.display = 'none';
        } else {
          const channelNameFromSidebar = getChannelNameFromSidebarById(activeChannelId, guildId);
          const channelNameFromDom = getConversationInfoFromDom(activeChannelId, guildId)?.name || '';
          const channelName = channelNameFromSidebar || channelNameFromDom || (activeChannelId ? `Channel ${activeChannelId}` : 'Current channel');
          if (channelName) {
            ui.channelBadge.style.display = '';
            ui.channelName.textContent = channelName;
          } else {
            ui.channelBadge.style.display = 'none';
          }
        }
        return;
      }

      ui.channelBadge.style.display = 'none';
      const dmDom = getConversationInfoFromDom(activeChannelId, guildId);
      const dmName = dmDom?.name || convStable.name || 'DM';
      const dmAvatar = dmDom?.avatar || convStable.avatar || '';

      ui.convBadge.style.display = '';
      ui.convName.textContent = dmName;
      if (dmAvatar) {
        ui.convAvatar.src = dmAvatar;
        ui.convAvatar.style.display = '';
      } else {
        ui.convAvatar.style.display = 'none';
      }
      if (dmName) convStable.name = dmName;
      if (dmAvatar) convStable.avatar = dmAvatar;

      const token = getAuthTokenForConv();
      if (!token) {
        const now = Date.now();
        if (now - lastBadgeWarnNoTokenAt > 15000) {
          lastBadgeWarnNoTokenAt = now;
          log.warn('conv:badge:no-token');
        }
        return;
      }
      fetchConversationInfoFromApi(activeChannelId).then((info) => {
        if (!info) return;
        const nextName = info.name || ui.convName.textContent || 'DM';
        ui.convName.textContent = nextName;
        if (info.avatar) {
          ui.convAvatar.src = info.avatar;
          ui.convAvatar.style.display = '';
        }
        convStable.name = nextName;
        if (info.avatar) convStable.avatar = info.avatar;
      });
    }


    function toggleWindow() {
      const isOpen = ui.undiscordWindow.style.display !== 'none';

      if (isOpen) {
        ui.undiscordWindow.style.display = 'none';
        ui.undiscordBtn.style.color = 'var(--interactive-normal)';
      } else {
        ui.undiscordWindow.style.display = '';
        ui.undiscordBtn.style.color = 'var(--interactive-active)';

        // Auto-fill only on open, and only if not running
        safeAutofillFields();
        scheduleConversationBadgeUpdate();
      }
    }


     // cached elements
     ui.logArea = $('#logArea');
     ui.autoScroll = $('#autoScroll');
     ui.progressMain = $('#progressBar');
     ui.progressIcon = ui.undiscordBtn.querySelector('progress');
     ui.progressBarPercent = $('#progressBarPercent');
     ui.percent = $('#progressPercent');
    ui.verboseMode = $('#verboseMode');
    ui.previewMode = $('#previewMode');
    ui.hideAuthorText = $('#hideAuthorText');
    ui.hideMessageText = $('#hideMessageText');
    ui.redact = $('#redact');
    ui.channelBadge = $('#channelBadge');
    ui.channelName = $('#channelName');
    ui.convBadge = $('#convBadge');
    ui.convName = $('#convName');
    ui.convAvatar = $('#convAvatar');
    ui.deleteAllChannels = $('#deleteAllChannels');
    ui.preScanStatus = $('#preScanStatus');

    function updateDeleteAllToggleVisibility() {
      const guildId = $('input#guildId')?.value?.trim() || getGuildId({ silent: true }) || '';
      const isServer = !!guildId && guildId !== '@me';
      const wrap = ui.deleteAllChannels?.closest('.allChannelsToggle');
      if (!wrap) return;
      wrap.style.display = isServer ? '' : 'none';
      if (!isServer && ui.deleteAllChannels?.checked) {
        ui.deleteAllChannels.checked = false;
      }
    }

    ui.deleteAllChannels?.addEventListener('change', () => {
      scheduleConversationBadgeUpdate();
    });
    updateDeleteAllToggleVisibility();

    function applyVerboseUI() {
      const on = !!ui.verboseMode.checked;
      ui.undiscordWindow.classList.toggle('verbose', on);
      renderLogsForMode(on ? 'verbose' : 'compact');
      if (ui.autoScroll?.checked) {
        // Wait for render + style recalculation, then snap to bottom reliably.
        requestAnimationFrame(() => requestAnimationFrame(() => scrollLogToBottom({ smooth: true })));
      }
    }
    ui.verboseMode.onchange = applyVerboseUI;
    applyVerboseUI();
    scheduleConversationBadgeUpdate();
    setInterval(() => {
      if (ui.undiscordWindow?.style?.display !== 'none' && undiscordCore?.state?.running) {
        scheduleConversationBadgeUpdate();
      }
    }, 500);



     // register event listeners
     $('#hide').onclick = toggleWindow;
     $('#toggleSidebar').onclick = ()=> ui.undiscordWindow.classList.toggle('hide-sidebar');
     $('button#start').onclick = startAction;
     $('button#stop').onclick = stopAction;
     $('button#clear').onclick = () => {
      ui.logArea.innerHTML = '';
      logStore.compact = [];
      logStore.verbose = [];
    };
     $('button#getAuthor').onclick = () => $('input#authorId').value = getAuthorId();
    $('button#getGuild').onclick = () => {
      const guildInput = $('input#guildId');
      const channelInput = $('input#channelId');

      const g = getGuildId(); // already shows alert if not found
      if (g) {
        guildInput.value = g;
        if (g === '@me') {
          const c = getChannelId(); // already shows alert if not found
          if (c) channelInput.value = c;
        }
        updateDeleteAllToggleVisibility();
        scheduleConversationBadgeUpdate();
      }
    };

    $('button#getChannel').onclick = () => {
      const guildInput = $('input#guildId');
      const channelInput = $('input#channelId');

      const c = getChannelId(); // already shows alert if not found
      if (c) channelInput.value = c;

      const g = getGuildId(); // already shows alert if not found
      if (g) guildInput.value = g;
      updateDeleteAllToggleVisibility();
      scheduleConversationBadgeUpdate();
    };

    let savedHideAuthor = false;
    let savedHideMessage = false;
    function applyRedactInputs(on) {
      const ids = ['authorId', 'guildId', 'channelId'];
      for (const id of ids) {
        const input = $(`input#${id}`);
        if (!input) continue;
        if (on) {
          input.dataset.udPrevType = input.dataset.udPrevType || input.type || 'text';
          input.type = 'password';
        } else if (input.dataset.udPrevType) {
          input.type = input.dataset.udPrevType;
        }
      }
    }
    function applyRedactUI() {
      const on = !!ui.redact?.checked;
      ui.undiscordWindow.classList.toggle('redact', on);

      if (on) {
        savedHideAuthor = !!ui.hideAuthorText?.checked;
        savedHideMessage = !!ui.hideMessageText?.checked;
        if (ui.hideAuthorText) {
          ui.hideAuthorText.checked = true;
          ui.hideAuthorText.disabled = true;
        }
        if (ui.hideMessageText) {
          ui.hideMessageText.checked = true;
          ui.hideMessageText.disabled = true;
        }
      } else {
        if (ui.hideAuthorText) {
          ui.hideAuthorText.disabled = false;
          ui.hideAuthorText.checked = savedHideAuthor;
        }
        if (ui.hideMessageText) {
          ui.hideMessageText.disabled = false;
          ui.hideMessageText.checked = savedHideMessage;
        }
      }

      applyRedactInputs(on);
      applyPrivacyUI();

      // Re-render logs so verbose lines get redacted immediately.
      const mode = ui.verboseMode?.checked ? 'verbose' : 'compact';
      renderLogsForMode(mode);
      if (ui.autoScroll?.checked) {
        requestAnimationFrame(() => scrollLogToBottom({ smooth: true }));
      }
    }
     ui.redact.onchange = () => {
       if (!ui.redact.checked) {
        alert('Streamer mode is OFF. Sensitive information may be visible.\nPlease double check before sharing your screen.');
      }
      applyRedactUI();
     };
    function applyPrivacyUI() {
      const hideAuthorText = !!ui.hideAuthorText?.checked;
      const hideMessageText = !!ui.hideMessageText?.checked;
      ui.undiscordWindow.classList.toggle('hide-author', hideAuthorText);
      ui.undiscordWindow.classList.toggle('hide-text', hideMessageText);

      // Chrome does not consistently support -webkit-text-security on inputs;
      // switching the input type is reliable across browsers.
      try {
        const authorInput = $('input#authorId');
        if (authorInput) {
          if (hideAuthorText) {
            authorInput.dataset.udAuthorType = authorInput.dataset.udAuthorType || authorInput.type || 'text';
            authorInput.type = 'password';
          } else {
            authorInput.type = authorInput.dataset.udAuthorType || 'text';
          }
        }
      } catch {}
    }

    ui.hideAuthorText?.addEventListener('change', applyPrivacyUI);
    ui.hideMessageText?.addEventListener('change', applyPrivacyUI);
    applyPrivacyUI();
    applyRedactUI();

     $('#pickMessageAfter').onclick = async () => {
       alert('Select a message on the chat.\nThe message below it will be deleted.');
       toggleWindow();
       const id = await messagePicker.grab('after');
       if (id) $('input#minId').value = id;
       toggleWindow();
     };
     $('#pickMessageBefore').onclick = async () => {
       alert('Select a message on the chat.\nThe message above it will be deleted.');
       toggleWindow();
       const id = await messagePicker.grab('before');
       if (id) $('input#maxId').value = id;
       toggleWindow();
     };
     $('button#getToken').onclick = async () => {
       $('input#token').value = await fillToken();
      scheduleConversationBadgeUpdate();
     };

     // sync delays
     $('input#searchDelay').onchange = (e) => {
       const v = parseInt(e.target.value);
       if (v) undiscordCore.options.searchDelay = v;
     };
     $('input#deleteDelay').onchange = (e) => {
       const v = parseInt(e.target.value);
       if (v) undiscordCore.options.deleteDelay = v;
     };

     $('input#searchDelay').addEventListener('input', (event) => {
       $('div#searchDelayValue').textContent = event.target.value + 'ms';
     });
     $('input#deleteDelay').addEventListener('input', (event) => {
       $('div#deleteDelayValue').textContent = event.target.value + 'ms';
     });

     // import json
     const fileSelection = $('input#importJsonInput');
     fileSelection.onchange = async () => {
       const files = fileSelection.files;

       // No files added
       if (files.length === 0) return log.warn('No file selected.');

       // Get channel id field to set it later
       const channelIdField = $('input#channelId');

       // Force the guild id to be ourself (@me)
       const guildIdField = $('input#guildId');
       guildIdField.value = '@me';

       // Set author id in case its not set already
       $('input#authorId').value = getAuthorId();
       try {
         const file = files[0];
         const text = await file.text();
         const json = JSON.parse(text);
         const channelIds = Object.keys(json);
         channelIdField.value = channelIds.join(',');
         log.info(`Loaded ${channelIds.length} channels.`);
       } catch(err) {
         log.error('Error parsing file!', err);
       }
     };

     // redirect console logs to inside the window after setting up the UI
     setLogFn(printLog);

     setupUndiscordCore();
   }

  function getAvatarURL(author) {
    try {
      const id = author?.id;
      const avatar = author?.avatar;
      const disc = parseInt(author?.discriminator || '0', 10);

      if (id && avatar) {
        // png is OK; you can use .webp too
        return `https://cdn.discordapp.com/avatars/${id}/${avatar}.png?size=32`;
      }
      // fallback Discord default avatar
      return `https://cdn.discordapp.com/embed/avatars/${(disc % 5)}.png`;
    } catch {
      return `https://cdn.discordapp.com/embed/avatars/0.png`;
    }
  }

  function formatArgs(args) {
    return Array.from(args).map(o =>
      typeof o === 'object'
        ? JSON.stringify(o, o instanceof Error && Object.getOwnPropertyNames(o))
        : String(o)
    ).join('\t');
  }

  function getCurrentAuthorId() {
    try {
      const v = $('input#authorId')?.value?.trim();
      if (v) return v;
    } catch {}
    try {
      const v = undiscordCore?.options?.authorId;
      if (typeof v === 'string' && v.trim()) return v.trim();
    } catch {}
    return '';
  }

  function getCurrentGuildId() {
    try {
      const v = $('input#guildId')?.value?.trim();
      if (v) return v;
    } catch {}
    try {
      const v = undiscordCore?.options?.guildId;
      if (typeof v === 'string' && v.trim()) return v.trim();
    } catch {}
    return '';
  }

  function getCurrentChannelId() {
    try {
      const v = $('input#channelId')?.value?.trim();
      if (v) return v;
    } catch {}
    try {
      const v = undiscordCore?.options?.channelId;
      if (typeof v === 'string' && v.trim()) return v.trim();
    } catch {}
    return '';
  }

  function redactSensitiveInText(text) {
    let result = escapeHTML(text || '');
    const ids = [getCurrentAuthorId(), getCurrentGuildId(), getCurrentChannelId()].filter(Boolean);
    for (const id of ids) {
      const safe = escapeHTML(id);
      if (safe) result = result.split(safe).join('[hidden]');
    }
    return result;
  }

  function renderWithAuthorIdSpans(text) {
    const id = getCurrentAuthorId();
    if (!id) return escapeHTML(text || '');
    const raw = String(text || '');
    const parts = raw.split(id);
    if (parts.length === 1) return escapeHTML(raw);
    const redaction = `<span class="authorText authorId">${escapeHTML(id)}</span><span class="authorHidden authorId">[hidden]</span>`;
    return parts.map(p => escapeHTML(p)).join(redaction);
  }

  function scrollLogToBottom({ smooth = false } = {}) {
    if (!ui?.logArea) return;
    const top = ui.logArea.scrollHeight;
    if (smooth && typeof ui.logArea.scrollTo === 'function') {
      ui.logArea.scrollTo({ top, behavior: 'smooth' });
    } else {
      ui.logArea.scrollTop = top;
    }
  }

  function appendCompactLog(entry) {
    const payload = entry.args[0] || {};
    const avatarUrl = getAvatarURL(payload.author);
    const ts = payload.timestamp ? new Date(payload.timestamp) : entry.time;
    const time = ts.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false });
    const date = ts.toLocaleDateString();
    const tag = payload.author ? (payload.author.global_name || payload.author.username || 'Unknown') : 'Unknown';
    const meta = payload.meta || '';
    const showChannel = !!payload.showChannel;
    const channelLabel = String(payload.channelName || payload.channelId || '').trim();
    const channelHtml = showChannel && channelLabel
      ? `<span class="lineChannel">#${escapeHTML(channelLabel)}</span>`
      : '';
    const content = payload.content || '';
    const attachments = Array.isArray(payload.attachments) ? payload.attachments : [];
    const embeds = Array.isArray(payload.embeds) ? payload.embeds : [];

    const mediaCandidates = [];
    const seen = new Set();
    const addCandidate = (urlRaw, contentType = '', filename = 'file') => {
      const url = String(urlRaw || '').trim();
      if (!url) return;
      if (seen.has(url)) return;
      seen.add(url);
      mediaCandidates.push({ url, contentType: String(contentType || '').toLowerCase(), filename: String(filename || 'file') });
    };

    for (const a of attachments) {
      addCandidate(a?.proxy_url || a?.url, a?.content_type, a?.filename || 'file');
    }

    for (const e of embeds) {
      addCandidate(e?.video?.url || e?.image?.url || e?.thumbnail?.url || e?.url, e?.type || '', e?.title || e?.provider?.name || 'embed');
    }

    const urlRegex = /(https?:\/\/[^\s<>"']+)/gi;
    const contentUrls = String(content).match(urlRegex) || [];
    for (const u of contentUrls) {
      addCandidate(u, '', 'link');
    }

    const mediaHtml = mediaCandidates.map((m) => {
      const srcRaw = m.url;
      const src = escapeHTML(srcRaw);
      const ct = m.contentType;
      const name = escapeHTML(m.filename);
      const rawName = String(m.filename || '').toLowerCase();
      const lowerUrl = srcRaw.toLowerCase();

      const isImage = ct.startsWith('image/') || /\.(png|jpe?g|gif|webp|bmp|svg)(\?|$)/.test(lowerUrl);
      const isVideo = ct.startsWith('video/') || ct === 'gifv' || /\.(mp4|webm|mov|m4v|avi|mkv)(\?|$)/.test(lowerUrl);
      const isAudio = ct.startsWith('audio/') || /\.(mp3|wav|ogg|m4a|flac|aac)(\?|$)/.test(lowerUrl);
      const isGifLikeVideo = isVideo && (
        ct === 'gifv' ||
        /\.gifv?(\?|$)/.test(lowerUrl) ||
        rawName.includes('gif') ||
        /(?:^|\/\/)(?:media\.)?tenor\.com\//.test(lowerUrl)
      );

      if (isImage) return `<img src="${src}" alt="${name}">`;
      if (isGifLikeVideo) return `<video autoplay loop muted playsinline preload="metadata" src="${src}"></video>`;
      if (isVideo) return `<video controls preload="metadata" src="${src}"></video>`;
      if (isAudio) return `<audio controls preload="metadata" src="${src}"></audio>`;
      return '';
    }).filter(Boolean).join('');

    const visibleText = content.trim();
    const hasOnlyUrls = visibleText.length > 0 && visibleText.replace(urlRegex, '').trim() === '';
    const hideUrlTextBecauseMediaIsRendered = !!mediaHtml && hasOnlyUrls;
    const textHtml = hideUrlTextBecauseMediaIsRendered
      ? ''
      : (visibleText ? escapeHTML(visibleText) : (mediaHtml ? '' : '[no text]'));
    const attachmentsHtml = mediaHtml ? `<div class="attachments">${mediaHtml}</div>` : '';
    // NOTE: logArea is a <pre>; avoid whitespace/newlines which render as extra gaps.
    ui.logArea.insertAdjacentHTML(
      'beforeend',
      `<div class="log log-del"><div class="stamp"><div class="date"><span class="d">${escapeHTML(date)}</span><span class="t">${escapeHTML(time)}</span></div></div><img class="authorAvatar" src="${avatarUrl}" alt=""><div class="txt"><div class="head"><div class="author"><span class="authorText">${escapeHTML(tag)}</span><span class="authorHidden">[hidden]</span></div>${channelHtml}</div><div class="content"><span class="msgText">${textHtml}</span><span class="msgHidden">[hidden]</span>${attachmentsHtml}</div></div><div class="meta">${escapeHTML(meta)}</div></div>`
    );
  }

  function appendVerboseLog(entry) {
    const time = entry.time.toLocaleTimeString([], { hour12: false });
    const badge = entry.type || 'log';
    const authorId = entry.args[0]?.author?.id || '';
    const authorIdHtml = authorId
      ? ` <span class="authorText authorId">(${escapeHTML(authorId)})</span><span class="authorHidden authorId">(hidden)</span>`
      : '';
    const msgHtml = entry.type === 'del'
      ? `<span class="vmeta">${escapeHTML(entry.args[0]?.meta || 'Deleted')}</span>${authorIdHtml} — <span class="msgText">${escapeHTML(entry.args[0]?.content || '')}</span><span class="msgHidden">[hidden]</span>`
      : (ui.redact?.checked ? redactSensitiveInText(formatArgs(entry.args)) : renderWithAuthorIdSpans(formatArgs(entry.args)));

    // NOTE: logArea is a <pre>; avoid whitespace/newlines which render as extra gaps.
    ui.logArea.insertAdjacentHTML(
      'beforeend',
      `<div class="log log-vrow log-${escapeHTML(entry.type)}"><div class="vtime">${escapeHTML(time)}</div><div class="vbadge">${escapeHTML(badge)}</div><div class="vmsg">${msgHtml}</div></div>`
    );
  }

  function appendCompactTextLog(entry) {
    const time = entry.time.toLocaleTimeString([], { hour12: false });
    const type = String(entry.type || 'info');
    const msg = ui.redact?.checked
      ? redactSensitiveInText(formatArgs(entry.args))
      : renderWithAuthorIdSpans(formatArgs(entry.args));
    ui.logArea.insertAdjacentHTML(
      'beforeend',
      `<div class="log log-${escapeHTML(type)}">[${escapeHTML(time)}] ${msg}</div>`
    );
  }

  function appendCompactEntry(entry) {
    if (entry.type === 'del') appendCompactLog(entry);
    else appendCompactTextLog(entry);
  }

    function renderLogsForMode(mode) {
    ui.logArea.innerHTML = '';
    const entries = logStore[mode] || [];
    for (const entry of entries) {
      if (mode === 'verbose') appendVerboseLog(entry);
      else if (entry.type !== 'debug' && entry.type !== 'verb') appendCompactEntry(entry);
    }
  }

  function printLog(type = '', args) {
    const entry = { type, args: Array.from(args), time: new Date() };
    logStore.verbose.push(entry);
    logStore.compact.push(entry);

    const isVerbose = !!ui.verboseMode?.checked;
    if (isVerbose) {
      appendVerboseLog(entry);
    } else {
      // Keep failures and progress explanations visible in both log modes.
      if (type !== 'debug' && type !== 'verb') {
        appendCompactEntry(entry);
      }
    }

    if (ui.autoScroll.checked) scrollLogToBottom();
    if (type === 'error') console.error(PREFIX, ...Array.from(args));
  }


  function setupUndiscordCore() {
    let progressTicker = null;
    const lockedControls = new Map();

    function renderProgress(state, stats) {
      const end = stats.endTime || new Date();
      const elapsed = msToHMS(Math.max(0, end - stats.startTime));
      const count = undiscordCore.options.previewMode
        ? `Previewed: ${state.previewCount}`
        : `Deleted: ${state.delCount}`;
      const reactions = undiscordCore.options.removeReactions
        ? ` | Reactions ${undiscordCore.options.previewMode ? 'previewed' : 'removed'}: ${undiscordCore.options.previewMode ? state.reactionPreviewCount : state.reactionRemovedCount}`
        : '';
      ui.percent.textContent = `Read: ${state.scannedCount} | ${count}${reactions} | Failed: ${state.failCount + state.reactionFailCount} | Channel: ${state.channelIndex}/${state.channelCount} | Elapsed: ${elapsed}`;
      if (state.running) {
        ui.progressMain.removeAttribute('value');
        ui.progressIcon.removeAttribute('value');
        ui.progressBarPercent.textContent = '...';
        if (state.phase === 'STOPPING') {
          ui.preScanStatus.textContent = 'Stopping; waiting for the current operation to unwind...';
        } else {
          const waiting = Math.max(0, stats.pendingWaitUntilTs - Date.now());
          if (waiting > 0) {
            ui.preScanStatus.textContent = `Waiting ${Math.ceil(waiting / 1000)}s before continuing...`;
          } else if (state.phase !== 'PREPARING') {
            const activity = state.phase === 'DELETING' ? 'Deleting matching messages' :
              state.phase === 'UNREACTING' ? 'Removing your reactions' : 'Reading older history';
            ui.preScanStatus.textContent = `${activity} (${state.channelIndex}/${state.channelCount} channels). Total not yet known.`;
          }
        }
      }
      $('div#searchDelayValue').textContent = undiscordCore.options.searchDelay + 'ms';
      $('div#deleteDelayValue').textContent = undiscordCore.options.deleteDelay + 'ms';
    }

    undiscordCore.onStart = (state, stats) => {
      ui.undiscordWindow.classList.remove('finished');
      $('#doneBanner').hidden = true;
      $('#doneBanner').textContent = '';
      $('#start').disabled = true;
      $('#stop').disabled = false;
      ui.undiscordBtn.classList.add('running');
      ui.progressMain.style.display = 'block';
      ui.progressBarPercent.style.display = 'block';
      ui.percent.style.display = 'block';
      ui.preScanStatus.style.display = 'block';
      ui.preScanStatus.textContent = 'Preparing the selected scope...';
      const editable = new Set(['redact', 'hideAuthorText', 'hideMessageText', 'verboseMode', 'searchDelay', 'deleteDelay']);
      for (const control of ui.undiscordWindow.querySelectorAll('.sidebar input, .sidebar button, #deleteAllChannels, #deleteMessages, #removeReactions')) {
        if (editable.has(control.id)) continue;
        lockedControls.set(control, control.disabled);
        control.disabled = true;
      }
      renderProgress(state, stats);
      progressTicker = setInterval(() => renderProgress(undiscordCore.state, undiscordCore.stats), 500);
    };

    undiscordCore.onProgress = renderProgress;

    undiscordCore.onStop = (state, stats) => {
      clearInterval(progressTicker);
      progressTicker = null;
      for (const [control, disabled] of lockedControls) control.disabled = disabled;
      lockedControls.clear();
      $('#start').disabled = false;
      $('#stop').disabled = true;
      ui.undiscordBtn.classList.remove('running');
      ui.preScanStatus.style.display = 'none';
      renderProgress(state, stats);

      const isPreview = undiscordCore.options.previewMode;
      const counts = `Messages: ${state.delCount} deleted, ${state.previewCount} previewed, ${state.alreadyGoneCount} already gone, ${state.failCount} failed, ${state.nonDeletableCount} not deletable.` +
        (undiscordCore.options.removeReactions
          ? ` Own reactions: ${state.reactionRemovedCount} removed, ${state.reactionPreviewCount} previewed, ${state.reactionGoneCount} already unavailable, ${state.reactionFailCount} failed.`
          : '') +
        ` Read ${state.scannedCount} messages.`;
      let message;
      let tone = 'warning';
      if (state.endReason === 'DONE') {
        if (state.matchedCount === 0 && state.reactionCount === 0) {
          message = `Scan finished: no messages or own reactions matched the selected actions in the accessible history (${state.scannedCount} messages read). If you expected more, check Author ID for deletion, filters, NSFW selection, and history permissions.`;
        } else {
          message = `${isPreview ? 'Preview complete; no messages or reactions changed.' : 'Finished scanning the selected accessible history.'} ${counts}`;
          tone = isPreview ? 'info' : 'success';
        }
      } else if (state.endReason === 'PARTIAL') {
        message = `Incomplete. ${counts} ${state.channelFailures.length} channel failures; ${state.discoveryIssues.length} discovery issues. See the visible warnings below.`;
      } else if (state.endReason === 'STOPPED') {
        message = `Stopped by user; older history may remain. ${counts}`;
      } else {
        message = `Stopped due to an error: ${state.errorMessage || 'See the error log below.'} ${counts}`;
        tone = 'error';
      }

      const banner = $('#doneBanner');
      banner.textContent = message;
      banner.dataset.tone = tone;
      banner.hidden = false;
      ui.undiscordWindow.classList.toggle('finished', tone === 'success');
      ui.progressMain.style.display = state.endReason === 'DONE' ? 'block' : 'none';
      if (state.endReason === 'DONE') {
        ui.progressMain.max = 1;
        ui.progressMain.value = 1;
        ui.progressBarPercent.textContent = 'Done';
      } else {
        ui.progressBarPercent.textContent = state.endReason === 'STOPPED' ? 'Stopped' : state.endReason === 'ERROR' ? 'Error' : 'Partial';
      }
      if (tone === 'success') log.success(message);
      else if (tone === 'error') log.error(message);
      else if (tone === 'info') log.info(message);
      else log.warn(message);
    };
    $('div#searchDelayValue').textContent = $('input#searchDelay').value + 'ms';
    $('div#deleteDelayValue').textContent = $('input#deleteDelay').value + 'ms';
  }

  async function startAction() {
    if (undiscordCore.state.running) return;
    const authorInput = $('input#authorId');
    const guildInput = $('input#guildId');
    const channelInput = $('input#channelId');
    const tokenInput = $('input#token');
    const guildId = guildInput.value.trim() || getGuildId({ silent: true }) || '';
    const channelValue = channelInput.value.trim() || getChannelId({ silent: true }) || '';
    const allChannels = ui.deleteAllChannels.checked && guildId !== '@me';
    const minMessage = $('input#minId').value.trim();
    const maxMessage = $('input#maxId').value.trim();
    undiscordCore.options = {
      ...undiscordCore.options,
      authToken: '',
      authorId: authorInput.value.trim(),
      guildId,
      channelId: '',
      minId: minMessage || $('input#minDate').value,
      maxId: maxMessage || $('input#maxDate').value,
      content: $('input#search').value.trim(),
      hasLink: $('input#hasLink').checked,
      hasFile: $('input#hasFile').checked,
      includeNsfw: $('input#includeNsfw').checked,
      includePinned: $('input#includePinned').checked,
      pattern: $('input#pattern').value,
      previewMode: ui.previewMode.checked,
      deleteMessages: $('#deleteMessages').checked,
      removeReactions: $('#removeReactions').checked,
      searchDelay: Number($('input#searchDelay').value),
      deleteDelay: Number($('input#deleteDelay').value),
    };
    ui.logArea.innerHTML = '';
    logStore.compact = [];
    logStore.verbose = [];
    undiscordCore.begin();
    let reason = 'ERROR';
    try {
      if (!undiscordCore.options.deleteMessages && !undiscordCore.options.removeReactions) {
        throw new Error('Select message deletion, reaction removal, or both.');
      }
      if (guildId !== '@me' && !/^\d{17,21}$/.test(guildId)) {
        throw new Error('Open a server or DM, or enter a valid Server ID (@me for DMs).');
      }
      const channelIds = allChannels ? [] : parseChannelIdsInput(channelValue);
      if (!allChannels && channelIds.length === 0) throw new Error('Select a Channel ID before starting.');
      if ((minMessage && !/^\d{17,21}$/.test(minMessage)) || (maxMessage && !/^\d{17,21}$/.test(maxMessage))) {
        throw new Error('Message interval fields must contain message IDs, not dates or links.');
      }
      const options = undiscordCore.options;
      if (options.minId) options.minId = toSnowflake(options.minId);
      if (options.maxId) options.maxId = toSnowflake(options.maxId);
      if (options.minId && options.maxId && BigInt(options.minId) >= BigInt(options.maxId)) {
        throw new Error('The After boundary must be earlier than the Before boundary.');
      }
      new RegExp(options.pattern, 'i');
      guildInput.value = guildId;
      channelInput.value = channelValue;
      if (options.deleteMessages && !options.authorId) {
        try {
          options.authorId = String(getAuthorId() || '');
        } catch {
          // Resolve the authenticated author below when Discord storage is unavailable.
        }
      }
      options.authToken = tokenInput.value.trim() || await fillToken();
      undiscordCore.checkRunning();
      if (!options.authToken) throw new Error('Authorization token unavailable. Enter it in Advanced settings before retrying.');
      tokenInput.value = options.authToken;
      if (options.deleteMessages && !options.authorId) {
        const self = await undiscordCore.request('/users/@me');
        options.authorId = self.id;
      }
      if (options.deleteMessages && (typeof options.authorId !== 'string' || !/^\d{17,21}$/.test(options.authorId))) {
        throw new Error('A valid Author ID is required; refusing to delete without an author filter.');
      }
      authorInput.value = options.authorId;
      const discovery = await getServerMessageChannels(guildId, undiscordCore, {
        channelIds,
        allChannels,
        onProgress: text => { ui.preScanStatus.textContent = text; },
      });
      undiscordCore.checkRunning();
      undiscordCore.state.discoveryIssues = discovery.issues;
      if (discovery.channels.length === 0) {
        throw new Error('No message-bearing channels were resolved for this selection. Check the discovery warnings, permissions, and NSFW setting; no changes were made.');
      }
      log.info(`Scanning ${discovery.channels.length} channel(s), newest to oldest. Message totals remain unknown until traversal finishes.`);
      if (options.removeReactions) {
        log.info('Reaction removal affects only the signed-in account, including other authors’ matching messages. Reactions on successfully deleted messages disappear with the message and are not counted separately.');
      }
      if (options.previewMode) log.info('Preview mode: no DELETE requests will be sent.');
      reason = await undiscordCore.runBatch(discovery.channels);
    } catch (error) {
      if (error.name === 'AbortError' || undiscordCore.state.endReason === 'STOPPED') {
        reason = 'STOPPED';
      } else {
        reason = 'ERROR';
        undiscordCore.state.errorMessage = error.message || String(error);
        log.error('Cannot complete the selected actions:', undiscordCore.state.errorMessage);
      }
    } finally {
      undiscordCore.finish(reason);
    }
  }

  function stopAction() {
    if (!undiscordCore.state.running) return;
    $('#stop').disabled = true;
    undiscordCore.stop();
  }

   // ---- END Undiscord ----

initUI();

})();
