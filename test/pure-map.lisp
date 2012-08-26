#+xcvb (module (:depends-on ("package")))

(in-package :lisp-pure-datastructure-test)

(declaim (optimize (speed 1) (debug 3) (space 3)))

(defsuite* (test-pure-map
            :in test-suite
            :documentation "Testing pure functional maps"))

(defmethod interface-test ((i <map>))
  (simple-linear-map-test i)
  (harder-linear-map-test i)
  (multilinear-map-test i))

(defmethod simple-linear-map-test ((i <map>))
  (declare (optimize (speed 1) (debug 3) (space 3)))
  ;;; TODO: test each and every function in the API
  (X 'interface-test *package* i)
  (X 'empty)
  (is (null (map-alist i (empty i))))
  (is (empty-p i (alist-map* i ())))

  (X 'lookup)
  (is (equal "12"
             (lookup
              i
              (alist-map*
               i '((57 . "57") (10 . "10") (12 . "12")))
              12)))
  (loop :for (k . v) :in *al-1* :with m = (alist-map* i *al-1*) :do
    (is (eq v (lookup i m k))))

  (X 'alist-map*-and-back)
  (is (equal-alist *alist-10-latin*
                   (map-alist i (alist-map* i *alist-10-latin*))))
  (is (equal-alist *alist-10-latin*
                   (map-alist i (alist-map* i *alist-10-latin*))))
  (is (equal-alist *alist-100-decimal*
                   (map-alist i (alist-map* i *al-1*))))
  (is (equal-alist *al-5*
                   (map-alist
                    i (check-invariant
                       i (join i (alist-map* i *al-2*)
                               (alist-map* i *al-3*))))))

  (X 'insert)
  (is (equal '((0)) (map-alist i (insert i (empty i) 0 nil))))
  (is (equal-alist
       '((1 . "1") (2 . "2") (3 . "3"))
       (map-alist i (insert i (alist-map* i '((1 . "1") (3 . "3"))) 2 "2"))))

  (X 'insert-and-join)
  (is (equal-alist
       '((0 . "0") (1 . "1") (2 . "2"))
       (map-alist i (insert i (join i (alist-map* i '((1 . "1")))
                                    (alist-map* i'((2 . "2")))) 0 "0"))))

  (X 'insert-and-size)
  (is (= 101 (size i (insert i (alist-map* i *al-1*) 101 "101"))))

  (X 'drop)
  (multiple-value-bind (m k v) (drop i (empty i) 0)
    (is (empty-p i m))
    (is (null k))
    (is (null v)))
  (multiple-value-bind (r d b)
      (drop i (alist-map* i '((1 . "1") (2 . "2"))) 1)
    (is (equal '(((2 . "2")) "1" t)
               (list (map-alist i r) d b))))
  (multiple-value-bind (r d b)
      (drop i (alist-map* i *al-1*) 42)
    (is (equal d "42")
        (is (equal b t)))
    (is (= (size i r) 99)))

  (X 'drop-and-size)
  (multiple-value-bind (r d b)
      (drop i (alist-map* i *alist-100-decimal*) 57)
    (is (= (size i r) 99))
    (is (equal d "57"))
    (is (eql b t)))

  (X 'first-key-value)
  (is (equal '(nil nil nil)
             (multiple-value-list (first-key-value i (empty i)))))
  (multiple-value-bind (k v b)
      (first-key-value i (alist-map* i *al-2*))
    (multiple-value-bind (vv bb) (lookup <alist> *al-2* k)
      (is (equal b t))
      (is (equal bb t))
      (is (equal v vv))))
  (multiple-value-bind (k v b)
      (first-key-value i (alist-map* i *alist-100-latin*))
    (multiple-value-bind (vv bb) (lookup <alist> *alist-100-latin* k)
      (is (equal b t))
      (is (equal bb t))
      (is (equal v vv))))

  (X 'decons)
  (multiple-value-bind (b m k v) (decons i (empty i))
    (is (empty-p i m))
    (is (equal '(nil nil nil) (list b k v))))
  (multiple-value-bind (b m k v) (decons i (alist-map* i *alist-10-latin*))
    (is (eq b t))
    (is (equal (list v t)
               (multiple-value-list (lookup <alist> *alist-10-latin* k))))
    (is (equal (list nil nil)
               (multiple-value-list (lookup i m k))))
    (is (= (size i m) 9)))

  (X 'fold-left)
  (is (eql nil (fold-left i (empty i) (constantly t) nil)))
  (is (eql t (fold-left i (empty i) (constantly t) t)))
  (is (equal-alist
       '((2 . "2") (1 . "1") (20 . "20") (30 . "30"))
       (map-alist i
                  (fold-left
                   i (alist-map* i (make-alist 2))
                   #'(lambda (m k v) (insert i m k v))
                   (alist-map* i '((20 . "20") (30 . "30")))))))

  (X 'fold-left-and-size)
  (is (= 100
         (size i
               (fold-left i (alist-map* i *alist-100-decimal*)
                          #'(lambda (m k v) (insert i m k v))
                          (alist-map* i *alist-100-latin*)))))

  (X 'fold-right)
  (is (eql nil (fold-right i (empty i) (constantly t) nil)))
  (is (eql t (fold-right i (empty i) (constantly t) t)))
  (is (equal-alist
       '((1 . "1") (2 . "2") (20 . "20") (30 . "30"))
       (map-alist i
                  (fold-right
                   i (alist-map* i (make-alist 2))
                   #'(lambda (k v m) (insert i m k v))
                   (alist-map* i '((20 . "20") (30 . "30")))))))

  (X 'for-each)
  (is (eql nil (while-collecting (c)
                 (for-each i (empty i) #'(lambda (k v) (c (cons k v)))))))
  (is (equal-alist
       *alist-10-latin*
       (while-collecting (c)
         (with-output-to-string (o)
           (for-each i (alist-map* i *alist-10-latin*)
                     #'(lambda (k v) (c (cons k v))))))))
  (is (= 1129 (length (with-output-to-string (o)
                        (for-each i (alist-map* i *alist-100-english*)
                                  #'(lambda (x y)
                                      (format o "~A~A" x y)))))))

  (X 'join)
  (is (empty-p i (join i (empty i) (empty i))))
  (is (equal-alist '((1 . "1") (2 . "2") (5 . "5") (6 . "6"))
                   (map-alist
                    i
                    (join i
                          (alist-map* i '((1 . "1") (2 . "2")))
                          (alist-map* i '((5 . "5") (6 . "6")))))))
  (X 'join-and-size)
  (is (= 100 (size i
                   (join i
                         (alist-map* i *alist-10-latin*)
                         (alist-map* i *alist-100-latin*)))))

  (X 'divide-and-join)
  (multiple-value-bind (m1 m2) (divide i (empty i))
    (is (empty-p i m1))
    (is (empty-p i m2)))
  (multiple-value-bind (x y)
      (divide i (alist-map* i *alist-10-latin*))
    (is (equal-alist *alist-10-latin*
                     (append (map-alist i x) (map-alist i y)))))

  (X 'divide-and-size)
  (multiple-value-bind (x y)
      (divide i (alist-map* i '()))
    (is (empty-p i x))
    (is (empty-p i y)))
  (multiple-value-bind (x y)
      (divide i (alist-map* i '((1 . "1"))))
    (is (empty-p i x))
    (is (= 1 (size i y))))
  (multiple-value-bind (x y)
      (divide i (alist-map* i *alist-100-latin*))
    (let ((sx (size i x)) (sy (size i y)))
      (is (plusp sx))
      (is (plusp sy))
      (is (= 100 (+ sx sy)))))

  (X 'size)
  (is (= 0 (size i (empty i))))
  (is (= 100 (size i (alist-map* i *alist-100-decimal*))))
  (is (= 99 (size i (nth-value 1 (decons i (alist-map* i *alist-100-decimal*))))))

  (X 'update-key)
  ;; TODO: add more tests
  (is (empty-p i (update-key i (empty i) 0 (constantly nil))))

  (X 'map/2)
  ;; TODO: add more tests
  (is (empty-p i (map/2 i (constantly t) (empty i) (empty i))))

  (X 'convert)
  (is (null (convert <alist> i (empty i))))
  (is (equal-alist *alist-10-latin*
                   (convert <alist> i (convert i <alist> *alist-10-latin*))))

  (X 'iterator)
  (is (equal-alist *alist-10-latin*
                   (flow i <alist> (convert i <alist> *alist-10-latin*) nil)))
  t)

(defmethod harder-linear-map-test ((i <map>))
  ;; (X 'join/list)
  ;; TODO: add tests

  (X 'divide/list)
  ;; TODO: add more tests
  (is (null (divide/list i (empty i)))))

(defmethod multilinear-map-test ((i <map>))
  (let ((m (alist-map* i *alist-10-latin*)))
    (equal-alist (map-alist i m) (map-alist i (join i m m)))))

(defmethod simple-linear-map-test :after ((i <number-map>))
  (let* ((a1 (make-alist 1000 "~@R"))
         (a2 (shuffle-list a1))
         (m1 (convert i <alist> a1))
         (m2 (convert i <alist> a2)))
    (check-invariant i m1)
    (check-invariant i m2)
    (is (= 10 (pure::node-height m1)))
    (is (<= 10 (pure::node-height m2) 15))
    (is (= 1000 (size i m1)))
    (is (= 1000 (size i m2)))))

(defparameter <denm> (<encoded-key-map>
                      :base-interface <number-map>
                      :key-encoder #'(lambda (dk) (* dk 2))
                      :key-decoder #'(lambda (ek) (/ ek 2))))

(deftest test-pure-map-interfaces ()
  (dolist (i (list <alist> <number-map> <hash-table> <fmim> <denm>))
    (interface-test i)))

(defparameter <lsnm> (<linearized-map> stateful:<number-map>))

(deftest test-linearized-map-interfaces ()
  (simple-linear-map-test <lsnm>)
  (harder-linear-map-test <lsnm>))
