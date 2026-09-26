(in-package #:tomoe-user)

(defparameter +bar-runs+ '((:cpu :cpu-a :cpu-b) (:memory :memory-a :memory-b) (:gpu :gpu-a :gpu-b)))

(defun bar--words (text)
  (let ((words nil) (start nil))
    (dotimes (index (1+ (length text)) (nreverse words))
      (if (and (< index (length text))
               (not (member (char text index) '(#\Space #\Tab #\Newline #\Return #\;))))
          (unless start (setf start index))
          (when start
            (push (subseq text start index) words)
            (setf start nil))))))

(defun bar--hex-p (value)
  (and (member (length value) '(4 7 9))
       (char= (char value 0) #\#)
       (every (lambda (c) (digit-char-p c 16)) (subseq value 1))))

(defun bar--palette (css)
  (let ((table nil))
    (with-input-from-string (in css)
      (loop for line = (read-line in nil)
            while line
            do (let ((words (bar--words line)))
                 (when (and (= 3 (length words)) (equal (first words) "@define-color"))
                   (push (cons (second words) (third words)) table)))))
    (flet ((resolve (name)
             (loop for value = (cdr (assoc name table :test #'equal))
                   repeat 8
                   do (cond ((null value) (return nil))
                            ((char= (char value 0) #\@) (setf name (subseq value 1)))
                            ((bar--hex-p value) (return value))
                            (t (return nil))))))
      (let ((bg (some #'resolve '("bg" "background" "color0")))
            (fg (some #'resolve '("fg" "foreground" "color15" "color7"))))
        (when (or bg fg) (list :bg bg :fg fg))))))

(defun bar--percent (part whole)
  (if (plusp whole) (max 0 (min 100 (round (* 100 part) whole))) 0))

(defun bar--sample (probe previous event)
  (let ((numbers (when (eql (getf event :code) 0)
                   (mapcar (lambda (word) (parse-integer word :junk-allowed t))
                           (bar--words (getf event :stdout)))))
        (sample (copy-list previous)))
    (destructuring-bind (&optional a b c d &rest more) numbers
      (declare (ignore more))
      (ecase probe
        (:cpu
         (when (and a b)
           (let ((spent (- a (getf sample :total a))))
             (setf (getf sample :percent)
                   (if (plusp spent)
                       (bar--percent (- spent (- b (getf sample :idle b))) spent)
                       (getf sample :percent 0))
                   (getf sample :total) a
                   (getf sample :idle) b
                   (getf sample :temp) (and c (round c 1000))))))
        (:memory
         (when (and a b)
           (setf (getf sample :percent) (bar--percent (- a b) a)
                 (getf sample :used) (round (- a b) 1024))))
        (:gpu
         (if (and a b c)
             (setf (getf sample :util) (max 0 (min 100 a)) (getf sample :used) b
                   (getf sample :total) c (getf sample :temp) d (getf sample :failures) 0)
             (setf (getf sample :failures) (1+ (getf sample :failures 0)))))))
    sample))

(defun bar--labels (module state snapshot)
  (let ((show (getf +bar+ :show)))
    (ecase module
      (:time (list (clock-text (getf +bar+ :time))))
      (:date (list (clock-text (getf +bar+ :date))))
      (:cpu
       (let ((cpu (getf state :cpu)))
         (list (format nil "CPU ~3D%~@[ ~2D°~]" (getf cpu :percent 0)
                       (and (getf show :cpu-temp) (getf cpu :temp))))))
      (:memory
       (let ((memory (getf state :memory)))
         (list (if (and (getf show :memory-absolute) (getf memory :used))
                   (format nil "RAM ~4,1FG" (/ (getf memory :used) 1024d0))
                   (format nil "RAM ~3D%" (getf memory :percent 0))))))
      (:gpu
       (let ((gpu (getf state :gpu)))
         (when (and (getf gpu :util) (< (getf gpu :failures 0) 3))
           (list (format nil "GPU ~3D%~@[ ~2D°~]~@[ ~4,1FG~]" (getf gpu :util)
                         (and (getf show :gpu-temp) (getf gpu :temp))
                         (and (getf show :gpu-vram) (plusp (getf gpu :total 0))
                              (/ (getf gpu :used) 1024d0)))))))
      (:battery
       (let ((battery (service-state snapshot :battery)))
         (list (format nil "~D%" (getf battery :percent 0))
               (if (getf battery :charging) "↑" "↓"))))
      (:network
       (let* ((network (service-state snapshot :network))
              (ssid (getf network :ssid)))
         (list (if (and (getf network :connected) (stringp ssid) (plusp (length ssid)))
                   (remove (code-char 0) ssid)
                   "offline")))))))

(defun bar--cell (texts width palette)
  (let ((height (getf +bar+ :height)))
    (if texts
        (ui :row :width width :height height :gap (getf +bar+ :label-gap)
            :padding (getf +bar+ :padding) :background (getf palette :bg)
            :border (getf +bar+ :border) :border-color (getf palette :fg)
            :children (loop for text in texts
                            collect (ui :text :text text :size (getf +bar+ :label-size)
                                        :color (getf palette :fg) :font (getf +bar+ :font))))
        (ui :row :width width :height height))))

(defun bar--surfaces (items palette)
  (let* ((height (getf +bar+ :height))
         (spacing (getf +bar+ :spacing))
         (inset (floor spacing 2))
         (exclusive (getf +bar+ :exclusive))
         (indent (if exclusive (getf +bar+ :indent) 0))
         (thickness (+ height indent))
         (pair (getf +bar+ :center-between))
         (seam (loop for (a b) on (mapcar #'car items)
                     for index from 1
                     when (and b (eq a (first pair)) (eq b (second pair))) return index)))
    (labels ((cells (list intrinsic)
               (loop for (module . texts) in list
                     collect (bar--cell texts (unless intrinsic (getf (getf +bar+ :widths) module))
                                        palette)))
             (half (list justify padding)
               (ui :row :width 0 :grow 1 :height height :gap spacing :justify justify
                   :padding padding :children (cells list t))))
      (loop for edge in (getf +bar+ :edges)
            collect (shell-surface edge
                                   (ui :row :gap (if seam 0 spacing) :justify :center
                                       :padding (cond ((zerop indent) 0)
                                                      ((eq edge :top) (list indent 0 0 0))
                                                      (t (list 0 0 indent 0)))
                                       :children (if seam
                                                     (list (half (subseq items 0 seam) :end
                                                                 (list 0 inset 0 0))
                                                           (half (nthcdr seam items) :start
                                                                 (list 0 0 0 inset)))
                                                     (cells items nil)))
                                   :anchors (if (or seam exclusive) (list edge :left :right) (list edge))
                                   :height thickness :layer (if exclusive :top :overlay)
                                   :exclusive-zone (if exclusive thickness 0)
                                   :background "#00000000")))))

(define-extension "bar" (:reads (:services) :state (list :palette nil :watch nil))
    (snapshot state event)
  (let* ((type (getf event :type))
         (name (getf event :name))
         (sysinfo (getf +bar+ :sysinfo))
         (probe (car (find name +bar-runs+ :key #'rest :test #'member))))
    (flet ((run (probe)
             (nth (mod (getf (getf state probe) :run 0) 2) (rest (assoc probe +bar-runs+))))
           (live-p (probe)
             (and (getf sysinfo probe) (member probe (getf +bar+ :modules))
                  (< (getf (getf state probe) :failures 0) 3))))
      (cond
        ((and (eq type :timer) (getf sysinfo name))
         (let ((sample (copy-list (getf state name))))
           (setf (getf sample :run) (1+ (getf sample :run 0))
                 (getf state name) sample)))
        ((and (eq type :exec) probe (eq name (run probe)))
         (setf (getf state probe) (bar--sample probe (getf state probe) event)))
        ((and (eq type :exec) (eq name :palette) (eql (getf event :code) 0))
         (setf (getf state :palette) (or (bar--palette (getf event :stdout)) (getf state :palette))
               (getf state :watch) t))
        ((and (eq type :watch) (eq name :palette))
         (setf (getf state :palette) (or (bar--palette (getf event :content)) (getf state :palette)))))
      (let ((palette (list :bg (or (getf (getf state :palette) :bg) (theme :base))
                           :fg (or (getf (getf state :palette) :fg) (theme :text)))))
        (values state
                (append
                 (list (interval :clock (getf +bar+ :clock-interval))
                       (exec-async :palette (getf +bar+ :palette-command)))
                 (when (getf state :watch)
                   (list (watch-file :palette (getf +bar+ :palette-file))))
                 (loop for probe in '(:cpu :memory :gpu)
                       when (live-p probe)
                         append (list (interval probe (getf (getf sysinfo probe) :interval))
                                      (exec-async (run probe) (getf (getf sysinfo probe) :command))))
                 (bar--surfaces (loop for module in (getf +bar+ :modules)
                                      collect (cons module (bar--labels module state snapshot)))
                                palette))
                nil)))))
