(in-package #:tomoe-user)

(defun window-shader--output (outputs x y)
  (find-if (lambda (output)
             (and (<= (getf output :x) x (+ (getf output :x) (getf output :width) -1))
                  (<= (getf output :y) y (+ (getf output :y) (getf output :height) -1))))
           outputs))

(define-extension "window-shader" (:reads (:key :focus :outputs :window-geometry) :state nil) (snapshot state event)
  (when (and (equal (getf event :owner) "window-shader")
             (equal (getf event :command) "toggle"))
    (setf state (not state)))
  (let* ((focus (context snapshot :focus))
         (geometry (and focus (window-geometry snapshot focus)))
         (output (and geometry
                      (window-shader--output (context snapshot :outputs)
                                             (getf geometry :x) (getf geometry :y))))
         (surface
           (when (and state geometry output)
             (let ((scale (/ (getf output :scale-120 120) 120)))
               (shell-surface :window-shader (ui :stack)
                              :anchors '(:top :left)
                              :margin (list (/ (- (getf geometry :y) (getf output :y)) scale)
                                            0 0
                                            (/ (- (getf geometry :x) (getf output :x)) scale))
                              :width (/ (getf geometry :width) scale)
                              :height (/ (getf geometry :height) scale)
                              :layer :overlay
                              :click-through t
                              :background (list :shader (getf +window-shader+ :shader)
                                                :fps (getf +window-shader+ :fps)))))))
    (values state
            (remove nil (list (apply #'bind-key (getf +window-shader+ :bind)) surface))
            nil)))
