local orig = ...
local function pack(...) return { n = select("#", ...), ... } end
local env = getfenv and getfenv(1)
if type(env) == "table" and setfenv then pcall(setfenv, orig, env) end
local ret = pack(orig(select(2, ...)))

local MIN_GAP, JITTER, MAX_CLAIMS, STALE = 1.0, 0.6, 300, 15
local MAIL_VIEW = "Guis.Panels.Chat.Component.MailNewComponent"
local LOG_FILE = ".finix-aniimo/rewards.log"
local state = { off = false, gen = 0, hooked = false, run = nil }
local logger, paths

local function stamp()
  local ok, s = pcall(os.date, "!%Y-%m-%dT%H:%M:%SZ")
  if ok and type(s) == "string" then return s end
  return tostring(os.time())
end

local function field(v)
  if v == nil then return "-" end
  return (tostring(v):gsub("[\t\r\n]", " "))
end

local function logPaths()
  local list = {}
  local ok, dp = pcall(function() return CS.UnityEngine.Application.dataPath end)
  if ok and type(dp) == "string" and dp ~= "" then list[1] = dp .. "/../" .. LOG_FILE end
  list[#list + 1] = LOG_FILE
  return list
end

local function append(line)
  paths = paths or logPaths()
  for _, p in ipairs(paths) do
    local f = io.open(p, "a")
    if f then
      f:write(line)
      f:close()
      return true
    end
  end
end

local function log(event, label, result, quiet)
  pcall(function() append(table.concat({ stamp(), field(event), field(label), field(result) }, "\t") .. "\n") end)
  if quiet then return end
  local msg = "[rewards] " .. tostring(event) .. " " .. field(label) .. " " .. field(result)
  pcall(print, msg)
  if logger == nil then
    logger = false
    pcall(function() logger = require("Core.Log.LoggerManager").getLogger("RewardsMod") or false end)
  end
  if logger then pcall(function() logger:warn(msg) end) end
end

local function toast(text)
  pcall(function() pg.global.ui.tips:showTextTip(text, nil, nil, nil, nil, nil, nil, true) end)
end

local function setting()
  local v = type(env) == "table" and rawget(env, "ANIIMO_REWARDS") or nil
  if v == nil and type(os) == "table" and os.getenv then
    local ok, e = pcall(os.getenv, "ANIIMO_REWARDS")
    if ok then v = e end
  end
  return v ~= nil and tostring(v) or ""
end

local function tab(v)
  local t = type(v)
  return t == "table" or t == "userdata"
end

local function req(name)
  local ok, m = pcall(require, name)
  if ok and tab(m) then return m end
end

local function has(t, k)
  if not tab(t) then return false end
  local ok, v = pcall(function() return t[k] end)
  return ok and type(v) == "function"
end

local function iter(f, v)
  if tab(v) then
    local ok, a, b, c = pcall(f, v)
    if ok and type(a) == "function" then return a, b, c end
  end
  return next, {}, nil
end
local function kv(v) return iter(pairs, v) end
local function iv(v) return iter(ipairs, v) end

local function len(v)
  if not tab(v) then return 0 end
  local ok, n = pcall(function() return #v end)
  return ok and type(n) == "number" and n or 0
end

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

local function act()
  local A, C, CA = req("Common.Utils.ActivityUtils"), req("Common.Const.ActivityConst"), req("Utils.ClientActivityUtils")
  if A and C and CA and tab(C.EventType) and tab(C.TaskState) and tab(C.ActivityTaskType) then return A, C, CA end
end

local function task(add, eid, tid, tag, label)
  add(k(tag, "task", tid), label, function(me) me:reqActReceiveTaskReward(tid, eid) end)
end

local function group(add, eid, gid, tag, label)
  add(k(tag, "group", gid), label, function(me) me:reqActReceiveGroupTaskReward(gid, eid) end)
end

local function openEvents(et)
  local A, _, CA = act()
  local POST = req("Data.game_event_type_post_data")
  local list = {}
  if not (A and POST and et ~= nil and has(CA, "isGameEventTabOpen") and has(CA, "isEventOpen") and has(A, "getOprActivityUnlockCond")) then return list end
  for eid in kv(POST[et]) do
    if CA.isGameEventTabOpen(eid) and CA.isEventOpen(eid) and A.getOprActivityUnlockCond(eid) then list[#list + 1] = eid end
  end
  table.sort(list, function(a, b) return tostring(a) < tostring(b) end)
  return list
end

local function taskInfos(add, seen, et, eid, tag, name, list)
  local _, C = act()
  local CAN = C.TaskState.Finihed_CanRecv
  for _, t in iv(list) do
    if tab(t) and t.taskId ~= nil then
      seen(t.taskId, t.taskState)
      if t.taskState == CAN then task(add, eid, t.taskId, tag, name .. " " .. tostring(t.taskId)) end
    end
  end
end

local function dailyActive(add, seen)
  local A, C, CA = act()
  local ETD = req("Data.event_task_data")
  if not (A and ETD and has(A, "isOprActivityOpenByType") and has(CA, "getTaskInfoByActType")) then return "deps" end
  local ET, AT, CAN = C.EventType, C.ActivityTaskType, C.TaskState.Finihed_CanRecv
  local ok, eid = A.isOprActivityOpenByType(ET.DailyActive)
  if not ok or not eid then return "closed" end
  local UI = req("Utils.LuaUIUtils")
  local full = true
  if has(UI, "isDailyActiveScoreFull") then full = UI.isDailyActiveScoreFull() and true or false end
  for _, t in kv(CA.getTaskInfoByActType(ET.DailyActive)) do
    if tab(t) then
      seen(t.taskId, t.taskState)
      if t.taskState == CAN then
        if t.taskType == AT.DailyActive_GetScore and not full then
          task(add, eid, t.taskId, "daily", "Daily activity task " .. tostring(t.taskId))
        elseif t.taskType == AT.DailyActive_ScoreReward then
          local cfg = ETD[t.taskId]
          if tab(cfg) and cfg.groupId then group(add, eid, cfg.groupId, "daily", "Daily activity score chest") end
        end
      end
    end
  end
end

local function groupTasks(seen, g)
  local A = act()
  if g == nil then return end
  for _, tid in iv(A.getActTaskIdsByGroupId(g)) do seen(tid, A.getActTaskState(pg.me, tid)) end
end

local function bpContext()
  local A, C = act()
  local GED, BPD = req("Data.game_event_data"), req("Data.event_battlepass_data")
  if not (A and GED and BPD and has(A, "getActivityData") and has(A, "isOprActivityOpen")) then return nil, "deps" end
  local bp = A.getActivityData(pg.me, C.EventType.BattlePass)
  local phase = tab(bp) and tab(bp.activityBase) and bp.activityBase.activityPhase
  local cfg = phase and BPD[phase]
  if not tab(cfg) then return nil, "nophase" end
  local eid
  for id, e in kv(GED) do
    if tab(e) and e.eventType == C.EventType.BattlePass and e.phase == phase then eid = id end
  end
  if not eid or not A.isOprActivityOpen(eid) then return nil, "closed" end
  return { A = A, C = C, bp = bp, phase = phase, cfg = cfg, eid = eid }
end

local function battlePass(add, seen)
  local x, why = bpContext()
  if not x then return why end
  local A, cfg, eid, bp = x.A, x.cfg, x.eid, x.bp
  local CAN = x.C.TaskState.Finihed_CanRecv
  local RD = req("Utils.CashShopRedDotUtils")
  local wg = tab(cfg.weekTaskGroupId) and cfg.weekTaskGroupId[bp.weeklyNum or 0] or nil
  local sg, ag = cfg.seasonTaskGroupId, cfg.awardTaskGroupId
  if has(A, "getActTaskIdsByGroupId") and has(A, "getActTaskState") then
    for _, g in ipairs({ wg, sg, ag }) do groupTasks(seen, g) end
  end
  if wg and has(RD, "hasClaimableWeeklyTask") and RD.hasClaimableWeeklyTask() then group(add, eid, wg, "bp", "Battle pass weekly tasks") end
  if sg and has(RD, "hasClaimableSeasonTask") and RD.hasClaimableSeasonTask() then group(add, eid, sg, "bp", "Battle pass season tasks") end
  if ag and has(A, "getActTaskIdsByGroupId") and has(A, "getActTaskState") then
    for _, tid in iv(A.getActTaskIdsByGroupId(ag)) do
      if A.getActTaskState(pg.me, tid) == CAN then group(add, eid, ag, "bp", "Battle pass level rewards") break end
    end
  end
end

local function bpCycle(add, seen)
  local x, why = bpContext()
  if not x then return why end
  local SC, bp, C = req("Data.sys_config_data"), x.bp, x.C
  if not (SC and has(bp, "getCycleRewardState")) then return "deps" end
  seen("unlock", bp.unlockCycleReward)
  if bp.unlockCycleReward ~= 1 then return end
  local CAN = C.TaskState.Finihed_CanRecv
  local lo = (tonumber(SC.BATTLE_PASS_LEVEL_UP_MAX) or 0) + 1
  local hi = math.min(tonumber(bp.bpLevel) or 0, tonumber(bp.cycleRewardShowMaxlv) or 0)
  for lv = lo, hi do
    local f, p = bp:getCycleRewardState(lv)
    seen(lv, tostring(f) .. "/" .. tostring(p))
    if f == CAN or p == CAN then
      return add(k("bp", "cycle", x.phase), "Battle pass loop rewards", function(me) me:serverMsg("RPC_CS_ReceiveBpCycleReward", noop) end)
    end
  end
end

local mileage = {}
local SEASON_FIELDS = { { "petTaskGroup", "pets" }, { "battleTaskGroup", "battle" }, { "eggTaskGroup", "eggs" }, { "homeTaskGroup", "home" } }

local function seasonAchievement(add, seen)
  local A, C, CA = act()
  if not (A and has(A, "isOprActivityTabOpenByType") and has(A, "getActTaskCanReceiveByGroupId") and has(A, "getActTaskIdsByGroupId") and has(A, "getActTaskState") and has(CA, "isGameEventTabOpen")) then return "deps" end
  local ok, eid = A.isOprActivityTabOpenByType(C.EventType.SeasonAchievements, pg.me)
  if not ok or not eid or not CA.isGameEventTabOpen(eid) then return "closed" end
  local ETD, SAD = req("Data.event_task_data"), req("Data.event_season_achievement_data")
  local AT, SUB, TS = C.ActivityTaskType, C.ActivityTaskSubType, C.TaskState
  local done = {}
  local function emit(g, label)
    if g ~= nil and not done[g] then
      done[g] = true
      group(add, eid, g, "season", label)
    end
  end
  if ETD and tab(SUB) and mileage[eid] == nil then
    mileage[eid] = false
    for _, cfg in kv(ETD) do
      if tab(cfg) and cfg.activityId == eid and cfg.actTaskType == AT.Active_AchievementTask and cfg.actSubTaskType == SUB.AchiTask_SeasonAchieve_Mileage then
        mileage[eid] = cfg.groupId or false
        break
      end
    end
  end
  local mg = mileage[eid]
  if mg then
    local ready = false
    for _, tid in iv(A.getActTaskIdsByGroupId(mg)) do
      if ETD[tid] ~= nil then
        local s = A.getActTaskState(pg.me, tid) or TS.UnFinished
        seen(tid, s)
        if s == TS.Finihed_CanRecv then ready = true end
      end
    end
    if ready then emit(mg, "Season achievement mileage") end
  end
  local sa = SAD and SAD[eid]
  if not tab(sa) then return mg and nil or "noconfig" end
  for _, f in ipairs(SEASON_FIELDS) do
    for _, g in iv(sa[f[1]]) do
      groupTasks(seen, g)
      if len(A.getActTaskCanReceiveByGroupId(pg.me, g)) > 0 then emit(g, "Season achievement " .. tostring(g) .. " (" .. f[2] .. ")") end
    end
  end
end

local function sign(add, seen)
  local A, C, CA = act()
  local POST = req("Data.game_event_type_post_data")
  if not (A and POST and has(A, "isOprActivityOpen") and has(A, "getActTaskCanReceiveByGroupId") and has(A, "getActTaskIdsByGroupId") and has(A, "getActTaskState") and has(CA, "isGameEventTabOpen") and has(CA, "getSignTaskGroupIds")) then return "deps" end
  local ET, CAN = C.EventType, C.TaskState.Finihed_CanRecv
  for _, et in ipairs({ ET.SignNewbie, ET.SignVersion, ET.LongTermSign }) do
    for eid in kv(POST[et]) do
      if CA.isGameEventTabOpen(eid) and A.isOprActivityOpen(eid) then
        for _, g in iv(CA.getSignTaskGroupIds(eid)) do
          for _, tid in iv(A.getActTaskIdsByGroupId(g)) do
            local s = A.getActTaskState(pg.me, tid)
            seen(tid, s)
            if s == CAN then task(add, eid, tid, "sign", "Sign-in reward " .. tostring(tid)) end
          end
        end
      end
    end
  end
end

local function crossPlatform(add, seen)
  local _, C, CA = act()
  if not (C and has(CA, "getTaskInfoByActType")) then return "deps" end
  local et = C.EventType.CrossPlatform
  local eid = openEvents(et)[1]
  if not eid then return "closed" end
  taskInfos(add, seen, et, eid, "cross", "Cross-platform task", CA.getTaskInfoByActType(et))
end

local function firstTopup(add, seen)
  local _, C, CA = act()
  if not (C and has(CA, "getTaskInfoByTaskType")) then return "deps" end
  local et = C.EventType.FirstTopup
  local eid = openEvents(et)[1]
  if not eid then return "closed" end
  taskInfos(add, seen, et, eid, "firsttopup", "First top-up reward", CA.getTaskInfoByTaskType(et, C.ActivityTaskType.Active_AchievementTask))
end

local function journeyTrial(add, seen)
  local _, C, CA = act()
  local T = tab(CA) and CA.REUNION_TRAINING_TASK_TYPE
  if not (C and tab(T) and has(CA, "getTaskInfoList")) then return "deps" end
  local eid = openEvents(C.EventType.JourneyTrial)[1]
  if not eid then return "closed" end
  local CAN = C.TaskState.Finihed_CanRecv
  local function try(t, tag)
    if tab(t) and t.taskId ~= nil then
      seen(t.taskId, t.taskState)
      if t.taskState == CAN then task(add, eid, t.taskId, "journey", "Journey of Trials " .. tag .. " " .. tostring(t.taskId)) end
    end
  end
  for _, t in iv(CA.getTaskInfoList(T.normal, true)) do try(t, "task") end
  for _, t in iv(CA.getTaskInfoList(T.row, true)) do try(t, "row") end
  local fin = CA.getTaskInfoList(T.final, true)
  if tab(fin) then try(fin[1], "final") end
end

local function petDispatch(add, seen)
  local A, C, CA = act()
  local TT = C and C.ActivityTaskType
  if not (A and has(A, "getActivityData") and has(CA, "getTaskInfoByActType") and TT.PetDispatch_Dispatch and TT.PetDispatch_StageScore) then return "deps" end
  local et = C.EventType.PetDispatch
  local eid = openEvents(et)[1]
  if not eid then return "closed" end
  local data = A.getActivityData(pg.me, et)
  if not tab(data) then return "nodata" end
  local PDU = req("GameApp.PetDispatch.PetDispatchUtils")
  local clues = {}
  if has(PDU, "getCurrentStageClues") then
    for _, c in kv(PDU.getCurrentStageClues(data.eventPhase)) do
      if tab(c) and c.taskId ~= nil then clues[c.taskId] = true end
    end
  end
  local CAN = C.TaskState.Finihed_CanRecv
  for _, t in kv(CA.getTaskInfoByActType(et)) do
    if tab(t) and t.taskId ~= nil then
      seen(t.taskId, t.taskState)
      if t.taskState == CAN then
        if t.taskType == TT.PetDispatch_Dispatch and clues[t.taskId] then
          task(add, eid, t.taskId, "dispatch", "Pet dispatch clue reward " .. tostring(t.taskId))
        elseif t.taskType == TT.PetDispatch_StageScore then
          task(add, eid, t.taskId, "dispatch", "Pet dispatch progress reward " .. tostring(t.taskId))
        end
      end
    end
  end
end

local function growthGift(add, seen)
  local A, C, CA = act()
  local ATD = req("Data.activate_tasks_data")
  if not (A and ATD and has(A, "getActivityData") and has(CA, "getTaskInfoList")) then return "deps" end
  local et = C.EventType.GrowthGift
  local d = A.getActivityData(pg.me, et)
  seen("receivedPetFlag", tab(d) and d.receivedPetFlag or nil)
  if not (tab(d) and d.receivedPetFlag == 1) then return "noegg" end
  for _, eid in ipairs(openEvents(et)) do
    local cfg = ATD[eid]
    local g = tab(cfg) and tab(cfg.foreverTaskGroup) and cfg.foreverTaskGroup[1]
    if g then taskInfos(add, seen, et, eid, "growth", "Growth gift collection reward", CA.getTaskInfoList(g, true)) end
  end
end

local function littleFire(add, seen)
  local _, C, CA = act()
  if not (C and has(CA, "getTaskInfoByTaskType")) then return "deps" end
  local et, TT, CAN = C.EventType.LittleFirePerson, C.ActivityTaskType, C.TaskState.Finihed_CanRecv
  local eid = openEvents(et)[1]
  if not eid then return "closed" end
  for _, name in ipairs({ "LittleFire_PersonReward", "LittleFire_GlobalReward" }) do
    if TT[name] ~= nil then
      for _, t in kv(CA.getTaskInfoByTaskType(et, TT[name])) do
        if tab(t) then
          seen(t.taskId, t.taskState)
          if t.taskState == CAN and t.taskGroupId ~= nil then group(add, eid, t.taskGroupId, "littlefire", "Little Fire progress reward") end
        end
      end
    end
  end
  for _, name in ipairs({ "Active_DailyTask", "Active_WeeklyTask", "Active_AchievementTask" }) do
    if TT[name] ~= nil then taskInfos(add, seen, et, eid, "littlefire", "Little Fire task", CA.getTaskInfoByTaskType(et, TT[name])) end
  end
end

local function fishingCapture(add, seen)
  local _, C, CA = act()
  local ATD = req("Data.activate_tasks_data")
  if not (C and ATD and has(CA, "getFishingCaptureRedDotState")) then return "deps" end
  for _, eid in ipairs(openEvents(C.EventType.FishingCapture)) do
    local cfg = ATD[eid]
    local gid = tab(cfg) and tab(cfg.foreverTaskGroup) and cfg.foreverTaskGroup[1]
    local st = CA.getFishingCaptureRedDotState(eid)
    local n = tab(st) and len(st.rewardTaskIds) or 0
    seen(eid, n)
    if gid and n > 0 then group(add, eid, gid, "fishing", "Fishing capture progress rewards") end
  end
end

local function leylineTreeUp(add, seen)
  local A, C, CA = act()
  local ETD = req("Data.event_task_data")
  if not (A and ETD and has(A, "getActTaskMap") and has(CA, "_isInLeylineTreeUpTime")) then return "deps" end
  local et = C.EventType.LeylineTreeUp
  if not CA._isInLeylineTreeUpTime() then return "closed" end
  local eid = openEvents(et)[1]
  if not eid then return "closed" end
  local CAN = C.TaskState.Finihed_CanRecv
  for tid, t in kv(A.getActTaskMap(pg.me, et)) do
    if ETD[tid] ~= nil and tab(t) then
      seen(tid, t.state)
      if t.state == CAN then task(add, eid, tid, "leylineup", "Leyline tree event task " .. tostring(tid)) end
    end
  end
end

local function redBook(add, seen)
  local A, C = act()
  local ATD, ETD = req("Data.activate_tasks_data"), req("Data.event_task_data")
  if not (A and ATD and ETD and has(A, "getActTaskIdsByGroupId") and has(A, "getActTaskState")) then return "deps" end
  local CAN = C.TaskState.Finihed_CanRecv
  local function sortv(id)
    local c = ETD[id]
    return tab(c) and tonumber(c.sort) or math.huge
  end
  for _, eid in ipairs(openEvents(C.EventType.RedBook or 115)) do
    local cfg = ATD[eid]
    local grp = tab(cfg) and cfg.foreverTaskGroup
    if tab(grp) then
      local ids = {}
      for _, tid in iv(A.getActTaskIdsByGroupId(grp[1])) do ids[#ids + 1] = tid end
      table.sort(ids, function(a, b)
        local sa, sb = sortv(a), sortv(b)
        if sa == sb then return a < b end
        return sa < sb
      end)
      local t2
      for _, tid in iv(A.getActTaskIdsByGroupId(grp[2])) do t2 = tid break end
      local shown, done = { ids[1], ids[2], (t2 ~= nil and ETD[t2] ~= nil) and t2 or nil }, {}
      for i = 1, 3 do
        local tid = shown[i]
        if tid ~= nil and not done[tid] then
          done[tid] = true
          local s = A.getActTaskState(pg.me, tid)
          seen(tid, s)
          if s == CAN then task(add, eid, tid, "redbook", "RedNote event task " .. tostring(tid)) end
        end
      end
    end
  end
end

local function rogue(add, seen)
  local RU, RDC = req("Utils.RogueUtils"), req("Const.RedDotConst")
  local REWARD = RDC and tab(RDC.RedDotStyle) and RDC.RedDotStyle.REWARD
  if not RU or REWARD == nil then return "deps" end
  if has(RU, "getRedDotWeeklyState") then
    local s = RU.getRedDotWeeklyState()
    seen("weekly", s)
    if s == REWARD then add("rogue:weekly", "Tower weekly boss reward", function(me) me:getRogueAllWeeklyReward() end) end
  end
  if has(RU, "getRedDotSeasonWeeklyRewardState") then
    local s = RU.getRedDotSeasonWeeklyRewardState()
    seen("seasonWeekly", s)
    if s == REWARD then add("rogue:seasonWeekly", "Tower season weekly reward", function(me) me:getAllRogueSeasonWeeklyReward(0) end) end
  end
  if has(RU, "getRedDotDailyState") then
    local s = RU.getRedDotDailyState()
    seen("daily", s)
    if s == REWARD then add("rogue:daily", "Tower daily harvest", function(me) me:getDailyReward() end) end
  end
end

local function monthCard(add, seen)
  local mc, MU = pg.game and pg.game.monthCard, req("GameApp.MonthCard.MonthCardUtils")
  if not (has(mc, "requestClaimStoredReward") and has(MU, "hasStoredReward")) then return "deps" end
  local s = MU.hasStoredReward() and true or false
  seen("stored", s)
  if s then add("monthcard:stored", "Month card stored reward", function() mc:requestClaimStoredReward() end) end
end

local function homeBook(add, seen)
  local HB = req("Utils.HomeBookRedDotUtils")
  if not has(HB, "canReceiveScoreReward") then return "deps" end
  local s = HB.canReceiveScoreReward() and true or false
  seen("grade", s)
  if s then add("homebook:grade", "Home handbook grade reward", function(me) me:reqReceiveHandbookGradeReward(noop) end) end
end

local function homeBookCategory(add, seen)
  local HB, HD = req("Utils.HomeBookRedDotUtils"), req("Utils.HomeBookDataUtils")
  local me = pg.me
  if not (has(HB, "canReceiveCategoryReward") and has(HD, "getFirstCategories") and has(me, "reqReceiveCategoryProgressReward")) then return "deps" end
  for _, e in iv(HD.getFirstCategories()) do
    if tab(e) and e.id ~= nil then
      local cond = tab(e.config) and e.config.unlockCondition or nil
      local unlocked = cond == nil or cond == 0 or (tab(me.triggerMap) and me.triggerMap:isCompleteOrMeetCondition(cond) == true)
      local s = HB.canReceiveCategoryReward(e.id, unlocked) and true or false
      seen(e.id, s)
      if s then
        local n = has(me, "getHomeHandbookReceivedCategoryCount") and me:getHomeHandbookReceivedCategoryCount(e.id) or 0
        add(k("homebook", "cat", e.id, n), "Home handbook category " .. tostring(e.id), function(p) p:reqReceiveCategoryProgressReward(e.id, noop) end)
      end
    end
  end
end

local function grabEggs(add, seen)
  local GE = req("Guis.Utils.GrabEggsRankUtils")
  if not has(GE, "hasClaimableReward") then return "deps" end
  local s = GE.hasClaimableReward() and true or false
  seen("rank", s)
  if s then add("grabeggs:rank", "Grab-eggs season rank reward", function(me) me:serverMsg("RPC_CS_GetRobEggLevelReward", 0, 0, 0) end) end
end

local function uiModel(name)
  local ui = pg.global and pg.global.ui
  local p = tab(ui) and ui[name]
  local m = tab(p) and p.model
  return tab(m) and m or nil
end

local function grabEggsMode(add, seen)
  local m = uiModel("grabEggsMode")
  if not m then return "deps" end
  if has(m, "hasReadyRewardBox") and has(m, "buildBoxSlotList") then
    local ready = m:hasReadyRewardBox() and true or false
    seen("boxes", ready)
    if ready then
      for i, d in iv(m:buildBoxSlotList()) do
        if tab(d) and d.isReady and d.rewardId ~= nil then
          add(k("grabeggs", "box", i, d.id), "Grab-eggs reward box " .. i, function(me) me:serverMsg("RPC_CS_OpenRobEggLevelRewardBox", d.rewardId) end)
        end
      end
    end
  end
  local cs = tab(pg.me.showCases) and pg.me.showCases[1001]
  local GD, RW = req("Data.egg_book_group_data"), req("Data.egg_book_reward_data")
  if tab(cs) and GD and RW and has(m, "hasCollectionReward") then
    local ready = m:hasCollectionReward(cs) and true or false
    seen("case1001", ready)
    if ready then
      local g = GD[1001]
      local pts, rec = tonumber(cs.allPoint) or 0, cs.rewardRecord
      for lv, n in kv(tab(g) and RW[g.reward]) do
        if tab(n) and (tonumber(n.nodePoint) or 0) <= pts and not ((tonumber(tab(rec) and rec[lv]) or 0) > 0) then
          add(k("grabeggs", "case", lv), "Grab-eggs collection reward " .. tostring(lv), function(me) me:serverMsg("RPC_CS_GetShowCaseReward", 1001, lv, noop) end)
        end
      end
    end
  end
end

local function course(add, seen)
  local m, GD = uiModel("questCourseV2"), req("Data.guide_course_grade_data")
  if not (m and GD and has(m, "canGetCourseGradeLevelReward") and has(m, "getGradeCourseList") and has(m, "canGetCourseReward")) then return "deps" end
  for grade, levels in kv(GD) do
    for level = 1, len(levels) do
      local s = m:canGetCourseGradeLevelReward(grade, level) and true or false
      seen(k(grade, level), s)
      if s then
        add(k("course", "level", grade, level), "Course grade " .. tostring(grade) .. " level " .. level, function(me) me:getCourseLevelReward(grade, level, noop) end)
      end
    end
    for _, c in iv(m:getGradeCourseList(grade)) do
      if tab(c) and c.id ~= nil then
        local s = m:canGetCourseReward(c.id) and true or false
        seen(c.id, s)
        if s then add(k("course", "course", c.id), "Course " .. tostring(c.id), function(me) me:getCourseReward(c.id, noop) end) end
      end
    end
  end
end

local function playerLevel(add, seen)
  local m = uiModel("playerLvReward")
  if not (m and has(m, "redDot_CheckHasLvReward") and has(m, "getPlayerLvDataList") and tab(m.LEVEL_STATE)) then return "deps" end
  local lvs = {}
  for _, d in iv(m:getPlayerLvDataList()) do
    if tab(d) then
      seen(d.lv, d.lvState)
      if d.lvState == m.LEVEL_STATE.LEVEL_MATCH then lvs[#lvs + 1] = d.lv end
    end
  end
  if #lvs == 0 or not m:redDot_CheckHasLvReward() then return end
  local list = table.concat(lvs, ",")
  add(k("playerlv", list), "Player level rewards " .. list, function(me)
    local CH = require("Core.Common.CallbackHandler")
    me:serverMsg("RPC_CS_GetLevelReward", lvs, CH({ done = noop }, "done"))
  end)
end

local function lotteryTimes(add, seen)
  local LU, GT = req("Utils.LotteryUtils"), req("Data.gacha_times_data")
  if not (has(LU, "hasClaimableTimesReward") and GT) then return "deps" end
  for drawId, list in kv(GT) do
    local d = tonumber(drawId)
    if d and tab(list) then
      local s = LU.hasClaimableTimesReward(d) and true or false
      seen(d, s)
      if s then
        local g = tab(pg.me.gachaMap) and pg.me.gachaMap[d]
        local cnt = tab(g) and tonumber(g.drawCount) or 0
        local got = tab(g) and g.claimedTimesRewardNums
        for i, t in iv(list) do
          local n = tab(t) and tonumber(t.num)
          if n and n <= cnt and not (tab(got) and got[n] == true) then
            add(k("gacha", d, i), "Draw-count reward " .. d .. " #" .. i, function(me) me:serverMsg("RPC_CS_GachaClaimTimesReward", d, i, noop) end)
          end
        end
      end
    end
  end
end

local function specialTrain(add, seen)
  local m, QU, QC, R = uiModel("SpecialTrainNew"), req("GameApp.Quest.QuestUtils"), req("Common.Const.QuestConst"), req("Const.RedDotConst")
  if not (m and QU and QC and R and has(m, "redDot_GetSpecialTrainState") and has(QU, "getCurChapterId")) then return "deps" end
  local style = m:redDot_GetSpecialTrainState()
  seen("hud", style)
  if style ~= R.RedDotStyle.REWARD then return end
  local cur = tonumber(QU.getCurChapterId()) or 0
  if cur > 0 and has(m, "getChapterTb") and has(m, "redDot_GetChapterPageState") then
    for _, ch in iv(m:getChapterTb()) do
      local id = tab(ch) and ch.chapterId
      if id and m:redDot_GetChapterPageState(id) then
        add(k("strain", "chapter", id), "Special training chapter " .. tostring(id), function(me) me:getSpecialTrainChapterReward(id, noop) end)
      end
    end
  end
  local SRC, SUB = QC.SPECIAL_TRAIN_REWARD_SRC_TYPE, QC.QUEST_TRAIN_SUB_TYPE
  if tab(SRC) and tab(SUB) and has(m, "getPageTypeTb") and has(m, "getAllCanGetSpecialTrainRewardList") then
    for _, pt in iv(m:getPageTypeTb()) do
      local tt = tab(pt) and pt.trainType
      if tt then
        for c = cur, tt == SUB.COMPULSORY and 0 or cur, -1 do
          local ids = m:getAllCanGetSpecialTrainRewardList(c, tt)
          if len(ids) > 0 then
            add(k("strain", "entry", c, tt), "Special training rewards " .. c .. "/" .. tostring(tt), function(me) me:getSpecialTrainEntryReward(ids, SRC.HANDBOOK, noop) end)
          end
        end
      end
    end
  end
  if has(m, "getBadgeListTab") and has(m, "redDot_GetBadgeState") then
    for _, b in kv(m:getBadgeListTab(0)) do
      if tab(b) and m:redDot_GetBadgeState(b) then
        add(k("strain", "badge", b.stageId), "Special training badge " .. tostring(b.stageId), function(me) me:getSpecialTrainBadgeReward(b.isFinal and true or false, noop) end)
      end
    end
  end
  if pg.me.isGetBadgeMaxReward and has(m, "getExchangeInfo") then
    local x = m:getExchangeInfo()
    if tab(x) and type(x.canExchangeNum) == "number" and x.canExchangeNum > 0 then
      add("strain:exchange", "Special training badge exchange", function(me) me:getSpecialTrainBadgeContinuousReward(noop) end)
    end
  end
end

local function petResearch(add, seen)
  local m, PRU, R = uiModel("petResearch"), req("Guis.Utils.PetResearchUtils"), req("Const.RedDotConst")
  if not (m and PRU and R and tab(PRU.PET_SHOW_TAB) and has(m, "redDot_GetPetResearchState") and has(PRU, "checkCountryReward")) then return "deps" end
  local style = m:redDot_GetPetResearchState()
  seen("hud", style)
  if style ~= R.RedDotStyle.REWARD then return end
  local area, TAB = m.areaId, PRU.PET_SHOW_TAB
  if not area then return "noarea" end
  if PRU.checkCountryReward(area, TAB.SPECIES, PRU.REWARD_COLLECT) then
    add(k("petres", "species", area), "Pet research species collection", function(me) me:getPetHandbookSpeciesCollectReward(area, -1) end)
  end
  if PRU.checkCountryReward(area, TAB.FORM, PRU.REWARD_COLLECT) then
    add(k("petres", "form", area), "Pet research form collection", function(me) me:getPetHandbookCountryCollectReward(area, -1) end)
  end
  if PRU.checkCountryReward(area, TAB.SPECIES, PRU.REWARD_LEVEL) then
    add(k("petres", "level", area), "Pet research country level", function(me) me:getPetHandbookCountryLevelReward(area, -1) end)
  end
  local CD, hb = req("Data.pet_research_content_data"), pg.me.petHandbookMap
  if CD and hb and has(PRU, "getPetResearchSpeciesList") and has(PRU, "_checkPetHasTopicReward") and has(PRU, "getPetAllTopicRewardByTemplateId") then
    for _, id in kv(PRU.getPetResearchSpeciesList(area)) do
      local c = CD[id]
      if tab(c) and c.isShow ~= 0 and (not has(PRU, "checkPetHasFormInCountry") or PRU.checkPetHasFormInCountry(id, area)) and PRU._checkPetHasTopicReward(id, hb) then
        local list = PRU.getPetAllTopicRewardByTemplateId(id)
        if len(list) > 0 then
          add(k("petres", "topic", id, len(list)), "Pet topic rewards " .. tostring(id), function(me) me:reqGetPetTopicRewards(list) end)
        end
      end
    end
  end
end

local function bossRush(add, seen)
  local BU, SR = req("Utils.BossRushUtils"), req("Data.bossrush_season_reward_data")
  if not (BU and SR and has(BU, "hasUnreceivedSeasonReward") and has(BU, "getCurSeasonStar") and has(BU, "isSeasonRewardReceived")) then return "deps" end
  local any = BU.hasUnreceivedSeasonReward() and true or false
  seen("hud", any)
  if not any then return end
  local cur, star = tonumber(pg.me.curBossRushSeasonId) or 0, tonumber(BU.getCurSeasonStar()) or 0
  for need, cfg in kv(SR) do
    if type(need) == "number" and need <= star and tab(cfg) and not BU.isSeasonRewardReceived(need) then
      local ok = false
      for lo, row in kv(cfg) do
        for hi, v in kv(row) do
          if type(lo) == "number" and type(hi) == "number" and lo <= cur and cur <= hi and tab(v) and (tonumber(v.awardId) or 0) > 0 then ok = true end
        end
      end
      if ok then add(k("bossrush", cur, need), "Boss rush season reward " .. need, function(me) me:serverMsg("RPC_CS_BossRushReceiveSeasonReward", need, noop) end) end
    end
  end
end

local function homeCar(add, seen)
  local m, R = uiModel("homeCarLevelUp"), req("Const.RedDotConst")
  if not (m and R and has(m, "redDot_GetLevelRewardState") and has(m, "getHomeCarLevelReward")) then return "deps" end
  local style = m:redDot_GetLevelRewardState()
  seen("level", style)
  if style == R.RedDotStyle.REWARD then add("homecar:level", "Home car level rewards", function() m:getHomeCarLevelReward(-1, noop) end) end
end

local function inStage(v, stage)
  if type(v) == "number" then return v == stage end
  for _, x in kv(v) do if x == stage then return true end end
  return false
end

local function homeSeason(add, seen)
  local HU, KC, R = req("Utils.HomeSeasonUtils"), req("Common.Const.Const"), req("Const.RedDotConst")
  local _, C = act()
  local me = pg.me
  if not (HU and KC and R and C and tab(KC.HOMELAND_SEASON_MODULE_TYPE) and has(HU, "isSeasonAvailable")) then return "deps" end
  if not HU.isSeasonAvailable(me) then return "closed" end
  local s, REWARD, MT = me.homeSeasonId, R.RedDotStyle.REWARD, KC.HOMELAND_SEASON_MODULE_TYPE
  local CR = req("Data.home_season_collection_reward_data")
  if CR and has(HU, "getProgressRewardRedDotStyle") then
    local style = HU.getProgressRewardRedDotStyle(me)
    seen("progress", style)
    if style == REWARD then
      local st = me.homeSeasonCollectionRewardStateMap
      for id, cfg in kv(CR) do
        if tab(cfg) and cfg.seasonId == s and tab(st) and st[id] == HU.COLLECTION_REWARD_STATE_CAN_RECEIVE then
          add(k("homeseason", "progress", id), "Home season progress reward " .. tostring(id), function(p) p:serverMsg("RPC_CS_ReceiveHomeSeasonCollectionReward", id) end)
        end
      end
    end
  end
  local HSD, HMD, DT, MR = req("Data.home_season_data"), req("Data.home_season_module_data"), req("Data.home_season_daily_task_data"), req("Data.home_season_mutation_collection_reward_data")
  local season = HSD and HSD[s]
  if not (HMD and tab(season) and has(HU, "getHomeSeasonModuleRedDotStyle")) then return end
  for _, mid in iv(season.funcRefIds) do
    local md = HMD[mid]
    if tab(md) and md.seasonId == s then
      local style = HU.getHomeSeasonModuleRedDotStyle(me, s, mid, md.type)
      seen(k("module", mid), style)
      if style == REWARD and md.type == MT.DAILY_QUEST and DT then
        local pend, stm = me.homeSeasonTaskPendingRewardMap, me.homeSeasonTaskStateMap
        for tid, cfg in kv(DT) do
          local p = tonumber(tab(pend) and pend[tid]) or 0
          if tab(cfg) and cfg.seasonId == s and (p > 0 or (inStage(cfg.stageId, me.homeSeasonStageId) and tab(stm) and stm[tid] == C.TaskState.Finihed_CanRecv)) then
            add(k("homeseason", "task", tid, p), "Home season daily task " .. tostring(tid), function(q) q:reqReceiveHomeSeasonTaskReward(tid, noop) end)
          end
        end
      elseif style == REWARD and md.type == MT.ITEM_COLLECT and MR and has(HU, "hasReceivableHomeSeasonMutationReward") and HU.hasReceivableHomeSeasonMutationReward(me, s) then
        local stars = tonumber(tab(me.homeSeasonMutationStarBySeason) and me.homeSeasonMutationStarBySeason[s]) or 0
        local got = me.homeSeasonMutationRewardReceived
        local ids = {}
        for id, cfg in kv(MR) do
          if tab(cfg) and cfg.seasonId == s and (tonumber(cfg.needPoint) or 0) <= stars and not (tab(got) and got[id] == true) then ids[#ids + 1] = id end
        end
        if #ids > 0 then
          add(k("homeseason", "mutation", s, #ids), "Home season collection rewards", function(q) q:reqReceiveHomeSeasonMutationReward(ids, noop) end)
        end
      end
    end
  end
end

local function questChapter(add, seen)
  local m, QC = uiModel("quest"), req("Data.quest_catalog")
  if not (m and QC and has(m, "isChapterProgressRewardCanClaim") and has(m, "getChapterProgressRewardInfo")) then return "deps" end
  local done = {}
  for _, cat in kv(QC) do
    for _, ch in iv(tab(cat) and cat.chapters) do
      if not done[ch] then
        done[ch] = true
        local s = m:isChapterProgressRewardCanClaim(ch) and true or false
        seen(ch, s)
        if s then
          local info = m:getChapterProgressRewardInfo(ch)
          for _, r in iv(tab(info) and info.rewardList) do
            if tab(r) and r.canClaim and info.configId then
              add(k("quest", "chapter", info.configId, r.rewardIndex), "Quest chapter reward " .. tostring(ch) .. " #" .. tostring(r.rewardIndex), function(me) me:getChapterQuestProgressReward(info.configId, r.rewardIndex, noop) end)
            end
          end
        end
      end
    end
  end
end

local SOURCES = {
  { "daily", dailyActive }, { "battlepass", battlePass }, { "bpcycle", bpCycle }, { "season", seasonAchievement }, { "sign", sign },
  { "cross", crossPlatform }, { "firsttopup", firstTopup }, { "journey", journeyTrial }, { "dispatch", petDispatch }, { "growth", growthGift },
  { "littlefire", littleFire }, { "fishing", fishingCapture }, { "leylineup", leylineTreeUp }, { "redbook", redBook },
  { "rogue", rogue }, { "monthcard", monthCard }, { "homebook", homeBook }, { "homebookcat", homeBookCategory }, { "grabeggs", grabEggs },
  { "grabeggsmode", grabEggsMode }, { "course", course }, { "playerlv", playerLevel }, { "gacha", lotteryTimes }, { "strain", specialTrain },
  { "petres", petResearch }, { "bossrush", bossRush }, { "homecar", homeCar }, { "homeseason", homeSeason }, { "quest", questChapter },
}

local function nextAction(tried)
  local found
  local function add(key, label, fn)
    if not found and not tried[key] then found = { key = key, label = label, fn = fn } end
  end
  for _, src in ipairs(SOURCES) do
    if found then break end
    src[2](add, noop)
  end
  return found
end

local function short(v, n)
  local s = field(v)
  if #s > n then s = s:sub(1, n) .. "~" end
  return s
end

local function counts(map)
  local keys = {}
  for key in pairs(map) do keys[#keys + 1] = key end
  table.sort(keys)
  for i, key in ipairs(keys) do keys[i] = key .. ":" .. map[key] end
  return table.concat(keys, ",")
end

local HOT = { ["2"] = true, ["true"] = true, Reward = true }

local function diagSource(name, fn)
  local n, ready, states, hot, cold = 0, 0, {}, {}, {}
  local function seen(id, st)
    n = n + 1
    local key = short(st, 16)
    states[key] = (states[key] or 0) + 1
    local list = HOT[key] and hot or cold
    if #list < 5 then list[#list + 1] = short(id, 24) .. "=" .. key end
  end
  local function add() ready = ready + 1 end
  local ok, why = pcall(fn, add, seen)
  for _, x in ipairs(cold) do if #hot < 5 then hot[#hot + 1] = x end end
  local parts = { "ready=" .. ready, "seen=" .. n }
  if n > 0 then parts[#parts + 1] = "states=" .. counts(states) end
  if #hot > 0 then parts[#parts + 1] = "sample=" .. table.concat(hot, ",") end
  if not ok then parts[#parts + 1] = "err=" .. short(why, 160) elseif why then parts[#parts + 1] = "exit=" .. tostring(why) end
  log("diag", name, table.concat(parts, " "), true)
end

local DATA = { "event_task_data", "game_event_data", "game_event_type_post_data", "event_season_achievement_data", "event_battlepass_data", "activate_tasks_data", "guide_course_grade_data", "quest_catalog" }

local function diagModules()
  local parts = {}
  for _, name in ipairs(DATA) do
    local ok, m = pcall(require, "Data." .. name)
    local row = "-"
    if ok and tab(m) then pcall(function() for _, v in pairs(m) do row = type(v) break end end) end
    parts[#parts + 1] = name .. "=" .. (ok and type(m) or "err") .. "/" .. row
  end
  log("diag", "data", table.concat(parts, " "), true)
end

local function flag(f, ...)
  if type(f) ~= "function" then return "?" end
  local ok, v = pcall(f, ...)
  if not ok then return "E" end
  return v and "1" or "0"
end

local function diagActivity()
  local A, C, CA = act()
  if not (A and C) then return log("diag", "act", "deps", true) end
  local POST = req("Data.game_event_type_post_data")
  local names = C.NewFrameEventAttriName
  local ets = {}
  for et in kv(names) do ets[#ets + 1] = et end
  table.sort(ets)
  for _, et in ipairs(ets) do
    local ok, err = pcall(function()
      local attr = names[et]
      local parts = { "attr=" .. tostring(attr), "raw=" .. (pg.me[attr] ~= nil and "1" or "0") }
      local d = has(A, "getActivityData") and A.getActivityData(pg.me, et) or nil
      local base = tab(d) and d.activityBase
      parts[#parts + 1] = "aid=" .. field(tab(base) and base.activityId or nil)
      local st, n = {}, 0
      for _, t in kv(tab(base) and base.activityTasks) do
        n = n + 1
        local key = short(tab(t) and t.state or nil, 8)
        st[key] = (st[key] or 0) + 1
      end
      parts[#parts + 1] = "tasks=" .. n
      if n > 0 then parts[#parts + 1] = "states=" .. counts(st) end
      local eids, m = {}, 0
      for eid in kv(POST and POST[et]) do
        m = m + 1
        if m <= 4 then
          eids[#eids + 1] = tostring(eid) .. ":T" .. flag(A.isOprActivityTabOpen, eid, pg.me) .. "G" .. flag(CA.isGameEventTabOpen, eid) .. "O" .. flag(A.isOprActivityOpen, eid) .. "E" .. flag(CA.isEventOpen, eid)
        end
      end
      parts[#parts + 1] = "eids=" .. m .. (#eids > 0 and ("[" .. table.concat(eids, ",") .. "]") or "")
      log("diag", "act " .. tostring(et), table.concat(parts, " "), true)
    end)
    if not ok then log("diag", "act " .. tostring(et), "err=" .. short(err, 160), true) end
  end
end

local function diag()
  log("diag", "begin", #SOURCES .. " sources", true)
  pcall(diagModules)
  for _, src in ipairs(SOURCES) do pcall(diagSource, src[1], src[2]) end
  local ok, err = pcall(diagActivity)
  if not ok then log("diag", "act", "err=" .. short(err, 160), true) end
  log("diag", "end", "-", true)
end

local function delay() return MIN_GAP + math.random() * JITTER end

local function run(player, mode)
  state.gen = state.gen + 1
  local gen, tried, last = state.gen, {}, nil
  local cur = { count = 0, beat = now() }
  state.run = cur
  local verb = mode == "dry" and "would claim " or "claimed "
  local TM = require("Core.Timer.TimerManager")
  local tick
  local function stop(why, text)
    if gen == state.gen then state.gen = state.gen + 1 end
    if state.run == cur then state.run = nil end
    log("stop", why, cur.count)
    toast(text or ("Rewards stopped (" .. why .. "), " .. verb .. cur.count))
  end
  local function fail(where, err)
    state.off = true
    log("error", where, tostring(err))
    stop("error", "Rewards error at " .. where .. ", off until restart")
  end
  local function again(sec)
    local ok, err = pcall(TM.addTimer, sec, tick)
    if not ok then fail("timer", err) end
  end
  tick = function()
    if gen ~= state.gen or state.off then return end
    cur.beat = now() or cur.beat
    local s = setting()
    if killed(s) then return stop("kill switch") end
    if pg.me ~= player or player.destroyed then return stop("player changed") end
    local t, res = now()
    if t and last and t - last < MIN_GAP - 0.05 + res then return again(delay()) end
    if cur.count >= MAX_CLAIMS then return stop("cap of " .. MAX_CLAIMS .. " reached") end
    local ok, a = pcall(nextAction, tried)
    if not ok then return fail("readiness check", a) end
    if not a then return stop("nothing left", "Rewards: " .. verb .. cur.count .. ", nothing left") end
    tried[a.key], last = true, t
    if mode == "dry" or s == "dry" then
      log("dry", a.label, "not sent")
      toast("Rewards (dry run): " .. a.label)
    else
      local ok2, err = pcall(a.fn, player)
      if not ok2 then return fail(a.label, err) end
      log("claim", a.label, "ok")
      toast("Rewards: " .. a.label)
    end
    cur.count = cur.count + 1
    again(delay())
  end
  log("start", mode == "dry" and "dry run" or "claim run", "ok")
  pcall(diag)
  toast(mode == "dry" and "Rewards: dry run, nothing will be sent" or "Rewards: claiming, one every 1-2 s")
  again(delay())
end

local function onPress()
  if state.off then
    log("press", "ignored", "disabled after error")
    return toast("Rewards: off after an error, restart the game")
  end
  local cur, t = state.run, now()
  if cur and t and cur.beat and t - cur.beat > STALE then
    log("press", "stale run dropped", cur.count)
    state.run, state.gen = nil, state.gen + 1
    cur = nil
  end
  if cur then
    log("press", "ignored", "running, " .. cur.count .. " so far")
    return toast("Rewards: already running, " .. cur.count .. " so far")
  end
  local s = setting()
  if killed(s) then
    log("press", "ignored", "kill switch")
    return toast("Rewards: off (ANIIMO_REWARDS=" .. s .. ")")
  end
  local me = pg.me
  if type(me) ~= "table" then return log("press", "ignored", "no player") end
  run(me, s == "dry" and "dry" or "claim")
end

local function wrapButton(view)
  local btn = view.btnAllReadUButton
  local click = btn and btn.luaClick
  if not click then return log("hook", "mail button", "no click handler") end
  btn.luaClick = function(...)
    local r = pack(click(...))
    local ok, err = pcall(onPress)
    if not ok then
      state.off = true
      log("error", "button press", tostring(err))
    end
    return unpack(r, 1, r.n)
  end
end

local function hookMail()
  if state.hooked then return end
  local M = req(MAIL_VIEW)
  local base = M and rawget(M, "initView")
  if type(base) ~= "function" then return log("hook", "mail panel", "initView not found") end
  state.hooked = true
  rawset(M, "initView", function(self, ...)
    local r = pack(base(self, ...))
    local ok, err = pcall(wrapButton, self)
    if not ok then log("hook", "mail button", tostring(err)) end
    return unpack(r, 1, r.n)
  end)
  log("hook", "mail panel", "ok")
end

local function install(cls)
  local vt = type(cls) == "table" and has(cls, "getVtbl") and cls.getVtbl()
  local base = type(vt) == "table" and rawget(vt, "onBecomePlayer")
  if type(base) ~= "function" then return log("hook", "onBecomePlayer", "not found") end
  rawset(vt, "onBecomePlayer", function(self, ...)
    local r = pack(base(self, ...))
    local ok, err = pcall(hookMail)
    if not ok then log("hook", "mail panel", tostring(err)) end
    return unpack(r, 1, r.n)
  end)
end

local ok, err = pcall(install, ret[1])
if not ok then log("hook", "install", tostring(err)) end
return unpack(ret, 1, ret.n)
