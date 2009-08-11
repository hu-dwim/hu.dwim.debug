;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.new-project.documentation)

(def layered-method make-system-description ((system (eql (find-system :hu.dwim.new-project))))
  "This is a new project template that should be copied when starting a new one.

Steps to create a new project called 'foo':
 - copy the whole directory recursively into a directory called 'foo'
 - replace all occurances of 'new-project' in all files with 'foo'
 - rename files that include 'new-project' in their names to include 'foo'
 - take care about uppercase and camelcase letters
 - delete the '_darcs' directory, delete superfluous files, add new ones
 - the form (asdf:oos 'asdf:test-op :foo) should run the empty test suite without errors
 - run 'darcs init', 'darcs add', and 'darcs put' according to your needs")
