(in-package #:tomoe-user)

(defun probe--sample (probe previous system)
  (let ((sample (copy-list previous)))
    (ecase probe
      (:cpu
       (let ((total (getf system :cpu-total)) (idle (getf system :cpu-idle)))
         (when total
           (let ((spent (- total (getf sample :total total))))
             (setf (getf sample :percent)
                   (if (plusp spent)
                       (max 0 (min 100 (round (* 100 (- spent (- idle (getf sample :idle idle)))) spent)))
                       (getf sample :percent 0))
                   (getf sample :total) total
                   (getf sample :idle) idle
                   (getf sample :temp) (getf system :cpu-temperature))))))
      (:memory
       (let ((total (getf system :memory-total)) (available (getf system :memory-available)))
         (when (and total (plusp total))
           (setf (getf sample :percent) (round (* 100 (- total available)) total)
                 (getf sample :used) (round (- total available) 1024)))))
      (:gpu
       (let ((gpu (first (getf system :gpus))))
         (cond (gpu (setf (getf sample :percent) (max 0 (min 100 (getf gpu :busy)))
                          (getf sample :used) (getf gpu :vram-used)
                          (getf sample :total) (getf gpu :vram-total)
                          (getf sample :temp) (getf gpu :temperature)
                          (getf sample :failures) 0))
               (system (setf (getf sample :failures) (1+ (getf sample :failures 0))))))))
    sample))

(defun probe--gpu-p (gpu) (and (getf gpu :percent) (< (getf gpu :failures 0) 3)))
