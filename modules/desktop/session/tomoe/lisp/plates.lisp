(in-package #:tomoe-user)

(defun cassette--groove ()
  (ui :row :children (list (ui :rect :width 1 :height (cassette--px 10) :background (cassette--c :groove))
                           (ui :rect :width 1 :height (cassette--px 10) :background (cassette--c :shine)))))

(defun cassette--plate (items grille edge)
  (let* ((parts (loop for (item . rest) on (remove nil items)
                      collect (ui :row :gap (cassette--px 4) :align :center :children (remove nil item))
                      when rest collect (cassette--groove)))
         (body (ui :row :height (cassette--px 16) :align :center :gap (cassette--px 6)
                   :padding (list 0 (cassette--px 6) 0 (cassette--px 6))
                   :children (append (when (member grille '(:start :both)) (list (cassette--grille)))
                                     parts
                                     (when (member grille '(:end :both)) (list (cassette--grille)))))))
    (when parts
      (let ((plate (ui :column :align :stretch :background (cassette--c :face) :border 1 :border-color (cassette--c :ink)
                       :children (list (ui :rect :height 1 :background (cassette--c :shine))
                                       body
                                       (ui :rect :height 1 :background (cassette--c :shade))))))
        (if (eq edge :top)
            (ui :column :align :stretch
                :children (list plate (ui :row :height (cassette--shadow) :padding (list 0 0 0 (cassette--shadow))
                                          :children (list (ui :rect :grow 1 :height (cassette--shadow) :background (cassette--c :shadow))))))
            plate)))))

(defun cassette--line (items edge)
  (let* ((modules (getf +cassette+ :modules))
         (pair (getf +cassette+ :center-between))
         (inset (getf +cassette+ :inset))
         (seam (loop for (a b) on modules
                     for index from 1
                     when (and b (eq a (first pair)) (eq b (second pair))) return index)))
    (flet ((half (plate justify padding)
             (ui :row :width 0 :grow 1 :justify justify :padding padding :children (remove nil (list plate)))))
      (ui :row :align :start :justify :center
          :children (if seam
                        (list (half (cassette--plate (subseq items 0 seam) :start edge) :end (list 0 inset 0 0))
                              (half (cassette--plate (nthcdr seam items) :end edge) :start (list 0 0 0 inset)))
                        (remove nil (list (cassette--plate items :both edge))))))))

(defun cassette--shadow () (cassette--px 2))

(defun cassette--height (edge) (+ (cassette--px 16) 4 (if (eq edge :top) (cassette--shadow) 0)))

(define-extension "bar" (:reads (:system :services :data :outputs)
                         :state (list :cpu nil :memory nil :gpu nil))
    (snapshot state event)
  (when (and (eq (getf event :type) :timer) (eq (getf event :name) :sample))
    (let ((system (context snapshot :system)))
      (dolist (probe '(:cpu :memory :gpu))
        (setf (getf state probe) (probe--sample probe (getf state probe) system)))))
  (let* ((items (loop for module in (getf +cassette+ :modules)
                      collect (cassette--module module state snapshot)))
         (focal (state-value snapshot :focal-frame))
         (wide (first (sort (copy-list (context snapshot :outputs)) #'> :key (lambda (o) (getf o :width)))))
         (height (cassette--height :bottom))
         (hot (loop for probe in '(:cpu :gpu) thereis (cassette--hot-p (getf (getf state probe) :temp)))))
    (values state
            (append (list (interval :sample (getf +cassette+ :sample))
                          (publish-state :hud-hot (and hot t))
                          (publish-state :bar-floor
                                         (when (member :bottom (getf +cassette+ :edges))
                                           (cond (focal (list :output (getf focal :output)
                                                              :y (+ (getf focal :top) (getf focal :height) (round height 2))))
                                                 (wide (list :output (getf wide :name) :y (getf wide :height)))))))
                    (loop for edge in (getf +cassette+ :edges)
                          for line = (cassette--line items edge)
                          for height = (cassette--height edge)
                          collect (if focal
                                      (shell-surface edge line :output (getf focal :output) :anchors '(:top :left)
                                                     :width (getf focal :width) :height height
                                                     :margin (list (- (if (eq edge :top)
                                                                          (getf focal :top)
                                                                          (+ (getf focal :top) (getf focal :height)))
                                                                      (round height 2))
                                                                   0 0 (getf focal :left))
                                                     :layer :overlay :background "#00000000" :click-through t)
                                      (shell-surface edge line :output (getf wide :name) :anchors (list edge :left :right)
                                                     :height height :margin (if (eq edge :top) '(-1 0 0 0) '(0 0 -1 0))
                                                     :exclusive-zone (if (getf +cassette+ :exclusive) (- (cassette--height :bottom) 1) 0)
                                                     :layer :overlay :background "#00000000" :click-through t))))
            nil)))
