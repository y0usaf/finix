(in-package #:tomoe-user)

(defparameter +screenshot-thread--shape+
  (list :rim (round (thread-design--geom :rim-width))
        :swell 6 :pace 2400 :bead-hx 22 :bead-hy 9 :dot 3 :dot-swell 4))

(defun screenshot-thread--look (mode)
  (let* ((cast (thread-design--mode mode))
         (shape +screenshot-thread--shape+)
         (ink (getf cast :ink))
         (palette (thread-design--palette ink)))
    (list :shader (cond ((tomoe-setting-field-known-p :screenshot-mark :palette)
                         +screenshot-thread--colours+)
                        ((tomoe-setting-known-p :screenshot-mark)
                         +screenshot-thread--marks+)
                        (t +screenshot-thread--shader+))
          :data (append (getf cast :veil)
                        (loop for key in '(:rim :swell :pace :bead-hx :bead-hy :dot :dot-swell)
                              collect (getf shape key))
                        (thread-design--hex->rgba ink))
          :hint (thread-design--hint-look mode)
          :mark (list :ink ink :width 3 :head 18
                      :size (thread-design--type :mark-size)
                      :font (thread-design--type :font)
                      :palette (mapcar #'cdr palette)
                      :palette-keys (mapcar #'car palette))
          :motion (thread-design--motion :spring))))

(define-extension "screenshot-thread" (:reads (:data) :state nil) (snapshot state event)
  (declare (ignore event))
  (values state
          (when (eq (state-value snapshot :rail-theme) :thread)
            (list (publish-state :screenshot-look
                                 (screenshot-thread--look (state-value snapshot :theme-mode :dark)))))
          nil))
