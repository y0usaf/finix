(in-package #:tomoe-user)

(define-extension "shader-wallpaper" (:reads (:key) :state 0) (snapshot index event)
  (declare (ignore snapshot))
  (let ((shaders (getf +shader-wallpaper+ :shaders)))
    (when (and (eq (getf event :type) :key) (equal (getf event :owner) "shader-wallpaper"))
      (incf index))
    (setf index (mod index (length shaders)))
    (destructuring-bind (path fps) (nth index shaders)
      (values index
              (list (apply #'bind-key (getf +shader-wallpaper+ :bind))
                    (shell-surface :shader-wallpaper (ui :stack)
                                   :anchors '(:top :right :bottom :left) :layer :background
                                   :background (list :shader path :fps fps)))
              nil))))
