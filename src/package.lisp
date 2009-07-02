;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.new-project.system)

(defpackage :hu.dwim.new-project
  (:use :common-lisp
        :metabang-bind
        :alexandria
        :anaphora
        :iterate
        :defclass-star
        :closer-mop
        :cl-def
        :cl-syntax-sugar
        :hu.dwim.util
        :hu.dwim.new-project.system))
