cl-huey is a Common framework that enables the creation of event-driven systems leveraging Kafka and (soon) REST services.  The name is inspired by this hoary aviation quote:

> Helicopters are a bunch of parts flying in relatively close formation, all rotating around a different axis.

To a first approximation, that’s an excellent description of a decoupled software architecture.  One of the most storied helicopters is the Bell UH-1B “Huey”, hence the name.

![Bell UH-1B "Huey"](huey.png)

# Installation
This repo can be installed with Quicklisp:

```
(ql:quickload :cl-huey)
```
[ TODO:  verify that the above works ]

# Configuration
cl-huey expects two special variables to be set:

```
(defvar *kafka-bootstrap-brokers* "localhost:9092")
(defvar *zookeeper-servers* "localhost:2181")
```
[ TODO:  validate use of special variables ]

# Message Formats
The current implementation of cl-huey uses a standard message formant consisting of headers and a payload.  All messages on Kafka are in JSON format and must include at least two elements:

* ```correlationid``` is a key that ties multiple related messages together.  It is used for partitioning Kafka topics.
* ```payload``` is the content of the message.  It can be any valid JSON.
[ TODO:  Add future to allow specification of message format ]

# Producing Messages
cl-huey provides a function to write messages to a Kafka topic.  ```cl-huey-test-producer.lisp``` demonstrates how to use it:

```
(ql:quickload :cl-huey)

(cl-huey:produce topic-name correlation-id payload)
```
[ TODO:  How to get command line arguments? ]

# Consuming Messages
To receive messages from Kafka, register a function that accepts a correlation ID and a payload (cl-huey converts the JSON received from Kafka into s-expressions):
```
(ql:quickload :cl-huey)

(defun on-message (id payload)
  (format t "Correlation ID:  ~s~&Payload:  ~s~&" id payload))

(cl-huey:register #'on-message
                  :topic topic-name +topic-name+
                  :consumer-group +consumer-group+
                  :error-topic +error-topic-name+)

(cl-huey:start)
```
[ TODO:  caps or not for directives? use format or write?  what returned? ]
If the registered message handling function cannot process the messasge, it must raise an error.  ```cl-huey:recoverable-message-error``` is used when the message should be retried.  ```cl-huey:unrecoverable-message-error``` is used when the message cannot be processed.

By default, unrecoverable messages are written to the topic ```cl-huey:*unrecoverable-message-topic*```.  This can be overridden with the ```:error-topic``` parameter of ```cl-huey:register```.

The ```cl-huey:register``` function can also accept a condition handler as an optional argument, ```:condition-handler```, for more complex error handling.
[ TODO:  verify use of keywords in this way and how to pass (:cl-huey:foo) ]

cl-huey supports registering additional functions while it is running.

# Docker
The cl-huey repository includes a Dockerfile that creates an image that runs cl-huey in SBCL.  To add your code to it:

[ TODO ]
