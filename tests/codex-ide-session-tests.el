;;; codex-ide-session-tests.el --- Session tests for codex-ide -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'codex-ide)

(ert-deftest codex-ide-resume-global-uses-thread-working-directory ()
  (let ((selected-thread '((id . "thread-global")
                           (cwd . "/tmp/codex-global-project")))
        (resumed nil))
    (cl-letf (((symbol-function 'codex-ide--prepare-session-operations)
               (lambda () nil))
              ((symbol-function 'codex-ide--get-working-directory)
               (lambda () "/tmp/query-project"))
              ((symbol-function 'codex-ide--ensure-query-session-for-thread-selection)
               (lambda (_directory) 'query-session))
              ((symbol-function 'codex-ide--pick-thread-global)
               (lambda (_session &optional _omit-thread-id) selected-thread))
              ((symbol-function 'codex-ide--show-or-resume-thread)
               (lambda (thread-id directory)
                 (setq resumed (list thread-id directory)))))
      (codex-ide-resume-global)
      (should (equal resumed
                     (list "thread-global"
                           (codex-ide--normalize-directory
                            "/tmp/codex-global-project")))))))

(provide 'codex-ide-session-tests)

;;; codex-ide-session-tests.el ends here
