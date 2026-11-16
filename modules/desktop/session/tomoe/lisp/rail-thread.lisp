(in-package #:tomoe-user)

;;; THREAD: liquid glass on a thin seam
;;;
;;; A 34 px seam with one glass thread down its middle, 11 px wide and as tall
;;; as the cards, carrying the readings as beads: the clock (hours over
;;; minutes), the date (day over month), CPU, memory, bolo's voice at the weld,
;;; the GPU and the VRAM. Each gauge bead holds a level of denser glass from its
;;; foot up to its load, with a small label and its value. The focused card
;;; wears a 5 px glass rim welded to the thread by a meniscus at the weld; every
;;; other card keeps only a dark and a light hairline. A switch across the seam
;;; bends the thread after the new side and drains the old rim back into the
;;; thread while the new one fills out of the weld both ways; within a column
;;; the weld stays and the rims only drain and fill. bolo's turn plucks the
;;; thread -- a travelling wave out from the weld, the beads the nodes of the
;;; string, the voice bead swelling -- and the wave runs round the focused rim,
;;; which thickens and brightens as it passes, all dying away over the settle.
;;;
;;; shaders/thread.glsl draws every one of those, the readings included: this
;;; file only lays the beads out for it -- where each hangs, how tall it is, how
;;; its centre and the weld sit on the cards the deck gives -- in output pixels.
;;; Both modes share one set of glass numbers (the mock's), so the glass follows
;;; whatever lies under it; the type takes its ink from that same backdrop, per
;;; bead, so the readout holds on a dark and on a light wallpaper alike.

(defparameter +rail-thread--width+ 34)
(defparameter +rail-thread--settle+ 0.8d0)

;; How far round the cards this theme's shader is told it may repaint. The rail
;; stands in the seam, not on a card: the band's far side is the 76 px seam less
;; its two window gaps away from the card beside it -- 68 px, the way a narrow
;; output's focal frame lays it out -- and the readout and the thread's own glass
;; reach another 26 beyond the band's middle. A ring narrower than that leaves
;; the outer half of the readings out of the picture whenever the compositor
;; repaints only the rings (a switch in flight) or hands the surface a new
;; buffer (an output mode change), which is how the labels came out cut at the
;; screen's edge.
(defparameter +rail-thread--reach+ 80)

;; Each bead in the mock's 1412 px card: its kind, how far above the weld its
;; centre hangs (negative below it), and half its height. The order is the
;; shader's -- clock, date, cpu, memory, voice, gpu, vram -- and the voice bead
;; sits on the weld itself.
;;
;; Three beads hang above the voice dot and three below, a bead every 118 px of
;; the mock, so the run is symmetric about it: the time at the top, the date at
;; the bottom, the four gauges either side of the middle where the mock has them.
;; The voice dot is the run's centre, not its fifth bead.
(defparameter +rail-thread--beads+
  '((:clock -388 40) (:date 388 30) (:cpu -270 50) (:mem -152 50)
    (:voice 0 30) (:gpu 152 50) (:vram 270 50)))

(defun rail-thread--strip (context)
  "The strip the thread stands in: the deck's seam as it lays it out, or -- on an
output the deck gives no seam (an empty desktop, a fullscreen card) -- a strip
down the middle of the output, inset as the frame insets the cards."
  (or (getf context :seam)
      (let ((output (getf context :output)) (inset 14))
        (list :output (getf output :name)
              :x (- (+ (getf output :x) (floor (getf output :width) 2))
                    (floor (rail--seam-width) 2))
              :y (+ (getf output :y) inset)
              :width (rail--seam-width)
              :height (- (getf output :height) (* 2 inset))))))

(defun rail-thread--layout (strip)
  "The thread's geometry in output pixels from the deck's STRIP: its centre, the
cards' top and bottom, the weld's height, and each bead's centre and halves."
  (let* ((y0 (getf strip :y))
         (height (getf strip :height))
         (weld (+ y0 (floor height 2)))
         (x (+ (getf strip :x) (floor (getf strip :width) 2)))
         (px (lambda (offset) (round (* offset height) 1412))))
    (list :x x :top y0 :bottom (+ y0 height) :weld weld
          :beads (loop for (kind offset hy) in +rail-thread--beads+
                       collect (list kind (+ weld (funcall px offset)) (funcall px hy) 14)))))

;;; What a card without focus keeps round it, in the order +RAIL--THREAD-STYLES+:
;;; the hairline pair the mock draws, a dimmer dark line alone, nothing at all,
;;; or nothing under a soft halo round the focused card's rim. The rail names
;;; one in user.ui.tomoe.bar.rail.focus.
(defparameter +rail--thread-styles+ '(:hairline :dim :recede :glow))

(defun rail-thread--style ()
  (or (position (getf +rail+ :focus) +rail--thread-styles+)
      (position :glow +rail--thread-styles+)))

(defun rail-thread--value-lengths (state)
  "The four readings' values as character counts, so the shader centres each one
by the width its characters really take."
  (loop for reading in (kit--readings state)
        collect (if reading (min 6 (length (getf reading :value))) 0)))

(defun rail-thread--numbers (layout state)
  "The theme's own numbers for the shader, in the order thread.glsl reads them:
the glass's shape and motion, then where the thread stands, then each bead's
centre, half height and half width, then the values' widths and the unfocused
treatment."
  (append (list 5.5d0      ; half the thread's width
                5d0        ; the focused card's rim
                20d0       ; how far the rim and the thread weld
                64d0       ; how far the weld reaches up and down
                14d0       ; the cards' corner radius
                3200d0     ; px/s the voice runs along the thread and the rim
                7d0        ; how far a full voice pulls the thread
                0.0526316d0  ; radians per pixel of the pluck's wave
                34d0       ; radians per second it travels
                0.0011111d0  ; how fast it dies away from the weld
                9d0        ; how far a switch bends the thread
                0.14d0     ; seconds the bend takes to die
                46d0       ; radians per second it rings at
                260d0      ; pixels up and down the bend reaches
                0.12d0     ; seconds after a switch the new rim waits
                0.32d0     ; and how long it takes to fill
                0.2d0      ; seconds the old rim drains in
                (getf layout :x) (getf layout :top) (getf layout :bottom) (getf layout :weld))
          (loop for (kind cy hy hw) in (getf layout :beads) append (list cy hy hw))
          (mapcar (lambda (n) (coerce n 'double-float)) (rail-thread--value-lengths state))
          (list (coerce (rail-thread--style) 'double-float))))

;;; The readout is set in the shader itself (shaders/thread.glsl), in the ink
;;; the backdrop behind each bead calls for, so the theme carries no type
;;; surface: a still thread redraws nothing at all, not even on the minute.

(defun rail-thread--whole (look context theme)
  "The theme's one surface drawn whole, for the times there is no card for the
compositor's reach ring to hang on -- an empty desktop, a peek that has hidden
every card. KIT--FRAMES confines its shader to the ring round the cards it
carries; with no card that ring is empty, and a shell shader refuses a :REACH of
0, so this surface names none: the shader covers the whole output once and then
holds the picture, and the thread and its readings still stand in the seam.
(It is KIT--FRAMES with the :REACH left out; fold it back if the kit learns to
read a zero reach as no reach.)"
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
                              :until (kit--until look context))))
     (unless (getf +rail+ :focus-border)
       (loop for entry in carried
             collect (window-properties
                      (getf entry :id)
                      :radius (rail--design (getf look :radius 0))
                      :border (list :focused "#00000000" :unfocused "#00000000")))))))

(defparameter +rail-thread--strip-height+ 96)

(defun rail-thread--bar-numbers (context strip)
  "THREAD's numbers for a bar: the glass's shape from the strip's own layout, then
the flag that says which bar this is, its rect and its blocks."
  (append (rail-thread--numbers (rail-thread--layout strip) (getf context :state))
          (list (if (eq (getf strip :place) :top) 1d0 2d0))
          (rail--shader-rect (getf context :output) strip)
          (rail--block-data strip (rail--bar-blocks (getf context :state)
                                                    (getf context :snapshot) strip))))

(defun rail-thread--draw (look context)
  "THREAD: the glass thread with its beads, the readings in their glass and the
focused card's rim, all in one shader over the output -- and on an output the
deck gives no seam, a thread along each bar with a glass cell per reading."
  (destructuring-bind (&key state snapshot output strips &allow-other-keys) context
    (let* ((seam (find :seam strips :key (lambda (strip) (getf strip :place))))
           (bars (remove seam strips)))
      (if seam
          (let ((theme (rail-thread--numbers
                        (rail-thread--layout (rail-thread--strip context))
                        state)))
            (if (getf context :windows)
                (kit--frames look context theme :reach +rail-thread--reach+)
                (rail-thread--whole look context theme)))
          (append
           (kit--frames look context
                        (append (rail-thread--numbers (rail-thread--layout (first bars)) state)
                                (list 3d0))
                        :reach +rail-thread--reach+)
           (loop for strip in bars
                 for blocks = (rail--bar-blocks state snapshot strip)
                 for tag = (format nil "-~A" (string-upcase (symbol-name (getf strip :place))))
                 when blocks
                   append
                   (list
                    (shell-surface
                     (intern (format nil "RAIL-THREAD-BAR~A" tag) :keyword)
                     (ui :stack)
                     :output (getf output :name)
                     :anchors (list (getf strip :place))
                     :width (rail--design (getf strip :width))
                     :height (rail--design (getf strip :height))
                     :margin 0
                     :layer (getf context :layer) :click-through t
                     :exclusive-zone (rail--design (getf strip :height))
                     :background (list :shader (getf look :shader)
                                       :data (rail-thread--bar-numbers context strip)
                                       :clock (getf context :epoch)
                                       :until (kit--until look context)))
                    (shell-surface
                     (intern (format nil "RAIL-THREAD-TYPE~A" tag) :keyword)
                     (rail--web state snapshot strip blocks
                                (or (rail--material :ink) (rail--ink)))
                     :output (getf output :name)
                     :anchors (list (getf strip :place))
                     :width (rail--design (getf strip :width))
                     :height (rail--design (getf strip :height))
                     :margin 0
                     :layer (getf context :layer) :background "#00000000"
                     :click-through t :slide t))))))))



(defparameter +rail-thread+
  (list :draw #'rail-thread--draw :settle +rail-thread--settle+
        :strip-height +rail-thread--strip-height+
        :radius 14 :frame (list :edge 14 :title 0 :seam +rail-thread--width+)))
