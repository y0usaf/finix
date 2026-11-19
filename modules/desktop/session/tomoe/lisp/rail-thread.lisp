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
;;; The mock's beads, in the order they hang along the thread: each its kind, how far
;;; its centre stands above the weld (negative below it) and half its height, in the
;;; 1412 px of the mock's card. The voice bead sits on the weld itself, three beads
;;; above it and three below, so the run is symmetric.
(defparameter +rail-thread--mock+
  '((:time -388 40) (:cpu -270 50) (:memory -152 50) (:voice 0 30)
    (:gpu 152 50) (:vram 270 50) (:date 388 30)))

;;; The order the shader reads its beads in: the clock, the date, CPU, memory, the
;;; voice at the weld, the GPU and the VRAM.
(defparameter +rail-thread--bead-order+ '(:time :date :cpu :memory :voice :gpu :vram))

(defun rail-thread--layout (strip)
  "The thread's geometry in output pixels from the deck's STRIP: its centre, the
cards' top and bottom, the weld's height, and each bead's centre and halves -- the
mock's beads placed by the shared placement, symmetric about the weld."
  (let* ((y0 (getf strip :y))
         (height (getf strip :height))
         (weld (+ y0 (floor height 2)))
         (x (+ (getf strip :x) (floor (getf strip :width) 2)))
         (px (lambda (offset) (round (* offset height) 1412)))
         (mock (loop for (kind offset half) in +rail-thread--mock+
                     collect (list kind (- (funcall px offset) (funcall px half))
                                   (* 2 (funcall px half)))))
         (specs (loop for i below (length mock)
                      for (kind start size) = (nth i mock)
                      for previous = (and (plusp i) (nth (1- i) mock))
                      collect (list kind size
                                    (if previous
                                        (- start (+ (second previous) (third previous)))
                                        0))))
         (anchor (loop for (kind start size) in mock when (eq kind :voice) return (cons kind start)))
         (placed (rail--place specs anchor 1 nil))
         (by-kind (loop for (kind start size) in placed
                        collect (list kind
                                      (+ weld start (/ size 2))
                                      (/ size 2)
                                      14))))
    (list :x x :top y0 :bottom (+ y0 height) :weld weld
          :beads (loop for kind in +rail-thread--bead-order+
                       for bead = (find kind by-kind :key #'first)
                       when bead collect bead))))

(defun rail-thread--placed (state strip)
  "RAIL-THREAD--LAYOUT of STRIP, laid out again only when the strip has moved."
  (rail--memo state :thread-layout strip (lambda () (rail-thread--layout strip))))

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
                0.32d0     ; and how long it takes to fill, where the move ends
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

(defparameter +rail-thread--strip-height+ 48)

(defun rail-thread--bar-layout (strip state)
  "Horizontal thread geometry in surface-local pixels for a top or bottom bar:
a thin 11 px filament running the full length of the bar with 28 px tall beads
(matching the vertical seam's 28 px wide beads) clustered symmetrically at center."
  (let* ((width (coerce (getf strip :width) 'double-float))
         (height (coerce (getf strip :height) 'double-float))
         (mid-x (* 0.5d0 width))
         (mid-y (* 0.5d0 height))
         (top-p (eq (getf strip :place) :top))
         (gpu-p (probe--gpu-p (getf state :gpu)))
         (specs
           (if top-p
               (list (list :time (- mid-x 74d0) 46d0 14d0)
                     (list :date (+ mid-x 64d0) 56d0 14d0))
               (if gpu-p
                   (list (list :cpu (- mid-x 226d0) 48d0 14d0)
                         (list :memory (- mid-x 102d0) 48d0 14d0)
                         (list :voice mid-x 26d0 14d0)
                         (list :gpu (+ mid-x 102d0) 48d0 14d0)
                         (list :vram (+ mid-x 226d0) 48d0 14d0))
                   (list (list :cpu (- mid-x 102d0) 48d0 14d0)
                         (list :voice mid-x 26d0 14d0)
                         (list :memory (+ mid-x 102d0) 48d0 14d0))))))
    (list :x mid-y :top 10d0 :bottom (- width 10d0) :weld mid-x
          :beads (loop for kind in +rail-thread--bead-order+
                       for found = (find kind specs :key #'first)
                       collect (or found (list kind 0d0 0d0 0d0))))))

(defun rail-thread--bar-numbers (context strip)
  "THREAD's numbers for a bar, laid out for a surface that is the strip itself:
the corner its backdrop is read from, the thread's half width, the bar's mode --
1 along the top edge, 2 along the bottom, 4 down a side -- its own rect, and each
block's kind and rect in the surface's pixels, y up."
  (let* ((blocks (getf strip :blocks))
         (height (getf strip :height)))
    (append (list 0d0 0d0 5.5d0)
            (list (case (getf strip :place)
                    (:top 1d0) (:bottom 2d0) (t 4d0)))
            (list 0d0 0d0 (getf strip :width) height)
            (list (length blocks))
            (loop for (module x y width block-height) in blocks
                  append (list (rail--kind module) x (- height y block-height)
                               (+ x width) (- height y))))))

(defun rail-thread--draw (look context)
  "THREAD: the glass thread with its beads, the readings in their glass and the
focused card's rim, all in one shader over the output -- the seam and its beads
when the rail stands in a seam, else the frames alone and a glass bar along each
strip the config places. A theme drawn the same way with numbers of its own
names them in LOOK as :NUMBERS and :BAR-NUMBERS."
  (destructuring-bind (&key state snapshot output strips &allow-other-keys) context
    (let* ((numbers (getf look :numbers #'rail-thread--numbers))
           (bar-numbers (getf look :bar-numbers #'rail-thread--bar-numbers))
           (seam (find :seam strips :key (lambda (strip) (getf strip :place))))
           (bars (remove seam strips))
           (vertical (find-if (lambda (strip) (eq (getf strip :axis) :y)) bars))
           (frame-strip (or seam vertical (first bars))))
      (append
       (if seam
           (let ((theme (funcall numbers (rail-thread--placed state seam) state)))
             (if (getf context :windows)
                 (kit--frames look context theme :reach +rail-thread--reach+)
                 (rail-thread--whole look context theme)))
           (when (and frame-strip (getf context :windows))
             (kit--frames look context
                          (append (funcall numbers (rail-thread--placed state frame-strip) state)
                                  (list 3d0))
                          :reach +rail-thread--reach+)))
       (loop for strip in bars
             for blocks = (getf strip :blocks)
             for horiz = (eq (getf strip :axis) :x)
             for tag = (format nil "-~A" (string-upcase (symbol-name (getf strip :place))))
             when blocks
               append
               (if horiz
                   (let* ((bar-context (list* :output (list :x 0 :y 0
                                                            :width (getf strip :width)
                                                            :height (getf strip :height))
                                              :windows nil
                                              context))
                          (bar-mode (if (eq (getf strip :place) :top) 1d0 2d0))
                          (theme (append (funcall numbers (rail-thread--bar-layout strip state) state)
                                         (list bar-mode))))
                     (list
                      (shell-surface
                       (intern (format nil "RAIL-THREAD-BAR~A" tag) :keyword)
                       (ui :stack)
                       :output (getf output :name)
                       :anchors (if (getf strip :edge) (list (getf strip :edge)) '(:top :left))
                       :width (rail--design (getf strip :width))
                       :height (rail--design (getf strip :height))
                       :margin (if (getf strip :edge) 0
                                   (rail--surface-margin output (getf strip :x) (getf strip :y)))
                       :exclusive-zone (getf strip :zone 0)
                       :layer (getf context :layer) :click-through t
                       :background (list :shader (getf look :shader)
                                         :data (kit--data look bar-context theme)
                                         :clock (getf context :epoch)
                                         :until (kit--until look context)))))
                   (list
                    (shell-surface
                     (intern (format nil "RAIL-THREAD-BAR~A" tag) :keyword)
                     (ui :stack)
                     :output (getf output :name)
                     :anchors (if (getf strip :edge) (list (getf strip :edge)) '(:top :left))
                     :width (rail--design (getf strip :width))
                     :height (rail--design (getf strip :height))
                     :margin (if (getf strip :edge) 0
                                 (rail--surface-margin output (getf strip :x) (getf strip :y)))
                     :exclusive-zone (getf strip :zone 0)
                     :layer (getf context :layer) :click-through t
                     :background (list :shader (getf look :bar-shader (getf look :shader))
                                       :data (funcall bar-numbers context strip)
                                       :clock (getf context :epoch)
                                       :until (kit--until look context)))
                    (shell-surface
                     (intern (format nil "RAIL-THREAD-TYPE~A" tag) :keyword)
                     (rail--web state snapshot strip blocks
                                (or (rail--material :ink) (rail--ink)))
                     :output (getf output :name)
                     :anchors (if (getf strip :edge) (list (getf strip :edge)) '(:top :left))
                     :width (rail--design (getf strip :width))
                     :height (rail--design (getf strip :height))
                     :margin (if (getf strip :edge) 0
                                 (rail--surface-margin output (getf strip :x) (getf strip :y)))
                     :layer (getf context :layer) :background "#00000000"
                     :click-through t :slide t))))))))

(defparameter +rail-thread+
  (list :draw #'rail-thread--draw :settle +rail-thread--settle+
        :strip-height +rail-thread--strip-height+
        :radius 14 :frame (list :edge 14 :title 0 :seam +rail-thread--width+)
        :trail (list :cell 4d0 :life 0.16d0 :steps 3 :shape :dots
                     :dark :ink :light :ink)))
