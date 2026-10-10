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

local CLAIMS = {
  task = { call = "reqActReceiveTaskReward" },
  group = { call = "reqActReceiveGroupTaskReward" },
  bpCycle = { rpc = "RPC_CS_ReceiveBpCycleReward", tail = { noop } },
  rogueWeekly = { call = "getRogueAllWeeklyReward" },
  rogueSeasonWeekly = { call = "getAllRogueSeasonWeeklyReward", tail = { 0 } },
  rogueDaily = { call = "getDailyReward" },
  monthCardStored = { on = "game.monthCard", call = "requestClaimStoredReward" },
  monthCardDaily = { on = "game.monthCard", call = "requestClaimDailyReward" },
  homeBookGrade = { call = "reqReceiveHandbookGradeReward", tail = { noop } },
  homeBookCategory = { call = "reqReceiveCategoryProgressReward", tail = { noop } },
  grabEggsRank = { rpc = "RPC_CS_GetRobEggLevelReward", tail = { 0, 0, 0 } },
  grabEggsBox = { rpc = "RPC_CS_OpenRobEggLevelRewardBox" },
  grabEggsCase = { rpc = "RPC_CS_GetShowCaseReward", tail = { noop } },
  courseLevel = { call = "getCourseLevelReward", tail = { noop } },
  course = { call = "getCourseReward", tail = { noop } },
  playerLevel = { fn = function(me, lvs)
    local CH = require("Core.Common.CallbackHandler")
    me:serverMsg("RPC_CS_GetLevelReward", lvs, CH({ done = noop }, "done"))
  end },
  gachaTimes = { rpc = "RPC_CS_GachaClaimTimesReward", tail = { noop } },
  trainChapter = { call = "getSpecialTrainChapterReward", tail = { noop } },
  trainEntry = { call = "getSpecialTrainEntryReward", tail = { noop } },
  trainBadge = { call = "getSpecialTrainBadgeReward", tail = { noop } },
  trainExchange = { call = "getSpecialTrainBadgeContinuousReward", tail = { noop } },
  petSpecies = { call = "getPetHandbookSpeciesCollectReward", tail = { -1 } },
  petForm = { call = "getPetHandbookCountryCollectReward", tail = { -1 } },
  petLevel = { call = "getPetHandbookCountryLevelReward", tail = { -1 } },
  petTopic = { call = "reqGetPetTopicRewards" },
  bossRush = { rpc = "RPC_CS_BossRushReceiveSeasonReward", tail = { noop } },
  homeCarLevel = { call = "getHomeCarLevelReward", tail = { -1, noop } },
  homeSeasonProgress = { rpc = "RPC_CS_ReceiveHomeSeasonCollectionReward" },
  homeSeasonTask = { call = "reqReceiveHomeSeasonTaskReward", tail = { noop } },
  homeSeasonMutation = { call = "reqReceiveHomeSeasonMutationReward", tail = { noop } },
  questChapter = { call = "getChapterQuestProgressReward", tail = { noop } },
  puppet = { call = "reqActivityCatchScoreReward" },
  photoReward = { call = "reqActivityPhotoRewardGet" },
  photoExtra = { call = "reqActivityPhotoExtraRewardGet" },
  photoStage = { call = "reqActivityPhotoStageRewardGet" },
  petSave = { call = "reqActivityPetSaveWeekSumyReward", tail = { noop } },
  energy = { call = "serverActivityMsg" },
  petArea = { call = "getPetAreaReward" },
  homeCampFinish = { call = "finishDispatch" },
}

local function act()
  local A, C, CA = req("Common.Utils.ActivityUtils"), req("Common.Const.ActivityConst"), req("Utils.ClientActivityUtils")
  if A and C and CA and tab(C.EventType) and tab(C.TaskState) and tab(C.ActivityTaskType) then return A, C, CA end
end

local function task(add, eid, tid, tag, label)
  add(k(tag, "task", tid), label, "task", pack(tid, eid))
end

