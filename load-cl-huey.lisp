;;;; An example of how to load a cl-huey project.
;;;;
;;;; Mark:  Create a quicklisp distro

(in-package :common-lisp-user)

(ql:quickload :cl-rdkafka)
(ql:quickload :bt-semaphore)

(load (compile-file "package.lisp"))
(load (compile-file "cl-huey.lisp"))

;; Add cl-huey client code here
