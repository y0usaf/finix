(in-package #:tomoe-user)

(define-extension "peek" (:reads (:key :windows) :state nil) (snapshot hidden event)
  (let ((live (mapcar (lambda (window) (getf window :id)) (context snapshot :windows))))
    (setf hidden (cond ((and (eq (getf event :type) :key) (equal (getf event :owner) "peek"))
                        (unless hidden live))
                       ((subsetp live hidden) (intersection hidden live))))
    (values hidden
            (list* (apply #'bind-key (getf +peek+ :bind))
                   (when hidden (cons (focus nil) (mapcar #'hide-window hidden))))
            nil)))
