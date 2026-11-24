(in-package #:tomoe-user)

(defparameter +thread-design--modes+
  '(:dark (:veil (0.094d0 0.094d0 0.11d0 0.5d0)
           :ink "#F4F2EC"
           :ink-muted "#C6C3BA"
           :ink-subtle "#96938A"
           :plate "#18181CB8"
           :plate-rgb (0.094d0 0.094d0 0.11d0)
           :plate-alpha 0.76d0
           :rim "#FFFFFF2E"
           :key "#FFFFFF1C"
           :urgent "#FF5D5D"
           :urgent-rgb (1.0d0 0.365d0 0.365d0)
           :urgent-tint "#FF5D5D28"
           :accent "#57C8FF"
           :accent-rgb (0.341d0 0.784d0 1.0d0)
           :shadow "#00000059")
    :light (:veil (0.8d0 0.79d0 0.76d0 0.5d0)
            :ink "#18181C"
            :ink-muted "#48484F"
            :ink-subtle "#6D6C67"
            :plate "#F4F2ECC8"
            :plate-rgb (0.957d0 0.949d0 0.925d0)
            :plate-alpha 0.82d0
            :rim "#00000033"
            :key "#00000014"
            :urgent "#D93838"
            :urgent-rgb (0.851d0 0.220d0 0.220d0)
            :urgent-tint "#D9383820"
            :accent "#1D8BC4"
            :accent-rgb (0.114d0 0.545d0 0.769d0)
            :shadow "#00000028")))

(defparameter +thread-design--palette+
  '(("1" . :ink) ("2" . "#FF5D5D") ("3" . "#FFC857") ("4" . "#57C8FF") ("5" . "#6EE7A8")))

(defparameter +thread-design--geometry+
  '(:seam-width 34
    :strip-height 48
    :thread-half-width 5.5d0
    :rim-width 5d0
    :plate-rim-width 1
    :weld-radius 20d0
    :weld-spread 64d0
    :card-radius 14
    :plate-radius 12
    :bead-half-width 14
    :reach 80
    :window-edge 14
    :padding 10
    :margin 28
    :shadow-pad 12
    :notif-width 348
    :notif-min-width 220
    :notif-rim-width 2.2d0
    :notif-gap 14
    :notif-inset-x 14
    :notif-inset-y 14
    :notif-screen-margin 12))

(defparameter +thread-design--type+
  '(:font "Nib"
    :meta-size 11
    :meta-line-height 15
    :body-size 12.5d0
    :body-line-height 17
    :title-size 14
    :title-line-height 19
    :hint-size 15
    :mark-size 20))

(defparameter +thread-design--motion+
  '(:settle 0.8d0
    :spring (:enabled t :stiffness 260 :damping 1d0)
    :voice-speed 3200d0
    :voice-amp 7d0
    :voice-pluck 0.0526316d0
    :voice-freq 34d0
    :voice-env 0.0011111d0
    :bend-amp 9d0
    :bend-decay 0.14d0
    :bend-freq 46d0
    :bend-spread 260d0
    :fill-delay 0.12d0
    :fill-duration 0.32d0
    :drain-duration 0.2d0
    :enter-duration 0.38d0
    :enter-settle 0.45d0
    :exit-duration 0.22d0
    :pulse-duration 0.45d0
    :focus-settle-delay 1.2d0
    :trail (:cell 4d0 :life 0.16d0 :steps 3 :shape :dots :dark :ink :light :ink)))

(defun thread-design--mode (mode)
  (getf +thread-design--modes+ mode (getf +thread-design--modes+ :dark)))

(defun thread-design--token (mode key &optional default)
  (getf (thread-design--mode mode) key default))

(defun thread-design--geom (key &optional default)
  (getf +thread-design--geometry+ key default))

(defun thread-design--type (key &optional default)
  (getf +thread-design--type+ key default))

(defun thread-design--motion (key &optional default)
  (getf +thread-design--motion+ key default))

(defun thread-design--clamp (value lo hi)
  (max lo (min hi value)))

(defun thread-design--hex2 (n)
  (let* ((v (thread-design--clamp (round n) 0 255))
         (digits "0123456789ABCDEF")
         (hi (floor v 16))
         (lo (mod v 16)))
    (format nil "~A~A" (subseq digits hi (1+ hi)) (subseq digits lo (1+ lo)))))

