(in-package #:tomoe-user)

(defun theme--words (line)
  (let ((words nil) (start nil))
    (dotimes (i (1+ (length line)) (nreverse words))
      (if (and (< i (length line)) (not (member (char line i) '(#\Space #\Tab #\; #\Return))))
          (unless start (setf start i))
          (when start (push (subseq line start i) words) (setf start nil))))))

(defun theme--hex-p (value)
  (and (member (length value) '(4 7 9)) (char= (char value 0) #\#)
       (every (lambda (c) (digit-char-p c 16)) (subseq value 1))))

(defun theme--resolve (name table)
  (loop with key = name
        repeat 8
        do (let ((value (cdr (assoc key table :test #'equal))))
             (cond ((null value) (return nil))
                   ((char= (char value 0) #\@) (setf key (subseq value 1)))
                   ((theme--hex-p value) (return value))
                   (t (return nil))))))

(defun theme--palette (css)
  (let ((table nil))
    (with-input-from-string (in css)
      (loop for line = (read-line in nil) while line
            do (let ((words (theme--words line)))
                 (when (and (= 3 (length words)) (equal (first words) "@define-color"))
                   (push (cons (second words) (third words)) table)))))
    (loop for (name) in (reverse table)
          for value = (theme--resolve name table)
          when value append (list (intern (string-upcase name) :keyword) value))))

(define-extension "theme" (:reads (:focus) :state (list :palette nil :watch nil :focus nil :focus-at nil))
    (snapshot state event)
  (let ((type (getf event :type)) (name (getf event :name)) (focus (context snapshot :focus)))
    (cond ((and (eq type :exec) (eq name :palette) (eql (getf event :code) 0))
           (setf (getf state :palette) (or (theme--palette (getf event :stdout)) (getf state :palette))
                 (getf state :watch) t))
          ((and (eq type :watch) (eq name :palette))
           (setf (getf state :palette) (or (theme--palette (getf event :content)) (getf state :palette)))))
    (unless (equal focus (getf state :focus))
      (setf (getf state :focus) focus (getf state :focus-at) (when focus (hud--now))))
    (let* ((p (getf state :palette))
           (flash (hud--decay (getf state :focus-at) (getf +hud-theme+ :focus-flash))))
      (values state
              (append (list (exec-async :palette (getf +hud-theme+ :palette-command)))
                      (when (getf state :watch) (list (watch-file :palette (getf +hud-theme+ :palette-file))))
                      (when (plusp flash) (list (interval :tick (getf +hud-theme+ :tick))))
                      (when p (list (publish-state :hud-palette p)))
                      (list (settings :border (list :width (getf +hud-theme+ :border) :radius 0
                                                    :focused (hud--mix (hud--c p :accent) (hud--c p :fg) flash)
                                                    :unfocused (hud--c p :color8)))))
              nil))))
