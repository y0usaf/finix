{
  constant,
  declare,
  define-extension,
  getf,
  ignore,
  in-package,
  kw,
  list,
  nil,
  sound,
  sounds,
  str,
  uninterned,
  values,
  ...
}: [
  [in-package (uninterned "tomoe-user")]
  ({
    snapshot,
    state,
    event,
  }: [define-extension (str "sounds") [] [snapshot state event] [declare [ignore snapshot event]] [values state [list [sound (kw "key") [getf (constant sounds) (kw "key")] (kw "gain") [getf (constant sounds) (kw "key-gain")]] [sound (kw "button") [getf (constant sounds) (kw "button")] (kw "gain") [getf (constant sounds) (kw "button-gain")]] [sound (kw "close") [getf (constant sounds) (kw "close")] (kw "gain") [getf (constant sounds) (kw "close-gain")]]] nil]])
]
