local INTERVAL = 0.1
local GRACE = 2
local orig = ...
local function pack(...) return { n = select("#", ...), ... } end
local env = getfenv and getfenv(1)
if type(env) == "table" and setfenv then pcall(setfenv, orig, env) end
local ret = pack(orig(select(2, ...)))
local off, paths, prob, ability, scenes, timers, clock
local context

local function log(event, id, detail)
  pcall(function()
    if not paths then
      paths = { ".finix-aniimo/catch.log" }
      local ok, dp = pcall(function() return CS.UnityEngine.Application.dataPath end)
      if ok and type(dp) == "string" and dp ~= "" then
        table.insert(paths, 1, dp .. "/../.finix-aniimo/catch.log")
      end
    end
    local function field(v) return tostring(v or "-"):gsub("[\t\r\n]", " ") end
    local line = table.concat({ os.date("!%Y-%m-%dT%H:%M:%SZ"), field(event), field(id), field(detail) }, "\t") .. "\n"
    for _, p in ipairs(paths) do
      local f = io.open(p, "a")
      if f then f:write(line); f:close(); break end
    end
  end)
end

local function clear(self)
  if not self then return end
  local timer = self._finixCatchTimer
  self._finixCatchTimer, self._finixCatchLast, self._finixCatchDistance = nil, nil, nil
  self._finixCatchEmptySince, self._finixCatchPending = nil, nil
  if context == self then context = nil end
  if timer then timers.removeTimer(timer) end
end

local function disable(err)
  off = true
  pcall(clear, context)
  log("error", "disabled", err)
end

local function need(owner, name)
  assert(owner and type(owner[name]) == "function", name .. " missing")
end

local function prepare(self)
  local helper = pg.game.controller.lockHelper
  local camera = pg.game.camera.playerCameraMode.catchCamera
  if not self._finixCatchReady then
    need(pg.global.entityMgr, "getAllEntities")
    need(helper, "checkTargetValid")
    need(helper, "tryForceLockTarget")
    need(helper, "canForceLock")
    need(camera, "setTarget")
    need(camera, "checkDistance")
    need(camera, "isActive")
    need(self, "checkBallCanThrow")
    prob = prob or require("Common.Utils.CatchProbContext")
    need(prob, "clientGet")
    ability = ability or require("Data.ability_setting_global_const_data")
    scenes = scenes or require("Data.scene_data")
    timers = timers or require("Core.Timer.TimerManager")
    need(timers, "addRepeatTimer")
    need(timers, "removeTimer")
    clock = clock or require("Core.Common.Time")
    need(clock, "getTickSecond")
    self._finixCatchReady = true
  end
  return helper, camera
end

