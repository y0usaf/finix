(in-package #:tomoe-user)

(defparameter +screenshot-thread--modes+
  '(:dark (:veil (0.02d0 0.025d0 0.03d0 0.5d0) :shine (1 1 1 0.55d0)
           :line (0 0 0 0.6d0) :tint (0.85d0 0.88d0 0.95d0 0.08d0)
           :hint (:ink "#ECE7DC" :plate "#111318C8" :rim "#FFFFFF33" :key "#FFFFFF1F"))
    :light (:veil (0.16d0 0.15d0 0.13d0 0.3d0) :shine (1 1 1 0.8d0)
            :line (0.1d0 0.1d0 0.12d0 0.5d0) :tint (0.2d0 0.22d0 0.27d0 0.06d0)
            :hint (:ink "#1D1F24" :plate "#F6F3ECD0" :rim "#00000026" :key "#0000001A"))))

(defparameter +screenshot-thread--shape+
  '(:radius 3 :knot 7 :slack 0.78d0 :swing 0.05d0 :lift 0.1d0 :lens 0.9d0 :rim 1))

(defparameter +screenshot-thread--motion+
  '(:enabled t :stiffness 220 :damping 0.5d0))

(defun screenshot-thread--look (mode)
  (let ((cast (getf +screenshot-thread--modes+ mode (getf +screenshot-thread--modes+ :dark)))
        (shape +screenshot-thread--shape+))
    (list :shader +screenshot-thread--shader+
          :data (append (getf cast :veil) (getf cast :shine) (getf cast :line) (getf cast :tint)
                        (loop for key in '(:radius :knot :slack :swing :lift :lens :rim)
                              collect (getf shape key)))
          :hint (append (getf cast :hint)
                        (list :rim-width 1 :radius 14 :font "IBM Plex Mono Medium" :size 15
                              :padding 10 :margin 28 :blur t))
          :motion +screenshot-thread--motion+)))

(define-extension "screenshot-thread" (:reads (:data) :state nil) (snapshot state event)
  (declare (ignore event))
  (values state
          (when (eq (state-value snapshot :rail-theme) :thread)
            (list (publish-state :screenshot-look
                                 (screenshot-thread--look (state-value snapshot :theme-mode :dark)))))
          nil))
