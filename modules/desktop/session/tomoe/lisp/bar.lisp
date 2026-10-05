(in-package #:tomoe-user)

(defparameter +bar-probes+ '((:cpu :cpu) (:memory :memory) (:gpu :gpu) (:vram :gpu)))

(defun bar--sample (probe previous system)
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
         (cond (gpu (setf (getf sample :util) (max 0 (min 100 (getf gpu :busy)))
                          (getf sample :used) (getf gpu :vram-used)
                          (getf sample :total) (getf gpu :vram-total)
                          (getf sample :temp) (getf gpu :temperature)
                          (getf sample :failures) 0))
               (system (setf (getf sample :failures) (1+ (getf sample :failures 0))))))))
    sample))

(defun bar--target (module state)
  (let ((gpu (getf state :gpu)))
    (ecase module
      (:cpu (getf (getf state :cpu) :percent 0))
      (:memory (getf (getf state :memory) :percent 0))
      (:gpu (getf gpu :util 0))
      (:vram (if (plusp (or (getf gpu :total) 0))
                 (round (* 100 (or (getf gpu :used) 0)) (getf gpu :total))
                 0)))))

(defun bar--metric (m target push)
  (let ((m (copy-list m)) (old (getf m :target)))
    (when (and old (or (>= (- target old) 25) (and (>= target 90) (< old 90))))
      (setf (getf m :flash-at) (hud--now)))
    (when push
      (setf (getf m :history) (last (append (getf m :history) (list target)) (getf +bar+ :history))))
    (setf (getf m :target) target)
    (when (or (null (getf m :shown)) (< (abs (- target (getf m :shown))) 3))
      (setf (getf m :shown) (float target 1d0)))
    m))

(defun bar--ease (m dt)
  (let* ((m (copy-list m)) (shown (getf m :shown)) (target (getf m :target))
         (next (+ target (* (- shown target) (exp (- (/ dt (getf +bar+ :tau))))))))
    (setf (getf m :shown) (if (< (abs (- next target)) 0.3) (float target 1d0) next))
    m))

(defun bar--moving-p (m)
  (or (/= (getf m :shown) (getf m :target))
      (plusp (hud--decay (getf m :flash-at) (getf +bar+ :flash)))))

(defun bar--segments (p value accent &optional (zones t))
  (let* ((count (getf +bar+ :segments))
         (filled (* count (max 0 (min 1 value)))))
    (ui :row :gap 1 :align :center
        :children (loop for i below count
                        for lit = (max 0 (min 1 (- filled i)))
                        collect (ui :rect :width 4 :height 14
                                    :background (hud--mix (hud--off p)
                                                          (if zones (hud--heat (* 100 (/ (1+ i) count)) accent p) accent)
                                                          lit))))))

