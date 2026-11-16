(in-package #:tomoe-user)

;;; glyph
;;;
;;; The deck is one character grid. The seam is the rail: a column of
;;; box-drawing rules with bolo's turn at the head, its braille waterfall under
;;; it, the date, a clock built out of 3x5 blocks on a half-row grid, the gauges
;;; as bars in sixths with a four-second sparkline under each, and the network
;;; at the foot. The rail's ground is flat to the screen's edge and its rules run
;;; out into the lines of the frames on either side of it, so rail and windows
;;; read as one drawing rather than a bar standing next to a desktop.
;;;
;;; Every card the rail carries is fenced by square corners in the gap round it:
;;; one faint line when the card is not the one you are in, two in ink when it
;;; is. Inside the frame's top line, above the window's own pixels, sits a title
;;; row: the window's name or its app id in capitals, its place in the column at
;;; the far end, on the deck's own ground -- and on the card that holds focus,
;;; ink behind ground-coloured letters. Focus retypes the frame rather than
;;; sliding anything: two heads leave the middle of the frame's rail side, run up
;;; and down the perimeter, and the line behind them has doubled by the time they
;;; pass, meeting at the far edge; the frame the card wore before un-types the
;;; same way, its heads running back to the rail. A cut throw draws the new frame
;;; at once with no motion at all.
;;;
;;; While bolo has the turn the waterfall is the voice: sixteen dots across,
;;; sixty-four rows down, newest at the top, each row holding the level the voice
;;; had when it passed, sifted through a Bayer field so loudness is density. It
;;; dies away over the settle rather than snapping flat, and the rail carries a
;;; red dot for the open turn. Everything the eye follows is a number the rail
;;; hands the shader, and every surface comes to rest with it: the theme keeps no
;;; timer and has nothing left to tick once the voice has calmed.
;;;

;;; The geometry is the mockup's cells fitted to the deck: an 8 px gap round each
;;; card, a 30 px title row holding a 26 px cap row of Cozette, the 56 px rail
;;; with its rules 2 px thick, the clock on 7 px blocks, and the gauges'
;;; sparkline at a sample a second. Nothing below this header is commented.

(defparameter +rail-glyph--cast+
  (list :edge 8 :title 30 :gap 8 :line 2 :pair 4
        :dark (list :bg "#10100F" :ink "#ECE7DC" :dim "#9A958A" :faint "#545249"
                    :acc "#40D2BE" :red "#EC4C38" :track "#282826")
        :light (list :bg "#F0EDE6" :ink "#1E1E1D" :dim "#6E6A62" :faint "#B0ACA2"
                     :acc "#0A8C7E" :red "#C8321E" :track "#DAD6CD")))

(defparameter +rail-glyph--type+
  (list :sweep 0.26d0 :name 26 :small 13 :pad 18 :bar 14 :spark 28))

(defparameter +rail-glyph--bands+
  (list :rule 2 :mic 30 :water-end 0.350d0 :date-end 0.423d0
        :clock-end 0.570d0 :gauge-end 0.870d0))

(defparameter +rail-glyph--face+
  (list (list 7 5 5 5 7) (list 2 6 2 2 7) (list 7 1 7 4 7) (list 7 1 3 1 7)
        (list 5 5 7 1 1) (list 7 4 7 1 7) (list 7 4 7 5 7) (list 7 1 1 2 2)
        (list 7 5 7 5 7) (list 7 5 7 1 7)))

(defvar *rail-glyph--samples* nil)
(defvar *rail-glyph--second* nil)
(defun rail-glyph--num (key) (getf +rail-glyph--bands+ key))

(defun rail-glyph--c (role)
  "The colour ROLE draws with in the current mode."
  (getf (rail--cast *rail--mode*) role))

(defun rail-glyph--small (text role &optional (height 16))
  (rail--text text (rail-glyph--c role) (getf +rail-glyph--type+ :small) height))

(defun rail-glyph--name (text role &optional (height 26))
  (rail--text text (rail-glyph--c role) (getf +rail-glyph--type+ :name) height))

(defun rail-glyph--gap (height)
  (ui :rect :height (rail--design height)))

(defun rail-glyph--gap-ew (width)
  (ui :rect :width (rail--design width)))

(defun rail-glyph--clean (text)
  "TEXT as a window name: its first line, capitals, cut to what a title holds."
  (let* ((raw (if (and (stringp text) (plusp (length text))) text "?"))
         (line (subseq raw 0 (or (position #\Newline raw) (length raw))))
         (cut (subseq line 0 (min (length line) 30))))
    (string-upcase (if (plusp (length cut)) cut "?"))))

(defun rail-glyph--place (entry carried)
  "Where ENTRY sits in its column, the front first, and how long the column is."
  (let* ((side (getf entry :side))
         (ids (loop for other in carried
                    when (eq (getf other :side) side)
                      collect (getf other :id))))
    (list (1+ (or (position (getf entry :id) ids) 0)) (length ids))))

(defun rail-glyph--band (height)
  "Where the rail's bands sit, in design px from the seam's top: each band and
the rule that closes it."
  (let* ((rule (rail-glyph--num :rule))
         (mic (rail-glyph--num :mic))
         (a (round (* height (rail-glyph--num :water-end))))
         (b (round (* height (rail-glyph--num :date-end))))
         (c (round (* height (rail-glyph--num :clock-end))))
         (d (round (* height (rail-glyph--num :gauge-end))))
         (head (+ rule mic)))
    (list :mic rule :mic-h mic
          :water head :water-h (max 0 (- a head))
          :rule1 a
          :date (+ a rule) :date-h (max 0 (- b a rule))
          :rule2 b
          :clock (+ b rule) :clock-h (max 0 (- c b rule))
          :rule3 c
          :gauge (+ c rule) :gauge-h (max 0 (- d c rule))
          :rule4 d
          :net (+ d rule) :net-h (max 0 (- height rule d rule)))))

(defun rail-glyph--code (face)
  "One 3x5 face as a bit code: a row's three bits above the one over it, the
left of the row in the highest of its three."
  (let ((code 0) (place 1))
    (dolist (row face)
      (setf code (+ code (* place row)))
      (setf place (* place 8)))
    code))

(defun rail-glyph--digits ()
  "The ten faces in the order of their digits."
  (loop for face in +rail-glyph--face+ collect (rail-glyph--code face)))

(defun rail-glyph--clock-codes ()
  "The clock's four digits as the shader draws them: hours, then minutes."
  (let* ((digits (rail-glyph--digits))
         (codes (loop for ch across (or (clock-text (getf +cassette+ :time)) "")
                      when (digit-char-p ch)
                        collect (coerce (nth (digit-char-p ch) digits) 'double-float))))
    (append (subseq codes 0 (min 4 (length codes)))
            (loop repeat (- 4 (min 4 (length codes))) collect 0d0))))

(defun rail-glyph--history (state now)
  "Four whole seconds of each gauge, oldest first, from the samples the rail is
gliding toward."
  (let ((second (floor now)))
    (unless (eql second *rail-glyph--second*)
      (setf *rail-glyph--second* second)
      (setf *rail-glyph--samples*
            (cons (rail--meter-targets state)
                  (subseq *rail-glyph--samples* 0
                          (min 3 (length *rail-glyph--samples*))))))
    (let ((count (length *rail-glyph--samples*)))
      (loop for key in '(:cpu :memory :gpu :vram)
            append (loop for i from 3 downto 0
                         for sample = (nth (min i (1- count)) *rail-glyph--samples*)
                         collect (coerce (or (getf sample key) 0) 'double-float))))))

(defun rail-glyph--meter (state)
  "The four gauges as percentages, in the order the rail draws them."
  (let ((meter (getf state :rail-meter)))
    (loop for key in '(:cpu :memory :gpu :vram)
          collect (coerce (or (getf meter key) 0) 'double-float))))

(defun rail-glyph--palette ()
  "The seven colours, three reals each, in the order the shader reads them."
  (loop for role in '(:bg :ink :dim :faint :acc :red :track)
        append (rail--rgb (rail-glyph--c role))))

(defun rail-glyph--voice (state voicing epoch)
  "The voice as the shader reads it: when the turn opened and closed, whether it
is open, the settle, and the level history newest first."
  (let* ((levels (if voicing
                     (subseq (getf state :bolo-history) 0
                             (min 32 (length (getf state :bolo-history))))
                     nil))
         (since (and voicing (getf state :bolo-since)))
         (fade (and voicing (getf state :bolo-fade))))
    (append (list (if (realp since) (- since epoch) -1d9)
                  (if (realp fade) (- fade epoch) -1d9)
                  (if (and voicing (cassette--bolo-turn-p (getf state :bolo-state))) 1 0)
                  (getf +rail--voice+ :rise) (getf +rail--voice+ :settle)
                  (length levels))
            levels
            (loop repeat (- 32 (length levels)) collect 0d0))))

(defun rail-glyph--reals (values where count)
  "VALUES, checked to be COUNT reals the shader can read, named by WHERE."
  (unless (= (length values) count)
    (error "glyph ~A carries ~D numbers, not ~D" where (length values) count))
  (loop for value in values for i from 0
        unless (realp value) do (error "glyph ~A ~D is ~S" where i value))
  values)

(defun rail-glyph--frame-data (origin seam windows key old switch epoch)
  "Every number glyph.glsl reads for the frames surface, in its order."
  (rail-glyph--reals
   (append (list 0d0 (getf origin :x) (getf origin :y))
          (rail-glyph--palette)
          (list (getf seam :x) (getf seam :width)
                (rail--cast :gap) (rail--cast :line) (rail--cast :pair)
                (rail--cast :title)
                (if switch (- (getf switch :at) epoch) -1000000d0)
                (getf +rail-glyph--type+ :sweep)
                (or (and key (position key windows)) -1)
                (or (and old (position old windows)) -1)
                (if switch 0 -1)))
   "frames" 35))

(defun rail-glyph--outer (frame seam)
  "The rules at the frames' top and bottom, where the cards' own lines run, taken
from the first carried card's box so the rail and the frames meet."
  (let ((title (rail--cast :title)))
    (if frame
        (list (- (getf frame :y) title 4) (+ (getf frame :y) (getf frame :height) 4))
        (list (- (getf seam :y) 4) (+ (getf seam :y) (getf seam :height) 4)))))

(defun rail-glyph--rail-data (origin seam band state voicing epoch frame)
  "Every number glyph.glsl reads for the rail surface, in its order."
  (let ((y (getf seam :y))
        (height (getf seam :height))
        (blocks (max 1 (floor (getf band :gauge-h) 4))))
    (rail-glyph--reals
     (append
      (list 1d0 (getf origin :x) (getf origin :y))
      (rail-glyph--palette)
      (list (getf seam :x) (getf seam :width)
            0d0 0d0 0d0 0d0 0d0 0d0 0d0 0d0 0d0
            (+ (getf seam :x) 2) 56d0 y height
            (+ y (getf band :mic)) (getf band :mic-h)
            (+ y (getf band :water)) (coerce (getf band :water-h) 'double-float)
            (+ y (getf band :date)) (coerce (getf band :date-h) 'double-float)
            (+ y (getf band :clock)) (coerce (getf band :clock-h) 'double-float)
            (+ y (getf band :gauge)) (coerce blocks 'double-float)
            (+ y (getf band :net)) (coerce (getf band :net-h) 'double-float)
            48d0 (getf +rail-glyph--type+ :bar)
            66d0 (getf +rail-glyph--type+ :spark)
            (rail-glyph--num :rule)
            (+ y (getf band :rule1)) (+ y (getf band :rule2))
            (+ y (getf band :rule3)) (+ y (getf band :rule4)))
      (rail-glyph--clock-codes)
      (rail-glyph--meter state)
      (rail-glyph--history state (or (getf state :rail-step) 0))
      (rail-glyph--voice state voicing epoch)
      (rail-glyph--outer frame seam))
     "rail" 124)))

(defun rail-glyph--detail (key state meter)
  (case key
    (:cpu (cassette--degrees (getf (getf state :cpu) :temp)))
    (:gpu (cassette--degrees (getf (getf state :gpu) :temp)))
    (:memory (rail--digits (getf meter :memory-used)))
    (:vram (rail--digits (getf meter :vram-used)))))

(defun rail-glyph--gauge (key label state)
  "One gauge's rows: its label and detail, and its value in the accent while the
number is still moving toward the sample."
  (let* ((meter (getf state :rail-meter))
         (moving (getf state :rail-glide))
         (value (format nil "~D%" (max 0 (min 100 (round (or (getf meter key) 0)))))))
    (list (ui :rect :height (rail--design 2))
          (ui :row :height (rail--design 16) :padding '(0 1 0 1)
              :children (list (rail-glyph--small label :dim)
                              (ui :spacer)
                              (rail-glyph--small (rail-glyph--detail key state meter) :dim)))
          (ui :row :height (rail--design 26) :justify :end :padding '(0 1 0 1)
              :children (list (rail-glyph--name value (if moving :acc :ink))))
          (rail-glyph--gap 4)
          (rail-glyph--gap (getf +rail-glyph--type+ :bar))
          (rail-glyph--gap 4)
          (rail-glyph--gap (getf +rail-glyph--type+ :spark))
          (rail-glyph--gap 12))))

(defun rail-glyph--type (state snapshot seam band)
  "The rail's readings in type, on the rows the shader leaves for them."
  (let* ((turn (cassette--bolo-turn-p (getf state :bolo-state)))
         (since (getf state :bolo-since))
         (date (rail--parts (string-upcase (or (clock-text (getf +cassette+ :date)) ""))))
         (connected (getf (service-state snapshot :network) :connected))
         (date-pad (max 0 (floor (- (getf band :date-h) 58) 2)))
         (net-pad (max 0 (floor (- (getf band :net-h) 42) 2))))
    (ui :column :width (rail--design 56) :height (rail--design (getf seam :height))
            :align :stretch
        :children
        (append
         (list (rail-glyph--gap (rail-glyph--num :rule))
               (ui :row :height (rail--design (getf band :mic-h)) :align :center :justify :center
                   :children (list (if turn
                                       (rail-glyph--name (cassette--bolo-clock
                                                          (and (realp since)
                                                               (- (cassette--bolo-now) since)))
                                                         :ink)
                                       (rail-glyph--small "MIC" :faint))))
               (rail-glyph--gap (getf band :water-h))
               (rail-glyph--gap (rail-glyph--num :rule))
               (rail-glyph--gap date-pad)
               (ui :row :height (rail--design 16) :justify :center
                   :children (list (rail-glyph--small (or (first date) "--") :dim)))
               (ui :row :height (rail--design 26) :justify :center
                   :children (list (rail-glyph--name (or (second date) "--") :ink)))
               (ui :row :height (rail--design 16) :justify :center
                   :children (list (rail-glyph--small (or (third date) "") :dim)))
               (rail-glyph--gap (+ date-pad (rail-glyph--num :rule)))
               (rail-glyph--gap (getf band :clock-h))
               (rail-glyph--gap (rail-glyph--num :rule)))
         (loop for key in '(:cpu :memory :gpu :vram)
               for label in '("CPU" "MEM" "GPU" "VRAM")
               append (rail-glyph--gauge key label state))
         (list (rail-glyph--gap (rail-glyph--num :rule))
               (rail-glyph--gap net-pad)
               (ui :row :height (rail--design 16) :justify :center
                   :children (list (rail-glyph--small "NET" :dim)))
               (ui :row :height (rail--design 26) :justify :center
                   :children (list (rail-glyph--name (if connected "ON" "OFF")
                                                     (if connected :ink :red)))))))))

(defun rail-glyph--title-cell (entry carried names focus title-h width)
  "One column's title row: the card at its front, in the ground's ink while it
holds focus and in the dim reading otherwise, with its place in the column at the
row's far end."
  (let* ((id (and entry (getf entry :id)))
         (place (and entry (rail-glyph--place entry carried)))
         (here (and id (eql id focus)))
         (name (if entry (rail-glyph--clean (cdr (assoc id names))) ""))
         (role (if here :bg :dim))
         (row (ui :row :height (rail--design title-h) :align :center
                  :padding (list 3 (+ (getf +rail-glyph--type+ :pad) 6) 0
                                 (getf +rail-glyph--type+ :pad))
                  :children (list (rail-glyph--name name role)
                                  (ui :spacer)
                                  (rail-glyph--small (if place
                                                        (format nil "~D/~D"
                                                                (first place) (second place))
                                                        "")
                                                     role)))))
    (ui :stack :width (rail--design width) :height (rail--design title-h)
        :children (list (ui :rect :width (rail--design width)
                            :height (rail--design title-h)
                            :background (rail-glyph--c (if here :ink :bg)))
                        row))))

(defun rail-glyph--shown-p (box output)
  "Whether BOX reaches OUTPUT's screen at all."
  (and box
       (< (getf box :y) (+ (getf output :y) (getf output :height)))
       (> (+ (getf box :y) (getf box :height)) (getf output :y))))

(defun rail-glyph--windows (carried output focus old)
  "The cards the frames shader reads, at most eight: the focused card, the one it
came from, then the carried cards on this screen, nearest each column's front
first. A column carries its whole stack, so the head of the list would be one
column alone -- and the other column's card, often the focused one, would lose
its frame."
  (let ((ids nil))
    (dolist (id (list focus old))
      (when (and id (not (member id ids)) (< (length ids) 8))
        (setf ids (append ids (list id)))))
    (dolist (entry carried)
      (let ((id (getf entry :id)))
        (when (and (rail-glyph--shown-p (getf entry :box) output)
                   (not (member id ids))
                   (< (length ids) 8))
          (setf ids (append ids (list id))))))
    (dolist (entry carried)
      (let ((id (getf entry :id)))
        (when (and (not (member id ids)) (< (length ids) 8))
          (setf ids (append ids (list id))))))
    ids))

(defun rail-glyph--front (carried side)
  "The card nearest the front of the column on SIDE."
  (car (remove-if-not (lambda (entry) (eq (getf entry :side) side)) carried)))

(defun rail-glyph--titles (output carried names focus layer title-h seam)
  "The title rows of both columns, in one surface across the top of the deck: the
window each column has at its front, its name, and -- on the card that holds
focus -- the ink bar that inverts it."
  (let* ((left (rail-glyph--front carried :left))
         (right (rail-glyph--front carried :right))
         (left-x (if left (getf (getf left :box) :x) (getf output :x)))
         (left-w (if left (getf (getf left :box) :width) 1))
         (right-x (if right (getf (getf right :box) :x) left-x))
         (right-w (if right (getf (getf right :box) :width) 1)))
    (shell-surface
     :rail-titles
     (ui :row :height (rail--design title-h)
         :children (list (rail-glyph--gap-ew (max 0 (- left-x (getf output :x))))
                         (rail-glyph--title-cell left carried names focus title-h left-w)
                         (rail-glyph--gap-ew (max 0 (- right-x (+ left-x left-w))))
                         (rail-glyph--title-cell right carried names focus title-h right-w)))
     :output (getf output :name) :anchors '(:top :left)
     :width (rail--design (getf output :width))
     :height (rail--design title-h)
     :margin (list (rail--design (- (getf seam :y) (getf output :y))) 0 0 0)
     :layer layer :click-through t)))

(defun rail-glyph--names (snapshot carried)
  "Each carried window's name: its title, or its app id when it has none."
  (loop for window in (context snapshot :windows)
        for id = (getf window :id)
        when (find id carried :key (lambda (entry) (getf entry :id)))
          collect (cons id (or (getf window :title) (getf window :app-id)))))

(defun rail-glyph--draw (look context)
  "glyph: the rail down the seam, and the frames and titles round the cards."
  (declare (ignore look))
  (destructuring-bind (&key state snapshot epoch seam output carried key switch
                         voicing fade layer cut &allow-other-keys)
      context
    (let* ((names (rail-glyph--names snapshot carried))
           (settle (getf +rail-glyph--type+ :sweep))
           (voice (cassette--bolo-turn-p (getf state :bolo-state)))
           (height (getf seam :height))
           (band (rail-glyph--band height))
           (shader (getf look :shader))
           (title-h (rail--cast :title))
           (left (getf output :x))
           (top (getf output :y))
           (rail-x (- (getf seam :x) 4))
           (focus (and key (getf key :id)))
           (old (and switch (not cut) (getf switch :old)))
           (windows (rail-glyph--windows carried output focus old))
           (progress (and switch (not cut)))
           (moved (if progress
                      (max 0d0 (+ (- (getf switch :at) epoch) settle))
                      0d0))
           (calmed (cond (voice 1d6)
                         ((realp fade)
                          (max 0d0 (+ (- fade epoch) (getf +rail--voice+ :settle))))
                         (t 0d0))))

      (append
       (list (shell-surface
              :rail-frames (ui :stack)
              :output (getf output :name) :anchors '(:top :left)
              :width (rail--design (getf output :width))
              :height (rail--design (getf output :height))
              :layer layer :click-through t
              :background (list :shader shader
                                :data (rail-glyph--frame-data
                                       (list :x left :y top) seam windows
                                       (and key (getf key :id)) old switch
                                       epoch)
                                :windows windows :clock epoch
                                :until moved
                                :reach (rail--design 44)))
             (shell-surface
              :rail-slab (ui :stack)
              :output (getf output :name) :anchors '(:top :left)
              :width (rail--design 68)
              :height (rail--design (getf output :height))
              :margin (rail--surface-margin output rail-x top)
              :layer layer :click-through t
              :background (list :shader shader
                                :data (rail-glyph--rail-data (list :x rail-x :y top)
                                                             seam band state voicing epoch
                                                             (getf (first carried) :box))
                                :windows windows :clock epoch
                                :until (max moved calmed)))
             (shell-surface :rail-type (rail-glyph--type state snapshot seam band)
                            :output (getf output :name) :anchors '(:top :left)
                            :width (rail--design 56)
                            :height (rail--design height)
                            :margin (rail--surface-margin
                                     output (+ (getf seam :x) 2) (getf seam :y))
                            :layer layer :background "#00000000" :click-through t))
       (list (rail-glyph--titles output carried names focus layer title-h seam))
       (unless (getf +rail+ :focus-border)
         (loop for entry in carried
               collect (window-properties
                        (getf entry :id) :radius 0
                        :border (list :focused "#00000000" :unfocused "#00000000"))))))))

(defparameter +rail-glyph+
  (list :draw #'rail-glyph--draw :cast +rail-glyph--cast+
        :frame (list :edge 8 :title 30) :font "Cozette Vector Px"))
