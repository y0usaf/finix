(in-package #:tomoe-user)

(defun spine--parts (text)
  (loop with start = 0
        for i = (position-if (lambda (c) (member c '(#\: #\Space))) text :start start)
        for part = (subseq text start i)
        when (plusp (length part)) collect part
        while i do (setf start (1+ i))))

(defun spine--pixel (step)
  "Screen pixels per Nib font pixel for STEP, :small or :big text."
  (getf (getf +cassette+ :spine-pixels) step))

(defun spine--font (k)
  "Nib's 11-row em at K screen pixels per font pixel, so every stroke lands on
whole pixels and the text stays sharp."
  (* 11 k))

(defun spine--text (text color &optional (step :small))
  "TEXT for the spine in Nib at a whole pixel scale. The line box is the 7-row
cap height, so capitals and digits sit centred on their ink. Nib keeps each
glyph's blank column on its right; a matching column of padding on the left
centres the ink, not the advance."
  (let ((k (spine--pixel step)))
    (ui :row :padding (list 0 0 0 k)
        :children (list (ui :text :text text :size (spine--font k) :line-height (* 7 k) :color color
                            :font (getf +cassette+ :font))))))

(defun spine--detail (text color)
  "TEXT as small text. Nib has no degree sign and a fallback font would knock
the line off Nib's baseline, so a trailing one is drawn as a 3-pixel ring."
  (let ((text (string-trim " " text)))
    (if (and (plusp (length text)) (char= (char text (1- (length text))) #\°))
        (let ((k (spine--pixel :small)))
          (ui :row :align :start
              :children (list (spine--text (subseq text 0 (1- (length text))) color)
                              (ui :rect :width (* 3 k) :height (* 3 k) :border k :border-color color))))
        (spine--text text color))))

(defun spine--groove ()
  (ui :rect :height 1 :background (cassette--c :groove)))

(defun spine--meter (fraction)
  "A row of LED segments lit up to FRACTION, quiet under the number it backs."
  (let* ((count (getf +cassette+ :segments))
         (lit (round (* count (max 0 (min 1 fraction))))))
    (ui :row :gap 1
        :children (loop for i below count
                        collect (ui :rect :width (cassette--px 1) :height (cassette--px 2)
                                    :background (if (< i lit) (cassette--zone (/ (1+ i) count)) (cassette--c :led-off)))))))

(defun spine--gauge (label percent detail &optional hot)
  (let ((percent (max 0 (min 100 (round (or percent 0))))))
    (ui :column :align :center :gap (cassette--px 3)
        :children (remove nil
                          (list (spine--text label (cassette--c :dim))
                                (spine--text (format nil "~D" percent) (cassette--c :ink) :big)
                                (spine--meter (/ percent 100))
                                (when detail
                                  (spine--detail detail (if hot (cassette--c :orange) (cassette--c :dim)))))))))

(defun spine--window (text)
  "One tape-counter window: TEXT lit amber over the unlit 8s behind it."
  (ui :column :align :center :background (cassette--c :counter) :border 1 :border-color (cassette--c :rim)
      :padding (list (cassette--px 2) 0 (cassette--px 2) 0)
      :children (list (ui :stack :children (list (spine--text (cassette--ghost text) (cassette--c :counter-ghost) :big)
                                                 (spine--text text (cassette--c :amber) :big))))))

(defun spine--counter ()
  (ui :column :align :stretch :gap (cassette--px 1)
      :children (loop for part in (spine--parts (clock-text (getf +cassette+ :time)))
                      collect (spine--window part))))

(defun spine--date ()
  (destructuring-bind (&optional day date month &rest rest)
      (spine--parts (string-upcase (clock-text (getf +cassette+ :date))))
    (declare (ignore rest))
    (ui :column :align :center :gap (cassette--px 3)
        :children (remove nil
                          (list (when day (spine--text day (cassette--c :dim)))
                                (when date (spine--text date (cassette--c :ink) :big))
                                (when month (spine--text month (cassette--c :dim))))))))

(defun spine--fit (text width)
  "TEXT fitted to WIDTH characters as the cassette fits it, without the padding
after it or a space left before the cut."
  (let* ((fit (string-right-trim " " (cassette--fit text width)))
         (cut (- (length fit) 2)))
    (if (and (plusp cut) (string= ".." fit :start2 cut))
        (concatenate 'string (string-right-trim " " (subseq fit 0 cut)) "..")
        fit)))

(defun spine--title (text color)
  "TEXT turned a quarter clockwise to read down the spine, as on a J-card. The
line box keeps Nib's 3 rows below the baseline, which now lie on the left;
as much padding on the right centres the capitals across the spine."
  (let ((k (spine--pixel :big)))
    (ui :row :padding (list 0 (* 3 k) 0 0)
        :children (list (ui :text :text text :size (spine--font k) :line-height (* 10 k) :rotate 90
                            :color color :font (getf +cassette+ :font))))))

(defun spine--media (snapshot)
  (let* ((service (service-state snapshot :mpris))
         (status (getf service :status))
         (title (getf service :title))
         (length (getf service :length))
         (position (getf service :position))
         (played (if (and (realp length) (plusp length) (realp position)) (max 0 (min 1 (/ position length))) 0)))
    (when (and (stringp title) (plusp (length title)) (member status '("Playing" "Paused") :test #'equal))
      (ui :column :align :center :gap (cassette--px 4)
          :children (list (cassette--led (equal status "Playing"))
                          (cassette--reel (- 1 played))
                          (spine--title (spine--fit title (getf +cassette+ :spine-title))
                                        (if (equal status "Playing") (cassette--c :ink) (cassette--c :dim)))
                          (cassette--reel played))))))

(defun spine--module (module state snapshot)
  (let ((cpu (getf state :cpu)) (memory (getf state :memory)) (gpu (getf state :gpu)))
    (ecase module
      (:time (spine--counter))
      (:date (spine--date))
      (:media (spine--media snapshot))
      (:cpu (spine--gauge "CPU" (getf cpu :percent) (cassette--degrees (getf cpu :temp)) (cassette--hot-p (getf cpu :temp))))
      (:memory (spine--gauge "MEM" (getf memory :percent) (cassette--gib (getf memory :used))))
      (:gpu (when (probe--gpu-p gpu)
              (spine--gauge "GPU" (getf gpu :percent) (cassette--degrees (getf gpu :temp)) (cassette--hot-p (getf gpu :temp)))))
      (:vram (when (probe--gpu-p gpu)
               (spine--gauge "VRAM" (if (plusp (or (getf gpu :total) 0)) (round (* 100 (or (getf gpu :used) 0)) (getf gpu :total)) 0)
                             (cassette--gib (getf gpu :used)))))
      (:battery (let ((battery (service-state snapshot :battery)))
                  (spine--gauge (if (getf battery :charging) "CHG" "BAT") (getf battery :percent) nil)))
      (:network (let ((online (getf (service-state snapshot :network) :connected)))
                  (ui :column :align :center :gap (cassette--px 3)
                      :children (list (cassette--led online)
                                      (spine--text (if online "NET" "OFF") (cassette--c :dim))))))
      (:frame (let ((battery (state-value snapshot :frame-battery)))
                (when (getf battery :percent)
                  (spine--gauge (if (equal (getf battery :status) "Discharging") "VR" "VR+") (getf battery :percent) nil)))))))

(defun spine--cell (item)
  (ui :row :justify :center :padding (list (cassette--px 6) 0 (cassette--px 6) 0) :children (list item)))

(defun spine--run (items)
  (ui :column :height 0 :grow 1 :align :stretch :justify :center
      :children (loop for (item . rest) on (remove nil items)
                      collect (spine--cell item)
                      when rest collect (spine--groove))))

(defun spine--tray-height (tray)
  "Logical height of the tray slot that TRAY, a published :shelf-tray request
of (:count N :size PX), asks for at the top of the spine."
  (* (getf tray :count 0) (getf tray :size 0)))

(defun spine--body (items &optional (tray-height 0))
  (ui :column :align :stretch :background (cassette--c :face) :border 1 :border-color (cassette--c :rim)
      :children (remove nil
                        (list (when (plusp tray-height)
                                (ui :rect :height tray-height :background (cassette--c :counter)))
                              (spine--cell (cassette--grille))
                              (spine--run items)
                              (spine--cell (cassette--grille))))))

(defun spine--covered-p (snapshot box)
  "Whether a placed window overlaps BOX. Tiled windows never reach the seam, so
this is a float or a fullscreen window, which the spine then sits beneath."
  (loop for entry in (context snapshot :layout)
        thereis (and (getf entry :visible)
                     (< (getf entry :x) (+ (getf box :x) (getf box :width)))
                     (< (getf box :x) (+ (getf entry :x) (getf entry :width)))
                     (< (getf entry :y) (+ (getf box :y) (getf box :height)))
                     (< (getf box :y) (+ (getf entry :y) (getf entry :height))))))

(defun spine--fullscreen-p (snapshot output)
  (loop for entry in (context snapshot :layout)
        thereis (and (getf entry :visible) (getf entry :fullscreen)
                     (<= (getf entry :x) (getf output :x) (+ (getf entry :x) (getf entry :width) -1))
                     (<= (getf entry :y) (getf output :y) (+ (getf entry :y) (getf entry :height) -1)))))

(defun spine--plates (items output focal snapshot)
  (let ((split (or (cassette--split) (length items)))
        (layer (if (spine--fullscreen-p snapshot output) :bottom :top)))
    (loop for edge in '(:top :bottom)
          for plate = (cassette--plate (if (eq edge :top) (subseq items 0 split) (nthcdr split items)) :both edge)
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

(define-extension "bar" (:reads (:system :services :data :outputs :layout)
                         :state (list :cpu nil :memory nil :gpu nil))
    (snapshot state event)
  (when (and (eq (getf event :type) :timer) (eq (getf event :name) :sample))
    (let ((system (context snapshot :system)))
      (dolist (probe '(:cpu :memory :gpu))
        (setf (getf state probe) (probe--sample probe (getf state probe) system)))))
  (let* ((*cassette-mode* (state-value snapshot :theme-mode :dark))
         (seam (state-value snapshot :deck-seam))
         (output (and seam (find (getf seam :output) (context snapshot :outputs)
                                 :key (lambda (o) (getf o :name)) :test #'equal)))
         (scale (and output (/ (getf output :scale-120 120) 120)))
         (narrow (remove-if-not (lambda (o) (deck--narrow-p (list :output o))) (context snapshot :outputs)))
         (focal (state-value snapshot :focal-frame))
         (tray-height (spine--tray-height (state-value snapshot :shelf-tray)))
         (items (when narrow
                  (loop for module in (getf +cassette+ :modules)
                        collect (cassette--module module state snapshot))))
         (hot (loop for probe in '(:cpu :gpu) thereis (cassette--hot-p (getf (getf state probe) :temp)))))
    (values state
            (append (list (interval :sample (getf +cassette+ :sample))
                          (publish-state :hud-hot (and hot t)))
                    (when (and output (plusp tray-height))
                      (list (publish-state :shelf-tray-rect
                                           (list :output (getf seam :output)
                                                 :x (getf seam :x) :y (+ (getf seam :y) (round scale))
                                                 :width (getf seam :width)
                                                 :height (round (* tray-height scale))))))
                    (when output
                      (list (shell-surface :spine (spine--body (loop for module in (getf +cassette+ :modules)
                                                                     collect (spine--module module state snapshot))
                                                               tray-height)
                                           :output (getf output :name) :anchors '(:top :left)
                                           :width (round (getf seam :width) scale) :height (round (getf seam :height) scale)
                                           :margin (list (round (- (getf seam :y) (getf output :y)) scale) 0 0
                                                         (round (- (getf seam :x) (getf output :x)) scale))
                                           :layer (if (spine--covered-p snapshot seam) :bottom :top)
                                           :background "#00000000" :blur t
                                           :click-through t :slide t)))
                    (loop for o in narrow
                          append (spine--plates items o (and (equal (getf focal :output) (getf o :name)) focal) snapshot)))
            nil)))
