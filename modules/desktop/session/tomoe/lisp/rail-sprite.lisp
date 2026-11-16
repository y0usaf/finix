(in-package #:tomoe-user)

;;; sprite
;;;
;;; The deck as a game HUD. Everything is drawn in one picture made of art
;;; pixels four screen pixels square: the windows carry a nine-slice bevelled
;;; frame with notched corners, and focus moves between them as a selection
;;; cursor -- four corner brackets that pull in and go white for a frame, fly to
;;; the new window over two eased steps leaving a dithered afterimage and a
;;; dashed smear, land with a white flash and a burst of sparks, and settle --
;;; all stepped at twenty frames a second, like a sprite sheet rather than a
;;; spring. The rail between the columns is the panel of a cabinet: a bevelled
;;; plate with a keyline and cut grooves, bolo's voice read off a two-channel VU
;;; tower whose pips light from the bottom, hold their peak for a third of a
;;; second and then fall a pip at a time, and the readings beneath it in a 3x5
;;; pixel face -- a label, a value that runs up like a score, a sixteen-pip bar
;;; whose lead pip flashes while the number counts, and a detail line that turns
;;; red over the bar it belongs to. The panel is bolted to the focused card by
;;; three clamps on its edge that flash white when a switch lands.
;;;
;;; The window frames are the theme's room to breathe: :FRAME asks the deck for
;;; :EDGE 16 px round the columns -- the mock-up's content sits four art pixels
;;; in from the screen -- and no title row, since a card in this shell is the
;;; picture itself. A focused frame is four art pixels thick -- keyline, bevel,
;;; body, keyline -- which exactly fills the space round a card that the deck
;;; leaves it, and an unfocused one keeps a single dim line; the side of a frame
;;; that faces the rail is the panel's own edge, so rail and frame read as one
;;; cabinet face.
;;;
;;; One shader draws both the frames and the panel. The rail hands it the
;;; geometry, the readings as packed characters, the switch's time and boxes
;;; and the voice's envelope, and it animates from those alone. Every surface
;;; holds its last picture once its motion has settled, so a still desktop costs
;;; nothing; the panel repaints only while a number counts or bolo speaks. The
;;; numbers reach the shader already glided by rail.lisp's own sample easing,
;;; and the tower's peaks are worked out here from the level history, so the
;;; whole animation lives in one place on the GPU.
;;;
;;; The panel's data, in the order sprite.glsl reads it: kind 0, the art grid,
;;; the section count, the tower's pips, top, pitch, pip height and edge, the
;;; bar's height, the voice's open and close times, whether the turn is open,
;;; its rise and settle, the two channels' levels and peaks, the last switch's
;;; start, the clamps' side and three heights, the voice label's length, the
;;; mode, the shelf tray's height, the label as packed characters, the date's
;;; three parts, the clock's two, six gauge slots of nine (percent, counting,
;;; hot, label, value, detail), twelve sections of four (top, height, kind,
;;; index; a slot with kind -1 is padding), the media marker and the network's
;;; label and state as packed characters, and thirteen colour triples. Every
;;; block is emitted at its full length whatever the modules ask for, so a
;;; config without a GPU or with a player running cannot shift the palette. The frames' data is its kind, grid,
;;; band, arm, notch and spark reach, the seam's x and width, the two sides, the
;;; switch's start and whether it may move, the focused and previous card's
;;; slots, its settle, the previous card's box, the voice's five numbers and
;;; level, the sprite cadence and eased steps, the spark and burst reaches, the
;;; bracket arm, pull and landing, the mode and seven colour triples.

(defparameter +rail-sprite--grid+ 4)

(defparameter +rail-sprite--panel+
  (list :header 20 :tower 64 :pitch 12 :pip 8 :echo 3 :pips 26 :hold 10
        :groove 16 :date-lead 48 :date 84 :clock-lead 56 :clock 92
        :gauge-lead 40 :gauge 152 :media-lead 40 :media 60 :net-lead 40 :net 44
        :pad 16 :edge 5 :bar 20))

