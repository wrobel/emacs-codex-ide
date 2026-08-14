;;; codex-ide-protocol-tests.el --- Protocol tests for codex-ide -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'codex-ide)

(ert-deftest codex-ide-list-threads-follows-pagination-cursors ()
  (let* ((project-dir (codex-ide--normalize-directory temporary-file-directory))
         (session (codex-ide-session :directory project-dir))
         (captured-params nil))
    (cl-letf (((symbol-function 'codex-ide--request-sync)
               (lambda (_session method params)
                 (push params captured-params)
                 (should (equal method "thread/list"))
                 (if (alist-get 'cursor params)
                     '((data . [((id . "thread-two"))]))
                   '((data . [((id . "thread-one"))])
                     (nextCursor . "page-two"))))))
      (should (equal (codex-ide--list-threads session :limit 25)
                     '(((id . "thread-one"))
                       ((id . "thread-two")))))
      (should (equal (nreverse captured-params)
                     `(((cwd . ,project-dir)
                        (limit . 25)
                        (sortKey . "updated_at"))
                       ((cwd . ,project-dir)
                        (limit . 25)
                        (sortKey . "updated_at")
                        (cursor . "page-two"))))))))

(ert-deftest codex-ide-list-threads-global-omits-working-directory ()
  (let* ((session (codex-ide-session :directory temporary-file-directory))
         (captured-params nil))
    (cl-letf (((symbol-function 'codex-ide--request-sync)
               (lambda (_session method params)
                 (setq captured-params params)
                 (should (equal method "thread/list"))
                 '((data . [((id . "thread-global")
                             (cwd . "/tmp/elsewhere"))])))))
      (should (equal (codex-ide--list-threads session :global t)
                     '(((id . "thread-global")
                        (cwd . "/tmp/elsewhere")))))
      (should-not (assq 'cwd captured-params)))))

(provide 'codex-ide-protocol-tests)

;;; codex-ide-protocol-tests.el ends here
