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
        post['post_id'] = filename.split('.')[0]
        posts.append(post)

    return template('views/index', posts=posts)

@route('/post/<post_id>.html')
def post(post_id):
    f = open('posts/%s.md' % post_id)
    s = f.read().decode('utf-8')
    md = Markdown(extensions = ['meta', 'codehilite(linenums=False,guess_lang=False)'])
    content = md.convert(s)
    post = format_meta(md.Meta)
    post['content'] = content
    post['post_id'] = post_id
    return template('views/post', post=post)

@route('/post/<post_id>')
def old_post(post_id):
    if '-' in post_id:
        t = datetime.strptime('-'.join(post_id.split('-')[:-1]), '%Y-%m-%d').strftime('%s')
        redirect('/post/' + t)

@route('/static/<filename>')
def static(filename):
    return static_file(filename, root='static')

application = app()

if __name__ == '__main__':
    run(host='localhost', port=8001, debug=True, reloader=True)
