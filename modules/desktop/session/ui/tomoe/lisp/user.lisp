(in-package #:tomoe-user)

(define-extension "user" (:reads (:key :focus) :state nil) (snapshot state event)
  (declare (ignore state))
  (let ((command (when (and (eq (getf event :type) :key)
                            (equal (getf event :owner) "user"))
                   (getf event :command)))
        (focused (context snapshot :focus)))
    (values nil
            (mapcar (lambda (binding) (apply #'bind-key binding)) +policy-bindings+)
            (cond
              ((null command) nil)
              ((equal command "close") (when focused (list (close-window focused))))
              ((equal command "quit") (list (quit)))
              ((equal command "power") (list (output-power :toggle)))
              ((equal command "screenshot") (list (screenshot)))
              ((equal command "screenshot-screen") (list (screenshot :screen)))
              (t
               (let ((argv (policy--launch command)))
                 (when argv (list (apply #'launch argv)))))))))
