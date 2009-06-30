;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.new-project)

;;; These definitions need to be available by the time we are reading the other files, therefore
;;; they are in a standalone file.

(def function transform-function-definer-options (options)
  (if hu.dwim.new-project.system:*load-as-production-p*
      options
      (remove-from-plist options :inline :optimize)))

(def function setup-readtable ()
  (enable-sharp-boolean-syntax)
  (enable-readtime-wrapper-syntax)
  (enable-lambda-with-bang-args-syntax :start-character #\[ :end-character #\]))

#+#.(cl:when (cl:find-package "SWANK") '(:and))
(register-readtable-for-swank
 '("HU.DWIM.NEW-PROJECT" "HU.DWIM.NEW-PROJECT.TEST") 'setup-readtable)