local function group(add, eid, gid, tag, label)
  add(k(tag, "group", gid), label, "group", pack(gid, eid))
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
      return add(k("bp", "cycle", x.phase), "Battle pass loop rewards", "bpCycle", pack())
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
        add(k("homebook", "cat", e.id, n), "Home handbook category " .. tostring(e.id), "homeBookCategory", pack(e.id))
      end
    end
  end
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
          add(k("grabeggs", "box", i, d.id), "Grab-eggs reward box " .. i, "grabEggsBox", pack(d.rewardId))
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
          add(k("grabeggs", "case", lv), "Grab-eggs collection reward " .. tostring(lv), "grabEggsCase", pack(1001, lv))
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
        add(k("course", "level", grade, level), "Course grade " .. tostring(grade) .. " level " .. level, "courseLevel", pack(grade, level))
      end
    end
    for _, c in iv(m:getGradeCourseList(grade)) do
      if tab(c) and c.id ~= nil then
        local s = m:canGetCourseReward(c.id) and true or false
        seen(c.id, s)
        if s then add(k("course", "course", c.id), "Course " .. tostring(c.id), "course", pack(c.id)) end
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
  add(k("playerlv", list), "Player level rewards " .. list, "playerLevel", pack(lvs))
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
            add(k("gacha", d, i), "Draw-count reward " .. d .. " #" .. i, "gachaTimes", pack(d, i))
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
        add(k("strain", "chapter", id), "Special training chapter " .. tostring(id), "trainChapter", pack(id))
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
            add(k("strain", "entry", c, tt), "Special training rewards " .. c .. "/" .. tostring(tt), "trainEntry", pack(ids, SRC.HANDBOOK))
          end
        end
      end
    end
  end
  if has(m, "getBadgeListTab") and has(m, "redDot_GetBadgeState") then
    for _, b in kv(m:getBadgeListTab(0)) do
      if tab(b) and m:redDot_GetBadgeState(b) then
        add(k("strain", "badge", b.stageId), "Special training badge " .. tostring(b.stageId), "trainBadge", pack(b.isFinal and true or false))
      end
    end
  end
  if pg.me.isGetBadgeMaxReward and has(m, "getExchangeInfo") then
    local x = m:getExchangeInfo()
    if tab(x) and type(x.canExchangeNum) == "number" and x.canExchangeNum > 0 then
      add("strain:exchange", "Special training badge exchange", "trainExchange", pack())
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
    add(k("petres", "species", area), "Pet research species collection", "petSpecies", pack(area))
  end
  if PRU.checkCountryReward(area, TAB.FORM, PRU.REWARD_COLLECT) then
    add(k("petres", "form", area), "Pet research form collection", "petForm", pack(area))
  end
  if PRU.checkCountryReward(area, TAB.SPECIES, PRU.REWARD_LEVEL) then
    add(k("petres", "level", area), "Pet research country level", "petLevel", pack(area))
  end
  local CD, hb = req("Data.pet_research_content_data"), pg.me.petHandbookMap
  if CD and hb and has(PRU, "getPetResearchSpeciesList") and has(PRU, "_checkPetHasTopicReward") and has(PRU, "getPetAllTopicRewardByTemplateId") then
    for _, id in kv(PRU.getPetResearchSpeciesList(area)) do
      local c = CD[id]
      if tab(c) and c.isShow ~= 0 and (not has(PRU, "checkPetHasFormInCountry") or PRU.checkPetHasFormInCountry(id, area)) and PRU._checkPetHasTopicReward(id, hb) then
        local list = PRU.getPetAllTopicRewardByTemplateId(id)
        if len(list) > 0 then
          add(k("petres", "topic", id, len(list)), "Pet topic rewards " .. tostring(id), "petTopic", pack(list))
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
      if ok then add(k("bossrush", cur, need), "Boss rush season reward " .. need, "bossRush", pack(need)) end
    end
  end
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
          add(k("homeseason", "progress", id), "Home season progress reward " .. tostring(id), "homeSeasonProgress", pack(id))
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
            add(k("homeseason", "task", tid, p), "Home season daily task " .. tostring(tid), "homeSeasonTask", pack(tid))
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
          add(k("homeseason", "mutation", s, #ids), "Home season collection rewards", "homeSeasonMutation", pack(ids))
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
              add(k("quest", "chapter", info.configId, r.rewardIndex), "Quest chapter reward " .. tostring(ch) .. " #" .. tostring(r.rewardIndex), "questChapter", pack(info.configId, r.rewardIndex))
            end
          end
        end
      end
    end
  end
end

local function puppetScore(add, seen)
  local A, C = act()
  local me = pg.me
  if not (A and C and has(A, "getLuckyPetCanRewardList") and has(me, "reqActivityCatchScoreReward")) then return "deps" end
  local eid = openEvents(C.EventType.PuppetCatch)[1]
  if not eid then return "closed" end
  local list, done = A.getLuckyPetCanRewardList(me), me.luckyPetDayRewarded
  for i = 1, len(list) do
    local ready = list[i] and not (tab(done) and done[i])
    seen(i, ready)
    if ready then
      local arg = (i > 1 and list[i - 1] == true and tab(done) and done[i - 1] == true) and -1 or i
      add(k("puppet", "score", eid, i), "Puppet catch score reward " .. i, "puppet", pack(eid, arg))
    end
  end
end

local function photoSurvey(add, seen)
  local A, C = act()
  local me = pg.me
  if not (A and C and has(A, "getFormResearchCanRewardList") and has(me, "reqActivityPhotoRewardGet") and has(me, "reqActivityPhotoExtraRewardGet") and has(me, "reqActivityPhotoStageRewardGet")) then return "deps" end
  local eid = openEvents(C.EventType.PuppetPhoto)[1]
  if not eid then return "closed" end
  seen("finish", me.formResearchFinish)
  if me.formResearchFinish == true and me.formResearchRewarded ~= true then
    add(k("photo", "reward", eid), "Photo survey reward", "photoReward", pack(eid))
  end
  if me.formResearchObRewardFin == true and me.formResearchObRewardRew ~= true then
    add(k("photo", "extra", eid), "Photo survey extra reward", "photoExtra", pack(eid))
  end
  local list, done = A.getFormResearchCanRewardList(me), me.formResearchStageRewarded
  for i = 1, len(list) do
    local ready = list[i] and not (tab(done) and done[i])
    seen(i, ready)
    if ready then
      local arg = (i > 1 and list[i - 1] == true and tab(done) and done[i - 1] == true) and -1 or i
      add(k("photo", "stage", eid, i), "Photo survey stage reward " .. i, "photoStage", pack(eid, arg))
    end
  end
end

local function petSaveWeek(add, seen)
  local _, C, CA = act()
  local M = req("Guis.Panels.EventPetSaveManual.EventPetSaveManualModel")
  if not (C and has(CA, "checkPetSaveCurWeek") and has(M, "getWeekArrival") and has(M, "receivedWeekSumyReward") and has(M, "getSubActId") and has(pg.me, "reqActivityPetSaveWeekSumyReward")) then return "deps" end
  local eid = openEvents(C.EventType.PetSave)[1]
  if not eid then return "closed" end
  for week = 1, tonumber(CA.checkPetSaveCurWeek()) or 0 do
    local sub = M.getSubActId(M, week)
    local ready = M.getWeekArrival(M, week) and not M.receivedWeekSumyReward(M, sub)
    seen(week, ready and true or false)
    if ready then
      add(k("petsave", "week", eid, sub), "Pet save weekly summary " .. week, "petSave", pack(eid, sub))
    end
  end
end

local function energyMatch(add, seen)
  local A, C, CA = act()
  local TD = req("Data.energy_match_theme_data")
  local me = pg.me
  if not (A and C and TD and has(A, "getNewEnergyTheme") and has(A, "getEnergyThemeId") and has(CA, "redDotReward_CheckVitalityRewardItem") and has(me, "serverActivityMsg")) then return "deps" end
  local eid = openEvents(C.EventType.EnergyMatch)[1]
  if not eid then return "closed" end
  local theme, id = A.getNewEnergyTheme(me), A.getEnergyThemeId(me)
  local row = tab(TD[theme]) and TD[theme][id]
  for i, r in iv(tab(row) and row.award) do
    local ready = CA.redDotReward_CheckVitalityRewardItem(theme, id, i) and true or false
    seen(i, ready)
    if ready and tab(r) and r.index ~= nil then
      add(k("energy", "award", eid, r.index), "Vitality contest reward " .. tostring(r.index), "energy", pack(eid, "RPC_CS_GetEnergyMatchAward", r.index))
    end
  end
end

local function petArea(add, seen)
  local map = pg.game and pg.game.map
  if not has(map, "getPetAreaRewardsState") then return "deps" end
  local any = false
  for _, e in iv(map:getPetAreaRewardsState()) do
    if tab(e) and e.smallAreaId ~= nil and tab(e.rewardState) then
      for stage = 1, 3 do
        if e.rewardState[stage] then
          any = true
          add(k("petarea", e.smallAreaId, stage), "Pet area reward " .. tostring(e.smallAreaId) .. " stage " .. stage, "petArea", pack(e.smallAreaId, stage))
        end
      end
    end
  end
  seen("any", any)
end

local function homeCampDispatch(add, seen)
  local HLU, UI = req("Common.Utils.HomeLandUtils"), req("Const.UIConst")
  if not (HLU and UI and tab(UI.HOME_CAMP_DISPATCH_STATE) and has(HLU, "getCampCarEntity") and pg.me) then return "deps" end
  local car = pg.me.uid ~= nil and HLU.getCampCarEntity(pg.me.uid)
  if not (tab(car) and has(car, "getPetsDispatchInfo") and has(car, "getCampPetDispatchState") and has(car, "finishDispatch")) then return "nocar" end
  local ready = car:getPetsDispatchInfo() and car:getCampPetDispatchState() == UI.HOME_CAMP_DISPATCH_STATE.Finished and true or false
  seen("camp", ready)
  if ready then
    local did = has(car, "getDispatchId") and car:getDispatchId() or 0
    add(k("homecamp", "dispatch", did), "Home camp pet dispatch finish", "homeCampFinish", pack(), car)
  end
end

local function probe(row)
  return { row.name, function(add, seen)
    local M = row.ui and uiModel(row.ui) or req(row.mod)
    if not has(M, row.fn) then return "deps" end
    local want
    if row.is == "reward" then
      local R = req("Const.RedDotConst")
      want = R and tab(R.RedDotStyle) and R.RedDotStyle.REWARD
    elseif row.is then
      want = req(row.is[1])
      for i = 2, #row.is do want = tab(want) and want[row.is[i]] or nil end
    end
    if row.is and want == nil then return "deps" end
    local v
    if row.ui then v = M[row.fn](M) else v = M[row.fn]() end
    local ready
    if want ~= nil then ready = v == want else ready = v and true or false end
    seen("state", want ~= nil and v or ready)
    if not ready then return end
    local key = row.stamp and k(row.name, pg.me[row.stamp]) or row.name
    add(key, row.label, row.claim, pack(), row.ui and M or nil)
  end, covers = { row.fn } }
end

local SOURCES = {
  { "daily", dailyActive }, { "battlepass", battlePass }, { "bpcycle", bpCycle }, { "season", seasonAchievement }, { "sign", sign },
  { "cross", crossPlatform }, { "firsttopup", firstTopup }, { "journey", journeyTrial }, { "dispatch", petDispatch }, { "growth", growthGift },
  { "littlefire", littleFire }, { "fishing", fishingCapture, covers = { "getFishingCaptureRedDotState" } }, { "leylineup", leylineTreeUp }, { "redbook", redBook },
  probe{ name = "rogue-weekly", mod = "Utils.RogueUtils", fn = "getRedDotWeeklyState", is = "reward", claim = "rogueWeekly", label = "Tower weekly boss reward" },
  probe{ name = "rogue-seasonweekly", mod = "Utils.RogueUtils", fn = "getRedDotSeasonWeeklyRewardState", is = "reward", claim = "rogueSeasonWeekly", label = "Tower season weekly reward" },
  probe{ name = "rogue-daily", mod = "Utils.RogueUtils", fn = "getRedDotDailyState", is = "reward", claim = "rogueDaily", label = "Tower daily harvest" },
  probe{ name = "monthcard", mod = "GameApp.MonthCard.MonthCardUtils", fn = "hasStoredReward", claim = "monthCardStored", label = "Month card stored reward" },
  probe{ name = "homebook", mod = "Utils.HomeBookRedDotUtils", fn = "canReceiveScoreReward", claim = "homeBookGrade", label = "Home handbook grade reward" },
  { "homebookcat", homeBookCategory },
  probe{ name = "grabeggs", mod = "Guis.Utils.GrabEggsRankUtils", fn = "hasClaimableReward", claim = "grabEggsRank", label = "Grab-eggs season rank reward" },
  { "grabeggsmode", grabEggsMode }, { "course", course }, { "playerlv", playerLevel, covers = { "redDot_CheckHasLvReward" } }, { "gacha", lotteryTimes }, { "strain", specialTrain, covers = { "redDot_GetSpecialTrainState", "redDot_GetChapterPageState", "redDot_GetBadgeState" } },
  { "petres", petResearch, covers = { "redDot_GetPetResearchState" } }, { "bossrush", bossRush },
  probe{ name = "homecar", ui = "homeCarLevelUp", fn = "redDot_GetLevelRewardState", is = "reward", claim = "homeCarLevel", label = "Home car level rewards" },
  { "homeseason", homeSeason }, { "quest", questChapter },
  probe{ name = "monthcarddaily", mod = "GameApp.MonthCard.MonthCardUtils", fn = "getDailyRewardState", is = { "GameApp.MonthCard.MonthCardConst", "DAILY_REWARD_STATE", "AVAILABLE" }, stamp = "mcLastReceiveDailyAwardTm", claim = "monthCardDaily", label = "Month card daily reward" },
  { "puppet", puppetScore }, { "photo", photoSurvey }, { "petsave", petSaveWeek }, { "energy", energyMatch },
  { "petarea", petArea }, { "homecamp", homeCampDispatch },
}

local skipped = {}

local missing = {}

local function receiver(spec, player, recv)
  if recv ~= nil then return recv end
  if not spec.on then return player end
  local v = pg
  for part in spec.on:gmatch("[^.]+") do v = tab(v) and v[part] or nil end
  return v
end

local function perform(a)
  local spec, list, n = CLAIMS[a.claim], {}, a.args.n
  for i = 1, n do list[i] = a.args[i] end
  for _, v in ipairs(spec.tail or {}) do
    n = n + 1
    list[n] = v
  end
  if spec.fn then return spec.fn(a.recv, unpack(list, 1, n)) end
  if spec.rpc then return a.recv:serverMsg(spec.rpc, unpack(list, 1, n)) end
  return a.recv[spec.call](a.recv, unpack(list, 1, n))
end

local function nextAction(tried, player)
  local found
  local function add(key, label, claim, args, recv)
    if found or tried[key] then return end
    local spec = CLAIMS[claim]
    local on = spec and receiver(spec, player, recv)
    if not (spec and (spec.fn or has(on, spec.rpc and "serverMsg" or spec.call))) then
      if not missing[claim] then
        missing[claim] = true
        log("skip", claim, "claim target missing")
      end
      return
    end
    found = { key = key, label = label, claim = claim, args = args, recv = on }
  end
  for _, src in ipairs(SOURCES) do
    if found then break end
    local ok, err = pcall(src[2], add, noop)
    if not ok and not skipped[src[1]] then
      skipped[src[1]] = true
      log("skip", src[1], field(err))
    end
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

local function hot(key) return key == "2" or key == "true" or key == "Reward" end

local function diagSource(name, fn)
  local n, ready, states, heated, cold = 0, 0, {}, {}, {}
  local function seen(id, st)
    n = n + 1
    local key = short(st, 16)
    states[key] = (states[key] or 0) + 1
    local list = hot(key) and heated or cold
    if #list < 5 then list[#list + 1] = short(id, 24) .. "=" .. key end
  end
  local function add() ready = ready + 1 end
  local ok, why = pcall(fn, add, seen)
  for _, x in ipairs(cold) do if #heated < 5 then heated[#heated + 1] = x end end
  local parts = { "ready=" .. ready, "seen=" .. n }
  if n > 0 then parts[#parts + 1] = "states=" .. counts(states) end
  if #heated > 0 then parts[#parts + 1] = "sample=" .. table.concat(heated, ",") end
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

local DOT_FN = { "^redDot_Get", "^redDot_Check", "^getRedDot%w*State$" }
local DOT_SKIP = { "Path", "Key", "Numb", "Num", "Save" }

local function dotName(key)
  if type(key) ~= "string" then return false end
  local hit = false
  for _, p in ipairs(DOT_FN) do
    if key:find(p) then hit = true end
  end
  if not hit then return false end
  for _, x in ipairs(DOT_SKIP) do
    if key:find(x, 1, true) then return false end
  end
  return true
end

local function get(t, key)
  if not tab(t) then return nil end
  local ok, v = pcall(function() return t[key] end)
  return ok and v or nil
end

local function dotMethods(owner)
  local out, seen, queue, i = {}, {}, { owner }, 1
  while queue[i] and i <= 12 do
    local t = queue[i]
    i = i + 1
    if tab(t) and not seen[t] then
      seen[t] = true
      for key, v in kv(t) do
        if type(v) == "function" and dotName(key) then out[#out + 1] = key end
      end
      local ok, mt = pcall(getmetatable, t)
      local idx = ok and type(mt) == "table" and rawget(mt, "__index") or nil
      if tab(idx) then queue[#queue + 1] = idx end
      local sup = get(t, "super")
      if tab(sup) then queue[#queue + 1] = sup end
    end
  end
  table.sort(out)
  return out
end

local function dotOwners()
  local owners = {}
  local ok, loaded = pcall(function() return package.loaded end)
  if ok and tab(loaded) then
    for name, m in kv(loaded) do
      if type(name) == "string" and type(m) == "table" then owners[#owners + 1] = { name, m, false } end
    end
  end
  table.sort(owners, function(a, b) return a[1] < b[1] end)
  local ui, models = pg.global and pg.global.ui, {}
  for name, p in kv(ui) do
    local m = get(p, "model")
    if tab(m) then models[#models + 1] = { "ui." .. tostring(name), m, true } end
  end
  table.sort(models, function(a, b) return a[1] < b[1] end)
  for _, o in ipairs(models) do owners[#owners + 1] = o end
  return owners
end

local function discover()
  local R = req("Const.RedDotConst")
  local REWARD = R and tab(R.RedDotStyle) and R.RedDotStyle.REWARD
  if REWARD == nil then return log("discover", "skipped", "no RedDotStyle.REWARD", true) end
  local covered = {}
  for _, src in ipairs(SOURCES) do
    for _, name in ipairs(src.covers or {}) do covered[name] = true end
  end
  local owners = dotOwners()
  local st = { owners = #owners, fns = 0, reward = 0, covered = 0, errors = 0 }
  local done, lines = {}, {}
  for _, o in ipairs(owners) do
    local ok, names = pcall(dotMethods, o[2])
    for _, key in ipairs(ok and names or {}) do
      local fn = get(o[2], key)
      local id = o[3] and (tostring(o[2]) .. key) or fn
      if type(fn) == "function" and not done[id] then
        done[id] = true
        st.fns = st.fns + 1
        local okc, v
        if o[3] then
          okc, v = pcall(fn, o[2])
        else
          okc, v = pcall(fn)
          if not okc then okc, v = pcall(fn, o[2]) end
        end
        if not okc then
          st.errors = st.errors + 1
        elseif v == REWARD then
          st.reward = st.reward + 1
          if covered[key] then st.covered = st.covered + 1 else lines[#lines + 1] = { key, o[1] } end
        end
      end
    end
  end
  for _, l in ipairs(lines) do log("unclaimed", l[1], l[2], true) end
  log("discover", "summary", "owners=" .. st.owners .. " fns=" .. st.fns .. " reward=" .. st.reward .. " covered=" .. st.covered .. " unclaimed=" .. #lines .. " errors=" .. st.errors, true)
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
    local ok, a = pcall(nextAction, tried, player)
    if not ok then return fail("readiness check", a) end
    if not a then
      pcall(discover)
      return stop("nothing left", "Rewards: " .. verb .. cur.count .. ", nothing left")
    end
    tried[a.key], last = true, t
    if mode == "dry" or s == "dry" then
      log("dry", a.label, "not sent")
      toast("Rewards (dry run): " .. a.label)
    else
      local ok2, err = pcall(perform, a)
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
