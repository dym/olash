; -*- coding: utf-8; mode: common-lisp; -*-

(in-package :olash)

(restas:define-route main ("")
  (tpl:main (list :title "oLash | We will motivate you to work"
                  :content "Here will be some content")))