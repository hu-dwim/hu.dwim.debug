;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.debug.test)

;;;;;;
;;; Test

(def function make-deadlocking-threads ()
  (let ((spinlock (sb-thread::make-spinlock :name "spinlock"))
        (mutex (sb-thread::make-mutex :name "mutex")))
    (sb-thread:make-thread
     (lambda ()
       (sb-thread::with-mutex (mutex)
         (sleep 1)
         (sb-thread::with-spinlock (spinlock))))
     :name "Deadlocking thread 1")
    (sb-thread:make-thread
     (lambda ()
       (sb-thread::with-spinlock (spinlock)
         (sb-thread::sleep 1)
         (sb-thread::with-mutex (mutex))))
     :name "Deadlocking thread 2")))

(def function make-random-deadlocking-threads (&optional (count 10))
  (let ((mutexes
         (loop
            repeat count
            for i :from 0
            collect (sb-thread::make-mutex :name (format nil "lock ~A" i)))))
    (loop
       repeat count
       for i :from 0
       do (sb-thread:make-thread
           (lambda ()
             (loop
                (sb-thread::with-recursive-lock ((elt mutexes (random count)))
                  (sb-thread::with-recursive-lock ((elt mutexes (random count)))
                    (sb-thread::with-recursive-lock ((elt mutexes (random count))))))))
           :name (format nil "Deadlocking ~A" i)))))
