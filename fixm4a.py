#!/usr/bin/python

import os, sys, re
from mutagen.mp4 import MP4
import unicodedata

tags = {
    'album': '\xa9alb',
    'albumartist': 'aART',
    'albumartistsortorder': 'soaa',
    'albumsortorder': 'soal',
    'artist': '\xa9ART',
    'artistsortorder': 'soar',
    'bpm': 'tmpo',
    'comment': '\xa9cmt',
    'composer': '\xa9wrt',
    'composersortorder': 'soco',
    'copyright': 'cprt',
    'description': 'desc',
    'encodedby': '\xa9too',
    'genre': '\xa9gen',
    'grouping': '\xa9grp',
    'lyrics': '\xa9lyr',
    'partofcompilation': 'cpil',
    'partofgaplessalbum': 'pgap',
    'podcast': 'pcst',
    'podcastcategory': 'catg',
    'podcastepisodeguid': 'egid',
    'podcastkeywords': 'keyw',
    'podcasturl': 'purl',
    'purchasedate': 'purd',
    'showname': 'tvsh',
    'showsortorder': 'sosn',
    'title': '\xa9nam',
    'titlesortorder': 'sonm',
    'year': '\xa9day',
    }

def strip_accents(s):
   return ''.join((c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn'))

def visit(arg, dirname, names):
    #print dirname
    # Do some math/checking for disk number info
    parent = os.path.dirname(dirname)
    thisdir = os.path.basename(dirname)
    if 'Disk ' in thisdir:
        # Try to find other matching disk directories so we can determine a max number
        pass
    # Parse the files
    music = []
    for file in names:
        if file.startswith('.'):
            continue
        if file.endswith('.m4a'):
            # Save music files for later
            music.append(file)
        elif not os.path.isdir(os.path.join(dirname, file)):
            try:
                # Rename to remove UTF-8 characters so OSX can see them over NFS
                new = strip_accents(file.decode("utf-8"))
                new = new.replace(u'\u2019', "'") # smart apostrophe
                new = new.replace(u'\xb4', "'")   # some form of tilde
                new = new.replace(u'\xa1', '')    # upside down !
                new = new.replace(u'\xe6', 'ae')
                new = new.replace(u'\xdf', 'ss')  # eszet
                new = new.replace(u'\xa1', '')    # upside down !
                new = new.replace(u'\xbf', '')    # upside down ?
                new = new.replace(' MI ', ' Mi ') # typo
                new = re.sub('\(.+\)', '', new)
                new = re.sub('\[.+\]', '', new)
                new = new.replace('"', '')
                new = re.sub('\s*&\s*', ' and ', new)
                new = re.sub(r'[\\/:*?<>|]+', '-', new)
                new = re.sub(r' -(?! )', ' ', new)
                new = re.sub(r'\s+', ' ', new)
                new = re.sub(r'\W+;', ';', new)
                new = re.sub(r'^\W+|\W+$', '', new)
                new = re.sub(r'\W+(\.\w+)$', r'\1', new)
                new = new.replace(' #!@-', ' Shit')
                new = re.sub(r'^(\d+)\. ', r'\1 ', new)
                #print os.path.join(dirname, file)
                if file.decode("utf-8") != new.decode("utf-8"):
                    print '{0}\n  {1}'.format(file, new)
                    os.rename(os.path.join(dirname, file), os.path.join(dirname, new))
            except:
                print "FILE:  "+os.path.join(dirname, file)
                raise
    # Now parse the music files that we found
    for file in music:
        changed = False
        # Parse the m4a tag
        m = MP4(os.path.join(dirname, file))
        m[tags['encodedby']] = ['']
        try:
            (disk, numdisks) = m['disk'][0]
        except:
            disk = numdisks = 0
        try:
            (track, numtracks) = m['trkn'][0]
        except:
            track = numtracks = 0
        if numtracks == 0:
            numtracks = len(music)
            m['trkn'] = [(track,numtracks)]
            changed = True
        # Clean up the title
        #print m[tags['title']][0]
        title = m[tags['title']][0].strip()
        title = title.replace(',,,', ';')  # catch some oddities left over from fixing nero's tag issues
        title = re.sub(r'\s+', ' ', title)
        title = title.replace(' MI ', ' Mi ') # typo
        for term in ('the', 'by', 'of', 'a', 'an', 'and', 'but', 'or', 'for', 'nor', 'to', 'at', 'de', 'la', 'los', 'del', 'von', 'in', 'des', 'dem', 'der', 'di', 'with'):
            title = re.sub(
                r' {0} '.format(term),
                r' {0} '.format(term),
                title, flags=re.IGNORECASE
                )
            title = re.sub(
                r'([^a-z,]) {0} '.format(term),
                r'\1 {0} '.format(term.title()),
                title, flags=re.IGNORECASE
                )
            title = title.replace(' a Minor', ' A Minor')
        title = re.sub(r'(?:#|No\.?)(\d)', r'No. \1', title)
        title = title.replace(u'\u2019', "'") # smart apostrophe
        title = title.replace(u'\xb4', "'")   # some form of tilde
        title = title.replace(u'\xe6', 'ae')
        if title != m[tags['title']][0]:
            m[tags['title']] = [title]
            changed = True
        #print title
        # Other tags we may someday want to clean up
        #m[tags['artist']]
        #m[tags['albumartist']]
        #m[tags['partofcompilation']]
        # Save
        if changed:
            m.save()
        # Generate a new name
        new = u"{0} {1}".format(
            str(track).zfill(max(2,len(str(numtracks)))),
            title
            )
        new = new.replace(u'\xe6', 'ae')
        new = new.replace(u'\xdf', 'ss')  # eszet
        new = new.replace(u'\xa1', '')    # upside down !
        new = new.replace(u'\xbf', '')    # upside down ?
        new = strip_accents(new)
        new = re.sub('\(.+\)', '', new)
        new = re.sub('\[.+\]', '', new)
        new = new.replace('"', '')
        new = re.sub('\s*&\s*', ' and ', new)
        new = re.sub(r'[\\/:*?<>|]+', '-', new)
        new = re.sub(r' -(?! )', ' ', new)
        new = re.sub(r'\s+', ' ', new)
        new = re.sub(r'\W+;', ';', new)
        new = re.sub(r'^\W+|\W+$', '', new)
        new = new.replace(' #!@-', ' Shit')
        new = new.strip()+'.m4a'
        try:
            if file.decode("utf-8") != new.decode("utf-8"):
                print '{0}\n  {1}'.format(file, new)
                os.rename(os.path.join(dirname, file), os.path.join(dirname, new))
        except:
            print "FILE:  "+os.path.join(dirname, file)
            raise

if 1 in sys.argv:
    path = os.path.abspath(sys.argv[1])
else:
    path = os.path.abspath('.')
print path

os.path.walk(path, visit, None)
