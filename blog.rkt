#lang racket
(require racket/date
         web-server/servlet
         web-server/servlet-env
         web-server/dispatch
         web-server/templates
         (planet ryanc/db:1:5)) ; Fuck the db module

;; Utils
(define cur-path (find-system-path 'orig-dir))

;; Models
(define (get-connection)
  (sqlite3-connect
   #:database (string-append
               (path->string cur-path)
               "rktblog.db")))

(struct article
  (id title content date-create deleted)
  #:mutable)

(struct comment
  (id article-id content date-create deleted)
  #:mutable)

(define (vector->article vec)
  (article [vector-ref vec 0]
           [vector-ref vec 1]
           [vector-ref vec 2]
           [vector-ref vec 3]
           [vector-ref vec 4]))

(define (vector->comment vec)
  (comment [vector-ref vec 0]
           [vector-ref vec 1]
           [vector-ref vec 2]
           [vector-ref vec 3]
           [vector-ref vec 4]))

(define (get-article id)
  (let* ([conn (get-connection)]
         [ret (query-row conn
                         "select * from article where id = $1"
                         id)])
    (vector->article ret)))
;(get-article 1)

(define (get-articles start limit)
  (let* ([conn (get-connection)]
         [rets (query-rows conn
                (string-append
                 "select * from article where deleted = 0 "
                 "order by date_create limit $1, $2;")
                start
                limit)])
    (map vector->article rets)))
;(get-articles 0 10)

(define (get-comments start limit)
  (let* ([conn (get-connection)]
         [rets (query-rows conn
                           (string-append
                            "select * from comment where deleted=0 "
                            "order by date_create limit $1, $2;")
                           start limit)])
    (map vector->comment rets)))
;(get-comments 0 100)

;; Url dispatch
(define-values (url-dispatch site-url)
  (dispatch-rules
   [("") root-view]
   [("article" (integer-arg)) post-view]))

;; Templates
(define (render-base content)
  `(html (head
          (title "XXX")
          (link ((rel "stylesheet")
                 (href "http://themify.me/demo/themes/koi/wp-content/themes/koi/style.css")
                 (type "text/css"))))
         (body
          (div ((id "bg"))
               (div ((id "pagewrap"))
                    (div ((id "header"))
                         (div ((id "site-logo"))
                              (a ((href "/"))
                                 "XXXXXXXXX"))
                         (div ((id "site-description"))
                              "Yet another aisk's blog"))
                    (div ((id "layout") (class "clearfix sidebar1"))
                         ,content
                         (div ((id "sidebar"))))
                    (div ((id "footer"))))))))


(define (render-article a-article)
  (let* ([a-title (article-title a-article)]
         [a-content (article-content a-article)])
    `(div ((id "content") (class "list-post"))
          (div ((class "post clearfix"))
               (div ((class "post-content"))
                    (p ((class "post-date"))
                       (span ((class "day")) "18")
                       (span ((class "month")) "May")
                       (span ((class "year")) "2011"))
                    (h1 ((class "post-title"))
                        ,a-title)
                    (p ,a-content))))))


  
;; View functions
(define (root-view req)
  (response/xexpr
   (render-base `())))

(define (post-view req post-id)
  (let ([a-article (get-article post-id)])
    (response/xexpr
     (render-base (render-article a-article)))))

;; Main
(define (start req)
  (display (string-append
			(date->string (current-date))
			": "
			(url->string (request-uri req)) 
			"\n"))
  (url-dispatch req))

(serve/servlet start
               #:port 8080
               #:servlet-regexp #rx""
               #:launch-browser? #f)

