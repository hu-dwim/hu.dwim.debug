;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.def)

(def package :hu.dwim.debug.test
  (:use :hu.dwim.common
        :hu.dwim.debug
        :hu.dwim.def
        :hu.dwim.defclass-star
        :hu.dwim.stefil
        :hu.dwim.syntax-sugar
        :hu.dwim.util)
  (:readtable-setup (setup-readtable/same-as-package :hu.dwim.debug)))
