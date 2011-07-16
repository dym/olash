; -*- coding: utf-8; mode: common-lisp; -*-

(defpackage :olash-asd
  (:use :cl
        :asdf))

(in-package :olash-asd)

(defsystem olash
  :name "olash"
  :version "0.0.0"
  :author "Dmitriy Budashny <dmitriy.budashny@gmail.com>"
  :license "BSD"
  :components
  ((:module "src"
            :components
            ((:file "defmodule")
             (:file "routes" :depends-on ("defmodule")))))
  :depends-on (#:restas #:restas-directory-publisher
                        #:restas-odesk #:closure-template))