;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.debug)

;;;;;;
;;; Lexical trace

(def special-variable *trace-function-call-level* 0)
(def special-variable *trace-indentation-width* 2)

(def function write-trace-indent ()
  (write-spaces (* *trace-indentation-width*
                   *trace-function-call-level*)
                *trace-output*))

(def layer lexical-trace (hu.dwim.walker::ignore-undefined-references)
  ())

(def (macro e) with-lexical-trace ((&key &allow-other-keys) &body forms)
  (contextl:with-active-layers (lexical-trace)
    (unwalk-form (walk-form `(progn ,@forms)))))

(def function trace-application-form (operator operator-name arguments variable-names)
  (write-trace-indent)
  (format *trace-output* "(~A" operator-name)
  (pprint-logical-block (*trace-output* arguments)
    (iter (for argument :in arguments)
          (for variable-name = (pop variable-names))
          (write-string " " *trace-output*)
          (if variable-name
              (format *trace-output* "[~A: ~A]" variable-name argument)
              (format *trace-output* "~A" argument)))
    (write-string ")" *trace-output*)
    (terpri *trace-output*))
  (bind ((result-values (bind ((*trace-function-call-level* (1+ *trace-function-call-level*)))
                          (multiple-value-list (apply operator arguments)))))
    (write-trace-indent)
    (cond
      ((length= 0 result-values)
       (format *trace-output* "=> (values)~%"))
      ((length= 1 result-values)
       (format *trace-output* "=> ~S~%" (first result-values)))
      (t
       (format *trace-output* "=> (values ~{~S~^ ~})~%" result-values)))
    (values-list result-values)))

(def layered-method unwalk-form :in lexical-trace ((form application-form))
  (with-unique-names (arguments)
    `(bind ((,arguments (list ,@(mapcar 'unwalk-form (arguments-of form)))))
       (declare (dynamic-extent ,arguments))
       (trace-application-form ,(typecase form
                                  (lexical-application-form `(function ,(operator-of form)))
                                  (t `(quote ,(operator-of form))))
                               ',(operator-of form)
                               ,arguments
                               ,(bind ((variable-names (iter (for arg :in (arguments-of form))
                                                             (collect (typecase arg
                                                                        (variable-reference-form (name-of arg))
                                                                        (t nil))))))
                                      (if (every #'null variable-names)
                                          nil
                                          (list 'quote variable-names)))))))

(def function trace-setq-form (name value)
  (write-trace-indent)
  (format *trace-output* "(setq ~A ~S)~%=> ~S~%" name value value)
  value)

(def layered-method unwalk-form :in lexical-trace ((form setq-form))
  (bind ((name (name-of (variable-of form))))
    `(trace-setq-form ',(name-of (variable-of form)) (setq ,name ,(unwalk-form (value-of form))))))
