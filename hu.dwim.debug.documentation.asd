;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(load-system :hu.dwim.asdf)

(in-package :hu.dwim.asdf)

(defsystem :hu.dwim.debug.documentation
  :class hu.dwim.documentation-system
  :depends-on (:hu.dwim.debug.test
               :hu.dwim.wui)
  :components ((:module "documentation"
                :components ((:file "debug" :depends-on ("package"))
                             (:file "package")))))
