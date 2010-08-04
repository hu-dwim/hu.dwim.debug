;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.debug)

;;;;;;
;;; Reference map

(def special-variable *reference-map* nil)

(def function default-root-object-p (object &optional (count nil))
  (or (symbolp object)
      (and count
           (zerop count))))

(def function default-ignore-reference-p (referencing-object referenced-object)
  ;; ignore nil and t which we do not want to track down with path-to-root
  (or (eq referenced-object nil)
      (eq referenced-object t)
      ;; KLUDGE: ignore hash-table internal structure because the hash-table itself will be included separately
      (and (typep referencing-object 'simple-vector)
           (> (length referencing-object) 0)
           (let ((first-element (aref referencing-object 0)))
             (and (typep first-element 'hash-table)
                  (eq referencing-object (sb-impl::hash-table-table first-element)))))
      ;; ignore other kinds of referenced objects which we do not want to track down with path-to-root
      (typep referenced-object
             '(or number character string symbol package
               condition restart built-in-class stream
               standard-class structure-class
               sb-pcl:standard-effective-slot-definition
               sb-pcl:standard-direct-slot-definition))))

(def (function e) build-reference-map (&key (ignore-reference-predicate #'default-ignore-reference-p) (initial-size (floor 1E+6)))
  ;; free some memory
  ;; TODO: depending on swank is not enough
  (eval (read-from-string "(swank:clear-repl-results)"))
  (setf *reference-map* nil)
  (format *debug-io* "Before initial gc~%")
  (force-output *debug-io*)
  (sb-ext:gc :full t)
  (format *debug-io* "Before collecting reference map~%")
  (force-output *debug-io*)
  ;; collect map
  (prog1
      (sb-vm::without-gcing
        (let ((reference-map (make-hash-table :size initial-size :test 'eq))
              (cons-set (make-hash-table :size initial-size :test 'eq)))
          (sb-vm::map-allocated-objects
           (lambda (object type size)
             (declare (ignore size))
             (labels ((cons* (element-1 element-2)
                        (let ((cons-object (cons element-1 element-2)))
                          (setf (gethash cons-object cons-set) t)
                          cons-object))
                      (push-reference (referenced-object)
                        (unless (funcall ignore-reference-predicate object referenced-object)
                          (let ((value (gethash referenced-object reference-map)))
                            (setf (gethash referenced-object reference-map)
                                  (if value
                                      (unless (member object value)
                                        (cons* object value))
                                      (cons* object nil)))))))
               (unless (eq object reference-map)
                 (etypecase object
                   (cons
                    (unless (gethash object cons-set)
                      (push-reference (car object))
                      (push-reference (cdr object))))
                   (sb-pcl::slot-object
                    (push-reference (class-of object))
                    ;; slots are recorded in the instance vector
                    (push-reference (sb-pcl::std-instance-slots object)))
                   (function
                    (cond ((= type sb-vm:simple-fun-header-widetag)
                           (push-reference (sb-kernel:fun-code-header object)))
                          ((= type sb-vm:closure-header-widetag)
                           (push-reference (sb-kernel:%closure-fun object))
                           (iter (for i :from 0 :below (1- (sb-kernel:get-closure-length object)))
                                 (push-reference (sb-kernel:%closure-index-ref object i))))
                          (t (error "Unknown function type ~A" object))))
                   (sb-vm::code-component
                    (let ((length (sb-vm::get-header-data object)))
                      (do ((i sb-vm::code-constants-offset (1+ i)))
                          ((= i length))
                        (push-reference (sb-vm::code-header-ref object i)))))
                   (hash-table
                    (unless (or (eq object reference-map)
                                (eq object cons-set))
                      (iter (for (key value) :in-hashtable object)
                            (push-reference key)
                            (push-reference value))))
                   (vector
                    (unless (or (eq object (sb-impl::hash-table-table reference-map))
                                (eq object (sb-impl::hash-table-table cons-set)))
                      (dotimes (i (length object))
                        (push-reference (aref object i)))))
                   (array
                    (dotimes (i (apply '* (array-dimensions object)))
                      (push-reference (row-major-aref object i))))
                   (symbol
                    (push-reference (symbol-name object))
                    (push-reference (symbol-package object))
                    (push-reference (symbol-plist object))
                    (when (boundp object)
                      (push-reference (symbol-value object)))
                    (when (fboundp object)
                      (push-reference (symbol-function object))))
                   (number)
                   (sb-ext:weak-pointer
                    (push-reference (sb-ext:weak-pointer-value object)))
                   (sb-kernel::fdefn
                    (push-reference ()))
                   ((or sb-vm::instance  sb-kernel::random-class sb-sys:system-area-pointer))))))
           :dynamic t)
          (setf *reference-map* reference-map)))
    ;; free some memory in internal structures
    (format *debug-io* "Before final gc~%")
    (force-output *debug-io*)
    (sb-ext:gc :full t)))

(def (function e) build-reference-map-type-breakdown ()
  (let ((type-breakdown-map (make-hash-table :test 'eq)))
    (iter (for (referenced-object referencing-objects) :in-hashtable *reference-map*)
          (incf (gethash (class-of referenced-object) type-breakdown-map 0)
                (length referencing-objects)))
    type-breakdown-map))

(def (function e) referencing-objects-of (object)
  (gethash object *reference-map*))

(def (function e) count-references (object)
  (length (referencing-objects-of object)))

(def (function e) find-referenced-object (predicate &key (key #'identity))
  (iter (for (referenced-object referencing-objects) :in-hashtable *reference-map*)
        (when (funcall predicate (funcall key referenced-object))
          (return referenced-object))))

(def (function e) collect-referenced-objects (predicate)
  (iter (for (referenced-object referencing-objects) :in-hashtable *reference-map*)
        (when (funcall predicate referenced-object)
          (collect referenced-object))))

(def (function e) collect-root-objects (&optional (root-object-predicate #'default-root-object-p))
  (iter (for (referenced-object referencing-objects) :in-hashtable *reference-map*)
        (when (funcall root-object-predicate referenced-object (length referencing-objects))
          (collect referenced-object))))

;;;;;;
;;; Path to root

(def special-variable *visited-objects*)

(def special-variable *to-be-visited-objects*)

(def special-variable *referenced-object-indices*)

(def special-variable *referencing-levels*)

(def class reference-path ()
  ((elements :initarg :elements :accessor elements-of)))

(def method print-object ((instance reference-path) stream)
  (let ((*print-right-margin* most-positive-fixnum))
    (write-string "[" stream)
    (iter (for element :in (elements-of instance))
          (for previous-element :previous element)
          (unless (and (typep previous-element 'standard-object)
                       (eq element
                           (sb-pcl::std-instance-slots previous-element)))
            (unless (first-time-p)
              (write-string " -> " stream))
            (princ element stream)))
    (write-string "]" stream)))

(def (function e) path-to-root (object &key (initial-capacity 1000) (maximum-capacity 100000)
                                       (maximum-iteration 10000) (maximum-level 100) (maximum-result 100)
                                       (root-object-predicate #'default-root-object-p))
  (prog1
      (let ((*reference-map* *reference-map*)
            (*visited-objects* (make-hash-table :size initial-capacity :test 'eq))
            (*to-be-visited-objects* (make-array initial-capacity :adjustable t :fill-pointer 0))
            (*referenced-object-indices* (make-array initial-capacity :adjustable t :fill-pointer 0))
            (*referencing-levels* (make-array initial-capacity :adjustable t :fill-pointer 0)))
        (unless *reference-map*
          (build-reference-map))
        (flet ((push-to-be-visited-object (referencing-object referenced-object-index referencing-level)
                 (unless (gethash referencing-object *visited-objects*)
                   (vector-push-extend referencing-object *to-be-visited-objects*)
                   (vector-push-extend referenced-object-index *referenced-object-indices*)
                   (vector-push-extend referencing-level *referencing-levels*))))
          (push-to-be-visited-object object -1 0)
          (iter (for visit-index :upfrom 0)
                (while (< visit-index (length *to-be-visited-objects*)))
                (for visited-object = (aref *to-be-visited-objects* visit-index))
                (for referencing-level = (1+ (aref *referencing-levels* visit-index)))
                (when (> (array-total-size *to-be-visited-objects*) maximum-capacity)
                  (warn "Maximum capacity reached ~A" maximum-capacity)
                  (return result))
                (when (> visit-index maximum-iteration)
                  (warn "Maximum iteration reached ~A" maximum-iteration)
                  (return result))
                (if (> referencing-level maximum-level)
                    (warn "Skipping ~A at level ~A" (class-name (class-of visited-object)) referencing-level)
                    (let ((count 0))
                      (format *debug-io* "Level ~A, type ~A" referencing-level (class-name (class-of visited-object)))
                      (dolist (referencing-object (referencing-objects-of visited-object))
                        (push-to-be-visited-object referencing-object visit-index referencing-level)
                        (incf count))
                      (format *debug-io* ", reference count ~A~%" count)
                      (when (funcall root-object-predicate visited-object count)
                        (collect (labels ((collect-path (index)
                                            (unless (= index -1)
                                              (cons (aref *to-be-visited-objects* index)
                                                    (collect-path (aref *referenced-object-indices* index))))))
                                   (make-instance 'reference-path :elements (collect-path visit-index)))
                          :into result))
                      (setf (gethash visited-object *visited-objects*) t)))
                (when (> (length result) maximum-result)
                  (warn "Maximum result reached ~A" maximum-result)
                  (return result))
                (finally (return result)))))
    (sb-ext:gc :full t)))
