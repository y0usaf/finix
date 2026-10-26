(in-package #:tomoe-user)

(defun glass--margin (passes offset)
  (min 4096 (truncate (* (expt 2 passes) (+ offset 2)))))

(define-extension "glass" (:reads (:windows) :state nil) (snapshot state event)
  (declare (ignore event))
  (values state
          (cons (settings :blur (list* :enabled t
                                       :anti-artifact-margin
                                       (glass--margin (getf +glass+ :passes) (getf +glass+ :offset))
                                       +glass+))
                (loop for window in (context snapshot :windows)
                      collect (window-properties (getf window :id) :blur t)))
          nil))
