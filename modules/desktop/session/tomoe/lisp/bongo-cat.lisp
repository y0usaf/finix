(in-package #:tomoe-user)

(defun bongo-cat--frame (left right)
  (format nil "~A/bongo-cat-~A.png" (getf +bongo-cat+ :frames)
          (cond ((and left right) "both-down") (left "left-down") (right "right-down") (t "both-up"))))

(defun bongo-cat--toggle (tag a b) (if (eq tag a) b a))

(defun bongo-cat--bob (glyphs frame left gap strip)
  (ui :row :height strip :gap gap :align :start :padding (list 0 0 0 left)
      :children (loop for (text size color) in glyphs
                      for i from 0
                      collect (ui :column :height strip
                                  :padding (list (* 4 (mod (+ frame i) 3)) 0 0 0)
                                  :children (list (hud--text text size color))))))

(define-extension "bongo-cat" (:reads (:activity :services :data)
                               :state (list :left nil :right nil :idle :idle-a :sleeping nil :frame 0))
    (snapshot state event)
  (unless (getf state :idle) (setf (getf state :idle) :idle-a))
  (unless (getf state :frame) (setf (getf state :frame) 0))
  (let ((name (getf event :name)))
    (case (getf event :type)
      (:activity
       (if (equal (getf event :hand) "left")
           (setf (getf state :left) (bongo-cat--toggle (getf state :left) :left-a :left-b))
           (setf (getf state :right) (bongo-cat--toggle (getf state :right) :right-a :right-b)))
       (setf (getf state :idle) (bongo-cat--toggle (getf state :idle) :idle-a :idle-b)
             (getf state :sleeping) nil))
      (:timer
       (when (eq name (getf state :left)) (setf (getf state :left) nil))
       (when (eq name (getf state :right)) (setf (getf state :right) nil))
       (when (eq name (getf state :idle)) (setf (getf state :sleeping) t))
       (when (eq name :groove) (incf (getf state :frame))))))
  (let* ((p (state-value snapshot :hud-palette))
         (focal (state-value snapshot :focal-frame))
         (hot (state-value snapshot :hud-hot))
         (playing (equal (getf (service-state snapshot :mpris) :status) "Playing"))
         (frame (getf state :frame))
         (sleepy (and (getf state :sleeping) (not playing)))
         (groove (and playing (not sleepy)
                      (not (getf state :left)) (not (getf state :right))))
         (left (if groove (evenp frame) (getf state :left)))
         (right (if groove (oddp frame) (getf state :right)))
         (height (getf +bongo-cat+ :height))
         (width (round (* height 864) 360))
         (unit (/ width 192))
         (strip (getf +bongo-cat+ :strip))
         (offset (getf +bongo-cat+ :x-offset))
         (overlay (cond (sleepy (bongo-cat--bob (list (list "z" 10 (hud--c p :fg)) (list "Z" 13 (hud--c p :color4))
                                                      (list "z" 16 (hud--c p :color5)))
                                                frame (round (* 118 unit)) 3 strip))
                        (playing (bongo-cat--bob (list (list "♪" 16 (hud--c p :color5)) (list "♫" 18 (hud--c p :color6))
                                                       (list "♪" 14 (hud--c p :color3)))
                                                 frame (round (* 26 unit)) 10 strip))
                        (t (ui :row :height strip))))
         (cat (ui :stack :width width :height height
                  :children (append (list (ui :image :src (bongo-cat--frame left right) :width width :height height))
                                    (when hot
                                      (list (ui :row :width width :height height
                                                :padding (list (round (* 8 unit)) 0 0 (round (* 146 unit)))
                                                :children (list (hud--text "💦" 15 (hud--c p :fg) (getf +hud+ :emoji-font))))))))))
    (values state
            (append (loop for paw in (list (getf state :left) (getf state :right))
                          when paw collect (once paw (getf +bongo-cat+ :duration)))
                    (unless (getf state :sleeping) (list (once (getf state :idle) (getf +bongo-cat+ :idle))))
                    (when (or groove sleepy) (list (interval :groove (getf +bongo-cat+ :groove))))
                    (list (shell-surface :bongo-cat
                                         (ui :row :width (+ width (abs offset)) :height (+ strip height)
                                             :justify (if (minusp offset) :end :start)
                                             :children (list (ui :column :width width :height (+ strip height)
                                                                 :children (list (ui :column :height strip
                                                                                     :children (list overlay))
                                                                                 cat))))
                                         :output (getf focal :output)
                                         :anchors (if focal '(:top) '(:bottom))
                                         :margin (if focal
                                                     (list (- (+ (getf focal :top) (getf focal :height)) 6 strip height) 0 0 0)
                                                     (list 0 0 (getf +bongo-cat+ :margin-bottom) 0))
                                         :layer :overlay :background "#00000000" :click-through t)))
            nil)))
