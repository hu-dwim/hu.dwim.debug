;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.debug)

(def (macro e) break* ((&key io-format debugger-format inspect) &body forms)
  `(restart-case
       (bind ((values (multiple-value-list ,@forms)))
         ,@(when io-format `((format *debug-io* ,io-format values)))
         ,@(when inspect `((swank::inspect-in-emacs values :wait #f)))
         ,@(when debugger-format `((break ,debugger-format values)))
         (swank::quit-inspector)
         (values-list values))
     (return-from-break-with-values ()
       :report (lambda (stream)
                 (format stream "Continue by returning different values from BREAK."))
       (format *debug-io* "Enter new values to return with: ")
       ;; TODO: since we are in a macro, we could possibly pass down the lexical environment to eval
       (eval (read)))))

(def (macro e) break/print* ((&rest args &key &allow-other-keys) &body forms)
  `(break* (,@args :io-format "Stopping in debugger with multiple values: ~{~A ~}~%" :debugger-format "~{~A ~}")
     ,@forms))

(def (macro e) break/print (&body forms)
  `(break/print* ()
     ,@forms))

(def (macro e) break/inspect* ((&rest args &key &allow-other-keys) &body forms)
  `(break/print* (,@args :inspect #t)
     ,@forms))

(def (macro e) break/inspect (&body forms)
  `(break/inspect* ()
     ,@forms))
