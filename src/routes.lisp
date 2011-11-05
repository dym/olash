; -*- coding: utf-8; mode: common-lisp; -*-

(in-package :olash)

(restas:define-route main ("")
  (let ((session (hunchentoot:cookie-in *olash-web-session-key*)))
    (if (rbauth:authenticated-p session)
        (let ((first-name (rbauth:get-first-name session))
              (last-name (rbauth:get-last-name session)))
          (tpl:main-logged (list :title "oLash | We motivate"
                                 :firstname first-name
                                 :lastname last-name)))
        (tpl:main (list :title "oLash | We motivate")))))

; Fix for some bugs
(restas:define-route main-nil ("/NIL")
  (restas:redirect "/"))

(restas:define-route logout ("/logout/")
  (let ((session (hunchentoot:cookie-in *olash-web-session-key*)))
    (if (rbauth:authenticated-p session)
        (rbauth:logout session)))
  (restas:redirect "/"))

(restas:define-route util-get-hours ("/util/hours/"
                                     :content-type "application/json"
                                     :render-method #'encode-json)
  (let ((session (hunchentoot:cookie-in *olash-web-session-key*)))
    (if (rbauth:authenticated-p session)
        (list :result (format nil "~,2f" (* (/ (get-hours session) 40) 100)))
        '(:result "empty"))))