;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(load-system :hu.dwim.asdf)

(in-package :hu.dwim.asdf)

(defsystem :hu.dwim.debug.test
  :class hu.dwim.test-system
  :depends-on (:hu.dwim.debug
               :hu.dwim.stefil+hu.dwim.def+swank)
  :components ((:module "test"
                :components ((:file "package")
                             (:file "suite" :depends-on ("package"))
                             ;; it's SBCL only, and SBCL now has deadlock detection (:file "deadlock" :depends-on ("suite"))
                             (:file "path-to-root" :depends-on ("suite"))))))
