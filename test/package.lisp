;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :cl-new-project)

(defpackage :cl-new-project-test
  (:use :common-lisp
        :metabang-bind
        :alexandria
        :iterate
        :stefil
        :cl-def
        :cl-syntax-sugar
        :cl-new-project)

  (:export #:test))
