#!/usr/bin/env petite --quiet --script

(load "~/minlog/init.scm")
(set! COMMENT-FLAG #f)
(add-pvar-name "A" "B" "C" "D" (make-arity))
(set-goal (pf (for-each string-append (cdr (command-line)))))
(set! COMMENT-FLAG #t)
(prop)
(if (equal? (proof-to-context (current-proof)) '())
  (cdp)
  (exit)
  )
(exit)
