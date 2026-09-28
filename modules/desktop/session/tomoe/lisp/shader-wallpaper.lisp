(in-package #:tomoe-user)

(defun shader-wallpaper--menu (shaders chosen outputs)
  (destructuring-bind (&key width height gap border) (getf +shader-wallpaper+ :preview)
    (let ((count (length shaders)))
      (list* (shell-surface :shader-menu (ui :column :on-click :cancel :background "#00000066")
                            :anchors '(:top :right :bottom :left) :layer :overlay
                            :background "#00000000")
             (keyboard-grab)
             (bind-key nil "Left" :up) (bind-key nil "h" :up)
             (bind-key nil "Right" :down) (bind-key nil "l" :down)
             (bind-key nil "Return" :select) (bind-key nil "Escape" :cancel)
             (loop for output in outputs
                   for scale = (getf output :scale-120 120)
                   for output-width = (floor (* (getf output :width) 120) scale)
                   for output-height = (floor (* (getf output :height) 120) scale)
                   for tile-width = (min width (floor (- output-width (* (1+ count) gap)) count))
                   for tile-height = (floor (* height tile-width) width)
                   for left = (floor (- output-width (- (* count (+ tile-width gap)) gap)) 2)
                   for top = (floor (- output-height tile-height) 2)
                   nconc (loop for (path fps) in shaders
                               for index from 0
                               collect (shell-surface
                                        (intern (format nil "SHADER-PREVIEW-~A-~D" (getf output :name) index)
                                                :keyword)
                                        (ui :stack :width tile-width :height tile-height
                                            :border (if (= index chosen) border 0)
                                            :border-color (theme :accent)
                                            :on-click (intern (format nil "SELECT-~D" index) :keyword)
                                            :on-hover (intern (format nil "HOVER-~D" index) :keyword))
                                        :output (getf output :name) :anchors '(:top :left)
                                        :margin (list top 0 0 (+ left (* index (+ tile-width gap))))
                                        :width tile-width :height tile-height :layer :overlay
                                        :background (list :shader path :fps fps))))))))

(define-extension "shader-wallpaper" (:reads (:key :ui :outputs) :state nil) (snapshot state event)
  (let* ((shaders (getf +shader-wallpaper+ :shaders))
         (count (length shaders)))
    (destructuring-bind (&key (index 0) menu) state
      (when (equal (getf event :owner) "shader-wallpaper")
        (if (equal (getf event :command) "menu")
            (setf menu index)
            (multiple-value-bind (action choice) (and menu (menu-choice event menu count))
              (case action
                (:select (setf index choice menu nil))
                (:cancel (setf menu nil))
                (:move (setf menu choice))))))
      (setf index (mod index count) menu (and menu (mod menu count)))
      (destructuring-bind (path fps) (nth (or menu index) shaders)
        (values (list :index index :menu menu)
                (list* (apply #'bind-key (getf +shader-wallpaper+ :bind))
                       (shell-surface :shader-wallpaper (ui :stack)
                                      :anchors '(:top :right :bottom :left) :layer :background
                                      :background (list :shader path :fps fps))
                       (when menu (shader-wallpaper--menu shaders menu (context snapshot :outputs))))
                nil)))))
