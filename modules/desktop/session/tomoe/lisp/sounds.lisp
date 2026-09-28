(in-package #:tomoe-user)

(define-extension "sounds" () (snapshot state event)
  (declare (ignore snapshot event))
  (values state
          (list (sound :key (getf +sounds+ :key) :gain (getf +sounds+ :key-gain)
                       :spread (getf +sounds+ :key-spread))
                (sound :close (getf +sounds+ :close) :gain (getf +sounds+ :close-gain)))
          nil))
