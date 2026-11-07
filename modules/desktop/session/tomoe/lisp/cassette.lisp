(in-package #:tomoe-user)

(defun cassette--px (n) (max 1 (round (* n (getf +cassette+ :scale)))))

(defvar *cassette-mode* :dark)

(defun cassette--c (key) (getf (getf (getf +cassette+ :colors) *cassette-mode*) key))

(defun cassette--text (text color)
  (ui :text :text text :size (cassette--px 11) :line-height (cassette--px 11) :color color :font (getf +cassette+ :font)))

(defun cassette--engraved (text color)
  (ui :stack :children (list (ui :column :padding '(1 0 0 0) :children (list (cassette--text text (cassette--c :shine))))
                             (cassette--text text color))))

(defun cassette--ghost (text) (map 'string (lambda (c) (if (digit-char-p c) #\8 c)) text))

(defun cassette--window (text &key (face (cassette--c :lcd)) (rim (cassette--c :rim)) (ghost (cassette--c :ghost))
                                   (ink (cassette--c :ink)) (shown text))
  (ui :column :background face :border 1 :border-color rim
      :children (list (ui :rect :height 1 :background rim)
                      (ui :row :height (cassette--px 11) :align :center :padding (list 0 (cassette--px 3) 0 (cassette--px 3))
                          :children (list (ui :stack :children (list (cassette--text (cassette--ghost text) ghost)
                                                                     (cassette--text shown ink))))))))

(defun cassette--zone (x)
  (cond ((> x 0.84) (cassette--c :red)) ((> x 0.6) (cassette--c :amber)) (t (cassette--c :green))))

(defun cassette--ladder (fraction)
  (let* ((count (getf +cassette+ :segments))
         (lit (round (* count (max 0 (min 1 fraction))))))
    (ui :row :gap (cassette--px 1) :align :center
        :children (loop for i below count
                        collect (ui :rect :width (cassette--px 4) :height (cassette--px 8)
                                    :background (if (< i lit) (cassette--zone (/ (1+ i) count)) (cassette--c :led-off)))))))

(defun cassette--led (on)
  (ui :rect :width (cassette--px 3) :height (cassette--px 3) :background (if on (cassette--c :orange) (cassette--c :led-off))))

(defun cassette--gauge (label percent detail &optional hot)
  (let ((percent (max 0 (min 100 (round (or percent 0))))))
    (list (cassette--engraved label (cassette--c :ink))
          (cassette--window (format nil "~3D%" percent))
          (cassette--ladder (/ percent 100))
          (when detail (cassette--engraved detail (if hot (cassette--c :orange) (cassette--c :dim)))))))

(defun cassette--degrees (value) (if (realp value) (format nil "~2D°" (max 0 (min 99 (round value)))) "--°"))

(defun cassette--gib (mib) (if (realp mib) (format nil "~4,1FG" (/ mib 1024d0)) "--.-G"))

(defun cassette--hot-p (value) (and (realp value) (>= value (getf +cassette+ :hot))))

(defun cassette--fit (text width)
  (let ((clean (string-upcase (remove-if (lambda (c) (> (char-code c) 126)) text))))
    (format nil "~vA" width (if (> (length clean) width) (concatenate 'string (subseq clean 0 (- width 2)) "..") clean))))

(defun cassette--reel (amount)
  (let* ((box (cassette--px 12))
         (hub (cassette--px 4))
         (size (+ hub (* 2 (round (* (- box hub) (max 0 (min 1 amount))) 2)))))
    (ui :stack :width box :height box
        :children (list (ui :row :width box :height box :justify :center :align :center
                            :children (list (ui :circular-progress :size size :thickness (max 1 (/ (- size hub) 2)) :value 1
                                                :color (cassette--c :tape) :track (cassette--c :tape))))
                        (ui :row :width box :height box :justify :center :align :center
                            :children (list (ui :circular-progress :size hub :thickness 1 :value 1
                                                :color (cassette--c :ink) :track (cassette--c :ink))))))))

(defun cassette--media (snapshot)
  (let* ((service (service-state snapshot :mpris))
         (status (getf service :status))
         (title (getf service :title))
         (artist (getf service :artist))
         (length (getf service :length))
         (position (getf service :position))
         (played (if (and (realp length) (plusp length) (realp position)) (max 0 (min 1 (/ position length))) 0)))
    (when (and (stringp title) (plusp (length title)) (member status '("Playing" "Paused") :test #'equal))
      (list (cassette--led (equal status "Playing"))
            (ui :row :height (cassette--px 12) :align :center :gap (cassette--px 3) :padding (list 0 (cassette--px 4) 0 0)
                :background (cassette--c :paper) :border 1 :border-color (cassette--c :rim)
                :children (list (ui :rect :width (cassette--px 2) :height (- (cassette--px 12) 2) :background (cassette--c :orange))
                                (ui :rect :width (cassette--px 2) :height (- (cassette--px 12) 2) :background (cassette--c :teal))
                                (cassette--reel (- 1 played))
                                (cassette--text (cassette--fit (if (and (stringp artist) (plusp (length artist)))
                                                                   (format nil "~A - ~A" artist title)
                                                                   title)
                                                               (getf +cassette+ :media-width))
                                                (cassette--c :ink))
                                (cassette--reel played)))))))

(defun cassette--counter ()
  (let ((time (clock-text (getf +cassette+ :time))))
    (list (cassette--window time :face (cassette--c :counter) :rim (cassette--c :ink) :ghost (cassette--c :counter-ghost)
                                 :ink (cassette--c :amber)
                                 :shown (if (oddp (parse-integer (clock-text "%S"))) (substitute #\Space #\: time) time)))))

(defun cassette--module (module state snapshot)
  (let ((cpu (getf state :cpu)) (memory (getf state :memory)) (gpu (getf state :gpu)))
    (ecase module
      (:time (cassette--counter))
      (:date (list (cassette--engraved (string-upcase (clock-text (getf +cassette+ :date))) (cassette--c :ink))))
      (:media (cassette--media snapshot))
      (:cpu (cassette--gauge "CPU" (getf cpu :percent) (cassette--degrees (getf cpu :temp)) (cassette--hot-p (getf cpu :temp))))
      (:memory (cassette--gauge "MEM" (getf memory :percent) (cassette--gib (getf memory :used))))
      (:gpu (when (probe--gpu-p gpu)
              (cassette--gauge "GPU" (getf gpu :percent) (cassette--degrees (getf gpu :temp)) (cassette--hot-p (getf gpu :temp)))))
      (:vram (when (probe--gpu-p gpu)
               (cassette--gauge "VRAM" (if (plusp (or (getf gpu :total) 0)) (round (* 100 (or (getf gpu :used) 0)) (getf gpu :total)) 0)
                                (cassette--gib (getf gpu :used)))))
      (:battery (let ((battery (service-state snapshot :battery)))
                  (cassette--gauge (if (getf battery :charging) "CHG" "BAT") (getf battery :percent) nil)))
      (:network (let* ((network (service-state snapshot :network)) (ssid (getf network :ssid)) (online (getf network :connected)))
                  (list (cassette--led online)
                        (cassette--engraved (cassette--fit (cond ((and online (stringp ssid) (plusp (length ssid))) ssid) (online "online") (t "offline")) 16)
                                            (cassette--c :ink)))))
      (:frame (let ((battery (state-value snapshot :frame-battery)))
                (when (getf battery :percent)
                  (cassette--gauge (if (equal (getf battery :status) "Discharging") "VR" "VR+") (getf battery :percent) nil)))))))

(defun cassette--grille ()
  (let ((hole (cassette--px 1)))
    (ui :column :gap hole
        :children (loop repeat 4
                        collect (ui :row :gap hole
                                    :children (loop repeat 6 collect (ui :rect :width hole :height hole :background (cassette--c :hole))))))))

(defun cassette--groove ()
  (ui :row :children (list (ui :rect :width 1 :height (cassette--px 10) :background (cassette--c :groove))
                           (ui :rect :width 1 :height (cassette--px 10) :background (cassette--c :shine)))))

(defun cassette--plate (items grille edge)
  (let* ((parts (loop for (item . rest) on (remove nil items)
                      collect (ui :row :gap (cassette--px 4) :align :center :children (remove nil item))
                      when rest collect (cassette--groove)))
         (body (ui :row :height (cassette--px 16) :align :center :gap (cassette--px 6)
                   :padding (list 0 (cassette--px 6) 0 (cassette--px 6))
                   :children (append (when (member grille '(:start :both)) (list (cassette--grille)))
                                     parts
                                     (when (member grille '(:end :both)) (list (cassette--grille)))))))
    (when parts
      (let ((plate (ui :column :align :stretch :background (cassette--c :face) :border 1 :border-color (cassette--c :ink)
                       :children (list (ui :rect :height 1 :background (cassette--c :shine))
                                       body
                                       (ui :rect :height 1 :background (cassette--c :shade))))))
        (if (eq edge :top)
            (ui :column :align :stretch
                :children (list plate (ui :row :height (cassette--shadow) :padding (list 0 0 0 (cassette--shadow))
                                          :children (list (ui :rect :grow 1 :height (cassette--shadow) :background (cassette--c :shadow))))))
            plate)))))

(defun cassette--shadow () (cassette--px 2))

(defun cassette--height (edge) (+ (cassette--px 16) 4 (if (eq edge :top) (cassette--shadow) 0)))

(defun cassette--split ()
  (let ((pair (getf +cassette+ :center-between)))
    (loop for (a b) on (getf +cassette+ :modules)
          for index from 1
          when (and b (eq a (first pair)) (eq b (second pair))) return index)))