(defparameter +rail-sprite--switch+
  (list :fps 20 :frames 6
        :ease (list 0d0 0.16d0 0.55d0 0.9d0 1d0 1d0)
        :spark 48 :burst 56 :arm 160 :pull 48 :land 16))

(defparameter +rail-sprite--cast+
  (list :edge 16 :title 0 :band 16 :arm 160 :notch 4 :spark 12
        :dark (list :ol "#0B0A0C" :body "#8C8068" :hi "#C6B694" :lo "#4A4337"
                    :idle "#6A6252" :acc "#69A9DC" :white "#FBF6E8"
                    :rail "#17161A" :ink "#ECE7DC" :dim "#948B77"
                    :pip "#2B2A2E" :red "#D4474F" :gfill "#B9AE93")
        :light (list :ol "#241F1A" :body "#C9BD9E" :hi "#F3E9CE" :lo "#7E735C"
                     :idle "#A99D86" :acc "#2E6C9E" :white "#FFFFFF"
                     :rail "#E5DECD" :ink "#2A2721" :dim "#786E5B"
                     :pip "#CFC6B0" :red "#B23A42" :gfill "#3B372F")))

(defun rail-sprite--rgb (key)
  "KEY of the current mode's palette as three reals."
  (rail--rgb (or (getf (getf +rail-sprite--cast+ *rail--mode*) key) "#000000")))

