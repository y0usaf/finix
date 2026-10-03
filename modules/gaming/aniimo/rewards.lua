local orig = ...
local function pack(...) return { n = select("#", ...), ... } end
local env = getfenv and getfenv(1)
if type(env) == "table" and setfenv then pcall(setfenv, orig, env) end
local ret = pack(orig(select(2, ...)))

local START_DELAY, MIN_GAP, JITTER, MAX_CLAIMS = 10, 1.0, 0.6, 80
local state = { off = false, gen = 0, seen = setmetatable({}, { __mode = "k" }) }
local logger

local function log(msg)
  msg = "[rewards] " .. tostring(msg)
  pcall(print, msg)
  if logger == nil then
    logger = false
    pcall(function() logger = require("Core.Log.LoggerManager").getLogger("RewardsMod") or false end)
  end
  if logger then pcall(function() logger:warn(msg) end) end
end

local function setting()
  local v = type(env) == "table" and rawget(env, "ANIIMO_REWARDS") or nil
  if v == nil and type(os) == "table" and os.getenv then
    local ok, e = pcall(os.getenv, "ANIIMO_REWARDS")
    if ok then v = e end
  end
  return v ~= nil and tostring(v) or ""
end

local function req(name)
  local ok, m = pcall(require, name)
  if ok and type(m) == "table" then return m end
end

local function has(t, k) return type(t) == "table" and type(t[k]) == "function" end

local function killed(s) return s == "0" or s == "off" end

local function now()
  local T = req("Core.Common.Time")
  if has(T, "getRealMillisecond") then
    local ok, t = pcall(T.getRealMillisecond)
    if ok and type(t) == "number" then return t / 1000, 0.001 end
  end
  if type(os) == "table" and os.time then
    local ok, t = pcall(os.time)
    if ok and type(t) == "number" then return t, 1 end
  end
end


local function noop() end

local function k(...)
  local t = { ... }
  for i = 1, select("#", ...) do t[i] = tostring(t[i]) end
  return table.concat(t, ":")
end

local function mail(add)
  local chat = pg.game and pg.game.chat
  if has(chat, "checkHasRewardMail") and not chat.mailListRequestPending and chat.mailList and chat:checkHasRewardMail() then
    add("mail:all", function(me) me:setAllMailGiftReceived() end)
  end
end

local function act()
  local A, C, CA = req("Common.Utils.ActivityUtils"), req("Common.Const.ActivityConst"), req("Utils.ClientActivityUtils")
  if A and C and CA and C.EventType and C.TaskState and C.ActivityTaskType then return A, C, CA end
end

local function task(add, eid, tid, tag)
  add(k(tag, "task", eid, tid), function(me) me:reqActReceiveTaskReward(tid, eid) end)
end

local function group(add, eid, gid, tag)
  add(k(tag, "group", eid, gid), function(me) me:reqActReceiveGroupTaskReward(gid, eid) end)
end

local function dailyActive(add)
  local A, C, CA = act()
  local ETD = req("Data.event_task_data")
  if not (A and ETD and has(A, "isOprActivityOpenByType") and has(CA, "getTaskInfoByActType")) then return end
  local ET, AT, CAN = C.EventType, C.ActivityTaskType, C.TaskState.Finihed_CanRecv
  local ok, eid = A.isOprActivityOpenByType(ET.DailyActive)
  if not ok or not eid then return end
  local UI = req("Utils.LuaUIUtils")
  local full = true
  if has(UI, "isDailyActiveScoreFull") then full = UI.isDailyActiveScoreFull() and true or false end
  for _, t in pairs(CA.getTaskInfoByActType(ET.DailyActive) or {}) do
    if type(t) == "table" and t.taskState == CAN then
      if t.taskType == AT.DailyActive_GetScore and not full then
        task(add, eid, t.taskId, "daily")
      elseif t.taskType == AT.DailyActive_ScoreReward then
        local cfg = ETD[t.taskId]
        if cfg and cfg.groupId then group(add, eid, cfg.groupId, "daily") end
      end
    end
  end
end

local function battlePass(add)
  local A, C = act()
  local GED, BPD, RD = req("Data.game_event_data"), req("Data.event_battlepass_data"), req("Utils.CashShopRedDotUtils")
  if not (A and GED and BPD and RD and has(A, "getActivityData") and has(A, "isOprActivityOpen")) then return end
  local ET, CAN = C.EventType, C.TaskState.Finihed_CanRecv
  local bp = A.getActivityData(pg.me, ET.BattlePass)
  local phase = type(bp) == "table" and bp.activityBase and bp.activityBase.activityPhase
  local cfg = phase and BPD[phase]
  if not cfg then return end
  local eid
  for id, e in pairs(GED) do
    if type(e) == "table" and e.eventType == ET.BattlePass and e.phase == phase then eid = id end
  end
  if not eid or not A.isOprActivityOpen(eid) then return end
  if has(RD, "hasClaimableWeeklyTask") and cfg.weekTaskGroupId and RD.hasClaimableWeeklyTask() then
    local g = cfg.weekTaskGroupId[bp.weeklyNum or 0]
    if g then group(add, eid, g, "bp") end
  end
  if has(RD, "hasClaimableSeasonTask") and cfg.seasonTaskGroupId and RD.hasClaimableSeasonTask() then
    group(add, eid, cfg.seasonTaskGroupId, "bp")
  end
  if cfg.awardTaskGroupId and has(A, "getActTaskIdsByGroupId") and has(A, "getActTaskState") then
    for _, tid in ipairs(A.getActTaskIdsByGroupId(cfg.awardTaskGroupId) or {}) do
      if A.getActTaskState(pg.me, tid) == CAN then group(add, eid, cfg.awardTaskGroupId, "bp") break end
    end
  end