local function step(self)
  if not self._continuousThrowHeld or self.player ~= pg.me or self.player.currentContext ~= self then return clear(self) end
  local helper, camera = prepare(self)
  if not camera:isActive() or not helper:canForceLock() or not pg.me.enableLockTarget then
    self._finixCatchEmptySince = nil
    return
  end
  if not self:checkBallCanThrow() then return self:stopContinuousThrow("catch_ball_unavailable") end
  local scene = scenes[pg.me.space.sceneId]
  local radius = scene and scene.forceLockDis or ability.forceLockDis
  if pg.me.fogMaskRadius and pg.me.fogMaskRadius > 0 then radius = pg.me.fogMaskRadius end
  assert(type(radius) == "number" and radius > 0, "lock radius missing")
  local from = pg.pawn:getPosition()
  local candidates, pending = {}, 0
  for _, ent in pairs(pg.global.entityMgr:getAllEntities()) do
    if (ent.className == "ClientPuppet" or ent.className == "ClientPuppetGhost")
      and ent.space == pg.me.space and not ent.destroyed and not ent.isDestroyed then
      local distance = Vector3.Distance(from, ent:getPosition())
      if distance <= radius then
        if ent.isTrapped then
          pending = pending + 1
        elseif ent:canBeLocked() and helper:checkTargetValid(ent, radius, nil, false)
          and camera:checkDistance(ent) and prob.clientGet(ent, self.itemId).canCatch then
          candidates[#candidates + 1] = { entity = ent, distance = distance }
        end
      end
    end
  end
  if #candidates == 0 then
    if self._finixCatchPending ~= pending then log("wait", pending, "pending") end
    self._finixCatchPending = pending
    if pending > 0 then
      self._finixCatchEmptySince = nil
    else
      local now = clock.getTickSecond()
      self._finixCatchEmptySince = self._finixCatchEmptySince or now
      if now - self._finixCatchEmptySince >= GRACE then return self:stopContinuousThrow("catch_nothing_left") end
    end
    return
  end
  self._finixCatchEmptySince, self._finixCatchPending = nil, nil
  table.sort(candidates, function(a, b)
    if a.distance == b.distance then return a.entity.actorId < b.entity.actorId end
    return a.distance < b.distance
  end)
  local nextIndex
  for i, candidate in ipairs(candidates) do
    if candidate.entity.actorId == self._finixCatchLast then nextIndex = i % #candidates + 1; break end
  end
  if not nextIndex and self._finixCatchDistance then
    for i, candidate in ipairs(candidates) do
      if candidate.distance > self._finixCatchDistance
        or (candidate.distance == self._finixCatchDistance and candidate.entity.actorId > self._finixCatchLast) then
        nextIndex = i
        break
      end
    end
  end
  local chosen = candidates[nextIndex or 1]
  self._finixCatchLast, self._finixCatchDistance = chosen.entity.actorId, chosen.distance
  helper:tryForceLockTarget(chosen.entity.actorId, 0, radius)
  if helper.forceLockActorId ~= chosen.entity.actorId then return end
  camera:setTarget(chosen.entity)
  log("target", chosen.entity.actorId, string.format("%.2f", chosen.distance))
end

local function safely(fn, self)
  if off then return end
  local ok, err = pcall(fn, self)
  if not ok then disable(err) end
end

local function startLocking(self)
  if not self._continuousThrowHeld or self.player ~= pg.me or self.player.currentContext ~= self then return clear(self) end
  if self._finixCatchTimer then return end
  prepare(self)
  if context ~= self then clear(context) end
  context = self
  self._finixCatchLast, self._finixCatchDistance = nil, nil
  self._finixCatchEmptySince, self._finixCatchPending = nil, nil
  safely(step, self)
  if off or not self._continuousThrowHeld then return end
  self._finixCatchTimer = timers.addRepeatTimer(INTERVAL, function() safely(step, self) end)
  assert(self._finixCatchTimer, "lock timer missing")
end

local function install(cls)
  local start, tick, stop = rawget(cls, "startContinuousThrow"), rawget(cls, "_tryContinuousThrow"), rawget(cls, "stopContinuousThrow")
  assert(type(start) == "function", "startContinuousThrow missing")
  assert(type(tick) == "function", "_tryContinuousThrow missing")
  assert(type(stop) == "function", "stopContinuousThrow missing")
  cls.startContinuousThrow = function(self, ...)
    local held = self._continuousThrowHeld
    local r = pack(start(self, ...))
    if not held then safely(startLocking, self) end
    return unpack(r, 1, r.n)
  end
  cls._tryContinuousThrow = function(self, ...)
    safely(startLocking, self)
    return tick(self, ...)
  end
  cls.stopContinuousThrow = function(self, ...)
    if context == self then log("stop", self._finixCatchLast, select(1, ...)) end
    local ok, err = pcall(clear, self)
    if not ok then disable(err) end
    return stop(self, ...)
  end
  log("hook", "continuous throw", "ready")
end

local ok, err = pcall(install, ret[1])
if not ok then disable(err) end
return unpack(ret, 1, ret.n)
