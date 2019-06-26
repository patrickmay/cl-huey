(defpackage :com.vroom.cl-huey
  (:nicknames :cl-huey)
  (:use :common-lisp
        :cl-rdkafka)
  (:shadow #:produce)
  (:export #:make-producer
           #:produce
           #:register
           #:run))
