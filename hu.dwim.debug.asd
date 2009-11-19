;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(load-system :hu.dwim.asdf)

(in-package :hu.dwim.asdf)

(defsystem :hu.dwim.debug
  :class hu.dwim.system
  :author ("Attila Lendvai <attila.lendvai@gmail.com>"
           "Levente Mészáros <levente.meszaros@gmail.com>"
           "Tamás Borbély <tomi.borbely@gmail.com>")
  :licence "BSD / Public domain"
  :description "Various debug utilities"
  :depends-on (:hu.dwim.common
               :hu.dwim.def
               :hu.dwim.defclass-star
               :hu.dwim.util
               :hu.dwim.walker)
  :components ((:module "source"
                :components ((:file "package")
                             (:file "path-to-root" :depends-on ("package"))
                             (:file "deadlock" :depends-on ("package"))))))
