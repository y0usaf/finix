(in-package #:tomoe-user)

;; Tomoe policy, in Lisp. This is the Rust session's init.lua rewritten against
;; the Lisp compositor's API: the same file a user writes, no special case.
;;
;; lisp-config.nix prepends values serialized through toLisp; the session
;; installs the result into ~/.config/tomoe/init.lisp on every launch.
;; The flake is the source of truth. The compositor watches that file
;; and reloads it as you edit, so edits are live; --no-watch disables that,
;; Super+Shift+r reloads by hand. init.lisp is watched but the deck it loads
;; is not, so a fingerprint of the deck is stamped above to make a deck-only
;; change reload too.
;;
;; Ported from the Lua config:
;;   displays, the deck layout (the deck next to this file, loaded below),
;;   floating (Super+space), the floating launcher with focus return, the
;;   steam_proton / Lovely hide rule, application and media binds, screenshots
;;   and wallpaper.
;;
;; Not portable yet, so absent here:
;;   * the in-process bar (the Lua shell's cpu/memory/gpu/bongo/time/date
;;     modules). The Lisp compositor has no in-process shell; a bar has to be a
;;     separate layer-shell client.
;;   * process supervision (tomoe.process.service): launch is one-shot.
;;   * show-hotkey-overlay, and Mod+9 output blanking (no disable effect).
;;   * the built-in screenshot actions: grim + slurp + wl-copy stand in, and
;;     they copy to the clipboard without writing a file.
;;
;; Display settings, bindings, launch arguments, and sizing ratios live in
;; lisp-config.nix. App commands and wallpaper paths use the host's Nix defaults.

;; --- tiling area ------------------------------------------------------------

;; Exclusive zones the visible layer surfaces take from the tiling area, copied
;; from the shipped tiles unit so floating placement respects panels too.
(defun %policy-exclusive-edge (anchors)
  (flet ((exactly (&rest edges)
           (and (= (length anchors) (length edges))
                (every (lambda (edge) (member edge anchors)) edges))))
    (cond ((or (exactly :top) (exactly :top :left :right)) :top)
          ((or (exactly :bottom) (exactly :bottom :left :right)) :bottom)
          ((or (exactly :left) (exactly :left :top :bottom)) :left)
          ((or (exactly :right) (exactly :right :top :bottom)) :right))))

(defun %policy-insets (layers)
  (let ((top 0) (right 0) (bottom 0) (left 0))
    (dolist (layer layers)
      (let ((zone (getf layer :exclusive-zone))
            (margin (getf layer :margin)))
        (when (and (getf layer :visible) (integerp zone) (plusp zone))
          (let* ((edge (%policy-exclusive-edge (getf layer :anchors)))
                 (offset (case edge (:top (first margin)) (:right (second margin))
                                 (:bottom (third margin)) (:left (fourth margin))))
                 (inset (+ zone (or offset 0))))
            (when (plusp inset)
              (case edge
                (:top (setf top (max top inset)))
                (:right (setf right (max right inset)))
                (:bottom (setf bottom (max bottom inset)))
                (:left (setf left (max left inset)))))))))
    (list :top top :right right :bottom bottom :left left)))

(defun %usable-area (snapshot)
  "The first output, minus the exclusive zones of the visible layer surfaces."
  (let ((output (first (context snapshot :outputs))))
    (when output
      (let* ((insets (%policy-insets (context snapshot :layers)))
             (left (getf insets :left)) (top (getf insets :top)))
        (list :x (+ (getf output :x) left)
              :y (+ (getf output :y) top)
              :width (max 1 (- (getf output :width) left (getf insets :right)))
              :height (max 1 (- (getf output :height) top (getf insets :bottom))))))))

(defun %centred-box (area width height)
  "AREA comes from %usable-area; WIDTH and HEIGHT are pixels."
  (list (+ (getf area :x) (floor (- (getf area :width) width) 2))
        (+ (getf area :y) (floor (- (getf area :height) height) 2))
        width height))

;; --- displays ---------------------------------------------------------------

(define-extension "displays" () (snapshot state event)
  (declare (ignore snapshot state event))
  (values nil
          (mapcar (lambda (output)
                    (apply #'configure-output (first output) (second output)))
                  +policy-displays+)
          nil))

;; --- layout: the deck -------------------------------------------------------

;; The two-column deck, kept in its own file so it can be edited or replaced on
;; its own. Delete this line to fall back to the shipped horizontal tiling.
(load (namestring (merge-pathnames +policy-deck-path+
                                   (user-homedir-pathname))))

;; --- floating ---------------------------------------------------------------

;; Super+space toggles the focused window out of the tiling: centred at 60% of
;; the usable area, and kept there, because the unit owns that placement on
;; every dispatch. A fullscreen window is normalized first instead, the way
;; Niri's floating transition does it.
(define-extension "floating" (:reads (:windows :outputs :layers :key :focus) :state nil)
    (snapshot floating event)
  (let* ((windows (context snapshot :windows))
         (ids (mapcar (lambda (window) (getf window :id)) windows))
         (focused (context snapshot :focus))
         (window (find focused windows :key (lambda (w) (getf w :id))))
         (command (when (and (eq (getf event :type) :key)
                             (equal (getf event :owner) "floating"))
                    (getf event :command)))
         (area (%usable-area snapshot)))
    ;; A closed window leaves the set, and its geometry with it.
    (setf floating (remove-if-not (lambda (entry) (member (car entry) ids)) floating))
    (when (and (equal command "toggle") window)
      (let ((id (getf window :id)))
        (cond
          ((getf window :fullscreen) nil)
          ((assoc id floating)
           (setf floating (remove id floating :key #'car)))
          (area
           (let ((width (max 1 (floor (* (getf area :width) +policy-floating-ratio+))))
                 (height (max 1 (floor (* (getf area :height) +policy-floating-ratio+)))))
             (setf floating (cons (cons id (%centred-box area width height)) floating)))))))
    (values floating
            (append (list (apply #'bind-key +policy-floating-binding+))
                    (when (and (equal command "toggle") window (getf window :fullscreen))
                      (list (fullscreen (getf window :id) nil)))
                    (loop for (id . box) in floating
                          collect (place id (first box) (second box)
                                         (third box) (fourth box) t)))
            nil)))

;; --- floating launcher ------------------------------------------------------

;; The launcher (app-id "launcher") floats centred at a third of the usable
;; area, and the window that had focus when it opened gets it back when it
;; closes. The Rust config does this with on_window_open / on_window_close
;; hooks; here it is one unit, with the previous focus as its state.
(define-extension "launcher" (:reads (:windows :outputs :layers :focus) :state nil)
    (snapshot previous event)
  (let* ((windows (context snapshot :windows))
         (ids (mapcar (lambda (window) (getf window :id)) windows))
         (launchers (remove-if-not (lambda (window)
                                     (equal (getf window :app-id)
                                            (getf +policy-launcher+ :app-id)))
                                   windows))
         (launcher-ids (mapcar (lambda (window) (getf window :id)) launchers))
         (focused (context snapshot :focus))
         (type (getf event :type))
         (id (getf event :id))
         (area (%usable-area snapshot)))
    (when (and (eq type :map) (member id launcher-ids)) (setf previous focused))
    ;; focus is an effect, not a command, so it rides in the effects list; the
    ;; remembered window is forgotten once it has it back.
    (let ((return-to (when (and (eq type :unmap) previous (member previous ids)
                                (null launcher-ids))
                       previous)))
      (values (if return-to nil previous)
              (append
               (when area
                 (let* ((ratio (getf +policy-launcher+ :ratio))
                        (width (max 1 (floor (* (getf area :width) ratio))))
                        (height (max 1 (floor (* (getf area :height) ratio)))))
                   (loop for window in launchers
                         for box = (%centred-box area width height)
                         collect (place (getf window :id) (first box) (second box)
                                        (third box) (fourth box) t))))
               (when return-to (list (focus return-to))))
              nil))))

;; --- rules ------------------------------------------------------------------

;; What Lovely's injector leaves behind (app-id steam_proton, title starting
;; with "Lovely") stays out of the way: hidden, and it does not take focus from
;; what you were doing. Everything else is the layout's business.
(define-extension "rules" (:reads (:windows :focus) :state nil)
    (snapshot previous event)
  (let* ((windows (context snapshot :windows))
         (app-id (getf +policy-hidden-window+ :app-id))
         (prefix (getf +policy-hidden-window+ :title-prefix))
         (prefix-length (length prefix))
         (matched (remove-if-not
                   (lambda (window)
                     (and (equal (getf window :app-id) app-id)
                          (let ((title (getf window :title)))
                            (and title (>= (length title) prefix-length)
                                 (string= prefix title :end2 prefix-length)))))
                   windows))
         (matched-ids (mapcar (lambda (window) (getf window :id)) matched))
         (ids (mapcar (lambda (window) (getf window :id)) windows))
         (focused (context snapshot :focus))
         (type (getf event :type))
         (id (getf event :id)))
    (when (and (eq type :map) (member id matched-ids)) (setf previous focused))
    ;; focus = false: the window that had it keeps it, and a hidden window is
    ;; never the target. focus is an effect here, so it belongs in the effects
    ;; list, beside the placements.
    (let ((target
           (when (and (eq type :map) (member id matched-ids))
             (or (and previous (member previous ids)
                      (not (member previous matched-ids))
                      previous)
                 (getf (find-if-not (lambda (window)
                                      (member (getf window :id) matched-ids))
                                    windows)
                       :id)))))
      (values previous
              (append (loop for window in matched
                            collect (place (getf window :id) 0 0 1 1 nil))
                      ;; Only a matched map moves focus. Emitting (focus target)
                      ;; on every map cleared the keyboard focus the layout had
                      ;; just given the new window, so nothing could be typed
                      ;; into any client until this rule next ran.
                      (when (and (eq type :map) (member id matched-ids))
                        (list (focus target))))
              nil))))

;; --- applications, media, screenshots ---------------------------------------

(define-extension "user" (:reads (:key :focus) :state nil) (snapshot state event)
  (declare (ignore state))
  (let ((command (when (and (eq (getf event :type) :key)
                            (equal (getf event :owner) "user"))
                   (getf event :command)))
        (focused (context snapshot :focus)))
    (values nil
            (mapcar (lambda (binding) (apply #'bind-key binding)) +policy-bindings+)
            (cond
              ((null command) nil)
              ((equal command "close") (when focused (list (close-window focused))))
              ((equal command "quit") (list (quit)))
              (t
               (let ((argv (second (assoc command +policy-launches+ :test #'equal))))
                 (when argv (list (apply #'launch argv)))))))))
