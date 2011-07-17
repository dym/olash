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


(restas:define-route util-get-hours ("/util/hours/"
                                     :content-type "application/json")
  (let ((session (hunchentoot:cookie-in *olash-web-session-key*)))
    (if (rbauth:authenticated-p session)
        (odesk:with-odesk (:format :json
                           :public-key *odesk-api-public-key*
                           :secret-key *odesk-api-secret-key*
                           :api-token (rbauth:get-token session))
          (let* ((week-points (get-week-points (today)))
                 (json-text
                  (first
                   (odesk:timereports/get-provider :provider
                                                   (rbauth:get-username session)
                                                   :parameters
                                                   (list (cons "tq" (format nil "SELECT hours, team_id, worked_on WHERE (worked_on >= '~a') AND (worked_on < '~a')" (first week-points) (second week-points)))))))
                 (parsed-json (json:parse json-text))
                 (table (gethash "table" parsed-json))
                 (rows (gethash "rows" table))
                 (hours (iter (for htable in rows)
                              (collect (read-from-string (gethash "v" (first (gethash "c" htable))))))))
            (tpl:utils-hours (list :content (format nil "{\"result\": \"~a\"}" (* (/ (apply '+ hours) 30) 100))))))
        (tpl:utils-hours (list :content "{\"result\": \"empty\"}")))))