(defun bar--spark (p history accent)
  (let* ((h 16) (count (length history))
         (scale (max 20 (reduce #'max history :initial-value 0))))
    (ui :row :gap 1 :align :end :height h
        :children (append (loop repeat (- (getf +bar+ :history) count)
                                collect (ui :rect :width 2 :height 1 :background (hud--off p)))
                          (loop for v in history
                                for i from 1
                                collect (ui :rect :width 2 :height (max 1 (round (* h v) scale))
                                            :background (hud--mix (hud--c p :bg) (hud--heat v accent p)
                                                                  (+ 0.3 (* 0.7 (/ i count))))))))))

(defun bar--temp-color (p value)
  (cond ((not (realp value)) (hud--dim p))
        ((>= value (getf +bar+ :hot)) (hud--c p :color1))
        ((>= value (- (getf +bar+ :hot) 10)) (hud--c p :color3))
        (t (hud--dim p 0.75))))

(defun bar--gauge (p accent label m detail detail-color)
  (let* ((shown (getf m :shown 0))
         (color (hud--heat (round shown) accent p))
         (flash (hud--decay (getf m :flash-at) (getf +bar+ :flash))))
    (hud--panel p color
                (list* (hud--text label 11 (hud--dim p))
                       (ui :row :align :end
                           :children (list (hud--text (format nil "~3D" (round shown)) 16 (hud--mix (hud--c p :fg) color flash))
                                           (hud--text "%" 11 (hud--dim p))))
                       (bar--segments p (/ shown 100) accent)
                       (bar--spark p (getf m :history) accent)
                       (when detail (list (hud--text detail 12 (or detail-color (hud--dim p 0.75))))))
                :flash flash)))

(defun bar--degrees (value) (when (realp value) (format nil "~D°" (round value))))

(defun bar--gib (mib) (when (realp mib) (format nil "~,1FG" (/ mib 1024d0))))

(defun bar--truncate (text limit)
  (if (<= (length text) limit) text (concatenate 'string (subseq text 0 (1- limit)) "…")))

(defun bar--nonempty (value) (and (stringp value) (plusp (length value)) value))

(defun bar--media (snapshot state now)
  (let* ((service (service-state snapshot :mpris))
         (status (getf service :status))
         (title (bar--nonempty (getf service :title)))
         (artist (bar--nonempty (getf service :artist)))
         (key (list (getf service :player-name) title status (getf service :position))))
    (unless (equal key (getf state :media-key))
      (setf (getf state :media-key) key (getf state :media-at) now))
    (values (when (and title (member status '("Playing" "Paused") :test #'equal))
              (let* ((length (or (getf service :length) 0))
                     (playing (equal status "Playing"))
                     (elapsed (if playing (- now (getf state :media-at now)) 0))
                     (position (min length (+ (or (getf service :position) 0) elapsed))))
                (list :playing playing
                      :label (string-upcase (bar--truncate (if artist (format nil "~A - ~A" artist title) title)
                                                           (getf +bar+ :media-width)))
                      :value (if (plusp length) (/ position length) 0))))
            state)))

(defun bar--sweep (p color value)
  (ui :progress :height 2 :radius 0 :value value :color color :track (hud--off p)))

(defun bar--eq (color playing now)
  (ui :row :gap 1 :align :end :height 14
      :children (loop for i below 5
                      collect (ui :rect :width 2
                                  :height (if playing
                                              (+ 2 (round (* 12 (abs (sin (+ (* now (+ 5.3 (* 2.1 i))) (* 1.7 i)))))))
                                              2)
                                  :background color))))

(defun bar--clock (p state now)
  (let* ((fg (hud--c p :fg)) (accent (hud--c p :accent))
         (sec (getf state :sec 0))
         (tick (hud--decay (getf state :minute-at) 700))
         (frac (/ (+ sec (min 1 (- now (getf state :sec-at now)))) 60)))
    (hud--panel p accent
                (list (hud--icon #xF0150 14 accent)
                      (ui :column :gap 1 :align :stretch
                          :children (list (ui :row :align :end
                                              :children (list (hud--text (getf state :minute) 18 (hud--mix fg accent tick))
                                                              (hud--text (format nil ":~2,'0D" sec) 12 (hud--dim p))))
                                          (bar--sweep p accent frac))))
                :flash tick)))

(defun bar--battery (p battery &optional (label "BAT"))
  (let* ((percent (round (getf battery :percent 0)))
         (charging (getf battery :charging))
         (color (cond (charging (hud--c p :color2)) ((< percent 15) (hud--c p :color1))
                      ((< percent 30) (hud--c p :color3)) (t (hud--c p :color2)))))
    (hud--panel p color
                (list* (hud--text label 11 (hud--dim p))
                       (ui :row :align :end
                           :children (list (hud--text (format nil "~3D" percent) 16 (hud--c p :fg))
                                           (hud--text "%" 11 (hud--dim p))))
                       (bar--segments p (/ percent 100) color nil)
                       (when charging (list (hud--icon #xF140B 13 color)))))))

(defun bar--network (p network)
  (let* ((ssid (getf network :ssid))
         (online (getf network :connected))
         (label (cond ((and online (stringp ssid) (plusp (length ssid))) (string-upcase (remove (code-char 0) ssid)))
                      (online "ONLINE")
                      (t "OFFLINE")))
         (color (if online (hud--c p :color6) (hud--c p :color1))))
    (hud--panel p color (list (hud--icon (if online #xF05A9 #xF05AA) 14 color)
                              (hud--text (bar--truncate label 20) 14 (hud--c p :fg))))))

(defun bar--gpu-p (state)
  (let ((gpu (getf state :gpu)))
    (and (getf gpu :util) (< (getf gpu :failures 0) 3))))

(defun bar--module (module p state snapshot metrics media now)
  (let ((cpu (getf state :cpu)) (gpu (getf state :gpu)))
    (ecase module
      (:time (bar--clock p state now))
      (:date (hud--panel p (hud--c p :color4)
                         (list (hud--icon #xF00ED 14 (hud--c p :color4))
                               (hud--text (string-upcase (clock-text (getf +bar+ :date))) 14 (hud--c p :fg)))))
      (:battery (bar--battery p (service-state snapshot :battery)))
      (:network (bar--network p (service-state snapshot :network)))
      (:frame (let ((frame (state-value snapshot :frame-battery)))
                (when (getf frame :percent)
                  (bar--battery p (list :percent (getf frame :percent)
                                        :charging (not (equal (getf frame :status) "Discharging")))
                                "VR"))))
      (:media (when media
                (let ((color (hud--c p :color5)))
                  (hud--panel p color
                              (list (bar--eq color (getf media :playing) now)
                                    (ui :column :gap 3 :align :stretch
                                        :children (list (hud--text (getf media :label) 13 (hud--c p :fg))
                                                        (bar--sweep p color (getf media :value)))))))))
      (:cpu (bar--gauge p (hud--c p :color4) "CPU" (getf metrics :cpu)
                        (bar--degrees (getf cpu :temp)) (bar--temp-color p (getf cpu :temp))))
      (:memory (bar--gauge p (hud--c p :color5) "MEM" (getf metrics :memory)
                           (bar--gib (getf (getf state :memory) :used)) nil))
      (:gpu (when (bar--gpu-p state)
              (bar--gauge p (hud--c p :color2) "GPU" (getf metrics :gpu)
                          (bar--degrees (getf gpu :temp)) (bar--temp-color p (getf gpu :temp)))))
      (:vram (when (bar--gpu-p state)
               (bar--gauge p (hud--c p :color6) "VRAM" (getf metrics :vram) (bar--gib (getf gpu :used)) nil))))))

(defun bar--surfaces (modules panels)
  (let* ((h (+ (getf +hud+ :height) (getf +hud+ :shadow)))
         (gap (getf +bar+ :gap))
         (exclusive (getf +bar+ :exclusive))
         (indent (if exclusive (getf +bar+ :indent) 0))
         (thickness (+ h indent))
         (margin (if exclusive 0 (getf +bar+ :margin)))
         (inset (getf +bar+ :inset))
         (pair (getf +bar+ :center-between))
         (seam (loop for (a b) on modules
                     for index from 1
                     when (and b (eq a (first pair)) (eq b (second pair))) return index)))
    (flet ((half (list justify padding)
             (ui :row :width 0 :grow 1 :height h :gap gap :justify justify :padding padding
                 :children (remove nil list))))
      (loop for edge in (getf +bar+ :edges)
            collect (shell-surface edge
                                   (ui :row :height thickness :justify :center
                                       :padding (cond ((zerop indent) 0)
                                                      ((eq edge :top) (list indent 0 0 0))
                                                      (t (list 0 0 indent 0)))
                                       :children (if seam
                                                     (list (half (subseq panels 0 seam) :end (list 0 inset 0 0))
                                                           (half (nthcdr seam panels) :start (list 0 0 0 inset)))
                                                     (list (ui :row :height h :gap gap :children (remove nil panels)))))
                                   :anchors (if (or seam exclusive) (list edge :left :right) (list edge))
                                   :margin (if (eq edge :top) (list margin 0 0 0) (list 0 0 margin 0))
                                   :height thickness :layer (if exclusive :top :overlay)
                                   :exclusive-zone (if exclusive thickness 0)
                                   :background "#00000000" :click-through t)))))

(define-extension "bar" (:reads (:services :system :data)
                         :state (list :cpu nil :memory nil :gpu nil :metrics nil :at nil
                                      :sec nil :sec-at nil :minute nil :minute-at nil))
    (snapshot state event)
  (let* ((modules (getf +bar+ :modules))
         (probes (remove-duplicates (loop for module in modules
                                          for source = (second (assoc module +bar-probes+))
                                          when source collect source)))
         (probe (and (eq (getf event :type) :timer) (find (getf event :name) probes))))
    (when probe
      (setf (getf state probe) (bar--sample probe (getf state probe) (context snapshot :system))))
    (let* ((p (state-value snapshot :hud-palette))
           (now (hud--now))
           (dt (if (getf state :at) (- now (getf state :at)) 0))
           (metrics (loop for (module source) in +bar-probes+
                          when (member module modules)
                            append (list module (bar--ease (bar--metric (getf (getf state :metrics) module)
                                                                        (bar--target module state)
                                                                        (eq source probe))
                                                           dt))))
           (sec (or (parse-integer (clock-text "%S") :junk-allowed t) 0))
           (minute (clock-text (getf +bar+ :time))))
      (setf (getf state :metrics) metrics (getf state :at) now)
      (unless (eql sec (getf state :sec))
        (setf (getf state :sec) sec (getf state :sec-at) now))
      (unless (equal minute (getf state :minute))
        (setf (getf state :minute-at) (when (getf state :minute) now) (getf state :minute) minute))
      (multiple-value-bind (media next) (if (member :media modules) (bar--media snapshot state now) (values nil state))
        (setf state next)
        (let* ((cpu-temp (getf (getf state :cpu) :temp))
               (gpu-temp (getf (getf state :gpu) :temp))
               (limit (getf +bar+ :hot))
               (hot (or (and (realp cpu-temp) (>= cpu-temp limit)) (and (realp gpu-temp) (>= gpu-temp limit))))
               (moving (loop for (nil m) on metrics by #'cddr thereis (bar--moving-p m)))
               (panels (loop for module in modules
                             collect (bar--module module p state snapshot metrics media now))))
          (values state
                  (append (list (interval :clock (getf +bar+ :clock-tick)))
                          (loop for source in probes
                                when (< (getf (getf state source) :failures 0) 3)
                                  collect (interval source (getf (getf +bar+ :sample) source)))
                          (when moving (list (interval :fast (getf +bar+ :tick))))
                          (list (publish-state :hud-hot (and hot t)))
                          (bar--surfaces modules panels))
                  nil))))))
