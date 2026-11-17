(in-package #:tomoe-user)

(defun tomoe-setting-known-p (key)
  "Whether the running Tomoe's settings table has KEY. A config is loaded by
whatever build is running, which can predate the build it was generated for, and
a setting that build does not know refuses the extension that publishes it, so
an optional setting is published only where the running core lists it."
  (and (boundp 'tomoe::+settings+) (not (null (assoc key tomoe::+settings+)))))
