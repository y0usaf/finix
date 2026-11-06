{
  and,
  cond,
  copy-list,
  defun,
  ecase,
  first,
  getf,
  if',
  in-package,
  kw,
  let',
  max,
  min,
  plusp,
  round,
  setf,
  uninterned,
  when,
  ...
}: ({
  probe--sample',
  probe--gpu-p',
}: [
  [in-package (uninterned "tomoe-user")]
  ({
    probe,
    previous,
    system,
  }: [
    defun
    probe--sample'
    [probe previous system]
    ({sample}: [
      let'
      [[sample [copy-list previous]]]
      [
        ecase
        probe
        [
          (kw "cpu")
          ({
            total,
            idle,
          }: [let' [[total [getf system (kw "cpu-total")]] [idle [getf system (kw "cpu-idle")]]] [when total ({spent}: [let' [[spent ["-" total [getf sample (kw "total") total]]]] [setf [getf sample (kw "percent")] [if' [plusp spent] [max 0 [min 100 [round ["*" 100 ["-" spent ["-" idle [getf sample (kw "idle") idle]]]] spent]]] [getf sample (kw "percent") 0]] [getf sample (kw "total")] total [getf sample (kw "idle")] idle [getf sample (kw "temp")] [getf system (kw "cpu-temperature")]]])]])
        ]
        [
          (kw "memory")
          ({
            total,
            available,
          }: [let' [[total [getf system (kw "memory-total")]] [available [getf system (kw "memory-available")]]] [when [and total [plusp total]] [setf [getf sample (kw "percent")] [round ["*" 100 ["-" total available]] total] [getf sample (kw "used")] [round ["-" total available] 1024]]]])
        ]
        [(kw "gpu") ({gpu}: [let' [[gpu [first [getf system (kw "gpus")]]]] [cond [gpu [setf [getf sample (kw "percent")] [max 0 [min 100 [getf gpu (kw "busy")]]] [getf sample (kw "used")] [getf gpu (kw "vram-used")] [getf sample (kw "total")] [getf gpu (kw "vram-total")] [getf sample (kw "temp")] [getf gpu (kw "temperature")] [getf sample (kw "failures")] 0]] [system [setf [getf sample (kw "failures")] ["1+" [getf sample (kw "failures") 0]]]]]])]
      ]
      sample
    ])
  ])
  ({gpu}: [defun probe--gpu-p' [gpu] [and [getf gpu (kw "percent")] ["<" [getf gpu (kw "failures") 0] 3]]])
])
