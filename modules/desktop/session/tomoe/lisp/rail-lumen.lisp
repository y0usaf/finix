(in-package #:tomoe-user)

;;; lumen
;;;
;;; Pixel as light rather than matter. Every frame is one row of LED dots five
;;; pixels from dot to dot in the ten pixels round its card, so the two columns'
;;; rings meet in a single shared column of dots down the middle of the seam and
;;; the corners of every ring land on a dot. A card out of focus is unlit dots --
;;; slate in the dark, warm grey on paper -- with its title lit dim; the focused
;;; card's ring is lit, warm white with a halo in the dark and ink with a faint
;;; darkening one on paper, and its top edge carries a five-row dot-matrix
;;; readout: the title at the left, a scope for bolo's voice beside it, then
;;; CPU, MEM, GPU and VRAM each as a label, a twelve-dot bar and its value, and
;;; the clock and the date at the right, three dots by five a character, so the
;;; readout is made of the same dots the ring is.
;;;
;;; A focus change is a marquee chase: a bright head starts at the point of the
;;; new ring nearest the old card -- at the title's corner for a change within a
;;; column -- and runs both ways round it at nine thousand pixels a second,
;;; lighting the dots behind it and the readout's columns as it reaches them,
;;; while the old frame fades on a phosphor afterglow in a fifth of a second.
;;; The voice is a VU chase: every dot of the focused ring takes the level the
;;; voice had when the chase, which starts at the title's corner, ran that far
;;; round it, spikes of one or two dots stand off its sides and bottom with that
;;; level, and the readout's scope scrolls the level history, newest at its
;;; right; it all dies away over the settle. Only the focused card's ring and
;;; readout ever move, and the surface holds its last picture once they are
;;; still, so a still rail draws nothing.
;;;
;;; One shader (shaders/lumen.glsl) draws all of it over the output from the
;;; numbers lisp/rail-kit.lisp packs: the cards, the switch, bolo's levels, the
;;; readings and the clock. Each fragment costs a few dots -- the nearest dot of
;;; a ring or of the readout and the two beside it, for their share of the halo
;;; -- so the halo of a whole ring is never walked.

(defparameter +rail-lumen--cast+
  (list :dark (list :on "#F0EADC" :off "#282A3C" :glow "#969CD2" :hot "#FFFFFF"
                    :halo 0.42d0)
        :light (list :on "#262628" :off "#CECAC2" :glow "#3C3A46" :hot "#000000"
                     :halo 0.13d0)))

;; SHAPE: the ring's distance outside its card (:OUT), the spacing of the dots
;; (:PITCH) and a dot's radius (:DOT), and the pixels a second the marquee
;; (:CHASE) and the voice (:VU) run round a frame.
(defparameter +rail-lumen--shape+
  (list :out 10d0 :pitch 5d0 :dot 2.1d0 :chase 9000d0 :vu 4200d0))

;; The readout stands five rows above the ring, so the frame asks for 20 pixels
;; of title row above every card as well as 20 at the sides (the ring's ten and
;; ten of air), and 20 of seam: two rings' ten, meeting in one shared column.
(defparameter +rail-lumen--reach+ 42)

;; The band the readings fall back to with no card in focus: a scope, the four
;; gauges, the clock and the date, the same dots as a card's readout.
(defparameter +rail-lumen--free-cols+ 291)

;; The readout's text items -- the title, the clock, the date, the four labels
;; and the four values -- which the shader walks in one loop (the values' and the
;; titles' lengths come with the numbers, so it walks them without measuring
;; anything), and the passes it draws the frames in: the other cards, the focused
;; one, then the fallback band.
(defparameter +rail-lumen--items+ 11)
(defparameter +rail-lumen--passes+ 3)

(defun rail-lumen--value-lengths (state)
  "The four readings' values as character counts, left out of the shader's walk
so it need not measure them for itself."
  (loop for reading in (kit--readings state)
        collect (if reading (min 4 (length (getf reading :value))) 0)))

(defun rail-lumen--title-lengths (snapshot windows)
  "How many characters each of the railed cards' titles has, in the order the
shader's walk reads them, so it need not measure them itself."
  (loop for i below 8
        for id = (nth i windows)
        collect (if id (min 12 (length (kit--title snapshot id))) 0)))

(defun rail-lumen--numbers (free state snapshot windows)
  "Every number the shader reads after the kit's: the palette, the shape, whether
this is the fallback band rather than a card's ring, and the walk's bounds."
  (append (kit--colors '(:on :off :glow :hot))
          (list (getf +rail-lumen--shape+ :out)
                (getf +rail-lumen--shape+ :pitch)
                (getf +rail-lumen--shape+ :dot)
                (getf +rail-lumen--shape+ :chase)
                (getf +rail-lumen--shape+ :vu)
                ;; how strongly a lit dot lights its halo: on paper the same
                ;; number darkens it instead
                (rail--material :halo)
                (if free 1d0 0d0)
                (coerce +rail-lumen--items+ 'double-float)
                (coerce +rail-lumen--passes+ 'double-float))
          (mapcar (lambda (n) (coerce n 'double-float))
                  (rail-lumen--value-lengths state))
          (mapcar (lambda (n) (coerce n 'double-float))
                  (rail-lumen--title-lengths snapshot windows))))

(defun rail-lumen--theme (free context)
  "RAIL-LUMEN--NUMBERS for CONTEXT, drawn for the fallback band when FREE."
  (rail-lumen--numbers free (getf context :state) (getf context :snapshot)
                       (getf context :windows)))

(defun rail-lumen--free (look context)
  "The band the readings stand as with no card in focus -- a peek, an empty
desktop. KIT--FRAMES is drawn only within :REACH of the cards it carries, and
with none carried that ring is empty, so this is a surface of its own, no reach,
no card and exactly as wide as its dots, held at the top centre of the output."
  (destructuring-bind (&key output epoch layer &allow-other-keys) context
    (let* ((pitch (getf +rail-lumen--shape+ :pitch))
           (width (+ (* (1- +rail-lumen--free-cols+) pitch) 12))
           (height (+ (* 4 pitch) 12))
           (x (+ (getf output :x) (floor (- (getf output :width) width) 2)))
           (y (+ (getf output :y) 4)))
      (shell-surface
       :rail-lumen-free (ui :stack)
       :output (getf output :name) :anchors '(:top :left)
       :width (rail--design width) :height (rail--design height)
       :margin (rail--surface-margin output x y)
       :layer layer :click-through t
       :background (list :shader (getf look :shader)
                         :data (kit--data look context (rail-lumen--theme t context))
                         :clock epoch :until (kit--until look context))))))

(defun rail-lumen--draw (look context)
  "lumen: the ring of LED dots round every card the rail carries, the focused
card's dot-matrix readout over its top edge, and -- with no card in focus -- the
readings as one band at the top centre, all from CONTEXT."
  (append
   (kit--frames look context (rail-lumen--theme nil context) :reach +rail-lumen--reach+)
   (unless (getf context :key)
     (list (rail-lumen--free look context)))))

(defparameter +rail-lumen+
  (list :draw #'rail-lumen--draw :cast +rail-lumen--cast+ :settle 0.6d0 :radius 14
        :frame (list :edge 20 :title 20 :seam 20)))
