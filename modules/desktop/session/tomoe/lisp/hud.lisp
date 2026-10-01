(in-package #:tomoe-user)

(defun hud--now ()
  (/ (float (get-internal-real-time) 1d0) internal-time-units-per-second))

(defun hud--since (at)
  (if at (* 1000 (- (hud--now) at)) most-positive-fixnum))

(defun hud--decay (at ms)
  (let ((elapsed (hud--since at)))
    (if (< elapsed ms) (- 1 (/ elapsed ms)) 0)))

(defun hud--c (p key)
  (or (getf p key)
      (theme (case key
               (:bg :base) ((:fg :color15) :text) (:color1 :red) (:color2 :green) (:color3 :yellow)
               (:color4 :blue) (:color5 :mauve) (:color6 :sky) (:color8 :surface2) (t :accent)))))

(defun hud--hex2 (n) (format nil "~2,'0X" (max 0 (min 255 (round n)))))

(defun hud--alpha (hex aa) (if (= (length hex) 7) (concatenate 'string hex aa) hex))

(defun hud--fade (hex fraction) (hud--alpha hex (hud--hex2 (* 255 fraction))))

(defun hud--mix (a b f)
  (cond ((<= f 0) a)
        ((and (= (length a) 7) (= (length b) 7))
         (format nil "#~{~A~}"
                 (loop for i from 1 by 2 repeat 3
                       collect (hud--hex2 (+ (* (- 1 f) (parse-integer a :start i :end (+ i 2) :radix 16))
                                             (* f (parse-integer b :start i :end (+ i 2) :radix 16)))))))
        (t b)))

(defun hud--text (text size color &optional (font (getf +hud+ :font)))
  (ui :text :text text :size size :color color :font font))

(defun hud--icon (code size color)
  (hud--text (string (code-char code)) size color (getf +hud+ :icon-font)))

(defun hud--dim (p &optional (fraction 0.6)) (hud--fade (hud--c p :fg) fraction))

(defun hud--off (p) (hud--mix (hud--c p :bg) (hud--c p :fg) 0.14))

(defun hud--heat (percent accent p)
  (cond ((>= percent 90) (hud--c p :color1)) ((>= percent 70) (hud--c p :color3)) (t accent)))

(defun hud--frame (p accent flash content &key height)
  (let* ((s (getf +hud+ :shadow))
         (edge (hud--mix accent (hud--c p :fg) flash))
         (body (ui :row :height height :align :stretch
                   :background (hud--alpha (hud--c p :bg) "eb")
                   :border 1 :border-color (hud--alpha edge (if (plusp flash) "ff" "b3"))
                   :children (list (ui :rect :width 3 :background edge) content))))
    (ui :stack :children (list (ui :row :padding (list s 0 0 s) :align :stretch
                                   :children (list (ui :rect :grow 1 :background (hud--mix (hud--c p :bg) edge 0.6))))
                               (ui :row :padding (list 0 s s 0) :children (list body))))))

(defun hud--panel (p accent children &key (flash 0))
  (hud--frame p accent flash (ui :row :align :center :gap 8 :padding '(0 10 0 8) :children children)
              :height (getf +hud+ :height)))
