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
    lib.genAttrs ["pi-chronobreak" "pi-recap"] (name: "${flakeInputs.${name}}")
    // {
      pi-donsetch = "${inputPackages.pi-donsetch.default}";
      "compact-eval.ts" = ./compact-eval.ts;
      "work-fold.ts" = ./work-fold.ts;
      "message-interrupts.ts" = ./message-interrupts.ts;
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
          Error,
          JSON,
          Map,
          Object,
          Parameters,
          Promise,
          Readonly,
          Record,
          Response,
          Set,
          String,
          array,
          arrayOf,
          arrow,
          async,
          await,
          below,
          blank,
          call,
          const,
          continue,
          default,
          dot,
          export,
          fn,
          forOf,
          generic,
          globalThis,
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
          while,
          ...
        }: ({
          Api,
          Model,
          registerCustomApi,
          streamSimple,
          ExtensionAPI,
          ExtensionContext,
          CHAT_KINDS,
          WIRES,
          Token,
          Entry,
          crestAuth,
          token,
          entries,
          signedIn,
          credential,
          routed,
          crest,
        }: [
          (import' [(typeOnly Api) (typeOnly Model) registerCustomApi streamSimple] (str "@oh-my-pi/pi-ai"))
          (import' (typeOnly [ExtensionAPI ExtensionContext]) (str "@oh-my-pi/pi-coding-agent"))
          blank
          (const (typed CHAT_KINDS (generic Readonly [(generic Record [string true])])) (obj [(prop "chat" true) (prop "tiny" true)]))
          blank
          (const (typed WIRES (generic Map [string (generic Map [string (generic Model [Api])])])) (new (generic Map [string (generic Map [string (generic Model [Api])])]) []))
          blank
          (interface Token [
            (typed (opt "login") string)
            (typed (opt "secret") string)
            (typed (opt "error") string)
            (typed (opt "retry") number)
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
            model,
            value,
          }: (fn token (typed [(typed provider string) (typed model string)] (generic Promise [Token])) [
            (const (typed value (generic Record [string unknown])) (call (dot JSON "parse") [(await (call crestAuth [(str "token") provider model]))]))
            (return (obj (rows [
              (prop "login" (ternary (infix [(typeof (dot value "login")) "===" (str "string")]) (dot value "login") undefined))
              (prop "secret" (ternary (infix [(typeof (dot value "access")) "===" (str "string")]) (dot value "access") (ternary (infix [(typeof (dot value "key")) "===" (str "string")]) (dot value "key") undefined)))
              (prop "error" (ternary (infix [(typeof (dot value "error")) "===" (str "string")]) (dot value "error") undefined))
              (prop "retry" (ternary (infix [(typeof (dot value "retry")) "===" (str "number")]) (dot value "retry") undefined))
            ])))
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
              (call (dot providers "add") [(ternary (infix [(dot entry "kind") "===" (str "login")]) (str "anthropic") (dot entry "name"))])
            ]))
            (return providers)
          ])))
          blank
          ({
            provider,
            model,
          }: (fn credential [(typed provider string) (typed model string)] [
            (return (async ({next}: (arrow [] [
              (const next (await (call token [provider model])))
              (if' (infix [(dot next "secret") "===" undefined]) (throw' (new Error [(infix [(dot next "error") "??" (tpl ["crest-auth json token " (sub provider) ": no credential"])])])))
              (return (dot next "secret"))
            ]))))
          ]))
          blank
          ({
            provider,
            model,
          }: (fn routed [(typed provider string) (typed model string)] [
            (return (async ({
              args,
              input,
              init,
              headers,
              carrier,
            }: (arrow (typed [(typed (spread args) (generic Parameters [(typeof (dot globalThis "fetch"))]))] (generic Promise [Response])) [
              (const (array [input init]) args)
              (const headers (new (dot globalThis "Headers") [(dot init "?.headers")]))
              (const carrier (call (dot (array [(str "x-api-key") (str "authorization")]) "find") [({name}: (arrow [name] (below (call (dot headers "has") [name]))))]))
              (if' (infix [carrier "===" undefined]) (return (call (dot globalThis "fetch") [input init])))
              (while true ({
                next,
                response,
                verdict,
              }: [
                (const next (await (call token [provider model])))
                (if' (infix [(dot next "secret") "===" undefined]) [
                  (return (new Response [
                    (call (dot JSON "stringify") [(obj [(prop "type" (str "error")) (prop "error" (obj [(prop "type" (str "rate_limit_error")) (prop "code" (str "rate_limit_exceeded")) (prop "message" (dot next "error"))]))])])
                    (obj [(prop "status" 429) (prop "headers" (obj [(prop (str "content-type") (str "application/json")) (prop (str "retry-after") (call String [(infix [(dot next "retry") "??" 60])]))]))])
                  ]))
                ])
                (call (dot headers "set") [carrier (ternary (infix [carrier "===" (str "authorization")]) (tpl ["Bearer " (sub (dot next "secret"))]) (dot next "secret"))])
                (const response (await (call (dot globalThis "fetch") [input (obj [(spread init) headers])])))
                (if' (infix [(dot response "ok") "||" (dot next "login") "===" undefined]) (return response))
                (const (typed verdict (generic Record [string unknown])) (call (dot JSON "parse") [
                  (await (call crestAuth [
                    (str "cool")
                    (dot next "login")
                    model
                    (call String [(dot response "status")])
                    (spread (call (dot (array [(spread (dot response "headers"))]) "map") [
                      ({
                        name,
                        value,
                      }: (arrow [(array [name value])] (below (tpl [(sub name) "=" (sub value)]))))
                    ]))
                  ]))
                ]))
                (if' (infix [(dot verdict "limited") "!==" true]) (return response))
                (await (call (dot response "body?.cancel") []))
              ]))
            ]))))
          ]))
          blank
          (export (default (async ({
            pi,
            key,
            route,
            adopt,
          }: (fn crest (typed [(typed pi ExtensionAPI)] (generic Promise [void])) [
            (const key ({provider}: (arrow (typed [(typed provider string)] string) (below (tpl ["!crest-auth json token " (sub provider) " | jq -er '.access // .key' || echo crest-unavailable"])))))
            ({provider}: (forOf provider (await (call signedIn [])) [
              (if' (not (call (dot WIRES "has") [provider])) (call (dot WIRES "set") [provider (new Map [])]))
              (call (dot pi "registerProvider") [provider (obj [(prop "apiKey" (call key [provider]))])])
            ]))
            (const route ({
              provider,
              api,
              wire,
              models,
            }: (arrow (typed [(typed provider string)] void) [
              (const api (tpl ["crest-" (sub provider)]))
              (const wire (infix [(call (dot WIRES "get") [provider]) "??" (new Map [])]))
              (const models (array [(spread (call (dot wire "values") []))]))
              (call registerCustomApi [
                api
                ({
                  model,
                  context,
                  options,
                  target,
                }: (arrow [model context options] [
                  (const target (call (dot wire "get") [(dot model "id")]))
                  (if' (infix [target "===" undefined]) (throw' (new Error [(tpl ["crest: " (sub provider) " has no model " (sub (dot model "id"))])])))
                  (return (call streamSimple [
                    target
                    context
                    (obj [(spread options) (prop "apiKey" (call credential [provider (dot target "id")])) (prop "fetch" (call routed [provider (dot target "id")]))])
                  ]))
                ]))
              ])
              (call (dot pi "registerProvider") [
                provider
                (obj (rows [
                  (prop "baseUrl" (dot (idx models 0) "?.baseUrl"))
                  (prop "apiKey" (call key [provider]))
                  api
                  (prop "models" (call (dot models "map") [({model}: (arrow [model] (ternary (call (dot Object "hasOwn") [CHAT_KINDS (infix [(dot model "kind") "??" (str "chat")])]) (obj [(spread model) api]) model)))]))
                ]))
              ])
            ])))
            (const adopt (async ({
              _event,
              ctx,
              grown,
              current,
              next,
            }: (arrow (typed [(typed _event unknown) (typed ctx ExtensionContext)] (generic Promise [void])) [
              (const grown (new (generic Set [string]) []))
              ({
                model,
                wire,
              }: (forOf model (call (dot ctx "models.list") []) [
                (const wire (call (dot WIRES "get") [(dot model "provider")]))
                (if' (infix [wire "===" undefined "||" (dot model "api") "===" (tpl ["crest-" (sub (dot model "provider"))])]) continue)
                (call (dot wire "set") [(dot model "id") model])
                (if' (call (dot Object "hasOwn") [CHAT_KINDS (infix [(dot model "kind") "??" (str "chat")])]) (call (dot grown "add") [(dot model "provider")]))
              ]))
              ({provider}: (forOf provider grown [
                (call route [provider])
              ]))
              (const current (call (dot ctx "models.current") []))
              (if' (infix [current "===" undefined "||" (not (call (dot WIRES "has") [(dot current "provider")])) "||" (dot current "api") "===" (tpl ["crest-" (sub (dot current "provider"))])]) return')
              (const next (call (dot ctx "models.resolve") [(tpl [(sub (dot current "provider")) "/" (sub (dot current "id"))])]))
              (if' (infix [next "!==" undefined "&&" (dot next "api") "!==" (dot current "api")]) (await (call (dot pi "setModel") [next])))
            ]))))
            (call (dot pi "on") [(str "session_start") adopt])
            (call (dot pi "on") [(str "before_agent_start") adopt])
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
          startup.setupWizard = false;
          setupVersion = 3;
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
            "compact-eval.ts"
            "work-fold.ts"
            "message-interrupts.ts"
            "chat-look.ts"
            "box-commands.ts"
            "cwd.ts"
            "secrets/secrets.ts"
            "crest-auth.ts"
            "crest-reroute.ts"
            "optchat/extension.ts"
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
