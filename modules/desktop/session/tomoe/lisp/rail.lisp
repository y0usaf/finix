(in-package #:tomoe-user)

;;; MERIDIAN
;;;
;;; The seam between the deck's two columns is not a bar and no longer a track:
;;; it is one solid slab in the mode's own tone -- the paper dropped a step in
;;; the dark and lifted a step in the light -- with the readings knocked out of
;;; it in ink. The slab stands flush against the focused card and follows that
;;; card's frame, which is drawn in the same tone, so slab, readings and frame
;;; read as one cast piece; the far card keeps a dim hairline and the slab
;;; stands off it, leaving the wallpaper visible in between.
;;;
;;; Its ends are liquid: where the slab meets the focused card's frame the two
;;; straight edges are welded by the meniscus their union makes -- the curve
;;; B(A) = (SQRT K - SQRT A)^2, where A is the height above the slab's end and K
;;; is how far the weld reaches up the frame -- so the slab appears to be poured
;;; against the card rather than butted to it. While bolo has the turn the free
;;; edge is a level history: a sine ripple whose amplitude follows a sliding
;;; window of the last sixty-four samples, newest at the top.
;;;
;;; When focus crosses the rail the slab hops: its leading edge leaps to the new
;;; card's frame on a stiff spring, its trailing edge lets go 25ms later on a
;;; looser one, so the slab stretches across both frames, the welds stretch with
;;; it and break as it leaves, and it snaps back to width and settles. The new
;;; frame flashes toward the ink as the slab lands on it, and the readings ride
;;; the slab's middle.
;;;
;;; A spring can only move a surface, so the hop is recomputed once per display
;;; refresh while it runs, and the ripple at 60 Hz while bolo's turn moves it --
;;; a 4 Hz wave needs no more, and a repaint of the whole slab costs a few
;;; milliseconds. At rest the slab's tree is the same tree every sample and the
;;; compositor reuses it: nothing ticks.

(defvar *rail--palette* nil)
(defvar *rail--mode* :dark)
(defvar *rail--scale* 1)

(defparameter +rail--clock-inset+ 27)
(defparameter +rail--clock-height+ 62)
(defparameter +rail--air+ 32)
(defparameter +rail--wave-rows+ 20)

(defparameter +rail--slab+ 50)          ; how much of the seam the slab fills
(defparameter +rail--inset+ 32)         ; the slab stops this far short of the ends
(defparameter +rail--radius+ 10)        ; the slab's own ends
(defparameter +rail--weld+ 26)          ; how far the meniscus reaches up a frame
(defparameter +rail--weld-far+ 13)      ; the same, for the card it is leaving
(defparameter +rail--squash+ 0.9)       ; a stretched slab gives some of it back
(defparameter +rail--hop-ms+ 0.22)      ; one hop, start to settled
(defparameter +rail--hop-delay+ 0.025)  ; the trailing edge lets go this much later
(defparameter +rail--hop-lead+ '(:stiffness 6084 :damping-ratio 0.72 :launch 60))
(defparameter +rail--hop-trail+ '(:stiffness 7396 :damping-ratio 0.42 :launch 0))
(defparameter +rail--ripple-top+ 60)    ; where the free edge starts to move
(defparameter +rail--ripple-height+ 410) ; and how far down it goes
(defparameter +rail--ripple-step+ 4)  ; how finely the silhouette follows it
(defparameter +rail--ripple-wave+ 0.075) ; radians per pixel down the slab
(defparameter +rail--ripple-hz+ 26)     ; how fast the wave travels
(defparameter +rail--shadow+ 10)        ; the contact shadow's reach, in pixels
(defparameter +rail--shadow-alpha+ (list 0.55d0 0.26d0)) ; dark, light
(defparameter +rail--corner-steps+ 7)   ; points across a rounded end

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

(defun rail--paper () (hud--c *rail--palette* :bg))

(defun rail--slab ()
  "The slab's tone: the paper a step further from the ink, which is down in the
dark and up in the light. It is the mode's own cast piece, not its opposite."
  (if (eq *rail--mode* :dark)
      (hud--mix (rail--paper) "#000000" 0.62)
      (hud--mix (rail--paper) "#FFFFFF" 0.70)))

(defun rail--slab-fill ()
  "The slab's own light: a hair lighter at the top than at the bottom, the way a
cast face catches a room's light, as one two-stop gradient."
  (let ((slab (rail--slab)))
    (if (eq *rail--mode* :dark)
        (list :linear 90 (list 0 (hud--mix slab "#FFFFFF" 0.035))
              (list 1 (hud--mix slab "#000000" 0.035)))
        (list :linear 90 (list 0 (hud--mix slab "#FFFFFF" 0.06))
              (list 1 (hud--mix slab "#000000" 0.03))))))

(defun rail--slab-shadow ()
  "The shadow the slab casts on whatever is beside it: black over the wallpaper
in the dark, ink over it in the light."
  (hud--fade (if (eq *rail--mode* :dark) "#000000" (rail--c :ink))
             (if (eq *rail--mode* :dark) (first +rail--shadow-alpha+)
                 (second +rail--shadow-alpha+))))

(defun rail--knock () (rail--c :ink))

(defun rail--dead ()
  "An unfocused card's hairline: the paper with a little ink in it."
  (hud--mix (rail--paper) (rail--c :ink) 0.30))

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

(defun rail--voice-row (level)
  (let ((level (max 0 (min 1 (or level 0)))))
    (if (> level 0.02)
        (ui :rect :width (rail--design (max 2 (* 2 (round (* 18 (sqrt level))))))
            :height (rail--design 2) :radius (rail--design 1) :background (rail--value))
        (ui :column :align :center :padding '(1 0 0 0)
            :children (list (ui :rect :width (rail--design 2) :height (rail--design 1)
                                :radius (rail--design 1) :background (rail--label)))))))

(defun rail--voice (state)
  "Bolo's turn at the top of the web: the elapsed time and its own level
scrolling down as a waveform."
  (let ((since (getf state :bolo-since)))
    (ui :column :align :center
        :children
        (list (rail--text (cassette--bolo-clock
                           (and (realp since) (- (cassette--bolo-now) since)))
                          (rail--value) 22)
              (ui :rect :height (rail--design 4))
              (ui :column :align :center :gap (rail--design 3)
                  :children (loop for rest = (getf state :bolo-history) then (cdr rest)
                                  repeat +rail--wave-rows+
                                  collect (rail--voice-row (first rest))))))))

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
  (let ((cpu (getf state :cpu)) (memory (getf state :memory)) (gpu (getf state :gpu)))
    (ecase module
      (:time (rail--clock))
      (:date (rail--date))
      (:media (rail--media snapshot))
      (:cpu (rail--gauge "CPU" (getf cpu :percent) (cassette--degrees (getf cpu :temp))
                         (cassette--hot-p (getf cpu :temp)) ground))
      (:memory (rail--gauge "MEM" (getf memory :percent) (rail--digits (getf memory :used))
                            nil ground))
      (:gpu (rail--gauge "GPU" (getf gpu :percent) (cassette--degrees (getf gpu :temp))
                         (cassette--hot-p (getf gpu :temp)) ground))
      (:vram (rail--gauge "VRAM" (if (plusp (or (getf gpu :total) 0))
                                     (round (* 100 (or (getf gpu :used) 0)) (getf gpu :total))
                                     0)
                          (rail--digits (getf gpu :used)) nil ground))
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
        (put 123 (rail--voice state)))
      (dolist (entry (rail--places state snapshot (+ base (floor height 2))))
        (to (cdr entry))
        (put (rail--height (car entry) state snapshot)
             (rail--block (car entry) state snapshot ground))))
    (ui :column :align :center :width (rail--design width) :height (rail--design height)
        :children (loop for (tall . node) in (nreverse parts)
                        collect (or node (ui :rect :height (rail--design tall)))))))



;;; The slab

(defun rail--seam-width ()
  "The open seam between the two cards' borders: both channels and the rail."
  (+ (* 2 (getf +rail+ :channel)) (getf +rail+ :width)))

(defun rail--slab-edges (width side)
  "Where the slab starts and ends, in the seam's own pixels, for SIDE's card."
  (if (eq side :left)
      (cons 0 +rail--slab+)
      (cons (- width +rail--slab+) width)))

(defun rail--slab-shift (width edges)
  "How far the readings move off the seam's centre to ride the slab."
  (- (/ (+ (car edges) (cdr edges)) 2) (floor width 2)))

(defun rail--smoothstep (fraction)
  (let ((x (max 0d0 (min 1d0 fraction))))
    (* x x (- 3 (* 2 x)))))

(defun rail--hop-edges (from to elapsed)
  "The slab's two edges ELAPSED seconds into a hop from FROM's to TO's. The edge
in the direction of travel leads on a stiff spring; the other lets go 25ms later
on a looser one, so the slab bridges both frames and then snaps to width."
  (let* ((l0 (car from)) (r0 (cdr from)) (l1 (car to)) (r1 (cdr to))
         (lead (spring +rail--hop-lead+ elapsed))
         (trail (spring +rail--hop-trail+ (- elapsed +rail--hop-delay+))))
    (if (>= (+ l1 r1) (+ l0 r0))
        (cons (+ l0 (* trail (- l1 l0))) (+ r0 (* lead (- r1 r0))))
        (cons (+ l0 (* lead (- l1 l0))) (+ r0 (* trail (- r1 r0)))))))

(defun rail--hop-impact (elapsed)
  "The new frame's overshoot: zero, a stroke and a half at 45ms, then gone."
  (if (<= elapsed 0d0)
      0d0
      (* (expt 2.718281828459045 (/ (- (max (- elapsed 0.045d0) 0d0)) 0.07d0))
         (rail--smoothstep (/ elapsed 0.045d0)))))

(defun rail--weld (gap k)
  "How far the weld reaches up the frame while the slab's edge stands GAP from
it: full against the frame, gone once the edge has let go by two pixels."
  (if (< gap 2) (* k (- 1 (/ gap 2))) 0))

(defun rail--ripple (y now levels)
  "The free edge's offset at Y: a sine wave travelling down the slab, its
amplitude following the level history newest at the top."
  (let ((rows (length levels)))
    (if (or (zerop rows)
            (< y +rail--ripple-top+)
            (> y (+ +rail--ripple-top+ +rail--ripple-height+)))
        0
        (let* ((band (/ +rail--ripple-height+ rows))
               (key (/ (- y +rail--ripple-top+) band))
               (index (min (1- rows) (max 0 (floor key))))
               (next (min (1- rows) (1+ index)))
               (fraction (- key (floor key)))
               (here (or (nth index levels) 0))
               (there (or (nth next levels) 0))
               (level (+ here (* fraction (- there here))))
               (envelope (* (rail--smoothstep (/ (- y +rail--ripple-top+) 30d0))
                            (rail--smoothstep (/ (- (+ +rail--ripple-top+ +rail--ripple-height+) y)
                                                 60d0)))))
          (* (+ 2.5d0 (* 7d0 level))
             (sin (- (* y +rail--ripple-wave+) (* now +rail--ripple-hz+)))
             envelope)))))

(defun rail--edge-rows (top bottom radius)
  "The rows of a free edge: whole, but dense where the voice ripples it."
  (let* ((low (+ top radius))
         (high (- bottom radius))
         (first-row (max low +rail--ripple-top+))
         (last-row (min high (+ +rail--ripple-top+ +rail--ripple-height+))))
    (remove-duplicates
     (append
      (list low)
      (when (> first-row low) (list (- first-row 1)))
      (loop for y from first-row to last-row by +rail--ripple-step+ collect y)
      (when (< last-row high) (list (1+ last-row)))
      (list high))
     :test #'equal :from-end t)))

(defun rail--weld-profile (k)
  "Where a weld's boundary stands X out from the card's frame, and how far above
the slab's end it is: B(A) = (SQRT K - SQRT B)^2, the union of a straight frame
and a straight edge, from the apex on the frame to the slab's own end."
  (let ((root (sqrt k)) (steps (max 1 (round k))))
    (loop for step from 0 to steps
          for x = (* k (/ step steps))
          collect (cons x (expt (- root (sqrt x)) 2)))))

(defun rail--slab-points (width edges top bottom welds ripple now levels)
  "The slab's silhouette as x/y pairs: flush against the fused card's frame with
the weld that joins them, the free edge rippling with the voice, its two ends
rounded. WELDS is how far each side's weld reaches, 0 for a side that let go."
  (let* ((xl (car edges))
         (xr (cdr edges))
         (kleft (car welds))
         (kright (cdr welds))
         (radius (min +rail--radius+ (max 0 (floor (- xr xl) 2))))
         (quarter (* 0.5 1.5707963267948966))
         (rows (rail--edge-rows top bottom radius))
         (ripples (and ripple now levels (plusp (length levels))))
         (points nil))
    (labels ((add (x y)
               (push (list (coerce x 'double-float) (coerce y 'double-float)) points))
             (free-right (y) (+ xr (if ripples (rail--ripple y now levels) 0)))
             (free-left (y) (- xl (if ripples (rail--ripple y now levels) 0))))
      ;; the left end of the top edge
      (if (> kleft 0.5)
          (dolist (step (rail--weld-profile kleft)) (add (car step) (- top (cdr step))))
          (progn
            (add xl (+ top radius))
            (loop for step from 0 to +rail--corner-steps+
                  for angle = (* quarter (/ step +rail--corner-steps+))
                  do (add (- (+ xl radius) (* radius (cos angle)))
                          (- (+ top radius) (* radius (sin angle)))))))
      ;; the right end of the top edge
      (if (> kright 0.5)
          (dolist (step (reverse (rail--weld-profile kright)))
            (add (- width (car step)) (- top (cdr step))))
          (loop for step from 0 to +rail--corner-steps+
                for angle = (* quarter (/ step +rail--corner-steps+))
                do (add (+ (- xr radius) (* radius (sin angle)))
                        (- (+ top radius) (* radius (cos angle))))))
      ;; the right side
      (unless (> kright 0.5)
        (dolist (y rows) (add (free-right y) y)))
      ;; the right end of the bottom edge
      (if (> kright 0.5)
          (dolist (step (rail--weld-profile kright))
            (add (- width (car step)) (+ bottom (cdr step))))
          (loop for step from 0 to +rail--corner-steps+
                for angle = (* quarter (/ step +rail--corner-steps+))
                do (add (+ (- xr radius) (* radius (cos angle)))
                        (+ (- bottom radius) (* radius (sin angle))))))
      ;; the left end of the bottom edge
      (if (> kleft 0.5)
          (dolist (step (reverse (rail--weld-profile kleft)))
            (add (car step) (+ bottom (cdr step))))
          (loop for step from 0 to +rail--corner-steps+
                for angle = (* quarter (/ step +rail--corner-steps+))
                do (add (- (+ xl radius) (* radius (sin angle)))
                        (+ (- bottom radius) (* radius (cos angle))))))
      ;; the left side
      (unless (> kleft 0.5)
        (dolist (y (reverse rows)) (add (free-left y) y)))
      (let ((kept nil) (last-x nil) (last-y nil))
        (dolist (point (nreverse points))
          (unless (and last-x (< (abs (- (car point) last-x)) 0.05)
                       (< (abs (- (car (cdr point)) last-y)) 0.05))
            (push point kept)
            (setf last-x (car point)
                  last-y (car (cdr point)))))
        (loop for point in (nreverse kept) append point)))))

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

(defun rail--slab-node (width height edges top bottom welds ripple now levels)
  "One shape: the whole slab, welded to the fused card's frame, with its own
light and the shadow it casts on what is beside it."
  (ui :shape :width (rail--design width) :height (rail--design height)
      :points (rail--slab-points width edges top bottom welds ripple now levels)
      :background (rail--slab-fill)
      :shadow (list (list 0 0 (rail--design +rail--shadow+) 0 (rail--slab-shadow)))))

(define-extension "bar" (:reads (:system :services :data :outputs :layout :focus)
                         :state (list :cpu nil :memory nil :gpu nil
                                      :bolo-state nil :bolo-level 0
                                      :bolo-since nil :bolo-history nil
                                      :rail-side nil :rail-edges nil :rail-hop nil
                                      :rail-focus nil :rail-box nil))
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
         (box (and key (getf key :box)))
         (layer (if (rail--covered-p snapshot seam) :bottom :top))
         (tray (rail--tray snapshot))
         (now (hud--now))
         (hop (getf state :rail-hop))
         (painted (getf state :rail-edges))
         (rest (and side (rail--slab-edges width side)))
         (voice (cassette--bolo-turn-p (getf state :bolo-state)))
         (levels (getf state :bolo-history))
         (edges rest)
         (impact 0d0)
         (fresh 1d0))
    ;; A slab whose side changes hops; one that stays put rides its card, which
    ;; the surface's own attachment carries.
    (when (not (eql side (getf state :rail-side)))
      (setf hop (when (and (or painted rest) (eq (getf +rail+ :throw) :slide))
                  (list :at now :from (or painted rest) :to (or rest painted)
                        :from-side (getf state :rail-side) :to-side side
                        :box (or box (getf state :rail-box))
                        :focus (getf state :rail-focus)))))
    (when hop
      (let ((elapsed (- now (getf hop :at))))
        (if (>= elapsed +rail--hop-ms+)
            (setf hop nil)
            (let ((to (or rest (getf hop :to))))
              (setf edges (rail--hop-edges (getf hop :from) to elapsed)
                    impact (rail--hop-impact elapsed)
                    fresh (rail--smoothstep (/ elapsed 0.05d0)))))))
    (unless hop
      (setf edges (or rest painted)))
    (let* ((live (and edges box))
           (dock (eq (getf +rail+ :key-motion) :dock))
           (live-height (if dock height (if live (getf live :height) 0)))
           (live-y (if dock (if seam (getf seam :y) 0) (if live (getf live :y) 0)))
           (squash (if edges (* (max 0 (- (cdr edges) (car edges) +rail--slab+))
                                +rail--squash+)
                       0))
           (top (if live (+ +rail--inset+ squash) 0))
           (bottom (if live (- live-height +rail--inset+ squash) 0))
           (welds (and edges
                       (cons (rail--weld (car edges)
                                         (if (eql side :left) +rail--weld+ +rail--weld-far+))
                             (rail--weld (- width (cdr edges))
                                         (if (eql side :right) +rail--weld+ +rail--weld-far+)))))
           (shift (if edges (rail--slab-shift width edges) 0))
           (hot (loop for probe in '(:cpu :gpu)
                      thereis (cassette--hot-p (getf (getf state probe) :temp)))))
      (setf (getf state :rail-side) side
            (getf state :rail-edges) edges
            (getf state :rail-hop) hop
            (getf state :rail-focus) (getf key :id)
            (getf state :rail-box) (or box (getf state :rail-box)))
      (values state
              (append (list (interval :sample (getf +rail+ :sample))
                            (publish-state :hud-hot (and hot t)))
                      (when hop (list (interval :hop :refresh)))
                      (when (and voice (plusp (length levels)))
                        (list (interval :hop 16)))
                      (cassette--bolo-watches)
                      (when (and output tray)
                        (list (publish-state :shelf-tray-rect
                                             (list :output (getf seam :output)
                                                   :x (+ (rail--lane seam :left) (getf +rail+ :channel))
                                                   :y (getf seam :y)
                                                   :width (getf +rail+ :width)
                                                   :height tray))))
                      (when (and output live (plusp live-height) welds)
                        (list (shell-surface :rail-slab
                                             (ui :stack :width (rail--design width)
                                                 :height (rail--design live-height)
                                                 :children
                                                 (list (rail--slab-node width live-height edges
                                                                        top bottom welds
                                                                        voice now levels)))
                                             :output (getf output :name) :anchors '(:top :left)
                                             :width (rail--design width)
                                             :height (rail--design live-height)
                                             :margin (rail--surface-margin
                                                      output (rail--lane seam :left) live-y)
                                             :layer layer :background "#00000000"
                                             :click-through t
                                             :attach (and (not dock) (getf key :id))
                                             :attach-axes '(:y))))
                      (when output
                        (list (shell-surface :rail-type (rail--web state snapshot seam (rail--slab))
                                             :output (getf output :name) :anchors '(:top :left)
                                             :width (rail--design width)
                                             :height (rail--design height)
                                             :margin (rail--surface-margin
                                                      output (+ (rail--lane seam :left) shift)
                                                      (getf seam :y))
                                             :layer layer :background "#00000000"
                                             :click-through t)))
                      (unless (getf +rail+ :focus-border)
                        (loop for entry in carried
                              for id = (getf entry :id)
                              for mine = (eql id (getf key :id))
                              for old = (eql id (getf hop :focus))
                              collect (window-properties
                                       id
                                       :border (list :focused (hud--mix (rail--dead)
                                                                        (rail--knock)
                                                                        (max fresh impact))
                                                     :unfocused (if (and old hop)
                                                                    (hud--mix (rail--dead)
                                                                              (rail--knock)
                                                                              (- 1d0 fresh))
                                                                    (rail--dead))))))
                      (rail--narrow snapshot state))
              nil))))
