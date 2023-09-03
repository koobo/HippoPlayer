# https://hvsc.brona.dk/HVSC/C64Music/DOCUMENTS/STIL.txt
# TODO: Check /MUSICIANS/H/Hubbard_Rob/Delta.sid
# TODO: skip "folder items" like /MUSICIANS/H/Hubbard_Rob/
# TODO: check /MUSICIANS/Z/Zzap69/Jullov.sid
#       has two TITLE and ARTIST entries

from struct import *
import os
import textwrap
import re
import zlib

# Huffman tree found from the internetz

class NodeTree(object):
    def __init__(self, left=None, right=None):
        self.left = left
        self.right = right

    def children(self):
        return self.left, self.right

    def __str__(self):
        return self.left, self.right


def huffman_code_tree(node, binString=''):
    '''
    Function to find Huffman Code
    '''
    if type(node) is str:
        return {node: binString}
    (l, r) = node.children()
    d = dict()
    d.update(huffman_code_tree(l, binString + '0'))
    d.update(huffman_code_tree(r, binString + '1'))
    return d


def make_tree(nodes):
    '''
    Function to make tree
    :param nodes: Nodes
    :return: Root of the tree
    '''
    print("make_tree " + str(nodes))
    while len(nodes) > 1:
        # last tuple
        (key1, c1) = nodes[-1]
        # penultimate tuple
        (key2, c2) = nodes[-2]
        # Remote two tuples
        nodes = nodes[:-2]
        node = NodeTree(key1, key2)
        nodes.append((node, c1 + c2))
        nodes = sorted(nodes, key=lambda x: x[1], reverse=True)
    return nodes[0][0]


def huffmanEncode(stil):
    freq = {}
    count = 0
    for path in stil:
        for line in stil[path]["lines"]:
            for idx in range(0, len(line)):
                char = line[idx]
                count = count + 1
                if not char in freq:
                    freq[char] = 1
                else:
                    freq[char] = freq[char] + 1

    freq = sorted(freq.items(), key=lambda x: x[1], reverse=True)
    node = make_tree(freq)
    encoding = huffman_code_tree(node)
    for i in encoding:
        print(f'{i} : {encoding[i]}')


    bitCount = 0
    charCount = 0
    for path in stil:
        for line in stil[path]["lines"]:
            for idx in range(0, len(line)):
                char = line[idx]
                charCount = charCount + 1
                bitCount = bitCount + len(encoding[char])
    print("CharCount " + str(charCount))
    print("HuffCount " + str(bitCount/8))
    return


def dictionaryCompress(stil):
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

    for word in sortedWords:
        index = str(sortedWords.index(word) + 1)
        for path in stil:
            newLines = []
            for line in stil[path]["lines"]:
                newLines.append(line.replace(word[0], index))
            stil[path]["lines"] = newLines



def fnv1(data: bytearray):
    prime = 0x01000193
    hval = 0x811c9dc5
    for i in range(0, len(data)):
        hval = (hval * prime) & 0xffffffff
        hval = hval ^ data[i]
    return hval


def fnvHash(stil):
    for path in stil:
        stil[path]["hash"] = fnv1(path.upper().encode("ISO-8859-1"))

    dups = {}
    for path in stil:
        hash = stil[path]["hash"] 
        if hash in dups:
            print("Collision!")
            print(path)
        else:
            dups[hash] = 1


def convertStil():

    fileIn = open("STIL.txt", 'r', encoding='latin1')
    fileIdx = open("HiP-STIL.db", 'wb')
    tempFile = "/tmp/stil.tmp"
    fileDb = open(tempFile, 'wb')

    wrapper = textwrap.TextWrapper(width=39)
    stil = {}

    # Parse into a dictionary
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
                    if not "name" in block[songNumber]:
                        block[songNumber]["name"] = []
                    block[songNumber]["name"].append(line[9:])
             
                if line.startswith(" AUTHOR:"):
                    if not "author" in block[songNumber]:
                        block[songNumber]["author"] = []
                    block[songNumber]["author"].append(line[9:])
             
                if line.startswith("  TITLE:"):
                    if not "title" in block[songNumber]:
                        block[songNumber]["title"] = []
                    block[songNumber]["title"].append(line[9:])
             
                if line.startswith(" ARTIST:"):
                    if not "artist" in block[songNumber]:
                        block[songNumber]["artist"] = []
                    block[songNumber]["artist"].append(line[9:])
             
                if line.startswith("COMMENT:") or line.startswith("        "):
                    if not block[songNumber].get("comment"):
                        block[songNumber]["comment"] = line[9:]
                    else:
                        block[songNumber]["comment"] += line[8:]
    fileIn.close()


    # Create wrapped lines that are displayable in the hippo info window
    for path in stil:
        lines = []

        def wrapAndPut(nameIn, fieldIn, linesOut):
            if fieldIn in stil[path][songNumber]:
                if type(stil[path][songNumber][fieldIn]) is list:
                    for fieldValue in stil[path][songNumber][fieldIn]:
                        linesOut += wrapper.wrap(nameIn + ": " + fieldValue)
                else:
                    linesOut += wrapper.wrap(nameIn + ": " + stil[path][songNumber][fieldIn])


        for songNumber in stil[path]:
            if songNumber > 0: # Do not put title for generic info
                lines += wrapper.wrap(str("Song #" + str(songNumber)))
            wrapAndPut("Name", "name", lines)
            wrapAndPut("Author", "author", lines)
            wrapAndPut("Title", "title", lines)
            wrapAndPut("Artist", "artist", lines)
            wrapAndPut("Comment", "comment", lines)
        stil[path]["lines"] = lines


    #dictionaryCompress(stil)
    #huffmanEncode(stil)
    fnvHash(stil)


    # Leave space for length
    fileIdx.write(pack(">I", 0xdeadbeef))

    dbIndex = 0      
    count = 0
    for path in stil:
        #print("Path: " + path)    
        lines = stil[path]["lines"]
        count = count+1

        # Write hash and data offset
        fileIdx.write(pack(">IBBB", stil[path]["hash"], (dbIndex>>16)&0xff, (dbIndex>>8)&0xff, dbIndex&0xff))

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
            fileDb.write(pack(">" + str(len(line)) + "sBB", line.encode("ISO-8859-1", "replace"), 0x83, 0x03))

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
    
    print("Items: " + str(count))
    return

if __name__ == "__main__":
    convertStil()
