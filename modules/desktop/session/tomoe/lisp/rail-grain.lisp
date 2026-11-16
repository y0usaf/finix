(in-package #:tomoe-user)

;;; grain
;;;
;;; Pixel sand on glass's footprint. A card's frame is one rule of four pixel
;;; grains on the third art pixel outside its content, cut square at the corners,
;;; every grain its own tone and a few catching the light. The deck's seam is
;;; five art pixels wide, so both columns' third art pixel is the same column:
;;; the two columns' rules meet there by construction and are joined wherever
;;; two cards stand side by side, and the focused card's frame is doubled -- a
;;; second rule on the first art pixel outside its content, so the neighbour's
;;; single rule runs on through the seam as the focused frame's outer edge.
;;;
;;; The focused card's top rule carries, set into it in a three-by-five pixel
;;; type of four-pixel cells, its own title in the rule's ink -- typed in
;;; behind the pour when the card takes focus, never on a plate of its own -- a
;;; small compartment beside the title for bolo's voice, and at its right end a
;;; sand compartment for each reading: a label, a recessed box whose sand fills
;;; from the floor left to right with a grain falling in while the reading
;;; climbs, and the value; then the clock cast in sand digits and the date. The
;;; rule opens round each of them, and the inner rule runs on beneath them as
;;; the shelf they stand on.
;;;
;;; Focus is a pour. The frame that loses focus lets go: its rules run back
;;; along themselves into the point nearest the card taking focus, its type and
;;; sand drop a little and are gone. The new frame is poured from there both
;;; ways along its rules -- grains landing out of a small arc ahead of the
;;; front, the title typing in behind it -- while a short stream of grains
;;; crosses from the old frame to the new across the seam and sparks fly where
;;; the two fronts meet, stepped at twenty a second. Within a column the pour
;;; starts at the title corner. Every grain's place, tone and jump is a closed
;;; form of its cell, the time since the switch and a hash of that cell: the
;;; shader integrates nothing and nothing is simulated, so it can draw any
;;; instant of the motion and draws nothing at all once it has landed.
;;;
;;; Bolo's voice jumps every grain of the focused double rule off the frame --
;;; outward, nought to three art pixels -- by the level the voice had when it
;;; ran that far round from the title, hot grains glinting, and the bed in the
;;; compartment beside the title hops with the last three quarters of a second
;;; of the level history. Only the focused card's own rules move, and the hops
;;; shrink with the same envelope as the rest of the bar when the turn closes.
;;;
;;; The palette is GRAIN's: morph's ground tones in dark over near black, warm
;;; dark grains on paper in light, one line colour and one glint.

;; :INK is the one colour the rail's type draws on a bar in, and :TONES the four
;; the rule itself is grained from -- the cast's ink is a list of tones, and the
;; rail's type takes a colour, not a list of them.
(defparameter +rail-grain--cast+
  (list :dark (list :line "#40435C" :name "#84817A" :dim "#969288" :box "#545978"
                    :glint "#FFFDF4"
                    :frame '("#70769C" "#8086AC" "#606588" "#969BBE")
                    :ink "#ECE7DC"
                    :tones '("#ECE7DC" "#D0CABE" "#B0AA9E" "#DCD6CA"))
        :light (list :line "#A8A39A" :name "#7C7868" :dim "#605C56" :box "#969087"
                     :glint "#FFFFFF"
                     :frame '("#78736A" "#646058" "#8C877E" "#524F49")
                     :ink "#292928"
                     :tones '("#292928" "#44423E" "#605D57" "#383734"))))

(defparameter +rail-grain--pour+ 10400d0)    ; pixels a second the pour runs (2600 art px)
(defparameter +rail-grain--crumble+ 12000d0) ; and the old frame's rules run back (3000)
(defparameter +rail-grain--fall+ 1200d0)     ; pixels a second squared its type and sand drop (300)

(defun rail-grain--tone (key)
  "KEY of the cast in the current mode, its four tones as twelve reals, in the
order grain.glsl reads them."
  (loop for hex in (rail--material key) append (rail--rgb hex)))

(defun rail-grain--theme ()
  "Every colour and speed grain's shader reads, after the kit's own numbers:
the line, the unfocused title's ink, the glint, the dim and the compartments'
frames, then the frame's four tones and the ink's four, then the pour's speed,
the crumble and the fall."
  (append (kit--colors '(:line :name :glint :dim :box))
          (rail-grain--tone :frame)
          (rail-grain--tone :tones)
          (list +rail-grain--pour+ +rail-grain--crumble+ +rail-grain--fall+)))

(defparameter +rail-grain--strip-height+ 48)

(defun rail-grain--bar (look context strip)
  "GRAIN on a bar: one rule of grains along the strip's inner edge, the readings
set above it in the theme's own ink."
  (destructuring-bind (&key state snapshot output epoch layer &allow-other-keys) context
    (let ((blocks (rail--bar-blocks state snapshot strip)))
      (append
       (list (shell-surface
              (intern (format nil "RAIL-GRAIN-~A"
                              (string-upcase (symbol-name (getf strip :place))))
                      :keyword)
              (ui :stack)
              :output (getf output :name)
              :anchors (list (getf strip :place))
              :width (rail--design (getf strip :width))
              :height (rail--design (getf strip :height))
              :margin 0
              :layer layer :click-through t
              :exclusive-zone (rail--design (getf strip :height))
              :background (list :shader (getf look :shader)
                                :data (append (rail-grain--theme)
                                              (list (if (eq (getf strip :place) :top) 1d0 2d0))
                                              (rail--shader-rect output strip))
                                :clock epoch
                                :until (kit--until look context)))
             (shell-surface
              (intern (format nil "RAIL-GRAIN-TYPE-~A"
                              (string-upcase (symbol-name (getf strip :place))))
                      :keyword)
              (rail--web state snapshot strip blocks (rail--ink))
              :output (getf output :name)
              :anchors (list (getf strip :place))
              :width (rail--design (getf strip :width))
              :height (rail--design (getf strip :height))
              :margin 0
              :layer layer :background "#00000000" :click-through t :slide t))))))

(defun rail-grain--draw (look context)
  "grain: the rules over the output, the focused frame's furniture in its top
rule, the pour between them and bolo's voice on the focused frame; on an output
the deck gives no seam, a rule along each bar with the readings above it."
  (let ((bars (remove :seam (getf context :strips)
                      :key (lambda (strip) (getf strip :place)))))
    (append
     (if bars
         (kit--frames look context (append (rail-grain--theme) (list 0d0)) :reach 60)
         (kit--frames look context (rail-grain--theme) :reach 60))
     (loop for strip in bars append (rail-grain--bar look context strip)))))

(defparameter +rail-grain+
  (list :draw #'rail-grain--draw :cast +rail-grain--cast+ :settle 0.65d0
        :strip-height +rail-grain--strip-height+
        :frame (list :edge 20 :title 12 :seam 20)
        :trail (list :cell 4d0 :life 1d0 :steps 8 :shape :cells
                     :dark :glint :light :ink)))
