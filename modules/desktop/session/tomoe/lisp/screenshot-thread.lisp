(in-package #:tomoe-user)

(defparameter +screenshot-thread--modes+
  '(:dark (:veil (0.094d0 0.094d0 0.11d0 0.5d0)
           :ink "#F4F2EC"
           :hint (:ink "#F4F2EC" :plate "#18181CB8" :rim "#FFFFFF2E" :key "#FFFFFF1C"))
    :light (:veil (0.8d0 0.79d0 0.76d0 0.5d0)
            :ink "#18181C"
            :hint (:ink "#18181C" :plate "#F4F2ECC8" :rim "#00000033" :key "#00000014"))))

(defparameter +screenshot-thread--shape+
  '(:rim 5 :swell 6 :pace 2400 :bead-hx 22 :bead-hy 9 :dot 3 :dot-swell 4))

(defparameter +screenshot-thread--motion+
  '(:enabled t :stiffness 260 :damping 1d0))

(defun screenshot-thread--rgba (hex)
  (append (loop for i from 1 below 7 by 2
                collect (/ (parse-integer hex :start i :end (+ i 2) :radix 16) 255d0))
          (list 1d0)))

(defun screenshot-thread--look (mode)
  (let ((cast (getf +screenshot-thread--modes+ mode (getf +screenshot-thread--modes+ :dark)))
        (shape +screenshot-thread--shape+))
    (list :shader (if (tomoe-setting-known-p :screenshot-mark)
                      +screenshot-thread--marks+
                      +screenshot-thread--shader+)
          :data (append (getf cast :veil)
                        (loop for key in '(:rim :swell :pace :bead-hx :bead-hy :dot :dot-swell)
                              collect (getf shape key))
                        (screenshot-thread--rgba (getf cast :ink)))
          :hint (append (getf cast :hint)
                        (list :rim-width 1 :radius 12 :font "Nib" :size 15
                              :padding 10 :margin 28 :blur t))
          :mark (list :ink (getf cast :ink) :width 3 :head 18 :size 20 :font "Nib")
          :motion +screenshot-thread--motion+)))

(define-extension "screenshot-thread" (:reads (:data) :state nil) (snapshot state event)
  (declare (ignore event))
  (values state
          (when (eq (state-value snapshot :rail-theme) :thread)
            (list (publish-state :screenshot-look
                                 (screenshot-thread--look (state-value snapshot :theme-mode :dark)))))
          nil))
