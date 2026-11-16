(in-package #:tomoe-user)

;;; HALO: morph's cast material with no centre slab at all
;;;
;;; The deck's seam carries nothing but the four pixels its two gaps leave: every
;;; card stands its own frame, and the readings ride the focused card. On that
;;; card's top edge, at the end nearer the seam, a capsule the height of a line
;;; of type is welded to the frame by the smooth minimum that welds morph's slab
;;; to its frames -- the CROWN. It holds the clock, the day and date, and the
;;; four gauges, each gauge's load swelling the crown's rim by a welded bump and
;;; running a filled hairline of its own under its value. Every other card keeps
;;; a thin darker line. Focus is unmistakable the way morph's is: the focused
;;; card wears a five pixel cast frame in the same material, and the crown sits
;;; on it.
;;;
;;; A focus change siphons. The old frame drains back into the crown, its front
;;; running from the far side toward it, the crown hops to the new card on two
;;; springs -- its leading end stiff and its trailing end loose, so mid-flight it
;;; stretches into a long thin capsule -- and the new frame fills out of it both
;;; ways round the card. Within a column the crown does not move at all: the
;;; cards scroll under it, so the old frame drains and the new one fills from the
;;; crown where it stands at the top of the column. A quick switch (K_FLOW 0)
;;; only pours, one frame thinning as the other swells in.
;;;
;;; bolo's turn is the centrepiece: the whole focused frame becomes the speech
;;; waveform. Spikes stand off its outer edge, their reach at each point the
;;; level the voice had when it ran that far round from the crown (~3600 px/s
;;; both ways) over a slower swell, the material brightening toward its glow
;;; colour with the level, and the crown's head showing a small live trace. It
;;; dies away over the settle when the turn ends. Only the focused frame moves.
;;;
;;; All of it is one shader (shaders/halo.glsl) over the output; this file lays
;;; the crown out and sets its type as one anti-aliased surface at the crown's
;;; seated place -- IBM Plex Mono, the mock's sizes -- hidden while the crown is
;;; in flight across the seam, so the type never rides a stretched capsule, and
;;; never redrawn while it sits still.

;; The siphon moves for 0.46 s: the crown hops in the first 0.2, the old frame
;; has drained by 0.18 and the new one has filled by 0.40. The settle is also
;; what the rail's surface draws until, so keeping it well short of the second
;; the harness counts after a switch leaves the theme nothing to draw once the
;; cards are still.
(defparameter +rail-halo--settle+ 0.46d0)
(defparameter +rail-halo--hop+ 0.28d0)

(defun rail-halo--hop-time (switch)
  "How long this switch's crown is in the air for: the hop takes its share of the
move, so a shorter move -- a retargeted one -- still lands its crown before the
move is over."
  (if switch
      (* +rail-halo--hop+ (/ (rail--settle switch) +rail-halo--settle+))
      +rail-halo--hop+))

;; morph's cast in the mock's halo palette: the same material, corner radius and
;; frame thickness, plus the darker low light and the glow the waveform brightens
;; toward, the ink and dim of the crown's type and the track its hairlines run in.
(defparameter +rail-halo--cast+
  (list :frame 5 :line-width 1.5 :radius 14
        :dark (list :material "#3A3E58" :line "#26283C" :shadow "#020208" :shade 0.55
                    :shine "#ECE7DC" :gloss 0.34 :lo "#282B3E" :ink "#ECE7DC"
                    :dim "#96928A" :track "#2C2F44" :glow "#9CA4DE")
        :light (list :material "#B2ACA2" :line "#C4BFB6" :shadow "#342E28" :shade 0.24
                     :shine "#FFFFFF" :gloss 0.55 :lo "#969087" :ink "#292928"
                     :dim "#5C5953" :track "#9E988F" :glow "#767066")))

;; The crown, in design pixels: 30 tall, standing 29 above its card's top edge
;; (the frame's five and its own fifteen less the six it laps back), its seam-side
;; end 40 in from the card's seam edge. Its type is set at the mock's sizes in IBM
;; Plex Mono, whose advance is 600/1000 of its size, so every segment's width is
;; known exactly here and the shader puts the swells and hairlines in the same
;; places. The gauges' values are 4 cells ("100%") and the VRAM's 5 ("16.3G"),
;; held for the widest reading so the crown never changes width under a load.
;; It is 26 tall rather than 30, stands 25 above its card rather than 29, and asks
;; the deck for the same 30 pixels of title row: any less and the crown's own
;; swell would be clipped by the top of the screen.
(defparameter +rail-halo--crown-height+ 26)
(defparameter +rail-halo--crown-inset+ 30)
(defparameter +rail-halo--pad+ 7)
(defparameter +rail-halo--trace+ 130)
(defparameter +rail-halo--bump+ 5)
(defparameter +rail-halo--clock-segment+ (list :size 15 :chars 5 :lead 10 :trail 12))
(defparameter +rail-halo--date-segment+ (list :size 12 :chars 6 :lead 10 :trail 10))
(defparameter +rail-halo--gauge-segment+ (list :label 11 :value 14 :lead 10 :gap 7 :trail 12))
(defparameter +rail-halo--value-cells+ (list :percent 4 :vram 5))

(defun rail-halo--advance (size)
  "IBM Plex Mono's advance at SIZE: 600 of its 1000 units."
  (* size 3/5))

(defun rail-halo--segment-width (segment chars)
  (+ (getf segment :lead) (* chars (rail-halo--advance (getf segment :size)))
     (getf segment :trail)))

(defun rail-halo--clock-width ()
  (rail-halo--segment-width +rail-halo--clock-segment+ (getf +rail-halo--clock-segment+ :chars)))

(defun rail-halo--date-width ()
  (rail-halo--segment-width +rail-halo--date-segment+ (getf +rail-halo--date-segment+ :chars)))

(defun rail-halo--gauge-width (vram-p)
  (+ (getf +rail-halo--gauge-segment+ :lead)
     (* 3 (rail-halo--advance (getf +rail-halo--gauge-segment+ :label)))
     (getf +rail-halo--gauge-segment+ :gap)
     (* (if vram-p (getf +rail-halo--value-cells+ :vram) (getf +rail-halo--value-cells+ :percent))
        (rail-halo--advance (getf +rail-halo--gauge-segment+ :value)))
     (getf +rail-halo--gauge-segment+ :trail)))

(defun rail-halo--crown-width (readings)
  "The crown's width in design pixels: its pads and the segments of the readings
it holds, the VRAM the long one."
  (+ (* 2 +rail-halo--pad+) (rail-halo--clock-width) (rail-halo--date-width)
     (loop for reading in readings
           for k from 0
           when reading sum (rail-halo--gauge-width (= k 3)))))

;;; Where the crown stands, in output pixels: its centre on the top edge of the
;;; card it crowns, its seam-side end +RAIL-HALO--CROWN-INSET+ in from that edge,
;;; and, with no card holding focus, top centre.
(defun rail-halo--anchor (box side cw scale)
  (values (if (eq side :left)
              (- (+ (getf box :x) (getf box :width)) (* scale +rail-halo--crown-inset+) (/ cw 2))
              (+ (getf box :x) (* scale +rail-halo--crown-inset+) (/ cw 2)))
          ;; a frame and a crown half-height above the card's top edge, less the
          ;; eight the capsule laps back into the frame: 5 + 13 - 8
          (- (getf box :y)
             (* scale (- (+ (getf +rail-halo--cast+ :frame) (/ +rail-halo--crown-height+ 2)) 8)))))

(defun rail-halo--top-anchor (seam output scale)
  (values (if seam
              (+ (getf seam :x) (floor (getf seam :width) 2))
              (+ (getf output :x) (floor (getf output :width) 2)))
          (+ (getf output :y) (* scale 16))))

(defun rail-halo--anchors (context cw scale)
  "Where the crown stands before and after this draw's focus change: the centres
of the capsule that end and start the siphon, in output pixels. Across the seam
it leaves the card focus left and lands on the new one; within a column it holds
the column's top while the cards scroll under it, so both ends are that one
point; with neither card there it stands top centre. The last value says the
crown hops across the seam, so its type must wait for it."
  (destructuring-bind (&key key side switch cut old carried seam output now &allow-other-keys)
      context
    (let* ((focus-box (getf key :box))
           (old-entry (and old (find old carried :key (lambda (entry) (getf entry :id)))))
           (old-box (and old-entry (getf old-entry :box)))
           (from (and switch (getf switch :from)))
           (moving (and switch (not cut) (< (- now (getf switch :at)) (rail--settle switch)))))
      (multiple-value-bind (ex ey)
          (if (and focus-box side)
              (rail-halo--anchor focus-box side cw scale)
              (rail-halo--top-anchor seam output scale))
        (multiple-value-bind (sx sy)
            (cond
              ((not moving) (values ex ey))
              ;; within a column: the column's top, whichever card's box shows it
              ((and focus-box (eq from side))
               (rail-halo--anchor (if (and old-box (< (getf old-box :y) (getf focus-box :y)))
                                      old-box focus-box)
                                  side cw scale))
              ((and old-box (member from '(:left :right)))
               (rail-halo--anchor old-box from cw scale))
              ((or (null from) (eq from :free))
               (rail-halo--top-anchor seam output scale))
              (t (values ex ey)))
          (list sx sy ex ey
                (and moving (< (- now (getf switch :at)) (rail-halo--hop-time switch))
                     (not (eq from side)))))))))

(defun rail-halo--numbers (readings sx sy ex ey scale)
  "The theme's own numbers for halo.glsl, in the order the shader reads them: the
palette, the crown's shape and type metrics, its two anchors, its hairline and
the strength of its shadow."
  (let ((px (lambda (value) (* value scale))))
    (append (kit--colors '(:material :line :shadow :shine :lo :ink :dim :track :glow))
            (list (funcall px (getf +rail-halo--cast+ :frame))
                  (funcall px (getf +rail-halo--cast+ :line-width))
                  (funcall px (getf +rail-halo--cast+ :radius))
                  (funcall px (/ +rail-halo--crown-height+ 2))
                  (funcall px +rail-halo--pad+)
                  (funcall px (rail-halo--clock-width))
                  (funcall px (rail-halo--date-width))
                  (funcall px (rail-halo--gauge-width nil))
                  (funcall px (rail-halo--gauge-width nil))
                  (funcall px (rail-halo--gauge-width nil))
                  (funcall px (rail-halo--gauge-width t))
                  (funcall px +rail-halo--crown-inset+)
                  (funcall px +rail-halo--trace+)
                  (funcall px +rail-halo--bump+)
                  sx sy ex ey
                  (funcall px 6)
                  (getf (getf +rail-halo--cast+ *rail--mode*) :shade)))))

;;; The crown's type: one row of fixed cells, each holding its text the mock's
;;; distance in, so the shader's bumps and hairlines fall exactly under the
;;; numbers they belong to however the font hints.
(defun rail-halo--type (readings ink dim &optional ground)
  "The crown's type, on GROUND when no card holds focus and the shader has no
card to hang the crown on: a flat capsule of the cast material instead."
  (labels ((cell (width &rest children)
             (ui :row :width (rail--design width)
                 :height (rail--design +rail-halo--crown-height+)
                 :align :center :justify :start
                 :padding (list 0 0 0 (rail--design 10))
                 :children children))
           (gap (width) (ui :rect :width (rail--design width) :height 1)))
    (ui :row :height (rail--design +rail-halo--crown-height+) :align :center
        :radius (rail--design (/ +rail-halo--crown-height+ 2))
        :background (or ground "#00000000")
        :children
        (append
         (list (gap +rail-halo--pad+)
               (cell (rail-halo--clock-width)
                     (rail--text (clock-text "%H:%M") ink 15 15))
               (cell (rail-halo--date-width)
                     (rail--text (string-upcase (clock-text "%a %d")) dim 12 12)))
         (loop for reading in readings
               for k from 0
               when reading
                 append (list (cell (rail-halo--gauge-width (= k 3))
                                    (rail--text (getf reading :label) dim 11 11)
                                    (gap 7)
                                    (rail--text (getf reading :value) ink 14 14))))
         (list (gap +rail-halo--pad+))))))

(defun rail-halo--reveal (context now)
  "A timer that draws once more when this switch's crown has landed, so the
crown's type, hidden for the hop across the seam, comes back without waiting for
the next sample."
  (let* ((switch (getf context :switch))
         (age (- now (getf switch :at)))
         (left (- (rail-halo--hop-time switch) age)))
    (list (interval :halo-land (max 16 (ceiling (* 1000 (+ left 0.03d0))))))))

(defun rail-halo--draw (look context)
  "HALO: the frames, the crown and the voice in one shader over the output, the
crown's type on a surface of its own at the crown's seated place."
  (destructuring-bind (&key state output layer now &allow-other-keys) context
    (let* ((scale *rail--scale*)
           (readings (kit--readings state))
           (cw (* scale (rail-halo--crown-width readings)))
           (ink (or (rail--material :ink) (rail--ink)))
           (dim (or (rail--material :dim) (rail--label))))
      (destructuring-bind (sx sy ex ey hop) (rail-halo--anchors context cw scale)
        ;; with no card holding focus -- the peek, an empty desktop -- the
        ;; readings stand at the top centre; the type brings its own capsule so
        ;; they read even when no card leaves the shader a ring to draw in
        (let* ((rests (and (getf context :key) t))
               (theme (rail-halo--numbers readings sx sy ex ey scale)))
          (append
           (kit--frames look context theme :reach 56)
           (list (shell-surface
                  :rail-halo-type (rail-halo--type readings ink dim
                                                   (unless rests (rail--material :material)))
                  :output (getf output :name) :anchors '(:top :left)
                  :width (rail--design cw)
                  :height (rail--design (* scale +rail-halo--crown-height+))
                  :margin (rail--surface-margin
                           output (- ex (/ cw 2))
                           (- ey (* scale (/ +rail-halo--crown-height+ 2))))
                  :layer layer :background "#00000000" :click-through t
                  :visible (not hop)))
                 (when hop (rail-halo--reveal context now))))))))

(defparameter +rail-halo+
  (list :draw #'rail-halo--draw :cast +rail-halo--cast+
        :font "IBM Plex Mono Medium" :settle +rail-halo--settle+ :radius 14
        :frame (list :edge 14 :title 30 :seam 20)))
