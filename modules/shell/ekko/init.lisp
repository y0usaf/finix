;; Keep V2's builtins; add convenient split keys and a session-aware status.
(in-package #:cl-user)
(ekko/extensions:register-component
 :id :finix :reads '(:session :focus)
 :handler (lambda (snapshot event)
            (declare (ignore event))
            (list (ekko/extensions:action
                   :status :text
                   (format nil " ~A | pane ~D | C-b: v/h split  Tab focus  [ copy  r reload  ? help  d detach"
                           (ekko/extensions:value snapshot :session)
                           (ekko/extensions:value snapshot :focus))))))
(ekko/extensions:bind-key :component :finix :key "v" :command "split-columns")
(ekko/extensions:bind-key :component :finix :key "h" :command "split-rows")