(defun thread-design--hex->rgba (hex &optional (alpha 1d0))
  (let* ((has-alpha (>= (length hex) 9))
         (a (if has-alpha
                (* alpha (/ (parse-integer hex :start 7 :end 9 :radix 16) 255d0))
                (coerce alpha 'double-float))))
    (append (loop for i from 1 below 7 by 2
                  collect (/ (parse-integer hex :start i :end (+ i 2) :radix 16) 255d0))
            (list a))))

(defun thread-design--hex-with-alpha (hex factor)
  (let* ((base (if (>= (length hex) 9)
                   (parse-integer hex :start 7 :end 9 :radix 16)
                   255))
         (scaled (thread-design--clamp (round (* base factor)) 0 255)))
    (format nil "~A~A" (subseq hex 0 7) (thread-design--hex2 scaled))))

(defun thread-design--palette (ink)
  (loop for (key . colour) in +thread-design--palette+
        collect (cons key (if (eq colour :ink) ink colour))))

(defun thread-design--rim-numbers ()
  (list (coerce (thread-design--geom :thread-half-width) 'double-float)
        (coerce (thread-design--geom :rim-width) 'double-float)
        (coerce (thread-design--geom :weld-radius) 'double-float)
        (coerce (thread-design--geom :weld-spread) 'double-float)
        (coerce (thread-design--geom :card-radius) 'double-float)
        (coerce (thread-design--motion :voice-speed) 'double-float)
        (coerce (thread-design--motion :voice-amp) 'double-float)
        (coerce (thread-design--motion :voice-pluck) 'double-float)
        (coerce (thread-design--motion :voice-freq) 'double-float)
        (coerce (thread-design--motion :voice-env) 'double-float)
        (coerce (thread-design--motion :bend-amp) 'double-float)
        (coerce (thread-design--motion :bend-decay) 'double-float)
        (coerce (thread-design--motion :bend-freq) 'double-float)
        (coerce (thread-design--motion :bend-spread) 'double-float)
        (coerce (thread-design--motion :fill-delay) 'double-float)
        (coerce (thread-design--motion :fill-duration) 'double-float)
        (coerce (thread-design--motion :drain-duration) 'double-float)))

(defun thread-design--hint-look (mode &key (rim-width (thread-design--geom :plate-rim-width))
                                        (radius (thread-design--geom :plate-radius))
                                        (font (thread-design--type :font))
                                        (size (thread-design--type :hint-size))
                                        (padding (thread-design--geom :padding))
                                        (margin (thread-design--geom :margin))
                                        (blur t))
  (let ((cast (thread-design--mode mode)))
    (list :ink (getf cast :ink)
          :plate (getf cast :plate)
          :rim (getf cast :rim)
          :key (getf cast :key)
          :rim-width rim-width
          :radius radius
          :font font
          :size size
          :padding padding
          :margin margin
          :blur blur)))

(defun thread-design--text (text &key (mode :dark) (role :ink) size line-height font color (alpha 1d0))
  (let* ((base-color (or color (thread-design--token mode role (thread-design--token mode :ink))))
         (final-color (if (< alpha 0.999d0)
                          (thread-design--hex-with-alpha base-color alpha)
                          base-color))
         (resolved-size (or size (thread-design--type :body-size)))
         (resolved-font (or font (thread-design--type :font))))
    (if line-height
        (ui :text :text text :size resolved-size :line-height line-height
            :font resolved-font :color final-color)
        (ui :text :text text :size resolved-size
            :font resolved-font :color final-color))))

(defun thread-design--bead-dot (&key (mode :dark) (size 6) color (alpha 1d0))
  (let* ((base (or color (thread-design--token mode :accent)))
         (fill (if (< alpha 0.999d0)
                   (thread-design--hex-with-alpha base alpha)
                   base)))
    (ui :rect :width size :height size :radius (/ size 2d0) :background fill)))

(defun thread-design--pill (label &key (mode :dark) color background (alpha 1d0))
  (let* ((fg (or color (thread-design--token mode :ink)))
         (bg (or background (thread-design--token mode :key)))
         (fg-a (if (< alpha 0.999d0) (thread-design--hex-with-alpha fg alpha) fg))
         (bg-a (if (< alpha 0.999d0) (thread-design--hex-with-alpha bg alpha) bg)))
    (ui :row :align :center :padding '(1 6 1 6) :radius 6 :background bg-a
        :children (list (thread-design--text label :mode mode
                                             :size 10 :line-height 13 :color fg-a)))))

(defun thread-design--plate (children &key (mode :dark) width (padding (thread-design--geom :padding))
                                        (gap 4) (radius (thread-design--geom :plate-radius))
                                        (rim-width (thread-design--geom :plate-rim-width))
                                        background rim-color on-click)
  (let* ((cast (thread-design--mode mode))
         (outer-bg (or rim-color (getf cast :rim)))
         (inner-bg (or background (getf cast :plate)))
         (inner-radius (max 0 (- radius rim-width)))
         (inner (append (list :column :padding padding :gap gap
                              :background inner-bg :radius inner-radius
                              :children children)
                        (when width (list :width width))))
         (outer (append (list :column :padding rim-width :background outer-bg
                              :radius radius :children (list (apply #'ui inner)))
                        (when on-click (list :on-click on-click)))))
    (apply #'ui outer)))

(defun thread-design--now ()
  (/ (float (get-internal-real-time) 1d0) internal-time-units-per-second))

(defun thread-design--epoch (now)
  (* 256 (floor now 256)))

(defun thread-design--output-scale (output)
  (if output (max 1/4 (/ (getf output :scale-120 120) 120)) 1))

(defun thread-design--output-at (outputs x y)
  (find-if (lambda (output)
             (and (<= (getf output :x) x (+ (getf output :x) (getf output :width)))
                  (<= (getf output :y) y (+ (getf output :y) (getf output :height)))))
           outputs))
