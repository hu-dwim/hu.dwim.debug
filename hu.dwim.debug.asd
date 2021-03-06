;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(defsystem :hu.dwim.debug
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.system"
  :description "Various debug utilities such as lexical tracing, etc."
  :depends-on (:hu.dwim.common
               :hu.dwim.def+swank
               :hu.dwim.defclass-star
               :hu.dwim.util
               :hu.dwim.walker
               :swank)
  :components ((:module "source"
                :components (
                             ;; disable this because it's bitrotten, sbcl-only, and sbcl now has deadlock detection
                             ;; (:file "deadlock" :depends-on ("package"))
                             (:file "package")
                             (:file "trace" :depends-on ("package"))
                             (:file "util" :depends-on ("package"))))))
