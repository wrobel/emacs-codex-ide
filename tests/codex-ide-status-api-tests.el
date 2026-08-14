;;; codex-ide-status-api-tests.el --- Status API tests for codex-ide -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'codex-ide)
(require 'codex-ide-status-api)

(ert-deftest codex-ide-thread-row-normalizes-public-schema ()
  (let* ((directory (codex-ide--normalize-directory "/tmp/status-api"))
         (session (codex-ide-session :directory directory
                                     :thread-id "thread-one"
                                     :status "running"))
         (thread `((id . "thread-one")
                   (name . "Public row")
                   (cwd . ,directory)
                   (createdAt . 10)
                   (updatedAt . 20))))
    (cl-letf (((symbol-function 'codex-ide--session-for-thread-id)
               (lambda (thread-id row-directory)
                 (when (and (equal thread-id "thread-one")
                            (equal row-directory directory))
                   session))))
      (let ((row (codex-ide-thread-row thread)))
        (should (eq (plist-get row :kind) 'thread))
        (should (equal (plist-get row :thread-id) "thread-one"))
        (should (equal (plist-get row :title) "Public row"))
        (should (equal (plist-get row :directory) directory))
        (should (= (plist-get row :created-at) 10))
        (should (= (plist-get row :updated-at) 20))
        (should (equal (plist-get row :technical-status) "running"))
        (should (eq (plist-get row :session) session))))))

(ert-deftest codex-ide-list-thread-rows-global-uses-global-inventory ()
  (let ((global-called nil)
        (project-called nil)
        (thread '((id . "thread-global")
                  (name . "Global")
                  (cwd . "/tmp/global"))))
    (cl-letf (((symbol-function 'codex-ide--prepare-session-operations)
               (lambda () nil))
              ((symbol-function 'codex-ide--get-working-directory)
               (lambda () "/tmp/query"))
              ((symbol-function 'codex-ide--ensure-query-session-for-thread-selection)
               (lambda (_directory) 'query-session))
              ((symbol-function 'codex-ide--global-thread-list-data)
               (lambda (_session &optional _omit-thread-id)
                 (setq global-called t)
                 (list thread)))
              ((symbol-function 'codex-ide--thread-list-data)
               (lambda (&rest _args)
                 (setq project-called t)
                 nil))
              ((symbol-function 'codex-ide--session-for-thread-id)
               (lambda (&rest _args) nil)))
      (let ((rows (codex-ide-list-thread-rows :global t)))
        (should global-called)
        (should-not project-called)
        (should (equal (plist-get (car rows) :thread-id) "thread-global"))
        (should (equal (plist-get (car rows) :technical-status) "stored"))))))

(ert-deftest codex-ide-open-thread-resolves-directory-from-public-global-rows ()
  (let ((opened nil))
    (cl-letf (((symbol-function 'codex-ide-list-thread-rows)
               (lambda (&rest _args)
                 (list (list :thread-id "thread-open"
                             :directory "/tmp/open-project"))))
              ((symbol-function 'codex-ide--prepare-session-operations)
               (lambda () nil))
              ((symbol-function 'codex-ide--show-or-resume-thread)
               (lambda (thread-id directory)
                 (setq opened (list thread-id directory)))))
      (codex-ide-open-thread "thread-open")
      (should (equal opened '("thread-open" "/tmp/open-project"))))))

(ert-deftest codex-ide-status-actions-register-filter-and-unregister ()
  (let ((codex-ide-status-actions nil)
        (handler (lambda (_row) 'handled)))
    (codex-ide-register-status-action
     "Only linked"
     handler
     (lambda (row) (plist-get row :linked)))
    (should-not (codex-ide-status-available-actions '(:linked nil)))
    (should (equal (plist-get
                    (car (codex-ide-status-available-actions '(:linked t)))
                    :function)
                   handler))
    (codex-ide-unregister-status-action "Only linked")
    (should-not codex-ide-status-actions)))

(ert-deftest codex-ide-status-annotation-text-combines-provider-results ()
  (let ((codex-ide-status-annotation-functions
         (list (lambda (_row) "TODO")
               (lambda (_row) '("linked" "review"))
               (lambda (_row) nil))))
    (should (equal (codex-ide-status-annotation-text '(:thread-id "thread"))
                   "TODO  linked  review"))))

(provide 'codex-ide-status-api-tests)

;;; codex-ide-status-api-tests.el ends here
