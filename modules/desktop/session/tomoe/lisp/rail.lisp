(in-package #:tomoe-user)

;;; morph
;;;
;;; The seam between the deck's two columns is filled by one slab, and the
;;; focused card's frame is the same material: one colour, one thickness, the two
;;; welded where they meet by the smooth minimum of their fields, so slab, frame
;;; and the readings knocked out of the slab in ink read as one cast piece. Every
;;; other card the rail carries keeps a thin, darker line, and the slab stands off
;;; it with the wallpaper visible in between. The cards' corners are rounded to
;;; the frame's radius.
;;;
;;; When focus crosses the rail the slab hops: its leading edge leaps to the new
;;; card on a stiff spring and its trailing edge lets go on a looser one, so the
;;; slab stretches across the seam and snaps back to width. How the frame moves
;;; depends on the pace of the work (TIDE): a switch after a pause siphons -- the
;;; old frame drains back into the slab, the slab gulps, and the new frame fills
;;; out of it round the card -- while a switch hard on the heels of another only
;;; pours, the old frame thinning away as the new one swells in, so fast work
;;; stays calm. While bolo has the turn the slab is the voice: its free edge is a
;;; level history, a wave whose reach at each row is the level the voice had when
;;; it passed, newest at the top, with a belly that leans out with the level being
;;; spoken and a heave of the whole slab; when the turn closes it calms.
;;;
;;; All of that is one shader (shaders/morph.glsl) drawn on the GPU over two
;;; surfaces: a band down the seam and the frames over the rest of the output. The
;;; rail hands it the numbers below, the carried cards (whose drawn boxes the
;;; compositor fills in every frame, so a frame rides a card that is still sliding)
;;; and the times of the last switch and of bolo's turn; the shader animates from
;;; those on its own. Each surface draws every refresh only until its last motion
;;; has settled and then holds that picture, so a still rail costs nothing, and
;;; the voice band repaints alone while the frames stay put.
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
(defvar *rail--mode* :dark)
(defvar *rail--scale* 1)

(defparameter +rail--clock-inset+ 27)
(defparameter +rail--clock-height+ 62)
(defparameter +rail--air+ 32)

;; The voice: the slab is the meter, so what bolo says is drawn by the slab's own
;; shape. While the turn is open the free edge is a wave over its whole height,
;; its reach at each row the level the voice had when it passed (newest at the
;; top), plus a belly that leans out with the level being spoken; the whole slab
;; heaves with it. Every number the shape follows is here.
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
        :fade 48))       ; pixels the wave takes to reach full strength at each end

;; CAST: the material and its geometry, in physical pixels. The slab fills
;; :SLAB of the seam and stops :INSET short of its card's ends, which it rounds
;; by :END; the focused frame is :FRAME thick round corners of :RADIUS, welded to
;; the slab over :WELD; every other card has a :LINE-wide line. A stretched slab
;; gives back :SQUASH of its stretch at its ends. Each mode has its :MATERIAL,
;; the :LINE colour, the :SHADOW the material casts at :SHADE strength, and the
;; :SHINE its highlight takes at :GLOSS.
(defparameter +rail--cast+
  (list :frame 5 :line-width 1.5 :radius 14 :slab 50 :inset 30 :end 12 :weld 28 :squash 0.7
        :dark (list :material "#3A3E58" :line "#26283C" :shadow "#020208" :shade 0.55
                    :shine "#ECE7DC" :gloss 0.34)
        :light (list :material "#B2ACA2" :line "#D6D2CA" :shadow "#342E28" :shade 0.24
                     :shine "#FFFFFF" :gloss 0.55)))

;; TIDE: how a switch across the seam moves, in seconds unless marked. A switch
;; that comes :GAP or more after the previous one siphons, a quicker one pours;
;; either draws for :SETTLE. The slab's leading edge rides a spring of :OMEGA
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

(defun rail--value () (rail--c :ink))

(defun rail--detail ()
  (hud--fade (rail--c :ink) (if (eq *rail--mode* :dark) 0.62 0.66)))

(defun rail--label ()
  (hud--fade (rail--c :ink) (if (eq *rail--mode* :dark) 0.40 0.46)))

(defun rail--outline ()
  (hud--fade (rail--c :ink) 0.90))