end

local mileage = {}

local function seasonAchievement(add)
  local A, C, CA = act()
  local ETD, SAD = req("Data.event_task_data"), req("Data.event_season_achievement_data")
  if not (A and ETD and SAD and has(A, "isOprActivityTabOpenByType") and has(A, "getActTaskCanReceiveByGroupId") and has(CA, "isGameEventTabOpen")) then return end
  local AT, SUB = C.ActivityTaskType, C.ActivityTaskSubType
  local ok, eid = A.isOprActivityTabOpenByType(C.EventType.SeasonAchievements, pg.me)
  if not ok or not eid or not CA.isGameEventTabOpen(eid) then return end
  local function ready(g) return g ~= nil and #(A.getActTaskCanReceiveByGroupId(pg.me, g) or {}) > 0 end
  if mileage[eid] == nil and SUB then
    mileage[eid] = false
    for _, cfg in pairs(ETD) do
      if type(cfg) == "table" and cfg.activityId == eid and cfg.actTaskType == AT.Active_AchievementTask and cfg.actSubTaskType == SUB.AchiTask_SeasonAchieve_Mileage then
        mileage[eid] = cfg.groupId or false
        break
      end
    end
  end
  if mileage[eid] and ready(mileage[eid]) then group(add, eid, mileage[eid], "season") end
  local sa = SAD[eid]
  if type(sa) ~= "table" then return end
  for _, field in ipairs({ "petTaskGroup", "battleTaskGroup", "eggTaskGroup", "homeTaskGroup" }) do
    for _, g in ipairs(type(sa[field]) == "table" and sa[field] or {}) do
      if ready(g) then group(add, eid, g, "season") end
    end
  end
end

local function sign(add)
  local A, C, CA = act()
  local POST = req("Data.game_event_type_post_data")
  if not (A and POST and has(A, "isOprActivityOpen") and has(A, "getActTaskCanReceiveByGroupId") and has(CA, "isGameEventTabOpen") and has(CA, "getSignTaskGroupIds")) then return end
  local ET = C.EventType
  for _, et in ipairs({ ET.SignNewbie, ET.SignVersion, ET.LongTermSign }) do
    for eid in pairs(type(POST[et]) == "table" and POST[et] or {}) do
      if CA.isGameEventTabOpen(eid) and A.isOprActivityOpen(eid) then
        for _, g in ipairs(CA.getSignTaskGroupIds(eid) or {}) do
          for _, tid in ipairs(A.getActTaskCanReceiveByGroupId(pg.me, g) or {}) do
            task(add, eid, tid, "sign")
          end
        end
      end
    end
  end
end

local function rogue(add)
  local RU, RDC = req("Utils.RogueUtils"), req("Const.RedDotConst")
  local REWARD = RDC and RDC.RedDotStyle and RDC.RedDotStyle.REWARD
  if not RU or REWARD == nil then return end
  if has(RU, "getRedDotWeeklyState") and RU.getRedDotWeeklyState() == REWARD then
    add("rogue:weekly", function(me) me:getRogueAllWeeklyReward() end)
  end
  if has(RU, "getRedDotSeasonWeeklyRewardState") and RU.getRedDotSeasonWeeklyRewardState() == REWARD then
    add("rogue:seasonWeekly", function(me) me:getAllRogueSeasonWeeklyReward(0) end)
  end
  if has(RU, "getRedDotDailyState") and RU.getRedDotDailyState() == REWARD then
    add("rogue:daily", function(me) me:getDailyReward() end)
  end
end

local function monthCard(add)
  local mc, MU = pg.game and pg.game.monthCard, req("GameApp.MonthCard.MonthCardUtils")
  if has(mc, "requestClaimStoredReward") and has(MU, "hasStoredReward") and MU.hasStoredReward() then
    add("monthcard:stored", function() mc:requestClaimStoredReward() end)
  end
end

local function homeBook(add)
  local HB = req("Utils.HomeBookRedDotUtils")
  if has(HB, "canReceiveScoreReward") and HB.canReceiveScoreReward() then
    add("homebook:grade", function(me) me:reqReceiveHandbookGradeReward(noop) end)
  end
end

