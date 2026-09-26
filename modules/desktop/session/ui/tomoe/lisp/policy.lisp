(in-package #:tomoe-user)

(defun policy--prefix-p (prefix text)
  (and (stringp text) (>= (length text) (length prefix))
       (string= prefix text :end2 (length prefix))))

(defun policy--launch (command)
  (second (assoc command +policy-launches+ :test #'equal)))

(defun policy--terminal (windows)
  (getf (find-if (lambda (window)
                   (or (equal (getf window :app-id) (getf +policy-terminal+ :app-id))
                       (policy--prefix-p (getf +policy-terminal+ :title-prefix) (getf window :title))))
                 windows)
        :id))

(defun policy--unmanaged-p (snapshot window)
  (let ((properties (rules-for snapshot window)))
    (or (cdr (assoc :float properties)) (cdr (assoc :hidden properties)))))

(defun policy--area (snapshot &optional name)
  (let ((areas (context snapshot :workareas)))
    (or (find name areas :test #'equal :key (lambda (area) (getf area :name)))
        (first areas))))

(defun policy--centred (area ratio)
  (let ((width (max 1 (floor (* (getf area :width) ratio))))
        (height (max 1 (floor (* (getf area :height) ratio)))))
    (list (+ (getf area :x) (floor (- (getf area :width) width) 2))
          (+ (getf area :y) (floor (- (getf area :height) height) 2))
          width height)))

(define-extension "session" () (snapshot state event)
  (declare (ignore snapshot event))
  (values state
          (append (mapcar (lambda (display) (apply #'configure-output display)) +policy-displays+)
                  (list (apply #'settings +policy-settings+)
                        (run-once :wallpaper +policy-wallpaper+)))
          nil))

(define-extension "rules" () (snapshot state event)
  (declare (ignore snapshot event))
  (values state
          (list (window-rule :launcher :app-id (getf +policy-launcher+ :app-id)
                             :properties '((:float . t)) :reads '(:workareas)
                             :apply (lambda (window snapshot state event)
                                      (declare (ignore event))
                                      (let ((id (getf window :id))
                                            (area (policy--area snapshot)))
                                        (values state
                                                (append (when area
                                                          (list (apply #'place id (policy--centred
                                                                                   area (getf +policy-launcher+ :ratio)))))
                                                        (list (focus id)))
                                                nil))))
                (window-rule :hidden :app-id (getf +policy-hidden-window+ :app-id)
                             :match (lambda (window snapshot)
                                      (declare (ignore snapshot))
                                      (policy--prefix-p (getf +policy-hidden-window+ :title-prefix)
                                                        (getf window :title)))
                             :properties '((:hidden . t))
                             :apply (lambda (window snapshot state event)
                                      (declare (ignore snapshot event))
                                      (values state (list (hide-window (getf window :id))) nil))))
          nil))
