(in-package #:tomoe-user)

;;; FUSED
;;;
;;; The rail as a pixel HUD cast in sand: a bevelled slab in the seam, its
;;; compartments recessed into the material with grooves between them, and the
;;; readings poured into them as sand -- the gauges a level of grains, the clock
;;; two digits of grains, bolo's voice a bed of grains that hops while the turn
;;; is open and settles when it closes. Everything is drawn in four pixel art
;;; pixels, and the slab clamps to the focused card's frame at every groove.
;;;
;;; Each card's frame is a joined line, not a border: the focused card wears a
;;; double line whose two top rules open round its name, set into them in the
;;; line's own ink, and the rail-side rule runs into the slab so frame and slab
;;; read as one piece; every other card wears one light rule with its name set
;;; into the top of it. The title row above each card is the theme's :FRAME --
;;; it asks the deck for twenty pixels round the edges and twenty-eight above
;;; each card -- so the frame and its name have room outside the window box.
;;;
;;; A focus switch moves the frame as sand: the old frame lets go from the rail
;;; outward and its grains fall and drain into the slab, while the new frame is
;;; poured out of the slab along its rules, the name typing itself in behind the
;;; pour. All of that is timed from the switch in shaders/fused.glsl, which
;;; draws the frames over the output and the slab down the seam; the rail only
;;; hands it the numbers and the times, and steps its own look while a name is
;;; still typing. Once the pour has settled and the voice has calmed every
;;; surface holds its last picture, and the gauges step only when a drawn
;;; reading changes, so a still rail costs nothing.

(defparameter +rail-fused--cast+
  (list :edge 20 :title 28 :gap 4 :name 16 :slab 52 :inset 4 :groove 4 :pitch 196 :pitch-min 120
        :dark (list :mat "#3A3E58" :mat-hi "#545978" :mat-lo "#2A2D42" :shadow "#06060E"
                    :deep "#1C1E2C" :groove "#222434" :frame "#70769C" :line "#40435C"
                    :ink "#ECE7DC" :dim "#969288" :name "#84817A" :glint "#FFFDF4"
                    :tones (list "#ECE7DC" "#D0CABE" "#B0AA9E" "#928D83")
                    :dust (list "#70769C" "#8086AC" "#606588" "#969BBE"))
        :light (list :mat "#B2ACA2" :mat-hi "#CCC7BE" :mat-lo "#969087" :shadow "#8C867E"
                     :deep "#DEDAD2" :groove "#989289" :frame "#78736A" :line "#B8B3AA"
                     :ink "#292928" :dim "#58554F" :name "#7C7870" :glint "#FFFFFF"
                     :tones (list "#292928" "#44423E" "#605D57" "#7C7870")
                     :dust (list "#78736A" "#646058" "#8C877E" "#524F49"))))

(defparameter +rail-fused--motion+
  (list :type 0.24d0 :settle 0.50d0
        :vtop 12000d0 :gravity 30000d0))

(defun rail-fused--c (key)
  (rail--material key))

(defun rail-fused--side (id carried)
  (let ((entry (find id carried :key (lambda (item) (getf item :id)))))
    (case (and entry (getf entry :side))
      (:left -1)
      (:right 1)
      (t 0))))

(defun rail-fused--titles (snapshot)
  (loop for window in (context snapshot :windows)
        collect (cons (getf window :id)
                      (let ((title (getf window :title)))
                        (if (and title (plusp (length title))) title
                            (or (getf window :app-id) ""))))))

(defun rail-fused--title (id titles)
  (let ((pair (assoc id titles)))
    (if pair (cdr pair) "")))

(defun rail-fused--title-text (id carried titles)
  "The name shown on ID's frame, cut to the room its title row has."
  (let* ((entry (find id carried :key (lambda (item) (getf item :id))))
         (box (and entry (getf entry :box)))
         (room (if box (max 0 (floor (- (getf box :width) 28) (/ (rail--cast :name) 2))) 0))
         (name (rail-fused--title id titles)))
    (subseq name 0 (min (length name) room))))

(defun rail-fused--progress (switch cut now)
  (if (and switch (not cut))
      (min 1d0 (/ (max 0d0 (- now (getf switch :at))) (getf +rail-fused--motion+ :type)))
      1d0))

(defun rail-fused--window-block (id carried titles focus old switch cut progress)
  (let ((text (rail-fused--title-text id carried titles))
        (entry (find id carried :key (lambda (item) (getf item :id)))))
    (list (rail-fused--side id carried)
          (if (eql id focus) 1 0)
          (if (and old (eql id old) (not cut)) 1 0)
          (length text)
          (if entry (+ (getf (getf entry :box) :x) 16) 0)
          (if (and (eql id focus) switch (not cut)) progress 1d0)
          (/ (rail--cast :name) 2) (/ (rail--cast :name) 8))))

(defun rail-fused--frames-data (context)
  (destructuring-bind (&key snapshot epoch seam output carried key switch windows cut
                         old &allow-other-keys)
      context
    (let* ((motion +rail-fused--motion+)
           (now (hud--now))
           (titles (rail-fused--titles snapshot))
           (focus (and key (getf key :id)))
           (progress (rail-fused--progress switch cut now))
           (on (if (and switch (not cut)) 1 0)))
      (append (list 0
                    (getf output :x) (getf output :y)
                    (+ (getf seam :x) (floor (- (getf seam :width) (rail--cast :slab)) 2))
                    (+ (getf seam :x) (floor (- (getf seam :width) (rail--cast :slab)) 2)
                       (rail--cast :slab)))
              (rail--rgb (rail-fused--c :frame))
              (rail--rgb (rail-fused--c :line))
              (rail--rgb (first (getf (rail--cast *rail--mode*) :dust)))
              (rail--rgb (second (getf (rail--cast *rail--mode*) :dust)))
              (rail--rgb (rail-fused--c :glint))
              (list (getf motion :settle) (getf motion :vtop) (getf motion :gravity)
                    on
                    (if switch (- (getf switch :at) epoch) -1d6)
                    (rail--cast :gap))
              (loop for id in windows
                    append (rail-fused--window-block id carried titles focus old
                                                     switch cut progress))))))

(defun rail-fused--gauge-of (module state snapshot)
  (let ((meter (getf state :rail-meter))
        (cpu (getf state :cpu))
        (gpu (getf state :gpu)))
    (case module
      (:cpu (when (getf cpu :percent)
              (list :label "CPU" :percent (getf meter :cpu)
                    :detail (cassette--degrees (getf cpu :temp))
                    :hot (cassette--hot-p (getf cpu :temp)))))
      (:memory (when (getf (getf state :memory) :percent)
                 (list :label "MEM" :percent (getf meter :memory)
                       :detail (rail--digits (getf meter :memory-used)) :hot nil)))
      (:gpu (when (probe--gpu-p gpu)
              (list :label "GPU" :percent (getf meter :gpu)
                    :detail (cassette--degrees (getf gpu :temp))
                    :hot (cassette--hot-p (getf gpu :temp)))))
      (:vram (when (probe--gpu-p gpu)
               (list :label "VRM" :percent (getf meter :vram)
                     :detail (rail--digits (getf meter :vram-used)) :hot nil)))
      (:battery (let ((battery (service-state snapshot :battery)))
                  (when (getf battery :percent)
                    (list :label (if (getf battery :charging) "CHG" "BAT")
                          :percent (getf battery :percent) :detail nil :hot nil))))
      (:frame (let ((battery (state-value snapshot :frame-battery)))
                (when (getf battery :percent)
                  (list :label "FRM" :percent (getf battery :percent)
                        :detail (getf battery :status) :hot nil))))
      (t nil))))

(defun rail-fused--clock-parts ()
  (destructuring-bind (&optional hours minutes)
      (rail--parts (clock-text (getf +cassette+ :time)))
    (list (or (and hours (parse-integer hours :junk-allowed t)) 0)
          (or (and minutes (parse-integer minutes :junk-allowed t)) 0))))

(defun rail-fused--date-parts ()
  (destructuring-bind (&optional day date month &rest rest)
      (rail--parts (string-upcase (clock-text (getf +cassette+ :date))))
    (declare (ignore rest))
    (list (or day "--") (or date "--") (or month "---"))))

(defun rail-fused--layout (context)
  (destructuring-bind (&key state snapshot seam tray &allow-other-keys) context
    (let* ((modules (getf +rail+ :modules))
           (gauges (loop for module in modules
                         when (member module '(:cpu :memory :gpu :vram :battery :frame))
                           append (let ((gauge (rail-fused--gauge-of module state snapshot)))
                                    (when gauge (list gauge)))))
           (media (and (member :media modules) (rail--media-played snapshot)))
           (clock (and (member :time modules) (rail-fused--clock-parts)))
           (date (and (member :date modules) (rail-fused--date-parts)))
           (network (and (member :network modules)
                         (getf (service-state snapshot :network) :connected)))
           (groove (rail--cast :groove))
           (inset (rail--cast :inset))
           (height (getf seam :height))
           (top (+ inset (if tray (+ tray 8) 0)))
           (bottom (- height inset))
           (cap 44) (voice 264) (date-h 84) (clock-h 104) (media-h 112)
           (count (length gauges))
           (y top)
           (sections nil))
      (flet ((put (kind tall data)
               (push (append (list :kind kind :y y :h tall) data) sections)
               (incf y (+ tall groove))))
        (put :cap cap nil)
        (put :voice voice nil)
        (when date (put :date date-h (list :date date)))
        (when clock (put :clock clock-h (list :clock clock)))
        (when media (put :media media-h (list :status (first media)
                                              :level (* 100 (second media)))))
        (let* ((space (- bottom y))
               (tall (if (plusp count)
                         (min (rail--cast :pitch)
                              (max (rail--cast :pitch-min)
                                   (* 4 (floor (- space (* (1- count) groove))
                                               (* 4 count)))))
                         0)))
          (dotimes (i count)
            (put :gauge tall (list :gauge (nth i gauges)))))
        (when network (put :net 76 (list :online (and network t))))
        (list :sections (nreverse sections) :height height :inset inset :groove groove)))))

(defun rail-fused--text (text colour size)
  (rail--text text colour size size))

(defun rail-fused--gauge-node (section)
  (let* ((gauge (getf section :gauge))
         (h (getf section :h))
         (bar (max 0 (- h 100)))
         (percent (max 0 (min 100 (round (or (getf gauge :percent) 0)))))
         (detail (getf gauge :detail))
         (value (format nil "~D%" percent)))
    (ui :column :height (rail--design h) :align :center
        :children (append
                   (list (ui :rect :height (rail--design 6))
                         (rail-fused--text (getf gauge :label) (rail--label) 24)
                         (ui :rect :height (rail--design 4))
                         (rail-fused--text value (rail--value) 24)
                         (ui :rect :height (rail--design 6))
                         (ui :rect :height (rail--design bar))
                         (ui :rect :height (rail--design 8)))
                   (when detail
                     (list (rail-fused--text detail
                                             (if (getf gauge :hot) (rail-fused--c :glint)
                                                 (rail--detail))
                                             24)))
                   (list (ui :rect :height (rail--design 4)))))))

(defun rail-fused--media-node (section)
  (let* ((h (getf section :h))
         (bar (max 0 (- h 96)))
         (status (getf section :status)))
    (ui :column :height (rail--design h) :align :center
        :children (list (ui :rect :height (rail--design 6))
                        (rail-fused--text "MED" (rail--label) 24)
                        (ui :rect :height (rail--design 4))
                        (rail-fused--text (if (equal status "Playing") ">" "||") (rail--value) 24)
                        (ui :rect :height (rail--design 6))
                        (ui :rect :height (rail--design bar))
                        (ui :rect :height (rail--design 32))))))

(defun rail-fused--section-node (context section)
  (let ((kind (getf section :kind)) (h (getf section :h)))
    (case kind
      (:cap (ui :column :height (rail--design h) :align :center :justify :center
                :children (if (cassette--bolo-turn-p (getf (getf context :state) :bolo-state))
                              (list (rail--voice (getf context :state)))
                              (list (rail-fused--text "MIC" (rail--label) 24)))))
      (:date (destructuring-bind (day date month) (getf section :date)
               (ui :column :height (rail--design h) :align :center :justify :center
                   :children (list (rail-fused--text day (rail--label) 24)
                                   (rail-fused--text date (rail--value) 24)
                                   (rail-fused--text month (rail--label) 24)))))
      (:media (rail-fused--media-node section))
      (:gauge (rail-fused--gauge-node section))
      (:net (ui :column :height (rail--design h) :align :center :justify :center
                :children (list (rail-fused--text "NET" (rail--label) 24)
                                (rail-fused--text (if (getf section :online) "ON" "OFF")
                                                  (rail--value) 24))))
      (t (ui :rect :height (rail--design h))))))

(defun rail-fused--type (context layout)
  (ui :column :width (rail--design (rail--cast :slab)) :height (rail--design (getf layout :height))
      :align :center
      :children (loop for section in (getf layout :sections)
                      append (list (rail-fused--section-node context section)
                                   (ui :rect :height (rail--design (getf layout :groove)))))))

(defun rail-fused--compartments (layout)
  (loop for section in (getf layout :sections)
        append (case (getf section :kind)
                 (:gauge (list (getf section :y) (+ (getf section :y) (getf section :h))
                               (max 0 (min 100 (round (or (getf (getf section :gauge) :percent) 0))))
                               (if (getf (getf section :gauge) :hot) 1 0) 1))
                 (:media (list (getf section :y) (+ (getf section :y) (getf section :h))
                               (max 0 (min 100 (round (or (getf section :level) 0))))
                               0 2))
                 (t nil))))

(defun rail-fused--slab-data (context layout)
  (destructuring-bind (&key state epoch seam switch cut voicing fade &allow-other-keys)
      context
    (let* ((sections (getf layout :sections))
           (groove (getf layout :groove))
           (comp (rail-fused--compartments layout))
           (count (min 6 (floor (length comp) 5)))
           (padded-comp (append comp (loop repeat (- 30 (length comp)) collect 0)))
           (grooves (loop for section in (cdr sections)
                          collect (max 0 (- (getf section :y) groove))))
           (clock (find :clock sections :key (lambda (s) (getf s :kind))))
           (voice (find :voice sections :key (lambda (s) (getf s :kind))))
           (clock-parts (and clock (getf clock :clock)))
           (levels (if voicing
                       (subseq (getf state :bolo-history) 0
                               (min 32 (length (getf state :bolo-history))))
                       nil))
           (padded (append levels (loop repeat (- 32 (length levels)) collect 0d0)))
           (width (getf seam :width)))
      (append (list 1
                    (floor (- width (rail--cast :slab)) 2)
                    (+ (floor (- width (rail--cast :slab)) 2) (rail--cast :slab))
                    (getf layout :height) groove)
              (rail--rgb (rail-fused--c :mat))
              (rail--rgb (rail-fused--c :mat-hi))
              (rail--rgb (rail-fused--c :mat-lo))
              (rail--rgb (rail-fused--c :shadow))
              (rail--rgb (rail-fused--c :deep))
              (rail--rgb (rail-fused--c :groove))
              (rail--rgb (rail-fused--c :frame))
              (rail--rgb (rail-fused--c :glint))
              (loop for tone in (getf (rail--cast *rail--mode*) :tones) append (rail--rgb tone))
              (list (if clock-parts (first clock-parts) 0)
                    (if clock-parts (second clock-parts) 0)
                    (if voicing 1 0)
                    (let ((since (getf state :bolo-since)))
                      (if (and since voicing) (- since epoch) -1d9))
                    (let ((closed (and (realp fade) voicing)))
                      (if closed (- fade epoch) -1d9))
                    (getf +rail--voice+ :rise)
                    (getf +rail--voice+ :settle)
                    (length levels))
              padded
              (list count)
              padded-comp
              (list (if clock (getf clock :y) 0) (if clock (+ (getf clock :y) (getf clock :h)) 0)
                    (if voice (getf voice :y) 0) (if voice (+ (getf voice :y) (getf voice :h)) 0)
                    (if switch (- (getf switch :at) epoch) -1d6)
                    (if (and switch (not cut)) 1 0))
              (subseq (append grooves (list 0 0 0 0 0 0 0 0)) 0 8)))))

(defun rail-fused--title-surfaces (context)
  (destructuring-bind (&key snapshot output carried key layer switch cut now &allow-other-keys)
      context
    (let ((titles (rail-fused--titles snapshot))
          (focus (and key (getf key :id)))
          (progress (rail-fused--progress switch cut now)))
      (loop for entry in carried
            for box = (getf entry :box)
            for id = (getf entry :id)
            when (and box
                      (< (getf box :y) (+ (getf output :y) (getf output :height)))
                      (> (+ (getf box :y) (getf box :height)) (getf output :y)))
              collect
              (let* ((text (rail-fused--title-text id carried titles))
                     (room (max 1 (- (getf box :width) 16)))
                     (writing (and (eql id focus) switch (not cut)))
                     (size (rail--cast :name))
                     (shown (* (/ size 2) (length text) (if writing progress 1)))
                     (colour (if (eql id focus) (rail-fused--c :frame)
                                 (rail-fused--c :name))))
                (shell-surface
                 (intern (format nil "RAIL-TITLE-~D" id) :keyword)
                 (ui :column :height (rail--design (rail--cast :title))
                     :children (list (ui :rect :height (rail--design
                                                         (- (rail--cast :title)
                                                            (* 5/2 (rail--cast :gap))
                                                            (* 3/8 size))))
                                     (ui :row :height (rail--design size)
                                         :children (list (ui :rect :width (rail--design 16))
                                                         (ui :text :text text :size (rail--design size)
                                                             :line-height (rail--design size)
                                                             :height (rail--design size)
                                                             :width (rail--design (max 1 shown))
                                                             :color colour
                                                             :font (getf *rail--look* :font))))))
                 :output (getf output :name) :anchors '(:top :left)
                 :width (rail--design room) :height (rail--design (rail--cast :title))
                 :margin (rail--surface-margin output (getf box :x)
                                               (- (getf box :y) (rail--cast :title)))
                 :layer layer :background "#00000000" :click-through t
                 :attach id))))))

(defun rail-fused--draw (look context)
  "FUSED: the sand frames over the output, the slab down the seam and the
readings poured into its compartments."
  (declare (ignore look))
  (destructuring-bind (&key epoch seam output carried switch cut fade voice layer
                         windows &allow-other-keys)
      context
    (let* ((motion +rail-fused--motion+)
           (now (hud--now))
           (layout (rail-fused--layout context))
           (moved (if (and switch (not cut))
                      (max 0d0 (+ (- (getf switch :at) epoch) (getf motion :settle)))
                      0d0))
           (calmed (cond (voice 1d6)
                         ((realp fade) (max 0d0 (+ (- fade epoch)
                                                   (getf +rail--voice+ :settle))))
                         (t 0d0)))
           (typing (and switch (not cut)
                        (< (- now (getf switch :at)) (+ (getf motion :type) 0.04d0))))
           (band-x (getf seam :x))
           (band-width (getf seam :width))
           (band-height (getf seam :height))
           (slab-x (+ (getf seam :x) (floor (- (getf seam :width) (rail--cast :slab)) 2)))
           (shader (getf look :shader)))
      (append
       (list
        (shell-surface
         :rail-slab (ui :stack)
         :output (getf output :name) :anchors '(:top :left)
         :width (rail--design band-width)
         :height (rail--design band-height)
         :margin (rail--surface-margin output band-x (getf seam :y))
         :layer layer :click-through t
         :background (list :shader shader
                           :data (rail-fused--slab-data context layout)
                           :windows windows :clock epoch
                           :until (max moved calmed)))
        (shell-surface
         :rail-frames (ui :stack)
         :output (getf output :name) :anchors '(:top :left)
         :width (rail--design (getf output :width))
         :height (rail--design (getf output :height))
         :layer layer :click-through t
         :background (list :shader shader
                           :data (rail-fused--frames-data context)
                           :windows windows :clock epoch :until moved
                           :reach (rail--design 44))))
       (when typing (list (interval :look 16)))
       (list (shell-surface :rail-type (rail-fused--type context layout)
                            :output (getf output :name) :anchors '(:top :left)
                            :width (rail--design (rail--cast :slab))
                            :height (rail--design band-height)
                            :margin (rail--surface-margin output slab-x (getf seam :y))
                            :layer layer :background "#00000000"
                            :click-through t))
       (rail-fused--title-surfaces context)
       (unless (getf +rail+ :focus-border)
         (loop for entry in carried
               collect (window-properties
                        (getf entry :id)
                        :radius 0
                        :border (list :focused "#00000000" :unfocused "#00000000"))))))))

(defparameter +rail-fused+
  (list :draw #'rail-fused--draw
        :cast +rail-fused--cast+
        :frame (list :edge 20 :title 28)
        :font "m3x6 Mono"))
