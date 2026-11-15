(in-package #:tomoe-user)

;; The voice block's shape: how many sample rows the waveform keeps, how wide a
;; full-level bar is, and how a row and the gap under it are drawn.
(defparameter +bolo-voice+
  (list :rows 20 :width 14 :bar 2 :gap 1 :floor 0.02))

(defparameter +bolo-ticks+ (coerce internal-time-units-per-second 'double-float))

(defun cassette--bolo-trim (text)
  (string-trim '(#\Space #\Tab #\Newline #\Return) (or text "")))

(defun cassette--bolo-text (text color size)
  (ui :text :text text :size (cassette--px size) :line-height (cassette--px size)
      :color color :font (getf +cassette+ :font)))

(defun cassette--bolo-now ()
  "Monotonic seconds, the scale the voice block's elapsed timer runs on."
  (/ (get-internal-real-time) +bolo-ticks+))

(defun cassette--bolo-turn-p (name)
  "Whether NAME is a state in which bolo is taking a dictation."
  (member name '("listening" "recording") :test #'equal))

(defun cassette--bolo-clock (seconds)
  "SECONDS as the m:ss the spine reads at a glance."
  (let ((whole (max 0 (floor (or seconds 0)))))
    (format nil "~D:~2,'0D" (floor whole 60) (mod whole 60))))

(defun cassette--bolo-since (path)
  "When the turn began, in CASSETTE--BOLO-NOW seconds. Bolo writes its state
as the turn opens, so the file's own write date is the turn's start rather than
a guess, and a bar reloaded mid-turn still shows the elapsed time."
  (let ((written (ignore-errors (file-write-date path))))
    (if (and written (<= written (get-universal-time)))
        (max 0 (- (cassette--bolo-now) (- (get-universal-time) written)))
        (cassette--bolo-now))))

(defun cassette--bolo-bar (level)
  "One sample row: a centred bar as wide as LEVEL, teal while there is voice
and a thin dim line in a pause, so silence reads as a flat waveform in either
theme rather than as a blank block."
  (let* ((level (max 0 (min 1 (or level 0))))
         (voice (> level (getf +bolo-voice+ :floor))))
    (ui :rect
        :width (if voice
                   (max 1 (round (* (cassette--px (getf +bolo-voice+ :width)) (sqrt level))))
                   (cassette--px 1))
        :height (cassette--px (getf +bolo-voice+ :bar))
        :background (cassette--c (if voice :teal :dim)))))

(defun cassette--bolo-wave (history)
  "HISTORY's newest level at the top, one row each, so the waveform scrolls down
the spine as it is spoken. Rows that are not there yet sit on the same baseline,
which keeps the block's height still from the first frame."
  (ui :column :align :center :gap (cassette--px (getf +bolo-voice+ :gap))
      :children (loop for i below (getf +bolo-voice+ :rows)
                      for rest on history
                      collect (cassette--bolo-bar (first rest)))))

(defun cassette--bolo (state)
  "Bolo's dictation at the top of the spine: the elapsed turn and bolo's own
level breathing down as a live waveform in the theme's teal. Nothing between
turns -- a nil cell draws nothing, and the block adds no timer of its own, so
an idle bar wakes no more than it did without it."
  (when (cassette--bolo-turn-p (getf state :bolo-state))
    (let ((since (getf state :bolo-since)))
      (ui :column :align :center :gap (cassette--px 4)
          :children (list (cassette--bolo-text
                           (cassette--bolo-clock
                            (and (realp since) (- (cassette--bolo-now) since)))
                           (cassette--c :ink) 9)
                          (cassette--bolo-wave (getf state :bolo-history)))))))

(defun cassette--bolo-watch (state event)
  "Fold one watch event from bolo's state or level file into STATE. A turn opens
the clock from the state file's write date and starts a fresh waveform, and
level events scroll that waveform."
  (let ((content (cassette--bolo-trim (getf event :content))))
    (cond
      ((eq (getf event :name) :bolo-state)
       (when (member content '("idle" "listening" "recording" "transcribing" "done" "error")
                     :test #'equal)
         ;; Only the edge into a turn starts it; recording -> listening within
         ;; the same turn keeps the clock and the waveform.
         (unless (and (cassette--bolo-turn-p (getf state :bolo-state))
                      (cassette--bolo-turn-p content))
           (setf (getf state :bolo-history) nil)
           (when (cassette--bolo-turn-p content)
             (setf (getf state :bolo-since) (cassette--bolo-since (getf +bolo+ :state)))))
         (setf (getf state :bolo-state) content)))
      ((eq (getf event :name) :bolo-level)
       (let ((level (ignore-errors (read-from-string content))))
         (when (and (realp level) (<= 0 level 1))
           (let ((level (coerce level 'single-float)))
             (setf (getf state :bolo-level) level)
             (when (cassette--bolo-turn-p (getf state :bolo-state))
               (let ((history (cons level (getf state :bolo-history)))
                     (rows (getf +bolo-voice+ :rows)))
                 (setf (getf state :bolo-history)
                       (if (> (length history) rows)
                           (subseq history 0 rows)
                           history))))))))))
  state)

(defun cassette--bolo-watches ()
  "Watch bolo's state and level files. A watch on a missing file is an error,
and bolo may not have started yet, so only existing files are watched."
  (loop for (name path) in (list (list :bolo-state (getf +bolo+ :state))
                                 (list :bolo-level (getf +bolo+ :level)))
        when (probe-file path)
          collect (watch-file name path)))
