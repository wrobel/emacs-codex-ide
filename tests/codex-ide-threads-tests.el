;;; codex-ide-threads-tests.el --- Thread picker tests for codex-ide -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'codex-ide)

(ert-deftest codex-ide-pick-thread-global-displays-directory-and-returns-thread ()
  (let* ((thread '((id . "thread-global-1234")
                   (name . "Global task")
                   (createdAt . 1744038896)
                   (cwd . "/tmp/global-task")))
         (recorded-extra-properties nil))
    (cl-letf (((symbol-function 'codex-ide--global-thread-list-data)
               (lambda (&optional _session _omit-thread-id) (list thread)))
              ((symbol-function 'completing-read)
               (lambda (_prompt collection &rest _args)
                 (setq recorded-extra-properties completion-extra-properties)
                 (caar collection))))
      (should (equal (codex-ide--pick-thread-global 'query-session) thread))
      (let* ((affixation-function
              (plist-get recorded-extra-properties :affixation-function))
             (affixation (car (funcall affixation-function '("Global task")))))
        (should (equal (car affixation) "Global task"))
        (should (string-match-p
                 (regexp-quote
                  (abbreviate-file-name
                   (codex-ide--normalize-directory "/tmp/global-task")))
                 (nth 2 affixation)))))))

(provide 'codex-ide-threads-tests)

;;; codex-ide-threads-tests.el ends here
