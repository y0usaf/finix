(in-package #:tomoe-user)

;;; glass
;;;
;;; morph in liquid glass: the same slab, frames, gauges, motion and voice, drawn
;;; by morph.glsl with GLASS defined. The glass takes no colour of its own and
;;; nothing from the mode: what it shows is what lies beneath it, bent towards
;;; its rims by :LENS over its :BEVEL, frosted by :FROST, its colour lifted by
;;; :VIBRANCE and a :HAZE of scattered light, with light caught along its rims at
;;; :RIM and a dark line just inside them at :EDGE, so it reads over a white page
;;; and a black one alike. Only the readings' ink follows the mode, as text does
;;; everywhere; where what lies beneath sits too near that ink, the glass darkens
;;; or brightens it until the two stand :CONTRAST apart in luminance, keeping its
;;; hue. Every other card's line is etched the same way out of what is beneath
;;; it. A mode's :MATERIAL is only the ground a warning bead cuts its number in.

(defparameter +rail-glass--pane+
  (list :line "#808080" :shadow "#000000" :shade 0.20 :shine "#FFFFFF" :gloss 0.40
        :glass (list :frost 7 :lens 11 :bevel 16 :rim 0.9 :haze 0.05 :vibrance 0.35
                     :contrast 0.5 :edge 0.16)))

(defparameter +rail-glass+
  (list :draw #'rail--morph-draw :font "IBM Plex Mono Medium" :strip-height 96
        :cast (list :frame 5 :line-width 1.5 :radius 14 :slab 50 :inset 22 :end 22 :weld 28
                    :squash 0.7 :swell 11
                    :dark (list* :material "#161925" +rail-glass--pane+)
                    :light (list* :material "#F7F5F0" +rail-glass--pane+))))
