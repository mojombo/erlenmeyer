(module erlenmeyer mzscheme
  (require (lib "foreign.ss")) (unsafe!)
  (provide read-next-packet 
           bind-erlang-ports
           fd->input-port
           fd->output-port)

;  We'll start with the standard ports
  (define erlang-input-port (current-input-port))
  (define erlang-output-port (current-output-port))
 
  (define (bind-erlang-ports)
    (set! erlang-input-port  (fd->input-port 3 'erlang-in))
    (set! erlang-output-port (fd->output-port 4 'erlang-out)))
  
; The all-important fd->input port code thanks to Matthew Flatt
  (define (fd->input-port fd name)
    (scheme_make_fd_input_port fd name 0 0))

  (define (fd->output-port fd name)
    (scheme_make_fd_output_port fd name 0 0 0))

  (define scheme_make_fd_input_port
    (get-ffi-obj "scheme_make_fd_input_port" #f
                 (_fun _int _scheme _int _int -> _scheme)))

  (define scheme_make_fd_output_port
    (get-ffi-obj "scheme_make_fd_output_port"
                  #f
                  (_fun _int _scheme _int _int _int -> _scheme)))
  
; Data conversion functions
  (define ERL_VERSION       131)
  (define ERL_SMALL_INT     97)
  (define ERL_INT           98)
  (define ERL_SMALL_BIGNUM  110)
  (define ERL_LARGE_BIGNUM  111)
  (define ERL_FLOAT         99)
  (define ERL_ATOM          100)
  (define ERL_REF           101)
  (define ERL_NEW_REF       114)
  (define ERL_PORT          102)
  (define ERL_PID           103)
  (define ERL_SMALL_TUPLE   104)
  (define ERL_LARGE_TUPLE   105)
  (define ERL_NIL           106)
  (define ERL_STRING        107)
  (define ERL_LIST          108)
  (define ERL_BIN           109)
  (define ERL_FUN           117)
  (define ERL_NEW_FUN       112)

(define (read-size-record)
  (let ((size (read-bytes 4 erlang-input-port)))
    (fprintf (current-error-port) "RAW SIZE READ AS ~s~n" size)
    (integer-bytes->integer size #f)))

(define (read-sized-group)
  (let* ((size (read-size-record))
         (magic (read-magic-number))
        (packet-data (read-bytes (- size 1) erlang-input-port)))
    (fprintf (current-error-port) "READ PACKET (~s)(~s): ~s~n" size magic packet-data)
    packet-data))

(define (read-magic-number)
  (read-bytes 1 erlang-input-port))

(define (read-next-packet)
  ;(unless (read-magic-number) (raise `bad-magic))
  (display "Going to read group...\n")
  (read-sized-group)
  (display "Read group!\n"))
  ;(let ((r (read-bytes 5 erlang-input-port)))
  ;  (if (eof-object? r) (begin (fprintf (current-error-port) "EOF! EXITING") (exit)))
  ;    (fprintf (current-error-port) "~s~n" (read-bytes 5 erlang-input-port))))
) ; End module