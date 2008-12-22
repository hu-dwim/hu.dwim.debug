;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2008 by the authors.
;;;
;;; See LICENCE for details.

(cl:in-package :cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (asdf:oos 'asdf:load-op :cl-syntax-sugar))

(defpackage #:cl-new-project-system
  (:use :cl :asdf :cl-syntax-sugar)

  (:export #:*load-as-production-p*))

(in-package #:cl-new-project-system)

(defvar *load-as-production-p* t)

(defsystem :cl-new-project
  :version "0.1"
  :author ("Attila Lendvai <attila.lendvai@gmail.com>"
	   "Tamás Borbély <tomi.borbely@gmail.com>"
	   "Levente Mészáros <levente.meszaros@gmail.com>")
  :maintainer ("Attila Lendvai <attila.lendvai@gmail.com>"
               "Tamás Borbély <tomi.borbely@gmail.com>"
	       "Levente Mészáros <levente.meszaros@gmail.com>")
  :licence "BSD / Public domain"
  :default-component-class cl-source-file-with-readtable
  :class system-with-readtable
  :setup-readtable-function "cl-new-project::setup-readtable"
  :depends-on (:metabang-bind
               :alexandria
               :anaphora
               :iterate
               :defclass-star
               :closer-mop
               :cl-def
               :cl-syntax-sugar)
  :components
  ((:module "src"
            :components
            ((:file "package")
             (:file "duplicates" :depends-on ("package"))
             (:file "configuration" :depends-on ("duplicates"))
             (:file "new-project" :depends-on ("configuration"))))))

(defmethod perform ((op test-op) (system (eql (find-system :cl-new-project))))
  (operate 'load-op :cl-new-project-test)
  (in-package :cl-new-project-test)
  (eval (read-from-string "(progn
                             (stefil:funcall-test-with-feedback-message 'test))"))
  (values))

(defmethod operation-done-p ((op test-op) (system (eql (find-system :cl-new-project))))
  nil)
