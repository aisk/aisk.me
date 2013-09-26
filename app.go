package main

import (
    "log"
    "io/ioutil"
    "github.com/hoisie/web"
    "github.com/russross/blackfriday"
)

func index(ctx *web.Context) string {
    return "this is index"
}

func post(ctx *web.Context, post_id string) string {
    md, err := ioutil.ReadFile("posts/" + post_id)
    if err != nil {
        log.Print(err)
        ctx.NotFound("no such post")
    }
    html := blackfriday.MarkdownCommon(md)
    return string(html)
}

func main() {
    web.Get("/", index)
    web.Get(`/post/(.*)`, post)
    web.Run("localhost:4321")
}
