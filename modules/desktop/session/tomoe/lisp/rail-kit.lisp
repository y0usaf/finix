(in-package #:tomoe-user)

;;; The kit thread's shader draws with
;;;
;;; Thread draws its whole look in one shader over the output -- the frames round
;;; the cards, the readings riding the focused frame or the seam, the motion of a
;;; focus switch and bolo's voice on the focused frame -- from numbers the rail
;;; hands it in one layout, and shaders/kit.glsl, which its shader starts with,
;;; unpacks it:
;;;
;;;   0-1     the surface's corner in output pixels
;;;   2-4     the focused card's index in :WINDOWS, the old one's, its side
;;;   5-9     the switch: when (iTime), pour 0 / siphon 1 / none -1, the side it
;;;           came from, the seconds it moves for, and which curve shapes its
;;;           clock
;;;   10-15   bolo's turn: opened, closed (iTime), open, rise, settle, how many
;;;           levels
;;;   16-18   the voice's three bands -- lo, mid, hi -- the swell it is riding,
;;;           the level now and how fast it is moving, which the focused frame's
;;;           whole border moves with at once
;;;   19-50   +KIT--LEVELS+ levels newest first
;;;   51-70   four readings -- cpu, memory, gpu, video memory -- each its glided
;;;           percent (-1 when there is no such probe), which way it is heading,
;;;           its value as six characters and its label as three
;;;   71-75   the clock as six characters, the day as three, the date as six
;;;   76-131  each of the eight :WINDOWS: its side and its title as eighteen
;;;           characters
;;;   132-    the theme's own numbers: its palette and its shape
;;;
;;; Text travels as character codes, three to a number, upper case, so each
;;; shader sets it in its own type. Every time is in the shader's own clock,
;;; seconds since the rail's epoch, so a surface can hold its last picture
;;; once its :UNTIL has passed and nothing it draws moves.

(defparameter +kit--levels+ 32)
(defparameter +kit--bands+ 16)
(defparameter +kit--theme+ 132)

(defun kit--code (text i)
  (if (< i (length text))
      (let ((code (char-code (char-upcase (char text i)))))
        (if (<= 32 code 126) code 63))
      32))

(defun kit--pack (text count)
  "TEXT as COUNT numbers, three characters to each, upper case, space padded."
  (loop for k below count
        collect (+ (kit--code text (* 3 k))
                   (* 256 (kit--code text (+ (* 3 k) 1)))
                   (* 65536 (kit--code text (+ (* 3 k) 2))))))

(defun kit--title (snapshot id)
  "ID's title, or its app id when it has none."
  (let ((window (find id (context snapshot :windows) :key (lambda (w) (getf w :id)))))
    (or (let ((title (getf window :title))) (and title (plusp (length title)) title))
        (getf window :app-id)
        "")))

(defun kit--readings (state)
  "The four gauges as (:label :percent :trend :value), NIL for a probe the
machine lacks, each drawing the rail's glided reading."
  (let ((meter (getf state :rail-meter))
        (targets (rail--meter-targets state))
        (gpu (getf state :gpu)))
    (loop for (key label used) in '((:cpu "CPU" nil) (:memory "MEM" nil)
                                    (:gpu "GPU" nil) (:vram "VRM" :vram-used))
          collect (when (or (member key '(:cpu :memory)) (probe--gpu-p gpu))
                    (let ((shown (max 0 (min 100 (or (getf meter key) 0))))
                          (target (or (getf targets key) 0)))
                      (list :label label :percent shown
                            :trend (cond ((> target (+ shown 0.5)) 1)
                                         ((< target (- shown 0.5)) -1)
                                         (t 0))
                            :value (if used
                                       (rail--digits (getf meter used))
                                       (format nil "~D%" (round shown)))))))))

(defun kit--gauges (state)
  (loop for reading in (kit--readings state)
        append (if reading
                   (append (list (getf reading :percent) (getf reading :trend))
                           (kit--pack (getf reading :value) 2)
                           (kit--pack (getf reading :label) 1))
                   (list -1 0 32 32 32))))

(defun kit--clock ()
  (append (kit--pack (clock-text "%H:%M") 2)
          (kit--pack (clock-text "%a") 1)
          (kit--pack (clock-text "%d %b") 2)))

(defun kit--voice (state voicing epoch)
  (let* ((history (if voicing (getf state :bolo-history) nil))
         (levels (subseq history 0 (min +kit--levels+ (length history))))
         (since (getf state :bolo-since))
         (fade (getf state :bolo-fade)))
    (append (list (if (and voicing (realp since)) (- since epoch) -1d9)
                  (if (and voicing (realp fade)) (- fade epoch) -1d9)
                  (if (and voicing (cassette--bolo-turn-p (getf state :bolo-state))) 1 0)
                  (getf +rail--voice+ :rise) (getf +rail--voice+ :settle) (length levels))
            (or (rail--bands levels) (list 0 0 0))
            levels
            (make-list (- +kit--levels+ (length levels)) :initial-element 0))))

(defun kit--cards (snapshot windows carried)
  (loop for i below 8
        for id = (nth i windows)
        for entry = (and id (find id carried :key (lambda (e) (getf e :id))))
        append (cons (rail--side-sign (and entry (getf entry :side)))
                     (kit--pack (if id (kit--title snapshot id) "") 6))))

(defun kit--settle (look context)
  "How long this draw's switch is drawn for: the rail's own clock for it, which
is the theme's own when the config names none."
  (let ((switch (getf context :switch)))
    (if switch (rail--settle switch) (getf look :settle 0.6d0))))

(defun kit--until (look context)
  "The iTime the theme's surface moves until: the switch's settle, an open
turn, a closed turn's calming; before then it draws every refresh, after it
holds its picture."
  (destructuring-bind (&key state epoch switch cut voice fade &allow-other-keys) context
    (max (if (and switch (not cut)) (+ (- (getf switch :at) epoch) (kit--settle look context)) 0d0)
         (cond ((and voice (cassette--bolo-turn-p (getf state :bolo-state))) 1d6)
               ((realp fade) (+ (- fade epoch) (getf +rail--voice+ :settle)))
               (t 0d0)))))

(defun kit--data (look context theme)
  "Every number the theme's shader reads: the kit's layout, then THEME, the
theme's own numbers."
  (destructuring-bind (&key state snapshot epoch output carried key side switch cut
                         old windows voicing &allow-other-keys)
      context
    (append (list (getf output :x) (getf output :y)
                  (or (and key (position (getf key :id) windows)) -1)
                  (or (and old (position old windows)) -1)
                  (rail--side-sign side)
                  (if (and switch (not cut)) (- (getf switch :at) epoch) -1d6)
                  (case (and switch (not cut) (getf switch :flow)) (:siphon 1) (:pour 0) (t -1))
                  (rail--side-sign (and switch (getf switch :from)))
                  (kit--settle look context)
                  (rail--curve))
            (kit--voice state voicing epoch)
            (kit--gauges state)
            (kit--clock)
            (kit--cards snapshot windows carried)
            theme)))

(defun kit--band (context)
  "The rail's own band, down the seam between the cards, as a surface: where
the rail is, for whoever asks the compositor for it -- the landing gate crops
the rail by this box, the one morph's type surface publishes. A theme sets its
readings in its shader and so carries no type surface of its own; the band is
still the rail's. Nothing of the look is drawn here, so it is the seam's own
glass at 1/255: a surface with nothing in it is pruned."
  (destructuring-bind (&key output layer seam &allow-other-keys) context
    (let* ((middle (floor (rail--seam-width) 2))
           (x (if seam (rail--lane seam :left)
                  (- (+ (getf output :x) (floor (getf output :width) 2)) middle)))
           (y (if seam (getf seam :y) (+ (getf output :y) 14))))
      (shell-surface
       :rail-type (ui :stack)
       :output (getf output :name) :anchors '(:top :left)
       :width (rail--design (rail--seam-width))
       :height (rail--design (if seam (getf seam :height) (- (getf output :height) 28)))
       :margin (rail--surface-margin output x y)
       :layer layer :background "#00000001" :click-through t :slide t))))

(defun kit--frames (look context theme &key (reach 48))
  "The theme's one surface: the whole output, drawn by its shader from
KIT--DATA, repainting only within REACH pixels of the cards it carries."
  (destructuring-bind (&key output windows epoch layer carried &allow-other-keys) context
    (append
     (list (shell-surface
            :rail-frames (ui :stack)
            :output (getf output :name) :anchors '(:top :left)
            :width (rail--design (getf output :width))
            :height (rail--design (getf output :height))
            :layer layer :click-through t
            :background (list :shader (getf look :shader)
                              :data (kit--data look context theme)
                              :windows windows :clock epoch
                              :until (kit--until look context)
                              :reach (rail--design reach)))
           (kit--band context))
     (unless (getf +rail+ :focus-border)
       (loop for entry in carried
             collect (window-properties
                      (getf entry :id)
                      :radius (rail--design (getf look :radius 0))
                      :border (list :focused "#00000000" :unfocused "#00000000")))))))
