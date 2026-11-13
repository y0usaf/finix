(in-package #:tomoe-user)

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
(defparameter +deck--column-commands+
  '("focus-left" "focus-right" "swap-columns" "to-left" "to-right" "ratio"))
(defun deck--narrow-p (area)
  (let ((output (and area (getf area :output))))
    (and output (< (* 9 (getf output :width)) (* 21 (getf output :height))))))
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
the column empties. GONE still sits in ORDER, so the entry after it is the window
a scroll would have revealed; at the bottom of the column, the one above it."
  (let* ((column (remove-if-not (lambda (id) (eql (deck--side-of state id) side)) order))
         (index (position gone column))
         (next (and index (nth (if (< (1+ index) (length column)) (1+ index) (max 0 (1- index))) column))))
    (unless (eql next gone) next)))
(defun deck--manageable-p (state id)
  (and (not (member id (getf state :fullscreen))) (not (member id (getf state :floating)))))

(defparameter +deck--tab-gap+ 3
  "Logical pixels between two tabs in a strip.")
(defparameter +deck--tab-pad+ 7
  "Logical pixels of breathing room beside a tab's title.")
(defparameter +deck--tab-radius+ 3
  "Logical corner radius of a tab.")
(defparameter +deck--tab-advance+ 0.62
  "Roughly how much of a tab's font size one character covers, for fitting titles.
Titles are also clipped by their own box, so a wrong estimate costs space, never
an overflow into the next tab.")
(defparameter +deck--tab-colours+
  (list :base "#1e1e2e" :accent "#89b4fa" :subtext0 "#a6adc8")
  "Theme colours for the strips, used until the :THEME publisher carries its own.")

(defun deck--scale (area)
  (let ((output (getf area :output))) (/ (getf output :scale-120 120) 120)))
(defun deck--tab-height (area)
  "The strip's height: a title's line plus room above and below it."
  (let ((size (getf +layout+ :tab-size)))
    (round (* (deck--scale area) (+ size 12)))))
(defun deck--tab-font ()
  (or (getf +layout+ :tab-font) "monospace, Bold"))
(defun deck--tab-size ()
  (or (getf +layout+ :tab-size) 12))
(defun deck--colour (theme key)
  (or (getf theme key) (getf +deck--tab-colours+ key)))
(defun deck--tint (colour alpha)
  "COLOUR carrying ALPHA (0-255), when it has no alpha channel of its own."
  (if (and (stringp colour) (= (length colour) 7))
      (concatenate 'string colour (format nil "~2,'0X" alpha))
      colour))
(defun deck--tabs-p (state area)
  "Whether the deck draws tab strips at all: only where it has two tiled columns
on a wide output, so never in the even grid, beside a fullscreen window, or on an
output the deck lays out as one column."
  (and area (not (getf state :grid)) (not (getf state :fullscreen)) (not (deck--narrow-p area))))
(defun deck--tab-windows (state side)
  "The windows of SIDE that get a tab: the column's tiled windows, never a float."
  (remove-if-not (lambda (id) (deck--manageable-p state id)) (deck--column state side)))
(defun deck--tab-strip-p (state area side)
  (and (deck--tabs-p state area) (deck--tab-windows state side)))
(defun deck--tab-title (window)
  "A tab's label: the window title, else its app id, else a word for a bare window."
  (let ((title (getf window :title)) (app (getf window :app-id)))
    (cond ((and (stringp title) (plusp (length title))) title)
          ((and (stringp app) (plusp (length app))) app)
          (t "window"))))
(defun deck--tab-fit (text width)
  "TEXT cut to WIDTH logical pixels at the tab's size, with an ellipsis when it has
to lose something."
  (let* ((limit (max 1 (floor (/ width (* +deck--tab-advance+ (deck--tab-size))))))
         (length (length text)))
    (if (<= length limit)
        text
        (concatenate 'string (subseq text 0 (max 0 (1- limit))) (string (code-char #x2026))))))

(defun deck--column-frame (state area side)
  "The gap-inset box (X Y WIDTH HEIGHT) of SIDE's column on AREA."
  (let* ((gaps (getf +layout+ :gaps))
         (x (+ (getf area :x) gaps))
         (y (+ (getf area :y) gaps))
         (width (- (getf area :width) (* 2 gaps)))
         (height (- (getf area :height) (* 2 gaps)))
         (seam (getf +layout+ :seam))
         (left (deck--left-width state width)))
    (if (eql side :left)
        (list x y left height)
        (list (+ x left seam) y (- width seam left) height))))

(defun deck--tab-strip (state area side)
  "SIDE's strip in screen pixels: the top of the column's own box, where the tabs
sit and that the column's windows are placed under."
  (let ((output (getf area :output)))
    (destructuring-bind (x y width height) (deck--column-frame state area side)
      (declare (ignore height))
      (list :output (getf output :name) :ox (getf output :x) :oy (getf output :y)
            :x x :y y :width width :height (deck--tab-height area)
            :scale (deck--scale area)))))

(defun deck--tab-surface (state theme strip side windows)
  "One strip of tabs for SIDE, or NIL when the strip has nothing to show.
WINDOWS are the managed windows the tabs name."
  (let* ((tabs (deck--tab-windows state side))
         (front (deck--front state side))
         (size (deck--tab-size))
         (font (deck--tab-font))
         (height (/ (getf strip :height) (getf strip :scale)))
         (width (/ (getf strip :width) (getf strip :scale)))
         (count (length tabs))
         (gap (if (= count 1) 0 +deck--tab-gap+)))
    (when (plusp count)
      (let ((tab-width (/ (- width (* gap (1- count))) count))
            (base (deck--colour theme :base))
            (accent (deck--colour theme :accent))
            (subtext (deck--colour theme :subtext0)))
        (shell-surface (if (eql side :left) :deck-tabs-left :deck-tabs-right)
                       (ui :row :gap gap :height height
                           :radius +deck--tab-radius+
                           :background (deck--tint base 230)
                           :children
                           (loop for id in tabs
                                 for label = (deck--tab-title
                                              (find id windows :key (lambda (window) (getf window :id))))
                                 for active = (eql id front)
                                 collect
                                 (ui :button :key (intern (format nil "TAB-~D" id) :keyword)
                                     :on-click :tab
                                     :width tab-width :height height
                                     :radius +deck--tab-radius+
                                     :align :center
                                     :background (when active accent)
                                     :children
                                     (list (ui :text :text (deck--tab-fit label (- tab-width (* 2 +deck--tab-pad+)))
                                               :size size :font font
                                               :color (if active base subtext)
                                               :width (max 1 (- tab-width (* 2 +deck--tab-pad+))))))))
                       :output (getf strip :output)
                       :anchors '(:top :left)
                       :margin (list (round (- (getf strip :y) (getf strip :oy)) (getf strip :scale))
                                     0 0
                                     (round (- (getf strip :x) (getf strip :ox)) (getf strip :scale)))
                       :width (round (getf strip :width) (getf strip :scale))
                       :height (round (getf strip :height) (getf strip :scale))
                       :layer :top
                       :background "#00000000")))))

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

(defun deck--output-of (outputs entry)
  (let ((cx (+ (getf entry :x) (floor (getf entry :width) 2)))
        (cy (+ (getf entry :y) (floor (getf entry :height) 2))))
    (find-if (lambda (output)
               (and (<= (getf output :x) cx (+ (getf output :x) (getf output :width)))
                    (<= (getf output :y) cy (+ (getf output :y) (getf output :height)))))
             outputs)))

(defun deck--area (snapshot)
  "The focused window's output box and the area its exclusive zones leave free."
  (let* ((outputs (context snapshot :outputs))
         (focus (previous-context snapshot :focus))
         (entry (and focus (deck--layout-entry (previous-context snapshot :layout) focus)))
         (output (or (and entry (deck--output-of outputs entry)) (first outputs)))
         (area (and output (policy--area snapshot (getf output :name)))))
    (when area
      (list* :output output area))))

(defun deck--left-width (state width)
  "How wide the left column is, out of WIDTH less the seam between the columns."
  (floor (* (- width (getf +layout+ :seam)) (nth (1- (getf state :ratio)) (getf +layout+ :ratios)))))

(defun deck--grid-columns (state)
  (ceiling (sqrt (count-if (lambda (id) (deck--manageable-p state id)) (deck--windows state)))))

(defun deck--grid-extra (cols)
  "How much wider than a window gap the middle of an even grid is: it splits on
the deck's seam, so whatever stands there stays between the columns."
  (if (evenp cols) (- (getf +layout+ :seam) (getf +layout+ :gaps)) 0))

(defun deck--grid-cell (cols width)
  (floor (- width (* (1- cols) (getf +layout+ :gaps)) (deck--grid-extra cols)) cols))

(defun deck--split (state width)
  "Where the seam starts within the tiled WIDTH, or NIL when the deck has no
middle seam: a grid with an odd number of columns."
  (if (getf state :grid)
      (let ((cols (deck--grid-columns state)))
        (when (and (plusp cols) (evenp cols))
          (let ((half (/ cols 2)))
            (+ (* half (deck--grid-cell cols width)) (* (1- half) (getf +layout+ :gaps))))))
      (deck--left-width state width)))

(defun deck--seam (state area)
  "The free strip in the deck's middle seam on AREA, a window gap in from each
side; NIL on a narrow output, while a window is fullscreen, in a grid with an
odd number of columns, or when the seam is no wider than two gaps."
  (let* ((gaps (getf +layout+ :gaps))
         (x (and area (+ (getf area :x) gaps)))
         (split (and area (deck--split state (- (getf area :width) (* 2 gaps)))))
         (inner (- (getf +layout+ :seam) (* 2 gaps))))
    (unless (or (null split) (getf state :fullscreen) (deck--narrow-p area) (not (plusp inner)))
      (list :output (getf (getf area :output) :name)
            :x (+ x split gaps) :y (+ (getf area :y) gaps)
            :width inner :height (- (getf area :height) (* 2 gaps))))))

(defun deck--box (state area id)
  "Where ID goes, or NIL when it is not in the window set."
  (let* ((gaps (getf +layout+ :gaps))
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
              (cell-width (deck--grid-cell cols width))
              (cell-height (floor (- height (* (1- rows) gaps)) rows))
              (column (mod index cols))
              (row (floor index cols)))
         (list (+ x (* column (+ cell-width gaps)) (if (>= column (/ cols 2)) (deck--grid-extra cols) 0))
               (+ y (* row (+ cell-height gaps)))
               cell-width cell-height)))
      ((deck--narrow-p area)
       (let* ((column (remove-if-not (lambda (candidate) (deck--manageable-p state candidate))
                                     (deck--windows state)))
              (front (or (position (deck--current state) column) 0))
              (index (position id column)))
         (when index
           (list x (+ y (* (- index front) (+ height gaps))) width height))))
      (t
       (let* ((side (deck--side-of state id))
              (column (deck--column state side))
              (front (position (deck--front state side) column))
              (index (position id column))
              (strip (and side (deck--tab-strip-p state area side)
                          (+ (deck--tab-height area) gaps))))
         (when (and side index front)
           (destructuring-bind (column-x column-y column-width column-height)
               (deck--column-frame state area side)
             (let ((card-y (+ column-y (or strip 0)))
                   (card-height (max 1 (- column-height (or strip 0)))))
               (list column-x (+ card-y (* (- index front) (+ card-height gaps)))
                     column-width card-height)))))))))

(defun deck--places (managed state area)
  "One place effect per managed window: exactly one owner, no duplicates."
  (let ((windows (deck--windows state)))
    (loop for window in managed
          for id = (getf window :id)
          for box = (deck--box state area id)
          append (list (if box
                           (apply #'place id (append box (list t)))
                           (place id 0 0 (max 1 (getf window :width))
                                  (max 1 (getf window :height)) nil)))
          append (list (fullscreen id (and box (member id windows)
                                           (member id (getf state :fullscreen))
                                           t))))))

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
         (other (and index (>= (+ index direction) 0) (nth (+ index direction) column)))
         (order (deck--windows state))
         (mine (and other (position id order)))
         (theirs (and other (position other order))))
    (when (and other mine theirs)
      (setf (nth mine order) other
            (nth theirs order) id))
    state))

(defun deck--reorder-all (state direction)
  (let* ((order (deck--windows state))
         (index (position (deck--current state) order))
         (target (and index (+ index direction))))
    (when (and target (< -1 target (length order)))
      (rotatef (nth index order) (nth target order)))
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
        (let* ((column (deck--column state previous))
               (index (position id column))
               (next (and index (nth (mod (1+ index) (length column)) column))))
          (deck--adopt-front state previous (if (and next (not (eql next id))) next nil))))
      (setf (cdr (assoc id (getf state :columns))) side)
      (deck--adopt-front state side id))
    state))

