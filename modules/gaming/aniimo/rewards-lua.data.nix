{
  CS,
  apply,
  assign,
  blank,
  break,
  dot,
  field,
  fn,
  forIn,
  forNum,
  getfenv,
  getmetatable,
  if',
  ifElse,
  index,
  inline,
  io,
  ipairs,
  len,
  local,
  localFunction,
  math,
  method,
  next,
  nil,
  not,
  os,
  package,
  pairs,
  paren,
  pcall,
  pg,
  print,
  rawget,
  rawset,
  require,
  return,
  rows,
  select,
  setfenv,
  str,
  table,
  table',
  tonumber,
  tostring,
  type,
  unpack,
  vararg,
  while,
  ...
}: ({
  orig,
  pack,
  env,
  ret,
  MIN_GAP,
  JITTER,
  MAX_CLAIMS,
  STALE,
  MAIL_VIEW,
  LOG_FILE,
  state,
  logger,
  paths,
  stamp,
  field',
  logPaths,
  append,
  log,
  toast,
  setting,
  tab,
  req,
  has,
  iter,
  kv,
  iv,
  len',
  killed,
  now,
  noop,
  k,
  CLAIMS,
  act,
  task,
  group,
  openEvents,
  taskInfos,
  dailyActive,
  groupTasks,
  bpContext,
  battlePass,
  bpCycle,
  mileage,
  SEASON_FIELDS,
  seasonAchievement,
  sign,
  crossPlatform,
  firstTopup,
  journeyTrial,
  petDispatch,
  growthGift,
  littleFire,
  fishingCapture,
  leylineTreeUp,
  redBook,
  homeBookCategory,
  uiModel,
  grabEggsMode,
  course,
  playerLevel,
  lotteryTimes,
  specialTrain,
  petResearch,
  bossRush,
  inStage,
  homeSeason,
  questChapter,
  puppetScore,
  photoSurvey,
  petSaveWeek,
  energyMatch,
  petArea,
  homeCampDispatch,
  probe,
  SOURCES,
  skipped,
  missing,
  receiver,
  perform,
  nextAction,
  short,
  counts,
  hot,
  diagSource,
  DATA,
  diagModules,
  flag,
  diagActivity,
  diag,
  DOT_FN,
  DOT_SKIP,
  dotName,
  get,
  dotMethods,
  dotOwners,
  discover,
  delay,
  run,
  onPress,
  wrapButton,
  hookMail,
  install,
  ok,
  err,
}: [
  (local orig [vararg])
  (localFunction pack {
    params = [vararg];
    body = inline [(return [(table [(field "n" [select (str "#") vararg]) vararg])])];
  })
  (local env [[getfenv "and" [getfenv 1]]])
  (if' [[type env] "==" (str "table") "and" setfenv] (inline [[pcall setfenv orig env]]))
  (local ret [[pack [orig [select 2 vararg]]]])
  blank
  (local [MIN_GAP JITTER MAX_CLAIMS STALE] [1.0 0.6 300 15])
  (local MAIL_VIEW [(str "Guis.Panels.Chat.Component.MailNewComponent")])
  (local LOG_FILE [(str ".finix-aniimo/rewards.log")])
  (local state [(table [(field "off" false) (field "gen" 0) (field "hooked" false) (field "run" nil)])])
  (local [logger paths] [])
  blank
  (localFunction stamp ({
    ok,
    s,
  }: [
    (local [ok s] [[pcall (dot os "date") (str "!%Y-%m-%dT%H:%M:%SZ")]])
    (if' [ok "and" [type s] "==" (str "string")] (inline [(return [s])]))
    (return [[tostring [(dot os "time")]]])
  ]))
  blank
  (localFunction field' ({v}: {
    params = [v];
    body = [
      (if' [v "==" nil] (inline [(return [(str "-")])]))
      (return [(paren [(method [tostring v] "gsub") (str "[\\t\\r\\n]") (str " ")])])
    ];
  }))
  blank
  (localFunction logPaths ({
    list,
    ok,
    dp,
  }: [
    (local list [(table [])])
    (local [ok dp] [[pcall (fn (inline [(return [(dot CS "UnityEngine.Application.dataPath")])]))]])
    (if' [ok "and" [type dp] "==" (str "string") "and" dp "~=" (str "")] (inline [(assign (index list 1) [[dp ".." (str "/../") ".." LOG_FILE]])]))
    (assign (index list [(len list) "+" 1]) [LOG_FILE])
    (return [list])
  ]))
  blank
  (localFunction append ({line}: {
    params = [line];
    body = [
      (assign paths [[paths "or" [logPaths]]])
      (forIn ({
        _,
        p,
        f,
      }: {
        names = [_ p];
        values = [[ipairs paths]];
        body = [
          (local f [[(dot io "open") p (str "a")]])
          (if' f [
            [(method f "write") line]
            [(method f "close")]
            (return [true])
          ])
        ];
      }))
    ];
  }))
  blank
  (localFunction log ({
    event,
    label,
    result,
    quiet,
    msg,
  }: {
    params = [event label result quiet];
    body = [
      [pcall (fn (inline [[append [[(dot table' "concat") (table [[stamp] [field' event] [field' label] [field' result]]) (str "\\t")] ".." (str "\\n")]]]))]
      (if' quiet (inline [(return [])]))
      (local msg [[(str "[rewards] ") ".." [tostring event] ".." (str " ") ".." [field' label] ".." (str " ") ".." [field' result]]])
      [pcall print msg]
      (if' [logger "==" nil] [
        (assign logger [false])
        [pcall (fn (inline [(assign logger [[[(dot [require (str "Core.Log.LoggerManager")] "getLogger") (str "RewardsMod")] "or" false]])]))]
      ])
      (if' logger (inline [[pcall (fn (inline [[(method logger "warn") msg]]))]]))
    ];
  }))
  blank
  (localFunction toast ({text}: {
    params = [text];
    body = [
      [pcall (fn (inline [[(method (dot pg "global.ui.tips") "showTextTip") text nil nil nil nil nil nil true]]))]
    ];
  }))
  blank
  (localFunction setting ({v}: [
    (local v [[[type env] "==" (str "table") "and" [rawget env (str "ANIIMO_REWARDS")] "or" nil]])
    (if' [v "==" nil "and" [type os] "==" (str "table") "and" (dot os "getenv")] ({
      ok,
      e,
    }: [
      (local [ok e] [[pcall (dot os "getenv") (str "ANIIMO_REWARDS")]])
      (if' ok (inline [(assign v [e])]))
    ]))
    (return [[v "~=" nil "and" [tostring v] "or" (str "")]])
  ]))
  blank
  (localFunction tab ({
    v,
    t,
  }: {
    params = [v];
    body = [
      (local t [[type v]])
      (return [[t "==" (str "table") "or" t "==" (str "userdata")]])
    ];
  }))
  blank
  (localFunction req ({
    name,
    ok,
    m,
  }: {
    params = [name];
    body = [
      (local [ok m] [[pcall require name]])
      (if' [ok "and" [tab m]] (inline [(return [m])]))
    ];
  }))
  blank
  (localFunction has ({
    t,
    k,
    ok,
    v,
  }: {
    params = [t k];
    body = [
      (if' (not [tab t]) (inline [(return [false])]))
      (local [ok v] [[pcall (fn (inline [(return [(index t k)])]))]])
      (return [[ok "and" [type v] "==" (str "function")]])
    ];
  }))
  blank
  (localFunction iter ({
    f,
    v,
  }: {
    params = [f v];
    body = [
      (if' [tab v] ({
        ok,
        a,
        b,
        c,
      }: [
        (local [ok a b c] [[pcall f v]])
        (if' [ok "and" [type a] "==" (str "function")] (inline [(return [a b c])]))
      ]))
      (return [next (table []) nil])
    ];
  }))
  (localFunction kv ({v}: {
    params = [v];
    body = inline [(return [[iter pairs v]])];
  }))
  (localFunction iv ({v}: {
    params = [v];
    body = inline [(return [[iter ipairs v]])];
  }))
  blank
  (localFunction len' ({
    v,
    ok,
    n,
  }: {
    params = [v];
    body = [
      (if' (not [tab v]) (inline [(return [0])]))
      (local [ok n] [[pcall (fn (inline [(return [(len v)])]))]])
      (return [[ok "and" [type n] "==" (str "number") "and" n "or" 0]])
    ];
  }))
  blank
  (localFunction killed ({s}: {
    params = [s];
    body = inline [(return [[s "==" (str "0") "or" s "==" (str "off")]])];
  }))
  blank
  (localFunction now ({T}: [
    (local T [[req (str "Core.Common.Time")]])
    (if' [has T (str "getRealMillisecond")] ({
      ok,
      t,
    }: [
      (local [ok t] [[pcall (dot T "getRealMillisecond")]])
      (if' [ok "and" [type t] "==" (str "number")] (inline [(return [[t "/" 1000] 0.001])]))
    ]))
    (if' [[type os] "==" (str "table") "and" (dot os "time")] ({
      ok,
      t,
    }: [
      (local [ok t] [[pcall (dot os "time")]])
      (if' [ok "and" [type t] "==" (str "number")] (inline [(return [t 1])]))
    ]))
  ]))
  blank
  (localFunction noop (inline []))
  blank
  (localFunction k ({t}: {
    params = [vararg];
    body = [
      (local t [(table [vararg])])
      (forNum ({i}: {
        name = i;
        range = [1 [select (str "#") vararg]];
        body = inline [(assign (index t i) [[tostring (index t i)]])];
      }))
      (return [[(dot table' "concat") t (str ":")]])
    ];
  }))
  blank
  (local CLAIMS [
    (table (rows [
      (field "task" (table [(field "call" (str "reqActReceiveTaskReward"))]))
      (field "group" (table [(field "call" (str "reqActReceiveGroupTaskReward"))]))
      (field "bpCycle" (table [(field "rpc" (str "RPC_CS_ReceiveBpCycleReward")) (field "tail" (table [noop]))]))
      (field "rogueWeekly" (table [(field "call" (str "getRogueAllWeeklyReward"))]))
      (field "rogueSeasonWeekly" (table [(field "call" (str "getAllRogueSeasonWeeklyReward")) (field "tail" (table [0]))]))
      (field "rogueDaily" (table [(field "call" (str "getDailyReward"))]))
      (field "monthCardStored" (table [(field "on" (str "game.monthCard")) (field "call" (str "requestClaimStoredReward"))]))
      (field "monthCardDaily" (table [(field "on" (str "game.monthCard")) (field "call" (str "requestClaimDailyReward"))]))
      (field "homeBookGrade" (table [(field "call" (str "reqReceiveHandbookGradeReward")) (field "tail" (table [noop]))]))
      (field "homeBookCategory" (table [(field "call" (str "reqReceiveCategoryProgressReward")) (field "tail" (table [noop]))]))
      (field "grabEggsRank" (table [(field "rpc" (str "RPC_CS_GetRobEggLevelReward")) (field "tail" (table [0 0 0]))]))
      (field "grabEggsBox" (table [(field "rpc" (str "RPC_CS_OpenRobEggLevelRewardBox"))]))
      (field "grabEggsCase" (table [(field "rpc" (str "RPC_CS_GetShowCaseReward")) (field "tail" (table [noop]))]))
      (field "courseLevel" (table [(field "call" (str "getCourseLevelReward")) (field "tail" (table [noop]))]))
      (field "course" (table [(field "call" (str "getCourseReward")) (field "tail" (table [noop]))]))
      (field "playerLevel" (table [
        (field "fn" (fn ({
          me,
          lvs,
          CH,
        }: {
          params = [me lvs];
          body = [
            (local CH [[require (str "Core.Common.CallbackHandler")]])
            [(method me "serverMsg") (str "RPC_CS_GetLevelReward") lvs [CH (table [(field "done" noop)]) (str "done")]]
          ];
        })))
      ]))
      (field "gachaTimes" (table [(field "rpc" (str "RPC_CS_GachaClaimTimesReward")) (field "tail" (table [noop]))]))
      (field "trainChapter" (table [(field "call" (str "getSpecialTrainChapterReward")) (field "tail" (table [noop]))]))
      (field "trainEntry" (table [(field "call" (str "getSpecialTrainEntryReward")) (field "tail" (table [noop]))]))
      (field "trainBadge" (table [(field "call" (str "getSpecialTrainBadgeReward")) (field "tail" (table [noop]))]))
      (field "trainExchange" (table [(field "call" (str "getSpecialTrainBadgeContinuousReward")) (field "tail" (table [noop]))]))
      (field "petSpecies" (table [(field "call" (str "getPetHandbookSpeciesCollectReward")) (field "tail" (table [(-1)]))]))
      (field "petForm" (table [(field "call" (str "getPetHandbookCountryCollectReward")) (field "tail" (table [(-1)]))]))
      (field "petLevel" (table [(field "call" (str "getPetHandbookCountryLevelReward")) (field "tail" (table [(-1)]))]))
      (field "petTopic" (table [(field "call" (str "reqGetPetTopicRewards"))]))
      (field "bossRush" (table [(field "rpc" (str "RPC_CS_BossRushReceiveSeasonReward")) (field "tail" (table [noop]))]))
      (field "homeCarLevel" (table [(field "call" (str "getHomeCarLevelReward")) (field "tail" (table [(-1) noop]))]))
      (field "homeSeasonProgress" (table [(field "rpc" (str "RPC_CS_ReceiveHomeSeasonCollectionReward"))]))
      (field "homeSeasonTask" (table [(field "call" (str "reqReceiveHomeSeasonTaskReward")) (field "tail" (table [noop]))]))
      (field "homeSeasonMutation" (table [(field "call" (str "reqReceiveHomeSeasonMutationReward")) (field "tail" (table [noop]))]))
      (field "questChapter" (table [(field "call" (str "getChapterQuestProgressReward")) (field "tail" (table [noop]))]))
      (field "puppet" (table [(field "call" (str "reqActivityCatchScoreReward"))]))
      (field "photoReward" (table [(field "call" (str "reqActivityPhotoRewardGet"))]))
      (field "photoExtra" (table [(field "call" (str "reqActivityPhotoExtraRewardGet"))]))
      (field "photoStage" (table [(field "call" (str "reqActivityPhotoStageRewardGet"))]))
      (field "petSave" (table [(field "call" (str "reqActivityPetSaveWeekSumyReward")) (field "tail" (table [noop]))]))
      (field "energy" (table [(field "call" (str "serverActivityMsg"))]))
      (field "petArea" (table [(field "call" (str "getPetAreaReward"))]))
      (field "homeCampFinish" (table [(field "call" (str "finishDispatch"))]))
    ]))
  ])
  blank
  (localFunction act ({
    A,
    C,
    CA,
  }: [
    (local [A C CA] [[req (str "Common.Utils.ActivityUtils")] [req (str "Common.Const.ActivityConst")] [req (str "Utils.ClientActivityUtils")]])
    (if' [A "and" C "and" CA "and" [tab (dot C "EventType")] "and" [tab (dot C "TaskState")] "and" [tab (dot C "ActivityTaskType")]] (inline [(return [A C CA])]))
  ]))
  blank
  (localFunction task ({
    add,
    eid,
    tid,
    tag,
    label,
  }: {
    params = [add eid tid tag label];
    body = [
      [add [k tag (str "task") tid] label (str "task") [pack tid eid]]
    ];
  }))
  blank
  (localFunction group ({
    add,
    eid,
    gid,
    tag,
    label,
  }: {
    params = [add eid gid tag label];
    body = [
      [add [k tag (str "group") gid] label (str "group") [pack gid eid]]
    ];
  }))
  blank
  (localFunction openEvents ({
    et,
    A,
    _,
    CA,
    POST,
    list,
  }: {
    params = [et];
    body = [
      (local [A _ CA] [[act]])
      (local POST [[req (str "Data.game_event_type_post_data")]])
      (local list [(table [])])
      (if' (not [A "and" POST "and" et "~=" nil "and" [has CA (str "isGameEventTabOpen")] "and" [has CA (str "isEventOpen")] "and" [has A (str "getOprActivityUnlockCond")]]) (inline [(return [list])]))
      (forIn ({eid}: {
        names = [eid];
        values = [[kv (index POST et)]];
        body = [
          (if' [[(dot CA "isGameEventTabOpen") eid] "and" [(dot CA "isEventOpen") eid] "and" [(dot A "getOprActivityUnlockCond") eid]] (inline [(assign (index list [(len list) "+" 1]) [eid])]))
        ];
      }))
      [
        (dot table' "sort")
        list
        (fn ({
          a,
          b,
        }: {
          params = [a b];
          body = inline [(return [[[tostring a] "<" [tostring b]]])];
        }))
      ]
      (return [list])
    ];
  }))
  blank
  (localFunction taskInfos ({
    add,
    seen,
    et,
    eid,
    tag,
    name,
    list,
    _,
    C,
    CAN,
  }: {
    params = [add seen et eid tag name list];
    body = [
      (local [_ C] [[act]])
      (local CAN [(dot C "TaskState.Finihed_CanRecv")])
      (forIn ({
        _,
        t,
      }: {
        names = [_ t];
        values = [[iv list]];
        body = [
          (if' [[tab t] "and" (dot t "taskId") "~=" nil] [
            [seen (dot t "taskId") (dot t "taskState")]
            (if' [(dot t "taskState") "==" CAN] (inline [[task add eid (dot t "taskId") tag [name ".." (str " ") ".." [tostring (dot t "taskId")]]]]))
          ])
        ];
      }))
    ];
  }))
  blank
  (localFunction dailyActive ({
    add,
    seen,
    A,
    C,
    CA,
    ETD,
    ET,
    AT,
    CAN,
    ok,
    eid,
    UI,
    full,
  }: {
    params = [add seen];
    body = [
      (local [A C CA] [[act]])
      (local ETD [[req (str "Data.event_task_data")]])
      (if' (not [A "and" ETD "and" [has A (str "isOprActivityOpenByType")] "and" [has CA (str "getTaskInfoByActType")]]) (inline [(return [(str "deps")])]))
      (local [ET AT CAN] [(dot C "EventType") (dot C "ActivityTaskType") (dot C "TaskState.Finihed_CanRecv")])
      (local [ok eid] [[(dot A "isOprActivityOpenByType") (dot ET "DailyActive")]])
      (if' [(not ok) "or" (not eid)] (inline [(return [(str "closed")])]))
      (local UI [[req (str "Utils.LuaUIUtils")]])
      (local full [true])
      (if' [has UI (str "isDailyActiveScoreFull")] (inline [(assign full [[[(dot UI "isDailyActiveScoreFull")] "and" true "or" false]])]))
      (forIn ({
        _,
        t,
      }: {
        names = [_ t];
        values = [[kv [(dot CA "getTaskInfoByActType") (dot ET "DailyActive")]]];
        body = [
          (if' [tab t] [
            [seen (dot t "taskId") (dot t "taskState")]
            (if' [(dot t "taskState") "==" CAN] [
              (ifElse [(dot t "taskType") "==" (dot AT "DailyActive_GetScore") "and" (not full)] [
                  [task add eid (dot t "taskId") (str "daily") [(str "Daily activity task ") ".." [tostring (dot t "taskId")]]]
                ] (if' [(dot t "taskType") "==" (dot AT "DailyActive_ScoreReward")] ({cfg}: [
                  (local cfg [(index ETD (dot t "taskId"))])
                  (if' [[tab cfg] "and" (dot cfg "groupId")] (inline [[group add eid (dot cfg "groupId") (str "daily") (str "Daily activity score chest")]]))
                ])))
            ])
          ])
        ];
      }))
    ];
  }))
  blank
  (localFunction groupTasks ({
    seen,
    g,
    A,
  }: {
    params = [seen g];
    body = [
      (local A [[act]])
      (if' [g "==" nil] (inline [(return [])]))
      (forIn ({
        _,
        tid,
      }: {
        names = [_ tid];
        values = [[iv [(dot A "getActTaskIdsByGroupId") g]]];
        body = inline [[seen tid [(dot A "getActTaskState") (dot pg "me") tid]]];
      }))
    ];
  }))
  blank
  (localFunction bpContext ({
    A,
    C,
    GED,
    BPD,
    bp,
    phase,
    cfg,
    eid,
  }: [
    (local [A C] [[act]])
    (local [GED BPD] [[req (str "Data.game_event_data")] [req (str "Data.event_battlepass_data")]])
    (if' (not [A "and" GED "and" BPD "and" [has A (str "getActivityData")] "and" [has A (str "isOprActivityOpen")]]) (inline [(return [nil (str "deps")])]))
    (local bp [[(dot A "getActivityData") (dot pg "me") (dot C "EventType.BattlePass")]])
    (local phase [[[tab bp] "and" [tab (dot bp "activityBase")] "and" (dot bp "activityBase.activityPhase")]])
    (local cfg [[phase "and" (index BPD phase)]])
    (if' (not [tab cfg]) (inline [(return [nil (str "nophase")])]))
    (local eid [])
    (forIn ({
      id,
      e,
    }: {
      names = [id e];
      values = [[kv GED]];
      body = [
        (if' [[tab e] "and" (dot e "eventType") "==" (dot C "EventType.BattlePass") "and" (dot e "phase") "==" phase] (inline [(assign eid [id])]))
      ];
    }))
    (if' [(not eid) "or" (not [(dot A "isOprActivityOpen") eid])] (inline [(return [nil (str "closed")])]))
    (return [(table [(field "A" A) (field "C" C) (field "bp" bp) (field "phase" phase) (field "cfg" cfg) (field "eid" eid)])])
  ]))
  blank
  (localFunction battlePass ({
    add,
    seen,
    x,
    why,
    A,
    cfg,
    eid,
    bp,
    CAN,
    RD,
    wg,
    sg,
    ag,
  }: {
    params = [add seen];
    body = [
      (local [x why] [[bpContext]])
      (if' (not x) (inline [(return [why])]))
      (local [A cfg eid bp] [(dot x "A") (dot x "cfg") (dot x "eid") (dot x "bp")])
      (local CAN [(dot x "C.TaskState.Finihed_CanRecv")])
      (local RD [[req (str "Utils.CashShopRedDotUtils")]])
      (local wg [[[tab (dot cfg "weekTaskGroupId")] "and" (index (dot cfg "weekTaskGroupId") [(dot bp "weeklyNum") "or" 0]) "or" nil]])
      (local [sg ag] [(dot cfg "seasonTaskGroupId") (dot cfg "awardTaskGroupId")])
      (if' [[has A (str "getActTaskIdsByGroupId")] "and" [has A (str "getActTaskState")]] [
        (forIn ({
          _,
          g,
        }: {
          names = [_ g];
          values = [[ipairs (table [wg sg ag])]];
          body = inline [[groupTasks seen g]];
        }))
      ])
      (if' [wg "and" [has RD (str "hasClaimableWeeklyTask")] "and" [(dot RD "hasClaimableWeeklyTask")]] (inline [[group add eid wg (str "bp") (str "Battle pass weekly tasks")]]))
      (if' [sg "and" [has RD (str "hasClaimableSeasonTask")] "and" [(dot RD "hasClaimableSeasonTask")]] (inline [[group add eid sg (str "bp") (str "Battle pass season tasks")]]))
      (if' [ag "and" [has A (str "getActTaskIdsByGroupId")] "and" [has A (str "getActTaskState")]] [
        (forIn ({
          _,
          tid,
        }: {
          names = [_ tid];
          values = [[iv [(dot A "getActTaskIdsByGroupId") ag]]];
          body = [
            (if' [[(dot A "getActTaskState") (dot pg "me") tid] "==" CAN] (inline [[group add eid ag (str "bp") (str "Battle pass level rewards")] break]))
          ];
        }))
      ])
    ];
  }))
  blank
  (localFunction bpCycle ({
    add,
    seen,
    x,
    why,
    SC,
    bp,
    C,
    CAN,
    lo,
    hi,
  }: {
    params = [add seen];
    body = [
      (local [x why] [[bpContext]])
      (if' (not x) (inline [(return [why])]))
      (local [SC bp C] [[req (str "Data.sys_config_data")] (dot x "bp") (dot x "C")])
      (if' (not [SC "and" [has bp (str "getCycleRewardState")]]) (inline [(return [(str "deps")])]))
      [seen (str "unlock") (dot bp "unlockCycleReward")]
      (if' [(dot bp "unlockCycleReward") "~=" 1] (inline [(return [])]))
      (local CAN [(dot C "TaskState.Finihed_CanRecv")])
      (local lo [[[[tonumber (dot SC "BATTLE_PASS_LEVEL_UP_MAX")] "or" 0] "+" 1]])
      (local hi [[(dot math "min") [[tonumber (dot bp "bpLevel")] "or" 0] [[tonumber (dot bp "cycleRewardShowMaxlv")] "or" 0]]])
      (forNum ({
        lv,
        f,
        p,
      }: {
        name = lv;
        range = [lo hi];
        body = [
          (local [f p] [[(method bp "getCycleRewardState") lv]])
          [seen lv [[tostring f] ".." (str "/") ".." [tostring p]]]
          (if' [f "==" CAN "or" p "==" CAN] [
            (return [[add [k (str "bp") (str "cycle") (dot x "phase")] (str "Battle pass loop rewards") (str "bpCycle") [pack]]])
          ])
        ];
      }))
    ];
  }))
  blank
  (local mileage [(table [])])
  (local SEASON_FIELDS [(table [(table [(str "petTaskGroup") (str "pets")]) (table [(str "battleTaskGroup") (str "battle")]) (table [(str "eggTaskGroup") (str "eggs")]) (table [(str "homeTaskGroup") (str "home")])])])
  blank
  (localFunction seasonAchievement ({
    add,
    seen,
    A,
    C,
    CA,
    ok,
    eid,
    ETD,
    SAD,
    AT,
    SUB,
    TS,
    done,
    emit,
    mg,
    sa,
  }: {
    params = [add seen];
    body = [
      (local [A C CA] [[act]])
      (if' (not [A "and" [has A (str "isOprActivityTabOpenByType")] "and" [has A (str "getActTaskCanReceiveByGroupId")] "and" [has A (str "getActTaskIdsByGroupId")] "and" [has A (str "getActTaskState")] "and" [has CA (str "isGameEventTabOpen")]]) (inline [(return [(str "deps")])]))
      (local [ok eid] [[(dot A "isOprActivityTabOpenByType") (dot C "EventType.SeasonAchievements") (dot pg "me")]])
      (if' [(not ok) "or" (not eid) "or" (not [(dot CA "isGameEventTabOpen") eid])] (inline [(return [(str "closed")])]))
      (local [ETD SAD] [[req (str "Data.event_task_data")] [req (str "Data.event_season_achievement_data")]])
      (local [AT SUB TS] [(dot C "ActivityTaskType") (dot C "ActivityTaskSubType") (dot C "TaskState")])
      (local done [(table [])])
      (localFunction emit ({
        g,
        label,
      }: {
        params = [g label];
        body = [
          (if' [g "~=" nil "and" (not (index done g))] [
            (assign (index done g) [true])
            [group add eid g (str "season") label]
          ])
        ];
      }))
      (if' [ETD "and" [tab SUB] "and" (index mileage eid) "==" nil] [
        (assign (index mileage eid) [false])
        (forIn ({
          _,
          cfg,
        }: {
          names = [_ cfg];
          values = [[kv ETD]];
          body = [
            (if' [[tab cfg] "and" (dot cfg "activityId") "==" eid "and" (dot cfg "actTaskType") "==" (dot AT "Active_AchievementTask") "and" (dot cfg "actSubTaskType") "==" (dot SUB "AchiTask_SeasonAchieve_Mileage")] [
              (assign (index mileage eid) [[(dot cfg "groupId") "or" false]])
              break
            ])
          ];
        }))
      ])
      (local mg [(index mileage eid)])
      (if' mg ({ready}: [
        (local ready [false])
        (forIn ({
          _,
          tid,
        }: {
          names = [_ tid];
          values = [[iv [(dot A "getActTaskIdsByGroupId") mg]]];
          body = [
            (if' [(index ETD tid) "~=" nil] ({s}: [
              (local s [[[(dot A "getActTaskState") (dot pg "me") tid] "or" (dot TS "UnFinished")]])
              [seen tid s]
              (if' [s "==" (dot TS "Finihed_CanRecv")] (inline [(assign ready [true])]))
            ]))
          ];
        }))
        (if' ready (inline [[emit mg (str "Season achievement mileage")]]))
      ]))
      (local sa [[SAD "and" (index SAD eid)]])
      (if' (not [tab sa]) (inline [(return [[mg "and" nil "or" (str "noconfig")]])]))
      (forIn ({
        _,
        f,
      }: {
        names = [_ f];
        values = [[ipairs SEASON_FIELDS]];
        body = [
          (forIn ({
            _,
            g,
          }: {
            names = [_ g];
            values = [[iv (index sa (index f 1))]];
            body = [
              [groupTasks seen g]
              (if' [[len' [(dot A "getActTaskCanReceiveByGroupId") (dot pg "me") g]] ">" 0] (inline [[emit g [(str "Season achievement ") ".." [tostring g] ".." (str " (") ".." (index f 2) ".." (str ")")]]]))
            ];
          }))
        ];
      }))
    ];
  }))
  blank
  (localFunction sign ({
    add,
    seen,
    A,
    C,
    CA,
    POST,
    ET,
    CAN,
  }: {
    params = [add seen];
    body = [
      (local [A C CA] [[act]])
      (local POST [[req (str "Data.game_event_type_post_data")]])
      (if' (not [A "and" POST "and" [has A (str "isOprActivityOpen")] "and" [has A (str "getActTaskCanReceiveByGroupId")] "and" [has A (str "getActTaskIdsByGroupId")] "and" [has A (str "getActTaskState")] "and" [has CA (str "isGameEventTabOpen")] "and" [has CA (str "getSignTaskGroupIds")]]) (inline [(return [(str "deps")])]))
      (local [ET CAN] [(dot C "EventType") (dot C "TaskState.Finihed_CanRecv")])
      (forIn ({
        _,
        et,
      }: {
        names = [_ et];
        values = [[ipairs (table [(dot ET "SignNewbie") (dot ET "SignVersion") (dot ET "LongTermSign")])]];
        body = [
          (forIn ({eid}: {
            names = [eid];
            values = [[kv (index POST et)]];
            body = [
              (if' [[(dot CA "isGameEventTabOpen") eid] "and" [(dot A "isOprActivityOpen") eid]] [
                (forIn ({
                  _,
                  g,
                }: {
                  names = [_ g];
                  values = [[iv [(dot CA "getSignTaskGroupIds") eid]]];
                  body = [
                    (forIn ({
                      _,
                      tid,
                      s,
                    }: {
                      names = [_ tid];
                      values = [[iv [(dot A "getActTaskIdsByGroupId") g]]];
                      body = [
                        (local s [[(dot A "getActTaskState") (dot pg "me") tid]])
                        [seen tid s]
                        (if' [s "==" CAN] (inline [[task add eid tid (str "sign") [(str "Sign-in reward ") ".." [tostring tid]]]]))
                      ];
                    }))
                  ];
                }))
              ])
            ];
          }))
        ];
      }))
    ];
  }))
  blank
  (localFunction crossPlatform ({
    add,
    seen,
    _,
    C,
    CA,
    et,
    eid,
  }: {
    params = [add seen];
    body = [
      (local [_ C CA] [[act]])
      (if' (not [C "and" [has CA (str "getTaskInfoByActType")]]) (inline [(return [(str "deps")])]))
      (local et [(dot C "EventType.CrossPlatform")])
      (local eid [(index [openEvents et] 1)])
      (if' (not eid) (inline [(return [(str "closed")])]))
      [taskInfos add seen et eid (str "cross") (str "Cross-platform task") [(dot CA "getTaskInfoByActType") et]]
    ];
  }))
  blank
  (localFunction firstTopup ({
    add,
    seen,
    _,
    C,
    CA,
    et,
    eid,
  }: {
    params = [add seen];
    body = [
      (local [_ C CA] [[act]])
      (if' (not [C "and" [has CA (str "getTaskInfoByTaskType")]]) (inline [(return [(str "deps")])]))
      (local et [(dot C "EventType.FirstTopup")])
      (local eid [(index [openEvents et] 1)])
      (if' (not eid) (inline [(return [(str "closed")])]))
      [taskInfos add seen et eid (str "firsttopup") (str "First top-up reward") [(dot CA "getTaskInfoByTaskType") et (dot C "ActivityTaskType.Active_AchievementTask")]]
    ];
  }))
  blank
  (localFunction journeyTrial ({
    add,
    seen,
    _,
    C,
    CA,
    T,
    eid,
    CAN,
    try,
    fin,
  }: {
    params = [add seen];
    body = [
      (local [_ C CA] [[act]])
      (local T [[[tab CA] "and" (dot CA "REUNION_TRAINING_TASK_TYPE")]])
      (if' (not [C "and" [tab T] "and" [has CA (str "getTaskInfoList")]]) (inline [(return [(str "deps")])]))
      (local eid [(index [openEvents (dot C "EventType.JourneyTrial")] 1)])
      (if' (not eid) (inline [(return [(str "closed")])]))
      (local CAN [(dot C "TaskState.Finihed_CanRecv")])
      (localFunction try ({
        t,
        tag,
      }: {
        params = [t tag];
        body = [
          (if' [[tab t] "and" (dot t "taskId") "~=" nil] [
            [seen (dot t "taskId") (dot t "taskState")]
            (if' [(dot t "taskState") "==" CAN] (inline [[task add eid (dot t "taskId") (str "journey") [(str "Journey of Trials ") ".." tag ".." (str " ") ".." [tostring (dot t "taskId")]]]]))
          ])
        ];
      }))
      (forIn ({
        _,
        t,
      }: {
        names = [_ t];
        values = [[iv [(dot CA "getTaskInfoList") (dot T "normal") true]]];
        body = inline [[try t (str "task")]];
      }))
      (forIn ({
        _,
        t,
      }: {
        names = [_ t];
        values = [[iv [(dot CA "getTaskInfoList") (dot T "row") true]]];
        body = inline [[try t (str "row")]];
      }))
      (local fin [[(dot CA "getTaskInfoList") (dot T "final") true]])
      (if' [tab fin] (inline [[try (index fin 1) (str "final")]]))
    ];
  }))
  blank
  (localFunction petDispatch ({
    add,
    seen,
    A,
    C,
    CA,
    TT,
    et,
    eid,
    data,
    PDU,
    clues,
    CAN,
  }: {
    params = [add seen];
    body = [
      (local [A C CA] [[act]])
      (local TT [[C "and" (dot C "ActivityTaskType")]])
      (if' (not [A "and" [has A (str "getActivityData")] "and" [has CA (str "getTaskInfoByActType")] "and" (dot TT "PetDispatch_Dispatch") "and" (dot TT "PetDispatch_StageScore")]) (inline [(return [(str "deps")])]))
      (local et [(dot C "EventType.PetDispatch")])
      (local eid [(index [openEvents et] 1)])
      (if' (not eid) (inline [(return [(str "closed")])]))
      (local data [[(dot A "getActivityData") (dot pg "me") et]])
      (if' (not [tab data]) (inline [(return [(str "nodata")])]))
      (local PDU [[req (str "GameApp.PetDispatch.PetDispatchUtils")]])
      (local clues [(table [])])
      (if' [has PDU (str "getCurrentStageClues")] [
        (forIn ({
          _,
          c,
        }: {
          names = [_ c];
          values = [[kv [(dot PDU "getCurrentStageClues") (dot data "eventPhase")]]];
          body = [
            (if' [[tab c] "and" (dot c "taskId") "~=" nil] (inline [(assign (index clues (dot c "taskId")) [true])]))
          ];
        }))
      ])
      (local CAN [(dot C "TaskState.Finihed_CanRecv")])
      (forIn ({
        _,
        t,
      }: {
        names = [_ t];
        values = [[kv [(dot CA "getTaskInfoByActType") et]]];
        body = [
          (if' [[tab t] "and" (dot t "taskId") "~=" nil] [
            [seen (dot t "taskId") (dot t "taskState")]
            (if' [(dot t "taskState") "==" CAN] [
              (ifElse [(dot t "taskType") "==" (dot TT "PetDispatch_Dispatch") "and" (index clues (dot t "taskId"))] [
                  [task add eid (dot t "taskId") (str "dispatch") [(str "Pet dispatch clue reward ") ".." [tostring (dot t "taskId")]]]
                ] (if' [(dot t "taskType") "==" (dot TT "PetDispatch_StageScore")] [
                  [task add eid (dot t "taskId") (str "dispatch") [(str "Pet dispatch progress reward ") ".." [tostring (dot t "taskId")]]]
                ]))
            ])
          ])
        ];
      }))
    ];
  }))
  blank
  (localFunction growthGift ({
    add,
    seen,
    A,
    C,
    CA,
    ATD,
    et,
    d,
  }: {
    params = [add seen];
    body = [
      (local [A C CA] [[act]])
      (local ATD [[req (str "Data.activate_tasks_data")]])
      (if' (not [A "and" ATD "and" [has A (str "getActivityData")] "and" [has CA (str "getTaskInfoList")]]) (inline [(return [(str "deps")])]))
      (local et [(dot C "EventType.GrowthGift")])
      (local d [[(dot A "getActivityData") (dot pg "me") et]])
      [seen (str "receivedPetFlag") [[tab d] "and" (dot d "receivedPetFlag") "or" nil]]
      (if' (not [[tab d] "and" (dot d "receivedPetFlag") "==" 1]) (inline [(return [(str "noegg")])]))
      (forIn ({
        _,
        eid,
        cfg,
        g,
      }: {
        names = [_ eid];
        values = [[ipairs [openEvents et]]];
        body = [
          (local cfg [(index ATD eid)])
          (local g [[[tab cfg] "and" [tab (dot cfg "foreverTaskGroup")] "and" (index (dot cfg "foreverTaskGroup") 1)]])
          (if' g (inline [[taskInfos add seen et eid (str "growth") (str "Growth gift collection reward") [(dot CA "getTaskInfoList") g true]]]))
        ];
      }))
    ];
  }))
  blank
  (localFunction littleFire ({
    add,
    seen,
    _,
    C,
    CA,
    et,
    TT,
    CAN,
    eid,
  }: {
    params = [add seen];
    body = [
      (local [_ C CA] [[act]])
      (if' (not [C "and" [has CA (str "getTaskInfoByTaskType")]]) (inline [(return [(str "deps")])]))
      (local [et TT CAN] [(dot C "EventType.LittleFirePerson") (dot C "ActivityTaskType") (dot C "TaskState.Finihed_CanRecv")])
      (local eid [(index [openEvents et] 1)])
      (if' (not eid) (inline [(return [(str "closed")])]))
      (forIn ({
        _,
        name,
      }: {
        names = [_ name];
        values = [[ipairs (table [(str "LittleFire_PersonReward") (str "LittleFire_GlobalReward")])]];
        body = [
          (if' [(index TT name) "~=" nil] [
            (forIn ({
              _,
              t,
            }: {
              names = [_ t];
              values = [[kv [(dot CA "getTaskInfoByTaskType") et (index TT name)]]];
              body = [
                (if' [tab t] [
                  [seen (dot t "taskId") (dot t "taskState")]
                  (if' [(dot t "taskState") "==" CAN "and" (dot t "taskGroupId") "~=" nil] (inline [[group add eid (dot t "taskGroupId") (str "littlefire") (str "Little Fire progress reward")]]))
                ])
              ];
            }))
          ])
        ];
      }))
      (forIn ({
        _,
        name,
      }: {
        names = [_ name];
        values = [[ipairs (table [(str "Active_DailyTask") (str "Active_WeeklyTask") (str "Active_AchievementTask")])]];
        body = [
          (if' [(index TT name) "~=" nil] (inline [[taskInfos add seen et eid (str "littlefire") (str "Little Fire task") [(dot CA "getTaskInfoByTaskType") et (index TT name)]]]))
        ];
      }))
    ];
  }))
  blank
  (localFunction fishingCapture ({
    add,
    seen,
    _,
    C,
    CA,
    ATD,
  }: {
    params = [add seen];
    body = [
      (local [_ C CA] [[act]])
      (local ATD [[req (str "Data.activate_tasks_data")]])
      (if' (not [C "and" ATD "and" [has CA (str "getFishingCaptureRedDotState")]]) (inline [(return [(str "deps")])]))
      (forIn ({
        _,
        eid,
        cfg,
        gid,
        st,
        n,
      }: {
        names = [_ eid];
        values = [[ipairs [openEvents (dot C "EventType.FishingCapture")]]];
        body = [
          (local cfg [(index ATD eid)])
          (local gid [[[tab cfg] "and" [tab (dot cfg "foreverTaskGroup")] "and" (index (dot cfg "foreverTaskGroup") 1)]])
          (local st [[(dot CA "getFishingCaptureRedDotState") eid]])
          (local n [[[tab st] "and" [len' (dot st "rewardTaskIds")] "or" 0]])
          [seen eid n]
          (if' [gid "and" n ">" 0] (inline [[group add eid gid (str "fishing") (str "Fishing capture progress rewards")]]))
        ];
      }))
    ];
  }))
  blank
  (localFunction leylineTreeUp ({
    add,
    seen,
    A,
    C,
    CA,
    ETD,
    et,
    eid,
    CAN,
  }: {
    params = [add seen];
    body = [
      (local [A C CA] [[act]])
      (local ETD [[req (str "Data.event_task_data")]])
      (if' (not [A "and" ETD "and" [has A (str "getActTaskMap")] "and" [has CA (str "_isInLeylineTreeUpTime")]]) (inline [(return [(str "deps")])]))
      (local et [(dot C "EventType.LeylineTreeUp")])
      (if' (not [(dot CA "_isInLeylineTreeUpTime")]) (inline [(return [(str "closed")])]))
      (local eid [(index [openEvents et] 1)])
      (if' (not eid) (inline [(return [(str "closed")])]))
      (local CAN [(dot C "TaskState.Finihed_CanRecv")])
      (forIn ({
        tid,
        t,
      }: {
        names = [tid t];
        values = [[kv [(dot A "getActTaskMap") (dot pg "me") et]]];
        body = [
          (if' [(index ETD tid) "~=" nil "and" [tab t]] [
            [seen tid (dot t "state")]
            (if' [(dot t "state") "==" CAN] (inline [[task add eid tid (str "leylineup") [(str "Leyline tree event task ") ".." [tostring tid]]]]))
          ])
        ];
      }))
    ];
  }))
  blank
  (localFunction redBook ({
    add,
    seen,
    A,
    C,
    ATD,
    ETD,
    CAN,
    sortv,
  }: {
    params = [add seen];
    body = [
      (local [A C] [[act]])
      (local [ATD ETD] [[req (str "Data.activate_tasks_data")] [req (str "Data.event_task_data")]])
      (if' (not [A "and" ATD "and" ETD "and" [has A (str "getActTaskIdsByGroupId")] "and" [has A (str "getActTaskState")]]) (inline [(return [(str "deps")])]))
      (local CAN [(dot C "TaskState.Finihed_CanRecv")])
      (localFunction sortv ({
        id,
        c,
      }: {
        params = [id];
        body = [
          (local c [(index ETD id)])
          (return [[[tab c] "and" [tonumber (dot c "sort")] "or" (dot math "huge")]])
        ];
      }))
      (forIn ({
        _,
        eid,
        cfg,
        grp,
      }: {
        names = [_ eid];
        values = [[ipairs [openEvents [(dot C "EventType.RedBook") "or" 115]]]];
        body = [
          (local cfg [(index ATD eid)])
          (local grp [[[tab cfg] "and" (dot cfg "foreverTaskGroup")]])
          (if' [tab grp] ({
            ids,
            t2,
            shown,
            done,
          }: [
            (local ids [(table [])])
            (forIn ({
              _,
              tid,
            }: {
              names = [_ tid];
              values = [[iv [(dot A "getActTaskIdsByGroupId") (index grp 1)]]];
              body = inline [(assign (index ids [(len ids) "+" 1]) [tid])];
            }))
            [
              (dot table' "sort")
              ids
              (fn ({
                a,
                b,
                sa,
                sb,
              }: {
                params = [a b];
                body = [
                  (local [sa sb] [[sortv a] [sortv b]])
                  (if' [sa "==" sb] (inline [(return [[a "<" b]])]))
                  (return [[sa "<" sb]])
                ];
              }))
            ]
            (local t2 [])
            (forIn ({
              _,
              tid,
            }: {
              names = [_ tid];
              values = [[iv [(dot A "getActTaskIdsByGroupId") (index grp 2)]]];
              body = inline [(assign t2 [tid]) break];
            }))
            (local [shown done] [(table [(index ids 1) (index ids 2) [[t2 "~=" nil "and" (index ETD t2) "~=" nil] "and" t2 "or" nil]]) (table [])])
            (forNum ({
              i,
              tid,
            }: {
              name = i;
              range = [1 3];
              body = [
                (local tid [(index shown i)])
                (if' [tid "~=" nil "and" (not (index done tid))] ({s}: [
                  (assign (index done tid) [true])
                  (local s [[(dot A "getActTaskState") (dot pg "me") tid]])
                  [seen tid s]
                  (if' [s "==" CAN] (inline [[task add eid tid (str "redbook") [(str "RedNote event task ") ".." [tostring tid]]]]))
                ]))
              ];
            }))
          ]))
        ];
      }))
    ];
  }))
  blank
  (localFunction homeBookCategory ({
    add,
    seen,
    HB,
    HD,
    me,
  }: {
    params = [add seen];
    body = [
      (local [HB HD] [[req (str "Utils.HomeBookRedDotUtils")] [req (str "Utils.HomeBookDataUtils")]])
      (local me [(dot pg "me")])
      (if' (not [[has HB (str "canReceiveCategoryReward")] "and" [has HD (str "getFirstCategories")] "and" [has me (str "reqReceiveCategoryProgressReward")]]) (inline [(return [(str "deps")])]))
      (forIn ({
        _,
        e,
      }: {
        names = [_ e];
        values = [[iv [(dot HD "getFirstCategories")]]];
        body = [
          (if' [[tab e] "and" (dot e "id") "~=" nil] ({
            cond,
            unlocked,
            s,
          }: [
            (local cond [[[tab (dot e "config")] "and" (dot e "config.unlockCondition") "or" nil]])
            (local unlocked [[cond "==" nil "or" cond "==" 0 "or" [[tab (dot me "triggerMap")] "and" [(method (dot me "triggerMap") "isCompleteOrMeetCondition") cond] "==" true]]])
            (local s [[[(dot HB "canReceiveCategoryReward") (dot e "id") unlocked] "and" true "or" false]])
            [seen (dot e "id") s]
            (if' s ({n}: [
              (local n [[[has me (str "getHomeHandbookReceivedCategoryCount")] "and" [(method me "getHomeHandbookReceivedCategoryCount") (dot e "id")] "or" 0]])
              [add [k (str "homebook") (str "cat") (dot e "id") n] [(str "Home handbook category ") ".." [tostring (dot e "id")]] (str "homeBookCategory") [pack (dot e "id")]]
            ]))
          ]))
        ];
      }))
    ];
  }))
  blank
  (localFunction uiModel ({
    name,
    ui,
    p,
    m,
  }: {
    params = [name];
    body = [
      (local ui [[(dot pg "global") "and" (dot pg "global.ui")]])
      (local p [[[tab ui] "and" (index ui name)]])
      (local m [[[tab p] "and" (dot p "model")]])
      (return [[[tab m] "and" m "or" nil]])
    ];
  }))
  blank
  (localFunction grabEggsMode ({
    add,
    seen,
    m,
    cs,
    GD,
    RW,
  }: {
    params = [add seen];
    body = [
      (local m [[uiModel (str "grabEggsMode")]])
      (if' (not m) (inline [(return [(str "deps")])]))
      (if' [[has m (str "hasReadyRewardBox")] "and" [has m (str "buildBoxSlotList")]] ({ready}: [
        (local ready [[[(method m "hasReadyRewardBox")] "and" true "or" false]])
        [seen (str "boxes") ready]
        (if' ready [
          (forIn ({
            i,
            d,
          }: {
            names = [i d];
            values = [[iv [(method m "buildBoxSlotList")]]];
            body = [
              (if' [[tab d] "and" (dot d "isReady") "and" (dot d "rewardId") "~=" nil] [
                [add [k (str "grabeggs") (str "box") i (dot d "id")] [(str "Grab-eggs reward box ") ".." i] (str "grabEggsBox") [pack (dot d "rewardId")]]
              ])
            ];
          }))
        ])
      ]))
      (local cs [[[tab (dot pg "me.showCases")] "and" (index (dot pg "me.showCases") 1001)]])
      (local [GD RW] [[req (str "Data.egg_book_group_data")] [req (str "Data.egg_book_reward_data")]])
      (if' [[tab cs] "and" GD "and" RW "and" [has m (str "hasCollectionReward")]] ({ready}: [
        (local ready [[[(method m "hasCollectionReward") cs] "and" true "or" false]])
        [seen (str "case1001") ready]
        (if' ready ({
          g,
          pts,
          rec',
        }: [
          (local g [(index GD 1001)])
          (local [pts rec'] [[[tonumber (dot cs "allPoint")] "or" 0] (dot cs "rewardRecord")])
          (forIn ({
            lv,
            n,
          }: {
            names = [lv n];
            values = [[kv [[tab g] "and" (index RW (dot g "reward"))]]];
            body = [
              (if' [[tab n] "and" [[tonumber (dot n "nodePoint")] "or" 0] "<=" pts "and" (not [[[tonumber [[tab rec'] "and" (index rec' lv)]] "or" 0] ">" 0])] [
                [add [k (str "grabeggs") (str "case") lv] [(str "Grab-eggs collection reward ") ".." [tostring lv]] (str "grabEggsCase") [pack 1001 lv]]
              ])
            ];
          }))
        ]))
      ]))
    ];
  }))
  blank
  (localFunction course ({
    add,
    seen,
    m,
    GD,
  }: {
    params = [add seen];
    body = [
      (local [m GD] [[uiModel (str "questCourseV2")] [req (str "Data.guide_course_grade_data")]])
      (if' (not [m "and" GD "and" [has m (str "canGetCourseGradeLevelReward")] "and" [has m (str "getGradeCourseList")] "and" [has m (str "canGetCourseReward")]]) (inline [(return [(str "deps")])]))
      (forIn ({
        grade,
        levels,
      }: {
        names = [grade levels];
        values = [[kv GD]];
        body = [
          (forNum ({
            level,
            s,
          }: {
            name = level;
            range = [1 [len' levels]];
            body = [
              (local s [[[(method m "canGetCourseGradeLevelReward") grade level] "and" true "or" false]])
              [seen [k grade level] s]
              (if' s [
                [add [k (str "course") (str "level") grade level] [(str "Course grade ") ".." [tostring grade] ".." (str " level ") ".." level] (str "courseLevel") [pack grade level]]
              ])
            ];
          }))
          (forIn ({
            _,
            c,
          }: {
            names = [_ c];
            values = [[iv [(method m "getGradeCourseList") grade]]];
            body = [
              (if' [[tab c] "and" (dot c "id") "~=" nil] ({s}: [
                (local s [[[(method m "canGetCourseReward") (dot c "id")] "and" true "or" false]])
                [seen (dot c "id") s]
                (if' s (inline [[add [k (str "course") (str "course") (dot c "id")] [(str "Course ") ".." [tostring (dot c "id")]] (str "course") [pack (dot c "id")]]]))
              ]))
            ];
          }))
        ];
      }))
    ];
  }))
  blank
  (localFunction playerLevel ({
    add,
    seen,
    m,
    lvs,
    list,
  }: {
    params = [add seen];
    body = [
      (local m [[uiModel (str "playerLvReward")]])
      (if' (not [m "and" [has m (str "redDot_CheckHasLvReward")] "and" [has m (str "getPlayerLvDataList")] "and" [tab (dot m "LEVEL_STATE")]]) (inline [(return [(str "deps")])]))
      (local lvs [(table [])])
      (forIn ({
        _,
        d,
      }: {
        names = [_ d];
        values = [[iv [(method m "getPlayerLvDataList")]]];
        body = [
          (if' [tab d] [
            [seen (dot d "lv") (dot d "lvState")]
            (if' [(dot d "lvState") "==" (dot m "LEVEL_STATE.LEVEL_MATCH")] (inline [(assign (index lvs [(len lvs) "+" 1]) [(dot d "lv")])]))
          ])
        ];
      }))
      (if' [(len lvs) "==" 0 "or" (not [(method m "redDot_CheckHasLvReward")])] (inline [(return [])]))
      (local list [[(dot table' "concat") lvs (str ",")]])
      [add [k (str "playerlv") list] [(str "Player level rewards ") ".." list] (str "playerLevel") [pack lvs]]
    ];
  }))
  blank
  (localFunction lotteryTimes ({
    add,
    seen,
    LU,
    GT,
  }: {
    params = [add seen];
    body = [
      (local [LU GT] [[req (str "Utils.LotteryUtils")] [req (str "Data.gacha_times_data")]])
      (if' (not [[has LU (str "hasClaimableTimesReward")] "and" GT]) (inline [(return [(str "deps")])]))
      (forIn ({
        drawId,
        list,
        d,
      }: {
        names = [drawId list];
        values = [[kv GT]];
        body = [
          (local d [[tonumber drawId]])
          (if' [d "and" [tab list]] ({s}: [
            (local s [[[(dot LU "hasClaimableTimesReward") d] "and" true "or" false]])
            [seen d s]
            (if' s ({
              g,
              cnt,
              got,
            }: [
              (local g [[[tab (dot pg "me.gachaMap")] "and" (index (dot pg "me.gachaMap") d)]])
              (local cnt [[[tab g] "and" [tonumber (dot g "drawCount")] "or" 0]])
              (local got [[[tab g] "and" (dot g "claimedTimesRewardNums")]])
              (forIn ({
                i,
                t,
                n,
              }: {
                names = [i t];
                values = [[iv list]];
                body = [
                  (local n [[[tab t] "and" [tonumber (dot t "num")]]])
                  (if' [n "and" n "<=" cnt "and" (not [[tab got] "and" (index got n) "==" true])] [
                    [add [k (str "gacha") d i] [(str "Draw-count reward ") ".." d ".." (str " #") ".." i] (str "gachaTimes") [pack d i]]
                  ])
                ];
              }))
            ]))
          ]))
        ];
      }))
    ];
  }))
  blank
  (localFunction specialTrain ({
    add,
    seen,
    m,
    QU,
    QC,
    R,
    style,
    cur,
    SRC,
    SUB,
  }: {
    params = [add seen];
    body = [
      (local [m QU QC R] [[uiModel (str "SpecialTrainNew")] [req (str "GameApp.Quest.QuestUtils")] [req (str "Common.Const.QuestConst")] [req (str "Const.RedDotConst")]])
      (if' (not [m "and" QU "and" QC "and" R "and" [has m (str "redDot_GetSpecialTrainState")] "and" [has QU (str "getCurChapterId")]]) (inline [(return [(str "deps")])]))
      (local style [[(method m "redDot_GetSpecialTrainState")]])
      [seen (str "hud") style]
      (if' [style "~=" (dot R "RedDotStyle.REWARD")] (inline [(return [])]))
      (local cur [[[tonumber [(dot QU "getCurChapterId")]] "or" 0]])
      (if' [cur ">" 0 "and" [has m (str "getChapterTb")] "and" [has m (str "redDot_GetChapterPageState")]] [
        (forIn ({
          _,
          ch,
          id,
        }: {
          names = [_ ch];
          values = [[iv [(method m "getChapterTb")]]];
          body = [
            (local id [[[tab ch] "and" (dot ch "chapterId")]])
            (if' [id "and" [(method m "redDot_GetChapterPageState") id]] [
              [add [k (str "strain") (str "chapter") id] [(str "Special training chapter ") ".." [tostring id]] (str "trainChapter") [pack id]]
            ])
          ];
        }))
      ])
      (local [SRC SUB] [(dot QC "SPECIAL_TRAIN_REWARD_SRC_TYPE") (dot QC "QUEST_TRAIN_SUB_TYPE")])
      (if' [[tab SRC] "and" [tab SUB] "and" [has m (str "getPageTypeTb")] "and" [has m (str "getAllCanGetSpecialTrainRewardList")]] [
        (forIn ({
          _,
          pt,
          tt,
        }: {
          names = [_ pt];
          values = [[iv [(method m "getPageTypeTb")]]];
          body = [
            (local tt [[[tab pt] "and" (dot pt "trainType")]])
            (if' tt [
              (forNum ({
                c,
                ids,
              }: {
                name = c;
                range = [cur [tt "==" (dot SUB "COMPULSORY") "and" 0 "or" cur] (-1)];
                body = [
                  (local ids [[(method m "getAllCanGetSpecialTrainRewardList") c tt]])
                  (if' [[len' ids] ">" 0] [
                    [add [k (str "strain") (str "entry") c tt] [(str "Special training rewards ") ".." c ".." (str "/") ".." [tostring tt]] (str "trainEntry") [pack ids (dot SRC "HANDBOOK")]]
                  ])
                ];
              }))
            ])
          ];
        }))
      ])
      (if' [[has m (str "getBadgeListTab")] "and" [has m (str "redDot_GetBadgeState")]] [
        (forIn ({
          _,
          b,
        }: {
          names = [_ b];
          values = [[kv [(method m "getBadgeListTab") 0]]];
          body = [
            (if' [[tab b] "and" [(method m "redDot_GetBadgeState") b]] [
              [add [k (str "strain") (str "badge") (dot b "stageId")] [(str "Special training badge ") ".." [tostring (dot b "stageId")]] (str "trainBadge") [pack [(dot b "isFinal") "and" true "or" false]]]
            ])
          ];
        }))
      ])
      (if' [(dot pg "me.isGetBadgeMaxReward") "and" [has m (str "getExchangeInfo")]] ({x}: [
        (local x [[(method m "getExchangeInfo")]])
        (if' [[tab x] "and" [type (dot x "canExchangeNum")] "==" (str "number") "and" (dot x "canExchangeNum") ">" 0] [
          [add (str "strain:exchange") (str "Special training badge exchange") (str "trainExchange") [pack]]
        ])
      ]))
    ];
  }))
  blank
  (localFunction petResearch ({
    add,
    seen,
    m,
    PRU,
    R,
    style,
    area,
    TAB,
    CD,
    hb,
  }: {
    params = [add seen];
    body = [
      (local [m PRU R] [[uiModel (str "petResearch")] [req (str "Guis.Utils.PetResearchUtils")] [req (str "Const.RedDotConst")]])
      (if' (not [m "and" PRU "and" R "and" [tab (dot PRU "PET_SHOW_TAB")] "and" [has m (str "redDot_GetPetResearchState")] "and" [has PRU (str "checkCountryReward")]]) (inline [(return [(str "deps")])]))
      (local style [[(method m "redDot_GetPetResearchState")]])
      [seen (str "hud") style]
      (if' [style "~=" (dot R "RedDotStyle.REWARD")] (inline [(return [])]))
      (local [area TAB] [(dot m "areaId") (dot PRU "PET_SHOW_TAB")])
      (if' (not area) (inline [(return [(str "noarea")])]))
      (if' [(dot PRU "checkCountryReward") area (dot TAB "SPECIES") (dot PRU "REWARD_COLLECT")] [
        [add [k (str "petres") (str "species") area] (str "Pet research species collection") (str "petSpecies") [pack area]]
      ])
      (if' [(dot PRU "checkCountryReward") area (dot TAB "FORM") (dot PRU "REWARD_COLLECT")] [
        [add [k (str "petres") (str "form") area] (str "Pet research form collection") (str "petForm") [pack area]]
      ])
      (if' [(dot PRU "checkCountryReward") area (dot TAB "SPECIES") (dot PRU "REWARD_LEVEL")] [
        [add [k (str "petres") (str "level") area] (str "Pet research country level") (str "petLevel") [pack area]]
      ])
      (local [CD hb] [[req (str "Data.pet_research_content_data")] (dot pg "me.petHandbookMap")])
      (if' [CD "and" hb "and" [has PRU (str "getPetResearchSpeciesList")] "and" [has PRU (str "_checkPetHasTopicReward")] "and" [has PRU (str "getPetAllTopicRewardByTemplateId")]] [
        (forIn ({
          _,
          id,
          c,
        }: {
          names = [_ id];
          values = [[kv [(dot PRU "getPetResearchSpeciesList") area]]];
          body = [
            (local c [(index CD id)])
            (if' [[tab c] "and" (dot c "isShow") "~=" 0 "and" [(not [has PRU (str "checkPetHasFormInCountry")]) "or" [(dot PRU "checkPetHasFormInCountry") id area]] "and" [(dot PRU "_checkPetHasTopicReward") id hb]] ({list}: [
              (local list [[(dot PRU "getPetAllTopicRewardByTemplateId") id]])
              (if' [[len' list] ">" 0] [
                [add [k (str "petres") (str "topic") id [len' list]] [(str "Pet topic rewards ") ".." [tostring id]] (str "petTopic") [pack list]]
              ])
            ]))
          ];
        }))
      ])
    ];
  }))
  blank
  (localFunction bossRush ({
    add,
    seen,
    BU,
    SR,
    any,
    cur,
    star,
  }: {
    params = [add seen];
    body = [
      (local [BU SR] [[req (str "Utils.BossRushUtils")] [req (str "Data.bossrush_season_reward_data")]])
      (if' (not [BU "and" SR "and" [has BU (str "hasUnreceivedSeasonReward")] "and" [has BU (str "getCurSeasonStar")] "and" [has BU (str "isSeasonRewardReceived")]]) (inline [(return [(str "deps")])]))
      (local any [[[(dot BU "hasUnreceivedSeasonReward")] "and" true "or" false]])
      [seen (str "hud") any]
      (if' (not any) (inline [(return [])]))
      (local [cur star] [[[tonumber (dot pg "me.curBossRushSeasonId")] "or" 0] [[tonumber [(dot BU "getCurSeasonStar")]] "or" 0]])
      (forIn ({
        need,
        cfg,
      }: {
        names = [need cfg];
        values = [[kv SR]];
        body = [
          (if' [[type need] "==" (str "number") "and" need "<=" star "and" [tab cfg] "and" (not [(dot BU "isSeasonRewardReceived") need])] ({ok}: [
            (local ok [false])
            (forIn ({
              lo,
              row,
            }: {
              names = [lo row];
              values = [[kv cfg]];
              body = [
                (forIn ({
                  hi,
                  v,
                }: {
                  names = [hi v];
                  values = [[kv row]];
                  body = [
                    (if' [[type lo] "==" (str "number") "and" [type hi] "==" (str "number") "and" lo "<=" cur "and" cur "<=" hi "and" [tab v] "and" [[tonumber (dot v "awardId")] "or" 0] ">" 0] (inline [(assign ok [true])]))
                  ];
                }))
              ];
            }))
            (if' ok (inline [[add [k (str "bossrush") cur need] [(str "Boss rush season reward ") ".." need] (str "bossRush") [pack need]]]))
          ]))
        ];
      }))
    ];
  }))
  blank
  (localFunction inStage ({
    v,
    stage,
  }: {
    params = [v stage];
    body = [
      (if' [[type v] "==" (str "number")] (inline [(return [[v "==" stage]])]))
      (forIn ({
        _,
        x,
      }: {
        names = [_ x];
        values = [[kv v]];
        body = inline [(if' [x "==" stage] (inline [(return [true])]))];
      }))
      (return [false])
    ];
  }))
  blank
  (localFunction homeSeason ({
    add,
    seen,
    HU,
    KC,
    R,
    _,
    C,
    me,
    s,
    REWARD,
    MT,
    CR,
    HSD,
    HMD,
    DT,
    MR,
    season,
  }: {
    params = [add seen];
    body = [
      (local [HU KC R] [[req (str "Utils.HomeSeasonUtils")] [req (str "Common.Const.Const")] [req (str "Const.RedDotConst")]])
      (local [_ C] [[act]])
      (local me [(dot pg "me")])
      (if' (not [HU "and" KC "and" R "and" C "and" [tab (dot KC "HOMELAND_SEASON_MODULE_TYPE")] "and" [has HU (str "isSeasonAvailable")]]) (inline [(return [(str "deps")])]))
      (if' (not [(dot HU "isSeasonAvailable") me]) (inline [(return [(str "closed")])]))
      (local [s REWARD MT] [(dot me "homeSeasonId") (dot R "RedDotStyle.REWARD") (dot KC "HOMELAND_SEASON_MODULE_TYPE")])
      (local CR [[req (str "Data.home_season_collection_reward_data")]])
      (if' [CR "and" [has HU (str "getProgressRewardRedDotStyle")]] ({style}: [
        (local style [[(dot HU "getProgressRewardRedDotStyle") me]])
        [seen (str "progress") style]
        (if' [style "==" REWARD] ({st}: [
          (local st [(dot me "homeSeasonCollectionRewardStateMap")])
          (forIn ({
            id,
            cfg,
          }: {
            names = [id cfg];
            values = [[kv CR]];
            body = [
              (if' [[tab cfg] "and" (dot cfg "seasonId") "==" s "and" [tab st] "and" (index st id) "==" (dot HU "COLLECTION_REWARD_STATE_CAN_RECEIVE")] [
                [add [k (str "homeseason") (str "progress") id] [(str "Home season progress reward ") ".." [tostring id]] (str "homeSeasonProgress") [pack id]]
              ])
            ];
          }))
        ]))
      ]))
      (local [HSD HMD DT MR] [[req (str "Data.home_season_data")] [req (str "Data.home_season_module_data")] [req (str "Data.home_season_daily_task_data")] [req (str "Data.home_season_mutation_collection_reward_data")]])
      (local season [[HSD "and" (index HSD s)]])
      (if' (not [HMD "and" [tab season] "and" [has HU (str "getHomeSeasonModuleRedDotStyle")]]) (inline [(return [])]))
      (forIn ({
        _,
        mid,
        md,
      }: {
        names = [_ mid];
        values = [[iv (dot season "funcRefIds")]];
        body = [
          (local md [(index HMD mid)])
          (if' [[tab md] "and" (dot md "seasonId") "==" s] ({style}: [
            (local style [[(dot HU "getHomeSeasonModuleRedDotStyle") me s mid (dot md "type")]])
            [seen [k (str "module") mid] style]
            (ifElse [style "==" REWARD "and" (dot md "type") "==" (dot MT "DAILY_QUEST") "and" DT] ({
                pend,
                stm,
              }: [
                (local [pend stm] [(dot me "homeSeasonTaskPendingRewardMap") (dot me "homeSeasonTaskStateMap")])
                (forIn ({
                  tid,
                  cfg,
                  p,
                }: {
                  names = [tid cfg];
                  values = [[kv DT]];
                  body = [
                    (local p [[[tonumber [[tab pend] "and" (index pend tid)]] "or" 0]])
                    (if' [[tab cfg] "and" (dot cfg "seasonId") "==" s "and" [p ">" 0 "or" [[inStage (dot cfg "stageId") (dot me "homeSeasonStageId")] "and" [tab stm] "and" (index stm tid) "==" (dot C "TaskState.Finihed_CanRecv")]]] [
                      [add [k (str "homeseason") (str "task") tid p] [(str "Home season daily task ") ".." [tostring tid]] (str "homeSeasonTask") [pack tid]]
                    ])
                  ];
                }))
              ]) (if' [style "==" REWARD "and" (dot md "type") "==" (dot MT "ITEM_COLLECT") "and" MR "and" [has HU (str "hasReceivableHomeSeasonMutationReward")] "and" [(dot HU "hasReceivableHomeSeasonMutationReward") me s]] ({
                stars,
                got,
                ids,
              }: [
                (local stars [[[tonumber [[tab (dot me "homeSeasonMutationStarBySeason")] "and" (index (dot me "homeSeasonMutationStarBySeason") s)]] "or" 0]])
                (local got [(dot me "homeSeasonMutationRewardReceived")])
                (local ids [(table [])])
                (forIn ({
                  id,
                  cfg,
                }: {
                  names = [id cfg];
                  values = [[kv MR]];
                  body = [
                    (if' [[tab cfg] "and" (dot cfg "seasonId") "==" s "and" [[tonumber (dot cfg "needPoint")] "or" 0] "<=" stars "and" (not [[tab got] "and" (index got id) "==" true])] (inline [(assign (index ids [(len ids) "+" 1]) [id])]))
                  ];
                }))
                (if' [(len ids) ">" 0] [
                  [add [k (str "homeseason") (str "mutation") s (len ids)] (str "Home season collection rewards") (str "homeSeasonMutation") [pack ids]]
                ])
              ])))
          ]))
        ];
      }))
    ];
  }))
  blank
  (localFunction questChapter ({
    add,
    seen,
    m,
    QC,
    done,
  }: {
    params = [add seen];
    body = [
      (local [m QC] [[uiModel (str "quest")] [req (str "Data.quest_catalog")]])
      (if' (not [m "and" QC "and" [has m (str "isChapterProgressRewardCanClaim")] "and" [has m (str "getChapterProgressRewardInfo")]]) (inline [(return [(str "deps")])]))
      (local done [(table [])])
      (forIn ({
        _,
        cat,
      }: {
        names = [_ cat];
        values = [[kv QC]];
        body = [
          (forIn ({
            _,
            ch,
          }: {
            names = [_ ch];
            values = [[iv [[tab cat] "and" (dot cat "chapters")]]];
            body = [
              (if' (not (index done ch)) ({s}: [
                (assign (index done ch) [true])
                (local s [[[(method m "isChapterProgressRewardCanClaim") ch] "and" true "or" false]])
                [seen ch s]
                (if' s ({info}: [
                  (local info [[(method m "getChapterProgressRewardInfo") ch]])
                  (forIn ({
                    _,
                    r,
                  }: {
                    names = [_ r];
                    values = [[iv [[tab info] "and" (dot info "rewardList")]]];
                    body = [
                      (if' [[tab r] "and" (dot r "canClaim") "and" (dot info "configId")] [
                        [add [k (str "quest") (str "chapter") (dot info "configId") (dot r "rewardIndex")] [(str "Quest chapter reward ") ".." [tostring ch] ".." (str " #") ".." [tostring (dot r "rewardIndex")]] (str "questChapter") [pack (dot info "configId") (dot r "rewardIndex")]]
                      ])
                    ];
                  }))
                ]))
              ]))
            ];
          }))
        ];
      }))
    ];
  }))
  blank
  (localFunction puppetScore ({
    add,
    seen,
    A,
    C,
    me,
    eid,
    list,
    done,
  }: {
    params = [add seen];
    body = [
      (local [A C] [[act]])
      (local me [(dot pg "me")])
      (if' (not [A "and" C "and" [has A (str "getLuckyPetCanRewardList")] "and" [has me (str "reqActivityCatchScoreReward")]]) (inline [(return [(str "deps")])]))
      (local eid [(index [openEvents (dot C "EventType.PuppetCatch")] 1)])
      (if' (not eid) (inline [(return [(str "closed")])]))
      (local [list done] [[(dot A "getLuckyPetCanRewardList") me] (dot me "luckyPetDayRewarded")])
      (forNum ({
        i,
        ready,
      }: {
        name = i;
        range = [1 [len' list]];
        body = [
          (local ready [[(index list i) "and" (not [[tab done] "and" (index done i)])]])
          [seen i ready]
          (if' ready ({arg}: [
            (local arg [[[i ">" 1 "and" (index list [i "-" 1]) "==" true "and" [tab done] "and" (index done [i "-" 1]) "==" true] "and" (-1) "or" i]])
            [add [k (str "puppet") (str "score") eid i] [(str "Puppet catch score reward ") ".." i] (str "puppet") [pack eid arg]]
          ]))
        ];
      }))
    ];
  }))
  blank
  (localFunction photoSurvey ({
    add,
    seen,
    A,
    C,
    me,
    eid,
    list,
    done,
  }: {
    params = [add seen];
    body = [
      (local [A C] [[act]])
      (local me [(dot pg "me")])
      (if' (not [A "and" C "and" [has A (str "getFormResearchCanRewardList")] "and" [has me (str "reqActivityPhotoRewardGet")] "and" [has me (str "reqActivityPhotoExtraRewardGet")] "and" [has me (str "reqActivityPhotoStageRewardGet")]]) (inline [(return [(str "deps")])]))
      (local eid [(index [openEvents (dot C "EventType.PuppetPhoto")] 1)])
      (if' (not eid) (inline [(return [(str "closed")])]))
      [seen (str "finish") (dot me "formResearchFinish")]
      (if' [(dot me "formResearchFinish") "==" true "and" (dot me "formResearchRewarded") "~=" true] [
        [add [k (str "photo") (str "reward") eid] (str "Photo survey reward") (str "photoReward") [pack eid]]
      ])
      (if' [(dot me "formResearchObRewardFin") "==" true "and" (dot me "formResearchObRewardRew") "~=" true] [
        [add [k (str "photo") (str "extra") eid] (str "Photo survey extra reward") (str "photoExtra") [pack eid]]
      ])
      (local [list done] [[(dot A "getFormResearchCanRewardList") me] (dot me "formResearchStageRewarded")])
      (forNum ({
        i,
        ready,
      }: {
        name = i;
        range = [1 [len' list]];
        body = [
          (local ready [[(index list i) "and" (not [[tab done] "and" (index done i)])]])
          [seen i ready]
          (if' ready ({arg}: [
            (local arg [[[i ">" 1 "and" (index list [i "-" 1]) "==" true "and" [tab done] "and" (index done [i "-" 1]) "==" true] "and" (-1) "or" i]])
            [add [k (str "photo") (str "stage") eid i] [(str "Photo survey stage reward ") ".." i] (str "photoStage") [pack eid arg]]
          ]))
        ];
      }))
    ];
  }))
  blank
  (localFunction petSaveWeek ({
    add,
    seen,
    _,
    C,
    CA,
    M,
    eid,
  }: {
    params = [add seen];
    body = [
      (local [_ C CA] [[act]])
      (local M [[req (str "Guis.Panels.EventPetSaveManual.EventPetSaveManualModel")]])
      (if' (not [C "and" [has CA (str "checkPetSaveCurWeek")] "and" [has M (str "getWeekArrival")] "and" [has M (str "receivedWeekSumyReward")] "and" [has M (str "getSubActId")] "and" [has (dot pg "me") (str "reqActivityPetSaveWeekSumyReward")]]) (inline [(return [(str "deps")])]))
      (local eid [(index [openEvents (dot C "EventType.PetSave")] 1)])
      (if' (not eid) (inline [(return [(str "closed")])]))
      (forNum ({
        week,
        sub,
        ready,
      }: {
        name = week;
        range = [1 [[tonumber [(dot CA "checkPetSaveCurWeek")]] "or" 0]];
        body = [
          (local sub [[(dot M "getSubActId") M week]])
          (local ready [[[(dot M "getWeekArrival") M week] "and" (not [(dot M "receivedWeekSumyReward") M sub])]])
          [seen week [ready "and" true "or" false]]
          (if' ready [
            [add [k (str "petsave") (str "week") eid sub] [(str "Pet save weekly summary ") ".." week] (str "petSave") [pack eid sub]]
          ])
        ];
      }))
    ];
  }))
  blank
  (localFunction energyMatch ({
    add,
    seen,
    A,
    C,
    CA,
    TD,
    me,
    eid,
    theme,
    id,
    row,
  }: {
    params = [add seen];
    body = [
      (local [A C CA] [[act]])
      (local TD [[req (str "Data.energy_match_theme_data")]])
      (local me [(dot pg "me")])
      (if' (not [A "and" C "and" TD "and" [has A (str "getNewEnergyTheme")] "and" [has A (str "getEnergyThemeId")] "and" [has CA (str "redDotReward_CheckVitalityRewardItem")] "and" [has me (str "serverActivityMsg")]]) (inline [(return [(str "deps")])]))
      (local eid [(index [openEvents (dot C "EventType.EnergyMatch")] 1)])
      (if' (not eid) (inline [(return [(str "closed")])]))
      (local [theme id] [[(dot A "getNewEnergyTheme") me] [(dot A "getEnergyThemeId") me]])
      (local row [[[tab (index TD theme)] "and" (index (index TD theme) id)]])
      (forIn ({
        i,
        r,
        ready,
      }: {
        names = [i r];
        values = [[iv [[tab row] "and" (dot row "award")]]];
        body = [
          (local ready [[[(dot CA "redDotReward_CheckVitalityRewardItem") theme id i] "and" true "or" false]])
          [seen i ready]
          (if' [ready "and" [tab r] "and" (dot r "index") "~=" nil] [
            [add [k (str "energy") (str "award") eid (dot r "index")] [(str "Vitality contest reward ") ".." [tostring (dot r "index")]] (str "energy") [pack eid (str "RPC_CS_GetEnergyMatchAward") (dot r "index")]]
          ])
        ];
      }))
    ];
  }))
  blank
  (localFunction petArea ({
    add,
    seen,
    map,
    any,
  }: {
    params = [add seen];
    body = [
      (local map [[(dot pg "game") "and" (dot pg "game.map")]])
      (if' (not [has map (str "getPetAreaRewardsState")]) (inline [(return [(str "deps")])]))
      (local any [false])
      (forIn ({
        _,
        e,
      }: {
        names = [_ e];
        values = [[iv [(method map "getPetAreaRewardsState")]]];
        body = [
          (if' [[tab e] "and" (dot e "smallAreaId") "~=" nil "and" [tab (dot e "rewardState")]] [
            (forNum ({stage}: {
              name = stage;
              range = [1 3];
              body = [
                (if' (index (dot e "rewardState") stage) [
                  (assign any [true])
                  [add [k (str "petarea") (dot e "smallAreaId") stage] [(str "Pet area reward ") ".." [tostring (dot e "smallAreaId")] ".." (str " stage ") ".." stage] (str "petArea") [pack (dot e "smallAreaId") stage]]
                ])
              ];
            }))
          ])
        ];
      }))
      [seen (str "any") any]
    ];
  }))
  blank
  (localFunction homeCampDispatch ({
    add,
    seen,
    HLU,
    UI,
    car,
    ready,
  }: {
    params = [add seen];
    body = [
      (local [HLU UI] [[req (str "Common.Utils.HomeLandUtils")] [req (str "Const.UIConst")]])
      (if' (not [HLU "and" UI "and" [tab (dot UI "HOME_CAMP_DISPATCH_STATE")] "and" [has HLU (str "getCampCarEntity")] "and" (dot pg "me")]) (inline [(return [(str "deps")])]))
      (local car [[(dot pg "me.uid") "~=" nil "and" [(dot HLU "getCampCarEntity") (dot pg "me.uid")]]])
      (if' (not [[tab car] "and" [has car (str "getPetsDispatchInfo")] "and" [has car (str "getCampPetDispatchState")] "and" [has car (str "finishDispatch")]]) (inline [(return [(str "nocar")])]))
      (local ready [[[(method car "getPetsDispatchInfo")] "and" [(method car "getCampPetDispatchState")] "==" (dot UI "HOME_CAMP_DISPATCH_STATE.Finished") "and" true "or" false]])
      [seen (str "camp") ready]
      (if' ready ({did}: [
        (local did [[[has car (str "getDispatchId")] "and" [(method car "getDispatchId")] "or" 0]])
        [add [k (str "homecamp") (str "dispatch") did] (str "Home camp pet dispatch finish") (str "homeCampFinish") [pack] car]
      ]))
    ];
  }))
  blank
  (localFunction probe ({row}: {
    params = [row];
    body = [
      (return [
        (table [
          (dot row "name")
          (fn ({
            add,
            seen,
            M,
            want,
            v,
            ready,
            key',
          }: {
            params = [add seen];
            body = [
              (local M [[(dot row "ui") "and" [uiModel (dot row "ui")] "or" [req (dot row "mod")]]])
              (if' (not [has M (dot row "fn")]) (inline [(return [(str "deps")])]))
              (local want [])
              (ifElse [(dot row "is") "==" (str "reward")] ({R}: [
                  (local R [[req (str "Const.RedDotConst")]])
                  (assign want [[R "and" [tab (dot R "RedDotStyle")] "and" (dot R "RedDotStyle.REWARD")]])
                ]) (if' (dot row "is") [
                  (assign want [[req (index (dot row "is") 1)]])
                  (forNum ({i}: {
                    name = i;
                    range = [2 (len (dot row "is"))];
                    body = inline [(assign want [[[tab want] "and" (index want (index (dot row "is") i)) "or" nil]])];
                  }))
                ]))
              (if' [(dot row "is") "and" want "==" nil] (inline [(return [(str "deps")])]))
              (local v [])
              (ifElse (dot row "ui") (inline [(assign v [[(index M (dot row "fn")) M]])]) (inline [(assign v [[(index M (dot row "fn"))]])]))
              (local ready [])
              (ifElse [want "~=" nil] (inline [(assign ready [[v "==" want]])]) (inline [(assign ready [[v "and" true "or" false]])]))
              [seen (str "state") [want "~=" nil "and" v "or" ready]]
              (if' (not ready) (inline [(return [])]))
              (local key' [[(dot row "stamp") "and" [k (dot row "name") (index (dot pg "me") (dot row "stamp"))] "or" (dot row "name")]])
              [add key' (dot row "label") (dot row "claim") [pack] [(dot row "ui") "and" M "or" nil]]
            ];
          }))
          (field "covers" (table [(dot row "fn")]))
        ])
      ])
    ];
  }))
  blank
  (local SOURCES [
    (table (rows [
      [(table [(str "daily") dailyActive]) (table [(str "battlepass") battlePass]) (table [(str "bpcycle") bpCycle]) (table [(str "season") seasonAchievement]) (table [(str "sign") sign])]
      [(table [(str "cross") crossPlatform]) (table [(str "firsttopup") firstTopup]) (table [(str "journey") journeyTrial]) (table [(str "dispatch") petDispatch]) (table [(str "growth") growthGift])]
      [(table [(str "littlefire") littleFire]) (table [(str "fishing") fishingCapture (field "covers" (table [(str "getFishingCaptureRedDotState")]))]) (table [(str "leylineup") leylineTreeUp]) (table [(str "redbook") redBook])]
      (apply probe (table [(field "name" (str "rogue-weekly")) (field "mod" (str "Utils.RogueUtils")) (field "fn" (str "getRedDotWeeklyState")) (field "is" (str "reward")) (field "claim" (str "rogueWeekly")) (field "label" (str "Tower weekly boss reward"))]))
      (apply probe (table [(field "name" (str "rogue-seasonweekly")) (field "mod" (str "Utils.RogueUtils")) (field "fn" (str "getRedDotSeasonWeeklyRewardState")) (field "is" (str "reward")) (field "claim" (str "rogueSeasonWeekly")) (field "label" (str "Tower season weekly reward"))]))
      (apply probe (table [(field "name" (str "rogue-daily")) (field "mod" (str "Utils.RogueUtils")) (field "fn" (str "getRedDotDailyState")) (field "is" (str "reward")) (field "claim" (str "rogueDaily")) (field "label" (str "Tower daily harvest"))]))
      (apply probe (table [(field "name" (str "monthcard")) (field "mod" (str "GameApp.MonthCard.MonthCardUtils")) (field "fn" (str "hasStoredReward")) (field "claim" (str "monthCardStored")) (field "label" (str "Month card stored reward"))]))
      (apply probe (table [(field "name" (str "homebook")) (field "mod" (str "Utils.HomeBookRedDotUtils")) (field "fn" (str "canReceiveScoreReward")) (field "claim" (str "homeBookGrade")) (field "label" (str "Home handbook grade reward"))]))
      (table [(str "homebookcat") homeBookCategory])
      (apply probe (table [(field "name" (str "grabeggs")) (field "mod" (str "Guis.Utils.GrabEggsRankUtils")) (field "fn" (str "hasClaimableReward")) (field "claim" (str "grabEggsRank")) (field "label" (str "Grab-eggs season rank reward"))]))
      [(table [(str "grabeggsmode") grabEggsMode]) (table [(str "course") course]) (table [(str "playerlv") playerLevel (field "covers" (table [(str "redDot_CheckHasLvReward")]))]) (table [(str "gacha") lotteryTimes]) (table [(str "strain") specialTrain (field "covers" (table [(str "redDot_GetSpecialTrainState") (str "redDot_GetChapterPageState") (str "redDot_GetBadgeState")]))])]
      [(table [(str "petres") petResearch (field "covers" (table [(str "redDot_GetPetResearchState")]))]) (table [(str "bossrush") bossRush])]
      (apply probe (table [(field "name" (str "homecar")) (field "ui" (str "homeCarLevelUp")) (field "fn" (str "redDot_GetLevelRewardState")) (field "is" (str "reward")) (field "claim" (str "homeCarLevel")) (field "label" (str "Home car level rewards"))]))
      [(table [(str "homeseason") homeSeason]) (table [(str "quest") questChapter])]
      (apply probe (table [(field "name" (str "monthcarddaily")) (field "mod" (str "GameApp.MonthCard.MonthCardUtils")) (field "fn" (str "getDailyRewardState")) (field "is" (table [(str "GameApp.MonthCard.MonthCardConst") (str "DAILY_REWARD_STATE") (str "AVAILABLE")])) (field "stamp" (str "mcLastReceiveDailyAwardTm")) (field "claim" (str "monthCardDaily")) (field "label" (str "Month card daily reward"))]))
      [(table [(str "puppet") puppetScore]) (table [(str "photo") photoSurvey]) (table [(str "petsave") petSaveWeek]) (table [(str "energy") energyMatch])]
      [(table [(str "petarea") petArea]) (table [(str "homecamp") homeCampDispatch])]
    ]))
  ])
  blank
  (local skipped [(table [])])
  blank
  (local missing [(table [])])
  blank
  (localFunction receiver ({
    spec,
    player,
    recv,
    v,
  }: {
    params = [spec player recv];
    body = [
      (if' [recv "~=" nil] (inline [(return [recv])]))
      (if' (not (dot spec "on")) (inline [(return [player])]))
      (local v [pg])
      (forIn ({part}: {
        names = [part];
        values = [[(method (dot spec "on") "gmatch") (str "[^.]+")]];
        body = inline [(assign v [[[tab v] "and" (index v part) "or" nil]])];
      }))
      (return [v])
    ];
  }))
  blank
  (localFunction perform ({
    a,
    spec,
    list,
    n,
  }: {
    params = [a];
    body = [
      (local [spec list n] [(index CLAIMS (dot a "claim")) (table []) (dot a "args.n")])
      (forNum ({i}: {
        name = i;
        range = [1 n];
        body = inline [(assign (index list i) [(index (dot a "args") i)])];
      }))
      (forIn ({
        _,
        v,
      }: {
        names = [_ v];
        values = [[ipairs [(dot spec "tail") "or" (table [])]]];
        body = [
          (assign n [[n "+" 1]])
          (assign (index list n) [v])
        ];
      }))
      (if' (dot spec "fn") (inline [(return [[(dot spec "fn") (dot a "recv") [unpack list 1 n]]])]))
      (if' (dot spec "rpc") (inline [(return [[(method (dot a "recv") "serverMsg") (dot spec "rpc") [unpack list 1 n]]])]))
      (return [[(index (dot a "recv") (dot spec "call")) (dot a "recv") [unpack list 1 n]]])
    ];
  }))
  blank
  (localFunction nextAction ({
    tried,
    player,
    found,
    add,
  }: {
    params = [tried player];
    body = [
      (local found [])
      (localFunction add ({
        key',
        label,
        claim,
        args,
        recv,
        spec,
        on,
      }: {
        params = [key' label claim args recv];
        body = [
          (if' [found "or" (index tried key')] (inline [(return [])]))
          (local spec [(index CLAIMS claim)])
          (local on [[spec "and" [receiver spec player recv]]])
          (if' (not [spec "and" [(dot spec "fn") "or" [has on [(dot spec "rpc") "and" (str "serverMsg") "or" (dot spec "call")]]]]) [
            (if' (not (index missing claim)) [
              (assign (index missing claim) [true])
              [log (str "skip") claim (str "claim target missing")]
            ])
            (return [])
          ])
          (assign found [(table [(field "key" key') (field "label" label) (field "claim" claim) (field "args" args) (field "recv" on)])])
        ];
      }))
      (forIn ({
        _,
        src,
        ok,
        err,
      }: {
        names = [_ src];
        values = [[ipairs SOURCES]];
        body = [
          (if' found (inline [break]))
          (local [ok err] [[pcall (index src 2) add noop]])
          (if' [(not ok) "and" (not (index skipped (index src 1)))] [
            (assign (index skipped (index src 1)) [true])
            [log (str "skip") (index src 1) [field' err]]
          ])
        ];
      }))
      (return [found])
    ];
  }))
  blank
  (localFunction short ({
    v,
    n,
    s,
  }: {
    params = [v n];
    body = [
      (local s [[field' v]])
      (if' [(len s) ">" n] (inline [(assign s [[[(method s "sub") 1 n] ".." (str "~")]])]))
      (return [s])
    ];
  }))
  blank
  (localFunction counts ({
    map,
    keys,
  }: {
    params = [map];
    body = [
      (local keys [(table [])])
      (forIn ({key'}: {
        names = [key'];
        values = [[pairs map]];
        body = inline [(assign (index keys [(len keys) "+" 1]) [key'])];
      }))
      [(dot table' "sort") keys]
      (forIn ({
        i,
        key',
      }: {
        names = [i key'];
        values = [[ipairs keys]];
        body = inline [(assign (index keys i) [[key' ".." (str ":") ".." (index map key')]])];
      }))
      (return [[(dot table' "concat") keys (str ",")]])
    ];
  }))
  blank
  (localFunction hot ({key'}: {
    params = [key'];
    body = inline [(return [[key' "==" (str "2") "or" key' "==" (str "true") "or" key' "==" (str "Reward")]])];
  }))
  blank
  (localFunction diagSource ({
    name,
    fn',
    n,
    ready,
    states,
    heated,
    cold,
    seen,
    add,
    ok,
    why,
    parts,
  }: {
    params = [name fn'];
    body = [
      (local [n ready states heated cold] [0 0 (table []) (table []) (table [])])
      (localFunction seen ({
        id,
        st,
        key',
        list,
      }: {
        params = [id st];
        body = [
          (assign n [[n "+" 1]])
          (local key' [[short st 16]])
          (assign (index states key') [[[(index states key') "or" 0] "+" 1]])
          (local list [[[hot key'] "and" heated "or" cold]])
          (if' [(len list) "<" 5] (inline [(assign (index list [(len list) "+" 1]) [[[short id 24] ".." (str "=") ".." key']])]))
        ];
      }))
      (localFunction add (inline [(assign ready [[ready "+" 1]])]))
      (local [ok why] [[pcall fn' add seen]])
      (forIn ({
        _,
        x,
      }: {
        names = [_ x];
        values = [[ipairs cold]];
        body = inline [(if' [(len heated) "<" 5] (inline [(assign (index heated [(len heated) "+" 1]) [x])]))];
      }))
      (local parts [(table [[(str "ready=") ".." ready] [(str "seen=") ".." n]])])
      (if' [n ">" 0] (inline [(assign (index parts [(len parts) "+" 1]) [[(str "states=") ".." [counts states]]])]))
      (if' [(len heated) ">" 0] (inline [(assign (index parts [(len parts) "+" 1]) [[(str "sample=") ".." [(dot table' "concat") heated (str ",")]]])]))
      (ifElse (not ok) (inline [(assign (index parts [(len parts) "+" 1]) [[(str "err=") ".." [short why 160]]])]) (if' why (inline [(assign (index parts [(len parts) "+" 1]) [[(str "exit=") ".." [tostring why]]])])))
      [log (str "diag") name [(dot table' "concat") parts (str " ")] true]
    ];
  }))
  blank
  (local DATA [(table [(str "event_task_data") (str "game_event_data") (str "game_event_type_post_data") (str "event_season_achievement_data") (str "event_battlepass_data") (str "activate_tasks_data") (str "guide_course_grade_data") (str "quest_catalog")])])
  blank
  (localFunction diagModules ({parts}: [
    (local parts [(table [])])
    (forIn ({
      _,
      name,
      ok,
      m,
      row,
    }: {
      names = [_ name];
      values = [[ipairs DATA]];
      body = [
        (local [ok m] [[pcall require [(str "Data.") ".." name]]])
        (local row [(str "-")])
        (if' [ok "and" [tab m]] (inline [
          [
            pcall
            (fn (inline [
              (forIn ({
                _,
                v,
              }: {
                names = [_ v];
                values = [[pairs m]];
                body = inline [(assign row [[type v]]) break];
              }))
            ]))
          ]
        ]))
        (assign (index parts [(len parts) "+" 1]) [[name ".." (str "=") ".." [ok "and" [type m] "or" (str "err")] ".." (str "/") ".." row]])
      ];
    }))
    [log (str "diag") (str "data") [(dot table' "concat") parts (str " ")] true]
  ]))
  blank
  (localFunction flag ({
    f,
    ok,
    v,
  }: {
    params = [f vararg];
    body = [
      (if' [[type f] "~=" (str "function")] (inline [(return [(str "?")])]))
      (local [ok v] [[pcall f vararg]])
      (if' (not ok) (inline [(return [(str "E")])]))
      (return [[v "and" (str "1") "or" (str "0")]])
    ];
  }))
  blank
  (localFunction diagActivity ({
    A,
    C,
    CA,
    POST,
    names,
    ets,
  }: [
    (local [A C CA] [[act]])
    (if' (not [A "and" C]) (inline [(return [[log (str "diag") (str "act") (str "deps") true]])]))
    (local POST [[req (str "Data.game_event_type_post_data")]])
    (local names [(dot C "NewFrameEventAttriName")])
    (local ets [(table [])])
    (forIn ({et}: {
      names = [et];
      values = [[kv names]];
      body = inline [(assign (index ets [(len ets) "+" 1]) [et])];
    }))
    [(dot table' "sort") ets]
    (forIn ({
      _,
      et,
      ok,
      err,
    }: {
      names = [_ et];
      values = [[ipairs ets]];
      body = [
        (local [ok err] [
          [
            pcall
            (fn ({
              attr,
              parts,
              d,
              base,
              st,
              n,
              eids,
              m,
            }: [
              (local attr [(index names et)])
              (local parts [(table [[(str "attr=") ".." [tostring attr]] [(str "raw=") ".." [(index (dot pg "me") attr) "~=" nil "and" (str "1") "or" (str "0")]]])])
              (local d [[[has A (str "getActivityData")] "and" [(dot A "getActivityData") (dot pg "me") et] "or" nil]])
              (local base [[[tab d] "and" (dot d "activityBase")]])
              (assign (index parts [(len parts) "+" 1]) [[(str "aid=") ".." [field' [[tab base] "and" (dot base "activityId") "or" nil]]]])
              (local [st n] [(table []) 0])
              (forIn ({
                _,
                t,
                key',
              }: {
                names = [_ t];
                values = [[kv [[tab base] "and" (dot base "activityTasks")]]];
                body = [
                  (assign n [[n "+" 1]])
                  (local key' [[short [[tab t] "and" (dot t "state") "or" nil] 8]])
                  (assign (index st key') [[[(index st key') "or" 0] "+" 1]])
                ];
              }))
              (assign (index parts [(len parts) "+" 1]) [[(str "tasks=") ".." n]])
              (if' [n ">" 0] (inline [(assign (index parts [(len parts) "+" 1]) [[(str "states=") ".." [counts st]]])]))
              (local [eids m] [(table []) 0])
              (forIn ({eid}: {
                names = [eid];
                values = [[kv [POST "and" (index POST et)]]];
                body = [
                  (assign m [[m "+" 1]])
                  (if' [m "<=" 4] [
                    (assign (index eids [(len eids) "+" 1]) [[[tostring eid] ".." (str ":T") ".." [flag (dot A "isOprActivityTabOpen") eid (dot pg "me")] ".." (str "G") ".." [flag (dot CA "isGameEventTabOpen") eid] ".." (str "O") ".." [flag (dot A "isOprActivityOpen") eid] ".." (str "E") ".." [flag (dot CA "isEventOpen") eid]]])
                  ])
                ];
              }))
              (assign (index parts [(len parts) "+" 1]) [[(str "eids=") ".." m ".." [(len eids) ">" 0 "and" [(str "[") ".." [(dot table' "concat") eids (str ",")] ".." (str "]")] "or" (str "")]]])
              [log (str "diag") [(str "act ") ".." [tostring et]] [(dot table' "concat") parts (str " ")] true]
            ]))
          ]
        ])
        (if' (not ok) (inline [[log (str "diag") [(str "act ") ".." [tostring et]] [(str "err=") ".." [short err 160]] true]]))
      ];
    }))
  ]))
  blank
  (localFunction diag ({
    ok,
    err,
  }: [
    [log (str "diag") (str "begin") [(len SOURCES) ".." (str " sources")] true]
    [pcall diagModules]
    (forIn ({
      _,
      src,
    }: {
      names = [_ src];
      values = [[ipairs SOURCES]];
      body = inline [[pcall diagSource (index src 1) (index src 2)]];
    }))
    (local [ok err] [[pcall diagActivity]])
    (if' (not ok) (inline [[log (str "diag") (str "act") [(str "err=") ".." [short err 160]] true]]))
    [log (str "diag") (str "end") (str "-") true]
  ]))
  blank
  (local DOT_FN [(table [(str "^redDot_Get") (str "^redDot_Check") (str "^getRedDot%w*State$")])])
  (local DOT_SKIP [(table [(str "Path") (str "Key") (str "Numb") (str "Num") (str "Save")])])
  blank
  (localFunction dotName ({
    key',
    hit,
  }: {
    params = [key'];
    body = [
      (if' [[type key'] "~=" (str "string")] (inline [(return [false])]))
      (local hit [false])
      (forIn ({
        _,
        p,
      }: {
        names = [_ p];
        values = [[ipairs DOT_FN]];
        body = [
          (if' [(method key' "find") p] (inline [(assign hit [true])]))
        ];
      }))
      (if' (not hit) (inline [(return [false])]))
      (forIn ({
        _,
        x,
      }: {
        names = [_ x];
        values = [[ipairs DOT_SKIP]];
        body = [
          (if' [(method key' "find") x 1 true] (inline [(return [false])]))
        ];
      }))
      (return [true])
    ];
  }))
  blank
  (localFunction get ({
    t,
    key',
    ok,
    v,
  }: {
    params = [t key'];
    body = [
      (if' (not [tab t]) (inline [(return [nil])]))
      (local [ok v] [[pcall (fn (inline [(return [(index t key')])]))]])
      (return [[ok "and" v "or" nil]])
    ];
  }))
  blank
  (localFunction dotMethods ({
    owner,
    out,
    seen,
    queue,
    i,
  }: {
    params = [owner];
    body = [
      (local [out seen queue i] [(table []) (table []) (table [owner]) 1])
      (while [(index queue i) "and" i "<=" 12] ({t}: [
        (local t [(index queue i)])
        (assign i [[i "+" 1]])
        (if' [[tab t] "and" (not (index seen t))] ({
          ok,
          mt,
          idx,
          sup,
        }: [
          (assign (index seen t) [true])
          (forIn ({
            key',
            v,
          }: {
            names = [key' v];
            values = [[kv t]];
            body = [
              (if' [[type v] "==" (str "function") "and" [dotName key']] (inline [(assign (index out [(len out) "+" 1]) [key'])]))
            ];
          }))
          (local [ok mt] [[pcall getmetatable t]])
          (local idx [[ok "and" [type mt] "==" (str "table") "and" [rawget mt (str "__index")] "or" nil]])
          (if' [tab idx] (inline [(assign (index queue [(len queue) "+" 1]) [idx])]))
          (local sup [[get t (str "super")]])
          (if' [tab sup] (inline [(assign (index queue [(len queue) "+" 1]) [sup])]))
        ]))
      ]))
      [(dot table' "sort") out]
      (return [out])
    ];
  }))
  blank
  (localFunction dotOwners ({
    owners,
    ok,
    loaded,
    ui,
    models,
  }: [
    (local owners [(table [])])
    (local [ok loaded] [[pcall (fn (inline [(return [(dot package "loaded")])]))]])
    (if' [ok "and" [tab loaded]] [
      (forIn ({
        name,
        m,
      }: {
        names = [name m];
        values = [[kv loaded]];
        body = [
          (if' [[type name] "==" (str "string") "and" [type m] "==" (str "table")] (inline [(assign (index owners [(len owners) "+" 1]) [(table [name m false])])]))
        ];
      }))
    ])
    [
      (dot table' "sort")
      owners
      (fn ({
        a,
        b,
      }: {
        params = [a b];
        body = inline [(return [[(index a 1) "<" (index b 1)]])];
      }))
    ]
    (local [ui models] [[(dot pg "global") "and" (dot pg "global.ui")] (table [])])
    (forIn ({
      name,
      p,
      m,
    }: {
      names = [name p];
      values = [[kv ui]];
      body = [
        (local m [[get p (str "model")]])
        (if' [tab m] (inline [(assign (index models [(len models) "+" 1]) [(table [[(str "ui.") ".." [tostring name]] m true])])]))
      ];
    }))
    [
      (dot table' "sort")
      models
      (fn ({
        a,
        b,
      }: {
        params = [a b];
        body = inline [(return [[(index a 1) "<" (index b 1)]])];
      }))
    ]
    (forIn ({
      _,
      o,
    }: {
      names = [_ o];
      values = [[ipairs models]];
      body = inline [(assign (index owners [(len owners) "+" 1]) [o])];
    }))
    (return [owners])
  ]))
  blank
  (localFunction discover ({
    R,
    REWARD,
    covered,
    owners,
    st,
    done,
    lines,
  }: [
    (local R [[req (str "Const.RedDotConst")]])
    (local REWARD [[R "and" [tab (dot R "RedDotStyle")] "and" (dot R "RedDotStyle.REWARD")]])
    (if' [REWARD "==" nil] (inline [(return [[log (str "discover") (str "skipped") (str "no RedDotStyle.REWARD") true]])]))
    (local covered [(table [])])
    (forIn ({
      _,
      src,
    }: {
      names = [_ src];
      values = [[ipairs SOURCES]];
      body = [
        (forIn ({
          _,
          name,
        }: {
          names = [_ name];
          values = [[ipairs [(dot src "covers") "or" (table [])]]];
          body = inline [(assign (index covered name) [true])];
        }))
      ];
    }))
    (local owners [[dotOwners]])
    (local st [(table [(field "owners" (len owners)) (field "fns" 0) (field "reward" 0) (field "covered" 0) (field "errors" 0)])])
    (local [done lines] [(table []) (table [])])
    (forIn ({
      _,
      o,
      ok,
      names,
    }: {
      names = [_ o];
      values = [[ipairs owners]];
      body = [
        (local [ok names] [[pcall dotMethods (index o 2)]])
        (forIn ({
          _,
          key',
          fn',
          id,
        }: {
          names = [_ key'];
          values = [[ipairs [ok "and" names "or" (table [])]]];
          body = [
            (local fn' [[get (index o 2) key']])
            (local id [[(index o 3) "and" [[tostring (index o 2)] ".." key'] "or" fn']])
            (if' [[type fn'] "==" (str "function") "and" (not (index done id))] ({
              okc,
              v,
            }: [
              (assign (index done id) [true])
              (assign (dot st "fns") [[(dot st "fns") "+" 1]])
              (local [okc v] [])
              (ifElse (index o 3) [
                  (assign [okc v] [[pcall fn' (index o 2)]])
                ] [
                  (assign [okc v] [[pcall fn']])
                  (if' (not okc) (inline [(assign [okc v] [[pcall fn' (index o 2)]])]))
                ])
              (ifElse (not okc) [
                  (assign (dot st "errors") [[(dot st "errors") "+" 1]])
                ] (if' [v "==" REWARD] [
                  (assign (dot st "reward") [[(dot st "reward") "+" 1]])
                  (ifElse (index covered key') (inline [(assign (dot st "covered") [[(dot st "covered") "+" 1]])]) (inline [(assign (index lines [(len lines) "+" 1]) [(table [key' (index o 1)])])]))
                ]))
            ]))
          ];
        }))
      ];
    }))
    (forIn ({
      _,
      l,
    }: {
      names = [_ l];
      values = [[ipairs lines]];
      body = inline [[log (str "unclaimed") (index l 1) (index l 2) true]];
    }))
    [log (str "discover") (str "summary") [(str "owners=") ".." (dot st "owners") ".." (str " fns=") ".." (dot st "fns") ".." (str " reward=") ".." (dot st "reward") ".." (str " covered=") ".." (dot st "covered") ".." (str " unclaimed=") ".." (len lines) ".." (str " errors=") ".." (dot st "errors")] true]
  ]))
  blank
  (localFunction delay (inline [(return [[MIN_GAP "+" [(dot math "random")] "*" JITTER]])]))
  blank
  (localFunction run ({
    player,
    mode,
    gen,
    tried,
    last,
    cur,
    verb,
    TM,
    tick,
    stop,
    fail,
    again,
  }: {
    params = [player mode];
    body = [
      (assign (dot state "gen") [[(dot state "gen") "+" 1]])
      (local [gen tried last] [(dot state "gen") (table []) nil])
      (local cur [(table [(field "count" 0) (field "beat" [now])])])
      (assign (dot state "run") [cur])
      (local verb [[mode "==" (str "dry") "and" (str "would claim ") "or" (str "claimed ")]])
      (local TM [[require (str "Core.Timer.TimerManager")]])
      (local tick [])
      (localFunction stop ({
        why,
        text,
      }: {
        params = [why text];
        body = [
          (if' [gen "==" (dot state "gen")] (inline [(assign (dot state "gen") [[(dot state "gen") "+" 1]])]))
          (if' [(dot state "run") "==" cur] (inline [(assign (dot state "run") [nil])]))
          [log (str "stop") why (dot cur "count")]
          [toast [text "or" [(str "Rewards stopped (") ".." why ".." (str "), ") ".." verb ".." (dot cur "count")]]]
        ];
      }))
      (localFunction fail ({
        where,
        err,
      }: {
        params = [where err];
        body = [
          (assign (dot state "off") [true])
          [log (str "error") where [tostring err]]
          [stop (str "error") [(str "Rewards error at ") ".." where ".." (str ", off until restart")]]
        ];
      }))
      (localFunction again ({
        sec,
        ok,
        err,
      }: {
        params = [sec];
        body = [
          (local [ok err] [[pcall (dot TM "addTimer") sec tick]])
          (if' (not ok) (inline [[fail (str "timer") err]]))
        ];
      }))
      (assign tick [
        (fn ({
          s,
          t,
          res,
          ok,
          a,
        }: [
          (if' [gen "~=" (dot state "gen") "or" (dot state "off")] (inline [(return [])]))
          (assign (dot cur "beat") [[[now] "or" (dot cur "beat")]])
          (local s [[setting]])
          (if' [killed s] (inline [(return [[stop (str "kill switch")]])]))
          (if' [(dot pg "me") "~=" player "or" (dot player "destroyed")] (inline [(return [[stop (str "player changed")]])]))
          (local [t res] [[now]])
          (if' [t "and" last "and" t "-" last "<" MIN_GAP "-" 0.05 "+" res] (inline [(return [[again [delay]]])]))
          (if' [(dot cur "count") ">=" MAX_CLAIMS] (inline [(return [[stop [(str "cap of ") ".." MAX_CLAIMS ".." (str " reached")]]])]))
          (local [ok a] [[pcall nextAction tried player]])
          (if' (not ok) (inline [(return [[fail (str "readiness check") a]])]))
          (if' (not a) [
            [pcall discover]
            (return [[stop (str "nothing left") [(str "Rewards: ") ".." verb ".." (dot cur "count") ".." (str ", nothing left")]]])
          ])
          (assign [(index tried (dot a "key")) last] [true t])
          (ifElse [mode "==" (str "dry") "or" s "==" (str "dry")] [
              [log (str "dry") (dot a "label") (str "not sent")]
              [toast [(str "Rewards (dry run): ") ".." (dot a "label")]]
            ] ({
              ok2,
              err,
            }: [
              (local [ok2 err] [[pcall perform a]])
              (if' (not ok2) (inline [(return [[fail (dot a "label") err]])]))
              [log (str "claim") (dot a "label") (str "ok")]
              [toast [(str "Rewards: ") ".." (dot a "label")]]
            ]))
          (assign (dot cur "count") [[(dot cur "count") "+" 1]])
          [again [delay]]
        ]))
      ])
      [log (str "start") [mode "==" (str "dry") "and" (str "dry run") "or" (str "claim run")] (str "ok")]
      [pcall diag]
      [toast [mode "==" (str "dry") "and" (str "Rewards: dry run, nothing will be sent") "or" (str "Rewards: claiming, one every 1-2 s")]]
      [again [delay]]
    ];
  }))
  blank
  (localFunction onPress ({
    cur,
    t,
    s,
    me,
  }: [
    (if' (dot state "off") [
      [log (str "press") (str "ignored") (str "disabled after error")]
      (return [[toast (str "Rewards: off after an error, restart the game")]])
    ])
    (local [cur t] [(dot state "run") [now]])
    (if' [cur "and" t "and" (dot cur "beat") "and" t "-" (dot cur "beat") ">" STALE] [
      [log (str "press") (str "stale run dropped") (dot cur "count")]
      (assign [(dot state "run") (dot state "gen")] [nil [(dot state "gen") "+" 1]])
      (assign cur [nil])
    ])
    (if' cur [
      [log (str "press") (str "ignored") [(str "running, ") ".." (dot cur "count") ".." (str " so far")]]
      (return [[toast [(str "Rewards: already running, ") ".." (dot cur "count") ".." (str " so far")]]])
    ])
    (local s [[setting]])
    (if' [killed s] [
      [log (str "press") (str "ignored") (str "kill switch")]
      (return [[toast [(str "Rewards: off (ANIIMO_REWARDS=") ".." s ".." (str ")")]]])
    ])
    (local me [(dot pg "me")])
    (if' [[type me] "~=" (str "table")] (inline [(return [[log (str "press") (str "ignored") (str "no player")]])]))
    [run me [s "==" (str "dry") "and" (str "dry") "or" (str "claim")]]
  ]))
  blank
  (localFunction wrapButton ({
    view,
    btn,
    click,
  }: {
    params = [view];
    body = [
      (local btn [(dot view "btnAllReadUButton")])
      (local click [[btn "and" (dot btn "luaClick")]])
      (if' (not click) (inline [(return [[log (str "hook") (str "mail button") (str "no click handler")]])]))
      (assign (dot btn "luaClick") [
        (fn ({
          r,
          ok,
          err,
        }: {
          params = [vararg];
          body = [
            (local r [[pack [click vararg]]])
            (local [ok err] [[pcall onPress]])
            (if' (not ok) [
              (assign (dot state "off") [true])
              [log (str "error") (str "button press") [tostring err]]
            ])
            (return [[unpack r 1 (dot r "n")]])
          ];
        }))
      ])
    ];
  }))
  blank
  (localFunction hookMail ({
    M,
    base,
  }: [
    (if' (dot state "hooked") (inline [(return [])]))
    (local M [[req MAIL_VIEW]])
    (local base [[M "and" [rawget M (str "initView")]]])
    (if' [[type base] "~=" (str "function")] (inline [(return [[log (str "hook") (str "mail panel") (str "initView not found")]])]))
    (assign (dot state "hooked") [true])
    [
      rawset
      M
      (str "initView")
      (fn ({
        self,
        r,
        ok,
        err,
      }: {
        params = [self vararg];
        body = [
          (local r [[pack [base self vararg]]])
          (local [ok err] [[pcall wrapButton self]])
          (if' (not ok) (inline [[log (str "hook") (str "mail button") [tostring err]]]))
          (return [[unpack r 1 (dot r "n")]])
        ];
      }))
    ]
    [log (str "hook") (str "mail panel") (str "ok")]
  ]))
  blank
  (localFunction install ({
    cls,
    vt,
    base,
  }: {
    params = [cls];
    body = [
      (local vt [[[type cls] "==" (str "table") "and" [has cls (str "getVtbl")] "and" [(dot cls "getVtbl")]]])
      (local base [[[type vt] "==" (str "table") "and" [rawget vt (str "onBecomePlayer")]]])
      (if' [[type base] "~=" (str "function")] (inline [(return [[log (str "hook") (str "onBecomePlayer") (str "not found")]])]))
      [
        rawset
        vt
        (str "onBecomePlayer")
        (fn ({
          self,
          r,
          ok,
          err,
        }: {
          params = [self vararg];
          body = [
            (local r [[pack [base self vararg]]])
            (local [ok err] [[pcall hookMail]])
            (if' (not ok) (inline [[log (str "hook") (str "mail panel") [tostring err]]]))
            (return [[unpack r 1 (dot r "n")]])
          ];
        }))
      ]
    ];
  }))
  blank
  (local [ok err] [[pcall install (index ret 1)]])
  (if' (not ok) (inline [[log (str "hook") (str "install") [tostring err]]]))
  (return [[unpack ret 1 (dot ret "n")]])
])
