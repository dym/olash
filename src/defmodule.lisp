; -*- coding: utf-8; mode: common-lisp; -*-

(in-package :olash)

(eval-when (:load-toplevel :compile-toplevel :execute)
  (defparameter *resources-dir*
    (merge-pathnames "resources/"
                     (asdf:component-pathname (asdf:find-system '#:olash))))

  (closure-template:compile-template :common-lisp-backend
                                     (merge-pathnames "index.tmpl"
                                                      *resources-dir*)))

;;;; restas odesk

(restas:mount-submodule olash-odesk (#:restas.odesk)
        (restas.odesk:*odesk-api-public-key* *odesk-api-public-key*)
        (restas.odesk:*odesk-api-secret-key* *odesk-api-secret-key*)
        (restas.odesk:*token-callback* 'rbauth-token-callback))

;;;; static files

(restas:mount-submodule olash-static (#:restas.directory-publisher)
  (restas.directory-publisher:*directory* (merge-pathnames "static/" *resources-dir*))
  (restas.directory-publisher:*autoindex* nil))