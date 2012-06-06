#lang racket
(require racket/date
         racket/pretty
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
        (id article-id email author website content date-create deleted)
        #:mutable)

(define (vector->article vec)
  (article [vector-ref vec 0]
           [vector-ref vec 1]
           [vector-ref vec 2]
           (seconds->date [vector-ref vec 3])
           [vector-ref vec 4]))

(define (vector->comment vec)
  (comment [vector-ref vec 0]
           [vector-ref vec 1]
           [vector-ref vec 2]
           [vector-ref vec 3]
           [vector-ref vec 4]
           [vector-ref vec 5]
           (seconds->date [vector-ref vec 6])
           [vector-ref vec 7]))

(define (get-article id)
  (let* ([conn (get-connection)]
         [ret (query-row 
                conn
                "select * from article where id = $1"
                id)])
    (vector->article ret)))
;(get-article 1)

(define (get-articles start limit)
  (let* ([conn (get-connection)]
         [rets (query-rows 
                 conn
                 (string-append
                   "select * from article where deleted = 0 "
                   "order by date_create desc limit $1, $2;")
                 start
                 limit)])
    (map vector->article rets)))
;(get-articles 0 10)

(define (get-comments article-id start limit)
  (let* ([conn (get-connection)]
         [rets (query-rows 
                 conn
                 (string-append
                   "select * from comment where deleted= 0 "
                   "and article_id = $1 "
                   "order by date_create limit $2, $3;")
                 article-id start limit)])
    (map vector->comment rets)))
;(get-comments 0 100)

(define (add-comment article-id email author website content)
  (let ([conn (get-connection)])
    (query-exec 
      conn 
      (string-append 
        "insert into comment "
        "(article_id,email,author,website,content) "
        "values ($1,$2,$3,$4,$5)")
      article-id email author website content))
  )

;; Url dispatch
(define-values (url-dispatch site-url)
  (dispatch-rules
    [("") root-view]
    [("article" (integer-arg)) article-view]))

;; Renders
(define (render-base content)
  `(html (head
           (title "XXX")
           (link ((rel "stylesheet")
                  (href "/style.css")
                  (type "text/css"))))
         (body
           (div ((id "bg"))
                (div ([id "pagewrap"])
                     (div ([id "header"])
                          (div ([id "site-logo"])
                               (a ([href "/"])
                                  "XXXXXXXXX"))
                          (div ([id "site-description"])
                               "Yet another aisk's blog"))
                     (div ([id "layout"] [class "clearfix sidebar1"])
                          ,content
                          (div ([id "sidebar"])))
                     (div ([id "footer"])))))))


(define (render-article a-article)
  (let* ([a-title (article-title a-article)]
         [a-content (article-content a-article)]
         [a-date-create (article-date-create a-article)]
         [a-url (string-append
                  "/article/"
                  (number->string (article-id a-article)))])
    `(div ([class "post clearfix"])
          (div ([class "post-content"])
               (p ((class "post-date"))
                  (span ((class "day"))
                        ,(number->string (date-day a-date-create)))
                  (span ((class "month")) "May")
                  (span ((class "year"))
                        ,(number->string (date-year a-date-create))))
               (h1 ((class "post-title"))
                   (a ([href ,a-url]) ,a-title))
               (p ,a-content)))))

(define (render-comment a-comment)
  `(li ([class "comment"])
       (p ([class "comment-author"])
          (img ([src "/images/head_54.png"]
                [class "avatar"]
                [width "54"]
                [height "54"]))
          (cite (a ([href ,(comment-website a-comment)]
                    [rel "external nofollow"]
                    [class "url"])
                   ,(comment-author a-comment)))
          (br)
          (small ([class "comment-time"])
                 (strong "Jan 17, 2011")
                 " @ 07:27:52"))
       (div ([class "commententry"])
            (p ,(comment-content a-comment))
            )
       ))

(define (render-comments comments)
  `(div ([id "comments"] [class "commentwrap"])
        (h4 ([class "comment-title"]) "Comments")
        (ol ([class "commentlist"])
            ,@(map render-comment comments))
        ,(render-commentform)
        ))

(define (render-commentform)
  `(div ([id "respond"])
        (h3 ([id "reply-title"]) "Leave a Reply")
        (form ([action ""]
               [method "post"]
               [id "commentform"])
              (p ([class "comment-form-author"])
                 (input ([id "author"]
                         [name "author"]
                         [type "text"]
                         [size "30"]
                         [required ""])
                        (label ([for "author"]) "Your Name"))
                 (span "*"))
              (p ([class "comment-form-email"])
                 (input ([id "email"]
                         [name "email"]
                         [type "email"]
                         [size "30"]
                         [maxlength "20"]
                         [required ""])
                        (label ([for "email"]) "Your Email"))
                 (span "*"))
              (p ([class "comment-form-url"])
                 (input ([id "website"]
                         [name "website"]
                         [type "url"]
                         [size "30"])
                        (label ([for "url"]) "Your Website")))
              (p ([class "comment-form-comment"])
                 (textarea ([id "comment"]
                            [name "comment"]
                            [cols "45"]
                            [rows "8"]
                            [required ""]) ""))
              (p ([class "form-submit"])
                 (input ([id "submit"]
                         [name "submit"]
                         [type "submit"]
                         [value "Post Comment"]))))))

;; View functions
(define (root-view req)
  (let* ([articles (get-articles 0 100)])
    (response/xexpr
      (render-base `(div ([id "content"] [class "list-post"])
                         ,@(map render-article articles))))))

(define (article-view req article-id)
  (cond
    [(equal? (request-method req) #"GET")
     (let ([a-article (get-article article-id)]
           [comments (get-comments article-id 0 100)])
       (response/xexpr
         (render-base `(div ([id "content"] [class "list-post"])
                            ,(render-article a-article)
                            ,(render-comments comments)))))]
    [(equal? (request-method req) #"POST")
     (if (can-save-comment? (request-bindings req))
       (save-comment article-id (request-bindings req))
       (display "xxxxxxxxxxxxxxxx!"))
     (redirect-to (url->string (request-uri req)))]))


(define (can-save-comment? bindings)
  (and (exists-binding? 'author bindings)
       (exists-binding? 'email bindings)
       (exists-binding? 'website bindings)
       (exists-binding? 'comment bindings)))

(define (save-comment article-id bindings)
  (add-comment
    article-id
    (extract-binding/single 'email bindings)
    (extract-binding/single 'author bindings)
    (extract-binding/single 'website bindings)
    (extract-binding/single 'comment bindings)))

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
               #:extra-files-paths (list
                                     (build-path cur-path "static"))
               #:launch-browser? #f)

