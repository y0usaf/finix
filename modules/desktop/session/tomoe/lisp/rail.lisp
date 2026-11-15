(in-package #:tomoe-user)

;;; KEYWAY
;;;
;;; The seam between the deck's two columns is a steel rail. Every carried card
;;; rides it on two guide shoes, and one accent key clamps the focused card to
;;; it: the key's lugs cover that card's shoes, a dog sits at the card's middle
;;; and a bar joins them. Nothing else on the desktop marks focus.
;;;
;;; The rail body, the carriages and the key are three kinds of shell surface.
;;; A carriage and the key are attached to their window, so the compositor adds
;;; the window's in-flight move offset to them every frame: they cannot drift
;;; from the card. Only the key's lane (x) ever slides, and it slides on the
;;; card's own window-move spring because it is the same animation.

(defvar *rail--palette* nil)
(defvar *rail--mode* :dark)
(defvar *rail--scale* 1)

(defparameter +rail--plate+ 2)    ; end plate
(defparameter +rail--way+ 2)      ; running surface down each long edge
(defparameter +rail--clock-y+ 696)
(defparameter +rail--air+ 22)
(defparameter +rail--wave-rows+ 20)

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

(defun rail--parts (text)
  (loop with start = 0
        for i = (position-if (lambda (c) (member c '(#\: #\Space))) text :start start)
        for part = (subseq text start i)
        when (plusp (length part)) collect part
        while i do (setf start (1+ i))))

(defun rail--text (text color size &optional (height size))
  (ui :text :text text :size (rail--design size) :line-height (rail--design size)
      :height (rail--design height) :color color :font (getf +cassette+ :font)))

(defun rail--bar (percent width)
  "A horizontal meter: WIDTH wide and 2 tall, filled to PERCENT."
  (let* ((percent (max 0 (min 100 (round (or percent 0)))))
         (lit (round (* width percent) 100))
         (color (cond ((> percent 84) (rail--c :red))
                      ((> percent 60) (rail--c :hot))
                      (t (rail--c :ink)))))
    (ui :stack :width (rail--design width) :height (rail--design 2) :background (rail--c :track)
        :children (list (ui :row :height (rail--design 2) :align :start
                            :children (list (ui :rect :width (rail--design lit)
                                                :height (rail--design 2)
                                                :background color)))))))

(defun rail--digits (mib)
  "Whole GiB from ten up, one decimal below, so a memory detail is four cells."
  (if (realp mib)
      (let ((gib (/ mib 1024d0)))
        (if (>= gib 10) (format nil "~DG" (round gib)) (format nil "~,1FG" gib)))
      "--G"))

(defun rail--gauge (label percent detail &optional hot)
  (let ((percent (max 0 (min 100 (round (or percent 0))))))
    (ui :column :align :center
        :children
        (append (list (rail--text label (rail--c :dim) 22)
                      (rail--text (format nil "~D%" percent) (rail--c :ink) 22)
                      (rail--bar percent 50))
                (when detail
                  (list (ui :rect :height (rail--design 8))
                        (rail--text detail (if hot (rail--c :hot) (rail--c :dim)) 22 14)))))))

(defun rail--date ()
  (destructuring-bind (&optional day date month &rest rest)
      (rail--parts (string-upcase (clock-text (getf +cassette+ :date))))
    (declare (ignore rest))
    (ui :column :align :center
        :children (remove nil
                          (list (when day (rail--text day (rail--c :dim) 22))
                                (when date (rail--text date (rail--c :ink) 22))
                                (when month (rail--text month (rail--c :dim) 22 14)))))))

(defun rail--clock ()
  (destructuring-bind (&optional hours minutes)
      (rail--parts (clock-text (getf +cassette+ :time)))
    (ui :column :align :center
        :children (list (rail--text (or hours "--") (rail--c :ink) 33 27)
                        (rail--text (or minutes "--") (rail--c :ink) 33 21)))))

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
        :children (list (rail--text (if (equal status "Playing") ">" "||") (rail--c :ink) 22)
                        (rail--bar (round (* 100 played)) 50)))))

(defun rail--network (snapshot)
  (let ((online (getf (service-state snapshot :network) :connected)))
    (ui :column :align :center
        :children (list (rail--text "NET" (rail--c :dim) 22)
                        (rail--text (if online "ON" "OFF") (rail--c :ink) 22)))))

(defun rail--voice-row (level)
  (let ((level (max 0 (min 1 (or level 0)))))
    (if (> level 0.02)
        (ui :rect :width (rail--design (max 1 (round (* 21 (sqrt level)))))
            :height (rail--design 3) :background (rail--c :teal))
        (ui :rect :width (rail--design 2) :height (rail--design 3)
            :background (rail--c :dim)))))

(defun rail--voice (state)
  "Bolo's turn at the top of the web: the elapsed time and its own level
scrolling down as a waveform, then the tie that closes the block."
  (let ((since (getf state :bolo-since)))
    (ui :column :align :center
        :children
        (append (list (rail--text (cassette--bolo-clock
                                   (and (realp since) (- (cassette--bolo-now) since)))
                                  (rail--c :ink) 22)
                      (ui :rect :height (rail--design 2))
                      (ui :column :align :center :gap (rail--design 2)
                          :children (loop for rest = (getf state :bolo-history) then (cdr rest)
                                          repeat +rail--wave-rows+
                                          collect (rail--voice-row (first rest))))
                      (ui :rect :height (rail--design 12)))
                (list (ui :rect :height (rail--design 1) :width (rail--design 52)
                          :background (rail--c :tie)))))))

(defun rail--height (module state snapshot)
  "The design height of MODULE's block, or NIL when it has nothing to show."
  (ecase module
    (:time 48)
    (:date 58)
    (:media (when (rail--media-played snapshot) 24))
    (:cpu 68)
    (:memory 68)
    (:gpu (when (probe--gpu-p (getf state :gpu)) 68))
    (:vram (when (probe--gpu-p (getf state :gpu)) 68))
    (:battery (when (getf (service-state snapshot :battery) :percent) 46))
    (:network 44)
    (:frame (when (getf (state-value snapshot :frame-battery) :percent) 46))))

(defun rail--block (module state snapshot)
  (let ((cpu (getf state :cpu)) (memory (getf state :memory)) (gpu (getf state :gpu)))
    (ecase module
      (:time (rail--clock))
      (:date (rail--date))
      (:media (rail--media snapshot))
      (:cpu (rail--gauge "CPU" (getf cpu :percent) (cassette--degrees (getf cpu :temp))
                         (cassette--hot-p (getf cpu :temp))))
      (:memory (rail--gauge "MEM" (getf memory :percent) (rail--digits (getf memory :used))))
      (:gpu (rail--gauge "GPU" (getf gpu :percent) (cassette--degrees (getf gpu :temp))
                         (cassette--hot-p (getf gpu :temp))))
      (:vram (rail--gauge "VRAM" (if (plusp (or (getf gpu :total) 0))
                                     (round (* 100 (or (getf gpu :used) 0)) (getf gpu :total))
                                     0)
                          (rail--digits (getf gpu :used))))
      (:battery (let ((battery (service-state snapshot :battery)))
                  (rail--gauge (if (getf battery :charging) "CHG" "BAT") (getf battery :percent) nil)))
      (:network (rail--network snapshot))
      (:frame (let ((battery (state-value snapshot :frame-battery)))
                (rail--gauge (if (equal (getf battery :status) "Discharging") "VR" "VR+")
                             (getf battery :percent) nil))))))

(defun rail--places (state snapshot)
  "Where each block's top is on screen: the clock is pinned to the card's
middle and the other blocks stack away from it, or the whole stack is centred on
the middle when the module list has no clock."
  (let* ((entries (loop for module in (getf +rail+ :modules)
                        for height = (rail--height module state snapshot)
                        when height collect (cons module height)))
         (pin (position :time entries :key #'car)))
    (if (null pin)
        (let* ((total (+ (loop for entry in entries sum (cdr entry))
                         (* 45 (max 0 (1- (length entries))))))
               (top (- 720 (floor total 2))))
          (loop for (module . height) in entries
                for y = top then (+ y height 45)
                collect (cons module y)))
        (let* ((clock +rail--clock-y+)
               (y clock)
               (above (loop for (module . height) in (reverse (subseq entries 0 pin))
                            do (decf y (+ 45 height))
                            collect (cons module y)))
               (below (let ((start (+ clock 48)))
                        (loop for (module . height) in (subseq entries (1+ pin))
                              do (incf start 45)
                              collect (prog1 (cons module start) (incf start height))))))
          (append (reverse above) (list (cons :time clock)) below)))))

(defun rail--tray (snapshot)
  "The height of the slot the shelf asked for at the top of the web, or NIL."
  (let ((tray (state-value snapshot :shelf-tray)))
    (when (and tray (plusp (getf tray :count 0)) (plusp (getf tray :size 0)))
      (* (getf tray :count) (getf tray :size)))))

(defun rail--web (state snapshot seam width)
  "The readings, the voice block and the tray in the rail's web, top to bottom."
  (let* ((base (+ (getf seam :y) +rail--plate+))
         (height (- (getf seam :height) (* 2 +rail--plate+)))
         (tray (rail--tray snapshot))
         (voice (cassette--bolo-turn-p (getf state :bolo-state)))
         (parts nil)
         (cursor 0))
    (labels ((to (screen-y)
               (let ((y (- screen-y base)))
                 (when (> y cursor) (push (cons (- y cursor) nil) parts) (setf cursor y))))
             (put (tall node) (push (cons tall node) parts) (incf cursor tall))
             (tie (screen-y)
               (to screen-y)
               (put 1 (ui :rect :height (rail--design 1) :width (rail--design 52)
                          :background (rail--c :tie)))))
      (when tray
        (to 44)
        (put (* tray *rail--scale*) (ui :rect :height (rail--design tray) :width (rail--design 52)
                      :background (rail--c :tray))))
      (when voice
        (to (+ 44 (or tray 0)))
        (put (+ 135) (rail--voice state)))
      (let ((previous nil))
        (dolist (entry (rail--places state snapshot))
          (let ((top (cdr entry)))
            (when previous (tie (- top (+ +rail--air+ 1))))
            (to top)
            (put (rail--height (car entry) state snapshot) (rail--block (car entry) state snapshot)))
          (setf previous entry))))
    (ui :column :align :center :width (rail--design width) :height (rail--design height)
        :children (loop for (tall . node) in (nreverse parts)
                        collect (or node (ui :rect :height (rail--design tall)))))))

(defun rail--body (state snapshot seam)
  (let ((width (getf +rail+ :width))
        (height (getf seam :height)))
    (ui :column :align :stretch
        :children
        (list (ui :rect :height (rail--design +rail--plate+) :background (rail--c :steel))
              (ui :row :height (rail--design (- height (* 2 +rail--plate+)))
                  :children
                  (list (ui :rect :width (rail--design +rail--way+) :background (rail--c :steel))
                        (rail--web state snapshot seam (- width (* 2 +rail--way+)))
                        (ui :rect :width (rail--design +rail--way+) :background (rail--c :steel))))
              (ui :rect :height (rail--design +rail--plate+) :background (rail--c :steel))))))

(defun rail--carriage (box)
  "One card's two guide shoes, in the channel between its border and the rail."
  (let ((shoe (getf +rail+ :shoe))
        (height (getf box :height)))
    (ui :column :align :stretch
        :children (list (ui :rect :height (rail--design shoe) :background (rail--c :steel))
                        (ui :rect :height (rail--design (- height (* 2 shoe))))
                        (ui :rect :height (rail--design shoe) :background (rail--c :steel))))))

(defun rail--key (box)
  "The clamp: two lugs over the card's shoes and a dog at its middle, joined by
a bar down the channel. It is the only accent on the desktop."
  (let* ((lug (getf +rail+ :shoe))
         (dog (getf +rail+ :dog))
         (bar (getf +rail+ :key-bar))
         (channel (getf +rail+ :channel))
         (height (getf box :height))
         (middle (- height (* 2 lug)))
         (side (max 0 (floor (- (+ channel (* 2 (getf +rail+ :bite))) bar) 2)))
         (accent (rail--c :key))
         (shoulders (max 0 (floor (- middle dog) 2))))
    (ui :column :align :stretch
        :children
        (list (ui :rect :height (rail--design lug) :background accent)
              (ui :stack :height (rail--design middle)
                  :children
                  (list (ui :row :height (rail--design middle) :align :start
                            :children (list (ui :rect :width (rail--design side))
                                            (ui :rect :width (rail--design bar)
                                                :height (rail--design middle) :background accent)
                                            (ui :rect :width (rail--design side))))
                        (ui :column :align :stretch
                            :children (remove nil
                                              (list (ui :rect :height (rail--design shoulders))
                                                    (when (plusp dog)
                                                      (ui :rect :height (rail--design dog)
                                                          :background accent))
                                                    (ui :rect :height (rail--design
                                                                       (- middle dog shoulders))))))))
              (ui :rect :height (rail--design lug) :background accent)))))

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

(defun rail--body-x (seam) (+ (rail--lane seam :left) (getf +rail+ :channel)))

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
  (loop for entry in (context snapshot :layout)
        thereis (and (getf entry :visible)
                     (< (getf entry :x) (+ (getf box :x) (getf box :width)))
                     (< (getf box :x) (+ (getf entry :x) (getf entry :width)))
                     (< (getf entry :y) (+ (getf box :y) (getf box :height)))
                     (< (getf box :y) (+ (getf entry :y) (getf entry :height))))))

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
                                      :bolo-since nil :bolo-history nil))
    (snapshot state event)
  (when (eq (getf event :type) :watch)
    (when (and (eq (getf event :name) :bolo-level)
               (not (cassette--bolo-turn-p (getf state :bolo-state))))
      (cassette--bolo-sync state))
    (cassette--bolo-watch state event))
  (when (and (eq (getf event :type) :timer) (eq (getf event :name) :sample))
    (cassette--bolo-sync state)
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
         (layer (if (rail--covered-p snapshot seam) :bottom :top))
         (tray (rail--tray snapshot))
         (hot (loop for probe in '(:cpu :gpu)
                    thereis (cassette--hot-p (getf (getf state probe) :temp)))))
    (values state
            (append (list (interval :sample (getf +rail+ :sample))
                          (publish-state :hud-hot (and hot t)))
                    (cassette--bolo-watches)
                    (when (and output tray)
                      (list (publish-state :shelf-tray-rect
                                           (list :output (getf seam :output)
                                                 :x (rail--body-x seam)
                                                 :y (getf seam :y)
                                                 :width (getf +rail+ :width)
                                                 :height tray))))
                    (when output
                      (list (shell-surface :rail (rail--body state snapshot seam)
                                           :output (getf output :name) :anchors '(:top :left)
                                           :width (rail--design (getf +rail+ :width))
                                           :height (rail--design (getf seam :height))
                                           :margin (rail--surface-margin output (rail--body-x seam)
                                                                         (getf seam :y))
                                           :layer layer :background "#00000000" :blur t
                                           :click-through t :slide t)))
                    (loop for entry in carried
                          for id = (getf entry :id)
                          for box = (getf entry :box)
                          append (list (shell-surface
                                        (intern (format nil "RAIL-CAR-~D" id) :keyword)
                                        (rail--carriage box)
                                        :output (getf output :name) :anchors '(:top :left)
                                        :width (rail--design (getf +rail+ :channel))
                                        :height (rail--design (getf box :height))
                                        :margin (rail--surface-margin
                                                 output (rail--lane seam (getf entry :side))
                                                 (getf box :y))
                                        :layer layer :background "#00000000"
                                        :click-through t :slide t
                                        :attach id :attach-axes '(:y))))
                    (when key
                      (let ((box (getf key :box)))
                        (list (shell-surface
                               :rail-key (rail--key box)
                               :output (getf output :name) :anchors '(:top :left)
                               :width (rail--design (+ (getf +rail+ :channel)
                                                       (* 2 (getf +rail+ :bite))))
                               :height (rail--design (getf box :height))
                               :margin (rail--surface-margin
                                        output (- (rail--lane seam (getf key :side))
                                                  (getf +rail+ :bite))
                                        (if (eq (getf +rail+ :key-motion) :dock)
                                            (getf seam :y)
                                            (getf box :y)))
                               :layer layer :background "#00000000" :click-through t
                               :slide (eq (getf +rail+ :throw) :slide)
                               :attach (unless (eq (getf +rail+ :key-motion) :dock)
                                         (getf key :id))
                               :attach-axes '(:y)))))
                    (unless (getf +rail+ :focus-border)
                      (loop for entry in carried
                            collect (window-properties (getf entry :id)
                                                       :border (list :focused (rail--c :steel)
                                                                     :unfocused (rail--c :steel)))))
                    (rail--narrow snapshot state))
            nil)))
