(in-package #:tomoe-user)

;; The voice block's shape: how many sample rows the waveform shows, how many
;; samples the history keeps for whatever else reads it (the rail's ripple walks
;; the whole history at 30 samples a second), how wide a full-level bar is, and
;; how a row and the gap under it are drawn.
(defparameter +bolo-voice+
  (list :rows 20 :ripple 64 :width 14 :bar 2 :gap 1 :floor 0.02))

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
  "SECONDS as the m:ss the bar reads at a glance."
  (let ((whole (max 0 (floor (or seconds 0)))))
    (format nil "~D:~2,'0D" (floor whole 60) (mod whole 60))))

(defun cassette--bolo-since (age)
  "When the turn began, in CASSETTE--BOLO-NOW seconds. Bolo writes its state
as the turn opens, so the age the watch reports with the file's content is the
turn's start rather than a guess, and a bar reloaded mid-turn still shows the
elapsed time."
  (if (and age (<= 0 age))
      (- (cassette--bolo-now) age)
      (cassette--bolo-now)))

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
the bar as it is spoken. Rows that are not there yet sit on the same baseline,
which keeps the block's height still from the first frame."
  (ui :column :align :center :gap (cassette--px (getf +bolo-voice+ :gap))
      :children (loop for rest = history then (cdr rest)
                      repeat (getf +bolo-voice+ :rows)
                      collect (cassette--bolo-bar (first rest)))))

(defun cassette--bolo (state)
  "Bolo's dictation at the top of the bar: the elapsed turn and bolo's own
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
the clock from the age the watch reports with the file and starts a fresh
waveform, level events scroll that waveform, and a turn closing keeps the
waveform for the bar to calm it -- the rail draws that from :bolo-fade."
  (let ((content (cassette--bolo-trim (getf event :content))))
    (cond
      ((eq (getf event :name) :bolo-state)
       (when (member content '("idle" "listening" "recording" "transcribing" "done" "error")
                     :test #'equal)
         ;; Only the edges matter; recording -> listening within the same turn
         ;; keeps the clock and the waveform.
         (let ((was (cassette--bolo-turn-p (getf state :bolo-state)))
               (turn (cassette--bolo-turn-p content)))
           (cond
             ((and turn (not was))
              (setf (getf state :bolo-history) nil
                    (getf state :bolo-fade) nil
                    (getf state :bolo-since) (cassette--bolo-since (getf event :age))))
             ((and was (not turn))
              (setf (getf state :bolo-fade) (cassette--bolo-now)))))
         (setf (getf state :bolo-state) content)))
      ((eq (getf event :name) :bolo-level)
       (let ((level (ignore-errors (read-from-string content))))
         (when (and (realp level) (<= 0 level 1))
           (let ((level (coerce level 'double-float)))
             (setf (getf state :bolo-level) level)
             (when (cassette--bolo-turn-p (getf state :bolo-state))
               (let ((history (cons level (getf state :bolo-history)))
                     (rows (max (getf +bolo-voice+ :rows) (getf +bolo-voice+ :ripple))))
                 (setf (getf state :bolo-history)
                       (if (> (length history) rows)
                           (subseq history 0 rows)
                           history))))))))))
  state)

(defun cassette--bolo-watches ()
  "Watch bolo's state and level files. A file that is not there yet is not an
error: the watch reports it as missing and starts reporting its content once
bolo creates it."
  (loop for (name path) in (list (list :bolo-state (getf +bolo+ :state))
                                 (list :bolo-level (getf +bolo+ :level)))
        collect (watch-file name path)))
