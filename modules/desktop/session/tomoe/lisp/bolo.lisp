(in-package #:tomoe-user)

(defun cassette--bolo-trim (text)
  (string-trim '(#\Space #\Tab #\Newline #\Return) (or text "")))

(defun cassette--bolo-text (text color size)
  (ui :text :text text :size (cassette--px size) :line-height (cassette--px size)
      :color color :font (getf +cassette+ :font)))

(defun cassette--bolo-lamp (color)
  (ui :row :justify :center
      :children (list (ui :rect :width (cassette--px 3) :height (cassette--px 3)
                          :background color))))

(defun cassette--bolo-meter (level)
  "Ten segments lit from the bottom in the bar's own zone colours, so the
meter reads like the gauges beside it."
  (let* ((count (getf +cassette+ :segments))
         (lit (round (* count (max 0 (min 1 (or level 0)))))))
    (ui :column :gap (cassette--px 1) :align :center
        :children (loop for i from (1- count) downto 0
                        collect (ui :rect :width (cassette--px 8) :height (cassette--px 3)
                                    :background (if (< i lit)
                                                    (cassette--zone (/ (1+ i) count))
                                                    (cassette--c :led-off)))))))

(defun cassette--bolo (state)
  "Bolo's dictation readout: how loud the microphone is while a clip is being
taken, then what became of it. Nothing at all between dictations."
  (let ((name (getf state :bolo-state))
        (level (getf state :bolo-level)))
    (flet ((cells (label color body)
             (ui :column :align :center :gap (cassette--px 3)
                 :children (list (cassette--bolo-text label color 7) body))))
      (cond
        ((member name '("listening" "recording") :test #'equal)
         (cells "MIC" (cassette--c :amber) (cassette--bolo-meter level)))
        ((equal name "transcribing")
         (cells "STT" (cassette--c :amber) (cassette--bolo-lamp (cassette--c :amber))))
        ((equal name "done")
         (cells "OK" (cassette--c :green) (cassette--bolo-lamp (cassette--c :green))))
        ((equal name "error")
         (cells "ERR" (cassette--c :red) (cassette--bolo-lamp (cassette--c :red))))
        (t nil)))))

(defun cassette--bolo-watch (state event)
  "Fold one watch event from bolo's state or level file into STATE."
  (let ((content (cassette--bolo-trim (getf event :content))))
    (cond
      ((eq (getf event :name) :bolo-state)
       (when (member content '("idle" "listening" "recording" "transcribing" "done" "error")
                     :test #'equal)
         (setf (getf state :bolo-state) content)))
      ((eq (getf event :name) :bolo-level)
       (let ((level (ignore-errors (read-from-string content))))
         (when (and (realp level) (<= 0 level 1))
           (setf (getf state :bolo-level) (coerce level 'single-float)))))))
  state)

(defun cassette--bolo-watches ()
  "Watch bolo's state and level files. A watch on a missing file is an error,
and bolo may not have started yet, so only existing files are watched."
  (loop for (name path) in (list (list :bolo-state (getf +bolo+ :state))
                                 (list :bolo-level (getf +bolo+ :level)))
        when (probe-file path)
          collect (watch-file name path)))
