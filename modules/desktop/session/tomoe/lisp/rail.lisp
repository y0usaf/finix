(in-package #:tomoe-user)

;;; LAMP
;;;
;;; The seam between the deck's two columns is not a bar but a track: one step
;;; darker than the paper, carrying nothing but light. The focused card's rail
;;; edge is a filament, and its light falls across the track, easing out toward
;;; the far card and fading toward the card's ends. Nothing else on the desktop
;;; marks focus, and there is no accent: the light is the theme's own ink lifted
;;; toward white in the dark and white itself in the light, so both modes read
;;; the same way.
;;;
;;; When focus leaves a card for one across the rail, the light neither jumps
;;; nor slides. The light that was on the old card converges on the rail's
;;; midpoint and dies there while, on the same clock, the new light blooms out
;;; of that midpoint on the other side. The filament crosses with it, so a lit
;;; edge is on the track in every frame of the crossing.
;;;
;;; The track, the light, the carriages' stubs and the readings' type are four
;;; kinds of shell surface. The light and the stubs are attached to their
;;; window, so the compositor adds that window's in-flight move offset to them
;;; every frame and they cannot drift from the card.
;;;
;;; A crossing is the one thing a spring cannot carry: a light that dies has to
;;; change its own alpha, and a surface's spring only moves it. So while a
;;; crossing runs the light is recomputed once per display refresh -- and only
;;; then. Nothing ticks at rest, and the light's tree at rest is the same tree
;;; every sample, which the compositor reuses instead of redrawing.

(defvar *rail--palette* nil)
(defvar *rail--mode* :dark)
(defvar *rail--scale* 1)

(defparameter +rail--clock-inset+ 27)
(defparameter +rail--clock-height+ 62)
(defparameter +rail--air+ 32)
(defparameter +rail--wave-rows+ 20)
(defparameter +rail--stub+ 40)          ; stub length at a card's two ends
(defparameter +rail--filament-inset+ 24)
(defparameter +rail--cross-ms+ 150)     ; one crossing, start to settled
(defparameter +rail--reach+ 60)         ; how far the light falls each way
(defparameter +rail--fade+ 140)         ; how long it takes to die at a card's end
(defparameter +rail--cells+ 18)         ; four pixels each across the open seam
(defparameter +rail--bands+ 6)          ; fade bands at each of a card's two ends
(defparameter +rail--floor+ 0.004)      ; the alpha a cell must reach to be drawn
(defparameter +rail--gather+ 1.6)       ; how early a dying light reaches the midpoint

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

(defun rail--track ()
  "The track, one step below the paper it stands on. The light falls on it."
  (if (eq *rail--mode* :dark)
      (hud--mix (rail--paper) "#000000" 0.45)
      (hud--mix (rail--paper) (rail--c :ink) 0.11)))

(defun rail--light ()
  "What the light is made of: toward white in both modes."
  (if (eq *rail--mode* :dark) (hud--mix (rail--c :ink) "#FFFFFF" 0.2) "#FFFFFF"))

(defun rail--peak () (if (eq *rail--mode* :dark) 0.22d0 0.95d0))

(defun rail--filament () (if (eq *rail--mode* :dark) (rail--c :ink) "#FFFFFF"))

(defun rail--filament-alpha () (if (eq *rail--mode* :dark) 0.9 1))

(defun rail--stub () (hud--fade (rail--c :ink) 0.22))

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
         (width (rail--light-width))
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
        (to (+ base 36 (or (/ tray *rail--scale*) 0)))
        (put 123 (rail--voice state)))
      (dolist (entry (rail--places state snapshot (+ base (floor height 2))))
        (to (cdr entry))
        (put (rail--height (car entry) state snapshot)
             (rail--block (car entry) state snapshot ground))))
    (ui :column :align :center :width (rail--design width) :height (rail--design height)
        :children (loop for (tall . node) in (nreverse parts)
                        collect (or node (ui :rect :height (rail--design tall)))))))


;;; The light

(defun rail--light-width ()
  "The open seam between the two cards' borders: both channels and the rail."
  (+ (* 2 (getf +rail+ :channel)) (getf +rail+ :width)))

