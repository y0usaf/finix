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
;; MOTION: how long a focus switch is drawn for and the shape of its clock.
;; :DURATION is the seconds the whole move takes, :QUICK the shorter time a move
;; that arrives mid-flight takes -- it retargets from the card the flight started
;; at, straight to the newest, so a run of quick switches shows one move and not
;; one per window -- and :CURVES the clocks the rail knows, which the config
;; picks one of. Every theme keeps the choreography it was drawn with and plays
;; it on this clock: the kit's four count the move's own seconds, morph, glass
;; and sand theirs, so a shorter duration compresses the move instead of cutting
;; it off.
(defparameter +rail--motion+
  (list :duration 0.30d0 :quick 0.12d0
        :curves '(:linear :ease-out-quad :ease-out-cubic :ease-out-expo)))

(defun rail--curve ()
  "Which clock the config asks for: its index in +RAIL--MOTION+ :CURVES."
  (or (position (getf (getf +rail+ :motion) :curve) (getf +rail--motion+ :curves))
      (position :ease-out-cubic (getf +rail--motion+ :curves))))

(defun rail--duration ()
  "The seconds a focus switch takes, from the config's bar.rail.motion."
  (let ((ms (getf (getf +rail+ :motion) :duration-ms)))
    (if (and (realp ms) (plusp ms))
        (/ ms 1000d0)
        (getf +rail--motion+ :duration))))

(defun rail--quick ()
  "The seconds a switch that lands mid-move takes: short enough to read as the
move retargeting rather than a second transition of its own."
  (max (/ 1d0 60) (min (getf +rail--motion+ :quick) (* 0.4d0 (rail--duration)))))

(defun rail--settle (switch)
  "How long SWITCH is drawn for."
  (or (and switch (getf switch :settle)) (rail--duration)))

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

(defun rail--trail ()
  "The pointer's trail: the theme's own cells, in the colour its cast gives them
for this mode -- or its readings' ink -- and nothing at all when the config keeps
trails off or the theme names none."
  (let* ((trail (getf *rail--look* :trail))
         (color (and trail (getf (getf (getf *rail--look* :cast) *rail--mode*)
                                 (getf trail *rail--mode*)))))
    (list :enabled (and trail t)
          :cell (or (getf trail :cell) 9d0)
          :life (or (getf trail :life) 0.35d0)
          :steps (or (getf trail :steps) 4)
          :shape (or (getf trail :shape) :cells)
          :color (or color (rail--ink)))))

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

(defun rail--place (specs anchor scale extent)
  "SPECS ((MODULE SIZE SPACE) ...) along the strip's axis in design units: SIZE is
the block's extent along it, SPACE the air before it, the first's ignored. ANCHOR
(MODULE . AT) pins that block's start AT design units from the strip's start;
without one the blocks are centred. Returns ((MODULE START SIZE) ...) in output
pixels from the strip's start, scaling and rounding each number once."
  (let* ((entries (mapcar (lambda (spec)
                            (list (first spec) (* scale (second spec)) (* scale (third spec))))
                          specs))
         (n (length entries))
         (pin (and anchor (position (car anchor) entries :key #'first))))
    (when (plusp n)
      (if pin
          (let ((at (* scale (cdr anchor))) (after nil) (before nil))
            (let ((start at) (i pin))
              (loop while (< i n)
                    do (when (> i pin)
                         (setf start (+ start (second (nth (1- i) entries))
                                        (third (nth i entries)))))
                       (push (list (first (nth i entries)) start
                                   (second (nth i entries)))
                             after)
                       (setf i (1+ i))))
            (let ((start at) (i (1- pin)))
              (loop while (>= i 0)
                    do (setf start (- start (third (nth (1+ i) entries))
                                      (second (nth i entries))))
                       (push (list (first (nth i entries)) start
                                   (second (nth i entries)))
                             before)
                       (setf i (1- i))))
            (append before (nreverse after)))
          (let* ((total (+ (loop for (module size space) in entries sum size)
                          (loop for (module size space) in (rest entries) sum space)))
                 (start (- (/ (or extent total) 2) (/ total 2)))
                 (after nil)
                 (i 0))
            (loop while (< i n)
                  do (when (plusp i)
                       (setf start (+ start (third (nth i entries))
                                      (second (nth (1- i) entries)))))
                     (push (list (first (nth i entries)) start
                                 (second (nth i entries)))
                           after)
                     (setf i (1+ i)))
            (nreverse after))))))

(defun rail--strip (place axis output ox oy width height blocks)
  (list :place place :axis axis :output output :x ox :y oy :width width :height height
        :blocks blocks))

(defun rail--seam-strip (output seam)
  (and seam (rail--strip :seam :y output (getf seam :x) (getf seam :y)
                         (getf seam :width) (getf seam :height) nil)))

(defun rail--across (strip)
  "STRIP's extent across its axis, in output pixels: (LO . SIZE)."
  (if (eq (getf strip :axis) :y)
      (cons (getf strip :x) (getf strip :width))
      (cons (getf strip :y) (getf strip :height))))

(defun rail--shader-origin (output x y height)
  "The corner a shader surface at (X, Y) from the output's top and HEIGHT tall
counts from: the rail's shaders read the output's own coordinates."
  (declare (ignore output height))
  (list x y))

(defun rail--shader-rect (output strip)
  "STRIP as the rail's shaders read it: (X0 Y0 X1 Y1) in the output's pixels."
  (declare (ignore output))
  (list (getf strip :x) (getf strip :y)
        (+ (getf strip :x) (getf strip :width))
        (+ (getf strip :y) (getf strip :height))))

(defun rail--strip-blocks (state snapshot strip specs anchor)
  "SPECS placed along STRIP's axis, as (MODULE X Y WIDTH HEIGHT) in output pixels
from the strip's corner."
  (let* ((vertical (eq (getf strip :axis) :y))
         (placed (rail--place specs anchor *rail--scale*
                              (if vertical
                                  (/ (getf strip :height) *rail--scale*)
                                  (/ (getf strip :width) *rail--scale*))))
         (width (getf strip :width)) (height (getf strip :height)))
    (loop for (module start size) in placed
          collect (if vertical
                      (list module 0 start width size)
                      (list module start 0 size height)))))

(defun rail--seam-specs (state snapshot)
  "The seam's blocks in design units: the tray and bolo's turn above the clock,
the modules in the order the bar names them, the air the rail leaves between."
  (let* ((tray (rail--tray snapshot))
         (voice (and (cassette--bolo-turn-p (getf state :bolo-state)) 22))
         (above (append (when voice (list (list :voice voice +rail--air+)))
                        (when tray (list (list :tray (/ tray *rail--scale*) +rail--air+)))))
         (modules (loop for module in (getf +rail+ :modules)
                        for height = (rail--height module state snapshot)
                        when height collect (list module height +rail--air+))))
    (append above modules)))

(defun rail--seam-anchor (state snapshot strip)
  (declare (ignore state snapshot))
  (let ((height (getf strip :height)))
    (when (and (realp height) (realp *rail--scale*) (plusp *rail--scale*))
      (cons :time (- (/ height *rail--scale* 2) +rail--clock-inset+)))))

(defun rail--weld (strip box)
  "Where STRIP's material attaches to the focused card BOX: the point of the box
nearest the strip, as (X . Y) in output pixels, or NIL with no card."
  (when (and box strip (getf strip :x) (getf strip :width)
             (getf box :width) (getf box :height))
    (let* ((place (getf strip :place))
           (x0 (getf box :x)) (y0 (getf box :y))
           (x1 (+ x0 (getf box :width))) (y1 (+ y0 (getf box :height)))
           (mid-x (max x0 (min x1 (+ (getf strip :x) (floor (getf strip :width) 2)))))
           (mid-y (max y0 (min y1 (+ (getf strip :y) (floor (getf strip :height) 2))))))
      (cond ((eq place :seam)
             (cons (if (< (+ (getf strip :x) (getf strip :width)) x0) x0 x1) mid-y))
            ((eq place :top) (cons mid-x y0))
            (t (cons mid-x y1))))))

(defun rail--edge-strips (look output)
  "The bars an output the deck gives no seam carries: a strip along its top edge and
one along its bottom, as wide as the output and as thick as the theme's strip."
  (let* ((scale (/ (getf output :scale-120 120) 120))
         (thickness (round (* scale (getf look :strip-height (rail--seam-width)))))
         (top (rail--strip :top :x output (getf output :x) (getf output :y)
                           (getf output :width) thickness nil))
         (bottom (rail--strip :bottom :x output (getf output :x)
                              (- (+ (getf output :y) (getf output :height)) thickness)
                              (getf output :width) thickness nil)))
    (list top bottom)))

(defparameter +rail--kinds+
  '((:time . 0) (:date . 1) (:cpu . 2) (:memory . 3) (:gpu . 4) (:vram . 5)
    (:voice . 6) (:tray . 7) (:media . 8) (:battery . 9) (:network . 10) (:frame . 11)))

(defun rail--kind (module)
  "MODULE as the rail's shaders read a block's kind."
  (or (cdr (assoc module +rail--kinds+)) 11))

(defparameter +rail--blocks-max+ 8)

(defun rail--block-data (strip blocks &key (max +rail--blocks-max+))
  "BLOCKS as a theme's shader reads them: how many, then each block's kind and
its rect in output pixels from STRIP's corner, then empty blocks up to MAX, the
fixed table size so every theme reads its own numbers at the same index."
  (let* ((ox (getf strip :x)) (oy (getf strip :y))
         (shown (subseq blocks 0 (min max (length blocks)))))
    (append (list (length shown))
            (loop for (module x y width height) in shown
                  append (list (rail--kind module) (+ ox x) (+ oy y)
                               (+ ox x width) (+ oy y height)))
            (make-list (* 5 (max 0 (- max (length shown)))) :initial-element 0))))

(defun rail--strip-surface (look context strip name data)
  "A surface on STRIP drawing DATA with the theme's shader: the whole strip, and
on a bar the work area it reserves."
  (destructuring-bind (&key output epoch layer &allow-other-keys) context
    (let ((seam (eq (getf strip :place) :seam)))
      (shell-surface
       name
       (ui :stack)
       :output (getf output :name)
       :anchors (if seam (list :top :left) (list (getf strip :place)))
       :width (rail--design (getf strip :width))
       :height (rail--design (getf strip :height))
       :margin (if seam (rail--surface-margin output (getf strip :x) (getf strip :y)) 0)
       :layer layer :click-through t
       :exclusive-zone (if seam 0 (rail--design (getf strip :height)))
       :background (list :shader (getf look :shader) :data data :clock epoch
                         :until (kit--until look context))))))

(defun rail--bar-modules (state snapshot place)
  "The blocks a bar at PLACE carries: the clock and the date along the top bar,
the readings and bolo's turn along the bottom."
  (if (eq place :top)
      (loop for module in '(:time :date)
            when (rail--height module state snapshot) collect module)
      (append (loop for module in (getf +rail+ :modules)
                    when (and (rail--height module state snapshot)
                              (not (member module '(:time :date))))
                      collect module)
              (when (cassette--bolo-turn-p (getf state :bolo-state)) (list :voice)))))

(defun rail--bar-blocks (state snapshot strip &optional modules)
  "STRIP's blocks as (MODULE X Y WIDTH HEIGHT) in output pixels: one equal slot
each along the strip, by the shared placement, centred in it."
  (let* ((modules (or modules (rail--bar-modules state snapshot (getf strip :place))))
         (n (length modules))
         (span (if (eq (getf strip :axis) :y) (getf strip :height) (getf strip :width))))
    (when (plusp n)
      (rail--strip-blocks state snapshot strip
                          (loop for module in modules collect (list module (floor span n) 0))
                          nil))))

(defun rail--windows-on (snapshot output)
  "Every visible window on OUTPUT, as (:ID :SIDE :BOX), nearest each side's front
first: the cards a rail strip on that output carries."
  (let ((x0 (getf output :x)) (y0 (getf output :y))
        (x1 (+ (getf output :x) (getf output :width)))
        (y1 (+ (getf output :y) (getf output :height)))
        (middle (+ (getf output :x) (floor (getf output :width) 2))))
    (loop for entry in (context snapshot :layout)
          when (and (getf entry :visible)
                    (< x0 (+ (getf entry :x) (getf entry :width)))
                    (< (getf entry :x) x1)
                    (< y0 (+ (getf entry :y) (getf entry :height)))
                    (< (getf entry :y) y1))
            collect (list :id (getf entry :id)
                          :side (if (< (+ (getf entry :x) (floor (getf entry :width) 2)) middle)
                                    :left :right)
                          :box entry))))

(defun rail--strips (look state snapshot deck output)
  "The rail's strips: the deck's seam on its output, and a top and a bottom bar on
every output the deck gives no seam, each with the weld it attaches to."
  (declare (ignore state))
  (let* ((focus-box (and (context snapshot :focus)
                         (find (context snapshot :focus) (context snapshot :layout)
                               :key (lambda (entry) (getf entry :id)))))
         (seam (and deck output
                     (rail--strip :seam :y output (getf deck :x) (getf deck :y)
                                  (getf deck :width) (getf deck :height) nil)))
         (narrow (loop for o in (context snapshot :outputs)
                       when (deck--narrow-p (list :output o)) collect o))
         (groups (append (when seam (list (list output (list seam))))
                         (loop for o in narrow
                               collect (list o (rail--edge-strips look o))))))
    (loop for group in groups
          for group-output = (first group)
          collect (list group-output
                        (loop for strip in (second group)
                              collect (append strip
                                              (list :weld (rail--weld strip focus-box))))))))

(defun rail--tray (snapshot)
  "The height of the slot the shelf asked for at the top of the stack, or NIL."
  (let ((tray (state-value snapshot :shelf-tray)))
    (when (and tray (plusp (getf tray :count 0)) (plusp (getf tray :size 0)))
      (* (getf tray :count) (getf tray :size)))))

(defun rail--blocks (state snapshot strip)
  "Every block the rail stacks in STRIP, as (MODULE X Y WIDTH HEIGHT) in output
pixels from the strip's corner: the readings round the clock, and above them bolo's
turn and the shelf's tray when they are there."
  (rail--strip-blocks state snapshot strip
                      (rail--seam-specs state snapshot)
                      (rail--seam-anchor state snapshot strip)))

(defun rail--extent (strip blocks)
  "The first block's start and the last block's end along STRIP's axis, in output
pixels."
  (when blocks
    (let* ((last (car (last blocks)))
           (vertical (eq (getf strip :axis) :y))
           (from (if vertical (getf strip :y) (getf strip :x)))
           (start (if vertical (third (first blocks)) (second (first blocks))))
           (end (if vertical (+ (third last) (fifth last))
                    (+ (second last) (fourth last)))))
      (list (+ from start) (+ from end)))))


(defun rail--web (state snapshot strip blocks ground)
  "The readings, the voice block and the tray, in type over the track."
  (let ((width (if (eq (getf strip :axis) :y) (rail--seam-width) (getf strip :width)))
        (height (getf strip :height))
        (vertical (eq (getf strip :axis) :y))
        (cursor 0) (parts nil))
    (loop for (module x y block-width block-height) in blocks
          for from = (if vertical y x)
          for size = (if vertical block-height block-width)
          do (when (> from cursor) (push (cons (- from cursor) nil) parts))
             (push (cons size
                         (case module
                           (:tray (ui :rect :height (rail--design size)
                                      :width (rail--design 52) :background (rail--c :tray)))
                           (:voice (rail--voice state))
                           (t (rail--block module state snapshot ground))))
                   parts)
             (setf cursor (+ from size)))
    (if vertical
        (ui :column :align :center :width (rail--design width) :height (rail--design height)
            :children (loop for (tall . node) in (nreverse parts)
                            collect (or node (ui :rect :height (rail--design tall)))))
        (ui :row :align :center :justify :center :width (rail--design (getf strip :width))
            :height (rail--design (getf strip :height))
            :children (loop for (module x y block-width block-height) in blocks
                            collect (ui :column :align :center :justify :center
                                        :width (rail--design block-width)
                                        :height (rail--design block-height)
                                        :children
                                        (list (case module
                                                (:tray (ui :rect :height (rail--design block-height)
                                                           :width (rail--design 52)
                                                           :background (rail--c :tray)))
                                                (:voice (rail--voice state))
                                                (t (rail--block module state snapshot ground))))))))))


(defun rail--gauges (strip state blocks)
  "The readings the slab swells with, as the shader reads them: for each gauge
its middle and half its reach in output pixels and its fraction, up to five."
  (let ((meter (getf state :rail-meter))
        (vertical (eq (getf strip :axis) :y))
        (from (if (eq (getf strip :axis) :y) (getf strip :y) (getf strip :x))))
    (loop for (module x y block-width block-height) in blocks
          for value = (case module
                        (:cpu (getf meter :cpu)) (:memory (getf meter :memory))
                        (:gpu (getf meter :gpu)) (:vram (getf meter :vram)))
          when value
            collect (list (if vertical (+ from y (/ block-height 2)) (+ from x (/ block-width 2)))
                          (/ (+ (if vertical block-height block-width)
                                (* *rail--scale* +rail--air+))
                             2)
                          (/ (max 0 (min 100 value)) 100d0))
              into gauges
          finally (return (subseq gauges 0 (min 5 (length gauges)))))))


;;; The slab and the frames


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
redraws.

A switch that arrives while the last move is still being drawn retargets it:
the move keeps the card and side it started from, so the window focus passed
through is never animated on its own, and it is drawn for the quick time. A run
of switches across four windows is therefore one move, from where the run began
to where it ends."
  (let ((was (getf state :rail-side))
        (old (getf state :rail-focus))
        (prev (getf state :rail-switch)))
    (when (and side was (not (and (eql side was) (eql id old)))
               (eq (getf +rail+ :throw) :slide))
      (let* ((moving (and prev (< (- now (getf prev :at)) (rail--settle prev))))
             (last (getf state :rail-switched))
             (pour (and last (< (- now last) (getf +rail--tide+ :gap)))))
        (setf (getf state :rail-switch)
              (list :at now
                    :from (if moving (getf prev :from) was)
                    :flow (if moving :pour (if pour :pour :siphon))
                    :old (if moving (getf prev :old) old)
                    :settle (if moving (rail--quick) (rail--duration)))
              (getf state :rail-switched) now)))
    (setf (getf state :rail-side) side
          (getf state :rail-focus) id)))

(defun rail--motion (switch side epoch)
  "The switch as the shader reads it: side, previous side, start, flow, hold,
gulp, how long it is drawn for and the clock its shape runs on."
  (let* ((flow (and switch (getf switch :flow)))
         (tide (getf +rail--tide+ (or flow :pour))))
    (list (rail--side-sign side)
          (if flow (rail--side-sign (getf switch :from)) (rail--side-sign side))
          (if switch (- (getf switch :at) epoch) -1d6)
          (case flow (:pour 0) (:siphon 1) (t -1))
          (getf tide :hold)
          (if (eq flow :siphon) (getf tide :gulp) 0)
          (rail--settle switch)
          (rail--curve))))

(defun rail--bands (levels)
  "Three bands of the voice from its level history, newest first: LO the swell it
is riding (the loudest of the last third of a second), MID the level now, and HI
the fast edge, how much the level is moving from sample to sample. They are what
the focused frame moves with, so its whole border answers at once and the three
of them give the border a shape and an attack rather than one uniform pump."
  (when levels
    (let* ((window (subseq levels 0 (min 9 (length levels))))
           (lo (reduce #'max window))
           (now (first levels))
           (moves (loop for (a b) on levels while b collect (abs (- a b))))
           (steps (subseq moves 0 (min 6 (length moves))))
           (hi (if steps
                   (min 1d0 (* 3d0 (/ (reduce #'+ steps) (length steps))))
                   0d0)))
      (list lo now hi))))

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
            (or (rail--bands levels) (list 0 0 0))
            levels
            (make-list (- 48 (length levels)) :initial-element 0))))

(defun rail--tide-data (origin skip strip extent output motion focus old voice gauges ghost
                        slab rail free)
  "Every number morph.glsl reads, in the order it reads them. ORIGIN is the
surface's corner and SKIP the span across the strip it leaves to the other
surface, both in output pixels, and EXTENT the ends of the rail's stack the slab
holds; FOCUS and OLD index the surface's :WINDOWS; GAUGES are what RAIL--GAUGES
makes of the readings the slab swells with; GHOST is the box the old card last
stood in when it is no longer shown, for its frame to drain from. SLAB says this
surface draws the slab at all, RAIL which side of the focused card the strip
stands on (0 right, 1 left, 2 above, 3 below) and FREE which way a bar's free
edge faces."
  (let* ((cast (getf *rail--look* :cast))
         (tide +rail--tide+)
         (lead (getf tide :lead)) (trail (getf tide :trail)) (ring (getf tide :ring))
         (pour (getf tide :pour)) (siphon (getf tide :siphon))
         (seam (eq (getf strip :place) :seam))
         (across (rail--across strip))
         (rect (rail--shader-rect output strip))
         (glass (rail--material :glass)))
    (append origin skip
            (rail--rgb (rail--material :material)) (rail--rgb (rail--material :line))
            (rail--rgb (rail--material :shadow)) (rail--rgb (rail--material :shine))
            (list (rail--material :gloss) (rail--material :shade)
                  (getf cast :radius) (getf cast :frame) (getf cast :line-width)
                  (getf cast :slab) (getf cast :inset) (getf cast :end) (getf cast :weld)
                  (if seam (rail--edge strip) (car across))
                  (if seam (getf +layout+ :seam) (cdr across)))
            motion
            (list (or focus -1) (or old -1) (length gauges) (first extent) (second extent)
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
            ;; the pane's numbers, always here so glass and morph read the same
            ;; layout: morph has no glass and never looks at them
            (if glass
                (append (loop for key in '(:frost :lens :bevel :rim :haze :vibrance :contrast :edge)
                              collect (getf glass key))
                        (rail--rgb (rail--ink)))
                (make-list 11 :initial-element 0))
            (list (if seam 0d0 1d0) (first rect) (second rect) (third rect) (fourth rect)
                  (if slab 1d0 0d0) (coerce rail 'double-float)
                  (coerce free 'double-float)))))


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

(defun rail--morph-rail (strip side)
  "Which side of the focused card STRIP stands on, as morph.glsl counts it: 0 to
the card's right, 1 to its left, 2 above it, 3 below."
  (case (getf strip :place)
    (:top 2) (:bottom 3)
    (t (if (eq side :left) 0 1))))

(defun rail--morph-motion (strip switch side epoch)
  "The switch as morph.glsl reads it: down a seam the slab hops between the cards'
sides; on a bar it holds its place and only the frames pour."
  (if (eq (getf strip :place) :seam)
      (rail--motion switch side epoch)
      (let* ((free (if (eq (getf strip :place) :top) 1 -1))
             (hold (rail--side-sign (if (minusp free) :right :left)))
             (m (rail--motion switch (if (minusp free) :right :left) epoch)))
        (list hold hold
              (nth 2 m) (nth 3 m) (nth 4 m) (nth 5 m) (nth 6 m) (nth 7 m)))))

(defun rail--morph-band (output strip)
  "The rect the slab and its frame weld draw on, in output pixels, as
(X Y WIDTH HEIGHT): down a seam the band the seam leaves plus the air the weld
reaches, and on a bar the strip and the air it reaches into the cards."
  (if (eq (getf strip :place) :seam)
      (list (- (rail--edge strip) 60) (getf output :y)
            (+ (getf +layout+ :seam) 120) (getf output :height))
      (list (getf output :x)
            (if (eq (getf strip :place) :top) (getf strip :y) (- (getf strip :y) 60))
            (getf output :width)
            (+ (getf strip :height) 60))))

(defun rail--morph-draw (look context)
  "morph: the frames over the output, the slab down the seam -- or along a bar --
as long as the readings it holds, and the readings set into it, all from
CONTEXT."
  (declare (ignore look))
  (destructuring-bind (&key state snapshot epoch output carried key side switch
                         old windows voicing fade layer strips &allow-other-keys)
      context
    (let* ((seam-strip (find :seam strips :key (lambda (s) (getf s :place))))
           (bars (if seam-strip (remove seam-strip strips) strips))
           (probe (or seam-strip (first bars)))
           (focus-index (and key (position (getf key :id) windows)))
           (old-index (and old (position old windows)))
           (ghost (rail--ghost snapshot old))
           (voice (cassette--bolo-turn-p (getf state :bolo-state)))
           (moved (if switch (max 0d0 (+ (- (getf switch :at) epoch) (rail--settle switch))) 0d0))
           (calmed (cond (voice 1d6)
                         ((realp fade) (max 0d0 (+ (- fade epoch) (getf +rail--voice+ :settle))))
                         (t 0d0)))
           (until (max moved calmed))
           (shader (getf look :shader))
           (now-origin (rail--shader-origin output (getf output :x) (getf output :y)
                                           (getf output :height)))
           (extent-of (lambda (strip blocks)
                        (or (rail--extent strip blocks)
                            (let* ((vertical (eq (getf strip :axis) :y))
                                   (from (if vertical (getf strip :y) (getf strip :x)))
                                   (size (if vertical (getf strip :height) (getf strip :width)))
                                   (middle (+ from (floor size 2))))
                              (list middle middle)))))
           (numbers (lambda (strip origin skip blocks gauges slab)
                      (rail--tide-data
                       origin skip strip (funcall extent-of strip blocks)
                       output (rail--morph-motion strip switch side epoch)
                       focus-index old-index (rail--voice-data state voicing epoch)
                       gauges ghost slab (rail--morph-rail strip side)
                       (if (and strip (eq (getf strip :place) :top)) 1 -1)))))
      (when probe
        (let* ((band (rail--morph-band output probe))
               (band-x (first band)) (band-width (third band))
               ;; down a seam the frames keep their share of the slab's field, so
               ;; the band's own surface draws that share for both; on a bar the
               ;; slab is the bar's alone
               (frames-data (if seam-strip
                                (funcall numbers seam-strip now-origin
                                         (list band-x (+ band-x band-width))
                                         (rail--blocks state snapshot seam-strip) nil t)
                                (funcall numbers probe now-origin (list 0 0) nil nil nil))))
          (append
           (list (shell-surface
                  :rail-frames (ui :stack)
                  :output (getf output :name) :anchors '(:top :left)
                  :width (rail--design (getf output :width))
                  :height (rail--design (getf output :height))
                  :layer layer :click-through t
                  :background (list :shader shader :data frames-data
                                    :windows windows :clock epoch :until until
                                    ;; only the rings round the cards are ever
                                    ;; drawn or repainted
                                    :reach (unless ghost (rail--design 40)))))
           (loop for strip in strips
                 for field = (rail--morph-band output strip)
                 for bx = (first field) for by = (second field)
                 for bw = (third field) for bh = (fourth field)
                 for seam-p = (eq (getf strip :place) :seam)
                 for blocks = (if seam-p (rail--blocks state snapshot strip)
                                   (rail--bar-blocks state snapshot strip))
                 for tag = (if seam-p "" (format nil "-~A" (string-upcase (symbol-name (getf strip :place)))))
                 append
                 (list (shell-surface
                        (intern (format nil "RAIL-SLAB~A" tag) :keyword)
                        (ui :stack)
                        :output (getf output :name)
                        :anchors (if seam-p (list :top :left) (list (getf strip :place)))
                        :width (rail--design bw) :height (rail--design bh)
                        :margin (if seam-p (rail--surface-margin output bx by) 0)
                        :layer layer :click-through t
                        :exclusive-zone (if seam-p 0 (rail--design (getf strip :height)))
                        :background (list :shader shader
                                          :data (funcall numbers strip
                                                         (rail--shader-origin output bx by bh)
                                                         (list 0 0) blocks
                                                         (rail--gauges strip state blocks) t)
                                          :windows windows :clock epoch :until until))
                       (shell-surface
                        (intern (format nil "RAIL-TYPE~A" tag) :keyword)
                        (rail--web state snapshot strip blocks (rail--material :material))
                        :output (getf output :name)
                        :anchors (if seam-p (list :top :left) (list (getf strip :place)))
                        :width (rail--design (if seam-p (rail--seam-width) (getf strip :width)))
                        :height (rail--design (getf strip :height))
                        :margin (if seam-p
                                    (rail--surface-margin
                                     output
                                     (+ (rail--lane strip :left) (if side (rail--shift side) 0))
                                     (getf strip :y))
                                    0)
                        :layer layer :background "#00000000"
                        :click-through t :slide t)))
           (unless (getf +rail+ :focus-border)
             (loop for entry in carried
                   collect (window-properties
                            (getf entry :id)
                            :radius (rail--design (rail--cast :radius))
                            :border (list :focused "#00000000"
                                          :unfocused "#00000000"))))))))))

(defparameter +rail-morph+
  (list :draw #'rail--morph-draw :cast +rail--cast+ :font "IBM Plex Mono Medium"
        :strip-height 96
        :trail (list :cell 7d0 :life 0.3d0 :steps 5 :shape :dots
                     :dark :shine :light :shadow)))

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
         (seam deck)
         (output (and seam (find (getf seam :output) (context snapshot :outputs)
                                 :key (lambda (o) (getf o :name)) :test #'equal)))
         (*rail--scale* (or (and output (max 1/4 (/ (getf output :scale-120 120) 120))) 1))
         (strips (rail--strips *rail--look* state snapshot deck output))
         (columns (and deck (state-value snapshot :deck-columns)))
         (carried (and deck columns (rail--carried columns (context snapshot :layout))))
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
           (switching (and switch (< (- now (getf switch :at)) (rail--settle switch))))
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
                      (when (and (getf +rail+ :trail) (tomoe-setting-known-p :cursor-trail))
                        (list (settings :cursor-trail (rail--trail))))
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
                                                   :y (+ (getf seam :y)
                                                         (third (find :tray (rail--blocks state snapshot
                                                                                          (rail--seam-strip output seam))
                                                                      :key #'first)))
                                                   :width (getf +rail+ :width)
                                                   :height tray))))
                      (loop for group in strips
                            for group-output = (first group)
                            for group-strips = (second group)
                            when group-strips append (funcall (getf *rail--look* :draw) *rail--look*
                                            (list :theme theme :state state :snapshot snapshot
                                                  :now now :epoch epoch
                                                  :seam (and (eq group-output output) seam)
                                                  :strips group-strips :output group-output
                                                  :carried (if (eq group-output output)
                                                               carried
                                                               (rail--windows-on snapshot group-output))
                                                  :key key :side side
                                                  :switch switch :switching switching
                                                  :cut cut :old old
                                                  :windows (if (eq group-output output)
                                                               windows
                                                               (let ((ids (mapcar (lambda (entry) (getf entry :id))
                                                                                  (rail--windows-on snapshot group-output))))
                                                                 (subseq ids 0 (min 8 (length ids)))))
                                                  :voice voice :voicing voicing
                                                  :levels levels :fade fade :settling settling
                                                  :layer (if (eq group-output output) layer :top)
                                                  :tray tray :hot hot))))
              nil))))
