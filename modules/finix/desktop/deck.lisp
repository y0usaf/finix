(in-package #:tomoe-user)

;; The "deck" layout: a 32:9 screen split into two half-columns that are each
;; 16:9. Each column is a deck — its front window fills the half and its other
;; windows stay mapped one slot above or below it, so Mod+j/k slides the stack
;; instead of swapping two windows. Port of the deck chunk in the user's Tomoe
;; Lua config, written against the public extension API: columns, deck order,
;; the deck front and floating windows are all extension state, and every
;; geometry change is a `place` effect.
;;
;; One implicit window set. The workspace machinery is gone (user decision:
;; single workspace), so Alt+digits are free for the app spawns in the policy.
;;
;; Mod is Alt, matching the original. Mod+r cycles the split, Mod+o toggles an
;; even grid, Mod+h/l/j/k drive the columns, Mod+Shift+* move windows,
;; Super+space floats the focused window.

;; lisp-config.nix prepends the layout constants and binding data through toLisp.
;; This file contains the layout implementation, not a standalone config.

(defun deck--state ()
  (list :grid nil :ratio 1 :focus nil
        :columns nil :windows nil
        :fronts (list (cons :left nil) (cons :right nil))
        :floating nil :floats nil :fullscreen nil))

(defun deck--entry (list id) (assoc id list))
(defun deck--layout-entry (layout id) (find id layout :key (lambda (entry) (getf entry :id))))
(defun deck--windows (state) (getf state :windows))
(defun deck--fronts (state) (getf state :fronts))
(defun deck--side-of (state id)
  (let ((entry (deck--entry (getf state :columns) id))) (and entry (cdr entry))))
(defun deck--column (state side)
  (remove-if-not (lambda (id) (eql (deck--side-of state id) side)) (deck--windows state)))
(defun deck--front (state side)
  "The window SIDE's deck shows in front. An adopted front counts only while it is
still in that column: a front can outlive its window between a close and the
handoff that replaces it, and a column placed against a front that is gone would
be placed nowhere and show nothing at all."
  (let* ((entry (assoc side (deck--fronts state)))
         (recorded (and entry (cdr entry)))
         (column (deck--column state side)))
    (if (member recorded column) recorded (first column))))
(defun deck--after-front (state order side gone)
  "The window that takes the front of SIDE in ORDER once GONE closes, or NIL when
the column empties. GONE still sits in ORDER, so the entry after it — wrapping,
the way a scroll does — is the window a scroll would have revealed."
  (let* ((column (remove-if-not (lambda (id) (eql (deck--side-of state id) side)) order))
         (index (position gone column))
         (next (and index (nth (mod (1+ index) (length column)) column))))
    (unless (eql next gone) next)))
(defun deck--manageable-p (state id)
  (and (not (member id (getf state :fullscreen))) (not (member id (getf state :floating)))))

(defun deck--current (state)
  "The window a command acts on: the focused one while it is in the window set,
otherwise whatever the deck still shows. A command must never depend on an id a
gone window left behind, or the keys go dead."
  (let ((focus (getf state :focus))
        (windows (deck--windows state)))
    (or (and (member focus windows) focus)
        (deck--front state :left)
        (deck--front state :right)
        (first windows))))

;; --- usable area -------------------------------------------------------------

(defun deck--exclusive-edge (anchors)
  "The edge an exclusive zone applies to, by the layer-shell rule."
  (let ((set (sort (copy-list anchors) #'string< :key #'symbol-name)))
    (cond ((equal set '(:top)) '(:top))
          ((equal set '(:bottom)) '(:bottom))
          ((equal set '(:left)) '(:left))
          ((equal set '(:right)) '(:right))
          ((equal set '(:left :right :top)) '(:top))
          ((equal set '(:bottom :left :right)) '(:bottom))
          ((equal set '(:bottom :left :top)) '(:left))
          ((equal set '(:bottom :right :top)) '(:right))
          (t nil))))

(defun deck--layer-inset (layer edge)
  "What LAYER reserves on EDGE: its exclusive zone plus that edge's margin."
  (let ((zone (getf layer :exclusive-zone))
        (margin (getf layer :margin)))
    (if (and (getf layer :visible) (integerp zone) (plusp zone)
             (member edge (deck--exclusive-edge (getf layer :anchors))))
        (+ zone (ecase edge
                  (:top (first margin)) (:right (second margin))
                  (:bottom (third margin)) (:left (fourth margin))))
        0)))

(defun deck--output-of (outputs entry)
  (let ((cx (+ (getf entry :x) (floor (getf entry :width) 2)))
        (cy (+ (getf entry :y) (floor (getf entry :height) 2))))
    (find-if (lambda (output)
               (and (<= (getf output :x) cx (+ (getf output :x) (getf output :width)))
                    (<= (getf output :y) cy (+ (getf output :y) (getf output :height)))))
             outputs)))

(defun deck--area (snapshot)
  "The focused window's output box and the area its exclusive zones leave free.
A layer surface carries no output name here, so every mapped panel is charged
against the output the layout is drawing on."
  (let* ((outputs (context snapshot :outputs))
         (focus (context snapshot :focus))
         (entry (and focus (deck--layout-entry (context snapshot :layout) focus)))
         (output (or (and entry (deck--output-of outputs entry)) (first outputs))))
    (when output
      (flet ((inset (edge)
               (reduce #'+ (context snapshot :layers) :initial-value 0
                       :key (lambda (layer) (deck--layer-inset layer edge)))))
        (let ((left (inset :left)) (right (inset :right))
              (top (inset :top)) (bottom (inset :bottom)))
          (list :output output
                :x (+ (getf output :x) left) :y (+ (getf output :y) top)
                :width (max 1 (- (getf output :width) left right))
                :height (max 1 (- (getf output :height) top bottom))))))))

;; --- geometry ----------------------------------------------------------------

(defun deck--box (state area id)
  "Where ID goes, or NIL when it is not in the window set."
  (let* ((gaps +deck-gaps+)
         ;; Gaps are an outer margin too: the layout draws inside them.
         (x (+ (getf area :x) gaps)) (y (+ (getf area :y) gaps))
         (width (- (getf area :width) (* 2 gaps))) (height (- (getf area :height) (* 2 gaps))))
    (cond
      ((not (member id (deck--windows state))) nil)
      ((member id (getf state :fullscreen))
       (let ((output (getf area :output)))
         (list (getf output :x) (getf output :y) (getf output :width) (getf output :height))))
      ((member id (getf state :floating)) (cdr (deck--entry (getf state :floats) id)))
      ((getf state :grid)
       (let* ((wins (remove-if-not (lambda (candidate) (deck--manageable-p state candidate))
                                   (deck--windows state)))
              (index (position id wins))
              (count (length wins))
              (cols (ceiling (sqrt count)))
              (rows (ceiling count cols))
              (cell-width (floor (- width (* (1- cols) gaps)) cols))
              (cell-height (floor (- height (* (1- rows) gaps)) rows))
              (column (mod index cols))
              (row (floor index cols)))
         (list (+ x (* column (+ cell-width gaps))) (+ y (* row (+ cell-height gaps)))
               cell-width cell-height)))
      (t
       (let* ((ratio (nth (1- (getf state :ratio)) +deck-ratios+))
              (left-width (floor (* (- width gaps) ratio)))
              (right-width (- width gaps left-width))
              (side (deck--side-of state id))
              (column (deck--column state side))
              (front (position (deck--front state side) column))
              (index (position id column)))
         (when (and side index front)
           (list (if (eql side :left) x (+ x left-width gaps))
                 (+ y (* (- index front) (+ height gaps)))
                 (if (eql side :left) left-width right-width)
                 height)))))))

(defun deck--places (snapshot state area)
  "One place effect per live window: exactly one owner, no duplicates."
  (let ((windows (deck--windows state)))
    (loop for window in (context snapshot :windows)
          for id = (getf window :id)
          for box = (deck--box state area id)
          append (list (if box
                           (apply #'place id (append box (list t)))
                           (place id 0 0 (max 1 (getf window :width))
                                  (max 1 (getf window :height)) nil)))
          ;; The deck owns fullscreen, so it asserts it for every window: T for
          ;; its own fullscreen set, NIL otherwise. Emitting nothing for the
          ;; rest would let the shipped window-state unit's accepted client
          ;; request stand (it mounts before this one). Denying it here is the
          ;; Rust WM's honor_client_fullscreen = false: a client cannot choose
          ;; layout policy, but Mod+f still fullscreens.
          append (list (fullscreen id (and box (member id windows)
                                           (member id (getf state :fullscreen))
                                           t))))))

;; --- commands ----------------------------------------------------------------

(defun deck--focus-window (state id)
  (setf (getf state :focus) id)
  state)

(defun deck--adopt-front (state side id)
  (let ((fronts (deck--fronts state)))
    (setf (cdr (assoc side fronts)) id))
  state)

(defun deck--rotate (state direction)
  "Scroll the side holding the current window; the deck wraps."
  (let* ((id (deck--current state))
         (side (deck--side-of state id))
         (column (deck--column state side)))
    (when (and side column)
      (let* ((index (position id column))
             (target (nth (mod (+ index direction) (length column)) column)))
        (deck--adopt-front state side target)
        (deck--focus-window state target)))))

(defun deck--reorder (state direction)
  "Swap the current window with its neighbour in its own column's order."
  (let* ((id (deck--current state))
         (side (deck--side-of state id))
         (column (deck--column state side))
         (index (position id column))
         (other (and index (nth (+ index direction) column)))
         (order (deck--windows state))
         (mine (and other (position id order)))
         (theirs (and other (position other order))))
    (when (and other mine theirs)
      (setf (nth mine order) other
            (nth theirs order) id))
    state))

(defun deck--cycle (state direction)
  "Focus the next or previous window in the window set, wrapping."
  (let* ((order (deck--windows state))
         (id (deck--current state))
         (index (or (position id order) 0))
         (target (and order (nth (mod (+ index direction) (length order)) order))))
    (when target
      (let ((side (deck--side-of state target)))
        (when side (deck--adopt-front state side target)))
      (deck--focus-window state target))))

(defun deck--swap-columns (state)
  (dolist (entry (getf state :columns))
    (setf (cdr entry) (if (eql (cdr entry) :left) :right :left)))
  (let ((fronts (deck--fronts state)))
    (let ((left (cdr (assoc :left fronts))) (right (cdr (assoc :right fronts))))
      (setf (cdr (assoc :left fronts)) right (cdr (assoc :right fronts)) left)))
  state)

(defun deck--to-column (state side)
  "Send the current window to SIDE, where it becomes that deck's front."
  (let* ((id (deck--current state))
         (previous (deck--side-of state id)))
    (when (and id (deck--manageable-p state id))
      (when (and previous (not (eql previous side)) (eql id (deck--front state previous)))
        ;; Popping the front reveals the window after it, as a scroll would.
        (let* ((column (deck--column state previous))
               (index (position id column))
               (next (and index (nth (mod (1+ index) (length column)) column))))
          (deck--adopt-front state previous (if (and next (not (eql next id))) next nil))))
      (setf (cdr (assoc id (getf state :columns))) side)
      (deck--adopt-front state side id))
    state))

(defun deck--toggle-floating (state area)
  (let ((id (deck--current state)))
    (when id
      (cond
        ((member id (getf state :fullscreen))
         ;; A fullscreen client becomes tiled on the first press, as in Tomoe.
         (setf (getf state :fullscreen) (remove id (getf state :fullscreen))))
        ((member id (getf state :floating))
         (setf (getf state :floating) (remove id (getf state :floating))
               (getf state :floats) (remove id (getf state :floats) :key #'car)))
        (t
         (let* ((width (floor (* (getf area :width) +deck-float-numerator+)))
                (height (floor (* (getf area :height) +deck-float-numerator+)))
                (x (+ (getf area :x) (floor (- (getf area :width) width) 2)))
                (y (+ (getf area :y) (floor (- (getf area :height) height) 2))))
           (push id (getf state :floating))
           (push (cons id (list x y width height)) (getf state :floats))))))
    state))

(defun deck--command (state area command)
  (cond
    ((equal command "focus-left")
     (deck--focus-window state (or (deck--front state :left) (deck--current state))))
    ((equal command "focus-right")
     (deck--focus-window state (or (deck--front state :right) (deck--current state))))
    ((equal command "scroll-down") (deck--rotate state 1))
    ((equal command "scroll-up") (deck--rotate state -1))
    ((equal command "next") (deck--cycle state 1))
    ((equal command "previous") (deck--cycle state -1))
    ((equal command "swap-columns") (deck--swap-columns state))
    ((equal command "move-down") (deck--reorder state 1))
    ((equal command "move-up") (deck--reorder state -1))
    ((equal command "to-left") (deck--to-column state :left))
    ((equal command "to-right") (deck--to-column state :right))
    ((equal command "grid") (setf (getf state :grid) (not (getf state :grid))))
    ((equal command "ratio")
     (setf (getf state :ratio) (1+ (mod (getf state :ratio) (length +deck-ratios+)))))
    ((equal command "floating") (deck--toggle-floating state area))
    ((equal command "fullscreen")
     (let ((id (deck--current state)))
       (when id
         (if (member id (getf state :fullscreen))
             (setf (getf state :fullscreen) (remove id (getf state :fullscreen)))
             (progn (setf (getf state :floating) (remove id (getf state :floating)))
                    (push id (getf state :fullscreen)))))))
    (t state)))

;; --- bindings ----------------------------------------------------------------

(defun deck--bindings ()
  (mapcar (lambda (binding) (apply #'bind-key binding)) +deck-bindings+))

;; --- extension ---------------------------------------------------------------

(define-extension "deck"
    (:reads (:windows :outputs :layers :layout :focus :key :button)
     :state (deck--state))
    (snapshot state event)
  (let* ((windows (context snapshot :windows))
         (ids (mapcar (lambda (window) (getf window :id)) windows))
         (focused (context snapshot :focus))
         (area (deck--area snapshot))
         (type (getf event :type)))
    ;; A front that closes hands its deck on, before the prune drops the id: the
    ;; window after it in that column takes the front, as a scroll would, and the
    ;; column that held the focused window keeps the keyboard. Without the handoff
    ;; the column keeps a front that is gone, so nothing in it is placed or shown
    ;; and no key can bring it back.
    (when (eq type :unmap)
      (let ((gone (getf event :id)))
        (dolist (side '(:left :right))
          (when (eql gone (cdr (assoc side (getf state :fronts))))
            (let ((next (deck--after-front state (deck--windows state) side gone)))
              (setf (cdr (assoc side (getf state :fronts))) next)
              (when (and next (eql gone (getf state :focus)))
                (setf (getf state :focus) next)))))))
    ;; Forget windows that are gone; ids are reused by the compositor.
    (setf (getf state :windows) (remove-if-not (lambda (id) (member id ids)) (getf state :windows))
          (getf state :columns) (remove-if-not (lambda (entry) (member (car entry) ids))
                                               (getf state :columns))
          (getf state :fronts)
          ;; A deck front that closed is cleared, never removed: the two keys
          ;; have to survive every prune, or adopting a front has nothing to set.
          (loop for entry in (getf state :fronts)
                collect (if (and (cdr entry) (not (member (cdr entry) ids)))
                            (cons (car entry) nil)
                            entry))
          (getf state :floating) (remove-if-not (lambda (id) (member id ids)) (getf state :floating))
          (getf state :floats) (remove-if-not (lambda (entry) (member (car entry) ids))
                                              (getf state :floats))
          (getf state :fullscreen) (remove-if-not (lambda (id) (member id ids))
                                                  (getf state :fullscreen)))
    (unless (member (getf state :focus) ids) (setf (getf state :focus) nil))
    ;; A click or a focus command from another unit moves focus; adopt it first
    ;; so a window that maps in the same dispatch still takes focus afterwards.
    (when (and focused (not (eql focused (getf state :focus)))
               (member focused (deck--windows state))
               (deck--manageable-p state focused))
      (let ((side (deck--side-of state focused)))
        (when side
          (deck--adopt-front state side focused)
          (deck--focus-window state focused))))
    ;; A new window joins the focused window's column, or the emptier one, and
    ;; arrives at the front of that deck.
    (dolist (window windows)
      (let ((id (getf window :id)))
        (unless (or (deck--side-of state id) (member id (getf state :floating)))
          (let* ((focus-side (and focused (deck--side-of state focused)))
                 (left (length (deck--column state :left)))
                 (right (length (deck--column state :right)))
                 ;; An even split puts the newcomer on the left, as in Tomoe.
                 (side (or focus-side (if (<= left right) :left :right))))
            (push (cons id side) (getf state :columns))
            (setf (getf state :windows) (append (getf state :windows) (list id)))
            (deck--adopt-front state side id)
            (setf (getf state :focus) id)))))
    (when (and (eq type :key) (equal (getf event :owner) "deck"))
      (deck--command state area (getf event :command)))
    ;; A client fullscreen request is denied: it never joins the fullscreen
    ;; set, and deck--places asserts NIL so window-state's acceptance is
    ;; overridden. Mod+f is the only way in.
    ;; A click focuses the window under the pointer and brings it to the front
    ;; of its deck, the way Tomoe's on_focus_change does. This unit owns focus
    ;; while it is mounted, so click-to-focus has to be answered here too.
    (when (and (eq type :button) (eql (getf event :state) :pressed))
      (let ((id (getf event :id)))
        (when (and (integerp id) (member id (deck--windows state))
                   (deck--manageable-p state id) (deck--side-of state id))
          (deck--adopt-front state (deck--side-of state id) id)
          (deck--focus-window state id))))
    ;; Close and quit are one-shot commands; only key and button dispatch may
    ;; return them, so the binding names them directly.
    (let* ((command (when (and (eq type :key) (equal (getf event :owner) "deck"))
                      (getf event :command)))
           (current (deck--current state)))
      (values state
              (append (deck--bindings) (deck--places snapshot state area)
                      ;; Focus always names a window the window set shows,
                      ;; so no command can leave the keyboard without a target.
                      (list (focus current)))
              (cond ((and (equal command "close") current)
                     (list (close-window current)))
                    (t nil))))))
