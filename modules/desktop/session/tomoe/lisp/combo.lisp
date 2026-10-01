(in-package #:tomoe-user)

(defun combo--hand (streak)
  (find-if (lambda (hand) (>= streak (first hand))) (getf +combo+ :hands)))

(defun combo--wpm (keys start now)
  (let* ((window (max 1d0 (min 4d0 (- now (or start now)))))
         (count (count-if (lambda (at) (<= (- now at) window)) keys)))
    (round (* (/ count window) 12))))

(defun combo--box (p text color size)
  (ui :row :padding '(1 7 1 7) :background color
      :children (list (hud--text text size (hud--c p :color15)))))

(defun combo--panel (p state now)
  (let ((streak (getf state :streak)) (fg (hud--c p :fg)))
    (cond
      ((>= streak (getf +combo+ :show))
       (let* ((hand (combo--hand streak))
              (color (hud--c p (fourth hand)))
              (tier (hud--decay (getf state :tier-at) (getf +combo+ :shake)))
              (pop (hud--decay (getf state :last-key) (getf +combo+ :pop)))
              (left (max 0 (- 1 (/ (hud--since (getf state :last-key)) (getf +combo+ :window)))))
              (mult (third hand))
              (drain (getf +combo+ :drain-width)))
         (hud--frame p color tier
                     (ui :column :gap 4 :padding '(5 10 6 8)
                         :children (list (ui :row :gap 8 :align :end
                                             :children (list (hud--text (second hand) 13 (hud--mix color fg tier))
                                                             (hud--text (format nil "~D WPM" (combo--wpm (getf state :keys) (getf state :start) now))
                                                                        11 (hud--dim p))))
                                         (ui :row :gap 6 :align :center :height 30
                                             :children (append (list (combo--box p (format nil "~D" streak) (hud--c p :color6)
                                                                                 (round (+ 16 (* 5 pop))))
                                                                     (hud--text "X" 14 (hud--c p :color1))
                                                                     (combo--box p (format nil "~D" mult)
                                                                                 (hud--mix (hud--c p :color1) fg tier) 16))
                                                               (when (>= mult (getf +combo+ :fire))
                                                                 (list (hud--text "🔥" (round (+ 15 (sin (* now 20)))) fg
                                                                                  (getf +hud+ :emoji-font))))))
                                         (ui :row :height 2 :width drain :background (hud--off p)
                                             :children (list (ui :rect :width (round (* drain left)) :height 2
                                                                 :background color))))))))
      ((getf state :cash)
       (let* ((roll (getf +combo+ :roll))
              (f (min 1 (/ (hud--since (getf state :cash-at)) roll)))
              (eased (- 1 (expt (- 1 f) 3)))
              (color (hud--c p :color3))
              (landed (hud--decay (when (>= f 1) (+ (getf state :cash-at) (/ roll 1000))) 300)))
         (hud--frame p color landed
                     (ui :column :gap 2 :padding '(5 10 6 8)
                         :children (list (ui :row :gap 8 :align :end
                                             :children (list (hud--text (getf state :cash-hand) 13 (hud--dim p))
                                                             (hud--text (format nil "~D X ~D" (getf state :cash-chips)
                                                                                (getf state :cash-mult))
                                                                        11 (hud--dim p))))
                                         (hud--text (format nil "+~:D" (round (* eased (getf state :cash)))) 24
                                                    (hud--mix fg color eased))))))))))

(define-extension "combo" (:reads (:activity :data)
                           :state (list :streak 0 :start nil :last-key nil :keys nil :tier-at nil
                                        :cash nil :cash-at nil :cash-hand nil :cash-chips 0 :cash-mult 1))
    (snapshot state event)
  (let ((now (hud--now)))
    (when (eq (getf event :type) :activity)
      (let ((before (combo--hand (getf state :streak)))
            (stamps (cons now (getf state :keys))))
        (when (zerop (getf state :streak)) (setf (getf state :start) now))
        (incf (getf state :streak))
        (setf (getf state :last-key) now
              (getf state :keys) (subseq stamps 0 (min 64 (length stamps)))
              (getf state :cash) nil)
        (unless (eq before (combo--hand (getf state :streak)))
          (setf (getf state :tier-at) now))))
    (when (and (plusp (getf state :streak)) (> (hud--since (getf state :last-key)) (getf +combo+ :window)))
      (let* ((streak (getf state :streak)) (hand (combo--hand streak)))
        (when (>= streak (getf +combo+ :cash-min))
          (setf (getf state :cash) (* streak (third hand)) (getf state :cash-at) now
                (getf state :cash-hand) (second hand) (getf state :cash-chips) streak
                (getf state :cash-mult) (third hand)))
        (setf (getf state :streak) 0 (getf state :start) nil)))
    (when (and (getf state :cash) (> (hud--since (getf state :cash-at)) (getf +combo+ :hold)))
      (setf (getf state :cash) nil))
    (let* ((p (state-value snapshot :hud-palette))
           (panel (combo--panel p state now))
           (since-tier (hud--since (getf state :tier-at)))
           (shake-ms (getf +combo+ :shake))
           (shake (if (< since-tier shake-ms)
                      (round (* 4 (- 1 (/ since-tier shake-ms)) (sin (/ since-tier 18))))
                      0))
           (offset (getf +combo+ :offset))
           (side (getf +combo+ :side)))
      (values state
              (append (when (or (plusp (getf state :streak)) (getf state :cash) (< since-tier shake-ms))
                        (list (interval :tick (getf +combo+ :tick))))
                      (list (publish-state :combo (list :active (plusp (getf state :streak))
                                                        :tier-at (getf state :tier-at))))
                      (when panel
                        (list (shell-surface :combo
                                             (ui :row :children (list (ui :row :width (+ offset side))
                                                                      (ui :row :width (+ offset side)
                                                                          :padding (list 0 0 0 (+ offset shake))
                                                                          :children (list panel))))
                                             :anchors '(:bottom) :margin (list 0 0 (getf +combo+ :lift) 0)
                                             :layer :overlay :background "#00000000" :click-through t))))
              nil))))