(defun deck--set-fullscreen (state id on)
  (setf (getf state :fullscreen) (remove id (getf state :fullscreen)))
  (when on
    (setf (getf state :floating) (remove id (getf state :floating)))
    (push id (getf state :fullscreen))
    (deck--focus-window state id))
  state)

(defun deck--toggle-floating (state area)
  (let ((id (deck--current state)))
    (cond
      ((null id))
      ((member id (getf state :fullscreen)) (deck--set-fullscreen state id nil))
      ((member id (getf state :floating))
       (setf (getf state :floating) (remove id (getf state :floating))
             (getf state :floats) (remove id (getf state :floats) :key #'car)))
      (area
       (push id (getf state :floating))
       (push (cons id (policy--centred area (getf +layout+ :float-ratio))) (getf state :floats))))
    state))

(defun deck--command (state area command)
  (cond
    ((and (deck--narrow-p area)
          (or (member command +deck--column-commands+ :test #'equal)
              (member command '("scroll-down" "scroll-up" "move-down" "move-up") :test #'equal)))
     (cond ((equal command "scroll-down") (deck--cycle state 1))
           ((equal command "scroll-up") (deck--cycle state -1))
           ((equal command "move-down") (deck--reorder-all state 1))
           ((equal command "move-up") (deck--reorder-all state -1))))
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
     (setf (getf state :ratio) (1+ (mod (getf state :ratio) (length (getf +layout+ :ratios))))))
    ((equal command "floating") (deck--toggle-floating state area))
    ((equal command "fullscreen")
     (let ((id (deck--current state)))
       (when id (deck--set-fullscreen state id (not (member id (getf state :fullscreen)))))))
    (t state)))

(defun deck--request (state id request requested)
  (case request
    (:fullscreen (deck--set-fullscreen state id requested))
    (:unfullscreen (deck--set-fullscreen state id nil))
    (:activate
     (let ((side (deck--side-of state id)))
       (when (and side (deck--manageable-p state id)) (deck--adopt-front state side id))
       (deck--focus-window state id))))
  state)

(defun deck--tab-click (state element)
  "Bring the window a tab names to the front of its column and focus it. ELEMENT
is the tab's hit key, TAB-ID."
  (let ((id (and (stringp element)
                 (>= (length element) 4)
                 (string= "tab-" element :end2 4)
                 (parse-integer element :start 4 :junk-allowed t))))
    (when (and id (member id (deck--windows state)))
      (let ((side (deck--side-of state id)))
        (when (and side (deck--manageable-p state id)) (deck--adopt-front state side id)))
      (deck--focus-window state id)))
  state)

(defun deck--raises (state current)
  (mapcar #'raise-window
          (append (remove current (reverse (getf state :floating)))
                  (when (member current (getf state :floating)) (list current))
                  (getf state :fullscreen))))

(define-extension "deck"
    (:reads (:windows :rules :data :outputs :workareas :layout :focus :key :button :pointer :request
             :settings :ui)
     :state (deck--state) :admission t)
    (snapshot state event)
  (let* ((windows (remove-if (lambda (window) (policy--unmanaged-p snapshot window))
                             (context snapshot :windows)))
         (ids (mapcar (lambda (window) (getf window :id)) windows))
         (focused (previous-context snapshot :focus))
         (area (deck--area snapshot))
         (type (getf event :type))
         (command (and (eq type :key) (equal (getf event :owner) "deck") (getf event :command)))
         (terminal (and (equal command "terminal") (policy--terminal windows))))
    (when (eq type :unmap)
      (let ((gone (getf event :id)))
        (dolist (side '(:left :right))
          (when (eql gone (cdr (assoc side (getf state :fronts))))
            (let ((next (deck--after-front state (deck--windows state) side gone)))
              (setf (cdr (assoc side (getf state :fronts))) next)
              (when (and next (eql gone (getf state :focus)))
                (setf (getf state :focus) next)))))))
    (setf (getf state :windows) (remove-if-not (lambda (id) (member id ids)) (getf state :windows))
          (getf state :columns) (remove-if-not (lambda (entry) (member (car entry) ids))
                                               (getf state :columns))
          (getf state :fronts)
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
    (when (and focused (not (eql focused (getf state :focus)))
               (member focused (deck--windows state))
               (deck--manageable-p state focused))
      (let ((side (deck--side-of state focused)))
        (when side
          (deck--adopt-front state side focused)
          (deck--focus-window state focused))))
    (dolist (window windows)
      (let ((id (getf window :id)))
        (unless (or (deck--side-of state id) (member id (getf state :floating)))
          (let* ((focus-side (and focused (deck--side-of state focused)))
                 (left (length (deck--column state :left)))
                 (right (length (deck--column state :right)))
                 (side (or focus-side (if (<= left right) :left :right))))
            (push (cons id side) (getf state :columns))
            (setf (getf state :windows) (append (getf state :windows) (list id)))
            (deck--adopt-front state side id)
            (setf (getf state :focus) id)
            (when (getf window :fullscreen-requested)
              (deck--set-fullscreen state id t))))))
    (when command
      (deck--command state area command))
    (when terminal
      (deck--request state terminal :activate nil))
    (when (and (member type '(:metadata :request)) (member (getf event :id) ids))
      (deck--request state (getf event :id) (getf event :request) (getf event :requested)))
    (when (or (and (eq type :button) (eql (getf event :state) :pressed))
              (and (eq type :pointer) (eq (getf event :state) :enter) (getf event :moved)
                   (setting snapshot :focus-follows-mouse)))
      (let ((id (getf event :id)))
        (when (and (integerp id) (member id (deck--windows state)))
          (when (and (deck--manageable-p state id) (deck--side-of state id))
            (deck--adopt-front state (deck--side-of state id) id))
          (deck--focus-window state id))))
    (when (and (eq type :ui) (equal (getf event :command) "tab"))
      (deck--tab-click state (getf event :element)))
    (let ((current (deck--current state)))
      (values state
              (append (mapcar (lambda (binding) (apply #'bind-key binding))
                              (if (deck--narrow-p area)
                                  (remove-if (lambda (binding)
                                               (member (string-downcase (third binding))
                                                       +deck--column-commands+ :test #'equal))
                                             +layout-bindings+)
                                  +layout-bindings+))
                      (when area (deck--places windows state area))
                      (list (publish-state :deck-seam (deck--seam state area)))
                      (let ((theme (state-value snapshot :theme)))
                        (loop for side in '(:left :right)
                              for strip = (and area (deck--tab-strip-p state area side)
                                               (deck--tab-strip state area side))
                              when strip
                                collect (deck--tab-surface state theme strip side windows)))
                      (deck--raises state current)
                      (list (focus current :raise nil)))
              (when (and (equal command "terminal") (null terminal))
                (list (apply #'launch (policy--launch "terminal"))))))))
