;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :asdf)

(operate 'load-op :hu.dwim.asdf)

(defsystem :hu.dwim.new-project
  :class hu.dwim.system
  :author ("Attila Lendvai <attila.lendvai@gmail.com>"
	   "Levente Mészáros <levente.meszaros@gmail.com>"
	   "Tamás Borbély <tomi.borbely@gmail.com>")
  :licence "BSD / Public domain"
  :description "Template for hu.dwim.new-project"
  :depends-on (:hu.dwim.common-lisp
               :hu.dwim.def
               :hu.dwim.defclass-star
               :hu.dwim.syntax-sugar
               :hu.dwim.util
               :hu.dwim.walker)
  :components ((:module "source"
                :components ((:file "package")
                             (:file "configuration" :depends-on ("package"))
                             (:file "new-project" :depends-on ("configuration"))))))
