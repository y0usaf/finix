(in-package #:tomoe-user)

(defparameter +notif-thread--max-cards+ 6)
(defparameter +notif-thread--summary-lines+ 2)
(defparameter +notif-thread--body-lines+ 5)
(defparameter +notif-thread--summary-chars+ 256)
(defparameter +notif-thread--body-chars+ 512)

(defun notif-thread--string (value)
  (if (stringp value) value ""))

(defun notif-thread--clean-text (text limit)
  (let* ((raw (notif-thread--string text))
         (trimmed (subseq raw 0 (min (length raw) limit)))
         (parts nil)
         (start 0)
         (len (length trimmed)))
    (loop for i below len
          when (char= (char trimmed i) #\Return)
            do (push (subseq trimmed start i) parts)
               (setf start (1+ i)))
    (push (subseq trimmed start len) parts)
    (values (apply #'concatenate 'string (nreverse parts))
            (> (length raw) limit))))

(defun notif-thread--split-lines (text)
  (let ((len (length text))
        (start 0)
        (lines nil))
    (loop for i below len
          when (char= (char text i) #\Newline)
            do (push (subseq text start i) lines)
               (setf start (1+ i)))
    (push (subseq text start len) lines)
    (nreverse lines)))

(defun notif-thread--break-char-p (ch)
  (or (char= ch #\Space)
      (char= ch #\Tab)
      (char= ch #\/)
      (char= ch #\-)
      (char= ch #\_)
      (char= ch #\.)))

(defun notif-thread--ellipsis (line max-chars)
  (let* ((trimmed (string-trim " " line))
         (keep (max 1 (min (length trimmed) (- max-chars 3)))))
    (concatenate 'string (subseq trimmed 0 keep) "...")))

(defun notif-thread--wrap-paragraph (paragraph max-chars)
  (let* ((clean (string-trim " " paragraph))
         (len (length clean)))
    (if (zerop len)
        nil
        (let ((lines nil)
              (pos 0))
          (loop while (< pos len)
                do (loop while (and (< pos len)
                                    (or (char= (char clean pos) #\Space)
                                        (char= (char clean pos) #\Tab)))
                         do (incf pos))
                   (when (< pos len)
                     (let ((rem (- len pos)))
                       (if (<= rem max-chars)
                           (progn
                             (push (string-trim " " (subseq clean pos len)) lines)
                             (setf pos len))
                           (let* ((limit (+ pos max-chars))
                                  (floor-pos (+ pos (max 1 (floor max-chars 2))))
                                  (split nil))
                             (loop for i from limit downto floor-pos
                                   when (and (< i len) (notif-thread--break-char-p (char clean i)))
                                     do (setf split i)
                                        (return))
                             (cond ((null split)
                                    (push (subseq clean pos limit) lines)
                                    (setf pos limit))
                                   ((or (char= (char clean split) #\Space)
                                        (char= (char clean split) #\Tab))
                                    (push (string-trim " " (subseq clean pos split)) lines)
                                    (setf pos (1+ split)))
                                   (t
                                    (let ((cut (min len (1+ split))))
                                      (push (subseq clean pos cut) lines)
                                      (setf pos cut)))))))))
          (nreverse lines)))))

(defun notif-thread--wrap (text max-chars max-lines char-limit)
  (multiple-value-bind (clean clipped-p) (notif-thread--clean-text text char-limit)
    (let* ((paragraphs (notif-thread--split-lines clean))
           (cols (max 12 max-chars))
           (all nil))
      (dolist (p paragraphs)
        (dolist (line (notif-thread--wrap-paragraph p cols))
          (push line all)))
      (let* ((ordered (nreverse all))
             (truncated (or clipped-p (> (length ordered) max-lines)))
             (shown (if (> (length ordered) max-lines)
                        (subseq ordered 0 max-lines)
                        ordered)))
        (when (and truncated shown)
          (let ((tail (1- (length shown))))
            (setf (nth tail shown) (notif-thread--ellipsis (nth tail shown) cols))))
        shown))))

(defun notif-thread--prefix-p (prefix text)
  (and (stringp text)
       (>= (length text) (length prefix))
       (string= prefix text :end2 (length prefix))))

(defun notif-thread--dismiss-id (event)
  (when (and (eq (getf event :type) :ui)
             (equal (getf event :owner) "notification-thread"))
    (let* ((cmd (getf event :command))
           (raw (cond ((symbolp cmd) (symbol-name cmd))
                      ((stringp cmd) cmd)
                      (t nil)))
           (name (and raw (string-upcase raw))))
      (when (and name (notif-thread--prefix-p "DISMISS-" name) (> (length name) 8))
        (let ((digits (subseq name 8)))
          (when (and (plusp (length digits))
                     (every #'digit-char-p digits))
            (parse-integer digits)))))))

(defun notif-thread--enter-timer-p (event)
  (when (eq (getf event :type) :timer)
    (let* ((name (getf event :name))
           (raw (cond ((symbolp name) (symbol-name name))
                      ((stringp name) name)
                      (t nil)))
           (str (and raw (string-upcase raw))))
      (and str (notif-thread--prefix-p "NOTIF-ENTER-" str)))))

(defun notif-thread--layout-entry (snapshot id)
  (and id
       (let ((entry (find id (context snapshot :layout) :key (lambda (e) (getf e :id)))))
         (when (and entry
                    (getf entry :visible)
                    (plusp (getf entry :width 0))
                    (plusp (getf entry :height 0)))
           entry))))

(defun notif-thread--window-meta (snapshot id)
  (and id (find id (context snapshot :windows) :key (lambda (w) (getf w :id)))))

(defun notif-thread--overlap-area (ax ay aw ah bx by bw bh)
  (let ((x0 (max ax bx))
        (y0 (max ay by))
        (x1 (min (+ ax aw) (+ bx bw)))
        (y1 (min (+ ay ah) (+ by bh))))
    (if (and (> x1 x0) (> y1 y0))
        (* (- x1 x0) (- y1 y0))
        0)))

(defun notif-thread--box-output (outputs box &optional output-name)
  (let* ((bx (getf box :x 0))
         (by (getf box :y 0))
         (bw (getf box :width 0))
         (bh (getf box :height 0))
         (cx (+ bx (floor bw 2)))
         (cy (+ by (floor bh 2))))
    (or (thread-design--output-at outputs cx cy)
        (let ((best nil)
              (best-area 0))
          (dolist (out outputs)
            (let ((area (notif-thread--overlap-area bx by bw bh
                                                    (getf out :x 0) (getf out :y 0)
                                                    (getf out :width 0) (getf out :height 0))))
              (when (> area best-area)
                (setf best out best-area area))))
          best)
        (and output-name
             (find output-name outputs :key (lambda (o) (getf o :name)) :test #'equal))
        (first outputs))))

(defun notif-thread--output-fullscreen-p (snapshot output)
  (let ((ox (getf output :x 0))
        (oy (getf output :y 0))
        (ow (getf output :width 0))
        (oh (getf output :height 0)))
    (loop for entry in (context snapshot :layout)
          for meta = (notif-thread--window-meta snapshot (getf entry :id))
          thereis (and (getf entry :visible)
                       (or (getf entry :fullscreen) (getf meta :fullscreen))
                       (plusp (notif-thread--overlap-area
                               (getf entry :x 0) (getf entry :y 0)
                               (getf entry :width 0) (getf entry :height 0)
                               ox oy ow oh))))))

(defun notif-thread--focal-box (snapshot output)
  (let ((focal (state-value snapshot :focal-frame)))
    (when (and focal (equal (getf focal :output) (getf output :name)))
      (let ((scale (thread-design--output-scale output)))
        (list :x (+ (getf output :x 0) (round (* (getf focal :left 0) scale)))
              :y (+ (getf output :y 0) (round (* (getf focal :top 0) scale)))
              :width (round (* (getf focal :width 0) scale))
              :height (round (* (getf focal :height 0) scale)))))))

(defun notif-thread--workarea-box (snapshot output)
  (let ((area (find (getf output :name) (context snapshot :workareas)
                    :key (lambda (w) (getf w :name)) :test #'equal)))
    (if (and area (plusp (getf area :width 0)) (plusp (getf area :height 0)))
        (list :x (getf area :x (getf output :x 0))
              :y (getf area :y (getf output :y 0))
              :width (getf area :width (getf output :width 0))
              :height (getf area :height (getf output :height 0)))
        (list :x (getf output :x 0)
              :y (getf output :y 0)
              :width (getf output :width 0)
              :height (getf output :height 0)))))

(defun notif-thread--anchor-for-window (snapshot id outputs now &optional locked-at)
  (let ((entry (notif-thread--layout-entry snapshot id)))
    (when entry
      (let* ((meta (notif-thread--window-meta snapshot id))
             (out (notif-thread--box-output outputs entry (getf meta :output))))
        (when out
          (list :window-id id
                :output (getf out :name)
                :x (getf entry :x)
                :y (getf entry :y)
                :width (getf entry :width)
                :height (getf entry :height)
                :fullscreen (and (or (getf entry :fullscreen)
                                     (getf meta :fullscreen)
                                     (notif-thread--output-fullscreen-p snapshot out))
                                 t)
                :locked-at (or locked-at now)))))))

(defun notif-thread--anchor-fallback (snapshot outputs now &optional preferred-output locked-at reacquire)
  (let* ((focal (state-value snapshot :focal-frame))
         (out (or (and preferred-output
                       (find preferred-output outputs :key (lambda (o) (getf o :name)) :test #'equal))
                  (and focal
                       (find (getf focal :output) outputs :key (lambda (o) (getf o :name)) :test #'equal))
                  (first outputs))))
    (when out
      (let ((box (or (notif-thread--focal-box snapshot out)
                     (notif-thread--workarea-box snapshot out))))
        (list :window-id nil
              :output (getf out :name)
              :x (getf box :x)
              :y (getf box :y)
              :width (getf box :width)
              :height (getf box :height)
              :fullscreen (and (notif-thread--output-fullscreen-p snapshot out) t)
              :locked-at (or locked-at now)
              :reacquire (and reacquire t))))))

(defun notif-thread--resolve-anchor (snapshot existing focus-id focus-since has-new-arrival outputs now)
  (let* ((locked-at (getf existing :locked-at))
         (reacquire (and existing (getf existing :reacquire) t))
         (refreshed
           (cond ((null existing) nil)
                 ((getf existing :window-id)
                  (notif-thread--anchor-for-window snapshot (getf existing :window-id) outputs now locked-at))
                 (t
                  (and (find (getf existing :output) outputs :key (lambda (o) (getf o :name)) :test #'equal)
                       (notif-thread--anchor-fallback snapshot outputs now (getf existing :output) locked-at reacquire)))))
         (settle-delay (thread-design--motion :focus-settle-delay)))
    (cond ((null refreshed)
           (or (notif-thread--anchor-for-window snapshot focus-id outputs now)
               (notif-thread--anchor-fallback snapshot outputs now
                                              (and existing (getf existing :output))
                                              nil
                                              (and existing (getf existing :window-id) t))))
          ((and (getf refreshed :reacquire) focus-id)
           (or (notif-thread--anchor-for-window snapshot focus-id outputs now)
               refreshed))
          ((and has-new-arrival
                focus-id
                (not (eql focus-id (getf refreshed :window-id)))
                (or (null (getf refreshed :window-id))
                    (>= (- now focus-since) settle-delay)))
           (or (notif-thread--anchor-for-window snapshot focus-id outputs now)
               refreshed))
          (t refreshed))))

(defun notif-thread--same-content-p (entry notif)
  (and (equal (getf entry :app) (notif-thread--string (getf notif :app)))
       (equal (getf entry :summary) (notif-thread--string (getf notif :summary)))
       (equal (getf entry :body) (notif-thread--string (getf notif :body)))
       (eql (and (getf entry :urgent) t) (and (getf notif :urgent) t))))

(defun notif-thread--content-spec (entry card-w)
  (let* ((app (string-trim " " (notif-thread--string (getf entry :app))))
         (summary (string-trim " " (notif-thread--string (getf entry :summary))))
         (body (string-trim " " (notif-thread--string (getf entry :body))))
         (urgent (and (getf entry :urgent) t))
         (title-src (if (plusp (length summary)) summary app))
         (show-app (and (plusp (length app))
                        (or (not (string-equal app title-src)) urgent)))
         (header-p (or show-app urgent))
         (inner-w (max 140 (- card-w 28)))
         (title-cols (max 14 (floor inner-w 7.6d0)))
         (body-cols (max 16 (floor inner-w 6.8d0)))
         (title-lines (if (plusp (length title-src))
                          (notif-thread--wrap title-src title-cols
                                              +notif-thread--summary-lines+
                                              +notif-thread--summary-chars+)
                          (list "Notification")))
         (body-lines (when (plusp (length body))
                       (notif-thread--wrap body body-cols
                                           +notif-thread--body-lines+
                                           +notif-thread--body-chars+)))
         (title-lh (thread-design--type :title-line-height))
         (body-lh (thread-design--type :body-line-height))
         (meta-lh (thread-design--type :meta-line-height))
         (card-h (+ 24
                    (if header-p (+ meta-lh 5) 0)
                    (* (length title-lines) title-lh)
                    (if body-lines (+ 5 (* (length body-lines) body-lh)) 0)
                    4)))
    (list :app (if show-app app (if urgent "URGENT" ""))
          :header-p header-p
          :urgent urgent
          :title-lines title-lines
          :body-lines body-lines
          :card-h card-h)))

(defun notif-thread--card-tree (entry spec mode card-w pad alpha)
  (let* ((urgent (getf spec :urgent))
         (header-p (getf spec :header-p))
         (app (getf spec :app))
         (title-lines (getf spec :title-lines))
         (body-lines (getf spec :body-lines))
         (card-h (getf spec :card-h))
         (dot-color (thread-design--token mode (if urgent :urgent :accent)))
         (dismiss-key (intern (format nil "DISMISS-~D" (getf entry :id)) :keyword))
         (children nil))
    (when header-p
      (let ((header-items (list (thread-design--bead-dot :mode mode :size 6 :color dot-color :alpha alpha))))
        (when (plusp (length app))
          (setf header-items
                (append header-items
                        (list (thread-design--text (string-upcase app)
                                                   :mode mode :role :ink-subtle
                                                   :size (thread-design--type :meta-size)
                                                   :line-height (thread-design--type :meta-line-height)
                                                   :alpha alpha)))))
        (when urgent
          (setf header-items
                (append header-items
                        (list (ui :spacer)
                              (thread-design--pill "URGENT"
                                                   :mode mode
                                                   :color (thread-design--token mode :urgent)
                                                   :background (thread-design--token mode :urgent-tint)
                                                   :alpha alpha)))))
        (push (ui :row :align :center :gap 7 :children header-items) children)))
    (push (ui :column :gap 0
              :children (loop for line in title-lines
                              collect (thread-design--text line
                                                           :mode mode :role :ink
                                                           :size (thread-design--type :title-size)
                                                           :line-height (thread-design--type :title-line-height)
                                                           :alpha alpha)))
          children)
    (when body-lines
      (push (ui :column :gap 0
                :children (loop for line in body-lines
                                collect (thread-design--text line
                                                             :mode mode :role :ink-muted
                                                             :size (thread-design--type :body-size)
                                                             :line-height (thread-design--type :body-line-height)
                                                             :alpha alpha)))
            children))
    (ui :column :padding pad
        :children
        (list (ui :column :width card-w :height card-h
                  :padding '(12 12 12 16) :gap 5
                  :on-click dismiss-key
                  :children (nreverse children))))))

(defun notif-thread--shader-data (entry mode scale pad epoch)
  (let* ((cast (thread-design--mode mode))
         (urgent (and (getf entry :urgent) t))
         (plate-rgb (getf cast :plate-rgb))
         (plate-a (coerce (getf cast :plate-alpha) 'double-float))
         (accent-rgb (getf cast (if urgent :urgent-rgb :accent-rgb)))
         (exit-at (getf entry :exit-at))
         (pulse (getf entry :pulse)))
    (list (coerce (* pad scale) 'double-float)
          (coerce (* (thread-design--geom :plate-radius) scale) 'double-float)
          (coerce (* (thread-design--geom :notif-rim-width) scale) 'double-float)
          (coerce scale 'double-float)
          (coerce (first plate-rgb) 'double-float)
          (coerce (second plate-rgb) 'double-float)
          (coerce (third plate-rgb) 'double-float)
          plate-a
          (coerce (first accent-rgb) 'double-float)
          (coerce (second accent-rgb) 'double-float)
          (coerce (third accent-rgb) 'double-float)
          (if urgent 1d0 0d0)
          (if (eq mode :light) 1d0 0d0)
          (coerce (- (getf entry :born) epoch) 'double-float)
          (coerce (thread-design--motion :enter-duration) 'double-float)
          (if exit-at (coerce (- exit-at epoch) 'double-float) -1d6)
          (coerce (thread-design--motion :exit-duration) 'double-float)
          (if (and (realp pulse) (> pulse -1d5))
              (coerce (- pulse epoch) 'double-float)
              -1d6))))

(defun notif-thread--until (entry epoch)
  (let* ((born (getf entry :born))
         (pulse (getf entry :pulse))
         (exit-at (getf entry :exit-at))
         (enter-end (+ (- born epoch) (thread-design--motion :enter-settle)))
         (pulse-end (if (and (realp pulse) (> pulse -1d5))
                        (+ (- pulse epoch) (thread-design--motion :pulse-duration))
                        0d0))
         (exit-end (if exit-at
                       (+ (- exit-at epoch) (thread-design--motion :exit-duration) 0.06d0)
                       0d0)))
    (max 0d0 enter-end pulse-end exit-end)))

(define-extension "notification-thread"
    (:reads (:services :outputs :workareas :windows :layout :focus :data :ui)
     :state (list :entries nil :anchor nil :dismissed nil :focus-id nil :focus-since 0d0 :gen 0))
    (snapshot state event)
  (let* ((now (thread-design--now))
         (epoch (thread-design--epoch now))
         (mode (state-value snapshot :theme-mode :dark))
         (outputs (context snapshot :outputs))
         (service (service-state snapshot :notifications))
         (raw-notifs (and (getf service :available)
                          (listp (getf service :notifications))
                          (reverse (getf service :notifications))))
         (focus-id (context snapshot :focus))
         (prev-focus (getf state :focus-id))
         (focus-since (if (eql focus-id prev-focus)
                          (getf state :focus-since 0d0)
                          now))
         (clicked-id (notif-thread--dismiss-id event))
         (enter-tick (notif-thread--enter-timer-p event))
         (prev-entries (copy-list (getf state :entries)))
         (dismissed (copy-list (getf state :dismissed)))
         (gen (getf state :gen 0))
         (exit-dur (thread-design--motion :exit-duration))
         (has-new-arrival nil))
    (when clicked-id
      (let ((src (or (find clicked-id raw-notifs :key (lambda (n) (getf n :id)))
                     (find clicked-id prev-entries :key (lambda (e) (getf e :id))))))
        (when src
          (setf dismissed
                (cons (list :id clicked-id
                            :app (notif-thread--string (getf src :app))
                            :summary (notif-thread--string (getf src :summary))
                            :body (notif-thread--string (getf src :body))
                            :urgent (and (getf src :urgent) t))
                      (remove clicked-id dismissed :key (lambda (rec) (getf rec :id))))))))
    (setf dismissed
          (loop for rec in dismissed
                for live = (find (getf rec :id) raw-notifs :key (lambda (n) (getf n :id)))
                when (and live (notif-thread--same-content-p rec live))
                  collect rec))
    (let* ((active-live (remove-if (lambda (n)
                                     (find (getf n :id) dismissed :key (lambda (rec) (getf rec :id))))
                                   raw-notifs))
           (active-ids (mapcar (lambda (n) (getf n :id)) active-live))
           (next-entries nil))
      (dolist (notif active-live)
        (let* ((id (getf notif :id))
               (old (find id prev-entries :key (lambda (e) (getf e :id)))))
          (cond ((null old)
                 (setf has-new-arrival t)
                 (incf gen)
                 (push (list :id id
                             :gen gen
                             :app (notif-thread--string (getf notif :app))
                             :summary (notif-thread--string (getf notif :summary))
                             :body (notif-thread--string (getf notif :body))
                             :urgent (and (getf notif :urgent) t)
                             :born now
                             :pulse -1d6
                             :exit-at nil
                             :entered nil)
                       next-entries))
                (t
                 (let* ((changed (not (notif-thread--same-content-p old notif)))
                        (was-exiting (getf old :exit-at))
                        (entered-now (if was-exiting
                                         nil
                                         (or (getf old :entered)
                                             enter-tick
                                             (>= (- now (getf old :born now)) 0.004d0)))))
                   (when was-exiting
                     (setf has-new-arrival t)
                     (incf gen))
                   (push (list :id id
                               :gen (if was-exiting gen (getf old :gen 0))
                               :app (notif-thread--string (getf notif :app))
                               :summary (notif-thread--string (getf notif :summary))
                               :body (notif-thread--string (getf notif :body))
                               :urgent (and (getf notif :urgent) t)
                               :born (if was-exiting now (getf old :born now))
                               :pulse (if changed now (getf old :pulse -1d6))
                               :exit-at nil
                               :entered entered-now)
                         next-entries))))))
      (dolist (old prev-entries)
        (unless (member (getf old :id) active-ids)
          (let* ((exit-at (or (getf old :exit-at) now))
                 (elapsed (- now exit-at)))
            (when (< elapsed exit-dur)
              (push (list :id (getf old :id)
                          :gen (getf old :gen 0)
                          :app (getf old :app)
                          :summary (getf old :summary)
                          :body (getf old :body)
                          :urgent (getf old :urgent)
                          :born (getf old :born now)
                          :pulse (getf old :pulse -1d6)
                          :exit-at exit-at
                          :entered t)
                    next-entries)))))
      (setf next-entries (nreverse next-entries))
      (if (or (null next-entries) (null outputs))
          (values (list :entries nil :anchor nil :dismissed dismissed
                        :focus-id focus-id :focus-since focus-since :gen gen)
                  nil
                  nil)
          (let* ((anchor (notif-thread--resolve-anchor
                          snapshot (getf state :anchor) focus-id focus-since
                          has-new-arrival outputs now))
                 (output (or (and anchor
                                  (find (getf anchor :output) outputs
                                        :key (lambda (o) (getf o :name)) :test #'equal))
                             (first outputs)))
                 (scale (thread-design--output-scale output))
                 (ox (getf output :x 0))
                 (oy (getf output :y 0))
                 (ow (max 1 (getf output :width 1)))
                 (oh (max 1 (getf output :height 1)))
                 (out-w (/ ow scale))
                 (out-h (/ oh scale))
                 (ax0 (thread-design--clamp (getf anchor :x ox) ox (+ ox ow)))
                 (ay0 (thread-design--clamp (getf anchor :y oy) oy (+ oy oh)))
                 (ax1 (thread-design--clamp (+ (getf anchor :x ox) (getf anchor :width ow)) ax0 (+ ox ow)))
                 (ay1 (thread-design--clamp (+ (getf anchor :y oy) (getf anchor :height oh)) ay0 (+ oy oh)))
                 (valid-box (and (> (- ax1 ax0) 0) (> (- ay1 ay0) 0)))
                 (lx (if valid-box (/ (- ax0 ox) scale) 0d0))
                 (ly (if valid-box (/ (- ay0 oy) scale) 0d0))
                 (lw (if valid-box (/ (- ax1 ax0) scale) out-w))
                 (pad (thread-design--geom :shadow-pad))
                 (screen-m (thread-design--geom :notif-screen-margin))
                 (inset-x (thread-design--geom :notif-inset-x))
                 (inset-y (thread-design--geom :notif-inset-y))
                 (gap (thread-design--geom :notif-gap))
                 (max-card-w (thread-design--geom :notif-width))
                 (min-card-w (thread-design--geom :notif-min-width))
                 (avail-out-w (max 120 (- out-w (* 2 screen-m))))
                 (avail-win-w (- lw (* 2 inset-x)))
                 (card-w (min avail-out-w
                              (min max-card-w
                                   (max (min min-card-w avail-out-w) avail-win-w))))
                 (card-x (thread-design--clamp (- (+ lx lw) inset-x card-w)
                                               screen-m
                                               (max screen-m (- out-w screen-m card-w))))
                 (cursor-y (thread-design--clamp (+ ly inset-y)
                                                 screen-m
                                                 (max screen-m (- out-h screen-m 48))))
                 (fullscreen-p (or (getf anchor :fullscreen)
                                   (notif-thread--output-fullscreen-p snapshot output)))
                 (surfaces nil)
                 (enter-timers nil)
                 (has-exiting nil)
                 (shown-count 0))
            (dolist (entry next-entries)
              (when (< shown-count +notif-thread--max-cards+)
                (let* ((spec (notif-thread--content-spec entry card-w))
                       (max-h (max 48 (- out-h (* 2 screen-m))))
                       (card-h (min max-h (getf spec :card-h)))
                       (fits (or (zerop shown-count)
                                 (<= (+ cursor-y card-h) (- out-h screen-m)))))
                  (when fits
                    (let* ((clamped-y (thread-design--clamp cursor-y screen-m
                                                            (max screen-m (- out-h screen-m card-h))))
                           (surf-w (+ card-w (* 2 pad)))
                           (surf-h (+ card-h (* 2 pad)))
                           (base-x (thread-design--clamp (- card-x pad) 0 (max 0 (- out-w surf-w))))
                           (base-y (thread-design--clamp (- clamped-y pad) 0 (max 0 (- out-h surf-h))))
                           (exit-at (getf entry :exit-at))
                           (entering (and (null exit-at) (not (getf entry :entered))))
                           (y-off (cond (exit-at -10) (entering -12) (t 0)))
                           (surf-y (thread-design--clamp (+ base-y y-off) 0 (max 0 (- out-h surf-h))))
                           (alpha (if exit-at
                                      (thread-design--clamp (- 1d0 (/ (- now exit-at) (* 0.65d0 exit-dur))) 0d0 1d0)
                                      1d0))
                           (tree (if (> alpha 0.04d0)
                                     (notif-thread--card-tree entry spec mode card-w pad alpha)
                                     (ui :stack)))
                           (layer (if (or fullscreen-p (getf entry :urgent)) :overlay :top))
                           (surface-name (intern (format nil "NOTIF-THREAD-~D" (getf entry :id)) :keyword)))
                      (when entering
                        (push (once (intern (format nil "NOTIF-ENTER-~D-~D"
                                                    (getf entry :id) (getf entry :gen 0))
                                            :keyword)
                                    :refresh)
                              enter-timers))
                      (when exit-at
                        (setf has-exiting t))
                      (push (shell-surface surface-name tree
                                           :output (getf output :name)
                                           :anchors '(:top :left)
                                           :margin (list surf-y 0 0 base-x)
                                           :width surf-w
                                           :height surf-h
                                           :layer layer
                                           :placement :world
                                           :exclusive-zone 0
                                           :slide t
                                           :background (list :shader +notification-thread--shader+
                                                             :data (notif-thread--shader-data entry mode scale pad epoch)
                                                             :clock epoch
                                                             :until (notif-thread--until entry epoch)))
                            surfaces)
                      (setf cursor-y (+ clamped-y card-h gap))
                      (incf shown-count))))))
            (let ((timers (append (nreverse enter-timers)
                                  (when has-exiting
                                    (list (interval :notif-exit 55))))))
              (values (list :entries next-entries
                            :anchor anchor
                            :dismissed dismissed
                            :focus-id focus-id
                            :focus-since focus-since
                            :gen gen)
                      (append timers (nreverse surfaces))
                      nil)))))))
