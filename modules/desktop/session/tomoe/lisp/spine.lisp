(in-package #:tomoe-user)

(defun spine--parts (text)
  (loop with start = 0
        for i = (position-if (lambda (c) (member c '(#\: #\Space))) text :start start)
        for part = (subseq text start i)
        when (plusp (length part)) collect part
        while i do (setf start (1+ i))))

(defun spine--turned (text color)
  (ui :text :text text :size (cassette--px 11) :line-height (cassette--px 11) :color color
      :font (getf +cassette+ :font) :rotate 90))

(defun spine--engraved (text color)
  (ui :stack :children (list (ui :column :padding '(1 0 0 0) :children (list (spine--turned text (cassette--c :shine))))
                             (spine--turned text color))))

(defun spine--groove ()
  (ui :column :align :stretch
      :children (list (ui :rect :height 1 :background (cassette--c :groove))
                      (ui :rect :height 1 :background (cassette--c :shine)))))

(defun spine--ladder (fraction)
  (let* ((count (getf +cassette+ :segments))
         (lit (round (* count (max 0 (min 1 fraction))))))
    (ui :column :gap (cassette--px 1) :align :center
        :children (loop for i from (1- count) downto 0
                        collect (ui :rect :width (cassette--px 6) :height (cassette--px 4)
                                    :background (if (< i lit) (cassette--zone (/ (1+ i) count)) (cassette--c :led-off)))))))

(defun spine--gauge (label percent detail &optional hot)
  (let ((percent (max 0 (min 100 (round (or percent 0))))))
    (ui :row :gap (cassette--px 3) :align :start
        :children (list (spine--ladder (/ percent 100))
                        (spine--engraved (format nil "~A ~3D%~@[ ~A~]" label percent detail)
                                         (if hot (cassette--c :orange) (cassette--c :ink)))))))

(defun spine--counter ()
  (ui :column :align :stretch
      :children (loop for part in (spine--parts (clock-text (getf +cassette+ :time)))
                      collect (cassette--window part :face (cassette--c :counter) :rim (cassette--c :ink)
                                                     :ghost (cassette--c :counter-ghost) :ink (cassette--c :amber)))))

(defun spine--date ()
  (ui :column :align :center :gap (cassette--px 2)
      :children (loop for part in (spine--parts (string-upcase (clock-text (getf +cassette+ :date))))
                      collect (cassette--engraved part (cassette--c :ink)))))

(defun spine--media (snapshot)
  (let* ((service (service-state snapshot :mpris))
         (status (getf service :status))
         (title (getf service :title))
         (artist (getf service :artist))
         (length (getf service :length))
         (position (getf service :position))
         (played (if (and (realp length) (plusp length) (realp position)) (max 0 (min 1 (/ position length))) 0)))
    (when (and (stringp title) (plusp (length title)) (member status '("Playing" "Paused") :test #'equal))
      (ui :column :align :center :gap (cassette--px 4) :padding (list (cassette--px 4) 0 (cassette--px 4) 0)
          :background (cassette--c :paper) :border 1 :border-color (cassette--c :rim)
          :children (list (cassette--led (equal status "Playing"))
                          (ui :rect :width (cassette--px 20) :height (cassette--px 2) :background (cassette--c :orange))
                          (ui :rect :width (cassette--px 20) :height (cassette--px 2) :background (cassette--c :teal))
                          (cassette--reel (- 1 played))
                          (spine--turned (cassette--fit (if (and (stringp artist) (plusp (length artist)))
                                                            (format nil "~A - ~A" artist title)
                                                            title)
                                                        (getf +cassette+ :media-width))
                                         (cassette--c :ink))
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
      (:network (let* ((network (service-state snapshot :network)) (ssid (getf network :ssid)) (online (getf network :connected)))
                  (ui :column :align :center :gap (cassette--px 4)
                      :children (list (cassette--led online)
                                      (spine--engraved (cassette--fit (cond ((and online (stringp ssid) (plusp (length ssid))) ssid)
                                                                            (online "online")
                                                                            (t "offline"))
                                                                      16)
                                                       (cassette--c :ink))))))
      (:frame (let ((battery (state-value snapshot :frame-battery)))
                (when (getf battery :percent)
                  (spine--gauge (if (equal (getf battery :status) "Discharging") "VR" "VR+") (getf battery :percent) nil)))))))

(defun spine--cell (item)
  (ui :row :justify :center :padding (list (cassette--px 5) 0 (cassette--px 5) 0) :children (list item)))

(defun spine--run (items justify)
  (ui :column :height 0 :grow 1 :align :stretch :justify justify
      :children (loop for (item . rest) on (remove nil items)
                      collect (spine--cell item)
                      when rest collect (spine--groove))))

(defun spine--body (items)
  (ui :row :align :stretch :background (cassette--c :face) :border 1 :border-color (cassette--c :ink)
      :children (list (ui :rect :width 1 :background (cassette--c :shine))
                      (ui :column :width 0 :grow 1 :align :stretch
                          :children (list (spine--cell (cassette--grille))
                                          (spine--run items :center)
                                          (spine--cell (cassette--grille))))
                      (ui :rect :width 1 :background (cassette--c :shade)))))

(defun spine--covered-p (snapshot box)
  "Whether a placed window overlaps BOX. Tiled windows never reach the seam, so
this is a float or a fullscreen window, which the spine then sits beneath."
  (loop for entry in (context snapshot :layout)
        thereis (and (getf entry :visible)
                     (< (getf entry :x) (+ (getf box :x) (getf box :width)))
                     (< (getf box :x) (+ (getf entry :x) (getf entry :width)))
                     (< (getf entry :y) (+ (getf box :y) (getf box :height)))
                     (< (getf box :y) (+ (getf entry :y) (getf entry :height))))))

(define-extension "bar" (:reads (:system :services :data :outputs :layout)
                         :state (list :cpu nil :memory nil :gpu nil))
    (snapshot state event)
  (when (and (eq (getf event :type) :timer) (eq (getf event :name) :sample))
    (let ((system (context snapshot :system)))
      (dolist (probe '(:cpu :memory :gpu))
        (setf (getf state probe) (probe--sample probe (getf state probe) system)))))
  (let* ((seam (state-value snapshot :deck-seam))
         (output (and seam (find (getf seam :output) (context snapshot :outputs)
                                 :key (lambda (o) (getf o :name)) :test #'equal)))
         (scale (and output (/ (getf output :scale-120 120) 120)))
         (hot (loop for probe in '(:cpu :gpu) thereis (cassette--hot-p (getf (getf state probe) :temp)))))
    (values state
            (append (list (interval :sample (getf +cassette+ :sample))
                          (publish-state :hud-hot (and hot t)))
                    (when output
                      (list (shell-surface :spine (spine--body (loop for module in (getf +cassette+ :modules)
                                                                     collect (spine--module module state snapshot)))
                                           :output (getf output :name) :anchors '(:top :left)
                                           :width (round (getf seam :width) scale) :height (round (getf seam :height) scale)
                                           :margin (list (round (- (getf seam :y) (getf output :y)) scale) 0 0
                                                         (round (- (getf seam :x) (getf output :x)) scale))
                                           :layer (if (spine--covered-p snapshot seam) :bottom :top)
                                           :background "#00000000" :click-through t :slide t))))
            nil)))