(defun rail--light-centre () (/ (1- (rail--light-width)) 2))

(defun rail--light-edge (side)
  "Where a CARD's edge meets the track: the left card's right edge, or the
right card's left edge, in the light surface's own pixels."
  (if (eq side :left) 0 (1- (rail--light-width))))

(defun rail--smoothstep (fraction)
  (let ((x (max 0d0 (min 1d0 fraction))))
    (* x x (- 3 (* 2 x)))))

(defun rail--curve (fraction)
  "A crossing's clock: quick off the mark, soft onto it, never past it."
  (let ((left (- 1d0 (max 0d0 (min 1d0 fraction)))))
    (- 1d0 (* left left left))))

(defun rail--lobe (x reach peak)
  (list :x (coerce x 'double-float) :reach (coerce reach 'double-float)
        :peak (coerce peak 'double-float)))

(defun rail--rest-lobe (side)
  (rail--lobe (rail--light-edge side) +rail--reach+ (rail--peak)))

(defun rail--falloff (lobe x row)
  "LOBE's alpha at X on a row whose own fade is ROW, zero outside its reach."
  (let ((reach (getf lobe :reach)) (peak (getf lobe :peak)))
    (if (or (null reach) (null peak) (<= reach 0d0) (<= peak 0d0))
        0d0
        (let ((near (max 0d0 (- 1d0 (/ (abs (- x (getf lobe :x))) reach)))))
          (* peak row (expt near 2.2d0))))))

(defun rail--light-cell (lobes x row)
  "The alpha of LOBES where they meet at X on a row of ROW: the composite of
stacking both, kept as one cell."
  (let ((clear 1d0))
    (dolist (lobe lobes)
      (let ((alpha (rail--falloff lobe x row)))
        (when (plusp alpha) (setf clear (* clear (- 1d0 (min 1d0 alpha)))))))
    (- 1d0 clear)))

(defun rail--light-rows (height fade)
  "The light's bands down a card of HEIGHT: a cut every FADE/BANDS at each end,
the body between them whole. HEIGHT and FADE are in the surface's own pixels."
  (let ((edge (min fade (floor height 2))))
    (if (< edge 2)
        (list (cons 0 height))
        (let* ((step (max 1 (round (/ edge +rail--bands+))))
               (cuts (append (loop for y from 0 to edge by step collect y)
                             (list (- height edge))
                             (loop for y from (+ (- height edge) step) below height by step
                                   collect y)
                             (list height))))
          (remove-duplicates
           (loop for (top next) on cuts while next when (< top next)
                 collect (cons top next))
           :test #'equal :from-end t)))))

(defun rail--light-row-fade (top bottom height fade)
  (let ((edge (min fade (floor height 2))))
    (if (< edge 1)
        1d0
        (let ((middle (/ (+ top bottom) 2)))
          (rail--smoothstep (/ (min middle (- height 1 middle)) edge))))))

(defun rail--light-band (top bottom height fade lobes)
  (let* ((cell (/ (rail--light-width) +rail--cells+))
         (row (rail--light-row-fade top bottom height fade))
         (paint (rail--light)))
    (ui :row :height (- bottom top) :align :start
        :children (loop for index below +rail--cells+
                        for x = (* cell (+ index 1/2))
                        for alpha = (rail--light-cell lobes x row)
                        collect (ui :rect :width (rail--design cell)
                                    :height (- bottom top)
                                    :background (when (> alpha +rail--floor+)
                                                  (hud--fade paint alpha)))))))

(defun rail--filament-node (height x rgb alpha)
  "The filament: a pixel of lifted ink at X, inset from the card's ends."
  (let ((inset (rail--design +rail--filament-inset+)))
    (ui :row :align :start
        :children
        (list (ui :rect :width (rail--design x))
              (ui :column :children
                  (list (ui :rect :height inset)
                        (ui :rect :width (rail--design 1)
                            :height (- height inset inset)
                            :background (hud--fade rgb alpha))
                        (ui :rect :height inset)))))))

(defun rail--light-tree (height lobes filament)
  "The light over a card of HEIGHT: LOBES' cells, the FILAMENT in front."
  (let ((fade (rail--design +rail--fade+)))
    (ui :stack :width (rail--design (rail--light-width)) :height height
        :children
        (append (list (ui :column :align :stretch
                          :children (loop for (top . bottom) in (rail--light-rows height fade)
                                          collect (rail--light-band top bottom height fade lobes))))
                (when filament
                  (list (rail--filament-node height (first filament) (second filament)
                                             (third filament))))))))

(defun rail--bloom (lobes to progress)
  "The light at PROGRESS across a crossing: LOBES converging on the midpoint and
dying there, and the wanted side's light blooming out of that same midpoint."
  (append
   (loop for lobe in lobes
         for u = (min 1d0 (* +rail--gather+ progress))
         collect (rail--lobe (+ (getf lobe :x) (* u (- (rail--light-centre) (getf lobe :x))))
                             (* (getf lobe :reach) (- 1d0 (* 0.4d0 progress)))
                             (* (getf lobe :peak) (- 1d0 progress))))
   (when (getf to :side)
     (let* ((edge (rail--light-edge (getf to :side)))
            (v (max 0d0 (min 1d0 (- (* +rail--gather+ progress) (1- +rail--gather+))))))
       (list (rail--lobe (+ (rail--light-centre) (* v (- edge (rail--light-centre))))
                         (* +rail--reach+ (+ (1- (/ 1d0 +rail--gather+))
                                             (* (/ 1d0 +rail--gather+) v)))
                         (* (rail--peak) progress)))))))


;;; The rail

(defun rail--track-body ()
  "The track: the whole open seam, one tone below the paper."
  (ui :column :align :stretch))

(defun rail--carriage (box side)
  "One card's two stubs, a pixel of ink at each end of where it meets the
track. The focused card is not given one: its edge is lit instead."
  (let ((height (getf box :height)))
    (ui :column :align (if (eq side :left) :start :end)
        :children (list (ui :rect :width (rail--design 1) :height (rail--design +rail--stub+)
                            :background (rail--stub))
                        (ui :rect :height (rail--design (- height (* 2 +rail--stub+))))
                        (ui :rect :width (rail--design 1) :height (rail--design +rail--stub+)
                            :background (rail--stub))))))

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

(define-extension "bar" (:reads (:system :services :data :outputs :layout :focus)
                         :state (list :cpu nil :memory nil :gpu nil
                                      :bolo-state nil :bolo-level 0
                                      :bolo-since nil :bolo-history nil
                                      :rail-light nil :rail-paint nil :rail-cross nil))
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
         (columns (and seam (state-value snapshot :deck-columns)))
         (carried (and columns (rail--carried columns (context snapshot :layout))))
         (focus (context snapshot :focus))
         (key (and focus (find focus carried :key (lambda (entry) (getf entry :id)))))
         (side (and key (getf key :side)))
         (box (and key (getf key :box)))
         (layer (if (rail--covered-p snapshot seam) :bottom :top))
         (tray (rail--tray snapshot))
         (now (hud--now))
         (painted (getf state :rail-paint))
         (wanted (and side (list :id focus :side side :box box)))
         (cross (getf state :rail-cross))
         (rest (and wanted (rail--rest-lobe side)))
         (lobes nil)
         (filament nil))
    ;; A light whose side changes crosses the rail; one that stays put rides its
    ;; card, which the surface's own attachment carries.
    (when (not (eql side (getf (getf state :rail-light) :side)))
      (setf cross (when (and (or painted wanted) (eq (getf +rail+ :throw) :slide))
                    (list :at now :lobes painted :to wanted
                          :box (or box (getf (getf state :rail-light) :box))
                          :from-x (if painted (getf (first painted) :x)
                                      (rail--light-centre))))))
    (when cross
      (let ((progress (rail--curve (/ (* 1000d0 (- now (getf cross :at)))
                                     +rail--cross-ms+))))
        (if (>= progress 1d0)
            (setf cross nil)
            (let ((edge (and (getf (getf cross :to) :side)
                             (rail--light-edge (getf (getf cross :to) :side)))))
              (setf lobes (rail--bloom (getf cross :lobes) (getf cross :to) progress)
                    filament (list (+ (getf cross :from-x)
                                      (* progress (- (or edge (rail--light-centre))
                                                     (getf cross :from-x))))
                                    (rail--filament)
                                    (if edge
                                        (rail--filament-alpha)
                                        (* (rail--filament-alpha) (- 1d0 progress)))))))))
    (unless cross
      (setf lobes (and rest (list rest))
            filament (when rest (list (rail--light-edge side) (rail--filament)
                                      (rail--filament-alpha)))))
    (let* ((live (and lobes (or (and box box) (getf cross :box))))
           (dock (eq (getf +rail+ :key-motion) :dock))
           (live-height (if dock (if seam (getf seam :height) 0)
                            (if live (getf live :height) 0)))
           (live-y (if dock (if seam (getf seam :y) 0) (if live (getf live :y) 0)))
           (stubs (remove (getf wanted :id) carried :key (lambda (entry) (getf entry :id))))
           (hot (loop for probe in '(:cpu :gpu)
                      thereis (cassette--hot-p (getf (getf state probe) :temp)))))
      (setf (getf state :rail-light) wanted
            (getf state :rail-paint) lobes
            (getf state :rail-cross) cross)
      (values state
              (append (list (interval :sample (getf +rail+ :sample))
                            (publish-state :hud-hot (and hot t)))
                      (when cross (list (interval :cross :refresh)))
                      (cassette--bolo-watches)
                      (when (and output tray)
                        (list (publish-state :shelf-tray-rect
                                             (list :output (getf seam :output)
                                                   :x (+ (rail--lane seam :left) (getf +rail+ :channel))
                                                   :y (getf seam :y)
                                                   :width (getf +rail+ :width)
                                                   :height tray))))
                      (when output
                        (list (shell-surface :rail-track (rail--track-body)
                                             :output (getf output :name) :anchors '(:top :left)
                                             :width (rail--design (rail--light-width))
                                             :height (rail--design (getf seam :height))
                                             :margin (rail--surface-margin output (rail--lane seam :left)
                                                                           (getf seam :y))
                                             :layer layer :background (rail--track)
                                             :click-through t)))
                      (when (and output live (plusp live-height))
                        (list (shell-surface :rail-light
                                             (rail--light-tree (rail--design live-height)
                                                               lobes filament)
                                             :output (getf output :name) :anchors '(:top :left)
                                             :width (rail--design (rail--light-width))
                                             :height (rail--design live-height)
                                             :margin (rail--surface-margin
                                                      output (rail--lane seam :left) live-y)
                                             :layer layer :background "#00000000"
                                             :click-through t
                                             :attach (and (not dock) (getf wanted :id))
                                             :attach-axes '(:y))))
                      (loop for entry in stubs
                            for id = (getf entry :id)
                            for stub = (getf entry :box)
                            append (list (shell-surface
                                          (intern (format nil "RAIL-CAR-~D" id) :keyword)
                                          (rail--carriage stub (getf entry :side))
                                          :output (getf output :name) :anchors '(:top :left)
                                          :width (rail--design (getf +rail+ :channel))
                                          :height (rail--design (getf stub :height))
                                          :margin (rail--surface-margin
                                                   output (rail--lane seam (getf entry :side))
                                                   (getf stub :y))
                                          :layer layer :background "#00000000"
                                          :click-through t :slide t
                                          :attach id :attach-axes '(:y))))
                      (when output
                        (list (shell-surface :rail-type (rail--web state snapshot seam (rail--track))
                                             :output (getf output :name) :anchors '(:top :left)
                                             :width (rail--design (rail--light-width))
                                             :height (rail--design (getf seam :height))
                                             :margin (rail--surface-margin output (rail--lane seam :left)
                                                                           (getf seam :y))
                                             :layer layer :background "#00000000"
                                             :click-through t)))
                      (unless (getf +rail+ :focus-border)
                        (loop for entry in carried
                              collect (window-properties (getf entry :id)
                                                         :border (list :focused (rail--c :rim)
                                                                       :unfocused (rail--c :rim)))))
                      (rail--narrow snapshot state))
              nil))))
