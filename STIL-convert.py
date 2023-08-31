# https://hvsc.brona.dk/HVSC/C64Music/DOCUMENTS/STIL.txt
# TODO: Check /MUSICIANS/H/Hubbard_Rob/Delta.sid
# TODO: skip "folder items" like /MUSICIANS/H/Hubbard_Rob/

from struct import *
import os
import textwrap
import re


def compressStil(stil):
    words = {}

    for path in stil:
        lines = stil[path]["lines"]
        #results = re.findall(r'\w+', " ".join(lines))
        results = re.findall(r'[\w:]+\s?', " ".join(lines))
        for word in results:
            if len(word) > 3:
                if word in words:
                    words[word] = words[word]+1
                else:
                    words[word] = 1

    # Set dictionary size
    sortedWords = sorted(words.items(), reverse=True, key=lambda item: item[1])[0:127]
    print(sortedWords)

    # This drops from 3.1M to 2.4M
    for word in sortedWords:
        index = str(sortedWords.index(word) + 1)
        for path in stil:
            newLines = []
            for line in stil[path]["lines"]:
                newLines.append(line.replace(word[0], index))
            stil[path]["lines"] = newLines



def compressIndex(stil):
    words = {}
    newStil = {}

    for path in stil:
        results = re.findall(r'[\w:]+\s?', path)
        for word in results:
            if len(word) > 3:
                if word in words:
                    words[word] = words[word]+1
                else:
                    words[word] = 1

    # Set dictionary size
    sortedWords = sorted(words.items(), reverse=True, key=lambda item: item[1])[0:127]
    print(sortedWords)

    for word in sortedWords:
        index = str(sortedWords.index(word) + 1)
        for path in stil:
            if not "newPath" in stil[path]:
                stil[path]["newPath"] = path
            stil[path]["newPath"] = stil[path]["newPath"].replace(word[0], index)

    for path in stil:
        newStil[stil[path]["newPath"]] = stil[path]

    return newStil


def symbolFrequency(stil):
    freq = {}
    count = 0
    for path in stil:
        for line in stil[path]["lines"]:
            for idx in range(0, len(line)):
                char = line[idx]
                count = count + 1
                if not char in freq:
                    freq[char] = 0
                else:
                    freq[char] = freq[char] + 1
    print(freq)
    print(count)
    return




fileIn = open("STIL.txt", 'r', encoding='latin1')
fileIdx = open("HiP-STIL.db", 'wb')
tempFile = "/tmp/stil.tmp"
fileDb = open(tempFile, 'wb')

wrapper = textwrap.TextWrapper(width=39)
stil = {}

while True:
    line = fileIn.readline()
    if not line:
        break
    if line[0] == "#":
        continue
    # Start of STIL block
    if line[0] == "/":
        # Strip line change and extension
        # Reverse: line[::-1]
        path = os.path.splitext(line.strip())[0]
        # Parse STIL block
        block = {}
        # Store non-song number specific data (eg. comment) in song 0
        songNumber = 0
        block[songNumber] = {}
        while True:
            pos = fileIn.tell()
            line = fileIn.readline()
            if not line or line[0] == "/":
                # Block done, stop at the start of the next STIL block
                fileIn.seek(pos)

                # Skip folder items, not supporting those at the moment
                if not path[-1] == "/":
                    stil[path] = block
                else:
                    pass #print("Skipped: " + path)        
                break
            line = line.rstrip()
            # Check for song indicator
            if line[0:2] == "(#":
                songNumber = int(line.strip("(#)"))
            # New dict for each song
            if not block.get(songNumber):
                block[songNumber] = {}
            if line.startswith("   NAME:"):
                block[songNumber]["name"] = line[9:]
            if line.startswith(" AUTHOR:"):
                block[songNumber]["author"] = line[9:]
            if line.startswith("  TITLE:"):
                block[songNumber]["title"] = line[9:]
            if line.startswith(" ARTIST:"):
                block[songNumber]["artist"] = line[9:]
            if line.startswith("COMMENT:") or line.startswith("        "):
                if not block[songNumber].get("comment"):
                    block[songNumber]["comment"] = line[9:]
                else:
                    block[songNumber]["comment"] += line[8:]
fileIn.close()


# Index format:
# byte: path length
# ?     path (UPPERCASED?)
# long: offset into data
# word: data length 


# Create concatenated and wrapped text
for path in stil:
    lines = []
    for songNumber in stil[path]:
        if songNumber > 0: # Do not put title for generic info
            lines += wrapper.wrap(str("Song #" + str(songNumber)))
        if stil[path][songNumber].get("name"):
            lines += wrapper.wrap("Name: " + stil[path][songNumber].get("name"))
        if stil[path][songNumber].get("author"):
            lines += wrapper.wrap("Author: " + stil[path][songNumber].get("author"))
        if stil[path][songNumber].get("title"):
            lines += wrapper.wrap("Title: " + stil[path][songNumber].get("title"))
        if stil[path][songNumber].get("artist"):
            lines += wrapper.wrap("Artist: " + stil[path][songNumber].get("artist"))
        if stil[path][songNumber].get("comment"):
            lines += wrapper.wrap("Comment: " + stil[path][songNumber].get("comment"))
    stil[path]["lines"] = lines

    
#compressStil(stil)
#stil = compressIndex(stil)
#symbolFrequency(stil)

# Leave space for length
fileIdx.write(pack(">I", 0))

dbIndex = 0        
for path in stil:
    #print("Path: " + path)    
    lines = stil[path]["lines"]
    pathOut = path
    # 733k to 584k index size drop 
    #pathOut = pathOut.replace("/DEMOS", "0")
    #pathOut = pathOut.replace("/GAMES", "1")
    #pathOut = pathOut.replace("/MUSICIANS", "2")

    # Write path and data offset
    # Big endian, pascal string with zero padding at the end, unsigned integer
    packString = ">" + str(len(pathOut)+2) + "pI"
    fileIdx.write(pack(packString, pathOut.upper().encode("latin1"), dbIndex))
    
    # Calculate text length
    # Each line with two byte line change magic code
    textLength = 0    
    for line in lines:
        textLength += len(line) + 2      
        
    dbIndex += textLength + 2    # add len

    # Write length
    # Big endian, two byte length
    fileDb.write(pack(">H", textLength))
    # Write text line
    # Big endian, string with length, two bytes custom Hippo line change
    for line in lines:
        fileDb.write(pack(">" + str(len(line)) + "sBB", line.encode("latin1", "replace"), 0x83, 0x03))

    continue

# Write index length to the first 4 bytes placeholder
idxLength = fileIdx.tell()
print("Idx length: " + str(idxLength))
print("Db length: " + str(fileDb.tell()))
fileIdx.seek(0)
fileIdx.write(pack(">I", idxLength))
fileIdx.seek(idxLength)

# Append the data part to the end of the file
fileDb.close()
fileDb = open(tempFile, 'rb')
fileIdx.write(fileDb.read())

fileIdx.close()
fileDb.close()
   