local function grabEggs(add)
  local GE = req("Guis.Utils.GrabEggsRankUtils")
  if has(GE, "hasClaimableReward") and GE.hasClaimableReward() then
    add("grabeggs:rank", function(me) me:serverMsg("RPC_CS_GetRobEggLevelReward", 0, 0, 0) end)
  end
end

local function uiModel(name)
  local ui = pg.global and pg.global.ui
  local p = type(ui) == "table" and ui[name]
  local m = type(p) == "table" and p.model
  return type(m) == "table" and m or nil
end

local function course(add)
  local m, GD = uiModel("questCourseV2"), req("Data.guide_course_grade_data")
  if not (m and GD and has(m, "canGetCourseGradeLevelReward") and has(m, "getGradeCourseList") and has(m, "canGetCourseReward")) then return end
  for grade, levels in pairs(GD) do
    for level = 1, type(levels) == "table" and #levels or 0 do
      if m:canGetCourseGradeLevelReward(grade, level) then
        add(k("course", "level", grade, level), function(me) me:getCourseLevelReward(grade, level, noop) end)
      end
    end
    for _, c in ipairs(m:getGradeCourseList(grade) or {}) do
      if type(c) == "table" and c.id ~= nil and m:canGetCourseReward(c.id) then
        add(k("course", "course", c.id), function(me) me:getCourseReward(c.id, noop) end)
      end
    end
  end
end

local function playerLevel(add)
  local m = uiModel("playerLvReward")
  if not (m and has(m, "redDot_CheckHasLvReward") and has(m, "getPlayerLvDataList") and m.LEVEL_STATE) then return end
  if not m:redDot_CheckHasLvReward() then return end
  local lvs = {}
  for _, d in ipairs(m:getPlayerLvDataList() or {}) do
    if type(d) == "table" and d.lvState == m.LEVEL_STATE.LEVEL_MATCH then lvs[#lvs + 1] = d.lv end
  end
  if #lvs == 0 then return end
  add(k("playerlv", table.concat(lvs, ",")), function(me)
    local CH = require("Core.Common.CallbackHandler")
    me:serverMsg("RPC_CS_GetLevelReward", lvs, CH({ done = noop }, "done"))
  end)
end

local SOURCES = { mail, dailyActive, battlePass, seasonAchievement, sign, rogue, monthCard, homeBook, grabEggs, course, playerLevel }

local function nextAction(tried)
  local found
  local function add(key, fn)
    if not found and not tried[key] then found = { key = key, fn = fn } end
  end
  for _, src in ipairs(SOURCES) do
    if found then break end
    src(add)
  end
  return found
end

local function delay() return MIN_GAP + math.random() * JITTER end

local function run(player)
  state.gen = state.gen + 1
  local gen, tried, count, last = state.gen, {}, 0, nil
  local TM = require("Core.Timer.TimerManager")
  local tick
  local function stop(why) if gen == state.gen then state.gen = state.gen + 1 end log("stopped: " .. why) end
  local function fail(where, err) state.off = true stop("error in " .. where .. ": " .. tostring(err) .. "; disabled for this session") end
  local function again(sec)
    local ok, err = pcall(TM.addTimer, sec, tick)
    if not ok then fail("timer", err) end
  end
  tick = function()
    if gen ~= state.gen or state.off then return end
    local s = setting()
    if killed(s) then return stop("kill switch") end
    if pg.me ~= player or player.destroyed then return stop("player changed") end
    local t, res = now()
    if t and last and t - last < MIN_GAP - 0.05 + res then return again(delay()) end
    if count >= MAX_CLAIMS then return stop("cap of " .. MAX_CLAIMS .. " reached") end
    local ok, a = pcall(nextAction, tried)
    if not ok then return fail("readiness check", a) end
    if not a then return stop("nothing left to claim, " .. count .. " sent") end
    tried[a.key] = true
    count, last = count + 1, t
    if s == "dry" then
      log("dry run, would claim " .. a.key)
    else
      local ok2, err = pcall(a.fn, player)
      if not ok2 then return fail(a.key, err) end
      log("claimed " .. a.key)
    end
    again(delay())
  end
  again(START_DELAY)
end

local function onLogin(player)
  if state.off or state.seen[player] then return end
  state.seen[player] = true
  if killed(setting()) then return log("off by kill switch") end
  run(player)
end

local function install(cls)
  local vt = type(cls) == "table" and has(cls, "getVtbl") and cls.getVtbl()
  local base = type(vt) == "table" and rawget(vt, "onBecomePlayer")
  if type(base) ~= "function" then return log("hook point not found; mod inactive") end
  rawset(vt, "onBecomePlayer", function(self, ...)
    local r = pack(base(self, ...))
    local ok, err = pcall(onLogin, self)
    if not ok then
      state.off = true
      log("error at login hook: " .. tostring(err) .. "; disabled for this session")
    end
    return unpack(r, 1, r.n)
  end)
end

local ok, err = pcall(install, ret[1])
if not ok then log("install failed: " .. tostring(err)) end
return unpack(ret, 1, ret.n)
