{
  add,
  del,
  file,
  hunk,
  ...
}: [
  (file "packages/coding-agent/src/session/prewalk.ts" [
    (hunk 1 [
      "import type { Agent, AgentMessage, AgentToolResult, AgentTurnEndContext } from \"@oh-my-pi/pi-agent-core\";"
      "import { invalidateMessageCache } from \"@oh-my-pi/pi-agent-core/compaction\";"
      "import type { Model, ToolResultMessage } from \"@oh-my-pi/pi-ai\";"
      (del "import { logger, prompt } from \"@oh-my-pi/pi-utils\";")
      (add "import { isRecord, logger, prompt } from \"@oh-my-pi/pi-utils\";")
      "import type { AutoPrewalkDecision } from \"../auto-prewalk/classifier\";"
      "import type { Settings } from \"../config/settings\";"
      "import type { LocalProtocolOptions } from \"../internal-urls\";"
    ])
    (hunk 52 [
      " * conservatively `write`, so an MCP tool the server declared read-only is"
      " * excluded through the hint the dispatch recorded for the tool that ran."
      " */"
      (del "function isPrewalkImplementationAction(result: ToolResultMessage): boolean {")
      (add "function isPrewalkImplementationAction(result: Pick<ToolResultMessage, \"toolName\" | \"details\">): boolean {")
      "\tif (!PREWALK_ACTION_TOOLS[result.toolName]) return false;"
      "\tconst details = result.details;"
      "\t// A direct filesystem edit/write carries no `xd://` dispatch metadata."
    ])
    (hunk 312 [
      "\t\t\tthis.#disarmNoop(prewalk);"
      "\t\t\treturn;"
      "\t\t}"
      (del "\t\tif (context.toolResults.some(result => result.toolName === \"todo\" && !result.isError)) this.#todoSeen = true;")
      (add "\t\tconst directTodoSeen = this.#todoSeen || context.toolResults.some(result => result.toolName === \"todo\" && !result.isError);")
      (add "\t\tconst todoRequired = this.#host.getActiveToolNames().includes(\"todo\");")
      (add "\t\tlet action: string | undefined;")
      (add "\t\tfor (const result of context.toolResults) {")
      (add "\t\t\tif (result.toolName === \"todo\" && !result.isError) this.#todoSeen = true;")
      (add "\t\t\tif ((directTodoSeen || this.#todoSeen || !todoRequired) && isPrewalkImplementationAction(result)) action ??= result.toolName;")
      (add "\t\t\tif (result.toolName !== \"eval\" || !isRecord(result.details) || !Array.isArray(result.details.cells)) continue;")
      (add "\t\t\tfor (const cell of result.details.cells) {")
      (add "\t\t\t\tif (!isRecord(cell) || !Array.isArray(cell.statusEvents)) continue;")
      (add "\t\t\t\tfor (const event of cell.statusEvents) {")
      (add "\t\t\t\t\tif (!isRecord(event) || event.hasError === true || event.error !== undefined) continue;")
      (add "\t\t\t\t\tif (event.op === \"todo\" && event.committed === true) this.#todoSeen = true;")
      (add "\t\t\t\t\tif (")
      (add "\t\t\t\t\t\t(this.#todoSeen || !todoRequired) &&")
      (add "\t\t\t\t\t\ttypeof event.op === \"string\" &&")
      (add "\t\t\t\t\t\tPREWALK_ACTION_TOOLS[event.op] === true &&")
      (add "\t\t\t\t\t\tisPrewalkImplementationAction({ toolName: event.op, details: event })")
      (add "\t\t\t\t\t) action ??= event.op;")
      (add "\t\t\t\t}")
      (add "\t\t\t}")
      (add "\t\t}")
      ""
      "\t\tconst hasToolResults = context.toolResults.length > 0;"
      "\t\tif (this.#planInjected && hasToolResults) {"
    ])
    (hunk 329 [
      "\t\t\t});"
      "\t\t}"
      ""
      (del "\t\tconst todoGateOpen = this.#todoSeen || !this.#host.getActiveToolNames().includes(\"todo\");")
      (del "\t\tconst action = todoGateOpen")
      (del "\t\t\t? context.toolResults.find(result => isPrewalkImplementationAction(result))")
      (del "\t\t\t: undefined;")
      "\t\tif (!action) {"
      "\t\t\tif (!this.#planInjected) {"
      "\t\t\t\tthis.#planInjected = true;"
    ])
    (hunk 376 [
      "\t\t}"
      "\t\tthis.#host.emitNotice("
      "\t\t\t\"info\","
      (del "\t\t\t`Prewalk: switched to \${target.provider}/\${target.id} after first \${action.toolName} call.`,")
      (add "\t\t\t`Prewalk: switched to \${target.provider}/\${target.id} after first \${action} call.`,")
      "\t\t\t\"prewalk\","
      "\t\t);"
      "\t\tthis.#host.agent.steer({"
    ])
  ])
  (file "packages/coding-agent/src/eval/js/tool-bridge.ts" [
    (hunk 104 [
      "\t\t\t\top: \"write\","
      "\t\t\t\tpath: record.path,"
      "\t\t\t\tchars: typeof record.content === \"string\" ? record.content.length : 0,"
      (add "\t\t\t\t...(details.xdev ? { xdev: isRecord(details.xdev) ? { tier: details.xdev.tier, readOnlyHint: details.xdev.readOnlyHint } : {} } : {}),")
      "\t\t\t});"
      "\t\tcase \"grep\":"
      "\t\t\treturn withError({"
    ])
  ])
]
