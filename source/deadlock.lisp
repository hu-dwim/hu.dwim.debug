;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.debug)

;;;;;;
;;; Duplicates

(def function linearize-array (array)
  (make-array (array-total-size array) 
              :displaced-to array
              :element-type (array-element-type array)))

(def function copy-matrix (matrix)
  (let ((storage (copy-seq (linearize-array matrix))))
    (make-array (array-dimensions matrix) :displaced-to storage)))

(def function matrix-times-matrix (mat1 mat2)
  "Multiplies two matrices together"
  (if (= (array-dimension mat1 1)
	 (array-dimension mat2 0))
      (let ((result (make-array (list (array-dimension mat1 0)
				      (array-dimension mat2 1)))))
	(dotimes (row (array-dimension result 0))
	  (dotimes (column (array-dimension result 1))
	    (let ((terms 0))
	      (dotimes (middle (array-dimension mat1 1))
		(setf terms (+ terms (* (or (aref mat1 row middle) 0) 
					(or (aref mat2 middle column) 0)))))
	      (setf (aref result row column) terms))))
	(return-from matrix-times-matrix result))
      (progn
	(format t "~&Illegal matrix multiplication: 
Matrix sizes ~a x ~a and ~a x ~a don't match."
		(array-dimension mat1 0)
		(array-dimension mat1 1)
		(array-dimension mat2 0)
		(array-dimension mat2 1))
	(return-from matrix-times-matrix nil))))

;;;;;;
;;; Collecting locks

(def function map-locks-in-backtrace (thunk)
  (sb-debug::map-backtrace
   (lambda (frame)
     (multiple-value-bind (function args)
         (sb-debug::frame-call frame)
       (when (member function '(sb-thread::call-with-mutex
                                sb-thread::call-with-spinlock
                                sb-thread::call-with-system-spinlock
                                sb-thread::call-with-system-mutex
                                sb-thread::call-with-recursive-lock
                                sb-thread::call-with-recursive-spinlock
                                sb-thread::call-with-recursive-system-spinlock))
         (funcall thunk (second args)))))))

(def function collect-locks-in-backtrace ()
  (let ((result (list)))
    (map-locks-in-backtrace
     (lambda (mutex)
       (push mutex result)))
    ;; result is intentionally reversed to be in acquiration order
    (values-list result)))

(def function call-in-thread (thunk thread)
  (let ((semaphore (sb-thread:make-semaphore :name "call-in-thread"))
        (result-values))
    (sb-thread:interrupt-thread
     thread
     (lambda ()
       (setf result-values (multiple-value-list (funcall thunk)))
       (sb-thread:signal-semaphore semaphore)))
    (sb-thread:wait-on-semaphore semaphore)
    (values-list result-values)))

(def function call-in-all-threads (thunk)
  (let ((result (list)))
    (dolist (thread (sb-thread:list-all-threads))
      (call-in-thread (lambda ()
                        (let ((locks (multiple-value-list (funcall thunk))))
                          (push (list* thread locks) result)))
                      thread))
    result))

(def function collect-all-locks-in-all-backtraces ()
  (delete-if
   (lambda (el)
     ;; drop threads without a lock
     (<= (length el) 1))
   (call-in-all-threads
    (lambda ()
      (collect-locks-in-backtrace)))))

;; TODO delme, sbcl's backtrace knows all this except the toplevel protection
(def (function e) print-backtrace (stream)
  (handler-case
    (progn
      (format stream "*** Backtrace of ~S:" (or (sb-thread:thread-name sb-thread:*current-thread*)
                                                sb-thread:*current-thread*))
      (let ((*print-right-margin* most-positive-fixnum))
        (sb-debug::map-backtrace
         (lambda (frame)
           (handler-case
               (sb-debug::print-frame-call frame stream :number t :verbosity 1)
             (serious-condition (error)
               ;; please note that the usage of ~S is important to avoid calling any custom PRINT-OBJECT
               (format stream "<<< Error while printing frame: ~S >>>" error))))
         :start 14
         :count 500)))
    (serious-condition (error)
      ;; please note that the usage of ~S is important to avoid calling any custom PRINT-OBJECT
      (format stream "<<< Error while printing backtrace: ~S >>>" error))))

(def function dump-backtrace-of-all-threads (&optional (file-name "/tmp/sbcl-thread-backtraces.txt"))
  (with-open-file (stream file-name
                          :direction :output :element-type 'character
                          :if-exists :supersede)
    (call-in-all-threads
     (lambda ()
       (print-backtrace stream)
       (terpri stream)
       (terpri stream))))
  file-name)

;;;;;;
;;; Deadlock detection

(def function find-cycles (adjacency-matrix)
  (let ((rank (array-dimension adjacency-matrix 0)))
    (loop
       repeat rank
       for matrix = (copy-matrix adjacency-matrix) :then (matrix-times-matrix matrix adjacency-matrix)
       do (loop
             for i :from 0 :below rank
             unless (zerop (aref matrix i i))
             collect i :into nodes
             finally (when nodes
                       (return-from find-cycles nodes))))))

(def function lock-owner (lock)
  (etypecase lock
    (sb-thread::spinlock (sb-thread::spinlock-value lock))
    (sb-thread::mutex (sb-thread::mutex-%owner lock))))

(def function lock-name (lock)
  (etypecase lock
    (sb-thread::spinlock (sb-thread::spinlock-name lock))
    (sb-thread::mutex (sb-thread::mutex-name lock))))

(def function find-deadlock (&optional (thread-acquired-locks-list (collect-all-locks-in-all-backtraces)))
  (labels ((thread-of (thread-acquired-locks)
             (first thread-acquired-locks))
           (last-lock-of (thread-acquired-locks)
             (first (last thread-acquired-locks)))
           (thread-position (thread)
             (position thread thread-acquired-locks-list :key #'thread-of)))
    (let* ((rank (length thread-acquired-locks-list))
           (matrix (make-array (list rank rank))))
      (loop
         for index :from 0
         for thread-acquired-locks :in thread-acquired-locks-list
         for thread = (thread-of thread-acquired-locks)
         for last-lock = (last-lock-of thread-acquired-locks)
         for last-lock-owner = (lock-owner last-lock)
         when (and last-lock-owner
                   (not (eq thread last-lock-owner)))
         do (let ((helder-index (thread-position last-lock-owner)))
              (setf (aref matrix index helder-index) 1)))
      (let ((cycles (find-cycles matrix)))
        (loop
           while cycles
           for i :from 0
           do (format t "cycle ~A~%" i) 
           collect (loop
                      with first-index = (pop cycles)
                      for index = first-index :then (let ((next-index
                                                           (thread-position
                                                            (lock-owner
                                                             (last-lock-of
                                                              (elt thread-acquired-locks-list index))))))
                                                      (setf cycles (delete next-index cycles))
                                                      next-index)
                      for first-iteration-p = t :then nil
                      until (and (not first-iteration-p)
                                 (= index first-index))
                      collect (let ((thread (thread-of (elt thread-acquired-locks-list index))))
                                (unless first-iteration-p
                                  (format t " held by~%"))
                                (format t "the thread ~S" (sb-thread::thread-name thread))
                                thread)
                      collect (let* ((lock (last-lock-of (elt thread-acquired-locks-list index)))
                                     (lock-name (lock-name lock)))
                                (format t " is waiting for ")
                                (if lock-name
                                    (format t "~S" lock-name)
                                    (format t "<unnamed> ~A" (class-name (class-of lock))))
                                lock)
                      finally (format t " held by the first thread~%")))))))
