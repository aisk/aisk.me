import os
from datetime import datetime
from markdown import Markdown
from bottle import *
from bottle import jinja2_view as view
from bottle import jinja2_template as template

def format_meta(meta):
    return {
        'title': meta['title'][0].strip('"').strip('\''),
        'date': datetime.strptime(meta['date'][0], '%Y-%m-%d'),
    }

def get_content_intro(content):
    return content.split('<!--more-->')[0]

@route('/')
def index():
    posts = []
    md = Markdown(extensions = ['meta'])
    files = sorted(filter(lambda x: x.endswith('.md') ,os.listdir('posts')), reverse=True)
    for filename in files:
        f = open('posts/%s' %filename)
        s = f.read().decode('utf-8')
        md = Markdown(extensions = ['meta'])
        content = md.convert(s)
        post = format_meta(md.Meta)
        post['content'] = get_content_intro(content)
        post['filename'] = filename.split('.')[0]
        posts.append(post)

    return template('views/index', posts=posts)

@route('/post/<filename>')
def post(filename):
    f = open('posts/%s.md' %filename)
    s = f.read().decode('utf-8')
    md = Markdown(extensions = ['meta'])
    content = md.convert(s)
    post = format_meta(md.Meta)
    post['content'] = content
    post['filename'] = filename
    return template('views/post', post=post)

@route('/static/<filename>')
def static(filename):
    return static_file(filename, root='static')

application = app()

if __name__ == '__main__':
    run(host='localhost', port=8000, debug=True, reloader=True)
