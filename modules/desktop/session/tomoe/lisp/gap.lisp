(in-package #:tomoe-user)

(defun gap--sample (probe previous system)
  (let ((sample (copy-list previous)))
    (ecase probe
      (:cpu
       (let ((total (getf system :cpu-total)) (idle (getf system :cpu-idle)))
         (when total
           (let ((spent (- total (getf sample :total total))))
             (setf (getf sample :percent)
                   (if (plusp spent)
                       (max 0 (min 100 (round (* 100 (- spent (- idle (getf sample :idle idle)))) spent)))
                       (getf sample :percent 0))
                   (getf sample :total) total
                   (getf sample :idle) idle
                   (getf sample :temp) (getf system :cpu-temperature))))))
      (:memory
       (let ((total (getf system :memory-total)) (available (getf system :memory-available)))
         (when (and total (plusp total))
           (setf (getf sample :percent) (round (* 100 (- total available)) total)
                 (getf sample :used) (round (- total available) 1024)))))
      (:gpu
       (let ((gpu (first (getf system :gpus))))
         (cond (gpu (setf (getf sample :percent) (max 0 (min 100 (getf gpu :busy)))
                          (getf sample :used) (getf gpu :vram-used)
                          (getf sample :total) (getf gpu :vram-total)
                          (getf sample :temp) (getf gpu :temperature)
                          (getf sample :failures) 0))
               (system (setf (getf sample :failures) (1+ (getf sample :failures 0))))))))
    sample))

(defun gap--gpu-p (gpu) (and (getf gpu :percent) (< (getf gpu :failures 0) 3)))

(defun gap--ascii (text) (remove-if (lambda (c) (> (char-code c) 126)) text))

(defun gap--degrees (value) (if (realp value) (format nil "~2D°" (max 0 (min 99 (round value)))) "--°"))

(defun gap--gib (mib) (if (realp mib) (format nil "~4,1FG" (/ mib 1024d0)) "--.-G"))

(defun gap--fit (text width)
  (format nil "~vA" width (if (> (length text) width) (concatenate 'string (subseq text 0 (- width 2)) "..") text)))

(defun gap--text (text color)
  (ui :text :text text :size 11 :line-height 11 :color color :font (getf +gap+ :font)))

(defun gap--item (p children)
  (ui :stack :children (list (ui :column :align :stretch
                                 :children (list (ui :rect :height 3)
                                                 (ui :rect :height 8 :background (hud--alpha (hud--c p :bg) "e6"))))
                             (ui :row :height 11 :align :end :gap 4 :padding '(0 4 0 4)
                                 :children (remove nil children)))))

(defun gap--meter (p value accent zones)
  (let ((filled (* 12 (max 0 (min 1 value)))))
    (ui :row :gap 1 :height 8 :align :end
        :children (loop for i below 12
                        collect (ui :rect :width 3 :height 8
                                    :background (hud--mix (hud--off p)
                                                          (if zones (hud--heat (* 100 (/ (1+ i) 12)) accent p) accent)
                                                          (max 0 (min 1 (- filled i)))))))))

(defun gap--gauge (p label accent percent detail &optional (zones t))
  (gap--item p (list (gap--text label accent)
                     (gap--text (format nil "~3D%" (max 0 (min 100 percent))) (hud--c p :fg))
                     (gap--meter p (/ percent 100) accent zones)
                     (when detail (gap--text detail (hud--dim p 0.75))))))

(defun gap--words (p &rest parts)
  (gap--item p (loop for (text color) on parts by #'cddr collect (gap--text text (or color (hud--c p :fg))))))

(defun gap--media (p snapshot)
  (let* ((service (service-state snapshot :mpris))
         (status (getf service :status))
         (title (getf service :title))
         (artist (getf service :artist)))
    (when (and (stringp title) (plusp (length title)) (member status '("Playing" "Paused") :test #'equal))
      (gap--words p (if (equal status "Playing") ">>" "||") (hud--c p :color5)
                  (gap--fit (gap--ascii (string-upcase (if (and (stringp artist) (plusp (length artist)))
                                                            (format nil "~A - ~A" artist title)
                                                            title)))
                            (getf +gap+ :media-width))
                  nil))))

(defun gap--battery (p snapshot)
  (let* ((battery (service-state snapshot :battery))
         (percent (round (getf battery :percent 0)))
         (color (cond ((getf battery :charging) (hud--c p :color2)) ((< percent 15) (hud--c p :color1))
                      ((< percent 30) (hud--c p :color3)) (t (hud--c p :color2)))))
    (gap--gauge p (if (getf battery :charging) "CHG" "BAT") color percent nil nil)))

(defun gap--network (p snapshot)
  (let* ((network (service-state snapshot :network))
         (ssid (getf network :ssid))
         (online (getf network :connected)))
    (gap--words p (gap--fit (cond ((and online (stringp ssid) (plusp (length ssid))) (gap--ascii (string-upcase ssid)))
                                  (online "ONLINE")
                                  (t "OFFLINE"))
                            20)
                (if online (hud--c p :color6) (hud--c p :color1)))))

(defun gap--frame (p snapshot)
  (let* ((battery (state-value snapshot :frame-battery))
         (percent (getf battery :percent))
         (powered (not (equal (getf battery :status) "Discharging"))))
    (when percent
      (gap--gauge p (if powered "VR+" "VR")
                  (cond (powered (hud--c p :color2)) ((< percent 15) (hud--c p :color1))
                        ((< percent 30) (hud--c p :color3)) (t (hud--c p :color2)))
                  percent nil nil))))

(defun gap--module (module p state snapshot)
  (let ((cpu (getf state :cpu)) (memory (getf state :memory)) (gpu (getf state :gpu)))
    (ecase module
      (:time (gap--words p (clock-text (getf +gap+ :time)) nil))
      (:date (gap--words p (string-upcase (clock-text (getf +gap+ :date))) nil))
      (:media (gap--media p snapshot))
      (:battery (gap--battery p snapshot))
      (:network (gap--network p snapshot))
      (:frame (gap--frame p snapshot))
      (:cpu (gap--gauge p "CPU" (hud--c p :color4) (getf cpu :percent 0) (gap--degrees (getf cpu :temp))))
      (:memory (gap--gauge p "MEM" (hud--c p :color5) (getf memory :percent 0) (gap--gib (getf memory :used))))
      (:gpu (when (gap--gpu-p gpu)
              (gap--gauge p "GPU" (hud--c p :color2) (getf gpu :percent 0) (gap--degrees (getf gpu :temp)))))
      (:vram (when (gap--gpu-p gpu)
               (gap--gauge p "VRAM" (hud--c p :color6)
                           (if (plusp (or (getf gpu :total) 0)) (round (* 100 (or (getf gpu :used) 0)) (getf gpu :total)) 0)
                           (gap--gib (getf gpu :used))))))))

(defun gap--line (panels)
  (let* ((modules (getf +gap+ :modules))
         (pair (getf +gap+ :center-between))
         (inset (getf +gap+ :inset))
         (seam (loop for (a b) on modules
                     for index from 1
                     when (and b (eq a (first pair)) (eq b (second pair))) return index)))
    (flet ((half (items justify padding)
             (ui :row :width 0 :grow 1 :height 11 :gap 6 :align :end :justify justify :padding padding
                 :children (remove nil items))))
      (ui :row :height 11 :align :end :justify :center
          :children (if seam
                        (list (half (subseq panels 0 seam) :end (list 0 inset 0 0))
                              (half (nthcdr seam panels) :start (list 0 0 0 inset)))
                        (list (ui :row :height 11 :gap 6 :align :end :children (remove nil panels))))))))

(define-extension "bar" (:reads (:system :services :data :outputs)
                         :state (list :cpu nil :memory nil :gpu nil))
    (snapshot state event)
  (when (and (eq (getf event :type) :timer) (eq (getf event :name) :sample))
    (let ((system (context snapshot :system)))
      (dolist (probe '(:cpu :memory :gpu))
        (setf (getf state probe) (gap--sample probe (getf state probe) system)))))
  (let* ((p (state-value snapshot :hud-palette))
         (line (gap--line (loop for module in (getf +gap+ :modules)
                                collect (gap--module module p state snapshot))))
         (focal (state-value snapshot :focal-frame))
         (wide (first (sort (copy-list (context snapshot :outputs)) #'> :key (lambda (o) (getf o :width)))))
         (hot (loop for probe in '(:cpu :gpu)
                    for temp = (getf (getf state probe) :temp)
                    thereis (and (realp temp) (>= temp (getf +gap+ :hot))))))
    (values state
            (append (list (interval :sample (getf +gap+ :sample))
                          (publish-state :hud-hot (and hot t)))
                    (loop for edge in (getf +gap+ :edges)
                          collect (if focal
                                      (shell-surface edge line :output (getf focal :output) :anchors '(:top :left)
                                                     :width (getf focal :width) :height 11
                                                     :margin (list (- (if (eq edge :top)
                                                                          (getf focal :top)
                                                                          (+ (getf focal :top) (getf focal :height)))
                                                                      6)
                                                                   0 0 (getf focal :left))
                                                     :layer :overlay :background "#00000000" :click-through t)
                                      (shell-surface edge line :output (getf wide :name) :anchors (list edge :left :right)
                                                     :height 11 :margin (if (eq edge :top) '(-3 0 0 0) 0)
                                                     :layer :overlay :background "#00000000" :click-through t))))
            nil)))
