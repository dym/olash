; -*- coding: utf-8; mode: common-lisp; -*-

(in-package :olash)

(defun test-token-callback (token)
  (format t "TOKEN: ~a~%" token))

(defun rbauth-token-callback (token)
  (odesk:with-odesk (:format :json
                     :public-key *odesk-api-public-key*
                     :secret-key *odesk-api-secret-key*
                     :api-token token)
    (let* ((json-text (first (odesk:hr/get-myself)))
           (parsed-json (json:parse json-text))
           (user-info (gethash "user" parsed-json))
           (username (gethash "id" user-info))
           (first-name (gethash "first_name" user-info))
           (last-name (gethash "last_name" user-info))
           (session (rbauth:generate-session username)))
      (rbauth:login username token session
                    :first-name first-name
                    :last-name last-name)
      (hunchentoot:set-cookie *olash-web-session-key*
                              :value session))))