(in-package #:tomoe-user)

;;; MEMBRANE: THREAD in living glass
;;;
;;; THREAD's seam, beads, readings, weld and motion, laid out by rail-thread.lisp
;;; and drawn by shaders/membrane.glsl in a glass that reads as glass: its edges
;;; bend the sharp backdrop, the primaries apart, and its body carries the
;;; windows' own blur of it (the compositor's frost()), with a Fresnel rim, a
;;; highlight down the lit side and the light it gathers on its far edge. Its
;;; walls are a soap film with a thin inner membrane, organelles drift in its
;;; plasm and the voice bead is a nucleus; a switch sends a swell along the
;;; thread, the new rim buds out of the weld and the old one pearls as it drains.
;;;
;;; +RAIL-MEMBRANE--GLASS+ sets every strength, in both modes alike: the glass
;;; follows what lies beneath it, as THREAD's does. A config changes one with
;;; (setf (getf +rail-membrane--glass+ :film) 0.6) and a reload; :FILM, :BUD and
;;; :PLASM at 0 leave THREAD's shapes in the same glass.

(defparameter +rail-membrane--glass+
  (list :frost 0.9         ; how much of the body is the windows' blur, against the sharp backdrop
        :lens 10           ; pixels the edge bends the backdrop inward
        :dispersion 0.08   ; how far apart the primaries bend
        :specular 0.8      ; the highlight down the lit side
        :fresnel 0.9       ; the sky and the desktop mirrored round the rim
        :vibrancy 1.3      ; saturation of what the glass passes
        :grain 1           ; steps of 8-bit dither against banding
        :caustic 0.8       ; light gathered on the far edge and thrown beside it
        :tint 0.4          ; the green-blue of thick soda glass
        :film 1            ; the soap film's colour and the inner membrane
        :bud 1             ; the new rim's bud and the old rim's pearling
        :plasm 1))         ; the thread's wandering girth and the organelles

;;; The order membrane.glsl reads them in, after THREAD's own numbers.
(defparameter +rail-membrane--knobs+
  '(:frost :lens :dispersion :specular :fresnel :vibrancy :grain :caustic :tint
    :film :bud :plasm))

(defun rail-membrane--glass ()
  (loop for knob in +rail-membrane--knobs+
        collect (coerce (or (getf +rail-membrane--glass+ knob) 0) 'double-float)))

(defun rail-membrane--numbers (layout state)
  "THREAD's numbers for LAYOUT, then the glass's."
  (append (rail-thread--numbers layout state) (rail-membrane--glass)))

(defun rail-membrane--bar-numbers (context strip)
  "THREAD's bar numbers with every one of its eight blocks' places held, so the
glass's numbers start where membrane.glsl reads them on a bar too."
  (let ((numbers (rail-thread--bar-numbers context strip)))
    (append numbers
            (make-list (max 0 (- 49 (length numbers))) :initial-element 0d0)
            (rail-membrane--glass))))

(defparameter +rail-membrane+
  (list* :numbers #'rail-membrane--numbers :bar-numbers #'rail-membrane--bar-numbers
         +rail-thread+))
