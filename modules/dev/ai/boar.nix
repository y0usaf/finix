{
  config,
  lib,
  pkgs,
  inputPackages,
  generators,
  ...
}: let
  gatewayModel = id: lib.getAttrs ["id" "name" "input" "reasoning" "cost"] (lib.findFirst (model: model.id == id) null config.user.dev.modelCatalog.models.providers.vercel-ai-gateway.models);
  agentFiles = dir: {
    "${dir}/settings.json" = {
      generator = lib.generators.toJSON {};
      value = {
        defaultTools = ["+codemode"];
        disabledExtensions = ["contain"];
        codemode.mode = "only";
        subagents = {
          concurrency = -1;
          roles = {
            scout = "fusion/terra-luna";
            ship = "fusion/opus-sol";
          };
          defaultRole = "scout";
        };
        defaultProvider = "fusion";
        defaultModel = "opus-sol";
        defaultThinkingLevel = "xhigh";
        fallbackProvider = "openai-codex";
        fallbackModel = "gpt-6.1-sol";
        messages.whenBusy = "steer";
        furrows.openedIdleSeconds = 0;
        memory.model = "openai-codex/gpt-6-luna";
        fusion.opus-sol = {
          lead = "anthropic/claude-opus-5-5";
          peer = "openai-codex/gpt-6.1-sol";
        };
        fusion.terra-luna = {
          lead = "openai-codex/gpt-6.1-terra";
          peer = "openai-codex/gpt-6-luna";
        };
        ascii = true;
        keys = {
          furrowNew = ["alt+t" "ctrl+n"];
          furrowRename = ["alt+r"];
          furrowClose = ["alt+w" "ctrl+shift+w" "ctrl+delete"];
          furrowNext = ["alt+." "ctrl+."];
          furrowPrev = ["alt+," "ctrl+,"];
          quit = ["ctrl+shift+d"];
        };
      };
    };
    "${dir}/models.json" = {
      generator = lib.generators.toJSON {};
      value.providers.vercel-ai-gateway.apiKey = "!cat ${config.users.users.${config.user.name}.home}/Tokens/AI_GATEWAY_API_KEY.txt";
      value.providers.vercel-ai-gateway.models = [
        (gatewayModel "moonshotai/kimi-k3.1-pro"
          // {
            contextWindow = 1048576;
            maxTokens = 1048576;
            compat.allowEmptySignature = true;
          })
        {
          id = "deepseek/deepseek-v4.1-flash-1017";
          name = "DeepSeek V4.1 Flash 1017";
          contextWindow = 1048576;
          maxTokens = 32768;
          input = ["text" "image"];
          reasoning = true;
          cost = {
            input = 0.075;
            output = 0.3;
            cacheRead = 0.0015;
            cacheWrite = 0;
          };
        }
        (gatewayModel "deepseek/deepseek-v4.1-flash-1017-fast"
          // {
            contextWindow = 1048576;
            maxTokens = 32768;
          })
      ];
      value.providers.openrouter.models = [
        {
          id = "inception/mercury-3";
          name = "Inception: Mercury 3";
          contextWindow = 1000000;
          maxTokens = 131072;
          input = ["text"];
          reasoning = true;
          cost = {
            input = 0.1;
            output = 0.35;
            cacheRead = 0.01;
            cacheWrite = 0;
          };
          thinkingLevelMap = {
            off = null;
            minimal = null;
            inherit (lib.genAttrs ["low" "medium" "high"] lib.id) low medium high;
            xhigh = null;
            max = null;
          };
        }
      ];
      value.providers.openai-codex.models = [
        {
          id = "gpt-6.1-terra";
          name = "GPT-6.1 Terra";
          contextWindow = 500000;
          maxTokens = 128000;
          input = ["text" "image"];
          reasoning = true;
          compat = {
            supportsAdditionalTools = true;
            supportsMidConvoSystemMessages = true;
            supportsOpenAIGrammarTools = true;
            supportsToolSearch = true;
          };
          cost = {
            input = 1;
            output = 5;
            cacheRead = 0.05;
            cacheWrite = 1.25;
            tiers = [
              {
                inputTokensAbove = 272000;
                input = 2;
                output = 7.5;
                cacheRead = 0.1;
                cacheWrite = 2.5;
              }
            ];
          };
          thinkingLevelMap = {
            off = null;
            minimal = "low";
            inherit (lib.genAttrs ["low" "medium" "high" "xhigh" "max"] lib.id) low medium high xhigh max;
          };
        }
      ];
    };
    "${dir}/mcp.json" = {
      generator = lib.generators.toJSON {};
      value.mcpServers.donsetch = {
        command = lib.getExe inputPackages.pi-donsetch.donsetch;
        args = ["mcp"];
      };
      value.mcpServers.jev = {
        command = "${pkgs.nodejs}/bin/node";
        args = [
          "${(generators.sourceFile "jev-mcp.mjs" (generators.javascript.render (({
              Error,
              JSON,
              array,
              arrow,
              async,
              await,
              blank,
              call,
              comment,
              const,
              continue,
              dot,
              fetch,
              function,
              if',
              import',
              inline,
              let',
              new,
              not,
              null',
              obj,
              optional,
              process,
              return,
              rows,
              str,
              throw',
              try',
              typeof,
              while,
              ...
            }: ({
              readFileSync,
              homedir,
              join,
              ENDPOINT,
              MODEL,
              VERSION,
              resolveKey,
              API_KEY,
              TOOL,
              buf,
              send,
              callSystemOne,
              handle,
            }: [
              (comment "#!/usr/bin/env node")
              blank
              (import' [readFileSync] "node:fs")
              (import' [homedir] "node:os")
              (import' [join] "node:path")
              blank
              (const ENDPOINT (str "https://api.typesafe.ai/v1/systemone"))
              (const MODEL (str "jev-latest"))
              (const VERSION (str "2025-11-25"))
              blank
              (function resolveKey {
                params = [];
                body = [
                  (if' (dot process "env.TYPESAFE_API_KEY") (return (call (dot process "env.TYPESAFE_API_KEY.trim") [])))
                  (try' [
                      (return (call (dot (call readFileSync [(call join [(call homedir []) (str "Tokens/TYPESAFE_API_KEY.txt")]) (str "utf8")]) "trim") []))
                    ] [
                      (return null')
                    ])
                ];
              })
              blank
              (const API_KEY (call resolveKey []))
              blank
              (const TOOL (obj (rows [
                ["name" (str "jev_decision")]
                [
                  "description"
                  (rows [
                    (str "Make fast, type-safe structured decisions with TypeSafe Jev (System One). ")
                    "+"
                    (str "Given a state (text or JSON) and a map of questions, returns a typed answer per question with ")
                    "+"
                    (str "calibrated probabilities and confidence. Three question primitives: noul (yes/no probability), ")
                    "+"
                    (str "choice (pick one of up to 255 options, with criteria map), score (rate along an ordered rubric ")
                    "+"
                    (str "list of 2-10 levels). All questions evaluate in parallel in one round trip.")
                  ])
                ]
                [
                  "inputSchema"
                  (obj (rows [
                    ["type" (str "object")]
                    [
                      "properties"
                      (obj (rows [
                        ["state" (obj [["type" (str "string")] ["description" (str "The program/document state to judge (plain text or JSON).")]])]
                        [
                          "questions"
                          (obj (rows [
                            ["type" (str "object")]
                            [
                              "description"
                              (rows [
                                (str "Map of answer-key -> question spec. Each spec: {type: 'noul'|'choice'|'score', instructions: string, criteria?: object|string[]}. ")
                                "+"
                                (str "choice criteria is an object of option -> description; score criteria is an ordered array of level labels; noul criteria optional.")
                              ])
                            ]
                            [
                              "additionalProperties"
                              (obj (rows [
                                ["type" (str "object")]
                                [
                                  "properties"
                                  (obj (rows [
                                    ["type" (obj [["type" (str "string")] ["enum" (array [(str "noul") (str "choice") (str "score")])]])]
                                    ["instructions" (obj [["type" (str "string")]])]
                                    ["criteria" (obj [["type" (str "object")]])]
                                  ]))
                                ]
                                ["required" (array [(str "type") (str "instructions")])]
                              ]))
                            ]
                          ]))
                        ]
                      ]))
                    ]
                    ["required" (array [(str "state") (str "questions")])]
                  ]))
                ]
              ])))
              blank
              (let' buf (str ""))
              (call (dot process "stdin.on") [
                (str "data")
                (arrow ({
                  chunk,
                  idx,
                }: {
                  params = [chunk];
                  body = [
                    [buf "+=" (call (dot chunk "toString") [])]
                    (let' idx null)
                    (while [[idx "=" (call (dot buf "indexOf") [(str "\\n")])] ">=" 0] ({
                      line,
                      msg,
                    }: [
                      (const line (call (dot (call (dot buf "slice") [0 idx]) "trim") []))
                      [buf "=" (call (dot buf "slice") [[idx "+" 1]])]
                      (if' (not line) continue)
                      (let' msg null)
                      (try' (inline [[msg "=" (call (dot JSON "parse") [line])]]) (inline [continue]))
                      (call handle [msg])
                    ]))
                  ];
                }))
              ])
              blank
              (function send ({obj'}: {
                params = [obj'];
                body = inline [(call (dot process "stdout.write") [[(call (dot JSON "stringify") [obj']) "+" (str "\\n")]])];
              }))
              blank
              (async (function callSystemOne ({
                state,
                questions,
                res,
                text,
              }: {
                params = [state questions];
                body = [
                  (if' (not API_KEY) (throw' (new Error [(str "TYPESAFE_API_KEY not set and ~/Tokens/TYPESAFE_API_KEY.txt unreadable")])))
                  (const res (await (call fetch [
                    ENDPOINT
                    (obj (rows [
                      ["method" (str "POST")]
                      ["headers" (obj [[(str "Content-Type") (str "application/json")] [(str "Authorization") [(str "Bearer ") "+" API_KEY]]])]
                      ["body" (call (dot JSON "stringify") [(obj [["model" MODEL] state questions])])]
                    ]))
                  ])))
                  (const text (await (call (dot res "text") [])))
                  (if' (not (dot res "ok")) ({detail}: [
                    (let' detail text)
                    (try' ({j}: inline [(const j (call (dot JSON "parse") [text])) [detail "=" (call (dot JSON "stringify") [[(dot j "detail") "||" j]])]]) (inline []))
                    (throw' (new Error [[(str "Jev API HTTP ") "+" (dot res "status") "+" (str ": ") "+" (call (dot detail "slice") [0 500])]]))
                  ]))
                  (return (call (dot JSON "parse") [text]))
                ];
              })))
              blank
              (async (function handle ({
                msg,
                id,
                method,
                params,
              }: {
                params = [msg];
                body = [
                  (const (obj [id method params]) msg)
                  (if' [method "===" (str "initialize")] [
                    (return (call send [
                      (obj [
                        ["jsonrpc" (str "2.0")]
                        id
                        [
                          "result"
                          (obj (rows [
                            ["protocolVersion" VERSION]
                            ["capabilities" (obj [["tools" (obj [])]])]
                            ["serverInfo" (obj [["name" (str "jev-mcp")] ["version" (str "0.1.0")]])]
                          ]))
                        ]
                      ])
                    ]))
                  ])
                  (if' [method "===" (str "ping")] (return (call send [(obj [["jsonrpc" (str "2.0")] id ["result" (obj [])]])])))
                  (if' [method "===" (str "notifications/initialized")] (return null))
                  (if' [method "===" (str "tools/list")] [
                    (return (call send [(obj [["jsonrpc" (str "2.0")] id ["result" (obj [["tools" (array [TOOL])]])]])]))
                  ])
                  (if' [method "===" (str "tools/call")] ({
                    name,
                    args,
                  }: [
                    (const name (optional params "name"))
                    (const args [(optional params "arguments") "||" (obj [])])
                    (try' ({data}: [
                        (if' [name "!==" (str "jev_decision")] (throw' (new Error [[(str "Unknown tool: ") "+" name]])))
                        (if' [(typeof (dot args "state")) "!==" (str "string") "||" (not (call (dot args "state.trim") []))] (throw' (new Error [(str "state is required and must be a string")])))
                        (if' [(not (dot args "questions")) "||" (typeof (dot args "questions")) "!==" (str "object")] (throw' (new Error [(str "questions map is required")])))
                        (const data (await (call callSystemOne [(dot args "state") (dot args "questions")])))
                        (return (call send [
                          (obj [
                            ["jsonrpc" (str "2.0")]
                            id
                            [
                              "result"
                              (obj (rows [
                                ["content" (array [(obj [["type" (str "text")] ["text" (call (dot JSON "stringify") [data null' 2])]])])]
                                ["structuredContent" data]
                                ["isError" false]
                              ]))
                            ]
                          ])
                        ]))
                      ]) ({e}: {
                        param = e;
                        body = [
                          (return (call send [
                            (obj [
                              ["jsonrpc" (str "2.0")]
                              id
                              [
                                "result"
                                (obj (rows [
                                  ["content" (array [(obj [["type" (str "text")] ["text" [(str "Error: ") "+" (dot e "message")]]])])]
                                  ["isError" true]
                                ]))
                              ]
                            ])
                          ]))
                        ];
                      }))
                  ]))
                  (call send [(obj [["jsonrpc" (str "2.0")] id ["error" (obj [["code" (-32601)] ["message" [(str "Method not found: ") "+" method]]])]])])
                ];
              })))
            ]))
            generators.javascript)))}"
        ];
      };
    };
  };
in {
  user.persist.directories = [
    ".local/state/boar"
    ".local/state/boar-rs"
  ];
  environment.systemPackages = [
    (inputPackages.boar-rs.default.overrideAttrs (old: {
      buildInputs = (old.buildInputs or []) ++ [pkgs.sqlite];
    }))
  ];
  user.files =
    agentFiles ".local/state/boar/agent"
    // agentFiles ".local/state/boar-rs/agent";
}
