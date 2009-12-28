;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(load-system :hu.dwim.asdf)

(in-package :hu.dwim.asdf)

(defsystem :hu.dwim.debug
  :class hu.dwim.system
  :description "Various debug utilities such as lexical tracing, etc."
  :depends-on (:hu.dwim.common
               :hu.dwim.def
               :hu.dwim.defclass-star
               :hu.dwim.util
               :hu.dwim.walker)
  :components ((:module "source"
                :components ((:file "deadlock" :depends-on ("package"))
                             (:file "package")
                             (:file "path-to-root" :depends-on ("package"))
                             (:file "util" :depends-on ("package"))))))
