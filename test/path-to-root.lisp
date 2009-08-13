;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.debug.test)

;;;;;;
;;; Test

(def class path-test ()
  ((foo :initarg :foo :accessor foo-of)
   (name :initarg :name :accessor name-of)))

(def method print-object ((instance path-test) stream)
  (print-unreadable-object (instance stream :type t :identity t)
    (let ((*standard-output* stream))
      (princ (name-of instance) stream))))

(def function test-1 ()
  (path-to-root 'o))

(let ((o (list 1 2 3 (cons (make-instance 'path-test :name "foo")
                           (make-instance 'path-test :name "bar")))))
  (def function test-2 ()
    (path-to-root (cdr (elt o 3)))))

(let ((o (make-instance 'path-test
                        :name "foo"
                        :foo (make-instance 'path-test
                                            :name "bar"))))
  (def function test-3 ()
    (path-to-root (foo-of o))))

(let ((o (make-instance 'path-test
                        :name "foo"
                        :foo (make-instance 'path-test
                                            :name "bar"
                                            :foo (make-instance 'path-test
                                                                :name "baz")))))
  (def function test-4 ()
    (path-to-root (foo-of (foo-of o)))))

(let ((o (make-instance 'path-test
                        :name "foo"
                        :foo (make-instance 'path-test
                                            :name "bar"
                                            :foo (list 1 2 3 4
                                                       (make-instance 'path-test
                                                                      :name "baz"))))))
  (def function test-5 ()
    (path-to-root (elt (foo-of (foo-of o)) 4))))

(let ((hash-table (make-hash-table))
      (foo (make-instance 'path-test :name "foo")))
  (setf (gethash 'o hash-table) foo)
  (def function test-6 ()
    (path-to-root (gethash 'o hash-table))))

(def function emit-lambda (a)
  (lambda ()
    a))

(let* ((o (emit-lambda (make-instance 'path-test :name "foo"))))
  (def function test-7 ()
    (path-to-root (funcall o))))
