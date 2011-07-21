; -*- coding: utf-8; mode: common-lisp; -*-

(in-package :olash)

(defun get-week-points (current-time)
  (let* ((start-time (adjust-timestamp current-time (offset :day-of-week :monday)))
         (end-time (adjust-timestamp start-time (offset :day 7))))
    (list (format-rfc3339-timestring nil start-time :omit-time-part t)
          (format-rfc3339-timestring nil end-time :omit-time-part t))))

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
                              :path "/"
                              :value session))))

(defun get-hours-from-report (session)
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
      (apply '+ hours))))
