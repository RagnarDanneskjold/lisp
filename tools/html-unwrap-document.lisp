#!/usr/local/bin/clisp -ansi -q -E utf-8
;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               html-unwrap-document
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;
;;;;    This script takes a HTML page containing a <div class="document"> entity
;;;;    and produces file containing only this element.
;;;;
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2015-10-20 <PJB> Created.
;;;;BUGS
;;;;LEGAL
;;;;    AGPL3
;;;;
;;;;    Copyright Pascal J. Bourguignon 2015 - 2016
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
;;;;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;;**************************************************************************
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (copy-readtable nil)))
(in-package "COMMON-LISP-USER")

(defmacro redirecting-stdout-to-stderr (&body body)
  (let ((verror  (gensym))
        (voutput (gensym)))
    `(let* ((,verror  nil)
            (,voutput (with-output-to-string (stream)
                        (let ((*standard-output* stream)
                              (*error-output*    stream)
                              (*trace-output*    stream))
                          (handler-case (progn ,@body)
                            (error (err) (setf ,verror err)))))))
       (when ,verror
         (terpri *error-output*)
         (princ ,voutput *error-output*)
         (terpri *error-output*)
         (princ ,verror *error-output*)
         (terpri *error-output*)
         (terpri *error-output*)
         #+(and clisp (not testing-script)) (ext:exit 1)))))

(redirecting-stdout-to-stderr
  (load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))

(redirecting-stdout-to-stderr
  (ql:quickload :com.informatimago.common-lisp))

(use-package "COM.INFORMATIMAGO.COMMON-LISP.HTML-PARSER.PARSE-HTML")
(use-package "COM.INFORMATIMAGO.COMMON-LISP.HTML-BASE.ML-SEXP")

(com.informatimago.common-lisp.cesarum.package:add-nickname
 "COM.INFORMATIMAGO.COMMON-LISP.HTML-GENERATOR.HTML" "<")


(defun unwrap (input output)
  (let* ((html        (child-tagged (parse-html-stream input) :html))
         (head        (child-tagged html :head))
         (title       (element-child (child-tagged head :title)))
         (author      (value-of-attribute-named (child-tagged-and-valued head :meta :name "author")      :content))
         (description (value-of-attribute-named (child-tagged-and-valued head :meta :name "description") :content))
         (keywords    (value-of-attribute-named (child-tagged-and-valued head :meta :name "keywords")    :content))
         (language    (or (value-of-attribute-named html :lang)
                          (value-of-attribute-named html :xml\:lang)
                          "en"))
         (class       "document")
         (document    (first (grandchildren-tagged-and-valued html :div :class class)))
         (id          (value-of-attribute-named document :id)))
    (write-line "<!-- THIS FILE IS GENERATED BY html-unwrap-document -->" output)
    (write-line "<!-- PLEASE DO NOT EDIT THIS FILE! -->" output)
    (unparse-html `(:div (:class       ,class
                          :id          ,id
                          :title       ,(or title "")
                          :author      ,(or author "")
                          :description ,(or description "")
                          :keywords    ,(or keywords "")
                          :language    ,(or language "en"))
                     ,@(element-children document))
                  output))
  (values))


(defun main (&optional arguments)
  (declare (ignore arguments))
  (unwrap *standard-input* *standard-output*))


#+(and clisp (not testing-script))
(progn
  (main ext:*args*)
  (ext:exit 0))

(pushnew :testing-script *features*)
;;;; THE END ;;;;
