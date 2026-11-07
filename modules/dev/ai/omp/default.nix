{
  config,
  lib,
  pkgs,
  flakeInputs,
  inputPackages,
  generators,
  ...
}: let
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
  secrets = ./secrets;
  # omp loads its extensions through these links, not their store paths, so a switch that rebuilds one leaves
  # config.yml's paths alone and running sessions see no "newly enabled" extension to restart for. omp-bot's
  # env (the omp_bot module) names its extensions by the same links, so a bot loads each once.
  extDir = "${config.users.users.${config.user.name}.home}/.omp/agent/ext";
  extLinks =
    lib.genAttrs ["pi-chronobreak" "pi-recap" "omp-bot"] (name: "${flakeInputs.${name}}")
    // {
      pi-donsetch = "${inputPackages.pi-donsetch.default}";
      "compact-eval.ts" = ./compact-eval.ts;
      "work-fold.ts" = ./work-fold.ts;
      "crest-reroute.ts" = ./crest-reroute.ts;
      "chat-look.ts" = generators.sourceFile "chat-look.ts" (generators.ts.render (({
          Array,
          Symbol,
          WeakMap,
          array,
          arrow,
          async,
          below,
          blank,
          call,
          class,
          const,
          default,
          dot,
          export,
          fn,
          forOf,
          globalThis,
          idx,
          if',
          import',
          infix,
          let',
          method,
          new,
          not,
          obj,
          optCall,
          prop,
          return,
          return',
          spread,
          str,
          sub,
          ternary,
          this,
          tpl,
          undefined,
          ...
        }: ({
          AssistantMessageComponent,
          chatTranscriptDisplayPreferences,
          UserMessageComponent,
          TranscriptContainer,
          col,
          isNativeSettled,
          settleNative,
          Composer,
          STATE,
          HIDDEN,
          Marked,
          same,
          said,
          install,
          chatLook,
        }: [
          (import' [AssistantMessageComponent] (str "@oh-my-pi/pi-tui/chat/assistant-message"))
          (import' [chatTranscriptDisplayPreferences] (str "@oh-my-pi/pi-tui/chat/display-preferences"))
          (import' [UserMessageComponent] (str "@oh-my-pi/pi-tui/chat/user-message"))
          (import' [TranscriptContainer] (str "@oh-my-pi/pi-tui/chrome"))
          (import' [col] (str "@oh-my-pi/pi-tui/native/describe"))
          (import' [isNativeSettled settleNative] (str "@oh-my-pi/pi-tui/native/settle"))
          (import' [Composer] (str "@oh-my-pi/pi-tui/prompt/composer"))
          blank
          (const STATE (call (dot Symbol "for") [(str "finix.omp-chat-look.state")]))
          (const HIDDEN (below (str "\\n# Tool activity\\nYour tool calls are hidden from the transcript, so say in words what you found and what you ran rather than pointing at a card.\\n")))
          blank
          (class Marked [
            ({
              items,
              role,
            }: (method "constructor" [items role] [
              (infix [(dot this "items") "=" items])
              (infix [(dot this "node") "=" (call col [items (obj [role])])])
            ]))
            blank
            (method "invalidate" [] [
              ({item}: (forOf item (dot this "items") (optCall (dot item "invalidate") [])))
            ])
            blank
            ({width}: (method "render" [width] [
              (return (call (dot this "items.flatMap") [({item}: (arrow item (call (dot item "render") [width])))]))
            ]))
            blank
            (method "describe" [] [
              (return (dot this "node"))
            ])
          ])
          blank
          ({
            a,
            b,
          }: (fn same [a b] [
            (return (infix [
              (dot a "length")
              "==="
              (dot b "length")
              "&&"
              (call (dot a "every") [
                ({
                  item,
                  i,
                }: (arrow [item i] (infix [item "===" (idx b i)])))
              ])
            ]))
          ]))
          blank
          ({
            block,
            source,
          }: (fn said [block] [
            (const source (ternary (infix [(dot block "?.mode") "===" (str "thinking")]) undefined (infix [(dot block "?.source") "??" block])))
            (return (infix [source "instanceof" UserMessageComponent "||" source "instanceof" AssistantMessageComponent]))
          ]))
          blank
          ({
            transcript,
            composer,
            nativeBlocks,
            describeSurface,
            marked,
            advice,
            shownBy,
            docks,
            advises,
            mark,
          }: (fn install [] [
            (const transcript (dot TranscriptContainer "prototype"))
            (const composer (dot Composer "prototype"))
            (const nativeBlocks (dot transcript "nativeBlocks"))
            (const describeSurface (dot composer "describeSurface"))
            (const marked (new WeakMap []))
            (const advice (new WeakMap []))
            (const shownBy (new WeakMap []))
            (const docks (new WeakMap []))
            blank
            ({
              block,
              is',
            }: (fn advises [block] [
              (let' is' (call (dot advice "get") [block]))
              (if' (infix [is' "===" undefined]) [
                (infix [is' "=" (dot (optCall (dot block "describe") []) "?.p?.role") "===" (str "omp.advisor")])
                (call (dot advice "set") [block is'])
              ])
              (return is')
            ]))
            blank
            ({
              block,
              role,
              wrapped,
            }: (fn mark [block] [
              (const role (ternary (call said [block]) (str "omp.chat.msg") (ternary (call advises [block]) (str "omp.chat.advice") undefined)))
              (if' (not role) (return block))
              (let' wrapped (call (dot marked "get") [block]))
              (if' (not wrapped) [
                (infix [wrapped "=" (new Marked [(array [block]) role])])
                (call (dot marked "set") [block wrapped])
              ])
              (if' (infix [(call isNativeSettled [block]) "&&" (not (call isNativeSettled [wrapped]))]) (call settleNative [wrapped]))
              (return wrapped)
            ]))
            blank
            (infix [
              (dot transcript "nativeBlocks")
              "="
              ({
                blocks,
                cached,
                marks,
                shown,
              }: (fn null [] [
                (const blocks (call (dot nativeBlocks "call") [this]))
                (const cached (call (dot shownBy "get") [this]))
                (if' (infix [(dot cached "?.blocks") "===" blocks]) (return (dot cached "shown")))
                (const marks (call (dot blocks "map") [mark]))
                (const shown (ternary (infix [cached "&&" (call same [(dot cached "shown") marks])]) (dot cached "shown") marks))
                (call (dot shownBy "set") [this (obj [blocks shown])])
                (return shown)
              ]))
            ])
            blank
            (infix [
              (dot composer "describeSurface")
              "="
              ({
                cx,
                surface,
                wrapped,
              }: (fn null [cx] [
                (const surface (call (dot describeSurface "call") [this cx]))
                (let' wrapped (call (dot docks "get") [surface]))
                (if' (not wrapped) [
                  (infix [wrapped "=" (obj [(prop "main" (dot surface "main")) (prop "dock" (array [(new Marked [(dot surface "dock") (str "omp.chat.dock")])]))])])
                  (call (dot docks "set") [surface wrapped])
                ])
                (return wrapped)
              ]))
            ])
          ]))
          blank
          (export (default ({pi}: (fn chatLook [pi] [
            (call (dot pi "setLabel") [(str "Chat look")])
            blank
            (call (dot pi "on") [
              (str "session_start")
              (async (arrow [] [
                (if' (idx globalThis STATE) return')
                (infix [(idx globalThis STATE) "=" true])
                (call install [])
              ]))
            ])
            blank
            (call (dot pi "on") [
              (str "before_agent_start")
              (async ({
                event,
                ctx,
                systemPrompt,
              }: (arrow [event ctx] [
                (if' (infix [(dot ctx "agent?.kind") "===" (str "sub") "||" (dot ctx "mode") "!==" (str "tui") "||" (not (dot chatTranscriptDisplayPreferences "hideToolActivity"))]) (return undefined))
                (if' (infix [(not (call (dot Array "isArray") [(dot event "systemPrompt")])) "||" (dot event "systemPrompt.length") "===" 0]) (return undefined))
                (const systemPrompt (array [(spread (dot event "systemPrompt"))]))
                (infix [(idx systemPrompt (infix [(dot systemPrompt "length") "-" 1])) "=" (tpl [(sub (idx systemPrompt (infix [(dot systemPrompt "length") "-" 1]))) (sub HIDDEN)])])
                (return (obj [systemPrompt]))
              ])))
            ])
          ]))))
        ]))
        generators.ts));
      "box-commands.ts" = generators.sourceFile "box-commands.ts" (generators.ts.render (({
          Boolean,
          Bun,
          Promise,
          Response,
          String,
          array,
          arrow,
          async,
          await,
          blank,
          call,
          const,
          default,
          dot,
          export,
          fn,
          idx,
          if',
          import',
          infix,
          new,
          not,
          obj,
          prop,
          regex,
          return,
          return',
          rows,
          spaces,
          spread,
          str,
          sub,
          ternary,
          tpl,
          ...
        }: (spaces 2 ({
          homedir,
          usage,
          expand,
          ompBox,
          boxCommands,
        }: [
          (import' [homedir] (str "node:os"))
          blank
          (const usage (str "usage: /box [list | add PATH [--copy] | rm NAME | reconcile]"))
          blank
          ({value}: (fn expand [value] [
            (if' (infix [value "===" (str "~")]) (return (call homedir [])))
            (if' (call (dot value "startsWith") [(str "~/")]) (return (tpl [(sub (call homedir [])) "/" (sub (call (dot value "slice") [2]))])))
            (return value)
          ]))
          blank
          (async ({
            args,
            proc,
            stdout,
            stderr,
            code,
          }: (fn ompBox [args] [
            (const proc (call (dot Bun "spawn") [(array [(str "omp-box") (spread args)]) (obj [(prop "stdout" (str "pipe")) (prop "stderr" (str "pipe"))])]))
            (const (array [stdout stderr code]) (await (call (dot Promise "all") [
              (array (rows [
                (call (dot (new Response [(dot proc "stdout")]) "text") [])
                (call (dot (new Response [(dot proc "stderr")]) "text") [])
                (dot proc "exited")
              ]))
            ])))
            (return (obj [(prop "ok" (infix [code "===" 0])) (prop "text" (call (dot (ternary (infix [code "===" 0]) stdout (infix [stderr "||" stdout])) "trim") []))]))
          ])))
          blank
          (export (default ({pi}: (fn boxCommands [pi] [
            (call (dot pi "setLabel") [(str "Box access")])
            blank
            (call (dot pi "registerCommand") [
              (str "box")
              (obj (rows [
                (prop "description" (str "Manage what omp-box shares: list, add, copy, remove, reconcile"))
                (prop "handler" (async ({
                  args,
                  ctx,
                  action,
                  rest,
                }: (arrow [args ctx] [
                  (const (array [action (spread rest)]) (call (dot (call (dot (call (dot (call String [(infix [args "??" (str "")])]) "trim") []) "split") [(regex "\\s+" "")]) "filter") [Boolean]))
                  blank
                  (if' (infix [(not action) "||" action "===" (str "list")]) ({result}: [
                    (const result (await (call ompBox [(array [(str "list")])])))
                    (call (dot ctx "ui.notify") [(infix [(dot result "text") "||" (str "no grants")]) (ternary (dot result "ok") (str "info") (str "error"))])
                    return'
                  ]))
                  blank
                  (if' (infix [action "===" (str "add")]) ({
                    copy,
                    path,
                    boxArgs,
                    result,
                  }: [
                    (const copy (call (dot rest "includes") [(str "--copy")]))
                    (const path (call (dot rest "find") [({value}: (arrow value (infix [value "!==" (str "--copy")])))]))
                    (if' (not path) [
                      (call (dot ctx "ui.notify") [usage (str "info")])
                      return'
                    ])
                    (const boxArgs (array [(str "add") (call expand [path])]))
                    (if' copy (call (dot boxArgs "push") [(str "--copy")]))
                    (const result (await (call ompBox [boxArgs])))
                    (call (dot ctx "ui.notify") [(infix [(dot result "text") "||" usage]) (ternary (dot result "ok") (str "info") (str "error"))])
                    return'
                  ]))
                  blank
                  (if' (infix [action "===" (str "rm")]) ({
                    name,
                    result,
                  }: [
                    (const name (idx rest 0))
                    (if' (not name) [
                      (call (dot ctx "ui.notify") [usage (str "info")])
                      return'
                    ])
                    (const result (await (call ompBox [(array [(str "rm") name])])))
                    (call (dot ctx "ui.notify") [(infix [(dot result "text") "||" usage]) (ternary (dot result "ok") (str "info") (str "error"))])
                    return'
                  ]))
                  blank
                  (if' (infix [action "===" (str "reconcile")]) ({result}: [
                    (const result (await (call ompBox [(array [(str "reconcile")])])))
                    (call (dot ctx "ui.notify") [(infix [(dot result "text") "||" (str "grants reconciled")]) (ternary (dot result "ok") (str "info") (str "error"))])
                    return'
                  ]))
                  blank
                  (call (dot ctx "ui.notify") [usage (str "info")])
                ]))))
              ]))
            ])
          ]))))
        ])))
        generators.ts));
      "cwd.ts" = generators.sourceFile "cwd.ts" (generators.ts.render (({
          String,
          arrow,
          async,
          blank,
          call,
          const,
          default,
          dot,
          export,
          fn,
          import',
          infix,
          obj,
          optIdx,
          prop,
          regex,
          return,
          rows,
          str,
          sub,
          ternary,
          tpl,
          undefined,
          ...
        }: ({
          buildDirectoryArgumentCompletions,
          cwd,
        }: [
          (import' [buildDirectoryArgumentCompletions] (str "@oh-my-pi/pi-coding-agent/slash-commands/builtin-completions"))
          blank
          (export (default ({pi}: (fn cwd [pi] [
            (call (dot pi "setLabel") [(str "Working directory")])
            blank
            (call (dot pi "on") [
              (str "input")
              (async ({
                event,
                dir,
              }: (arrow event [
                (const dir (optIdx (call (dot (regex "^\\/cwd\\s+(\\S[\\s\\S]*)$" "") "exec") [(call (dot (call String [(infix [(dot event "text") "??" (str "")])]) "trim") [])]) 1))
                (return (ternary dir (obj [(prop "text" (tpl ["/move " (sub dir)]))]) undefined))
              ])))
            ])
            blank
            (call (dot pi "registerCommand") [
              (str "cwd")
              (obj (rows [
                (prop "description" (str "Show the working directory; /cwd DIR moves the session there, as /move does"))
                (prop "getArgumentCompletions" (call buildDirectoryArgumentCompletions []))
                (prop "handler" (async ({
                  _args,
                  ctx,
                }: (arrow [_args ctx] [
                  (call (dot ctx "ui.notify") [(call (dot ctx "sessionManager.getCwd") []) (str "info")])
                ]))))
              ]))
            ])
          ]))))
        ]))
        generators.ts));
      secrets = "${secrets}";
      "crest-auth.ts" = generators.sourceFile "crest-auth.ts" (generators.ts.render (({
          Array,
          Bun,
          Date,
          Error,
          JSON,
          Map,
          Object,
          Promise,
          Readonly,
          Record,
          Response,
          Set,
          array,
          arrayOf,
          arrow,
          async,
          await,
          below,
          blank,
          call,
          const,
          const',
          continue,
          default,
          dot,
          export,
          fn,
          forOf,
          generic,
          idx,
          if',
          import',
          infix,
          interface,
          method,
          new,
          not,
          null',
          number,
          obj,
          opt,
          process,
          prop,
          return,
          return',
          rows,
          spread,
          str,
          string,
          sub,
          ternary,
          throw',
          tpl,
          typeOnly,
          typed,
          typeof,
          undefined,
          unknown,
          void,
          ...
        }: ({
          ApiKeyResolver,
          streamSimple,
          getBundledModels,
          ExtensionAPI,
          PROVIDERS,
          CHAT_KINDS,
          MARGIN,
          held,
          logins,
          Token,
          Entry,
          crestAuth,
          token,
          entries,
          signedIn,
          rotating,
          crest,
        }: [
          (import' [(typeOnly ApiKeyResolver) streamSimple] (str "@oh-my-pi/pi-ai"))
          (import' [getBundledModels] (str "@oh-my-pi/pi-catalog/models"))
          (import' (typeOnly [ExtensionAPI]) (str "@oh-my-pi/pi-coding-agent"))
          blank
          (const PROVIDERS (infix [(array [(str "anthropic") (str "openai-codex")]) "as" const']))
          (const (typed CHAT_KINDS (generic Readonly [(generic Record [string true])])) (obj [(prop "chat" true) (prop "tiny" true)]))
          (const MARGIN 300000)
          (const held (new (generic Map [string Token]) []))
          (const logins (new (generic Map [string string]) []))
          blank
          (interface Token [
            (typed "access" string)
            (typed (opt "login") string)
            (typed (opt "expires") number)
          ])
          blank
          (interface Entry [
            (typed "name" string)
            (typed "kind" string)
          ])
          blank
          (async ({
            args,
            child,
            stdout,
            stderr,
            code,
          }: (fn crestAuth (typed [(typed (spread args) (arrayOf string))] (generic Promise [string])) [
            (const child (call (dot Bun "spawn") [(array [(str "crest-auth") (str "json") (spread args)]) (obj [(prop "stdout" (str "pipe")) (prop "stderr" (str "pipe"))])]))
            (const (array [stdout stderr code]) (await (call (dot Promise "all") [
              (array (rows [
                (call (dot (new Response [(dot child "stdout")]) "text") [])
                (call (dot (new Response [(dot child "stderr")]) "text") [])
                (dot child "exited")
              ]))
            ])))
            (if' (infix [code "!==" 0]) (throw' (new Error [(tpl ["crest-auth json " (sub (call (dot args "join") [(str " ")])) ": " (sub (call (dot stderr "trim") []))])])))
            (return stdout)
          ])))
          blank
          (async ({
            provider,
            value,
            login,
            expires,
          }: (fn token (typed [(typed provider string)] (generic Promise [Token])) [
            (const (typed value unknown) (call (dot JSON "parse") [(await (call crestAuth [(str "token") provider]))]))
            (if' (infix [(typeof value) "!==" (str "object") "||" value "===" null' "||" (not (infix [(str "access") "in" value])) "||" (typeof (dot value "access")) "!==" (str "string")]) [
              (throw' (new Error [(tpl ["crest-auth json token " (sub provider) ": no access token"])]))
            ])
            (const login (ternary (infix [(str "login") "in" value "&&" (typeof (dot value "login")) "===" (str "string")]) (dot value "login") undefined))
            (const expires (ternary (infix [(str "expires") "in" value "&&" (typeof (dot value "expires")) "===" (str "number")]) (dot value "expires") undefined))
            (return (obj [(prop "access" (dot value "access")) login expires]))
          ])))
          blank
          (async ({value}: (fn entries (typed [] (generic Promise [(arrayOf Entry)])) [
            (const (typed value unknown) (call (dot JSON "parse") [(await (call crestAuth [(str "list")]))]))
            (if' (infix [(typeof value) "!==" (str "object") "||" value "===" null' "||" (not (infix [(str "logins") "in" value])) "||" (not (call (dot Array "isArray") [(dot value "logins")]))]) [
              (throw' (new Error [(str "crest-auth json list: no logins")]))
            ])
            (return (call (dot value "logins.flatMap") [
              ({entry}: (arrow [(typed entry unknown)] (below (ternary (infix (rows [
                (typeof entry)
                "==="
                (str "object")
                "&&"
                entry
                "!=="
                null'
                "&&"
                (str "name")
                "in"
                entry
                "&&"
                (typeof (dot entry "name"))
                "==="
                (str "string")
                "&&"
                (str "kind")
                "in"
                entry
                "&&"
                (typeof (dot entry "kind"))
                "==="
                (str "string")
              ])) (below (array [(obj [(prop "name" (dot entry "name")) (prop "kind" (dot entry "kind"))])])) (below (array []))))))
            ]))
          ])))
          blank
          (async ({providers}: (fn signedIn (typed [] (generic Promise [(generic Set [string])])) [
            (const providers (new (generic Set [string]) []))
            ({entry}: (forOf entry (await (call entries [])) [
              (if' (infix [(dot entry "kind") "===" (str "login")]) (call (dot providers "add") [(str "anthropic")]))
              (if' (infix [(dot entry "kind") "===" (str "oauth")]) (call (dot providers "add") [(dot entry "name")]))
            ]))
            (return providers)
          ])))
          blank
          ({provider}: (fn rotating (typed [(typed provider string)] ApiKeyResolver) [
            (return (async ({
              error,
              lastChance,
              previousKey,
              kept,
              spent,
              next,
            }: (arrow [(obj [error lastChance previousKey])] [
              (const kept (call (dot held "get") [provider]))
              (if' (infix [error "===" undefined "&&" kept "!==" undefined "&&" [(dot kept "expires") "??" 0] "-" MARGIN ">" (call (dot Date "now") [])]) (return (dot kept "access")))
              (const spent (ternary (infix [previousKey "===" undefined]) undefined (call (dot logins "get") [previousKey])))
              (if' (infix [error "!==" undefined "&&" lastChance "&&" spent "!==" undefined]) (await (call crestAuth [(str "cool") spent])))
              (const next (await (call token [provider])))
              (if' (infix [(dot next "login") "!==" undefined]) (call (dot logins "set") [(dot next "access") (dot next "login")]))
              (call (dot held "set") [provider next])
              (return (dot next "access"))
            ]))))
          ]))
          blank
          (export (default (async ({
            pi,
            providers,
          }: (fn crest (typed [(typed pi ExtensionAPI)] (generic Promise [void])) [
            (const providers (await (call signedIn [])))
            ({
              provider,
              bundled,
              baseUrl,
              api,
              wire,
            }: (forOf provider PROVIDERS [
              (const bundled (call getBundledModels [provider]))
              (const baseUrl (dot (idx bundled 0) "?.baseUrl"))
              (if' (infix [(not (call (dot providers "has") [provider])) "||" baseUrl "===" undefined]) continue)
              (const api (tpl ["crest-" (sub provider)]))
              (const wire (new Map [(call (dot bundled "map") [({model}: (arrow [model] (array [(dot model "id") model])))])]))
              (call (dot pi "registerProvider") [
                provider
                (obj (rows [
                  baseUrl
                  (prop "apiKey" (tpl ["!crest-auth json token " (sub provider) " | jq -er .access || echo crest-unavailable"]))
                  api
                  (prop "models" (call (dot bundled "map") [({model}: (arrow [model] (ternary (call (dot Object "hasOwn") [CHAT_KINDS (infix [(dot model "kind") "??" (str "chat")])]) (obj [(spread model) api]) model)))]))
                  ({
                    model,
                    context,
                    options,
                    target,
                  }: (method "streamSimple" [model context options] [
                    (const target (call (dot wire "get") [(dot model "id")]))
                    (if' (infix [target "===" undefined]) (throw' (new Error [(tpl ["crest: " (sub provider) " has no bundled model " (sub (dot model "id"))])])))
                    (return (call streamSimple [target context (obj [(spread options) (prop "apiKey" (call rotating [provider]))])]))
                  ]))
                ]))
              ])
            ]))
          ])))))
        ]))
        generators.ts));
      optchat = ./optchat;
    };
  ompSecret = pkgs.writeShellScriptBin "omp-secret" ''
    PATH=${lib.makeBinPath [pkgs.age]}:$PATH exec ${pkgs.bun}/bin/bun ${secrets}/omp-secret.ts "$@"
  '';
in {
  user.persist.directories = [
    ".omp"
    ".local/share/omp"
    ".local/state/omp-secrets"
  ];

  environment.systemPackages = [pkgs.jq pkgs.age ompSecret];

  user.files =
    lib.mapAttrs' (name: source: lib.nameValuePair ".omp/agent/ext/${name}" {source = "${source}";}) extLinks
    // {
      ".omp/agent/config.yml" = {
        generator = lib.generators.toYAML {};
        value = {
          defaultThinkingLevel = catalog.ompThinkingLevel;
          advisor.enabled = true;
          advisor.reviewMode = "agent-end";
          startup.checkUpdate = false;
          setupVersion = 2;
          symbolPreset = "unicode";
          theme.dark = "titanium";
          composer.tokenRate = false;
          disabledExtensions = [];
          dev.autoqa = false;
          debug.enabled = false;
          exa.enabled = false;
          colorBlindMode = false;
          hideThinkingBlock = true;
          statusLine = {
            sessionAccent = true;
            contextLine = "embedded";
          };
          tui = {
            renderMermaid = true;
            scrollbackRebuild = true;
          };
          display = {
            shimmer = "classic";
            smoothStreaming = true;
          };
          task = {
            showResolvedModelBadge = false;
            eager = "preferred";
            enableLsp = false;
            completionProbe = false;
          };
          edit.mode = "hashline";
          eval = {
            # A steer backgrounds a running cell so a message lands at once; the hour keeps
            # omp from backgrounding long cells on its own.
            autoBackground = {
              enabled = true;
              thresholdMs = 3600000;
            };
            js = false;
          };
          astGrep.enabled = true;
          github.enabled = true;
          codexResets.autoRedeem = "no";
          title.icons = "nf+emoji";
          interruptMode = "immediate";
          modelRoles = {
            default = "${catalog.defaultProvider}/${catalog.defaultModel}";
            advisor = catalog.advisorModel;
            smol = catalog.smolModel;
            judge = catalog.judgeModel;
            task = catalog.taskModel;
          };
          retry.fallbackChains = catalog.fallbackChains;
          extensions = map (path: "${extDir}/${path}") [
            "pi-chronobreak"
            "pi-recap"
            "pi-donsetch"
            "omp-bot/omp/code-mode.ts"
            "omp-bot/omp/barge-in.ts"
            "compact-eval.ts"
            "work-fold.ts"
            "chat-look.ts"
            "box-commands.ts"
            "cwd.ts"
            "secrets/secrets.ts"
            "crest-auth.ts"
            "crest-reroute.ts"
            "optchat/extension.ts"
            "omp-bot/omp/ompd.ts"
          ];
        };
      };
      ".omp/config.json" = {
        generator = toJSON;
        value = {
          terminal_width_percent = 50;
          panel_width_percent = 13;
          ascii = true;
          keybinds = {
            project_next = "ctrl+l";
            project_prev = "ctrl+h";
            session_next = "ctrl+j";
            session_prev = "ctrl+k";
          };
        };
      };
      ".omp/agent/settings.json" = {
        generator = toJSON;
        value = {
          inherit (catalog) defaultProvider;
          inherit (catalog) defaultModel;
          defaultThinkingLevel = catalog.ompThinkingLevel;
          inherit (catalog) enabledModels;
          packages = [];
        };
      };
      ".omp/agent/models.yml".text = builtins.readFile ./models.yml;
      ".omp/agent/models.json" = {
        generator = toJSON;
        value = catalog.models;
      };
      ".omp/agent/APPEND_SYSTEM.md".text = "${config.user.dev.prompts.shared}\n\n${catalog.taskNote}\n";
    };
}
