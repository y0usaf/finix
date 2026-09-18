;; Ekko deck profile: two column-decks, mirroring the tomoe "deck" layout
;; (modules/desktop/session/ui/tomoe/config.nix). The view splits into a
;; left and a right column; each column is a deck whose front pane fills it
;; while the rest stay mapped one slot above or below, so scrolling slides
;; the stack vertically instead of hide/show swapping. A spawned pane joins
;; the deck you last worked in (the :pending column commands record) and
;; takes its front. Minimized and floated panes leave the decks
;; (floats paint on top); closing a pane reveals the next member.
;;
;; Bindings. The top-level chords are Ctrl (fast, byte level) and Ctrl+Shift;
;; a few Ctrl chords need the Kitty protocol, noted below. Alt is out either
;; way: the tomoe compositor runs with Mod=Alt and grabs Mod+h/l, Mod+j/k,
;; Mod+o and Mod+r globally (modules/desktop/session/ui/tomoe/config.nix), so
;; an Alt chord is consumed by the compositor and can never reach ekko.
;;
;; How a control chord arrives. A Ctrl chord folds into its legacy control
;; code only for an ASCII letter base, so "C-h" is code 8 and matches both a
;; raw 0x08 byte and the Kitty CSI 104;5u event — those chords work on any
;; host. Every other control base keeps a distinct Ctrl bit (ekko rev
;; 0d7903b), because a legacy terminal has no distinct byte for it: Ctrl+[ IS
;; the raw 0x1B byte and Ctrl+Tab IS the bare 0x09 byte. Those chords
;; therefore need the Kitty keyboard path (the client's DISAMBIGUATE request,
;; encoded as CSI 1;<mods>u). Escape is unaffected: Kitty sends it as CSI 27u,
;; a legacy terminal as raw 0x1B, and neither matches Ctrl+[. The capitals
;; family carries the Shift bit: an uppercase ASCII letter base means Shift on
;; the lowercase key, so "C-J"/"C-K" are Ctrl+Shift+J/K, again on the Kitty
;; path (a legacy control byte cannot carry Shift).
;;   Ctrl+h / Ctrl+l  focus the left / right column's front pane
;;   Ctrl+j / Ctrl+k  scroll the focused deck down / up (wraps)
;;   Ctrl+o           flat equal-grid toggle        Ctrl+r  column ratio cycle
;;   Ctrl+d           deck mode — the full tomoe bind set, bare letters
;;                    standing in for the shifted chords:
;;                    h l focus column · j k scroll · J K move within deck ·
;;                    H L swap columns · [ ] send pane across · o grid ·
;;                    r ratio · n new pane · q close · Escape/Enter exits
;; Kitty-only, since the control byte collides (see above):
;;   Ctrl+[ / Ctrl+]  move the focused pane to the left / right column
;;   Ctrl+Tab         swap the two columns wholesale
;;   Ctrl+Shift+J / Ctrl+Shift+K  move the focused pane down / up in its deck
;; The cost is real: these Ctrl chords are intercepted before pane input, so
;; C-h (backspace alias), C-j, C-k (kill-line), C-l (clear-screen), C-o, C-r
;; (reverse-search) and C-d (EOF) no longer reach applications while the
;; normal map is active.
;;
;; Alt+Shift stays out: it belongs to the compositor — tomoe binds
;; Mod+Shift+h/l (swap columns) and Mod+Shift+j/k (move window) globally
;; (config.nix lines 979-982), and with Mod=Alt the compositor grabs those
;; chords, so they never reach ekko.
;;
;; The desktop defaults stay installed: this only replaces the layout
;; provider and contributes bindings.

(defpackage #:ekko-deck
  (:use #:cl #:ekko/extensions))
(in-package #:ekko-deck)

(defparameter +ratios+ '(1/2 2/3 1/3)
  "Ctrl+r column split cycle, like tomoe's 16:9+16:9 / 21:9+11:9 / 11:9+21:9.")

(defun pane-id (pane) (getf pane :id))

(defun sorted-panes (snapshot)
  (sort (copy-list (value snapshot :panes)) #'< :key #'pane-id))

(defun tiled-p (pane)
  (not (or (getf pane :minimized) (getf pane :floating))))

(defun deck-state (snapshot)
  (rest (assoc "deck" (value snapshot :component-state) :test #'equal)))

(defun state-list (state key)
  (let ((value (getf state key)))
    (and (listp value) value)))

(defun deck-model (snapshot)
  "Resolve the workspace into (:left :right) ordered column id lists, their
tiled subsets (:vl :vr), front ids (:fl :fr), :ratio, :grid and :pending.
Dead panes drop out; unassigned panes join the :pending column — the deck a
command last worked in, like a spawn joining the focused window's column in
tomoe — or balance into the shorter one (ties go left), and take its front."
  (let* ((state (deck-state snapshot))
         (panes (sorted-panes snapshot))
         (live (mapcar #'pane-id panes))
         (visible (mapcar #'pane-id (remove-if-not #'tiled-p panes)))
         (left (remove-if-not (lambda (id) (member id live))
                              (state-list state :left)))
         (right (remove-if-not (lambda (id) (member id live))
                               (state-list state :right)))
         (pending (let ((p (getf state :pending))) (and (member p '(:left :right)) p)))
         (new (remove-if (lambda (id) (or (member id left) (member id right)))
                         live)))
    (dolist (id new)
      (if (or (eq pending :left)
              (and (null pending) (<= (length left) (length right))))
          (setf left (append left (list id)))
          (setf right (append right (list id)))))
    (flet ((subset (col) (remove-if-not (lambda (id) (member id visible)) col))
           (joined (col) (car (last (remove-if-not (lambda (id) (member id col)) new)))))
      (let ((vl (subset left)) (vr (subset right))
            (focus (value snapshot :focus)))
        (flet ((front (col vcol stored)
                 ;; Newest joiner takes the front, then a focused member (a
                 ;; click or focus-next on a buried pane promotes it), then
                 ;; the remembered front, then the deck top.
                 (or (joined col)
                     (and (member focus vcol) focus)
                     (and (member stored vcol) stored)
                     (first vcol))))
          (list :left left :right right :vl vl :vr vr
                :fl (front left vl (getf state :fl))
                :fr (front right vr (getf state :fr))
                :ratio (let ((r (getf state :ratio))) (if (integerp r) r 0))
                :grid (and (getf state :grid) t)
                :pending pending
                :visible visible))))))

(defun model-state (model)
  (list :left (getf model :left) :right (getf model :right)
        :fl (getf model :fl) :fr (getf model :fr)
        :ratio (getf model :ratio) :grid (getf model :grid)
        :pending (getf model :pending)))

;; ─── Geometry (same inset arithmetic as the public tiled/floating providers) ──

(defun fit-insets (width height insets)
  (let* ((top (min (first insets) (max 0 (1- height))))
         (left (min (fourth insets) (max 0 (1- width))))
         (bottom (min (third insets) (max 0 (- height top 1))))
         (right (min (second insets) (max 0 (- width left 1)))))
    (list top right bottom left)))

(defun deck-viewport (snapshot)
  (let* ((viewport (value snapshot :viewport)) (geometry (value snapshot :geometry))
         (cols (getf viewport :cols)) (rows (getf viewport :rows))
         (insets (fit-insets cols rows (getf geometry :viewport-insets '(0 0 1 0)))))
    (values (fourth insets) (first insets)
            (- cols (second insets) (fourth insets))
            (- rows (first insets) (third insets)))))

(defun deck-frame (snapshot id x y width height)
  (let* ((geometry (value snapshot :geometry))
         (requested (copy-list (getf geometry :pane-insets '(1 0 0 0))))
         (boundary (getf geometry :boundary-insets)))
    (when boundary
      (multiple-value-bind (left top vw vh) (deck-viewport snapshot)
        (loop for outside in (list (= y top) (= (+ x width) (+ left vw))
                                   (= (+ y height) (+ top vh)) (= x left))
              for index from 0 when outside do (setf (nth index requested) (nth index boundary)))))
    (let ((insets (fit-insets width height requested)))
      (list :pane id :x (+ x (fourth insets)) :y (+ y (first insets))
            :cols (- width (second insets) (fourth insets))
            :rows (- height (first insets) (third insets))
            :outer (list x y width height)))))

(defun floating-rect (pane index left top width height)
  (destructuring-bind (x y w h)
      (let ((f (getf pane :floating)))
        (if (and (listp f) (= (length f) 4)) f
            (list (+ left (* 3 (mod index 8))) (+ top (mod index 8))
                  (max 12 (floor (* width 3) 4)) (max 4 (floor (* height 3) 4)))))
    (let ((w (min width (max 12 w))) (h (min height (max 4 h))))
      (list (max left (min x (+ left width (- w))))
            (max top (min y (+ top height (- h)))) w h))))

;; ─── Layout provider ──────────────────────────────────────────────────────────

(defun deck-columns (snapshot model x y w h gap)
  (let* ((ratio (nth (mod (getf model :ratio) (length +ratios+)) +ratios+))
         (lw (max 1 (min (- w gap 1) (floor (* (- w gap) ratio)))))
         (rw (max 1 (- w gap lw))))
    (flet ((place (vcol front cx cw)
             ;; The front fills the column; the rest stay full-size one slot
             ;; above or below it, so a scroll is a real slide.
             (let ((fi (or (position front vcol) 0)))
               (loop for id in vcol for i from 0
                     collect (deck-frame snapshot id cx (+ y (* (- i fi) h)) cw h)))))
      (append (place (getf model :vl) (getf model :fl) x lw)
              (place (getf model :vr) (getf model :fr) (+ x lw gap) rw)))))

(defun deck-grid (snapshot model x y w h gap)
  (let* ((ids (getf model :visible)) (n (length ids)))
    (when (plusp n)
      (let* ((cols (max 1 (ceiling (sqrt n))))
             (rows (ceiling n cols))
             (cw (max 1 (floor (- w (* (1- cols) gap)) cols)))
             (ch (max 1 (floor (- h (* (1- rows) gap)) rows))))
        (loop for id in ids for i from 0
              collect (deck-frame snapshot id
                                  (+ x (* (mod i cols) (+ cw gap)))
                                  (+ y (* (floor i cols) (+ ch gap)))
                                  cw ch))))))

(defun deck-place (snapshot event)
  (declare (ignore event))
  (let* ((model (deck-model snapshot))
         (gap (first (getf (value snapshot :geometry) :split-gaps '(1 0))))
         (focus (value snapshot :focus)))
    (multiple-value-bind (x y w h) (deck-viewport snapshot)
      (let ((placements
              (append (if (getf model :grid)
                          (deck-grid snapshot model x y w h gap)
                          (deck-columns snapshot model x y w h gap))
                      ;; Floating panes paint above the decks.
                      (loop for pane in (sorted-panes snapshot) for i from 0
                            when (getf pane :floating)
                            collect (apply #'deck-frame snapshot (pane-id pane)
                                           (floating-rect pane i x y w h))))))
        ;; Zoom is provider policy: hide the rest, show the focused pane full.
        (when (and (value snapshot :zoom)
                   (find focus placements :key (lambda (pl) (getf pl :pane))))
          (setf placements
                (append (loop for pl in placements
                              unless (eql focus (getf pl :pane))
                              collect (let ((hidden (copy-list pl)))
                                        (setf (getf hidden :visible) nil)
                                        hidden))
                        (list (deck-frame snapshot focus x y w h)))))
        (list (action :place-panes ':version 1 ':placements placements
                      ':camera '(0 0)))))))

;; ─── Commands ─────────────────────────────────────────────────────────────────

(defun column-of (model focus)
  (cond ((member focus (getf model :vl)) :left)
        ((member focus (getf model :vr)) :right)))

(defun focus-column (side)
  (lambda (snapshot event)
    (declare (ignore event))
    (let* ((model (deck-model snapshot))
           (front (getf model (if (eq side :left) :fl :fr))))
      (when front
        (setf (getf model :pending) side)
        (list (action :focus ':pane front)
              (action :set-state ':value (model-state model)))))))

(defun scroll-deck (dir)
  (lambda (snapshot event)
    (declare (ignore event))
    (let* ((model (deck-model snapshot))
           (side (column-of model (value snapshot :focus))))
      (when side
        (let ((vcol (getf model (if (eq side :left) :vl :vr)))
              (fkey (if (eq side :left) :fl :fr)))
          (when (> (length vcol) 1)
            (let ((target (nth (mod (+ (or (position (getf model fkey) vcol) 0) dir)
                                   (length vcol))
                               vcol)))
              (setf (getf model fkey) target
                    (getf model :pending) side)
              (list (action :focus ':pane target)
                    (action :set-state ':value (model-state model))))))))))

(defun move-in-deck (dir)
  (lambda (snapshot event)
    (declare (ignore event))
    (let* ((model (deck-model snapshot))
           (focus (value snapshot :focus))
           (side (cond ((member focus (getf model :left)) :left)
                       ((member focus (getf model :right)) :right))))
      (when side
        (let* ((col (getf model side))
               (i (position focus col)) (j (and i (+ i dir))))
          (when (and j (<= 0 j) (< j (length col)))
            (rotatef (nth i col) (nth j col))
            (setf (getf model :pending) side)
            (list (action :set-state ':value (model-state model)))))))))

(defun swap-columns (snapshot event)
  (declare (ignore event))
  (let ((model (deck-model snapshot)))
    (rotatef (getf model :left) (getf model :right))
    (rotatef (getf model :vl) (getf model :vr))
    (rotatef (getf model :fl) (getf model :fr))
    ;; Pending follows the focused pane across the swap.
    (let ((focus (value snapshot :focus)))
      (setf (getf model :pending)
            (cond ((member focus (getf model :left)) :left)
                  ((member focus (getf model :right)) :right)
                  (t (getf model :pending)))))
    (list (action :set-state ':value (model-state model)))))

(defun to-column (target)
  (lambda (snapshot event)
    (declare (ignore event))
    (let* ((model (deck-model snapshot))
           (focus (value snapshot :focus))
           (side (cond ((member focus (getf model :left)) :left)
                       ((member focus (getf model :right)) :right))))
      (when (and side (not (eq side target)))
        (let* ((col (getf model side)) (i (position focus col))
               (skey (if (eq side :left) :fl :fr))
               (tkey (if (eq target :left) :left :right))
               (tfkey (if (eq target :left) :fl :fr)))
          ;; If the moved pane was the deck front, reveal the member after
          ;; it (wrapping, like a scroll) rather than resetting to the top.
          (when (eql focus (getf model skey))
            (setf (getf model skey) (nth (mod (1+ i) (length col)) col)))
          (setf (getf model side) (remove focus col)
                (getf model tkey) (append (getf model tkey) (list focus))
                (getf model tfkey) focus
                (getf model :pending) target)
          (list (action :set-state ':value (model-state model))))))))

(defun close-pane (snapshot event)
  (declare (ignore event))
  (let* ((model (deck-model snapshot))
         (focus (value snapshot :focus))
         (side (column-of model focus)))
    (if side
        (let* ((vcol (getf model (if (eq side :left) :vl :vr)))
               (fkey (if (eq side :left) :fl :fr))
               ;; Focus the member the deck reveals next, like tomoe's
               ;; close-refocus pulling the window the deck uncovered.
               (target (and (> (length vcol) 1)
                            (nth (mod (1+ (or (position focus vcol) 0))
                                      (length vcol))
                                 vcol))))
          (if target
              (progn (setf (getf model fkey) target
                           (getf model :pending) side)
                     (list (action :close ':focus target)
                           (action :set-state ':value (model-state model))))
              (list (action :close))))
        (list (action :close)))))

;; ─── Registration ─────────────────────────────────────────────────────────────

(register-component :id ':deck :reads '(:panes :focus :component-state))
(register-layout-provider :component ':deck :name "deck" :api-version 1
                          :reads '(:panes :focus :viewport :geometry
                                   :component-state :zoom)
                          :handler #'deck-place)
(set-option :component ':deck :name ':layout-provider :value "deck")
;; One-cell column boundary; the desktop defaults set no split gap.
(set-option :component ':deck :name ':split-gaps :value '(1 0))

(register-command :component ':deck :name "deck-focus-left" :handler (focus-column :left))
(register-command :component ':deck :name "deck-focus-right" :handler (focus-column :right))
(register-command :component ':deck :name "deck-scroll-down" :handler (scroll-deck 1))
(register-command :component ':deck :name "deck-scroll-up" :handler (scroll-deck -1))
(register-command :component ':deck :name "deck-move-down" :handler (move-in-deck 1))
(register-command :component ':deck :name "deck-move-up" :handler (move-in-deck -1))
(register-command :component ':deck :name "deck-swap-columns" :handler #'swap-columns)
(register-command :component ':deck :name "deck-to-left" :handler (to-column :left))
(register-command :component ':deck :name "deck-to-right" :handler (to-column :right))
(register-command :component ':deck :name "deck-close" :handler #'close-pane)
(register-command :component ':deck :name "deck-new"
                  :handler (lambda (snapshot event) (declare (ignore event))
                             ;; Pin the new pane's column before it exists:
                             ;; the provider can't write state, so commands
                             ;; record the working deck in :pending.
                             (let* ((model (deck-model snapshot))
                                    (side (column-of model (value snapshot :focus))))
                               (when side (setf (getf model :pending) side))
                               (list (action :split ':axis ':columns)
                                     (action :set-state ':value (model-state model))))))
(register-command :component ':deck :name "deck-grid-toggle"
                  :handler (lambda (snapshot event) (declare (ignore event))
                             (let ((model (deck-model snapshot)))
                               (setf (getf model :grid) (not (getf model :grid)))
                               (list (action :set-state ':value (model-state model))))))
(register-command :component ':deck :name "deck-ratio-cycle"
                  :handler (lambda (snapshot event) (declare (ignore event))
                             (let ((model (deck-model snapshot)))
                               (setf (getf model :ratio)
                                     (mod (1+ (getf model :ratio)) (length +ratios+)))
                               (list (action :set-state ':value (model-state model))))))
(register-command :component ':deck :name "deck-mode"
                  :handler (lambda (snapshot event) (declare (ignore snapshot event))
                             (list (action :set-keymap ':name ':deck))))

;; The deck map and its entry need the desktop :normal map to exist; on a
;; bare runtime skip the bindings and keep the provider and commands.
(when (find ':normal (getf (registry) ':keymaps)
            :key (lambda (m) (getf m ':name)))
  (register-keymap :component ':deck :name ':deck :unbound ':ignore)
  ;; Top level: the core tomoe keys plus the rearrange chords — Ctrl+[ and
  ;; Ctrl+] move the focused pane across, Ctrl+Tab swaps the two columns
  ;; wholesale, and Ctrl+Shift+J/K reorder within a deck. Ctrl+[ / Ctrl+] /
  ;; Ctrl+Tab need the Kitty path (see the header); the rest fold to legacy
  ;; bytes or carry the Shift bit.
  (dolist (spec '(("C-h" . "deck-focus-left") ("C-l" . "deck-focus-right")
                  ("C-j" . "deck-scroll-down") ("C-k" . "deck-scroll-up")
                  ("C-o" . "deck-grid-toggle") ("C-r" . "deck-ratio-cycle")
                  ("C-d" . "deck-mode")
                  ("C-[" . "deck-to-left") ("C-]" . "deck-to-right")
                  ("C-Tab" . "deck-swap-columns")
                  ("C-J" . "deck-move-down") ("C-K" . "deck-move-up")))
    (bind-key :component ':deck :map ':normal :key (car spec) :command (cdr spec)))
  ;; Deck mode (Ctrl+d): tomoe's full set — capitals are the shifted letters;
  ;; the modal map carries Shift as the letter itself, with no modifier.
  (dolist (spec '(("h" . "deck-focus-left") ("l" . "deck-focus-right")
                  ("j" . "deck-scroll-down") ("k" . "deck-scroll-up")
                  ("J" . "deck-move-down") ("K" . "deck-move-up")
                  ("H" . "deck-swap-columns") ("L" . "deck-swap-columns")
                  ("[" . "deck-to-left") ("]" . "deck-to-right")
                  ("o" . "deck-grid-toggle") ("r" . "deck-ratio-cycle")
                  ("n" . "deck-new") ("q" . "deck-close")
                  ("Escape" . "normal-mode") ("Enter" . "normal-mode")))
    (bind-key :component ':deck :map ':deck :key (car spec) :command (cdr spec))))