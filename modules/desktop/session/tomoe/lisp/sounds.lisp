(in-package #:tomoe-user)

(define-extension "sounds" () (snapshot state event)
  (declare (ignore snapshot event))
  (values state
          (list (sound :key (getf +sounds+ :key) :gain (getf +sounds+ :key-gain))
                (sound :button (getf +sounds+ :button) :gain (getf +sounds+ :button-gain))
                (sound :close (getf +sounds+ :close) :gain (getf +sounds+ :close-gain)))
          nil))
