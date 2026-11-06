{
  blank,
  collect,
  cons,
  constant,
  context,
  declare,
  define-extension,
  defun,
  expt,
  for,
  getf,
  glass,
  ignore,
  in',
  in-package,
  kw,
  loop,
  min,
  nil,
  rows,
  settings,
  str,
  t,
  truncate,
  uninterned,
  values,
  window-properties,
  ...
}: ({glass--margin}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({
    passes,
    offset,
  }:
    rows [
      [defun glass--margin [passes offset]]
      [[min 4096 [truncate ["*" [expt 2 passes] ["+" offset 2]]]]]
    ])
  blank
  ({
    snapshot,
    state,
    event,
  }:
    rows [
      [define-extension (str "glass") [(kw "reads") [(kw "windows")] (kw "state") nil] [snapshot state event]]
      [[declare [ignore event]]]
      (rows [
        [values state]
        (rows [
          [
            cons
            [
              settings
              (kw "blur")
              (rows [
                ["list*" (kw "enabled") t]
                (kw "anti-artifact-margin")
                [[glass--margin [getf (constant glass) (kw "passes")] [getf (constant glass) (kw "offset")]]]
                (constant glass)
              ])
            ]
          ]
          ({window}:
            rows [
              [loop for window in' [context snapshot (kw "windows")]]
              [collect [window-properties [getf window (kw "id")] (kw "blur") t]]
            ])
        ])
        nil
      ])
    ])
])
