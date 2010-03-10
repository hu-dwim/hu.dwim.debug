;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.debug)

;;;;;;
;;; Lexical trace

(def special-variable *trace-function-call-level* 0)

(def function write-indent ()
  (iter (repeat (* 2 *trace-function-call-level*))
        (write-char #\Space *trace-output*)))

(def layer lexical-trace (hu.dwim.walker::ignore-undefined-references)
  ())

(def (macro e) with-lexical-trace ((&rest args &key &allow-other-keys) &body forms)
  (declare (ignore args))
  (contextl:with-active-layers (lexical-trace)
    (unwalk-form (walk-form `(progn ,@forms)))))

(def function trace-free-application-form (operator &rest arguments)
  (write-indent)
  (format *trace-output* "(~A ~{~S~^ ~})~%" operator arguments)
  (bind ((result (bind ((*trace-function-call-level* (1+ *trace-function-call-level*)))
                   (apply operator arguments))))
    (write-indent)
    (format *trace-output* "=> ~S~%" result)
    result))

(def layered-method unwalk-form :in lexical-trace ((form free-application-form))
  `(trace-free-application-form ',(operator-of form) ,@(mapcar 'unwalk-form (arguments-of form))))

(def function trace-variable-reference-form (name value)
  (write-indent)
  (format *trace-output* "~A => ~S~%" name value)
  value)

(def layered-method unwalk-form :in lexical-trace ((form variable-reference-form))
  `(trace-variable-reference-form ',(name-of form) ,(call-next-method)))

(def function trace-setq-form (name value)
  (write-indent)
  (format *trace-output* "(setq ~A ~S) => ~S~%" name value value)
  value)

(def layered-method unwalk-form :in lexical-trace ((form setq-form))
  (bind ((name (name-of (variable-of form))))
    `(trace-setq-form ',(name-of (variable-of form)) (setq ,name ,(unwalk-form (value-of form))))))
