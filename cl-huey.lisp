;;;; CL-HUEY is a framework for communicating with Kafka and exposing
;;;; REST APIs to facilitate building event-driven, asynchronous
;;;; architectures.  CL-HUEY encapsulates the logic of connecting to
;;;; Kafka, consuming messages, and producing messages.  Clients register
;;;; callback functions to respond to incoming messages.

(in-package :cl-huey)

(defmacro while (test &body body)
  "A little syntactic sugar around DO from Paul Graham's On Lisp.
  TO DO:  allow return parameter"
  `(do () ((not ,test)) ,@body))

(defvar *conf* (kf:conf
		"bootstrap.servers" "localhost:9092"))

(defun make-producer (topic-name)
  "Return a function that can produce messages on the topic TOPIC-NAME."
  (let ((producer (make-instance 'kf:producer
		                 :conf *conf*
		                 :key-serde #'kf:object->bytes
		                 :value-serde #'kf:object->bytes)))
    (lambda (key message)
      (kf:produce producer topic-name message :key key)
      (kf:flush producer (* 2 1000)))))

(defun produce (topic-name key message)
  "Write MESSAGE on TOPIC-NAME with the partition KEY."
  (let ((producer (make-producer topic-name)))
    (funcall producer key message)))
;; Mark:  memoize producers instead of recreating each time
;; Mark:  catch conditions raised by producers and retry if possible
;; Mark:  make timing configurable
;; Mark:  possible to autoflush?

(defvar *consumer-conf* (kf:conf
		         "bootstrap.servers" "127.0.0.1:9092"
		         "group.id" (write-to-string (get-universal-time))
		         "enable.auto.commit" "false"
		         "auto.offset.reset" "earliest"
		         "offset.store.method" "broker"
	                 "enable.partition.eof" "false"))

(defconstant +poll-period+ 5000) ; milliseconds

(defun string-serde (message)
  "Utility function to convert a Kafka message to a string."
  (kf:bytes->object message 'string))

;; If CONDITION-HANDLER is provided, it is called if MESSAGE-HANDLER
;; returns an unrecoverable error.  If ERROR-TOPIC is provided, any error
;; is logged to that topic.  If neither are provided, errors are logged
;; to *standard-out*.
(defun consume (message-handler topic-name consumer-group
                &key (error-topic nil) (condition-handler nil))
  "Invokes MESSAGE-HANDLER when a message is received on TOPIC-NAME."
  (setf (gethash "group.id" *consumer-conf*) consumer-group)
  (let ((consumer (make-instance 'kf:consumer
				 :conf *consumer-conf*
                                 :key-serde string-serde
				 :value-serde string-serde))
        (topics (list topic-name)))
    (kf:subscribe consumer topics)
    (do ((message (kf:poll consumer +poll-period+)
                  (kf:poll consumer +poll-period+)))
        (nil)
      (when message
        (funcall message-handler (kf:key message) (kf:value message))))
    (kf:unsubscribe consumer)))

(defparameter *consumers* (list))

(defun register (message-handler topic-name consumer-group
                 &key (error-topic nil) (condition-handler nil))
  "Register a function to be called when a message is received on TOPIC-NAME."
  (push (lambda ()
          (consume message-handler topic-name consumer-group
                   :error-topic error-topic
                   :condition-handler condition-handler))
        *consumers*))

;; (defparameter *threads* (list))  ; Mark:  only for debugging

(defun run ()
  "Start each consumer in a separate thread and wait for them all to finish."
  (let ((threads (list)))
    (dolist (consumer *consumers*)
      (push (bt:make-thread (lambda ()
                              (funcall consumer)))
            threads))
    (dolist (thread threads)
      (bt:join-thread thread))))


;; (dolist (thread *threads*)
;;   (when (bt:thread-alive-p thread)
;;     (bt:destroy-thread thread)))
;; *threads*

