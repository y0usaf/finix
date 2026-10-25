(in-package #:tomoe-user)

(define-extension "glass" (:reads (:windows) :state nil) (snapshot state event)
  (declare (ignore event))
  (values state
          (cons (settings :blur (list* :enabled t +glass+))
                (loop for window in (context snapshot :windows)
                      collect (window-properties (getf window :id) :blur t)))
          nil))
