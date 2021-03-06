;;;; -*- mode:lisp; coding:utf-8 -*-
;;;; mode:mmm;
;;;;**************************************************************************
;;;;FILE:               tea.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;
;;;;    Implementation of the TEA
;;;;    Tiny Encryption Algorithm:
;;;;    http://web.archive.org/web/20070929150931/http://www.simonshepherd.supanet.com/tea.htm
;;;;
;;;;
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2006-03-20 <PJB> Created.
;;;;BUGS
;;;;TODO
;;;;    Implement the new variant.
;;;;LEGAL
;;;;    AGPL3
;;;;
;;;;    Copyright Pascal J. Bourguignon 2006 - 2016
;;;;
;;;;    This program is free software: you can redistribute it and/or modify
;;;;    it under the terms of the GNU Affero General Public License as published by
;;;;    the Free Software Foundation, either version 3 of the License, or
;;;;    (at your option) any later version.
;;;;
;;;;    This program is distributed in the hope that it will be useful,
;;;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;;    GNU Affero General Public License for more details.
;;;;
;;;;    You should have received a copy of the GNU Affero General Public License
;;;;    along with this program.  If not, see <http://www.gnu.org/licenses/>
;;;;**************************************************************************
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (copy-readtable nil)))
(defpackage "COM.INFORMATIMAGO.COMMON-LISP.CESARUM.TEA"
  (:use "COMMON-LISP")
  (:export "TEA-DECIPHER" "TEA-ENCIPHER")
  (:documentation
   "

This package imlements the TEA, Tiny Encryption Algorithm.

Tiny Encryption Algorithm:
<http://web.archive.org/web/20070929150931/http://www.simonshepherd.supanet.com/tea.htm>

Note:      This algorithm as weaknesses.
See also:  COM.INFORMATIMAGO.COMMON-LISP.CESARUM.RAIDEN

License:

    AGPL3

    Copyright Pascal J. Bourguignon 2006 - 2012

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.
    If not, see <http://www.gnu.org/licenses/>

"))
(in-package "COM.INFORMATIMAGO.COMMON-LISP.CESARUM.TEA")



(eval-when (:compile-toplevel :load-toplevel :execute) (defconstant +n+ 32))
(declaim (inline op))
(defun op (x a b sum) (logxor (+ (ash x 4) a) (+ x sum) (+ (ash x -5) b)))
(defmacro ciploop ((v w k y z a b c d (sum init-sum) delta) &body body)
  `(let ((,y  (aref ,v 0)) (,z  (aref ,v 1))
         (,sum  ,init-sum) (,delta  #x9e3779b9)
         (,a  (aref ,k 0)) (,b  (aref ,k 1))
         (,c  (aref ,k 2)) (,d  (aref ,k 3)))
     (loop :repeat +n+ :do (progn ,@body) :finally (setf (aref ,w 0) ,y (aref ,w 1) ,z))))
(defmacro c-incf (var expr) `(setf ,var (mod (+ ,var ,expr) #x100000000)))
(defmacro c-decf (var expr) `(setf ,var (mod (- ,var ,expr) #x100000000)))
(defun tea-encipher (v w k)
  "
DO:     Encipher the clear text vector V, storing the code in the
        vector W, using the key K.
V:      The clear text: a vector of two 32-bit words.
W:      The code: a vector of two 32-bit words.
K:      The key: a vector of four 32-bit words.
"
  (ciploop (v w k y z a b c d (sum 0) delta)
           (c-incf sum delta) (c-incf y (op z a b sum)) (c-incf z (op y c d sum))))
(defun tea-decipher (v w k)
  "
DO:     Decipher the code vector V, storing the decrypted clear text
        in the vector W, using the key K.
V:      The code: a vector of two 32-bit words.
W:      The clear text: a vector of two 32-bit words.
K:      The key: a vector of four 32-bit words.
"
  (ciploop (v w k y z a b c d (sum  #.(mod (* +n+ #x9e3779b9) #x100000000)) delta)
           (c-decf z (op y c d sum)) (c-decf y (op z a b sum)) (c-decf sum delta)))



#|  {%c-mode%}

void encipher(unsigned long *const v,unsigned long *const w,
              const unsigned long *const k)
{
    register unsigned long       y=v[0],z=v[1],sum=0,delta=0x9E3779B9,
    a=k[0],b=k[1],c=k[2],d=k[3],n=32;

    while(n-->0)
        {
            sum += delta;
            y += (z << 4)+a ^ z+sum ^ (z >> 5)+b;
            z += (y << 4)+c ^ y+sum ^ (y >> 5)+d;
        }

    w[0]=y; w[1]=z;
}

void decipher(unsigned long *const v,unsigned long *const w,
              const unsigned long *const k)
{
    register unsigned long       y=v[0],z=v[1],sum=0xC6EF3720,
    delta=0x9E3779B9,a=k[0],b=k[1],
    c=k[2],d=k[3],n=32;

    /* sum = delta<<5, in general sum = delta * n */

    while(n-->0)
        {
            z -= (y << 4)+c ^ y+sum ^ (y >> 5)+d;
            y -= (z << 4)+a ^ z+sum ^ (z >> 5)+b;
            sum -= delta;
        }

    w[0]=y; w[1]=z;
}

{%/c-mode%} |#



#| {%c-mode%}
/* ANSI C (New Variant) */

void encipher(const unsigned long *const v,unsigned long *const w,
              const unsigned long * const k)
{
    register unsigned long       y=v[0],z=v[1],sum=0,delta=0x9E3779B9,n=32;

    while(n-->0)
        {
            y += (z << 4 ^ z >> 5) + z ^ sum + k[sum&3];
            sum += delta;
            z += (y << 4 ^ y >> 5) + y ^ sum + k[sum>>11 & 3];
        }

    w[0]=y; w[1]=z;
}

void decipher(const unsigned long *const v,unsigned long *const w,
              const unsigned long * const k)
{
    register unsigned long       y=v[0],z=v[1],sum=0xC6EF3720,
    delta=0x9E3779B9,n=32;

    /* sum = delta<<5, in general sum = delta * n */

    while(n-->0)
        {
            z -= (y << 4 ^ y >> 5) + y ^ sum + k[sum>>11 & 3];
            sum -= delta;
            y -= (z << 4 ^ z >> 5) + z ^ sum + k[sum&3];
        }

    w[0]=y; w[1]=z;
}

{%/c-mode%} |#



(defun word (a b c d)
  (dpb a (byte 8 24) (dpb b (byte 8 16) (dpb c (byte 8 8) d))))

(defun read-words (bits what)
  (loop
     :for bytes = (progn (format t "Please enter ~D bits of ~A: "
                                 bits what)
                         (let ((buffer (read-line *standard-input* nil nil)))
                           (map 'vector (function char-code) buffer)))
     :while (and bytes (< (* 8 (length bytes)) bits))
     :finally (return
                (and bytes
                     (loop
                        :for i :from 0 :by 4 :below (truncate (+ 7 bits) 8)
                        :collect (word (aref bytes (+ i 0))
                                       (aref bytes (+ i 1))
                                       (aref bytes (+ i 2))
                                       (aref bytes (+ i 3))) into words
                        :finally (return (coerce words 'vector)))))))

(defun interactive-test ()
  (loop
     with code = (vector 0 0)
     with decr = (vector 0 0)
     for clear = (prog1 (read-words  64 "clear text") (terpri))
     for key   = (prog1 (read-words 128 "key") (terpri))
     while (and clear key)
     do (progn (tea-encipher clear code key)
               (format t "(encipher ~S ~S)~% -->      ~S~%" clear key code)
               (tea-decipher code decr key)
               (format t "(decipher ~S ~S)~% -->      ~S~%" code key decr)
               (unless (equalp clear decr) (format t "!!! ERROR !!!~%")))))

(defun test ()
  (with-input-from-string (*standard-input*
                           "Hello World!
John McCarthy invented LISP.
Big Unknown Secret.
Very very secret key. Forget it!
")
    (interactive-test)))

;;;; THE END ;;;;