(defun rail-sprite--split (text)
  "TEXT's words, split on the spaces and colons a clock and a date are written
with, so the last word is never lost."
  (let ((parts nil) (start 0) (i 0))
    (loop while (< i (length text))
          do (let ((c (char text i)))
               (when (or (char= c #\:) (char= c #\Space))
                 (when (> i start) (push (subseq text start i) parts))
                 (setf start (1+ i))))
             (setf i (1+ i)))
    (when (> (length text) start) (push (subseq text start) parts))
    (reverse parts)))

(defun rail-sprite--code (string i)
  "The ASCII code of STRING's Ith character, a space past its end."
  (if (and string (< i (length string))) (char-code (char string i)) 32))

(defun rail-sprite--pack (string)
  "STRING's first four characters as ASCII codes, two to a float."
  (loop for i from 0 below 4 by 2
        collect (+ (rail-sprite--code string i) (* 256 (rail-sprite--code string (1+ i))))))

(defun rail-sprite--item (kind top height index)
  (list :kind kind :top top :height height :index index))

(defun rail-sprite--gauges (state snapshot)
  (loop for module in '(:cpu :memory :gpu :vram :frame :battery)
        when (and (member module (getf +rail+ :modules))
                  (rail--height module state snapshot))
          collect module))

(defun rail-sprite--stack (gauges date time media net pips)
  "The panel's blocks top down for a tower of PIPS."
  (let* ((p +rail-sprite--panel+)
         (spec (append (when date (list (list 2 (getf p :date-lead) (getf p :date) 0)))
                       (when time (list (list 3 (getf p :clock-lead) (getf p :clock) 0)))
                       (loop for module in gauges
                             for i from 0
                             collect (list 4 (if (zerop i) (getf p :gauge-lead) 0)
                                           (getf p :gauge) i))
                       (when media (list (list 5 (getf p :media-lead) (getf p :media)
                                                (round (* 100 (second media))))))
                       (when net (list (list 6 (getf p :net-lead) (getf p :net) 0)))))
         (sections (list (rail-sprite--item 0 (getf p :header) 20 0)
                         (rail-sprite--item 1 (getf p :tower) (* pips (getf p :pitch)) 0)))
         (y (+ (getf p :tower) (* pips (getf p :pitch)) (getf p :groove))))
    (loop for (kind lead height index) in spec
          for top = (+ y lead)
          do (setf sections (append sections (list (rail-sprite--item kind top height index)))
                   y (+ top height (getf p :groove)))
          finally (return sections))))

(defun rail-sprite--sections (state snapshot seam)
  "The panel's blocks for the modules the rail shows. The tower gives up pips
first, then the network and media blocks, then the gauges past the core four,
so a crowded module list still lands inside the seam."
  (let* ((p +rail-sprite--panel+)
         (modules (getf +rail+ :modules))
         (bottom (- (getf seam :height) (getf p :pad)))
         (gauges (rail-sprite--gauges state snapshot))
         (date (and (member :date modules) t))
         (time (and (member :time modules) t))
         (media (and (member :media modules) (rail--media-played snapshot)))
         (net (when (member :network modules)
                (list :online (getf (service-state snapshot :network) :connected)))))
    (labels ((fits-p (sections)
               (let ((last (car (last sections))))
                 (<= (+ (getf last :top) (getf last :height)) bottom)))
             (fit (pips gauges media net)
               (let ((sections (rail-sprite--stack gauges date time media net pips)))
                 (cond ((fits-p sections) sections)
                       ((> pips 8) (fit 8 gauges media net))
                       (net (fit pips gauges media nil))
                       (media (fit pips gauges nil nil))
                       ((> (length gauges) 5) (fit pips (subseq gauges 0 5) nil nil))
                       ((> (length gauges) 4) (fit pips (subseq gauges 0 4) nil nil))
                       (t sections)))))
      (let ((sections (fit (getf p :pips) gauges media net)))
        (subseq sections 0 (min 12 (length sections)))))))

(defun rail-sprite--ramp (a b x)
  "Zero at A, one at B, smooth between."
  (let ((u (max 0d0 (min 1d0 (/ (- (coerce x 'double-float) a)
                                (max 1d-6 (- (coerce b 'double-float) a)))))))
    (* u u (- 3d0 (* 2d0 u)))))

(defun rail-sprite--amp (state now)
  "The voice's envelope at NOW: up over the rise, down over the settle."
  (let* ((v +rail--voice+)
         (since (getf state :bolo-since))
         (fade (getf state :bolo-fade))
         (rise (getf v :rise))
         (settle (getf v :settle)))
    (cond ((and (realp fade) (realp since) (> now fade))
           (* (rail-sprite--ramp since (+ since rise) fade)
              (- 1d0 (rail-sprite--ramp fade (+ fade settle) now))))
          ((realp since) (rail-sprite--ramp since (+ since rise) now))
          (t 0d0))))

(defun rail-sprite--peak (levels amp pips skip hold)
  "The tower's peak in pips: the highest level in the history less a pip for
every sample past HOLD, so a quiet voice lets the peak fall a pip at a time."
  (let ((peak 0))
    (loop for level in levels
          for j from 0 below 20
          do (setf peak (max peak (- (round (* amp level pips)) (max 0 (- j hold))))))
    (max 0 peak)))

(defun rail-sprite--gauge (state snapshot module)
  "MODULE's reading: its percent, whether the number is counting, whether it is
running hot, and its label, value and detail."
  (let* ((meter (getf state :rail-meter))
         (cpu (getf state :cpu))
         (gpu (getf state :gpu))
         (sample (case module
                   (:cpu (getf meter :cpu))
                   (:memory (getf meter :memory))
                   (:gpu (getf meter :gpu))
                   (:vram (getf meter :vram))
                   (:frame (getf (state-value snapshot :frame-battery) :percent))
                   (:battery (getf (service-state snapshot :battery) :percent))
                   (t 0)))
         (target (case module
                   (:cpu (getf (getf state :cpu) :percent))
                   (:memory (getf (getf state :memory) :percent))
                   (:gpu (getf (getf state :gpu) :percent))
                   (:vram 0)
                   (:frame (getf (state-value snapshot :frame-battery) :percent))
                   (:battery (getf (service-state snapshot :battery) :percent))
                   (t 0)))
         (shown (max 0 (min 100 (round (or sample 0)))))
         (counting (if (and (realp sample) (realp target) (> (abs (- target sample)) 0.6)) 1 0))
         (hot (and (member module '(:cpu :gpu))
                   (cassette--hot-p (getf (if (eq module :cpu) cpu gpu) :temp))))
         (label (case module
                  (:cpu "CPU") (:memory "MEM") (:gpu "GPU") (:vram "VRAM")
                  (:frame (if (equal (getf (state-value snapshot :frame-battery) :status)
                                     "Discharging") "VR" "VR+"))
                  (:battery (if (getf (service-state snapshot :battery) :charging)
                                "CHG" "BAT"))))
         (detail (case module
                   (:cpu (cassette--degrees (getf cpu :temp)))
                   (:gpu (cassette--degrees (getf gpu :temp)))
                   (:memory (rail--digits (getf meter :memory-used)))
                   (:vram (rail--digits (getf meter :vram-used)))
                   (:frame nil)
                   (:battery nil))))
    (list shown counting (if hot 1 0) label
          (if (>= shown 100) "100" (format nil "~D%" shown))
          (or detail ""))))

(defun rail-sprite--clamp (seam side)
  "The clamps' three heights down the panel and the side they bolt to."
  (let ((h (getf seam :height)))
    (list (rail--side-sign side) 56 (floor h 2) (- h 56))))

(defun rail-sprite--label (state)
  "The voice block's heading: the turn's clock while bolo has it, MIC when the
tower is listening for one."
  (if (cassette--bolo-turn-p (getf state :bolo-state))
      (cassette--bolo-clock (and (realp (getf state :bolo-since))
                                 (- (cassette--bolo-now)
                                    (getf state :bolo-since))))
      "MIC"))

(defun rail-sprite--date ()
  (let ((parts (rail-sprite--split (string-upcase (or (clock-text (getf +cassette+ :date)) "")))))
    (list (or (first parts) "") (or (second parts) "") (or (third parts) ""))))

(defun rail-sprite--clock ()
  (let ((parts (rail-sprite--split (or (clock-text (getf +cassette+ :time)) ""))))
    (list (or (first parts) "") (or (second parts) ""))))

(defun rail-sprite--panel-data (state snapshot context seam side switch)
  "Every number sprite.glsl reads for the panel, in the order it reads them."
  (let* ((now (getf context :now))
         (epoch (getf context :epoch))
         (levels (getf context :levels))
         (voicing (getf context :voicing))
         (fade (getf context :fade))
         (p +rail-sprite--panel+)
         (sections (rail-sprite--sections state snapshot seam))
         (pips (max 1 (round (/ (getf (second sections) :height) (getf p :pitch)))))
         (amp (if voicing (rail-sprite--amp state now) 0d0))
         (level-a (if (and voicing levels) (* amp (first levels)) 0d0))
         (level-b (if (and voicing levels)
                      (* amp (nth (min (getf p :echo) (1- (length levels))) levels))
                      0d0))
         (peak-a (if voicing (rail-sprite--peak levels amp pips 0 (getf p :hold)) 0))
         (peak-b (if voicing (rail-sprite--peak levels amp pips (getf p :echo)
                                               (getf p :hold))
                           0))
         (modules (rail-sprite--gauges state snapshot))
         (gauges (loop for module in modules
                       collect (rail-sprite--gauge state snapshot module)))
         (label (rail-sprite--label state))
         (date (rail-sprite--date))
         (clock (rail-sprite--clock))
         (clamp (rail-sprite--clamp seam side)))
    (append
     (list 0 +rail-sprite--grid+ (min 12 (length sections)) pips (getf p :tower) (getf p :pitch)
           (getf p :pip) (getf p :edge) (getf p :bar)
           (if (and voicing (realp (getf state :bolo-since)))
               (- (getf state :bolo-since) epoch) -1d9)
           (if (realp fade) (- fade epoch) -1d9)
           (if (and voicing (cassette--bolo-turn-p (getf state :bolo-state))) 1 0)
           (coerce (getf +rail--voice+ :rise) 'double-float)
           (coerce (getf +rail--voice+ :settle) 'double-float)
           (coerce level-a 'double-float) (coerce level-b 'double-float)
           peak-a peak-b
           (if switch (- (getf switch :at) epoch) -1d9))
     clamp
     (list (length label) (if (eq *rail--mode* :light) 1 0)
           (if (getf context :tray) (/ (getf context :tray) 1d0) 0))
     (rail-sprite--pack label)
     (append (rail-sprite--pack (first date)) (rail-sprite--pack (second date))
             (rail-sprite--pack (third date)))
     (append (rail-sprite--pack (first clock)) (rail-sprite--pack (second clock)))
     (loop for i from 0 below 6
           for gauge = (nth i gauges)
           append (if gauge
                      (append (list (first gauge) (second gauge) (third gauge))
                              (rail-sprite--pack (fourth gauge))
                              (rail-sprite--pack (fifth gauge))
                              (rail-sprite--pack (sixth gauge)))
                      (append (list 0 0 0) (rail-sprite--pack "") (rail-sprite--pack "")
                              (rail-sprite--pack ""))))
     (loop for i from 0 below 12
           for section = (nth i sections)
           append (if section
                      (list (getf section :top) (getf section :height)
                            (getf section :kind) (getf section :index))
                      (list 0 0 -1 0)))
     (append (rail-sprite--rgb :ol) (rail-sprite--rgb :body) (rail-sprite--rgb :hi)
             (rail-sprite--rgb :lo) (rail-sprite--rgb :idle) (rail-sprite--rgb :acc)
             (rail-sprite--rgb :white) (rail-sprite--rgb :rail) (rail-sprite--rgb :ink)
             (rail-sprite--rgb :dim) (rail-sprite--rgb :pip) (rail-sprite--rgb :red)
             (rail-sprite--rgb :gfill))
     (rail-sprite--pack (if (and (rail--media-played snapshot)
                                 (equal (first (rail--media-played snapshot)) "Playing"))
                           ">" "||"))
     (rail-sprite--pack "NET")
     (rail-sprite--pack (if (getf (service-state snapshot :network) :connected) "ON" "OFF")))))

(defun rail-sprite--frame-data (context seam output side)
  "Every number sprite.glsl reads for the frames, in the order it reads them."
  (let* ((switch (getf context :switch))
         (epoch (getf context :epoch))
         (now (getf context :now))
         (windows (getf context :windows))
         (old (getf context :old))
         (key (getf context :key))
         (box (getf context :old-box))
         (levels (getf context :levels))
         (voicing (getf context :voicing))
         (state (getf context :state))
         (amp (if voicing (rail-sprite--amp state now) 0d0))
         (level (if (and voicing levels) (* amp (first levels)) 0d0)))
    (append
     (list 1 (rail--design +rail-sprite--grid+) (rail--design (getf +rail-sprite--cast+ :band))
           (rail--design (getf +rail-sprite--cast+ :arm))
           (rail--design (getf +rail-sprite--cast+ :notch))
           (rail--design (getf +rail-sprite--cast+ :spark))
           (- (rail--edge seam) (getf output :x))
           (getf +layout+ :seam)
           (rail--side-sign side)
           (if switch (rail--side-sign (getf switch :from)) 0)
           (if switch (- (getf switch :at) epoch) -1d9)
           (if (or (null switch) (getf context :cut)) -1d9 0)
           (or (and key (position (getf key :id) windows)) -1)
           (or (and old (position old windows)) -1)
           (coerce (getf +rail--tide+ :settle) 'double-float)
           (if box (getf box :x) 0) (if box (getf box :y) 0)
           (if box (+ (getf box :x) (getf box :width)) 0)
           (if box (+ (getf box :y) (getf box :height)) 0)
           (if (and voicing (realp (getf state :bolo-since)))
               (- (getf state :bolo-since) epoch) -1d9)
           (if (realp (getf context :fade)) (- (getf context :fade) epoch) -1d9)
           (if (and voicing (cassette--bolo-turn-p (getf state :bolo-state))) 1 0)
           (coerce (getf +rail--voice+ :rise) 'double-float)
           (coerce (getf +rail--voice+ :settle) 'double-float)
           (coerce level 'double-float))
     (list (coerce (getf +rail-sprite--switch+ :fps) 'double-float)
           (first (getf +rail-sprite--switch+ :ease))
           (second (getf +rail-sprite--switch+ :ease))
           (third (getf +rail-sprite--switch+ :ease))
           (fourth (getf +rail-sprite--switch+ :ease))
           (rail--design (getf +rail-sprite--switch+ :spark))
           (rail--design (getf +rail-sprite--switch+ :burst))
           (rail--design (getf +rail-sprite--switch+ :arm))
           (rail--design (getf +rail-sprite--switch+ :pull))
           (rail--design (getf +rail-sprite--switch+ :land))
           (if (eq *rail--mode* :light) 1 0))
     (append (rail-sprite--rgb :ol) (rail-sprite--rgb :hi) (rail-sprite--rgb :lo)
             (rail-sprite--rgb :body) (rail-sprite--rgb :idle)
             (rail-sprite--rgb :acc) (rail-sprite--rgb :white)))))

(defun rail-sprite--remember (state key)
  "Note where the focused card stood when a switch began, so a card that
travels -- a column swap -- leaves its brackets behind it."
  (let ((switch (getf state :rail-switch)))
    (unless (eql (and switch (getf switch :at)) (getf state :rail-sprite-switch))
      (setf (getf state :rail-sprite-switch) (and switch (getf switch :at))
            (getf state :rail-sprite-box) (and key (getf key :box))))
    (getf state :rail-sprite-box)))

(defun rail-sprite--counts (state)
  (loop for module in '(:cpu :memory :gpu :vram)
        for shown = (getf (getf state :rail-meter) module)
        for target = (case module
                       (:cpu (getf (getf state :cpu) :percent))
                       (:memory (getf (getf state :memory) :percent))
                       (:gpu (getf (getf state :gpu) :percent))
                       (t 0))
        thereis (and (realp shown) (realp target) (> (abs (- target shown)) 0.6))))

(defun rail-sprite--draw (look context)
  "sprite: the panel down the seam and the frames round the carried cards."
  (declare (ignore look))
  (destructuring-bind (&key state snapshot epoch seam output carried key side switch
                         cut old windows voicing fade layer tray now &allow-other-keys)
      context
    (let* ((switching (and switch (< (- now (getf switch :at))
                                     (getf +rail--tide+ :settle))))
           (box (rail-sprite--remember state key))
           (voice-until (if voicing
                            (+ (- now epoch)
                               (if (and (realp fade) (> now fade))
                                   (max 0d0 (- (+ fade (getf +rail--voice+ :settle)) now))
                                   0.12d0))
                            0d0))
           (switch-until (if switch
                            (max 0d0
                                 (+ (- (getf switch :at) epoch)
                                    (/ (getf +rail-sprite--switch+ :frames)
                                       (getf +rail-sprite--switch+ :fps))
                                    0.1d0))
                            0d0))
           (panel-until (max voice-until switch-until
                             (if (rail-sprite--counts state) 0.12d0 0d0)))
           (shader (getf look :shader))
           (edge (rail--edge seam))
           (seam-width (getf +layout+ :seam))
           (top (getf seam :y))
           (panel (rail-sprite--panel-data
                   state snapshot
                   (list :now now :epoch epoch :levels (getf context :levels)
                         :voicing voicing :fade fade :tray tray)
                   seam side switch))
           (frames (rail-sprite--frame-data
                    (list :switch switch :epoch epoch :now now :windows windows :old old
                          :key key :old-box box :levels (getf context :levels)
                          :voicing voicing :state state :fade fade :cut cut)
                    seam output side)))
      (append
       (list (shell-surface
              :rail-slab (ui :stack)
              :output (getf output :name) :anchors '(:top :left)
              :width (rail--design seam-width)
              :height (rail--design (getf seam :height))
              :margin (rail--surface-margin output edge top)
              :layer layer :click-through t
              :background (list :shader shader :data panel :clock epoch :until panel-until))
             (shell-surface
              :rail-frames (ui :stack)
              :output (getf output :name) :anchors '(:top :left)
              :width (rail--design (getf output :width))
              :height (rail--design (getf output :height))
              :layer layer :click-through t
              :background (list :shader shader :data frames :windows windows :clock epoch
                                :until switch-until
                                :reach (rail--design (if switching 520 48)))))
       (unless (getf +rail+ :focus-border)
         (loop for entry in carried
               collect (window-properties
                        (getf entry :id)
                        :radius 0
                        :border (list :focused "#00000000" :unfocused "#00000000"))))))))

(defparameter +rail-sprite+
  (list :draw #'rail-sprite--draw
        :cast +rail-sprite--cast+
        :frame (list :edge 16 :title 0)))