(defun rail--parts (text)
  (loop with start = 0
        for i = (position-if (lambda (c) (member c '(#\: #\Space))) text :start start)
        for part = (subseq text start i)
        when (plusp (length part)) collect part
        while i do (setf start (1+ i))))

(defun rail--text (text color size &optional (height size))
  (ui :text :text text :size (rail--design size) :line-height (rail--design size)
      :height (rail--design height) :color color :font (getf +cassette+ :font)))

(defun rail--split-unit (text)
  "TEXT as its number and its trailing percent sign, the sign drawn one tier
below the number it belongs to."
  (if (and (plusp (length text)) (char= (char text (1- (length text))) #\%))
      (list (subseq text 0 (1- (length text))) "%")
      (list text nil)))

(defun rail--number (text &optional (height 22))
  (destructuring-bind (number unit) (rail--split-unit text)
    (ui :row :align :center
        :children (append (list (rail--text number (rail--value) 22 height))
                          (when unit (list (rail--text unit (rail--label) 22 height)))))))

(defun rail--badge (node ground)
  "NODE inside a one pixel ink outline: a warning without a hue."
  (ui :column :align :center :padding '(3 4 0 4) :radius 3 :border 1
      :border-color (rail--outline) :background ground
      :children (list node)))

(defun rail--meter (percent)
  "A 36 wide, four tall rounded pill: the played fraction of the media, the
one reading a percentage cannot carry."
  (ui :progress :width (rail--design 36) :height (rail--design 4)
      :radius (rail--design 2) :value (/ (max 0 (min 100 (round (or percent 0)))) 100)
      :track (hud--fade (rail--c :ink) 0.12) :color (rail--value)))

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
        (append (list (rail--text label (rail--label) 22)
                      (if (> percent 84)
                          (rail--badge (rail--number value 19) ground)
                          (rail--number value)))
                (when detail
                  (list (if hot
                            (rail--badge (rail--number detail 19) ground)
                            (rail--text detail (rail--detail) 22))))))))

(defun rail--date ()
  (destructuring-bind (&optional day date month &rest rest)
      (rail--parts (string-upcase (clock-text (getf +cassette+ :date))))
    (declare (ignore rest))
    (ui :column :align :center
        :children (remove nil
                          (list (when day (rail--text day (rail--label) 22))
                                (when date (rail--text date (rail--value) 22))
                                (when month (rail--text month (rail--label) 22)))))))

(defun rail--clock ()
  (destructuring-bind (&optional hours minutes)
      (rail--parts (clock-text (getf +cassette+ :time)))
    (ui :column :align :center
        :children (list (rail--text (or hours "--") (rail--value) 33)
                        (rail--text (or minutes "--") (rail--value) 33 29)))))

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
        :children (list (rail--text (if (equal status "Playing") ">" "||") (rail--value) 22)
                        (rail--meter (round (* 100 played)))
                        (ui :rect :height (rail--design 8))))))

(defun rail--network (snapshot)
  (let ((online (getf (service-state snapshot :network) :connected)))
    (ui :column :align :center
        :children (list (rail--text "NET" (rail--label) 22)
                        (rail--text (if online "ON" "OFF") (rail--value) 22)))))

(defun rail--voice (state)
  "Bolo's turn at the top of the web: the elapsed time. The level itself is the
slab's shape, not a reading."
  (let ((since (getf state :bolo-since)))
    (ui :column :align :center
        :children (list (rail--text (cassette--bolo-clock
                                     (and (realp since) (- (cassette--bolo-now) since)))
                                    (rail--value) 22)))))

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
  "The height of the slot the shelf asked for at the top of the web, or NIL."
  (let ((tray (state-value snapshot :shelf-tray)))
    (when (and tray (plusp (getf tray :count 0)) (plusp (getf tray :size 0)))
      (* (getf tray :count) (getf tray :size)))))

