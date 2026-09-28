(in-package #:tomoe-user)

(define-extension "shader-wallpaper" (:reads (:key :ui) :state nil) (snapshot state event)
  (declare (ignore snapshot))
  (let* ((shaders (getf +shader-wallpaper+ :shaders))
         (count (length shaders)))
    (destructuring-bind (&key (index 0) menu) (and (listp state) state)
      (when (equal (getf event :owner) "shader-wallpaper")
        (if (equal (getf event :command) "menu")
            (setf menu index)
            (multiple-value-bind (action choice) (and menu (menu-choice event menu count))
              (case action
                (:select (setf index choice menu nil))
                (:cancel (setf menu nil))
                (:move (setf menu choice))))))
      (setf index (mod index count) menu (and menu (mod menu count)))
      (destructuring-bind (path fps) (rest (nth (or menu index) shaders))
        (values (list :index index :menu menu)
                (list* (apply #'bind-key (getf +shader-wallpaper+ :bind))
                       (shell-surface :shader-wallpaper (ui :stack)
                                      :anchors '(:top :right :bottom :left) :layer :background
                                      :background (list :shader path :fps fps))
                       (when menu
                         (menu-dialog :shader-wallpaper-menu (mapcar #'first shaders) menu
                                      :title "Wallpaper")))
                nil)))))
