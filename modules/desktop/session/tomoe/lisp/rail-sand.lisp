(in-package #:tomoe-user)

;;; sand
;;;
;;; Pixels are matter. A card's frame is packed sand: three rows of four pixel
;;; grains, each grain its own tone, a few catching the light, square at the
;;; corners, filling the room the deck leaves round the card. A card the rail is
;;; not focused on is left as a dusting of loose grains along its inner edge.
;;; The seam between the columns is the glass tube the sand comes from: a dark
;;; bore behind two bright edges, the date and the clock cast in grains, and the
;;; readings piled as sand in glass compartments.
;;;
;;; Focus is a pour. When focus leaves a card its frame lets go: the grains drop
;;; from the top edge, drift as they fall, and run along the bottom edge into the
;;; tube, while the inner dusting stays where it was. The card that takes focus
;;; is poured out of the tube: its top edge fills from the far end toward the
;;; rail with a spray hopping ahead of each landing, then grains fall down the
;;; two sides so each column fills from the bottom up, and last the bottom edge
;;; runs in from both corners. Every grain is a closed form of its cell, the time
;;; since the switch and a hash of the cell -- the shader integrates nothing and
;;; nothing is simulated on the CPU -- so a frame is as cheap to draw at any
;;; point of the motion, and both surfaces hold their last picture once the
;;; motion has landed. Gravity, the pour and flow speeds, the ring's width and
;;; the settle are +RAIL-SAND--...+ parameters.
;;;
;;; The tube's compartments are levels of sand: each fills from its glass floor,
;;; its surface mounded while the reading climbs and dented while it falls, a
;;; thin stream falling into it while it rises, and the top rows red when the
;;; probe runs hot. The levels draw the rail's glided readings, so they move with
;;; the numbers rather than jumping once a second. Bolo's voice is the bed of
;;; grains at the bottom of the voice chamber and the focused card's frame: the
;;; grains hop with the level history, a wave travelling out round the frame
;;; from the rail and across the bed. Only that card's own ring of grains hops,
;;; so the frame shows which card is being spoken into; every other card's
;;; dusting stays still, and with no card in focus the bed alone speaks. When
;;; the turn closes the hops shrink with the same envelope the rest of the bar
;;; uses instead of snapping flat.
;;;
;;; The palette is SAND's: warm ground tones on near black in dark, dark grains
;;; on warm paper in light, one red for a hot probe.

(defparameter +rail-sand--cast+
  (list :dark (list :tones '("#EEE9DE" "#CCC6BA" "#A6A094" "#807C72")
                    :glint "#FFFDF4" :dust "#605E58" :glass "#5C5A56" :glass-hi "#96948E"
                    :inside "#0E0E12" :ink "#ECE7DC" :dim "#78756E" :red "#EC5040")
        :light (list :tones '("#282827" "#464440" "#64615B" "#827E76")
                     :glint "#0A0A0A" :dust "#AAA69C" :glass "#A09C94" :glass-hi "#FFFFFF"
                     :inside "#ECE9E2" :ink "#222221" :dim "#848078" :red "#C8321E")))

(defparameter +rail-sand--grain+ 4)
(defparameter +rail-sand--ring+ 12)
;; seconds the pour was drawn for: sand's own choreography, which the rail now
;; times (shaders/sand.glsl DESIGN uses the same number)
(defparameter +rail-sand--settle+ 0.7d0)
(defparameter +rail-sand--gravity+ 36000d0)
(defparameter +rail-sand--top+ 16800d0)
(defparameter +rail-sand--flow+ 10400d0)
(defparameter +rail-sand--levels+ 32)
;; the readings a tube carries: every module the config names can have one, so
;; media, CPU, memory, the GPU, its video memory and the frame's battery all
;; draw, and the tube's numbers still fit the 192 a surface's data may hold
(defparameter +rail-sand--slots+ 6)

(defparameter +rail-sand--voice-height+ 0.30d0)
(defparameter +rail-sand--date+ 20)
(defparameter +rail-sand--date2+ 48)
(defparameter +rail-sand--clock+ 88)
(defparameter +rail-sand--clock2+ 140)
(defparameter +rail-sand--gauges+ 200)

(defun rail-sand--code (text i n)
  (if (< i n) (char-code (char text i)) 32))

(defun rail-sand--pack (text)
  "TEXT's first four characters as two numbers, two characters each."
  (let ((n (length text)))
    (list (+ (rail-sand--code text 0 n) (* 256 (rail-sand--code text 1 n)))
          (+ (rail-sand--code text 2 n) (* 256 (rail-sand--code text 3 n))))))

(defun rail-sand--percent (percent)
  (format nil "~D%" (max 0 (min 100 (round (or percent 0))))))

(defun rail-sand--section (label percent detail hot kind target)
  (let ((shown (max 0 (min 100 (or percent 0)))))
    (list :label label :value (rail-sand--percent shown) :detail (or detail "")
          :hot hot :kind kind :pct shown
          :trend (cond ((null target) 0)
                       ((> target (+ shown 0.5)) 1)
                       ((< target (- shown 0.5)) -1)
                       (t 0)))))

(defun rail-sand--media (snapshot)
  (let ((played (rail--media-played snapshot)))
    (when played
      (destructuring-bind (status fraction) played
        (rail-sand--section "MED" (* 100d0 fraction) "" nil 1 nil)))))

(defun rail-sand--battery (snapshot key)
  (let* ((frame (eq key :frame-battery))
         (battery (if frame (state-value snapshot :frame-battery)
                      (service-state snapshot :battery)))
         (charging (if frame (not (equal (getf battery :status) "Discharging"))
                       (getf battery :charging))))
    (when (realp (getf battery :percent))
      (rail-sand--section (cond ((and frame charging) "VR+")
                                (frame "VR")
                                (charging "CHG")
                                (t "BAT"))
                          (getf battery :percent) "" nil 0 nil))))

(defun rail-sand--section-of (module state snapshot)
  (let ((meter (getf state :rail-meter))
        (targets (rail--meter-targets state))
        (cpu (getf state :cpu))
        (gpu (getf state :gpu)))
    (case module
                (:media (rail-sand--media snapshot))
                (:cpu (rail-sand--section "CPU" (getf meter :cpu)
                                          (cassette--degrees (getf cpu :temp))
                                          (cassette--hot-p (getf cpu :temp)) 0 (getf targets :cpu)))
                (:memory (rail-sand--section "MEM" (getf meter :memory)
                                             (rail--digits (getf meter :memory-used))
                                             nil 0 (getf targets :memory)))
                (:gpu (when (probe--gpu-p gpu)
                        (rail-sand--section "GPU" (getf meter :gpu)
                                            (cassette--degrees (getf gpu :temp))
                                            (cassette--hot-p (getf gpu :temp)) 0 (getf targets :gpu))))
                (:vram (when (probe--gpu-p gpu)
                         (rail-sand--section "VRAM" (getf meter :vram)
                                             (rail--digits (getf meter :vram-used))
                                             nil 0 (getf targets :vram))))
                (:battery (rail-sand--battery snapshot :battery))
                (:frame (rail-sand--battery snapshot :frame-battery))
      (t nil))))

(defun rail-sand--sections (state snapshot)
  (loop for module in (getf +rail+ :modules)
        for section = (rail-sand--section-of module state snapshot)
        when section collect section))

(defun rail-sand--modules (state snapshot)
  "The modules sand draws a compartment for, in the bar's order."
  (loop for module in (getf +rail+ :modules)
        when (rail-sand--section-of module state snapshot) collect module))

(defun rail-sand--head (mode origin mid state clock voicing fade)
  (let* ((cast (getf +rail-sand--cast+ *rail--mode*))
         (history (if voicing (getf state :bolo-history) nil))
         (levels (subseq history 0 (min +rail-sand--levels+ (length history))))
         (voice (cassette--bolo-turn-p (getf state :bolo-state))))
    (append (list mode (first origin) (second origin) +rail-sand--grain+ +rail-sand--ring+ mid)
            (loop for hex in (getf cast :tones) append (rail--rgb hex))
            (rail--rgb (getf cast :glint))
            (rail--rgb (getf cast :dust))
            (rail--rgb (getf cast :glass))
            (rail--rgb (getf cast :glass-hi))
            (rail--rgb (getf cast :inside))
            (rail--rgb (getf cast :ink))
            (rail--rgb (getf cast :dim))
            (rail--rgb (getf cast :red))
            (list +rail-sand--gravity+ +rail-sand--top+ +rail-sand--flow+)
            (list (if voice 1 0)
                  (if (realp (getf state :bolo-since))
                      (- (getf state :bolo-since) clock)
                      -1d9)
                  (if (realp fade) (- fade clock) -1d9)
                  (getf +rail--voice+ :settle) (getf +rail--voice+ :rise) (length levels))
            levels
            (loop repeat (- +rail-sand--levels+ (length levels)) collect 0))))

(defun rail-sand--motion (switch clock focus old moving)
  (list (if switch (- (getf switch :at) clock) -1d9)
        (rail--settle switch)
        (or focus -1) (or old -1) (if moving 1 0)))

(defun rail-sand--gauge-data (section)
  (append (rail-sand--pack (getf section :label))
          (rail-sand--pack (getf section :value))
          (rail-sand--pack (getf section :detail))
          (list (if (getf section :hot) 1 0)
                (getf section :kind 0)
                (getf section :pct 0)
                (getf section :trend 0))))

(defun rail-sand--tube-data (state snapshot strip blocks clock voicing fade)
  "The tube's numbers: the palette and bolo's turn, the tube's rect and axis, the
compartment blocks, then the text and the readings."
  (let* ((x0 (getf strip :x))
         (y0 (getf strip :y))
         (x1 (+ x0 (getf strip :width)))
         (y1 (+ y0 (getf strip :height)))
         (mid (+ x0 (floor (getf strip :width) 2)))
         (found (rail-sand--sections state snapshot))
         (sections (subseq found 0 (min +rail-sand--slots+ (length found))))
         (day (string-upcase (clock-text "%a")))
         (date (clock-text "%d"))
         (hour (clock-text "%H"))
         (minute (clock-text "%M"))
         (voice (cassette--bolo-turn-p (getf state :bolo-state))))
    (append (rail-sand--head 1 (list x0 y0) mid state clock voicing fade)
            (list x0 x1 y0 y1 (if (eq (getf strip :axis) :y) 0d0 1d0))
            (rail-sand--block-data strip blocks)
            (rail-sand--pack day)
            (rail-sand--pack date)
            (rail-sand--pack hour)
            (rail-sand--pack minute)
            (rail-sand--pack (if voice
                                 (cassette--bolo-clock
                                  (and (realp (getf state :bolo-since))
                                       (- (cassette--bolo-now) (getf state :bolo-since))))
                                 "MIC"))
            (list (if voice 1 0))
            (loop for section in sections append (rail-sand--gauge-data section)))))

;; The blocks a tube's shader reads: bolo's bed, the day, the clock and one
;; compartment for each of the six readings a bar can carry -- nine, and no more
;; than the shader's data list holds beside the palette, the type and the gauges.
(defparameter +rail-sand--blocks-max+ 9)

(defun rail-sand--block-data (strip blocks)
  "BLOCKS as sand.glsl reads them: how many, then each one's kind and the start
and end of its run along STRIP's axis, in output pixels from the strip's corner.
A compartment always spans the strip across that axis, so its other two sides are
the tube's own; the table is padded to +RAIL-SAND--BLOCKS-MAX+ so the type and the
readings that follow it keep their indices however few compartments a bar
carries."
  (let* ((vertical (eq (getf strip :axis) :y))
         (origin (if vertical (getf strip :y) (getf strip :x)))
         (shown (subseq blocks 0 (min +rail-sand--blocks-max+ (length blocks)))))
    (append (list (length shown))
            (loop for (module x y width height) in shown
                  for from = (+ origin (if vertical y x))
                  append (list (rail--kind module) from
                               (+ from (if vertical height width))))
            (make-list (* 3 (max 0 (- +rail-sand--blocks-max+ (length shown))))
                       :initial-element 0))))

(defparameter +rail-sand--strip-height+ 96)

(defun rail-sand--seam-blocks (state snapshot strip)
  "The seam's compartments as blocks from STRIP's corner: bolo's bed over the top
three tenths, the day and the date, the clock, then a compartment for each
reading, in the tube's own proportions."
  (let* ((height (getf strip :height))
         (voice (round (* height +rail-sand--voice-height+)))
         (modules (rail-sand--modules state snapshot))
         (n (min (length modules) +rail-sand--slots+))
         (compartment (if (plusp n) (floor (- height voice 200) n) 0))
         (specs (append (list (list :voice voice 0)
                              (list :date 48 20)
                              (list :time 92 20))
                        (loop for module in (subseq modules 0 n)
                              for i from 0
                              collect (list module compartment (if (zerop i) 20 0))))))
    (rail--strip-blocks state snapshot strip specs (cons :voice 0))))

(defun rail-sand--bar-modules (state snapshot place)
  "The blocks a bar at PLACE carries: the clock and the date along the top bar,
the compartments and bolo's bed along the bottom. A bar carries the same readings
the tube's numbers do -- no more -- so every compartment has its record."
  (if (eq place :top)
      (loop for module in '(:time :date)
            when (rail--height module state snapshot) collect module)
      (let ((modules (rail-sand--modules state snapshot)))
        (append (subseq modules 0 (min +rail-sand--slots+ (length modules)))
                (when (cassette--bolo-turn-p (getf state :bolo-state))
                  (list :voice))))))

(defun rail-sand--blocks (state snapshot strip)
  "STRIP's blocks: the tube's own compartments in a seam, one equal slot each
along a bar."
  (if (eq (getf strip :place) :seam)
      (rail-sand--seam-blocks state snapshot strip)
      (rail--bar-blocks state snapshot strip
                        (rail-sand--bar-modules state snapshot (getf strip :place)))))

(defun rail-sand--draw (look context)
  "sand: the poured frames over the output and the glass tube down the seam, or
along each bar."
  (declare (ignore look))
  (destructuring-bind (&key state snapshot epoch now seam output carried key switch old
                         windows voice voicing fade layer cut strips &allow-other-keys)
      context
    (let* ((clock (rail--epoch now))
           (focus (and key (position (getf key :id) windows)))
           (oldi (and old (position old windows)))
           (at (and switch (getf switch :at)))
           (moving (and at (not cut) (<= 0 (- now at)) (< (- now at) (rail--settle switch))))
           (vopen (and voice (cassette--bolo-turn-p (getf state :bolo-state))))
           (end (cond (vopen (+ now 3600d0))
                      (moving (+ at (rail--settle switch)))
                      ((and (not voice) (realp fade)) (+ fade (getf +rail--voice+ :settle)))
                      (t nil)))
           (until (if end (- end clock) 0d0))
           (shader (getf look :shader))
           (probe (first strips))
           (mid (if probe
                    (+ (getf probe :x) (floor (getf probe :width) 2))
                    (+ (getf output :x) (floor (getf output :width) 2)))))
      (when probe
        (append
         (list (shell-surface
                :rail-frames (ui :stack)
                :output (getf output :name) :anchors '(:top :left)
                :width (rail--design (getf output :width))
                :height (rail--design (getf output :height))
                :layer layer :click-through t
                :background (list :shader shader
                                  :data (append (rail-sand--head 0
                                                                 (list (getf output :x) (getf output :y))
                                                                 mid state clock voicing fade)
                                                (rail-sand--motion switch clock focus oldi moving))
                                  :windows windows :clock clock
                                  :until until
                                  :reach (unless moving (rail--design 40)))))
         (loop for strip in strips
               for seam-p = (eq (getf strip :place) :seam)
               for tag = (if seam-p "" (format nil "-~A" (string-upcase (symbol-name (getf strip :place)))))
               for blocks = (rail-sand--blocks state snapshot strip)
               append
               (list (shell-surface
                      (intern (format nil "RAIL-SAND~A" tag) :keyword)
                      (ui :stack)
                      :output (getf output :name)
                      :anchors (if seam-p (list :top :left) (list (getf strip :place)))
                      :width (rail--design (getf strip :width))
                      :height (rail--design (getf strip :height))
                      :margin (if seam-p
                                  (rail--surface-margin output (getf strip :x) (getf strip :y))
                                  0)
                      :layer layer :click-through t
                      :exclusive-zone (if seam-p 0 (rail--design (getf strip :height)))
                      :background (list :shader shader
                                        :data (rail-sand--tube-data
                                               state snapshot strip blocks clock voicing fade)
                                        :clock clock
                                        :until until))))
         (unless (getf +rail+ :focus-border)
           (loop for entry in carried
                 collect (window-properties
                          (getf entry :id)
                          :radius (rail--design 0)
                          :border (list :focused "#00000000"
                                        :unfocused "#00000000")))))))))

(defparameter +rail-sand+
  (list :draw #'rail-sand--draw :cast +rail-sand--cast+
        :strip-height +rail-sand--strip-height+
        :frame (list :edge 12 :title 0)
        :trail (list :cell 6d0 :life 0.6d0 :steps 6 :shape :cells
                     :dark :glint :light :glint)))