(defun rail--web (state snapshot seam ground)
  "The readings, the voice block and the tray, in type over the track."
  (let* ((base (/ (getf seam :y) *rail--scale*))
         (height (/ (getf seam :height) *rail--scale*))
         (width (rail--seam-width))
         (tray (rail--tray snapshot))
         (voice (cassette--bolo-turn-p (getf state :bolo-state)))
         (parts nil)
         (cursor 0))
    (labels ((to (screen-y)
               (let ((y (- screen-y base)))
                 (when (> y cursor) (push (cons (- y cursor) nil) parts) (setf cursor y))))
             (put (tall node) (push (cons tall node) parts) (incf cursor tall)))
      (when tray
        (to (+ base 36))
        (put (/ tray *rail--scale*)
             (ui :rect :height (rail--design tray) :width (rail--design 52)
                 :background (rail--c :tray))))
      (when voice
        (to (+ base 36 (/ (or tray 0) *rail--scale*)))
        (put 22 (rail--voice state)))
      (dolist (entry (rail--places state snapshot (+ base (floor height 2))))
        (to (cdr entry))
        (put (rail--height (car entry) state snapshot)
             (rail--block (car entry) state snapshot ground))))
    (ui :column :align :center :width (rail--design width) :height (rail--design height)
        :children (loop for (tall . node) in (nreverse parts)
                        collect (or node (ui :rect :height (rail--design tall)))))))


;;; The slab and the frames

(defun rail--seam-width ()
  "The open seam between the two cards' borders: both channels and the rail."
  (+ (* 2 (getf +rail+ :channel)) (getf +rail+ :width)))

(defun rail--shift (side)
  "How far the readings move off the seam's centre to ride the slab on SIDE."
  (let ((off (- (+ (getf +rail--cast+ :frame) (/ (getf +rail--cast+ :slab) 2) -1)
                (/ (getf +layout+ :seam) 2))))
    (if (eq side :right) (- off) off)))

(defun rail--material (key)
  "KEY of the cast material in the current mode."
  (getf (getf +rail--cast+ *rail--mode*) key))

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
  "Note a change of the focused card's SIDE in STATE: a switch across the seam,
siphoning after a pause and pouring on the heels of the last one, from the card
that held focus before."
  (let ((was (getf state :rail-side)))
    (when (and side was (not (eql side was)))
      (let* ((last (getf state :rail-crossed))
             (pour (and last (< (- now last) (getf +rail--tide+ :gap)))))
        (setf (getf state :rail-switch)
              (list :at now :from was :flow (if pour :pour :siphon) :old (getf state :rail-focus))
              (getf state :rail-crossed) now)))
    (setf (getf state :rail-side) side
          (getf state :rail-focus) id)))

(defun rail--motion (switch side epoch)
  "The switch as the shader reads it: side, previous side, start, flow, hold, gulp."
  (let* ((cut (not (eq (getf +rail+ :throw) :slide)))
         (flow (and switch (not cut) (getf switch :flow)))
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
                                     (min 64 (length (getf state :bolo-history))))
                     nil))
         (since (and voicing (getf state :bolo-since)))
         (fade (and voicing (getf state :bolo-fade)))
         (v +rail--voice+))
    (append (list (if (realp since) (- since epoch) -1d9)
                  (if (realp fade) (- fade epoch) -1d9)
                  (if (and voicing (cassette--bolo-turn-p (getf state :bolo-state))) 1 0)
                  (getf v :rest) (getf v :level) (getf v :swell) (getf v :wave) (getf v :hz)
                  (getf v :bob) (getf v :bob-hz) (getf v :rise) (getf v :settle) (getf v :fade)
                  (length levels) 0)
            levels)))

(defun rail--tide-data (origin skip seam output motion focus old voice)
  "Every number morph.glsl reads, in the order it reads them. ORIGIN is the
surface's corner and SKIP the span of x it leaves to the other surface, both in
output pixels; FOCUS and OLD index the surface's :WINDOWS."
  (let* ((cast +rail--cast+)
         (tide +rail--tide+)
         (lead (getf tide :lead)) (trail (getf tide :trail)) (ring (getf tide :ring))
         (pour (getf tide :pour)) (siphon (getf tide :siphon))
         (dock (eq (getf +rail+ :key-motion) :dock)))
    (append origin skip
            (rail--rgb (rail--material :material)) (rail--rgb (rail--material :line))
            (rail--rgb (rail--material :shadow)) (rail--rgb (rail--material :shine))
            (list (rail--material :gloss) (rail--material :shade)
                  (getf cast :radius) (getf cast :frame) (getf cast :line-width)
                  (getf cast :slab) (getf cast :inset) (getf cast :end) (getf cast :weld)
                  (rail--edge seam) (getf +layout+ :seam))
            motion
            (list (or focus -1) (or old -1)
                  (if dock 1 0) (getf seam :y) (+ (getf seam :y) (getf seam :height))
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
            voice)))

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
  "Each carried window as (:ID :SIDE :BOX), nearest each column's front first."
  (loop for side in '(:left :right)
        for ids = (getf columns side)
        append (loop for id in (subseq ids 0 (min (length ids) (getf +rail+ :carry-max)))
                     for box = (find id layout :key (lambda (entry) (getf entry :id)))
                     when box collect (list :id id :side side :box box))))

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

