(in-package #:tomoe-user)

(defun bongo-cat--frame (left right)
  (format nil "~A/bongo-cat-~A.png" (getf +bongo-cat+ :frames)
          (cond ((and left right) "both-down") (left "left-down") (right "right-down") (t "both-up"))))

(define-extension "bongo-cat" (:reads (:activity) :state (list :left nil :right nil))
    (snapshot state event)
  (declare (ignore snapshot))
  (destructuring-bind (&key left right &allow-other-keys) state
    (case (getf event :type)
      (:activity
       (if (equal (getf event :hand) "left")
           (setf left (if (eq left :left-a) :left-b :left-a))
           (setf right (if (eq right :right-a) :right-b :right-a))))
      (:timer
       (when (eq (getf event :name) left) (setf left nil))
       (when (eq (getf event :name) right) (setf right nil))))
    (let* ((height (getf +bongo-cat+ :height))
           (width (round (* height 864) 360))
           (offset (getf +bongo-cat+ :x-offset)))
      (values (list :left left :right right)
              (append (loop for paw in (list left right)
                            when paw collect (once paw (getf +bongo-cat+ :duration)))
                      (list (shell-surface :bongo-cat
                                           (ui :row :width (+ width (abs offset)) :height height
                                               :justify (if (minusp offset) :end :start)
                                               :children (list (ui :image :src (bongo-cat--frame left right)
                                                                   :width width :height height)))
                                           :anchors '(:bottom)
                                           :margin (list 0 0 (getf +bongo-cat+ :margin-bottom) 0)
                                           :layer :overlay :background "#00000000")))
              nil))))
