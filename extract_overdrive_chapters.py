#!/usr/bin/python
#
# encode with 64kbps stereo, HE, optimize for voice
#

# Set to true for test mode
dryrun = True

import os, sys, re
import mutagen.id3 as id3
from mutagen.mp3 import MP3
from mutagen import File

from collections import OrderedDict

def timestr(secs):
    (secs, ms) = str(secs).split('.')
    ms    =  float(ms[0:3] + '.' + ms[3:])
    secs  = int(secs)
    hours = int(secs // 3600)
    secs  = secs % 3600
    mins  = int(secs // 60)
    secs  = secs % 60
    return '{0:02}:{1:02}:{2:02}.{3:03.0f}'.format(hours, mins, secs, ms)

def load_mp3(total, dir, file):
    path = os.path.join(dir, file)
    #mfile = File(path)
    #file = File('some.mp3') # mutagen can automatically detect format and type of tags
    #artwork = file.tags['APIC:'].data # access APIC frame and grab the image
    #with open('image.jpg', 'wb') as img:
    #    img.write(artwork) # write artwork to new image
    #artwork = mfile.tags['APIC:'].data # access APIC frame and grab the image
    #with open('{0}.jpg'.format(path), 'wb') as img:
    #    img.write(artwork) # write artwork to new image
    audio = MP3(path)
    print audio.info.length #, audio.info.bitrate
    m = id3.ID3(path)

    data = m.get('TXXX:OverDrive MediaMarkers')
    if not data:
        print "Can't find TXXX data point for {0}".format(file)
        print m.keys()
        return
    info = data.text[0].encode("ascii", "ignore")
    #print info
    file_chapters = re.findall(r"<Name>\s*([^>]+?)\s*</Name><Time>\s*([\d:.]+)\s*</Time>", info, re.MULTILINE)
    chapters = []
    for chapter in file_chapters:
        (name, length) = chapter
        name = re.sub(r'^"(.+)"$', r'\1', name)
        name = re.sub(r'^\*(.+)\*$', r'\1', name)
        name = re.sub(r'\s*\([^)]*\)$', '', name) # ignore any sub-chapter markers from Overdrive
        name = re.sub(r'\s+\(?continued\)?$', '', name) # ignore any sub-chapter markers from Overdrive
        name = re.sub(r'\s+-\s*$', '', name)      # ignore any sub-chapter markers from Overdrive
        name = re.sub(r'^Dis[kc]\s+\d+\W*$', '', name)  # ignore any disk markers from Overdrive
        name = name.strip()
        t_parts = list(length.split(':'))
        t_parts.reverse()
        seconds = total + float(t_parts[0])
        if len(t_parts) > 1:
            seconds += (int(t_parts[1]) * 60)
        if len(t_parts) > 2:
            seconds += (int(t_parts[2]) * 60 * 60)
        chapters.append([name, seconds])
        print name, seconds
        #chapters = re.search(r'(\w+)', info)
    #print repr(chapters)
    return (total + audio.info.length, chapters)
    return


    # try:
    #     if file.decode("utf-8") == new.decode("utf-8"):
    #         new = None
    # except:
    #     print "  FILE:  "+os.path.join(dirname, file)
    #     raise
    # # Return
    # return (m, new, changed)

def visit(arg, dirname, names):
    print dirname
    os.chdir(dirname)
    #parent = os.path.dirname(dirname)
    #thisdir = os.path.basename(dirname)
    #print thisdir
    # Parse the files
    total = 0;
    all_chapters = OrderedDict()
    for file in sorted(names):
        if file.endswith('.mp3'):
            (total, chapters) = load_mp3(total, dirname, file)
            for chapter in chapters:
                if chapter[0] in all_chapters.keys():
                    continue
                all_chapters[chapter[0]] = chapter[1]
    if len(all_chapters) > 0:
        with open('overdrive_chapters.txt', 'w') as file:
            for name, length in all_chapters.items():
                chapstr = u'{0} {1}'.format(timestr(length), name)
                print chapstr
                file.write(chapstr + '\n')
    #print repr(all_chapters)



if len(sys.argv) > 1:
    path = os.path.abspath(sys.argv[1])
else:
    path = os.path.abspath('.')
print path

os.path.walk(path, visit, None)
