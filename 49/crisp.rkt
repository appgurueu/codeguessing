#lang racket
(define (proceed-parse in) (read-char in) (parse in))
(define (assert cond) (when (not cond) (raise "assertion failed")))
(define (expect in c) (assert (eqv? c (read-char in))))
(define (read-atom in)
  (let [(c (peek-char in))]
    (if (or (char-whitespace? c) (char=? #\) c)) '()
        (begin (read-char in) (cons c (read-atom in))))))
(define (skip-line in)
  (if (eqv? #\newline (read-char in)) (void) (skip-line in)))
(define (parse in)
  (let [(c (peek-char in))]
    (cond
      [(or (eof-object? c) (char=? #\) c)) '()]
      [(char=? #\# c) (begin (skip-line in) (parse in))]
      [(char-whitespace? c) (proceed-parse in)]
      [(char=? #\( c) (let [(r (proceed-parse in))]
                        (begin (expect in #\)) (cons r (parse in))))]
      [else (cons (let [(s (list->string (read-atom in)))]
                    (or (string->number s) (list 'name s)))
                  (parse in))])))
(define (fnify f)
  (lambda (args ctx) (f (eval-args args ctx))))
(define (thunk args ctx)
  (fnify (lambda (_) (last (eval-args args ctx)))))
(define (my-lambda args ctx)
  (letrec [(param (begin (assert (eqv? 'name (caar args))) (cadar args)))
           (body (cdr args))
           (f (lambda (xs)
                (if (null? xs) f
                    (let* [(new-ctx (hash-set ctx param (car xs)))
                           (res (last (eval-args body new-ctx)))]
                      (if (null? (cdr xs)) res
                          (res (cdr xs) ctx))))))]
    (fnify f)))
(define (my-quote args _) args)
(define (fnify-n n f)
  (letrec [(l (lambda (args ctx)     
                (if (null? args) l
                    (let [(arg (eval (car args) ctx))]
                      (if (= n 1)
                          (if (null? (cdr args))
                              (f arg)
                              ((f arg) (eval-args (cdr args) ctx)))
                          ((fnify-n (- n 1) (curry f arg)) (cdr args) ctx)))
                    )))] l))
(define my-t (fnify-n 2 (lambda (x y) x)))
(define my-f (fnify-n 2 (lambda (x y) y)))
(define (my-<= n m)
  (cond
    [(eq? n m) my-t]
    [(and (number? n) (number? m)) (if (<= n m) my-t my-f)]
    [(null? n) (if (pair? m) my-t my-f)]
    [(and (pair? n) (pair? m))
     (cond
       [(not (my-<= (car n) (car m))) my-f]
       [(not (my-<= (car m) (car n))) my-t]
       [else (my-<= (cdr n) (cdr m))])]
    [else my-f]))
(define (d args)
  (display args)
  (newline))
(define (my-macro margs mctx)
  (lambda (args ctx)
    (eval (last (eval-args margs (hash-set ctx "..." args))) ctx)))
(define predefs
  (hash
   ;; builtins (mostly inherited from racket)
   "d" (fnify d)
   "ib" (fnify (lambda (_) (char->integer (read-char))))
   "ob" (fnify-n 1 (lambda (c) (write-char (integer->char c))))
   "do" (fnify last)
   "car" (fnify-n 1 car)
   "cdr" (fnify-n 1 cdr)
   "cons" (fnify-n 2 cons)
   "list" (fnify identity)
   "-" (fnify-n 1 -)
   "+" (fnify-n 2 +)
   "*" (fnify-n 2 *)
   "<=" (fnify-n 2 my-<=)
   "t" my-t
   "f" my-f
   ;; special forms
   "\\\\" thunk
   "\\" my-lambda
   "'" my-quote
   "$" my-macro)) 
(define (eval-args args ctx)
  (map (lambda (arg) (eval arg ctx)) args))
(define (eval expr ctx)
  (if (pair? expr)
      (let [(f (car expr)) (args (cdr expr))]
        (if (eqv? f 'name) (hash-ref ctx (car args))
            ((eval f ctx) args ctx)))
      expr))
(define (get-file-name)
  (command-line
   #:program "crisp"
   #:args (filename)
   filename))
(define (maybe-display v)
  (when (not (eq? v (void))) (display v)))
(maybe-display (eval
                (cons (list 'name "do")
                      (call-with-input-file (get-file-name) parse))
                predefs))