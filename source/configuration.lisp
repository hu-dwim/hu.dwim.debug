;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.new-project)

;;;;;;
;;; These definitions need to be available by the time we are reading other files, therefore they are in a standalone file.

(def function transform-function-definer-options (options)
  (if *load-as-production?*
      options
      (remove-from-plist options :inline :optimize)))

(def function setup-readtable ()
  (enable-sharp-boolean-syntax)
  (enable-readtime-wrapper-syntax)
  (enable-lambda-with-bang-args-syntax))

#+#.(cl:when (cl:find-package "SWANK") '(:and))
(register-readtable-for-swank
 '(:hu.dwim.new-project :hu.dwim.new-project.test) 'setup-readtable)