(defun rail--fullscreen-p (snapshot output)
  (loop for entry in (context snapshot :layout)
        thereis (and (getf entry :visible) (getf entry :fullscreen)
                     (<= (getf entry :x) (getf output :x) (+ (getf entry :x) (getf entry :width) -1))
                     (<= (getf entry :y) (getf output :y) (+ (getf entry :y) (getf entry :height) -1)))))

(defun rail--plates (items output focal snapshot)
  "On a narrow output, where there is no seam to stand in, the modules hang as
two plates across the top and bottom of the focal frame."
  (let ((split (or (cassette--split) (length items)))
        (layer (if (rail--fullscreen-p snapshot output) :bottom :top)))
    (loop for edge in '(:top :bottom)
          for plate = (cassette--plate (if (eq edge :top) (subseq items 0 split) (nthcdr split items))
                                       :both edge)
          for height = (cassette--height edge)
          when plate
            collect (apply #'shell-surface (intern (format nil "~A-~A" edge (getf output :name)) :keyword) plate
                           :output (getf output :name) :layer layer
                           :background "#00000000" :blur t :click-through t
                           (if focal
                               (list :anchors '(:top)
                                     :margin (list (- (+ (getf focal :top) (if (eq edge :top) 0 (getf focal :height)))
                                                      (round height 2))
                                                   0 0 0))
                               (list :anchors (list edge) :margin (if (eq edge :top) '(-1 0 0 0) '(0 0 -1 0))
                                     :exclusive-zone (1- height)))))))

(defun rail--surface-margin (output x y)
  (list (rail--design (- y (getf output :y))) 0 0 (rail--design (- x (getf output :x)))))

(defun rail--narrow (snapshot state)
  (let* ((outputs (remove-if-not (lambda (o) (deck--narrow-p (list :output o)))
                                 (context snapshot :outputs)))
         (focal (state-value snapshot :focal-frame))
         (modules (loop for module in (getf +rail+ :modules)
                        for node = (when (rail--height module state snapshot)
                                     (cassette--module module state snapshot))
                        when node collect node)))
    (loop for output in outputs
          append (rail--plates modules output
                               (and (equal (getf focal :output) (getf output :name)) focal)
                               snapshot))))

;;; The rail

