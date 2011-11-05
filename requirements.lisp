; -*- coding: utf-8; mode: common-lisp; -*-

(setf sb-impl::*default-external-format* :utf-8)

(defparameter *list-of-libraries* '(:iterate
                                    :split-sequence
                                    :local-time
                                    :cl-ppcre
                                    :cl-json
                                    :drakma
                                    :closure-template
                                    :md5
                                    :trivial-backtrace
                                    :rfc2388
                                    :cl-fad
                                    :iolib.syscalls
                                    :cl-redis
                                    :swank
                                    :routes))

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

(dolist (library *list-of-libraries*)
  (ql:quickload library))
