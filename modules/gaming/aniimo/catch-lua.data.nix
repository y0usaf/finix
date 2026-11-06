{
  CS,
  Vector3,
  assert',
  assign,
  blank,
  break,
  dot,
  field,
  fn,
  forIn,
  getfenv,
  if',
  ifElse,
  index,
  inline,
  io,
  ipairs,
  len,
  local,
  localFunction,
  method,
  nil,
  not,
  os,
  pairs,
  pcall,
  pg,
  rawget,
  require,
  return,
  rows,
  select,
  semicolon,
  setfenv,
  str,
  string,
  table,
  table',
  tostring,
  type,
  unpack,
  vararg,
  ...
}: ({
  INTERVAL,
  GRACE,
  orig,
  pack,
  env,
  ret,
  off,
  paths,
  prob,
  ability,
  scenes,
  timers,
  clock,
  context,
  log,
  clear,
  disable,
  need,
  prepare,
  step,
  safely,
  startLocking,
  install,
  ok,
  err,
}: [
  (local INTERVAL [0.1])
  (local GRACE [2])
  (local orig [vararg])
  (localFunction pack {
    params = [vararg];
    body = inline [(return [(table [(field "n" [select (str "#") vararg]) vararg])])];
  })
  (local env [[getfenv "and" [getfenv 1]]])
  (if' [[type env] "==" (str "table") "and" setfenv] (inline [[pcall setfenv orig env]]))
  (local ret [[pack [orig [select 2 vararg]]]])
  (local [off paths prob ability scenes timers clock] [])
  (local context [])
  blank
  (localFunction log ({
    event,
    id,
    detail,
  }: {
    params = [event id detail];
    body = [
      [
        pcall
        (fn ({
          field',
          line,
        }: [
          (if' (not paths) ({
            ok,
            dp,
          }: [
            (assign paths [(table [(str ".finix-aniimo/catch.log")])])
            (local [ok dp] [[pcall (fn (inline [(return [(dot CS "UnityEngine.Application.dataPath")])]))]])
            (if' [ok "and" [type dp] "==" (str "string") "and" dp "~=" (str "")] [
              [(dot table' "insert") paths 1 [dp ".." (str "/../.finix-aniimo/catch.log")]]
            ])
          ]))
          (localFunction field' ({v}: {
            params = [v];
            body = inline [(return [[(method [tostring [v "or" (str "-")]] "gsub") (str "[\\t\\r\\n]") (str " ")]])];
          }))
          (local line [[[(dot table' "concat") (table [[(dot os "date") (str "!%Y-%m-%dT%H:%M:%SZ")] [field' event] [field' id] [field' detail]]) (str "\\t")] ".." (str "\\n")]])
          (forIn ({
            _,
            p,
            f,
          }: {
            names = [_ p];
            values = [[ipairs paths]];
            body = [
              (local f [[(dot io "open") p (str "a")]])
              (if' f (inline [[(method f "write") line] semicolon [(method f "close")] semicolon break]))
            ];
          }))
        ]))
      ]
    ];
  }))
  blank
  (localFunction clear ({
    self,
    timer,
  }: {
    params = [self];
    body = [
      (if' (not self) (inline [(return [])]))
      (local timer [(dot self "_finixCatchTimer")])
      (assign [(dot self "_finixCatchTimer") (dot self "_finixCatchLast") (dot self "_finixCatchDistance")] [nil nil nil])
      (assign [(dot self "_finixCatchEmptySince") (dot self "_finixCatchPending")] [nil nil])
      (if' [context "==" self] (inline [(assign context [nil])]))
      (if' timer (inline [[(dot timers "removeTimer") timer]]))
    ];
  }))
  blank
  (localFunction disable ({err}: {
    params = [err];
    body = [
      (assign off [true])
      [pcall clear context]
      [log (str "error") (str "disabled") err]
    ];
  }))
  blank
  (localFunction need ({
    owner,
    name,
  }: {
    params = [owner name];
    body = [
      [assert' [owner "and" [type (index owner name)] "==" (str "function")] [name ".." (str " missing")]]
    ];
  }))
  blank
  (localFunction prepare ({
    self,
    helper,
    camera,
  }: {
    params = [self];
    body = [
      (local helper [(dot pg "game.controller.lockHelper")])
      (local camera [(dot pg "game.camera.playerCameraMode.catchCamera")])
      (if' (not (dot self "_finixCatchReady")) [
        [need (dot pg "global.entityMgr") (str "getAllEntities")]
        [need helper (str "checkTargetValid")]
        [need helper (str "tryForceLockTarget")]
        [need helper (str "canForceLock")]
        [need camera (str "setTarget")]
        [need camera (str "checkDistance")]
        [need camera (str "isActive")]
        [need self (str "checkBallCanThrow")]
        (assign prob [[prob "or" [require (str "Common.Utils.CatchProbContext")]]])
        [need prob (str "clientGet")]
        (assign ability [[ability "or" [require (str "Data.ability_setting_global_const_data")]]])
        (assign scenes [[scenes "or" [require (str "Data.scene_data")]]])
        (assign timers [[timers "or" [require (str "Core.Timer.TimerManager")]]])
        [need timers (str "addRepeatTimer")]
        [need timers (str "removeTimer")]
        (assign clock [[clock "or" [require (str "Core.Common.Time")]]])
        [need clock (str "getTickSecond")]
        (assign (dot self "_finixCatchReady") [true])
      ])
      (return [helper camera])
    ];
  }))
  blank
  (localFunction step ({
    self,
    helper,
    camera,
    scene,
    radius,
    from,
    candidates,
    pending,
    nextIndex,
    chosen,
  }: {
    params = [self];
    body = [
      (if' [(not (dot self "_continuousThrowHeld")) "or" (dot self "player") "~=" (dot pg "me") "or" (dot self "player.currentContext") "~=" self] (inline [(return [[clear self]])]))
      (local [helper camera] [[prepare self]])
      (if' [(not [(method camera "isActive")]) "or" (not [(method helper "canForceLock")]) "or" (not (dot pg "me.enableLockTarget"))] [
        (assign (dot self "_finixCatchEmptySince") [nil])
        (return [])
      ])
      (if' (not [(method self "checkBallCanThrow")]) (inline [(return [[(method self "stopContinuousThrow") (str "catch_ball_unavailable")]])]))
      (local scene [(index scenes (dot pg "me.space.sceneId"))])
      (local radius [[scene "and" (dot scene "forceLockDis") "or" (dot ability "forceLockDis")]])
      (if' [(dot pg "me.fogMaskRadius") "and" (dot pg "me.fogMaskRadius") ">" 0] (inline [(assign radius [(dot pg "me.fogMaskRadius")])]))
      [assert' [[type radius] "==" (str "number") "and" radius ">" 0] (str "lock radius missing")]
      (local from [[(method (dot pg "pawn") "getPosition")]])
      (local [candidates pending] [(table []) 0])
      (forIn ({
        _,
        ent,
      }: {
        names = [_ ent];
        values = [[pairs [(method (dot pg "global.entityMgr") "getAllEntities")]]];
        body = [
          (if' (rows [[[(dot ent "className") "==" (str "ClientPuppet") "or" (dot ent "className") "==" (str "ClientPuppetGhost")]] ["and" (dot ent "space") "==" (dot pg "me.space") "and" (not (dot ent "destroyed")) "and" (not (dot ent "isDestroyed"))]]) ({distance}: [
            (local distance [[(dot Vector3 "Distance") from [(method ent "getPosition")]]])
            (if' [distance "<=" radius] [
              (ifElse (dot ent "isTrapped") [
                  (assign pending [[pending "+" 1]])
                ] (if' (rows [[[(method ent "canBeLocked")] "and" [(method helper "checkTargetValid") ent radius nil false]] ["and" [(method camera "checkDistance") ent] "and" (dot [(dot prob "clientGet") ent (dot self "itemId")] "canCatch")]]) [
                  (assign (index candidates [(len candidates) "+" 1]) [(table [(field "entity" ent) (field "distance" distance)])])
                ]))
            ])
          ]))
        ];
      }))
      (if' [(len candidates) "==" 0] [
        (if' [(dot self "_finixCatchPending") "~=" pending] (inline [[log (str "wait") pending (str "pending")]]))
        (assign (dot self "_finixCatchPending") [pending])
        (ifElse [pending ">" 0] [
            (assign (dot self "_finixCatchEmptySince") [nil])
          ] ({now}: [
            (local now [[(dot clock "getTickSecond")]])
            (assign (dot self "_finixCatchEmptySince") [[(dot self "_finixCatchEmptySince") "or" now]])
            (if' [now "-" (dot self "_finixCatchEmptySince") ">=" GRACE] (inline [(return [[(method self "stopContinuousThrow") (str "catch_nothing_left")]])]))
          ]))
        (return [])
      ])
      (assign [(dot self "_finixCatchEmptySince") (dot self "_finixCatchPending")] [nil nil])
      [
        (dot table' "sort")
        candidates
        (fn ({
          a,
          b,
        }: {
          params = [a b];
          body = [
            (if' [(dot a "distance") "==" (dot b "distance")] (inline [(return [[(dot a "entity.actorId") "<" (dot b "entity.actorId")]])]))
            (return [[(dot a "distance") "<" (dot b "distance")]])
          ];
        }))
      ]
      (local nextIndex [])
      (forIn ({
        i,
        candidate,
      }: {
        names = [i candidate];
        values = [[ipairs candidates]];
        body = [
          (if' [(dot candidate "entity.actorId") "==" (dot self "_finixCatchLast")] (inline [(assign nextIndex [[i "%" (len candidates) "+" 1]]) semicolon break]))
        ];
      }))
      (if' [(not nextIndex) "and" (dot self "_finixCatchDistance")] [
        (forIn ({
          i,
          candidate,
        }: {
          names = [i candidate];
          values = [[ipairs candidates]];
          body = [
            (if' (rows [[(dot candidate "distance") ">" (dot self "_finixCatchDistance")] ["or" [(dot candidate "distance") "==" (dot self "_finixCatchDistance") "and" (dot candidate "entity.actorId") ">" (dot self "_finixCatchLast")]]]) [
              (assign nextIndex [i])
              break
            ])
          ];
        }))
      ])
      (local chosen [(index candidates [nextIndex "or" 1])])
      (assign [(dot self "_finixCatchLast") (dot self "_finixCatchDistance")] [(dot chosen "entity.actorId") (dot chosen "distance")])
      [(method helper "tryForceLockTarget") (dot chosen "entity.actorId") 0 radius]
      (if' [(dot helper "forceLockActorId") "~=" (dot chosen "entity.actorId")] (inline [(return [])]))
      [(method camera "setTarget") (dot chosen "entity")]
      [log (str "target") (dot chosen "entity.actorId") [(dot string "format") (str "%.2f") (dot chosen "distance")]]
    ];
  }))
  blank
  (localFunction safely ({
    fn',
    self,
    ok,
    err,
  }: {
    params = [fn' self];
    body = [
      (if' off (inline [(return [])]))
      (local [ok err] [[pcall fn' self]])
      (if' (not ok) (inline [[disable err]]))
    ];
  }))
  blank
  (localFunction startLocking ({
    self,
    id,
  }: {
    params = [self];
    body = [
      (if' [(not (dot self "_continuousThrowHeld")) "or" (dot self "player") "~=" (dot pg "me") "or" (dot self "player.currentContext") "~=" self] (inline [(return [[clear self]])]))
      (if' (dot self "_finixCatchTimer") (inline [(return [])]))
      (local id [(dot pg "game.controller.lockHelper.forceLockActorId")])
      (if' [(not id) "or" id "==" 0 "or" (not [(dot pg "getEntityByActorId") id])] (inline [(return [])]))
      [prepare self]
      (if' [context "~=" self] (inline [[clear context]]))
      (assign context [self])
      (assign [(dot self "_finixCatchLast") (dot self "_finixCatchDistance")] [nil nil])
      (assign [(dot self "_finixCatchEmptySince") (dot self "_finixCatchPending")] [nil nil])
      [safely step self]
      (if' [off "or" (not (dot self "_continuousThrowHeld"))] (inline [(return [])]))
      (assign (dot self "_finixCatchTimer") [[(dot timers "addRepeatTimer") INTERVAL (fn (inline [[safely step self]]))]])
      [assert' (dot self "_finixCatchTimer") (str "lock timer missing")]
    ];
  }))
  blank
  (localFunction install ({
    cls,
    start,
    tick,
    stop,
  }: {
    params = [cls];
    body = [
      (local [start tick stop] [[rawget cls (str "startContinuousThrow")] [rawget cls (str "_tryContinuousThrow")] [rawget cls (str "stopContinuousThrow")]])
      [assert' [[type start] "==" (str "function")] (str "startContinuousThrow missing")]
      [assert' [[type tick] "==" (str "function")] (str "_tryContinuousThrow missing")]
      [assert' [[type stop] "==" (str "function")] (str "stopContinuousThrow missing")]
      (assign (dot cls "startContinuousThrow") [
        (fn ({
          self,
          held,
          r,
        }: {
          params = [self vararg];
          body = [
            (local held [(dot self "_continuousThrowHeld")])
            (local r [[pack [start self vararg]]])
            (if' (not held) (inline [[safely startLocking self]]))
            (return [[unpack r 1 (dot r "n")]])
          ];
        }))
      ])
      (assign (dot cls "_tryContinuousThrow") [
        (fn ({self}: {
          params = [self vararg];
          body = [
            [safely startLocking self]
            (return [[tick self vararg]])
          ];
        }))
      ])
      (assign (dot cls "stopContinuousThrow") [
        (fn ({
          self,
          ok,
          err,
        }: {
          params = [self vararg];
          body = [
            (if' [context "==" self] (inline [[log (str "stop") (dot self "_finixCatchLast") [select 1 vararg]]]))
            (local [ok err] [[pcall clear self]])
            (if' (not ok) (inline [[disable err]]))
            (return [[stop self vararg]])
          ];
        }))
      ])
      [log (str "hook") (str "continuous throw") (str "ready")]
    ];
  }))
  blank
  (local [ok err] [[pcall install (index ret 1)]])
  (if' (not ok) (inline [[disable err]]))
  (return [[unpack ret 1 (dot ret "n")]])
])