(define-extension "bar" (:reads (:system :services :data :outputs :layout :focus)
                         :state (list :cpu nil :memory nil :gpu nil
                                      :bolo-state nil :bolo-level 0
                                      :bolo-since nil :bolo-history nil :bolo-fade nil
                                      :rail-side nil :rail-focus nil
                                      :rail-switch nil :rail-crossed nil
                                      :rail-meter nil :rail-step nil :rail-glide nil))
    (snapshot state event)
  (when (eq (getf event :type) :watch)
    (cassette--bolo-watch state event))
  (when (and (eq (getf event :type) :timer) (eq (getf event :name) :sample))
    (let ((system (context snapshot :system)))
      (dolist (probe '(:cpu :memory :gpu))
        (setf (getf state probe) (probe--sample probe (getf state probe) system)))))
  (let* ((*cassette-mode* (state-value snapshot :theme-mode :dark))
         (*rail--mode* *cassette-mode*)
         (*rail--palette* (state-value snapshot :hud-palette))
         (seam (state-value snapshot :deck-seam))
         (output (and seam (find (getf seam :output) (context snapshot :outputs)
                                 :key (lambda (o) (getf o :name)) :test #'equal)))
         (*rail--scale* (or (and output (max 1/4 (/ (getf output :scale-120 120) 120))) 1))
         (width (rail--seam-width))
         (height (if seam (getf seam :height) 0))
         (columns (and seam (state-value snapshot :deck-columns)))
         (carried (and columns (rail--carried columns (context snapshot :layout))))
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
    ;; The readings move toward the last sample before anything draws them.
    (rail--glide state now)
    (rail--switch state side (getf key :id) now)
    (unless (or voice settling)
      (setf (getf state :bolo-history) nil
            (getf state :bolo-fade) nil))
    (let* ((switch (getf state :rail-switch))
           (switching (and switch (< (- now (getf switch :at)) (getf +rail--tide+ :settle))))
           (old (and switching (getf switch :old)))
           (shown (and output (rail--shown carried output)))
           (windows (let ((ids (remove-duplicates (remove nil (list* (getf key :id) old shown))
                                                  :from-end t)))
                      (subseq ids 0 (min 8 (length ids)))))
           (focus-index (and key (position (getf key :id) windows)))
           (old-index (and old (position old windows)))
           (motion (rail--motion switch side epoch))
           (moved (if switch (max 0d0 (+ (- (getf switch :at) epoch) (getf +rail--tide+ :settle))) 0d0))
           (calmed (cond (voice 1d6)
                         ((realp fade) (max 0d0 (+ (- fade epoch) (getf +rail--voice+ :settle))))
                         (t 0d0)))
           (pad 60)
           (band-x (and seam (- (rail--edge seam) pad)))
           (band-width (+ (getf +layout+ :seam) (* 2 pad))))
      (values state
              (append (list (interval :sample (getf +rail+ :sample))
                            (publish-state :hud-hot (and hot t)))
                      ;; The slab, the frames and the voice animate on the GPU from
                      ;; the times the rail hands them; only the gauges need the
                      ;; rail itself to step, on its one timer, and only when a
                      ;; drawn number is due to change.
                      (let ((due (getf state :rail-glide)))
                        (when due
                          (list (interval :hop (max (getf +rail--glide+ :tick)
                                                    (ceiling (* 1000 due)))))))
                      (cassette--bolo-watches)
                      (when (and output tray)
                        (list (publish-state :shelf-tray-rect
                                             (list :output (getf seam :output)
                                                   :x (+ (rail--lane seam :left) (getf +rail+ :channel))
                                                   :y (getf seam :y)
                                                   :width (getf +rail+ :width)
                                                   :height tray))))
                      (when output
                        (let ((top (getf output :y)) (left (getf output :x)))
                          (list (shell-surface
                                 :rail-frames (ui :stack)
                                 :output (getf output :name) :anchors '(:top :left)
                                 :width (rail--design (getf output :width))
                                 :height (rail--design (getf output :height))
                                 :layer layer :click-through t
                                 :background (list :shader (getf +rail+ :shader)
                                                   :data (rail--tide-data
                                                          (list left top)
                                                          (list band-x (+ band-x band-width))
                                                          seam output motion focus-index old-index
                                                          (rail--voice-data state nil epoch))
                                                   :windows windows :clock epoch :until moved
                                                   ;; only the rings round the cards are
                                                   ;; ever drawn or repainted
                                                   :reach (rail--design 40)))
                                (shell-surface
                                 :rail-slab (ui :stack)
                                 :output (getf output :name) :anchors '(:top :left)
                                 :width (rail--design band-width)
                                 :height (rail--design (getf output :height))
                                 :margin (rail--surface-margin output band-x top)
                                 :layer layer :click-through t
                                 :background (list :shader (getf +rail+ :shader)
                                                   :data (rail--tide-data
                                                          (list band-x top) (list 0 0)
                                                          seam output motion focus-index old-index
                                                          (rail--voice-data state voicing epoch))
                                                   :windows windows :clock epoch
                                                   :until (max moved calmed)))
                                (shell-surface :rail-type (rail--web state snapshot seam
                                                                     (rail--material :material))
                                               :output (getf output :name) :anchors '(:top :left)
                                               :width (rail--design width)
                                               :height (rail--design height)
                                               :margin (rail--surface-margin
                                                        output (+ (rail--lane seam :left)
                                                                  (if side (rail--shift side) 0))
                                                        (getf seam :y))
                                               :layer layer :background "#00000000"
                                               :click-through t :slide t))))
                      (unless (getf +rail+ :focus-border)
                        (loop for entry in carried
                              collect (window-properties
                                       (getf entry :id)
                                       :radius (rail--design (getf +rail--cast+ :radius))
                                       :border (list :focused "#00000000"
                                                     :unfocused "#00000000"))))
                      (rail--narrow snapshot state))
              nil))))
