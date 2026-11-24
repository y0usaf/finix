(in-package #:tomoe-user)

(defparameter +rail-thread--width+ (thread-design--geom :seam-width))
(defparameter +rail-thread--settle+ (thread-design--motion :settle))
(defparameter +rail-thread--reach+ (thread-design--geom :reach))

(defparameter +rail-thread--mock+
  '((:time -388 40) (:cpu -270 50) (:memory -152 50) (:voice 0 30)
    (:gpu 152 50) (:vram 270 50) (:date 388 30)))

(defparameter +rail-thread--bead-order+ '(:time :date :cpu :memory :voice :gpu :vram))

(defun rail-thread--layout (strip)
  (let* ((y0 (getf strip :y))
         (height (getf strip :height))
         (weld (+ y0 (floor height 2)))
         (x (+ (getf strip :x) (floor (getf strip :width) 2)))
         (bead-hw (thread-design--geom :bead-half-width))
         (px (lambda (offset) (round (* offset height) 1412)))
         (mock (loop for (kind offset half) in +rail-thread--mock+
                     collect (list kind (- (funcall px offset) (funcall px half))
                                   (* 2 (funcall px half)))))
         (specs (loop for i below (length mock)
                      for (kind start size) = (nth i mock)
                      for previous = (and (plusp i) (nth (1- i) mock))
                      collect (list kind size
                                    (if previous
                                        (- start (+ (second previous) (third previous)))
                                        0))))
         (anchor (loop for (kind start size) in mock when (eq kind :voice) return (cons kind start)))
         (placed (rail--place specs anchor 1 nil))
         (by-kind (loop for (kind start size) in placed
                        collect (list kind
                                      (+ weld start (/ size 2))
                                      (/ size 2)
                                      bead-hw))))
    (list :x x :top y0 :bottom (+ y0 height) :weld weld
          :beads (loop for kind in +rail-thread--bead-order+
                       for bead = (find kind by-kind :key #'first)
                       when bead collect bead))))

(defun rail-thread--placed (state strip)
  (rail--memo state :thread-layout strip (lambda () (rail-thread--layout strip))))

(defparameter +rail--thread-styles+ '(:hairline :dim :recede :glow))

(defun rail-thread--style ()
  (or (position (getf +rail+ :focus) +rail--thread-styles+)
      (position :glow +rail--thread-styles+)))

(defun rail-thread--value-lengths (state)
  (loop for reading in (kit--readings state)
        collect (if reading (min 6 (length (getf reading :value))) 0)))

(defun rail-thread--numbers (layout state)
  (append (thread-design--rim-numbers)
          (list (getf layout :x) (getf layout :top) (getf layout :bottom) (getf layout :weld))
          (loop for (kind cy hy hw) in (getf layout :beads) append (list cy hy hw))
          (mapcar (lambda (n) (coerce n 'double-float)) (rail-thread--value-lengths state))
          (list (coerce (rail-thread--style) 'double-float))))

(defun rail-thread--whole (look context theme)
  (destructuring-bind (&key output windows epoch layer carried &allow-other-keys) context
    (append
     (list (shell-surface
            :rail-frames (ui :stack)
            :output (getf output :name) :anchors '(:top :left)
            :width (rail--design (getf output :width))
            :height (rail--design (getf output :height))
            :layer layer :click-through t
            :background (list :shader (getf look :shader)
                              :data (kit--data look context theme)
                              :windows windows :clock epoch
                              :until (kit--until look context))))
     (unless (getf +rail+ :focus-border)
       (loop for entry in carried
             collect (window-properties
                      (getf entry :id)
                      :radius (rail--design (getf look :radius 0))
                      :border (list :focused "#00000000" :unfocused "#00000000")))))))

(defparameter +rail-thread--strip-height+ (thread-design--geom :strip-height))

(defun rail-thread--bar-layout (strip state)
  (let* ((width (coerce (getf strip :width) 'double-float))
         (height (coerce (getf strip :height) 'double-float))
         (mid-x (* 0.5d0 width))
         (mid-y (* 0.5d0 height))
         (top-p (eq (getf strip :place) :top))
         (gpu-p (probe--gpu-p (getf state :gpu)))
         (bead-hw (coerce (thread-design--geom :bead-half-width) 'double-float))
         (specs
           (if top-p
               (list (list :time (- mid-x 74d0) 46d0 bead-hw)
                     (list :date (+ mid-x 64d0) 56d0 bead-hw))
               (if gpu-p
                   (list (list :cpu (- mid-x 226d0) 48d0 bead-hw)
                         (list :memory (- mid-x 102d0) 48d0 bead-hw)
                         (list :voice mid-x 26d0 bead-hw)
                         (list :gpu (+ mid-x 102d0) 48d0 bead-hw)
                         (list :vram (+ mid-x 226d0) 48d0 bead-hw))
                   (list (list :cpu (- mid-x 102d0) 48d0 bead-hw)
                         (list :voice mid-x 26d0 bead-hw)
                         (list :memory (+ mid-x 102d0) 48d0 bead-hw))))))
    (list :x mid-y :top 10d0 :bottom (- width 10d0) :weld mid-x
          :beads (loop for kind in +rail-thread--bead-order+
                       for found = (find kind specs :key #'first)
                       collect (or found (list kind 0d0 0d0 0d0))))))

(defun rail-thread--bar-numbers (context strip)
  (declare (ignore context))
  (let* ((blocks (getf strip :blocks))
         (height (getf strip :height)))
    (append (list 0d0 0d0 (coerce (thread-design--geom :thread-half-width) 'double-float))
            (list (case (getf strip :place)
                    (:top 1d0) (:bottom 2d0) (t 4d0)))
            (list 0d0 0d0 (getf strip :width) height)
            (list (length blocks))
            (loop for (module x y width block-height) in blocks
                  append (list (rail--kind module) x (- height y block-height)
                               (+ x width) (- height y))))))

(defun rail-thread--draw (look context)
  (destructuring-bind (&key state snapshot output strips &allow-other-keys) context
    (let* ((numbers (getf look :numbers #'rail-thread--numbers))
           (bar-numbers (getf look :bar-numbers #'rail-thread--bar-numbers))
           (seam (find :seam strips :key (lambda (strip) (getf strip :place))))
           (bars (remove seam strips))
           (vertical (find-if (lambda (strip) (eq (getf strip :axis) :y)) bars))
           (frame-strip (or seam vertical (first bars))))
      (append
       (if seam
           (let ((theme (funcall numbers (rail-thread--placed state seam) state)))
             (if (getf context :windows)
                 (kit--frames look context theme :reach +rail-thread--reach+)
                 (rail-thread--whole look context theme)))
           (when (and frame-strip (getf context :windows))
             (kit--frames look context
                          (append (funcall numbers (rail-thread--placed state frame-strip) state)
                                  (list 3d0))
                          :reach +rail-thread--reach+)))
       (loop for strip in bars
             for blocks = (getf strip :blocks)
             for horiz = (eq (getf strip :axis) :x)
             for tag = (format nil "-~A" (string-upcase (symbol-name (getf strip :place))))
             when blocks
               append
               (if horiz
                   (let* ((bar-context (list* :output (list :x 0 :y 0
                                                            :width (getf strip :width)
                                                            :height (getf strip :height))
                                              :windows nil
                                              context))
                          (bar-mode (if (eq (getf strip :place) :top) 1d0 2d0))
                          (theme (append (funcall numbers (rail-thread--bar-layout strip state) state)
                                         (list bar-mode))))
                     (list
                      (shell-surface
                       (intern (format nil "RAIL-THREAD-BAR~A" tag) :keyword)
                       (ui :stack)
                       :output (getf output :name)
                       :anchors (if (getf strip :edge) (list (getf strip :edge)) '(:top :left))
                       :width (rail--design (getf strip :width))
                       :height (rail--design (getf strip :height))
                       :margin (if (getf strip :edge) 0
                                   (rail--surface-margin output (getf strip :x) (getf strip :y)))
                       :exclusive-zone (getf strip :zone 0)
                       :layer (getf context :layer) :click-through t
                       :background (list :shader (getf look :shader)
                                         :data (kit--data look bar-context theme)
                                         :clock (getf context :epoch)
                                         :until (kit--until look context)))))
                   (list
                    (shell-surface
                     (intern (format nil "RAIL-THREAD-BAR~A" tag) :keyword)
                     (ui :stack)
                     :output (getf output :name)
                     :anchors (if (getf strip :edge) (list (getf strip :edge)) '(:top :left))
                     :width (rail--design (getf strip :width))
                     :height (rail--design (getf strip :height))
                     :margin (if (getf strip :edge) 0
                                 (rail--surface-margin output (getf strip :x) (getf strip :y)))
                     :exclusive-zone (getf strip :zone 0)
                     :layer (getf context :layer) :click-through t
                     :background (list :shader (getf look :bar-shader (getf look :shader))
                                       :data (funcall bar-numbers context strip)
                                       :clock (getf context :epoch)
                                       :until (kit--until look context)))
                    (shell-surface
                     (intern (format nil "RAIL-THREAD-TYPE~A" tag) :keyword)
                     (rail--web state snapshot strip blocks
                                (or (rail--material :ink) (rail--ink)))
                     :output (getf output :name)
                     :anchors (if (getf strip :edge) (list (getf strip :edge)) '(:top :left))
                     :width (rail--design (getf strip :width))
                     :height (rail--design (getf strip :height))
                     :margin (if (getf strip :edge) 0
                                 (rail--surface-margin output (getf strip :x) (getf strip :y)))
                     :layer (getf context :layer) :background "#00000000"
                     :click-through t :slide t))))))))

(defparameter +rail-thread+
  (list :draw #'rail-thread--draw :settle +rail-thread--settle+
        :strip-height +rail-thread--strip-height+
        :radius (thread-design--geom :card-radius)
        :frame (list :edge (thread-design--geom :window-edge) :title 0 :seam +rail-thread--width+)
        :trail (thread-design--motion :trail)))
