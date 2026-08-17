;;; codex-ide-delete-session-thread-tests.el --- Tests for delete-session-thread -*- lexical-binding: t; -*-

;;; Commentary:

;; Focused ERT coverage for the CODEX_HOME-backed thread deletion module.

;;; Code:

(require 'ert)
(require 'codex-ide-test-fixtures)
(require 'codex-ide)

(ert-deftest codex-ide-thread-rollout-path-finds-active-and-archived-storage ()
  (let* ((codex-home (make-temp-file "codex-ide-delete-storage-" t))
         (active-directory (expand-file-name "sessions/2026/08/17" codex-home))
         (archive-directory (expand-file-name "archived_sessions" codex-home))
         (active-id "thread-active-storage")
         (archived-id "thread-archived-storage")
         (active-file (expand-file-name
                       (format "rollout-active-%s.jsonl" active-id)
                       active-directory))
         (archived-file (expand-file-name
                         (format "rollout-archived-%s.jsonl" archived-id)
                         archive-directory))
         (process-environment (copy-sequence process-environment)))
    (unwind-protect
        (progn
          (make-directory active-directory t)
          (make-directory archive-directory t)
          (with-temp-file active-file)
          (with-temp-file archived-file)
          (setenv "CODEX_HOME" codex-home)
          (should (equal (codex-ide--thread-rollout-path active-id) active-file))
          (should (equal (codex-ide--thread-rollout-path archived-id) archived-file)))
      (delete-directory codex-home t))))

(ert-deftest codex-ide-delete-thread-storage-allows-archived-rollout ()
  (let* ((codex-home (make-temp-file "codex-ide-delete-archive-" t))
         (archive-directory (expand-file-name "archived_sessions" codex-home))
         (archived-file (expand-file-name
                         "rollout-archived-thread.jsonl"
                         archive-directory))
         (process-environment (copy-sequence process-environment)))
    (unwind-protect
        (progn
          (make-directory archive-directory t)
          (with-temp-file archived-file)
          (setenv "CODEX_HOME" codex-home)
          (codex-ide--delete-thread-storage archived-file)
          (should-not (file-exists-p archived-file))
          (should (file-directory-p archive-directory)))
      (delete-directory codex-home t))))

(ert-deftest codex-ide-delete-thread-storage-rejects-unrelated-file ()
  (let* ((codex-home (make-temp-file "codex-ide-delete-home-" t))
         (outside-directory (make-temp-file "codex-ide-delete-outside-" t))
         (outside-file (expand-file-name "rollout-outside.jsonl" outside-directory))
         (process-environment (copy-sequence process-environment)))
    (unwind-protect
        (progn
          (with-temp-file outside-file)
          (setenv "CODEX_HOME" codex-home)
          (should-error (codex-ide--delete-thread-storage outside-file))
          (should (file-exists-p outside-file)))
      (delete-directory codex-home t)
      (delete-directory outside-directory t))))

(ert-deftest codex-ide-delete-session-thread-deletes-live-session-and-storage ()
  (let ((project-dir (codex-ide-test--make-temp-project))
        (deleted-session nil)
        (deleted-storage nil)
        (prompt nil))
    (codex-ide-test-with-fixture project-dir
				 (codex-ide-test-with-fake-processes
				  (let ((session (codex-ide--create-process-session)))
				    (setf (codex-ide-session-thread-id session) "thread-delete-1")
				    (cl-letf (((symbol-function 'codex-ide--thread-rollout-path)
					       (lambda (_thread-id)
						 "/tmp/codex-thread-delete-1.jsonl"))
					      ((symbol-function 'yes-or-no-p)
					       (lambda (message)
						 (setq prompt message)
						 t))
					      ((symbol-function 'codex-ide--delete-live-thread-session)
					       (lambda (value)
						 (setq deleted-session value)))
					      ((symbol-function 'codex-ide--delete-thread-storage)
					       (lambda (rollout-path)
						 (setq deleted-storage rollout-path))))
				      (codex-ide-delete-session-thread "thread-delete-1")
				      (should (eq deleted-session session))
				      (should (equal deleted-storage "/tmp/codex-thread-delete-1.jsonl"))
				      (should (string-match-p
					       (regexp-quote
						(buffer-name (codex-ide-session-buffer session)))
					       prompt))))))))

(ert-deftest codex-ide-delete-session-thread-cancel-keeps-live-session-and-storage ()
  (let ((project-dir (codex-ide-test--make-temp-project))
        (deleted-session nil)
        (deleted-storage nil))
    (codex-ide-test-with-fixture project-dir
				 (codex-ide-test-with-fake-processes
				  (let ((session (codex-ide--create-process-session)))
				    (setf (codex-ide-session-thread-id session) "thread-delete-2")
				    (cl-letf (((symbol-function 'codex-ide--thread-rollout-path)
					       (lambda (_thread-id)
						 "/tmp/codex-thread-delete-2.jsonl"))
					      ((symbol-function 'yes-or-no-p)
					       (lambda (&rest _) nil))
					      ((symbol-function 'codex-ide--delete-live-thread-session)
					       (lambda (value)
						 (setq deleted-session value)))
					      ((symbol-function 'codex-ide--delete-thread-storage)
					       (lambda (&rest args)
						 (setq deleted-storage args))))
				      (should-error (codex-ide-delete-session-thread "thread-delete-2")
						    :type 'user-error)
				      (should-not deleted-session)
				      (should-not deleted-storage)
				      (should (buffer-live-p (codex-ide-session-buffer session)))))))))

(ert-deftest codex-ide-delete-session-thread-errors-when-storage-is-missing ()
  (let ((project-dir (codex-ide-test--make-temp-project))
        (prompted nil)
        (deleted-storage nil))
    (codex-ide-test-with-fixture project-dir
				 (cl-letf (((symbol-function 'codex-ide--thread-rollout-path)
					    (lambda (&rest _) nil))
					   ((symbol-function 'yes-or-no-p)
					    (lambda (&rest _)
					      (setq prompted t)
					      t))
					   ((symbol-function 'codex-ide--delete-thread-storage)
					    (lambda (&rest args)
					      (setq deleted-storage args))))
				   (should-error (codex-ide-delete-session-thread "thread-delete-missing")
						 :type 'user-error)
				   (should-not prompted)
				   (should-not deleted-storage)))))

(ert-deftest codex-ide-delete-session-thread-skip-confirmation-bypasses-prompt ()
  (let ((project-dir (codex-ide-test--make-temp-project))
        (deleted-session nil)
        (deleted-storage nil)
        (prompted nil))
    (codex-ide-test-with-fixture project-dir
				 (codex-ide-test-with-fake-processes
				  (let ((session (codex-ide--create-process-session)))
				    (setf (codex-ide-session-thread-id session) "thread-delete-3")
				    (cl-letf (((symbol-function 'codex-ide--thread-rollout-path)
					       (lambda (_thread-id)
						 "/tmp/codex-thread-delete-3.jsonl"))
					      ((symbol-function 'yes-or-no-p)
					       (lambda (&rest _)
						 (setq prompted t)
						 (ert-fail "Unexpected confirmation prompt")))
					      ((symbol-function 'codex-ide--delete-live-thread-session)
					       (lambda (value)
						 (setq deleted-session value)))
					      ((symbol-function 'codex-ide--delete-thread-storage)
					       (lambda (rollout-path)
						 (setq deleted-storage rollout-path))))
				      (codex-ide-delete-session-thread "thread-delete-3" t)
				      (should (eq deleted-session session))
				      (should (equal deleted-storage "/tmp/codex-thread-delete-3.jsonl"))
				      (should-not prompted)))))))

(provide 'codex-ide-delete-session-thread-tests)

;;; codex-ide-delete-session-thread-tests.el ends here
