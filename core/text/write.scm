(define (hash-table->plist table)
  (hash-table-fold table (lambda (key val plist) (cons key (cons val plist)))
                   '()))

(define (symbol-first-char-needs-quoting? char)
  (not (char-alphabetic? char)))

(define (symbol-subsequent-char-needs-quoting? char)
  (not (or (char-alphabetic? char)
           (char-numeric? char)
           (case char ((#\- #\_) #t) (else #f)))))

(define (symbol-name-needs-quoting? name)
  (let ((in (open-input-string name)))
    (let ((first-char (read-char in)))
      (or (eof-object? first-char)
          (symbol-first-char-needs-quoting? first-char)
          (let loop ()
            (let ((char (read-char in)))
              (cond ((eof-object? char) #f)
                    ((symbol-subsequent-char-needs-quoting? char) #t)
                    (else (loop)))))))))

(define (write-quoted-stringlike obj delimiter)
  (write-char delimiter)
  (let ((in (open-input-string obj)))
    (let loop ()
      (let ((char (read-char in)))
        (unless (eof-object? char)
          (case char ((#\\ #\" #\|) (write-char #\\)))
          (write-char char)
          (loop)))))
  (write-char delimiter))

(define (write-elements elts)
  (unless (null? elts)
    (write-nested (car elts))
    (let loop ((elts (cdr elts)))
      (unless (null? elts)
        (write-char #\space)
        (write-nested (car elts))
        (loop (cdr elts))))))

(define (write-nested obj)
  (cond ((boolean? obj)
         (write-char #\#)
         (write-char (if obj #\t #\f)))
        ((string? obj)
         (write-quoted-stringlike obj #\"))
        ((symbol? obj)
         (let ((name (symbol->string obj)))
           (if (symbol-name-needs-quoting? name)
               (write-quoted-stringlike name #\|)
               (write-string name))))
        ((and (integer? obj) (exact? obj))
         (write-string (number->string obj 10)))
        ((list? obj)
         (write-char #\()
         (write-elements obj)
         (write-char #\)))
        ((hash-table? obj)
         (write-char #\#)
         (write-char #\{)
         (write-elements (hash-table->plist obj))
         (write-char #\}))
        (else (error "Don't know how to write that object as core text"))))

(define (core-text-write obj)
  (write-nested obj)
  (newline))
