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
;;; grains at the bottom of the voice chamber: the grains hop with the level
;;; history, a wave travelling out along the focused card's frame from the rail
;;; and across the bed, and when the turn closes the hops shrink with the same
;;; envelope the rest of the bar uses instead of snapping flat.
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
(defparameter +rail-sand--settle+ 0.7d0)
(defparameter +rail-sand--gravity+ 36000d0)
(defparameter +rail-sand--top+ 16800d0)
(defparameter +rail-sand--flow+ 10400d0)
(defparameter +rail-sand--levels+ 48)
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

(defun rail-sand--sections (state snapshot)
  (let ((meter (getf state :rail-meter))
        (targets (rail--meter-targets state))
        (cpu (getf state :cpu))
        (gpu (getf state :gpu)))
    (loop for module in (getf +rail+ :modules)
          for section
            = (case module
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
                (t nil))
          when section collect section)))

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
        +rail-sand--settle+
        (or focus -1) (or old -1) (if moving 1 0)))

(defun rail-sand--gauge-data (section)
  (append (rail-sand--pack (getf section :label))
          (rail-sand--pack (getf section :value))
          (rail-sand--pack (getf section :detail))
          (list (if (getf section :hot) 1 0)
                (getf section :kind 0)
                (getf section :pct 0)
                (getf section :trend 0))))

(defun rail-sand--tube-data (state snapshot seam clock voicing fade)
  (let* ((x0 (getf seam :x))
         (x1 (+ x0 (getf seam :width)))
         (y0 (getf seam :y))
         (y1 (+ y0 (getf seam :height)))
         (vy1 (+ y0 (round (* (- y1 y0) +rail-sand--voice-height+))))
         (found (rail-sand--sections state snapshot))
         (sections (subseq found 0 (min +rail-sand--slots+ (length found))))
         (gy (+ vy1 +rail-sand--gauges+))
         (gn (length sections))
         (gh (if (plusp gn) (floor (- y1 gy) gn) 0))
         (day (string-upcase (clock-text "%a")))
         (date (clock-text "%d"))
         (hour (clock-text "%H"))
         (minute (clock-text "%M"))
         (voice (cassette--bolo-turn-p (getf state :bolo-state))))
    (append (rail-sand--head 1 (list x0 y0) (+ x0 (floor (- x1 x0) 2))
                             state clock voicing fade)
            (list x0 x1 y0 y1 vy1
                  (+ vy1 +rail-sand--date+) (+ vy1 +rail-sand--date2+)
                  (+ vy1 +rail-sand--clock+) (+ vy1 +rail-sand--clock2+)
                  gy gn gh)
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

(defun rail-sand--draw (look context)
  "sand: the poured frames over the output and the glass tube down the seam."
  (declare (ignore look))
  (destructuring-bind (&key state snapshot epoch now seam output carried key switch old
                         windows voice voicing fade layer cut &allow-other-keys)
      context
    (let* ((clock (rail--epoch now))
           (focus (and key (position (getf key :id) windows)))
           (oldi (and old (position old windows)))
           (at (and switch (getf switch :at)))
           (moving (and at (not cut) (<= 0 (- now at)) (< (- now at) +rail-sand--settle+)))
           (vopen (and voice (cassette--bolo-turn-p (getf state :bolo-state))))
           (end (cond (vopen (+ now 3600d0))
                      (moving (+ at +rail-sand--settle+))
                      ((and (not voice) (realp fade)) (+ fade (getf +rail--voice+ :settle)))
                      (t nil)))
           (until (if end (- end clock) 0d0))
           (shader (getf look :shader))
           (mid (+ (getf seam :x) (floor (getf seam :width) 2))))
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
                                :reach (unless moving (rail--design 40))))
             (shell-surface
              :rail-slab (ui :stack)
              :output (getf output :name) :anchors '(:top :left)
              :width (rail--design (getf seam :width))
              :height (rail--design (getf seam :height))
              :margin (rail--surface-margin output (getf seam :x) (getf seam :y))
              :layer layer :click-through t
              :background (list :shader shader
                                :data (rail-sand--tube-data state snapshot seam clock voicing fade)
                                :clock clock
                                :until until)))
       (unless (getf +rail+ :focus-border)
         (loop for entry in carried
               collect (window-properties
                        (getf entry :id)
                        :radius (rail--design 0)
                        :border (list :focused "#00000000"
                                      :unfocused "#00000000"))))))))

(defparameter +rail-sand+
  (list :draw #'rail-sand--draw :cast +rail-sand--cast+
        :frame (list :edge 12 :title 0)))
