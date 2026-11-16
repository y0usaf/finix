(in-package #:tomoe-user)

;;; The rail
;;;
;;; The seam between the deck's two columns is the rail: the readings, the clock
;;; and bolo's voice, drawn with the frames round the cards it carries in one of
;;; its themes. A theme is the whole look -- the rail, the window frames and
;;; titles, how focus moves between them, the gauges and the voice -- and is one
;;; plist, +RAIL-<NAME>+, whose :DRAW turns the rail's context into the surfaces
;;; and window properties that draw it; default.nix gathers the themes
;;; bar.rail.themes names into +RAIL-THEMES+ with each one's shader. A theme
;;; whose frames need more room than a window gap names it as :FRAME -- :EDGE
;;; pixels between the columns and the screen's edges, :TITLE pixels of title row
;;; above each card -- and the deck lays the columns out by it; the bar publishes
;;; that with the seam's width as :RAIL-FRAME. On a narrow output, the headset's,
;;; the deck has no seam: the rail stands beside the card in the focal frame the
;;; headset's layout publishes, as the seam stands beside the deck's right column,
;;; and carries every card shown there, so the same theme draws it. The theme is
;;; the bar's own state, the first one until Alt+Shift+T steps to the next, so a
;;; config reload keeps it. The rest of this file is what every theme shares --
;;; the readings, the switch and the voice -- and the first theme, morph.
;;;
;;; morph
;;;
;;; The seam between the deck's two columns holds one slab, as tall as the
;;; readings it carries, and the focused card's frame is the same material: one
;;; colour, one thickness, the two welded where they meet by the smooth minimum
;;; of their fields. Each gauge swells the slab's free edge by its load and its
;;; numbers are set into the slab in ink, so slab, frame and readings read as one
;;; cast piece. Every
;;; other card the rail carries keeps a thin, darker line, and the slab stands off
;;; it with the wallpaper visible in between. The cards' corners are rounded to
;;; the frame's radius.
;;;
;;; When focus crosses the rail the slab hops: its leading edge leaps to the new
;;; card on a stiff spring and its trailing edge lets go on a looser one, so the
;;; slab stretches across the seam and snaps back to width; when focus moves to
;;; another card in the same column the slab stays on its side. Either way the
;;; frame moves with the pace of the work (TIDE): a switch after a pause siphons
;;; -- the old frame drains back into the slab, the slab gulps, and the new frame
;;; fills out of it round the card -- while a switch hard on the heels of another
;;; only pours, the old frame thinning away as the new one swells in, so fast
;;; work stays calm. While bolo has the turn the slab is the voice: its free edge is a
;;; level history, a wave whose reach at each row is the level the voice had when
;;; it passed, newest at the top, with a belly that leans out with the level being
;;; spoken and a heave of the whole slab. The focused frame -- the card being
;;; spoken into -- comes alive with it: a ripple runs out of the weld both ways
;;; round its whole perimeter, the level history laid along it newest at the
;;; slab, each crest swelling the frame out, lapping a little over the card and
;;; catching the light, each trough thinning it. Every other card's line stays
;;; still, and with no card in focus the slab alone speaks. When the turn closes
;;; it calms.
;;;
;;; All of that is one shader (shaders/morph.glsl) drawn on the GPU over two
;;; surfaces: a band down the seam and the frames over the rest of the output. The
;;; rail hands it the numbers below, the carried cards (whose drawn boxes the
;;; compositor fills in every frame, so a frame rides a card that is still sliding)
;;; and the times of the last switch and of bolo's turn; the shader animates from
;;; those on its own. Each surface draws every refresh only until its last motion
;;; has settled and then holds that picture, so a still rail costs nothing, and
;;; while bolo has the turn the slab and the focused frame's ring repaint with it.
;;;
;;; The readings are sampled, not streamed: a CPU percentage is two reads of
;;; /proc/stat and a GPU is a polled counter, so a number only ever changes when
;;; it is read. The compositor reads the counters once a second; the rail
;;; samples them four times a second, so a sample lands within a quarter of a
;;; second of the read, and between samples each gauge eases toward the last one
;;; on an exponential approach, sweeping through the values in between instead
;;; of jumping a whole second's load at once. A step is taken only when a drawn
;;; number would change -- every number on the way is drawn, and no update is
;;; spent redrawing the same one -- and a gauge that draws its sample stops.

(defvar *rail--palette* nil)
(defvar *rail--look* nil)
(defvar *rail--mode* :dark)
(defvar *rail--scale* 1)

(defparameter +rail--clock-inset+ 27)
(defparameter +rail--clock-height+ 62)
(defparameter +rail--air+ 32)

;; The voice: the slab is the meter, so what bolo says is drawn by the slab's own
;; shape. While the turn is open the free edge is a wave over its whole height,
;; its reach at each row the level the voice had when it passed (newest at the
;; top), plus a belly that leans out with the level being spoken; the whole slab
;; heaves with it, and a ripple runs out of the weld round the focused frame,
;; the same history laid along its perimeter. Every number the shape follows is
;; here.
(defparameter +rail--voice+
  (list :rest 1d0        ; the free edge's wave in the quiet of a turn
        :level 12d0      ; and how much more the voice adds to it
        :swell 4.5d0     ; how far the belly leans toward the far card at full voice
        :wave 0.022d0    ; radians per pixel down the slab
        :hz 15d0         ; radians per second the wave travels
        :bob 2.5d0       ; how far the whole slab heaves at full voice
        :bob-hz 9d0      ; radians per second it heaves
        :rise 0.25d0     ; seconds the shape takes to come up as a turn opens
        :settle 0.8d0    ; seconds it takes to calm once the turn has closed
        :fade 48         ; pixels the wave takes to reach full strength at each end
        :frame 3d0       ; pixels a crest swells the focused frame out at full voice
        :ebb 3d0         ; and a trough thins it
        :lap 5d0         ; pixels a crest laps in over the card
        :glow 0.8d0      ; how much of the highlight a crest catches
        :ripple 0.016d0  ; radians per pixel round the frame, with a chop at 2.3 times it
        :ripple-hz 16d0)) ; radians per second the ripple runs out of the weld

;; CAST: the material and its geometry, in physical pixels. The slab fills
;; :SLAB of the seam and reaches :INSET past the rail's first and last blocks, so
;; it is as tall as what it holds, rounding its ends by :END; each gauge swells
;; the slab's free edge over its own rows by up to :SWELL at a full reading. The
;; focused frame is :FRAME thick round corners of :RADIUS, welded to the slab
;; over :WELD; every other card has a :LINE-wide line. A stretched slab gives
;; back :SQUASH of its stretch at its ends. Each mode has its :MATERIAL, the
;; :LINE colour, the :SHADOW the material casts at :SHADE strength, and the
;; :SHINE its highlight takes at :GLOSS.
(defparameter +rail--cast+
  (list :frame 5 :line-width 1.5 :radius 14 :slab 50 :inset 22 :end 22 :weld 28 :squash 0.7
        :swell 11
        :dark (list :material "#3A3E58" :line "#26283C" :shadow "#020208" :shade 0.55
                    :shine "#ECE7DC" :gloss 0.34)
        :light (list :material "#B2ACA2" :line "#D6D2CA" :shadow "#342E28" :shade 0.24
                     :shine "#FFFFFF" :gloss 0.55)))

;; TIDE: how a focus switch moves, in seconds unless marked. A switch that comes
;; :GAP or more after the previous one siphons, a quicker one pours; either draws
;; for :SETTLE. Across the seam the slab's leading edge rides a spring of :OMEGA
;; radians per second at :DAMPING with a :LAUNCH, its ends :LAG behind its middle;
;; the trailing edge lets go :DELAY plus the flow's :HOLD later on its own
;; spring. Once free the slab rings by :REACH pixels, dying over :DECAY at :RATE
;; radians per second. POUR swells the new frame in over :GROW with an :IMPACT
;; overshoot in pixels peaking at :IMPACT-AT and dying over :IMPACT-DECAY, and
;; thins the old one away between :LET-GO and :GONE. SIPHON drains the old frame
;; into the slab over :DRAIN (eased by the power :DRAIN-EASE, with a :BULGE in
;; pixels riding the drain), swells the slab by :GULP pixels as it arrives, and
;; fills the new frame from :FILL-AT over :FILL with a :HEAD of material at its
;; front, a :RIPPLE behind it and a :MEET pulse where the two fronts join.
(defparameter +rail--tide+
  (list :gap 0.6 :settle 0.7
        :lead (list :omega 78 :damping 0.72 :launch 60 :lag 0.03)
        :trail (list :omega 66 :damping 0.42 :delay 0.018)
        :ring (list :reach 2.6 :decay 0.09 :rate 70)
        :pour (list :hold 0.085 :grow 0.06 :impact 2.2 :impact-at 0.045 :impact-decay 0.07
                    :let-go 0.015 :gone 0.11)
        :siphon (list :hold 0.16 :gulp 6 :drain 0.16 :drain-ease 1.7 :bulge 6.5
                      :fill-at 0.025 :fill 0.27 :head 5.5 :ripple 1.4 :meet 4)))

;; The gauges: a reading is read once a second, so the number drawn between
;; reads glides toward it -- an exponential approach whose next step is taken
;; exactly when the number it draws would next change, never sooner than the
;; display's own beat, and nothing at all once it draws the sample. Every number
;; the glide follows is here.
(defparameter +rail--glide+
  (list :tick 16                        ; milliseconds a step waits at the least
        :tau 0.18d0))                   ; seconds a reading takes to cover a change

(defun rail--design (px)
  "PX of the design, in this output's logical units."
  (/ px *rail--scale*))

(defun rail--c (role)
  "The colour ROLE draws with: the cassette's own ink, dim, rim, led-off, face
or counter when it has one, and the theme's published palette key otherwise."
  (let ((source (getf (getf +rail+ :colors) role)))
    (or (getf (getf (getf +cassette+ :colors) *rail--mode*) source)
        (getf *rail--palette* source)
        "#00000000")))

(defun rail--cast (key)
  "KEY of the theme's cast: its geometry, or with a mode its colours."
  (getf (getf *rail--look* :cast) key))

(defun rail--material (key)
  "KEY of the theme's cast in the current mode."
  (getf (rail--cast *rail--mode*) key))

(defun rail--ink ()
  "The readings' ink: the theme's own when its cast names one, the palette's
otherwise."
  (or (rail--material :ink) (rail--c :ink)))

(defun rail--value () (rail--ink))

(defun rail--detail ()
  (hud--fade (rail--ink) (if (eq *rail--mode* :dark) 0.62 0.66)))

(defun rail--label ()
  (hud--fade (rail--ink) (if (eq *rail--mode* :dark) 0.40 0.46)))

(defun rail--parts (text)
  (let ((parts nil) (start 0))
    (dotimes (i (1+ (length text)) (nreverse parts))
      (when (or (= i (length text)) (member (char text i) '(#\: #\Space)))
        (when (> i start) (push (subseq text start i) parts))
        (setf start (1+ i))))))

(defun rail--text (text color size &optional (height size))
  (ui :text :text text :size (rail--design size) :line-height (rail--design height)
      :height (rail--design height) :color color :font (or (getf *rail--look* :font) (getf +cassette+ :font))))

(defun rail--split-unit (text)
  "TEXT as its number and its trailing percent sign, the sign drawn one tier
below the number it belongs to."
  (if (and (plusp (length text)) (char= (char text (1- (length text))) #\%))
      (list (subseq text 0 (1- (length text))) "%")
      (list text nil)))

(defun rail--number (text &optional (ink (rail--value)) (unit-ink (rail--label)))
  (destructuring-bind (number unit) (rail--split-unit text)
    (ui :row :align :center
        :children (append (list (rail--text number ink 21 22))
                          (when unit (list (rail--text unit unit-ink 14 22)))))))

(defun rail--drop (text ground)
  "TEXT cast in the slab's material inside a bead of ink: a warning without a hue."
  (destructuring-bind (number unit) (rail--split-unit text)
    (ui :row :align :center :padding (list 0 (rail--design 5) 0 (rail--design 5))
        :radius (rail--design 10) :height (rail--design 20) :background (rail--value)
        :children (append (list (rail--text number ground 15 20))
                          (when unit (list (rail--text unit ground 11 20)))))))

(defun rail--meter (percent)
  "A 36 wide, four tall rounded pill: the played fraction of the media, the
one reading a percentage cannot carry."
  (ui :progress :width (rail--design 36) :height (rail--design 4)
      :radius (rail--design 2) :value (/ (max 0 (min 100 (round (or percent 0)))) 100)
      :track (hud--fade (rail--ink) 0.12) :color (rail--value)))

(defun rail--digits (mib)
  "Whole GiB from ten up, one decimal below, so a memory detail is four cells."
  (if (realp mib)
      (let ((gib (/ mib 1024d0)))
        (if (>= gib 10) (format nil "~DG" (round gib)) (format nil "~,1FG" gib)))
      "--G"))

(defun rail--meter-targets (state)
  "The numbers the gauges draw, as the last sample read them: a percentage for
each, and the memory and the video memory in MiB."
  (let ((memory (getf state :memory)) (gpu (getf state :gpu)))
    (list :cpu (or (getf (getf state :cpu) :percent) 0)
          :memory (or (getf memory :percent) 0)
          :memory-used (or (getf memory :used) 0)
          :gpu (or (getf gpu :percent) 0)
          :vram (if (plusp (or (getf gpu :total) 0))
                    (/ (* 100d0 (or (getf gpu :used) 0)) (getf gpu :total))
                    0d0)
          :vram-used (or (getf gpu :used) 0))))

(defun rail--glide-unit (key value)
  "The step at which KEY's gauge draws VALUE differently: a whole percent, or for
memory the whole GiB from ten up and a tenth below, as RAIL--DIGITS writes it."
  (if (member key '(:memory-used :vram-used))
      (if (>= (abs value) 10240) 1024d0 102.4d0)
      1d0))

(defun rail--ln (x)
  "The natural logarithm of X > 0, which the policy language does not carry:
square roots bring X near one, where the series for 2 atanh((X-1)/(X+1)) is
already exact to a millionth in three terms."
  (let ((halvings 0))
    (loop while (or (> x 1.25d0) (< x 0.8d0))
          do (setf x (sqrt x) halvings (1+ halvings)))
    (let* ((y (/ (- x 1d0) (+ x 1d0))) (y2 (* y y)))
      (* (expt 2 (1+ halvings)) y (+ 1d0 (/ y2 3d0) (/ (* y2 y2) 5d0) (/ (* y2 y2 y2) 7d0))))))

(defun rail--glide-due (key here to)
  "Seconds until the approach from HERE to TO next changes what KEY's gauge
draws, or NIL when it already draws what TO does."
  (let* ((unit (rail--glide-unit key here))
         (drawn (round (/ here unit)))
         (edge (* unit (if (> to here) (+ drawn 0.5d0) (- drawn 0.5d0)))))
    (when (if (> to here) (< edge to) (> edge to))
      (* (getf +rail--glide+ :tau) (rail--ln (/ (- here to) (- edge to)))))))

(defun rail--glide (state now)
  "Step every gauge toward its last sample: an exponential approach over the time
since the last step, landing on the sample once it draws the same. Leaves how
long until a drawn number next changes in the state's :RAIL-GLIDE, NIL once none
will, so the rail ticks only when there is a different number to draw."
  (let* ((targets (rail--meter-targets state))
         (shown (getf state :rail-meter))
         (last (getf state :rail-step))
         ;; a glide that had stopped starts from where it stood, not from when
         ;; the rail last happened to look
         (elapsed (if (and last (getf state :rail-glide))
                      (max 0d0 (min 1d0 (- now last)))
                      0d0))
         (grip (- 1d0 (expt 2.718281828459045 (- (/ elapsed (getf +rail--glide+ :tau))))))
         (due nil))
    (setf (getf state :rail-step) now)
    (if (null shown)
        ;; The first sample is drawn as it is: a gauge counts up to nothing.
        (setf shown targets)
        (dolist (key '(:cpu :memory :memory-used :gpu :vram :vram-used))
          (let* ((to (coerce (getf targets key) 'double-float))
                 (here (coerce (getf shown key to) 'double-float))
                 (eased (+ here (* grip (- to here))))
                 (next (rail--glide-due key eased to)))
            (if next
                (setf (getf shown key) eased
                      due (if due (min due next) next))
                (setf (getf shown key) to)))))
    (setf (getf state :rail-meter) shown
          (getf state :rail-glide) due)))

(defun rail--gauge (label percent detail hot ground)
  (let* ((percent (max 0 (min 100 (round (or percent 0)))))
         (value (format nil "~D%" percent)))
    (ui :column :align :center
        :children
        (append (list (rail--text label (rail--label) 13 22)
                      (if (> percent 84) (rail--drop value ground) (rail--number value)))
                (when detail
                  (list (if hot
                            (rail--drop detail ground)
                            (rail--text detail (rail--detail) 15 22))))))))

(defun rail--date ()
  (destructuring-bind (&optional day date month &rest rest)
      (rail--parts (string-upcase (clock-text (getf +cassette+ :date))))
    (declare (ignore rest))
    (ui :column :align :center
        :children (remove nil
                          (list (when day (rail--text day (rail--label) 13 22))
                                (when date (rail--text date (rail--value) 21 22))
                                (when month (rail--text month (rail--label) 13 22)))))))

(defun rail--clock ()
  (destructuring-bind (&optional hours minutes)
      (rail--parts (clock-text (getf +cassette+ :time)))
    (ui :column :align :center
        :children (list (rail--text (or hours "--") (rail--value) 30 33)
                        (rail--text (or minutes "--") (rail--value) 30 29)))))

(defun rail--media-played (snapshot)
  (let* ((service (service-state snapshot :mpris))
         (status (getf service :status))
         (length (getf service :length))
         (position (getf service :position)))
    (when (and (getf service :title) (member status '("Playing" "Paused") :test #'equal))
      (list status (if (and (realp length) (plusp length) (realp position))
                       (max 0 (min 1 (/ position length)))
                       0)))))

(defun rail--media (snapshot)
  (destructuring-bind (status played) (rail--media-played snapshot)
    (ui :column :align :center
        :children (list (rail--text (if (equal status "Playing") ">" "||") (rail--value) 21 22)
                        (rail--meter (round (* 100 played)))
                        (ui :rect :height (rail--design 8))))))

(defun rail--network (snapshot)
  (let ((online (getf (service-state snapshot :network) :connected)))
    (ui :column :align :center
        :children (list (rail--text "NET" (rail--label) 13 22)
                        (rail--text (if online "ON" "OFF") (rail--value) 15 22)))))

(defun rail--voice (state)
  "Bolo's turn at the top of the stack: the elapsed time. The level itself is the
slab's shape, not a reading."
  (let ((since (getf state :bolo-since)))
    (ui :column :align :center
        :children (list (rail--text (cassette--bolo-clock
                                     (and (realp since) (- (cassette--bolo-now) since)))
                                    (rail--value) 15 22)))))

(defun rail--height (module state snapshot)
  "The design height of MODULE's block, or NIL when it has nothing to show."
  (ecase module
    (:time +rail--clock-height+)
    (:date 66)
    (:media (when (rail--media-played snapshot) 34))
    (:cpu 66)
    (:memory 66)
    (:gpu (when (probe--gpu-p (getf state :gpu)) 66))
    (:vram (when (probe--gpu-p (getf state :gpu)) 66))
    (:battery (when (getf (service-state snapshot :battery) :percent) 44))
    (:network 44)
    (:frame (when (getf (state-value snapshot :frame-battery) :percent) 44))))

(defun rail--block (module state snapshot ground)
  (let ((cpu (getf state :cpu)) (gpu (getf state :gpu))
        (meter (getf state :rail-meter)))
    (ecase module
      (:time (rail--clock))
      (:date (rail--date))
      (:media (rail--media snapshot))
      (:cpu (rail--gauge "CPU" (getf meter :cpu) (cassette--degrees (getf cpu :temp))
                         (cassette--hot-p (getf cpu :temp)) ground))
      (:memory (rail--gauge "MEM" (getf meter :memory)
                            (rail--digits (getf meter :memory-used)) nil ground))
      (:gpu (rail--gauge "GPU" (getf meter :gpu) (cassette--degrees (getf gpu :temp))
                         (cassette--hot-p (getf gpu :temp)) ground))
      (:vram (rail--gauge "VRAM" (getf meter :vram)
                          (rail--digits (getf meter :vram-used)) nil ground))
      (:battery (let ((battery (service-state snapshot :battery)))
                  (rail--gauge (if (getf battery :charging) "CHG" "BAT")
                               (getf battery :percent) nil nil ground)))
      (:network (rail--network snapshot))
      (:frame (let ((battery (state-value snapshot :frame-battery)))
                (rail--gauge (if (equal (getf battery :status) "Discharging") "VR" "VR+")
                             (getf battery :percent) nil nil ground))))))

(defun rail--places (state snapshot middle)
  "Where each block's top is in the web: the clock is pinned to MIDDLE and the
other blocks stack away from it, or the whole stack is centred on MIDDLE when
the module list has no clock."
  (let* ((entries (loop for module in (getf +rail+ :modules)
                        for height = (rail--height module state snapshot)
                        when height collect (cons module height)))
         (pin (position :time entries :key #'car)))
    (if (null pin)
        (let* ((total (+ (loop for entry in entries sum (cdr entry))
                         (* +rail--air+ (max 0 (1- (length entries))))))
               (top (- middle (floor total 2))))
          (loop for (module . height) in entries
                for y = top then (+ y height +rail--air+)
                collect (cons module y)))
        (let* ((clock (- middle +rail--clock-inset+))
               (y clock)
               (above (loop for (module . height) in (reverse (subseq entries 0 pin))
                            do (decf y (+ +rail--air+ height))
                            collect (cons module y)))
               (below (let ((start (+ clock +rail--clock-height+ +rail--air+)))
                        (loop for (module . height) in (subseq entries (1+ pin))
                              collect (prog1 (cons module start)
                                       (incf start (+ height +rail--air+)))))))
          (append (reverse above) (list (cons :time clock)) below)))))

(defun rail--tray (snapshot)
  "The height of the slot the shelf asked for at the top of the stack, or NIL."
  (let ((tray (state-value snapshot :shelf-tray)))
    (when (and tray (plusp (getf tray :count 0)) (plusp (getf tray :size 0)))
      (* (getf tray :count) (getf tray :size)))))

(defun rail--blocks (state snapshot seam)
  "Every block the rail stacks, as (MODULE TOP HEIGHT) in logical pixels down the
output: the readings round the clock, and above them bolo's turn and the shelf's
tray when they are there."
  (let* ((base (/ (getf seam :y) *rail--scale*))
         (height (/ (getf seam :height) *rail--scale*))
         (placed (loop for (module . top) in (rail--places state snapshot (+ base (floor height 2)))
                       collect (list module top (rail--height module state snapshot))))
         (top (if placed (second (first placed)) (+ base (floor height 2))))
         (tray (rail--tray snapshot))
         (above (append (when tray (list (list :tray (/ tray *rail--scale*))))
                        (when (cassette--bolo-turn-p (getf state :bolo-state))
                          (list (list :voice 22))))))
    (append (loop for (module tall) in (reverse above)
                  do (decf top (+ tall +rail--air+))
                  collect (list module top tall) into stacked
                  finally (return (reverse stacked)))
            placed)))

(defun rail--extent (blocks)
  "The first block's top and the last block's bottom, in output pixels."
  (when blocks
    (let ((last (car (last blocks))))
      (list (* *rail--scale* (second (first blocks)))
            (* *rail--scale* (+ (second last) (third last)))))))

(defun rail--web (state snapshot seam blocks ground)
  "The readings, the voice block and the tray, in type over the track."
  (let* ((base (/ (getf seam :y) *rail--scale*))
         (height (/ (getf seam :height) *rail--scale*))
         (width (rail--seam-width))
         (cursor 0)
         (parts nil))
    (loop for (module top tall) in blocks
          for y = (- top base)
          do (when (> y cursor) (push (cons (- y cursor) nil) parts))
             (push (cons tall
                         (case module
                           (:tray (ui :rect :height (rail--design (* tall *rail--scale*))
                                      :width (rail--design 52) :background (rail--c :tray)))
                           (:voice (rail--voice state))
                           (t (rail--block module state snapshot ground))))
                   parts)
             (setf cursor (+ y tall)))
    (ui :column :align :center :width (rail--design width) :height (rail--design height)
        :children (loop for (tall . node) in (nreverse parts)
                        collect (or node (ui :rect :height (rail--design tall)))))))

(defun rail--gauges (state blocks)
  "The readings the slab swells with, as the shader reads them: for each gauge
its middle and half its reach in output pixels and its fraction, up to five."
  (let ((meter (getf state :rail-meter)))
    (loop for (module top tall) in blocks
          for value = (case module
                        (:cpu (getf meter :cpu)) (:memory (getf meter :memory))
                        (:gpu (getf meter :gpu)) (:vram (getf meter :vram)))
          when value
            collect (list (* *rail--scale* (+ top (/ tall 2)))
                          (* *rail--scale* (/ (+ tall +rail--air+) 2))
                          (/ (max 0 (min 100 value)) 100d0))
              into gauges
          finally (return (subseq gauges 0 (min 5 (length gauges)))))))


;;; The slab and the frames

(defun rail--seam-width ()
  "The open seam between the two cards' borders: both channels and the rail."
  (+ (* 2 (getf +rail+ :channel)) (getf +rail+ :width)))

(defun rail--shift (side)
  "How far the readings move off the seam's centre to ride the slab on SIDE."
  (let ((off (- (+ (rail--cast :frame) (/ (rail--cast :slab) 2) -1)
                (/ (getf +layout+ :seam) 2))))
    (if (eq side :right) (- off) off)))

(defun rail--rgb (hex)
  "#RRGGBB as three reals from 0 to 1."
  (loop for i from 1 below 7 by 2
        collect (/ (+ (* 16 (digit-char-p (char hex i) 16)) (digit-char-p (char hex (1+ i)) 16))
                   255d0)))

(defun rail--epoch (now)
  "The second the shader's clock counts from: NOW rounded down to 256 seconds, so
its time stays small enough for a float to keep the motion smooth."
  (* 256 (floor now 256)))

(defun rail--side-sign (side) (case side (:left -1) (:right 1) (t 0)))

(defun rail--switch (state side id now)
  "Note a change of the focused card ID, on SIDE, in STATE: a switch across the
seam or along its column, or between a card and :FREE, the deck holding no
focus, siphoning after a pause and pouring on the heels of the last one, from
the card that held focus before. A cut throw notes none, so nothing animates or
redraws."
  (let ((was (getf state :rail-side))
        (old (getf state :rail-focus)))
    (when (and side was (not (and (eql side was) (eql id old)))
               (eq (getf +rail+ :throw) :slide))
      (let* ((last (getf state :rail-switched))
             (pour (and last (< (- now last) (getf +rail--tide+ :gap)))))
        (setf (getf state :rail-switch)
              (list :at now :from was :flow (if pour :pour :siphon) :old old)
              (getf state :rail-switched) now)))
    (setf (getf state :rail-side) side
          (getf state :rail-focus) id)))

(defun rail--motion (switch side epoch)
  "The switch as the shader reads it: side, previous side, start, flow, hold, gulp."
  (let* ((flow (and switch (getf switch :flow)))
         (tide (getf +rail--tide+ (or flow :pour))))
    (list (rail--side-sign side)
          (if flow (rail--side-sign (getf switch :from)) (rail--side-sign side))
          (if switch (- (getf switch :at) epoch) -1d6)
          (case flow (:pour 0) (:siphon 1) (t -1))
          (getf tide :hold)
          (if (eq flow :siphon) (getf tide :gulp) 0))))

(defun rail--voice-data (state voicing epoch)
  "The voice as the shader reads it: when the turn opened and closed, whether it
is open, the shape's numbers, and the level history, newest first."
  (let* ((levels (if voicing (subseq (getf state :bolo-history) 0
                                     (min 48 (length (getf state :bolo-history))))
                     nil))
         (since (and voicing (getf state :bolo-since)))
         (fade (and voicing (getf state :bolo-fade)))
         (v +rail--voice+))
    (append (list (if (realp since) (- since epoch) -1d9)
                  (if (realp fade) (- fade epoch) -1d9)
                  (if (and voicing (cassette--bolo-turn-p (getf state :bolo-state))) 1 0)
                  (getf v :rest) (getf v :level) (getf v :swell) (getf v :wave) (getf v :hz)
                  (getf v :bob) (getf v :bob-hz) (getf v :rise) (getf v :settle) (getf v :fade)
                  (length levels)
                  (getf v :frame) (getf v :ebb) (getf v :lap) (getf v :glow)
                  (getf v :ripple) (getf v :ripple-hz))
            levels
            (make-list (- 48 (length levels)) :initial-element 0))))

(defun rail--tide-data (origin skip seam extent output motion focus old voice gauges ghost)
  "Every number morph.glsl reads, in the order it reads them. ORIGIN is the
surface's corner and SKIP the span of x it leaves to the other surface, both in
output pixels, and EXTENT the top and bottom of the rail's stack the slab holds;
FOCUS and OLD index the surface's :WINDOWS; GAUGES are what RAIL--GAUGES makes
of the readings the slab swells with; GHOST is the box the old card last stood
in when it is no longer shown, for its frame to drain from."
  (let* ((cast (getf *rail--look* :cast))
         (tide +rail--tide+)
         (lead (getf tide :lead)) (trail (getf tide :trail)) (ring (getf tide :ring))
         (pour (getf tide :pour)) (siphon (getf tide :siphon)))
    (append origin skip
            (rail--rgb (rail--material :material)) (rail--rgb (rail--material :line))
            (rail--rgb (rail--material :shadow)) (rail--rgb (rail--material :shine))
            (list (rail--material :gloss) (rail--material :shade)
                  (getf cast :radius) (getf cast :frame) (getf cast :line-width)
                  (getf cast :slab) (getf cast :inset) (getf cast :end) (getf cast :weld)
                  (rail--edge seam) (getf +layout+ :seam))
            motion
            (list (or focus -1) (or old -1) (length gauges) (first extent) (second extent)
                  (getf tide :settle)
                  (getf lead :omega) (getf lead :damping) (getf lead :launch) (getf lead :lag)
                  (getf trail :omega) (getf trail :damping) (getf trail :delay)
                  (getf ring :reach) (getf ring :decay) (getf ring :rate)
                  (getf cast :squash)
                  (getf pour :grow) (getf pour :impact) (getf pour :impact-at)
                  (getf pour :impact-decay) (getf pour :let-go) (getf pour :gone)
                  (getf siphon :drain) (getf siphon :drain-ease) (getf siphon :bulge)
                  (getf siphon :fill-at) (getf siphon :fill) (getf siphon :head)
                  (getf siphon :ripple) (getf siphon :meet)
                  (getf output :height))
            voice
            (loop for gauge in gauges append gauge)
            (make-list (* 3 (- 5 (length gauges))) :initial-element 0)
            (list (getf cast :swell))
            (or ghost (list 0 0 0 0))
            (let ((glass (rail--material :glass)))
              (when glass
                (append (loop for key in '(:frost :lens :bevel :rim :haze :vibrance :contrast :edge)
                              collect (getf glass key))
                        (rail--rgb (rail--ink))))))))

(defun rail--shown (carried output)
  "The carried cards on OUTPUT's screen, nearest each column's front first."
  (let ((top (getf output :y)) (bottom (+ (getf output :y) (getf output :height))))
    (loop for entry in carried
          for box = (getf entry :box)
          when (and (< (getf box :y) bottom) (> (+ (getf box :y) (getf box :height)) top))
            collect (getf entry :id))))

(defun rail--edge (seam) (- (getf seam :x) (getf +layout+ :gaps)))

(defun rail--border ()
  "The theme's window border width, as the seam's own formula counts it."
  (max 0 (floor (- (getf +layout+ :seam)
                    (* 2 (getf +rail+ :channel))
                    (getf +rail+ :width))
                2)))

(defun rail--lane (seam side)
  (+ (rail--edge seam) (rail--border)
     (if (eq side :right) (+ (getf +rail+ :channel) (getf +rail+ :width)) 0)))

(defun rail--carried (columns layout)
  "Each carried window as (:ID :SIDE :BOX), nearest each column's front first;
a hidden window is carried by neither column until it is shown again."
  (loop for side in '(:left :right)
        for ids = (getf columns side)
        append (loop for id in (subseq ids 0 (min (length ids) (getf +rail+ :carry-max)))
                     for box = (find id layout :key (lambda (entry) (getf entry :id)))
                     when (and box (getf box :visible)) collect (list :id id :side side :box box))))

(defun rail--covered-p (snapshot box)
  "Whether a placed window overlaps BOX. Tiled windows never reach the seam, so
this is a float or a fullscreen window, which the rail then sits beneath."
  (and box
       (loop for entry in (context snapshot :layout)
             thereis (and (getf entry :visible)
                          (< (getf entry :x) (+ (getf box :x) (getf box :width)))
                          (< (getf box :x) (+ (getf entry :x) (getf entry :width)))
                          (< (getf entry :y) (+ (getf box :y) (getf box :height)))
                          (< (getf box :y) (+ (getf entry :y) (getf entry :height)))))))

(defun rail--surface-margin (output x y)
  (list (rail--design (- y (getf output :y))) 0 0 (rail--design (- x (getf output :x)))))

(defun rail--focal (snapshot)
  "On a narrow output, where the deck has no seam, the focal frame a headset
layout publishes, in output pixels, with its :OUTPUT; NIL when there is none."
  (let* ((frame (state-value snapshot :focal-frame))
         (output (and frame (find (getf frame :output) (context snapshot :outputs)
                                  :key (lambda (o) (getf o :name)) :test #'equal))))
    (when (and output (deck--narrow-p (list :output output)))
      (let ((scale (/ (getf output :scale-120 120) 120)))
        (flet ((px (key) (round (* scale (getf frame key)))))
          (list :output output :x (+ (getf output :x) (px :left)) :y (+ (getf output :y) (px :top))
                :width (px :width) :height (px :height)))))))

(defun rail--focal-cards (snapshot focal)
  "The seam a narrow output's rail stands in, beside the card in FOCAL as the
deck's seam stands beside its right column, and every card shown on that output
on the side of it its middle falls, the one in the frame first: (SEAM CARRIED)."
  (let* ((output (getf focal :output))
         (shown (loop for entry in (context snapshot :layout)
                      when (and (getf entry :visible) (not (getf entry :fullscreen))
                                (< (getf output :x) (+ (getf entry :x) (getf entry :width)))
                                (< (getf entry :x) (+ (getf output :x) (getf output :width)))
                                (< (getf output :y) (+ (getf entry :y) (getf entry :height)))
                                (< (getf entry :y) (+ (getf output :y) (getf output :height))))
                        collect entry))
         (inner (find-if (lambda (entry)
                           (let ((cx (+ (getf entry :x) (floor (getf entry :width) 2)))
                                 (cy (+ (getf entry :y) (floor (getf entry :height) 2))))
                             (and (<= (getf focal :x) cx (+ (getf focal :x) (getf focal :width)))
                                  (<= (getf focal :y) cy (+ (getf focal :y) (getf focal :height))))))
                         shown))
         (box (or inner focal))
         (gaps (getf +layout+ :gaps))
         (edge (getf box :x))
         (seam (list :output (getf output :name)
                     :x (+ (- edge (getf +layout+ :seam)) gaps) :y (getf box :y)
                     :width (- (getf +layout+ :seam) (* 2 gaps)) :height (getf box :height))))
    (list seam
          (loop for entry in (if inner (cons inner (remove inner shown)) shown)
                repeat (getf +rail+ :carry-max)
                collect (list :id (getf entry :id)
                              :side (if (< (+ (getf entry :x) (floor (getf entry :width) 2)) edge)
                                        :left :right)
                              :box entry)))))

;;; morph's surfaces

(defun rail--ghost (snapshot old)
  "The box, x0 y0 x1 y1 in output pixels, the card OLD was laid out in when it
is no longer shown -- hidden by a peek, say -- or NIL while it is shown."
  (let ((entry (and old (find old (context snapshot :layout) :key (lambda (e) (getf e :id))))))
    (when (and entry (not (getf entry :visible)) (plusp (getf entry :width 0)))
      (list (getf entry :x) (getf entry :y)
            (+ (getf entry :x) (getf entry :width)) (+ (getf entry :y) (getf entry :height))))))

(defun rail--morph-draw (look context)
  "morph: the frames over the output, the slab down the seam as tall as the
readings it holds, and the readings set into it, all from CONTEXT."
  (declare (ignore look))
  (destructuring-bind (&key state snapshot epoch seam output carried key side switch
                         old windows voicing fade layer &allow-other-keys)
      context
    (let* ((focus-index (and key (position (getf key :id) windows)))
           (old-index (and old (position old windows)))
           (ghost (rail--ghost snapshot old))
           (motion (rail--motion switch side epoch))
           (voice (cassette--bolo-turn-p (getf state :bolo-state)))
           (moved (if switch (max 0d0 (+ (- (getf switch :at) epoch) (getf +rail--tide+ :settle))) 0d0))
           (calmed (cond (voice 1d6)
                         ((realp fade) (max 0d0 (+ (- fade epoch) (getf +rail--voice+ :settle))))
                         (t 0d0)))
           (blocks (rail--blocks state snapshot seam))
           (extent (or (rail--extent blocks)
                       (let ((middle (+ (getf seam :y) (floor (getf seam :height) 2))))
                         (list middle middle))))
           (pad 60)
           (band-x (- (rail--edge seam) pad))
           (band-width (+ (getf +layout+ :seam) (* 2 pad)))
           (top (getf output :y))
           (left (getf output :x))
           (shader (getf look :shader)))
      (append
       (list (shell-surface
              :rail-frames (ui :stack)
              :output (getf output :name) :anchors '(:top :left)
              :width (rail--design (getf output :width))
              :height (rail--design (getf output :height))
              :layer layer :click-through t
              :background (list :shader shader
                                :data (rail--tide-data
                                       (list left top)
                                       (list band-x (+ band-x band-width))
                                       seam extent output motion focus-index old-index
                                       (rail--voice-data state voicing epoch) nil ghost)
                                :windows windows :clock epoch :until (max moved calmed)
                                ;; only the rings round the cards are
                                ;; ever drawn or repainted
                                :reach (unless ghost (rail--design 40))))
             (shell-surface
              :rail-slab (ui :stack)
              :output (getf output :name) :anchors '(:top :left)
              :width (rail--design band-width)
              :height (rail--design (getf output :height))
              :margin (rail--surface-margin output band-x top)
              :layer layer :click-through t
              :background (list :shader shader
                                :data (rail--tide-data
                                       (list band-x top) (list 0 0)
                                       seam extent output motion focus-index old-index
                                       (rail--voice-data state voicing epoch)
                                       (rail--gauges state blocks) ghost)
                                :windows windows :clock epoch
                                :until (max moved calmed)))
             (shell-surface :rail-type (rail--web state snapshot seam blocks
                                                  (rail--material :material))
                            :output (getf output :name) :anchors '(:top :left)
                            :width (rail--design (rail--seam-width))
                            :height (rail--design (getf seam :height))
                            :margin (rail--surface-margin
                                     output (+ (rail--lane seam :left)
                                               (if side (rail--shift side) 0))
                                     (getf seam :y))
                            :layer layer :background "#00000000"
                            :click-through t :slide t))
       (unless (getf +rail+ :focus-border)
         (loop for entry in carried
               collect (window-properties
                        (getf entry :id)
                        :radius (rail--design (rail--cast :radius))
                        :border (list :focused "#00000000"
                                      :unfocused "#00000000"))))))))

(defparameter +rail-morph+
  (list :draw #'rail--morph-draw :cast +rail--cast+ :font "IBM Plex Mono Medium"))

;;; The rail

(defun rail--theme (state)
  "The theme the rail draws in: the one STATE names, or the first."
  (let ((name (getf state :rail-theme)))
    (if (getf +rail-themes+ name) name (first +rail-themes+))))

(defun rail--next-theme (name)
  "The theme after NAME in +RAIL-THEMES+, round to the first after the last."
  (let ((rest (cddr (member name +rail-themes+))))
    (if rest (first rest) (first +rail-themes+))))

(define-extension "bar" (:reads (:system :services :data :outputs :layout :focus :command :windows)
                         :state (list :cpu nil :memory nil :gpu nil
                                      :bolo-state nil :bolo-level 0
                                      :bolo-since nil :bolo-history nil :bolo-fade nil
                                      :rail-theme nil
                                      :rail-side nil :rail-focus nil
                                      :rail-switch nil :rail-switched nil
                                      :rail-meter nil :rail-step nil :rail-glide nil))
    (snapshot state event)
  (when (eq (getf event :type) :watch)
    (cassette--bolo-watch state event))
  (when (and (eq (getf event :type) :timer) (eq (getf event :name) :sample))
    (let ((system (context snapshot :system)))
      (dolist (probe '(:cpu :memory :gpu))
        (setf (getf state probe) (probe--sample probe (getf state probe) system)))))
  (when (and (eq (getf event :type) :command) (equal (getf event :owner) "bar")
             (equal (getf event :name) "rail-theme"))
    (setf (getf state :rail-theme) (rail--next-theme (rail--theme state))))
  (let* ((theme (rail--theme state))
         (*rail--look* (getf +rail-themes+ theme))
         (*cassette-mode* (state-value snapshot :theme-mode :dark))
         (*rail--mode* *cassette-mode*)
         (*rail--palette* (state-value snapshot :hud-palette))
         (deck (state-value snapshot :deck-seam))
         (focal (and (null deck) (rail--focal snapshot)))
         (cards (and focal (rail--focal-cards snapshot focal)))
         (seam (or deck (first cards)))
         (output (and seam (find (getf seam :output) (context snapshot :outputs)
                                 :key (lambda (o) (getf o :name)) :test #'equal)))
         (*rail--scale* (or (and output (max 1/4 (/ (getf output :scale-120 120) 120))) 1))
         (columns (and deck (state-value snapshot :deck-columns)))
         (carried (if deck
                      (and columns (rail--carried columns (context snapshot :layout)))
                      (second cards)))
         (focus (context snapshot :focus))
         (key (and focus (find focus carried :key (lambda (entry) (getf entry :id)))))
         (side (and key (getf key :side)))
         (layer (if (rail--covered-p snapshot seam) :bottom :top))
         (tray (rail--tray snapshot))
         (now (hud--now))
         (epoch (rail--epoch now))
         (voice (cassette--bolo-turn-p (getf state :bolo-state)))
         (levels (getf state :bolo-history))
         (fade (getf state :bolo-fade))
         (settling (and (not voice) (realp fade) levels
                        (< (- now fade) (getf +rail--voice+ :settle))))
         (voicing (and (plusp (length levels)) (or voice settling)))
         (hot (loop for probe in '(:cpu :gpu)
                    thereis (cassette--hot-p (getf (getf state probe) :temp)))))
    (setf (getf state :rail-theme) theme)
    ;; The readings move toward the last sample before anything draws them.
    (rail--glide state now)
    (rail--switch state (or side (and output :free)) (getf key :id) now)
    (unless (or voice settling)
      (setf (getf state :bolo-history) nil
            (getf state :bolo-fade) nil))
    (let* ((switch (getf state :rail-switch))
           (cut (not (eq (getf +rail+ :throw) :slide)))
           (switching (and switch (< (- now (getf switch :at)) (getf +rail--tide+ :settle))))
           (old (and switching (getf switch :old)))
           (shown (and output (rail--shown carried output)))
           (windows (let ((ids (remove-duplicates (remove nil (list* (getf key :id) old shown))
                                                  :from-end t)))
                      (subseq ids 0 (min 8 (length ids))))))
      (values state
              (append (list (interval :sample (getf +rail+ :sample))
                            (publish-state :hud-hot (and hot t))
                            (publish-state :rail-theme theme)
                            (publish-state :rail-frame (append (getf *rail--look* :frame)
                                                               (list :seam (getf +layout+ :seam))))
                            (define-command "rail-theme"
                              :description "Step the rail to its next theme.")
                            (apply #'bind-key (getf +rail+ :theme-bind)))
                      ;; Each theme animates on the GPU from the times the rail
                      ;; hands it; only the gauges need the rail itself to step,
                      ;; on its one timer, and only when a drawn number is due to
                      ;; change.
                      (let ((due (getf state :rail-glide)))
                        (when due
                          (list (interval :hop (max (getf +rail--glide+ :tick)
                                                    (ceiling (* 1000 due)))))))
                      (cassette--bolo-watches)
                      (when (and output tray)
                        (list (publish-state :shelf-tray-rect
                                             (list :output (getf seam :output)
                                                   :x (+ (rail--lane seam :left) (getf +rail+ :channel))
                                                   :y (* *rail--scale*
                                                         (second (find :tray (rail--blocks state snapshot seam)
                                                                       :key #'first)))
                                                   :width (getf +rail+ :width)
                                                   :height tray))))
                      (when output
                        (funcall (getf *rail--look* :draw) *rail--look*
                                 (list :theme theme :state state :snapshot snapshot
                                       :now now :epoch epoch :seam seam :output output
                                       :carried carried :key key :side side
                                       :switch switch :switching switching :cut cut :old old
                                       :windows windows :voice voice :voicing voicing
                                       :levels levels :fade fade :settling settling
                                       :layer layer :tray tray :hot hot))))
              nil))))
