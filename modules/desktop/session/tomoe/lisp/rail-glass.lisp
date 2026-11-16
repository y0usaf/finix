(in-package #:tomoe-user)

(defparameter +rail-glass+
  (list :draw #'rail--morph-draw :font "IBM Plex Mono Medium"
        :cast (list :frame 5 :line-width 1.5 :radius 14 :slab 50 :inset 22 :end 22 :weld 28
                    :squash 0.7 :swell 11
                    :dark (list :material "#161925" :line "#4A4F66" :shadow "#000000" :shade 0.32
                                :shine "#FFFFFF" :gloss 0.34 :ink "#F4F2EC"
                                :glass (list :tint 0.22 :frost 7 :lens 11 :bevel 16 :rim 1.0
                                             :lift 0.10))
                    :light (list :material "#F7F5F0" :line "#C4C0B8" :shadow "#2E2A26" :shade 0.14
                                 :shine "#FFFFFF" :gloss 0.55 :ink "#1F1E1C"
                                 :glass (list :tint 0.40 :frost 7 :lens 11 :bevel 16 :rim 0.95
                                              :lift 0.02)))))
