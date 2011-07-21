; -*- coding: utf-8; mode: common-lisp; -*-

(in-package :olash)

(defun get-week-points (current-time)
  (list (adjust-timestamp current-time (offset :day-of-week :monday))
        current-time))

(defun test-token-callback (token)
  (format t "TOKEN: ~a~%" token))

(defun get-teamrooms (token)
  (odesk:with-odesk (:format :json
                     :public-key *odesk-api-public-key*
                     :secret-key *odesk-api-secret-key*
                     :api-token token)
    (let* ((json-text (first (odesk:team/get-teamrooms)))
           (parsed-json (json:parse json-text))
           (rooms-list (gethash "teamroom" (gethash "teamrooms" parsed-json))))
      (iter (for htable in rooms-list)
            (collect (gethash "id" htable))))))

(defun fetch-hours-from-report (token &key username start-date end-date)
  (odesk:with-odesk (:format :json
                     :public-key *odesk-api-public-key*
                     :secret-key *odesk-api-secret-key*
                     :api-token token)
    (let* ((json-text
            (first
             (odesk:timereports/get-provider :provider
                                             username
                                             :parameters
                                             (list (cons "tq" (format nil "SELECT hours, team_id, worked_on WHERE (worked_on >= '~a') AND (worked_on < '~a')" start-date end-date))))))
           (parsed-json (json:parse json-text))
           (table (gethash "table" parsed-json))
           (rows (gethash "rows" table))
           (hours (iter (for htable in rows)
                        (collect (read-from-string (gethash "v" (first (gethash "c" htable))))))))
      (apply '+ hours))))

(defun fetch-hours-from-workdiary (token &key username date)
  (let ((teamrooms (get-teamrooms token))
        (hours 0))
    (odesk:with-odesk (:format :json
                       :public-key *odesk-api-public-key*
                       :secret-key *odesk-api-secret-key*
                       :api-token token)
      (dolist (teamroom teamrooms)
        (let* ((json-text
                (first
                 (odesk:team/get-workdiary :company teamroom
                                           :username username
                                           :date date)))
               (parsed-json (json:parse json-text))
               (snap-list (gethash "snapshot" (gethash "snapshots" parsed-json)))
               (snapshots (iter (for htable in snap-list)
                                (if (not (cl-ppcre:scan "non-billed" (gethash "billing_status" htable)))
                                    (collect htable)))))
          (incf hours
                (/ (length snapshots) 6.0)))))
    hours))


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

; There are 2 functions that can get time worked:
; * get-hours
; * get-hours-from-report
; 
; 1st works slower but fetches more fresh data
; 2nd works faster but fetches more old data
(defun get-hours-from-report (session)
  (let* ((week-points (get-week-points (today)))
         (start-date (format-rfc3339-timestring nil (first week-points) :omit-time-part t))
         (end-date (format-rfc3339-timestring nil (adjust-timestamp (second week-points) (offset :day 1)) :omit-time-part t)))
    (fetch-hours-from-report (rbauth:get-token session)
                             :username (rbauth:get-username session)
                             :start-date start-date
                             :end-date end-date)))

(defun get-hours (session)
  (let* ((current-time (today))
         (week-points (get-week-points current-time))
         (start-time (first week-points))
         (end-time (second week-points))
         (start-date (format-rfc3339-timestring nil start-time :omit-time-part t))
         (end-date (format-rfc3339-timestring nil end-time :omit-time-part t))
         (current-date (format nil "~4,'0d~2,'0d~2,'0d"
                               (timestamp-year current-time)
                               (timestamp-month current-time)
                               (timestamp-day current-time)))
         (username (rbauth:get-username session))
         (token (rbauth:get-token session))
         (hours 0))
    ; Check if it's monday
    (if (timestamp< start-time end-time)
        (incf hours
              (fetch-hours-from-report token
                                       :username username
                                       :start-date start-date
                                       :end-date end-date)))
    (+ hours
       (fetch-hours-from-workdiary token
                                   :username username
                                   :date current-date))))