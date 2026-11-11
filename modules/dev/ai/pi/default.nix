{
  config,
  lib,
  flakeInputs,
  inputPackages,
  generators,
  ...
}: let
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
  flash = "vercel-ai-gateway/deepseek/deepseek-v4.1-flash-1017";
  cheapDeepseek.compat.vercelGatewayRouting.order = ["wafer" "morph" "runware"];
  defaultProvider = "anthropic";
  defaultModel = "claude-opus-5-5";
  taskModel = "vercel-ai-gateway/deepseek/deepseek-v4.1-flash-1017-fast";
in {
  options.user.dev.modelCatalog = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    description = "Shared coding-agent provider and model catalog.";
    default = {
      inherit defaultProvider defaultModel taskModel;
      defaultThinkingLevel = "xhigh";
      ompThinkingLevel = "auto";
      advisorModel = "openai-codex/gpt-6.1-sol:high";
      taskNote = "omp task workers run on ${taskModel} unless the task names a model; give Lean proofs and compiler work `model: \"${defaultProvider}/${defaultModel}\"`.";
      smolModel = flash;
      judgeModel = flash;
      fallbackChains = {
        default = ["openai-codex/gpt-6.1-sol:xhigh" flash];
        advisor = [flash];
        task = [flash];
      };

      enabledModels = [
        "vercel-ai-gateway/deepseek/deepseek-v4.1-flash-1017-fast"
        "vercel-ai-gateway/deepseek/deepseek-v4.1-flash"
        "vercel-ai-gateway/deepseek/deepseek-v4.1-flash-1017"
        "anthropic/claude-opus-5-5"
        "anthropic/claude-sonnet-5-5"
      ];

      models.providers = {
        vercel-ai-gateway = {
          modelOverrides = {
            "zai/glm-5.3-flash".compat.vercelGatewayRouting.order = ["runware" "wafer"];
            "deepseek/deepseek-v4.1-flash-1017" = cheapDeepseek;
            "deepseek/deepseek-v4.1-flash" = cheapDeepseek;
          };

          models = [
            {
              id = "deepseek/deepseek-v4.1-flash-1017";
              name = "DeepSeek V4.1 Flash 1017";
              api = "anthropic-messages";
              reasoning = true;
              input = ["text" "image"];
              compat.allowEmptySignature = true;
              contextWindow = 1000000;
              maxTokens = 384000;
              cost = {
                input = 0.13;
                output = 0.5;
                cacheRead = 0.0026;
                cacheWrite = 0;
              };
            }
            {
              id = "deepseek/deepseek-v4.1-flash-1017-fast";
              name = "DeepSeek V4.1 Flash 1017 Fast";
              api = "anthropic-messages";
              reasoning = true;
              input = ["text" "image"];
              compat.allowEmptySignature = true;
              contextWindow = 1000000;
              maxTokens = 384000;
              cost = {
                input = 0.6;
                output = 2.4;
                cacheRead = 0.014;
                cacheWrite = 0;
              };
            }
            {
              id = "moonshotai/kimi-k3.1-pro";
              name = "Kimi K3.1 Pro";
              api = "anthropic-messages";
              reasoning = true;
              input = ["text" "image"];
              compat.allowEmptySignature = true;
              contextWindow = 1000000;
              maxTokens = 131072;
              cost = {
                input = 2;
                output = 10;
                cacheRead = 0.2;
                cacheWrite = 0;
              };
            }
            {
              id = "moonshotai/kimi-k3.1-pro-highspeed";
              name = "Kimi K3.1 Pro High Speed";
              api = "anthropic-messages";
              reasoning = true;
              input = ["text" "image"];
              compat.allowEmptySignature = true;
              contextWindow = 1000000;
              maxTokens = 131072;
              cost = {
                input = 4;
                output = 20;
                cacheRead = 0.2;
                cacheWrite = 0;
              };
            }
          ];
        };

        celeris = {
          name = "Celeris";
          baseUrl = "https://inference.celeris.ai/celeris-1-magnus/v1";
          api = "openai-completions";
          apiKey = "$CELERIS_API_KEY";
          models = [
            {
              id = "celeris-1-magnus";
              name = "Celeris 1 Magnus";
              reasoning = true;
              contextWindow = 128000;
              maxTokens = 8192;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
          ];
        };

        bonsai = {
          name = "Bonsai (local)";
          baseUrl = "http://127.0.0.1:8891/v1";
          api = "openai-completions";
          apiKey = "none";
          models = [
            {
              id = "bonsai";
              name = "Ternary Bonsai 2 27B (local)";
              reasoning = true;
              thinkingLevelMap = {xhigh = "xhigh";};
              contextWindow = 32768;
              maxTokens = 8192;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
          ];
        };
      };
    };
  };

  config = {
    user.persist.directories = [
      ".config/pi/agent"
      ".config/pi-harness"
      ".local/share/pi"
      ".local/state/pi-harness"
      ".pi"
    ];
    environment.systemPackages = [inputPackages.pi-harness.default];
    environment.variables.PI_SKIP_VERSION_CHECK = "1";
    user.files = {
      ".pi/agent/settings.json" = {
        generator = toJSON;
        value = {
          inherit (catalog) defaultProvider defaultModel defaultThinkingLevel enabledModels;
          packages = [
            "${flakeInputs.pi-chronobreak}"
            "${flakeInputs.pi-rlm}"
            "${flakeInputs.pi-recap}"
            "${flakeInputs.pi-ampersand}"
            "${inputPackages.pi-donsetch.default}"
          ];
          extensions = [
            "${(generators.sourceFile "crest-auth.ts" (generators.ts.render (({
                Array,
                Date,
                Error,
                JSON,
                Map,
                Object,
                Promise,
                Readonly,
                ReadonlySet,
                Record,
                Set,
                String,
                array,
                arrayOf,
                arrow,
                async,
                await,
                below,
                blank,
                boolean,
                call,
                catch,
                const,
                continue,
                default,
                dot,
                export,
                fn,
                forAwait,
                forOf,
                generic,
                idx,
                if',
                import',
                infix,
                interface,
                let',
                method,
                new,
                not,
                null',
                number,
                obj,
                opt,
                process,
                prop,
                regex,
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
                try,
                typeOnly,
                typed,
                typeof,
                undefined,
                union,
                unknown,
                void,
                ...
              }: ({
                Api,
                AssistantMessage,
                AssistantMessageEvent,
                createAssistantMessageEventStream,
                Model,
                Provider,
                builtinProviders,
                ExtensionAPI,
                execFile,
                PROVIDERS,
                Token,
                Entry,
                logins,
                crestAuth,
                token,
                entries,
                signedIn,
                rateLimited,
                failed,
                successor,
                failover,
                crest,
              }: [
                (import' (rows [
                  (typeOnly Api)
                  (typeOnly AssistantMessage)
                  (typeOnly AssistantMessageEvent)
                  createAssistantMessageEventStream
                  (typeOnly Model)
                  (typeOnly Provider)
                ]) (str "@earendil-works/pi-ai"))
                (import' [builtinProviders] (str "@earendil-works/pi-ai/providers/all"))
                (import' (typeOnly [ExtensionAPI]) (str "@earendil-works/pi-coding-agent"))
                (import' [execFile] (str "node:child_process"))
                blank
                (const (typed PROVIDERS (generic Readonly [(generic Record [string true])])) (obj [(prop "anthropic" true) (prop (str "openai-codex") true)]))
                blank
                (interface Token [
                  (typed "access" string)
                  (typed "expires" number)
                  (typed (opt "login") string)
                ])
                blank
                (interface Entry [
                  (typed "name" string)
                  (typed "kind" string)
                ])
                blank
                (const logins (new (generic Map [string string]) []))
                blank
                ({args}: (fn crestAuth (typed [(typed (spread args) (arrayOf string))] (generic Promise [string])) [
                  (return (new Promise [
                    ({
                      resolve,
                      reject,
                    }: (arrow [resolve reject] (below (call execFile [
                      (str "crest-auth")
                      (array [(str "json") (spread args)])
                      ({
                        error,
                        stdout,
                        stderr,
                      }: (arrow [error stdout stderr] (below (ternary error (call reject [(new Error [(tpl ["crest-auth json " (sub (call (dot args "join") [(str " ")])) ": " (sub (infix [(call (dot stderr "trim") []) "||" (dot error "message")]))])])]) (call resolve [stdout])))))
                    ]))))
                  ]))
                ]))
                blank
                (async ({
                  provider,
                  value,
                  login,
                }: (fn token (typed [(typed provider string)] (generic Promise [Token])) [
                  (const (typed value unknown) (call (dot JSON "parse") [(await (call crestAuth [(str "token") provider]))]))
                  (if' (below (infix (rows [
                      (typeof value)
                      "!=="
                      (str "object")
                      "||"
                      value
                      "==="
                      null'
                      "||"
                      (not (infix [(str "access") "in" value]))
                      "||"
                      (typeof (dot value "access"))
                      "!=="
                      (str "string")
                      "||"
                      (not (infix [(str "expires") "in" value]))
                      "||"
                      (typeof (dot value "expires"))
                      "!=="
                      (str "number")
                    ]))) [
                      (throw' (new Error [(tpl ["crest-auth json token " (sub provider) ": no access token"])]))
                    ])
                  (const login (ternary (infix [(str "login") "in" value "&&" (typeof (dot value "login")) "===" (str "string")]) (dot value "login") undefined))
                  (if' (infix [login "!==" undefined]) (call (dot logins "set") [(dot value "access") login]))
                  (return (obj [(prop "access" (dot value "access")) (prop "expires" (dot value "expires")) login]))
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
                (const rateLimited ({message}: (arrow (typed [(typed message AssistantMessage)] boolean) (below (infix [(dot message "stopReason") "===" (str "error") "&&" (call (dot (regex "\\b429\\b|rate.?limit|too many requests|usage limit" "i") "test") [(infix [(dot message "errorMessage") "??" (str "")])])])))))
                blank
                ({
                  model,
                  error,
                }: (fn failed (typed [(typed model (generic Model [Api])) (typed error unknown)] AssistantMessage) [
                  (return (obj (rows [
                    (prop "role" (str "assistant"))
                    (prop "content" (array []))
                    (prop "api" (dot model "api"))
                    (prop "provider" (dot model "provider"))
                    (prop "model" (dot model "id"))
                    (prop "usage" (obj (rows [
                      (prop "input" 0)
                      (prop "output" 0)
                      (prop "cacheRead" 0)
                      (prop "cacheWrite" 0)
                      (prop "totalTokens" 0)
                      (prop "cost" (obj [(prop "input" 0) (prop "output" 0) (prop "cacheRead" 0) (prop "cacheWrite" 0) (prop "total" 0)]))
                    ])))
                    (prop "stopReason" (str "error"))
                    (prop "errorMessage" (ternary (infix [error "instanceof" Error]) (dot error "message") (call String [error])))
                    (prop "timestamp" (call (dot Date "now") []))
                  ])))
                ]))
                blank
                (async ({
                  provider,
                  spent,
                }: (fn successor (typed [(typed provider string) (typed spent (generic ReadonlySet [string]))] (generic Promise [(union [Token undefined])])) [
                  (try ({next}: [
                      (const next (await (call token [provider])))
                      (return (ternary (infix [(dot next "login") "!==" undefined "&&" (not (call (dot spent "has") [(dot next "login")]))]) next undefined))
                    ]) [
                      (catch null [
                        (return undefined)
                      ])
                    ])
                ])))
                blank
                ({base}: (fn failover (typed [(typed base Provider)] (idx Provider (str "streamSimple"))) [
                  (return ({
                    model,
                    context,
                    options,
                    out,
                    run,
                  }: (arrow [model context options] [
                    (const out (call createAssistantMessageEventStream []))
                    (const run (async ({
                      apiKey,
                      spent,
                      held,
                      flush,
                      open,
                    }: (arrow (typed [(typed apiKey (union [string undefined])) (typed spent (generic Set [string]))] (generic Promise [void])) [
                      (const (typed held (arrayOf AssistantMessageEvent)) (array []))
                      (const flush (arrow [] [
                        ({event}: (forOf event (call (dot held "splice") [0]) (call (dot out "push") [event])))
                      ]))
                      (let' open false)
                      ({event}: (forAwait event (call (dot base "streamSimple") [model context (obj [(spread options) apiKey])]) [
                        (if' (infix [(dot event "type") "===" (str "done") "||" (dot event "type") "===" (str "error")]) ({login}: [
                          (const login (ternary (infix [apiKey "===" undefined]) undefined (call (dot logins "get") [apiKey])))
                          (if' (infix [(dot event "type") "===" (str "error") "&&" (not open) "&&" login "!==" undefined "&&" (call rateLimited [(dot event "error")])]) ({next}: [
                            (call (dot spent "add") [login])
                            (await (call crestAuth [(str "cool") login]))
                            (const next (await (call successor [(dot base "id") spent])))
                            (if' (infix [next "!==" undefined]) (return (call run [(dot next "access") spent])))
                          ]))
                          (call flush [])
                          (call (dot out "push") [event])
                          return'
                        ]))
                        (call (dot held "push") [event])
                        (if' (infix [open "||" (dot event "type") "!==" (str "start")]) [
                          (infix [open "=" true])
                          (call flush [])
                        ])
                      ]))
                      (call flush [])
                      (call (dot out "end") [])
                    ]))))
                    (call (dot (call run [(dot options "?.apiKey") (new Set [])]) "catch") [({error}: (arrow [error] (below (call (dot out "push") [(obj [(prop "type" (str "error")) (prop "reason" (str "error")) (prop "error" (call failed [model error]))])]))))])
                    (return out)
                  ])))
                ]))
                blank
                (export (default (async ({
                  pi,
                  providers,
                }: (fn crest (typed [(typed pi ExtensionAPI)] (generic Promise [void])) [
                  (const providers (await (call signedIn [])))
                  ({
                    base,
                    oauth,
                  }: (forOf base (call builtinProviders []) [
                    (const oauth (dot base "auth.oauth"))
                    (if' (infix [(not (call (dot Object "hasOwn") [PROVIDERS (dot base "id")])) "||" (not (call (dot providers "has") [(dot base "id")])) "||" oauth "===" undefined]) continue)
                    (call (dot pi "registerProvider") [
                      (obj (rows [
                        (spread base)
                        (prop "auth" (obj (rows [
                          (prop "apiKey" (obj (rows [
                            (prop "name" (tpl ["Crest (" (sub (dot base "name")) ")"]))
                            (prop "check" (async (arrow [] (obj [(prop "type" (str "oauth")) (prop "source" (str "crest-auth"))]))))
                            (async ({next}: (method "resolve" [] [
                              (const next (await (call token [(dot base "id")])))
                              (return (obj (rows [
                                (prop "auth" (await (call (dot oauth "toAuth") [(obj [(prop "type" (str "oauth")) (prop "access" (dot next "access")) (prop "refresh" (str "")) (prop "expires" (dot next "expires"))])])))
                                (prop "source" (tpl ["crest-auth " (sub (infix [(dot next "login") "??" (dot base "id")]))]))
                              ])))
                            ])))
                          ])))
                        ])))
                        (prop "streamSimple" (call failover [base]))
                      ]))
                    ])
                  ]))
                ])))))
              ]))
              generators.ts)))}"
          ];
          enableInstallTelemetry = false;
          defaultTools = ["+codemode"];
          codemode.mode = "only";
          compaction.enabled = false;
          showHardwareCursor = true;
          editorPaddingX = 0;
          steeringMode = "one-at-a-time";
          transport = "sse";
          options.skills_paths = [
            "./.codex/skills"
            "./.claude/skills"
          ];
          hideThinkingBlock = true;
          collapseChangelog = true;
          quietStartup = true;
          doubleEscapeAction = "tree";
          treeFilterMode = "default";
          symbols = {
            preset = "ascii";
            overrides = {};
          };
          recap = {
            placement = "above";
            model = lib.head catalog.enabledModels;
          };
        };
      };
      ".pi/agent/models.json" = {
        generator = toJSON;
        value = catalog.models;
      };

      ".pi/workflows/goal-loop.json".source = ./goal-loop.json;
    };
  };
}
