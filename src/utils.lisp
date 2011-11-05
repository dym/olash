; -*- coding: utf-8; mode: common-lisp; -*-

(in-package :olash)

(defmacro cdr-assoc (key array)
  `(cdr (assoc ,key ,array)))

(defun encode-json (obj)
  (flet ((encode-json-list (list stream)
           (if (keywordp (car list))
               (json:encode-json-plist list stream)
               (json::encode-json-list-guessing-encoder list stream))))
    (let ((json::*json-list-encoder-fn* #'encode-json-list))
      (json:encode-json-to-string obj))))

(defmacro simple-json-bind ((&rest vars) stream &body body)
  (let ((cur-dec (gensym))
        (key-handler
         `(lambda (json-string)
            (let ((lisp-string
                   (funcall json:*json-identifier-name-to-lisp*
                            json-string)))
              ;; On recognizing a variable name, the key handler sets
              ;; the value handler to be a function which,
              ;; in its turn, assigns the decoded value to the
              ;; corresponding variable.  If no variable name matches
              ;; the key, the value handler is set to skip the value.
              (json:set-custom-vars
                  :object-value
                    (cond
                      ,@(loop for var in vars
                          collect
                           `((string= lisp-string ,(symbol-name var))
                             (lambda (value)
                               (setq ,var value))))
                      (t (constantly t))))))))
    `(let ((,cur-dec (json:current-decoder))
           ,@vars)
       (json:bind-custom-vars
           (:internal-decoder ,cur-dec
            :beginning-of-object (constantly t)
            :object-key ,key-handler
            :end-of-object (constantly t))
         (json:decode-json ,stream))
       ,@body)))

(defun get-week-points (current-time)
  (list (adjust-timestamp current-time (offset :day-of-week :monday))
        current-time))

(defun test-token-callback (token)
  (format t "TOKEN: ~a~%" token))

(defun get-odesk-teams (token)
  (odesk:with-odesk (:format :json
                     :public-key *odesk-api-public-key*
                     :secret-key *odesk-api-secret-key*
                     :api-token token)
    (let* ((json-text (first (odesk:hr/get-teams)))
           (rooms (if json-text
                      (json:with-decoder-simple-list-semantics
                        (with-input-from-string (s json-text)
                          (simple-json-bind (teams) s
                            teams))))))
      (if (listp rooms)
          (iter (for rooms-list in rooms)
                (collect (cdr-assoc :id rooms-list)))
          (cdr-assoc :id rooms)))))

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
           (rows (json:with-decoder-simple-list-semantics
                     (with-input-from-string (s json-text)
                       (simple-json-bind (table) s
                         (cdr-assoc :rows table))))))
      (iter (for elem in rows)
            (sum (read-from-string (cdr-assoc :v (first (cdr-assoc :c elem)))))))))

(defun fetch-hours-from-workdiary (token &key username date)
  (let ((teamrooms (get-odesk-teams token))
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
               (snap-list (if json-text
                              (json:with-decoder-simple-list-semantics
                                (with-input-from-string (s json-text)
                                  (simple-json-bind (snapshots) s
                                    (cdr-assoc :snapshot snapshots))))))
               (team-periods (iter (for elem in snap-list)
                                   (if (not (cl-ppcre:scan
                                             "non-billed"
                                             (cdr-assoc :billing--status elem)))
                                       (count elem)))))
          (format t "[workdiary] Teamroom: ~A (~A)= ~A~%" teamroom date (/ team-periods 6.0))
          (incf hours (/ team-periods 6.0)))))
    hours))

(defun rbauth-token-callback (token)
  (odesk:with-odesk (:format :json
                     :public-key *odesk-api-public-key*
                     :secret-key *odesk-api-secret-key*
                     :api-token token)
    (let* ((json-text (first (odesk:hr/get-myself)))
           (user-info (json:with-decoder-simple-list-semantics
                        (with-input-from-string (s json-text)
                          (simple-json-bind (user) s
                            user))))
           (username (cdr (assoc :id user-info)))
           (session (rbauth:generate-session username)))
      (rbauth:login username token session
                    :first-name (cdr (assoc :first--name user-info))
                    :last-name (cdr (assoc :last--name user-info)))
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
    (format t "[report] ~A .. ~A = ~A~%" start-date end-date hours)
    (+ hours
       (fetch-hours-from-workdiary token
                                   :username username
                                   :date current-date))))