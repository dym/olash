#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(require :asdf)

;;; If a fasl was stale, try to recompile and load (once).
(defmethod asdf:perform :around ((o asdf:load-op)
				 (c asdf:cl-source-file))
  (handler-case (call-next-method o c)
    ;; If a fasl was stale, try to recompile and load (once).
    (sb-ext:invalid-fasl ()
      (asdf:perform (make-instance 'asdf:compile-op) c)
      (call-next-method))))

(ql:quickload 'closure-template)
(ql:quickload 'md5)
(ql:quickload 'iterate)
(ql:quickload 'drakma)
(ql:quickload 'split-sequence)
(ql:quickload 'cl-ppcre)
(ql:quickload 'yason)
(ql:quickload 'routes)
(ql:quickload 'trivial-backtrace)
(ql:quickload 'rfc2388)
(ql:quickload 'cl-fad)
(ql:quickload 'hunchentoot)
(ql:quickload 'hunchentoot-cgi)
(ql:quickload 'iolib.syscalls)
(ql:quickload 'local-time)