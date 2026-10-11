local orig = ...
local function pack(...) return { n = select("#", ...), ... } end
local env = getfenv and getfenv(1)
if type(env) == "table" and setfenv then pcall(setfenv, orig, env) end
local ret = pack(orig(select(2, ...)))
local off, paths, prob, ability, scenes
local target

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
  pcall(print, "[catch] " .. tostring(event) .. " " .. tostring(id) .. " " .. tostring(detail))
end

local function disable(err)
  off, target = true, nil
  log("error", "disabled", err)
end

local function need(owner, name)
  assert(owner and type(owner[name]) == "function", name .. " missing")
end

local function prepare(self)
  local helper = pg.game.controller.lockHelper
  local camera = pg.game.camera.playerCameraMode.catchCamera
  if not self._finixCatchReady then
    need(helper, "getLockableTargetList")
    need(helper, "checkTargetValid")
    need(helper, "isTargetNoBlock")
    need(helper, "getLockPos")
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
    self._finixCatchReady = true
  end
  return helper, camera
end

local function observe(self)
  if not self._continuousThrowHeld or self.player ~= pg.me or self.player.currentContext ~= self then
    target = nil
    return
  end
  local helper, camera = prepare(self)
  if not camera:isActive() then target = nil; return end
  local id = helper.forceLockActorId
  local locked = id and id ~= 0 and pg.getEntityByActorId(id)
  target = nil
  if locked and not locked.isDestroyed and not locked.isTrapped and prob.clientGet(locked, self.itemId).canCatch then
    target = locked
    log("armed", locked.actorId, Vector3.Distance(pg.pawn:getPosition(), locked:getPosition()))
  end
end

local function step(self)
  if not self._continuousThrowHeld or self.player ~= pg.me or self.player.currentContext ~= self then
    target = nil
    return
  end
  local previous = target
  if not previous then return observe(self) end
  local helper, camera = prepare(self)
  if not camera:isActive() then target = nil; return end
  local id = helper.forceLockActorId
  if id and id ~= 0 and id ~= previous.actorId and pg.getEntityByActorId(id) then return observe(self) end
  local old = pg.getEntityByActorId(previous.actorId)
  if old and old.space and not old.isDestroyed then
    if old.isTrapped then return end
    if helper.forceLockActorId == 0 then
      target = nil
      log("stop", previous.actorId, "unlocked")
      return
    end
    if helper.forceLockActorId ~= previous.actorId then return observe(self) end
    return
  end
  log("target lost", previous.actorId, "gone")
  target = nil
  if not helper:canForceLock() or not pg.me.enableLockTarget then
    self:stopContinuousThrow("catch_lock_unavailable")
    return log("stop", previous.actorId, "lock unavailable")
  end
  if not self:checkBallCanThrow() then
    self:stopContinuousThrow("catch_ball_unavailable")
    return log("stop", previous.actorId, "ball unavailable")
  end
  local radius = scenes[pg.me.space.sceneId].forceLockDis or ability.forceLockDis
  if pg.me.fogMaskRadius and pg.me.fogMaskRadius > 0 then radius = pg.me.fogMaskRadius end
  assert(type(radius) == "number" and radius > 0, "lock radius missing")
  local count = helper:getLockableTargetList(pg.pawn, radius, false)
  local from = pg.pawn:getPosition()
  local lockPos = helper:getLockPos(pg.me.actorId, 0)
  local best, distance
  for i = 1, count do
    local ent = pg.getEntityByActorId(helper.actorList[i])
    if ent and ent.actorId ~= previous.actorId and helper:checkTargetValid(ent, radius, nil, false)
      and ent:canBeLocked() and camera:checkDistance(ent)
      and helper:isTargetNoBlock(lockPos, ent) and prob.clientGet(ent, self.itemId).canCatch then
      local d = Vector3.Distance(from, ent:getPosition())
      if d <= radius and (not distance or d < distance) then best, distance = ent, d end
    end
  end
  if not best then
    self:stopContinuousThrow("catch_nothing_left")
    return log("nothing left", previous.actorId, radius)
  end
  helper:tryForceLockTarget(best.actorId, 0, radius)
  if helper.forceLockActorId ~= best.actorId then
    self:stopContinuousThrow("catch_lock_rejected")
    return log("stop", best.actorId, "lock rejected")
  end
  camera:setTarget(best)
  target = best
  log("new target", best.actorId, string.format("%.2f", distance))
end

local function safely(fn, self)
  if off then return end
  local ok, err = pcall(fn, self)
  if not ok then disable(err) end
end

local function install(cls)
  local start, tick, stop = rawget(cls, "startContinuousThrow"), rawget(cls, "_tryContinuousThrow"), rawget(cls, "stopContinuousThrow")
  assert(type(start) == "function", "startContinuousThrow missing")
  assert(type(tick) == "function", "_tryContinuousThrow missing")
  assert(type(stop) == "function", "stopContinuousThrow missing")
  cls.startContinuousThrow = function(self, ...)
    local held = self._continuousThrowHeld
    local r = pack(start(self, ...))
    if not held then target = nil; safely(observe, self) end
    return unpack(r, 1, r.n)
  end
  cls._tryContinuousThrow = function(self, ...)
    safely(step, self)
    return tick(self, ...)
  end
  cls.stopContinuousThrow = function(self, ...)
    if target then log("stop", target.actorId, select(1, ...)) end
    target = nil
    return stop(self, ...)
  end
  log("hook", "continuous throw", "ready")
end

local ok, err = pcall(install, ret[1])
if not ok then disable(err) end
return unpack(ret, 1, ret.n)
