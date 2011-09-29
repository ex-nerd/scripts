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

def fix_title(s):
    new = s.strip()
    new = new.replace(' MI ', ' Mi ') # typo
    for term in ('the', 'by', 'of', 'a', 'an', 'and', 'but', 'or', 'for', 'in', 'nor', 'to', 'at', 'de', 'la', 'los', 'del', 'von', 'in', 'des', 'dem', 'der', 'di', 'with'):
        new = re.sub(
            r' {0} '.format(term),
            r' {0} '.format(term),
            new, flags=re.IGNORECASE
            )
        new = re.sub(
            r'([^a-z,]) {0} '.format(term),
            r'\1 {0} '.format(term.title()),
            new, flags=re.IGNORECASE
            )
    new = new.replace(' a Minor', ' A Minor')
    new = re.sub(r'(?:#|No\.?)(\d)', r'No. \1', new)
    new = new.replace(u'\u2019', "'") # smart apostrophe
    new = new.replace(u'\xb4', "'")   # some form of tilde meant to be apostrophe
    new = re.sub(r'\s+', ' ', new)
    new = re.sub(r'^the', 'The', new)
    #new = new[0].upper() + new[1:]
    return new.strip()

def fix_name(s):
    new = strip_accents(s)
    new = new.replace(u'\xa1', '')    # upside down !
    new = new.replace(u'\xe6', 'ae')
    new = new.replace(u'\xdf', 'ss')  # eszet
    new = new.replace(u'\xa1', '')    # upside down !
    new = new.replace(u'\xbf', '')    # upside down ?
    new = fix_title(new)
    new = new.replace('"', '')
    new = re.sub('\s*&\s*', ' and ', new)
    new = re.sub(r'[\\/:*?<>|]+', '-', new) # characters unfriendly to win/mac
    new = re.sub(r' -(?! )', ' ', new)
    new = re.sub(r'\s+', ' ', new)
    new = re.sub(r'\W+;', ';', new)
    new = re.sub(r'^[^\w\(]+|[^\w\)]+$', '', new)
    new = re.sub(r'\W+(\.\w+)$', r'\1', new)
    new = new.replace(' #!@-', ' Shit') # for one specific song
    new = re.sub(r'^(\d+)\. ', r'\1 ', new)
    return new

def fix_name_full(new):
    new = re.sub('\(.+\)', '', new)
    new = re.sub('\[.+\]', '', new)
    new = fix_name(new)
    return new

def load_mp4(dir, file, _disk = None):
    m = MP4(os.path.join(dir, file))
    changed = False
    # Don't want this taking up space
    if m.get(tags['encodedby'], []) != ['']:
        m[tags['encodedby']] = ['']
        changed = True
    # Adjust num tracks
    try:
        (track, numtracks) = m['trkn'][0]
    except:
        track = numtracks = 0
    if numtracks == 0:
        numtracks = len(music)
        m['trkn'] = [(track,numtracks)]
        changed = True
    # Try to detect disk numbers
    try:
        (disk, numdisks) = m['disk'][0]
    except:
        disk = numdisks = 0
    if _disk and disk != _disk:
        print "  Disknum mismatch on {0}".format(file)
        sys.exit(1)
    # Clean up the title
    #print m[tags['title']][0]
    title = m[tags['title']][0].strip()
    title = title.replace(',,,', ';')  # catch some oddities left over from fixing nero's tag issues
    title = fix_title(title)
    if title != m[tags['title']][0]:
        m[tags['title']] = [title]
        changed = True
    # Generate a new name
    new = fix_name_full(u"{0} {1}.m4a".format(
        str(track).zfill(max(2,len(str(numtracks)))),
        title
        ))
    if disk > 0 and numdisks > 1:
        new = "{0}-{1}".format(
            str(disk).zfill(len(str(numdisks))),
            new)
    try:
        if file.decode("utf-8") == new.decode("utf-8"):
            new = None
    except:
        print "  FILE:  "+os.path.join(dirname, file)
        raise
    # Return
    return (m, new, changed)

def visit(arg, dirname, names):
    print dirname
    # Do some math/checking for disk number info
    #parent = os.path.dirname(dirname)
    thisdir = os.path.basename(dirname)
    m = re.match(r'Disk ([ABC]|\d+)', thisdir)
    if m:
        disknum = m.group(1)
        if disknum == 'A':
            disknum = 1
        elif disknum == 'B':
            disknum = 2
        elif disknum == 'C':
            disknum = 3
    # Parse the files
    music   = []
    artists = {}
    is_comp = False
    artist  = None
    for file in names:
        if file.startswith('.'):
            continue
        if file.endswith('.m4a'):
            # Load some info about this mp4 for later comparison
            (mp4, name, changed) = load_mp4(dirname, file)
            # Setup for compilation detection
            if not is_comp:
                if artist:
                    if artist != mp4[tags['artist']][0]:
                        is_comp = True
                else:
                    artist = mp4[tags['artist']][0]
                    if artist.lower() == 'various':
                        is_comp = True
                    else:
                        a_artist = mp4.get(tags['albumartist'], [None])[0]
                        if a_artist and a_artist != artist:
                            is_comp = True
            # Save music files for later
            music.append({
                'file':    file,
                'name':    name,
                'mp4':     mp4,
                'changed': changed,
                })
        else:
            try:
                # Clean up the name
                if os.path.isdir(os.path.join(dirname, file)):
                    new = fix_name(file.decode("utf-8"))
                else:
                    new = fix_name_full(file.decode("utf-8"))
                #print os.path.join(dirname, file)
                if file.decode("utf-8") != new.decode("utf-8"):
                    print '  {0}\n    {1}'.format(file, new)
                    os.rename(os.path.join(dirname, file), os.path.join(dirname, new))
            except:
                print "  FILE:  "+os.path.join(dirname, file)
                raise
    if len(artists) > 1:
        is_comp = True
    # Now parse the music files that we found
    for group in music:
        # Load the data from the group, for easier manipulation
        file    = group['file']
        name    = group['name']
        mp4     = group['mp4']
        changed = group['changed']
        #print file
        # Compilation?
        compilation = mp4.get(tags['partofcompilation'])
        if not compilation and is_comp:
            mp4[tags['partofcompilation']] = True
            changed = True
        a_artist = mp4.get(tags['albumartist'], [None])[0]
        if compilation and not a_artist:
            mp4[tags['albumartist']] = ['Various']
            changed = True
        # Save
        if changed:
            print "  Save {0}".format(file)
            mp4.save()
        if name:
            print '  {0}\n    {1}'.format(file, name)
            os.rename(os.path.join(dirname, file), os.path.join(dirname, name))

if 1 in sys.argv:
    path = os.path.abspath(sys.argv[1])
else:
    path = os.path.abspath('.')
print path

os.path.walk(path, visit, None)
