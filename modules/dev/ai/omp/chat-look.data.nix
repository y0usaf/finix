{
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
])
