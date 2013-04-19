import os
from pprint import pprint as pp

def process(name):
    f = open('posts/' + name)
    metas = {}
    for i in range(8):
        meta = f.readline()
        meta = meta.split(': ')
        if len(meta) == 1: continue
        metas[meta[0]] = meta[1]
    new_f = open('new_posts/' + name, 'a')
    new_f.write('Title: %s' %metas['title'])
    new_f.write('Date: %s\n' %metas['date'])
    new_f.write(f.read())
    f.close()
    new_f.close()

if __name__ == '__main__':
    for name in os.listdir('posts'):
        process(name)
