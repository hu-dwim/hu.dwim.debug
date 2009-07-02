;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (asdf:find-system :cl-new-project)
  (asdf:oos 'asdf:load-op :cl-syntax-sugar))

(in-package :hu.dwim.new-project.system)

(setf *load-as-production-p* nil)

(defsystem :cl-new-project-test
  :description "Tests for cl-new-project."
  :default-component-class cl-source-file-with-readtable
  :class system-with-readtable
  :setup-readtable-function "hu.dwim.new-project::setup-readtable"
  :depends-on (:stefil
               :cl-new-project)
  :components
  ((:module :test
    :components ((:file "package")
                 (:file "suite" :depends-on ("package"))
                 (:file "new-project" :depends-on ("suite"))))))

(defmethod perform :after ((o load-op) (c (eql (find-system :cl-new-project-test))))
  (in-package :hu.dwim.new-project.test)
  (pushnew :debug *features*)
  (declaim (optimize (debug 3)))
  (warn "Pushed :debug in *features* and (declaim (optimize (debug 3))) was issued to help later C-c C-c'ing"))

(defmethod operation-done-p ((op test-op) (system (eql (find-system :cl-new-project-test))))
  nil)
