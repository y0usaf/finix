{
  and,
  and-key,
  append,
  apply,
  bind-key,
  blank,
  case,
  collect,
  constant,
  context,
  define-extension,
  defun,
  destructuring-bind,
  equal,
  exec-async,
  first,
  floor,
  for,
  format,
  from,
  function,
  getf,
  if',
  in',
  in-package,
  intern,
  keyboard-grab,
  kw,
  length,
  let',
  list,
  loop,
  menu-choice,
  min,
  mod,
  multiple-value-bind,
  nconc,
  nil,
  nth,
  or',
  quote,
  rows,
  second,
  setf,
  shader-wallpaper,
  shell-surface,
  str,
  t,
  theme,
  third,
  ui,
  uninterned,
  values,
  when,
  ...
}: ({shader-wallpaper--menu}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({
    shaders,
    chosen,
    outputs,
  }:
    rows [
      [defun shader-wallpaper--menu [shaders chosen outputs]]
      ({
        width,
        height,
        gap',
        border,
      }:
        rows [
          [destructuring-bind [and-key width height gap' border] [getf (constant shader-wallpaper) (kw "preview")]]
          ({count}:
            rows [
              [let' [[count [length shaders]]]]
              (rows [
                [
                  "list*"
                  (rows [
                    [shell-surface (kw "shader-menu") [ui (kw "column") (kw "on-click") (kw "cancel") (kw "background") (str "#00000066")]]
                    [(kw "anchors") (quote [(kw "top") (kw "right") (kw "bottom") (kw "left")]) (kw "layer") (kw "overlay")]
                    [(kw "background") (str "#00000000") (kw "blur") t]
                  ])
                ]
                [[keyboard-grab]]
                [[bind-key nil (str "Left") (kw "up")] [bind-key nil (str "h") (kw "up")]]
                [[bind-key nil (str "Right") (kw "down")] [bind-key nil (str "l") (kw "down")]]
                [[bind-key nil (str "Return") (kw "select")] [bind-key nil (str "Escape") (kw "cancel")]]
                ({
                  output,
                  scale,
                  output-width,
                  output-height,
                  tile-width,
                  tile-height,
                  left,
                  top,
                }:
                  rows [
                    [loop for output in' outputs]
                    [for scale "=" [getf output (kw "scale-120") 120]]
                    [for output-width "=" [floor ["*" [getf output (kw "width")] 120] scale]]
                    [for output-height "=" [floor ["*" [getf output (kw "height")] 120] scale]]
                    [for tile-width "=" [min width [floor ["-" output-width ["*" ["1+" count] gap']] count]]]
                    [for tile-height "=" [floor ["*" height tile-width] width]]
                    [for left "=" [floor ["-" output-width ["-" ["*" count ["+" tile-width gap']] gap']] 2]]
                    [for top "=" [floor ["-" output-height tile-height] 2]]
                    [
                      nconc
                      ({
                        path,
                        fps,
                        index,
                      }:
                        rows [
                          [loop for [path fps] in' shaders]
                          [for index from 0]
                          [
                            collect
                            (rows [
                              shell-surface
                              (rows [
                                [intern [format nil (str "SHADER-PREVIEW-~A-~D") [getf output (kw "name")] index]]
                                (kw "keyword")
                              ])
                              (rows [
                                [ui (kw "stack") (kw "width") tile-width (kw "height") tile-height]
                                [(kw "border") [if' ["=" index chosen] border 0]]
                                [(kw "border-color") [theme (kw "accent")]]
                                [(kw "on-click") [intern [format nil (str "SELECT-~D") index] (kw "keyword")]]
                                [(kw "on-hover") [intern [format nil (str "HOVER-~D") index] (kw "keyword")]]
                              ])
                              [(kw "output") [getf output (kw "name")] (kw "anchors") (quote [(kw "top") (kw "left")])]
                              [(kw "margin") [list top 0 0 ["+" left ["*" index ["+" tile-width gap']]]]]
                              [(kw "width") tile-width (kw "height") tile-height (kw "layer") (kw "overlay")]
                              [(kw "background") [list (kw "shader") path (kw "fps") fps]]
                            ])
                          ]
                        ])
                    ]
                  ])
              ])
            ])
        ])
    ])
  blank
  ({
    snapshot,
    state,
    event,
  }:
    rows [
      [define-extension (str "shader-wallpaper") [(kw "reads") [(kw "key") (kw "ui") (kw "outputs")] (kw "state") nil] [snapshot state event]]
      ({
        shaders,
        count,
      }:
        rows [
          [
            "let*"
            (rows [
              [[shaders [getf (constant shader-wallpaper) (kw "shaders")]]]
              [[count [length shaders]]]
            ])
          ]
          ({
            index,
            menu,
          }:
            rows [
              [destructuring-bind [and-key [index 0] menu] state]
              (rows [
                [when [equal [getf event (kw "owner")] (str "shader-wallpaper")]]
                (rows [
                  [if' [equal [getf event (kw "command")] (str "menu")]]
                  [[setf menu index]]
                  ({
                    action',
                    choice,
                  }:
                    rows [
                      [multiple-value-bind [action' choice] [and menu [menu-choice event menu count]]]
                      (rows [
                        [case action']
                        [[(kw "select") [setf index choice menu nil]]]
                        [[(kw "cancel") [setf menu nil]]]
                        [[(kw "move") [setf menu choice]]]
                      ])
                    ])
                ])
              ])
              [[setf index [mod index count] menu [and menu [mod menu count]]]]
              ({
                shown,
                command,
              }:
                rows [
                  [
                    let'
                    (rows [
                      [[shown [nth [or' menu index] shaders]]]
                      [[command [third [nth index shaders]]]]
                    ])
                  ]
                  (rows [
                    [values [list (kw "index") index (kw "menu") menu]]
                    (rows [
                      ["list*" [apply (function bind-key) [getf (constant shader-wallpaper) (kw "bind")]]]
                      (rows [
                        [shell-surface (kw "shader-wallpaper") [ui (kw "stack")]]
                        [(kw "anchors") (quote [(kw "top") (kw "right") (kw "bottom") (kw "left")]) (kw "layer") (kw "background")]
                        [(kw "background") [list (kw "shader") [first shown] (kw "fps") [second shown]]]
                      ])
                      (rows [
                        [append [when command [list [exec-async (kw "theme") command]]]]
                        [[when menu [shader-wallpaper--menu shaders menu [context snapshot (kw "outputs")]]]]
                      ])
                    ])
                    nil
                  ])
                ])
            ])
        ])
    ])
])
