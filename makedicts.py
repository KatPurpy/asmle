import random
from bitarray import bitarray

dict = open('dict.py','r').read().split('\n')

def GenerateDict():
    letters = random.sample('ABCDEFGHIJKLMNOPQRSTUVWXYZ',16)
    awords = []
    print(letters)

    for w in dict:
        add = True
        for c in w:
            if not c in letters:
                add = False
                break
        if add: awords.append(w)

    words = random.sample(awords,32)

    ewords = []
    for w in words:
        indices = []
        for c in w:
            indices.append(letters.index(c))
        ewords.append(indices)
        print(w,indices)

    return {'DICT': list(map(lambda c: ord(c),letters)),'ENCODED':ewords, 'ASCII': words}

success = False
a = None
b = None
while not success:
    try:
        if a is None: a = GenerateDict()
        if b is None: b = GenerateDict()
        success = True
    except:
        pass
print(a,b)

file = open('dictionary.bin','wb')
file.write(bytes(a['DICT']))
file.write(bytes(b['DICT']))

def writewords(words,dictid):
    for w in words:
        '''w[0] = 0xA
        w[1] = 0xB
        w[2] = 0xC
        w[3] = 0xD
        w[4] = 0xE'''
        def b(c): return c.to_bytes(1,'little')    
        
        n0 = dictid
        n1 = w[0]<<4
        n2 = w[1]
        n3 = w[2]<<4
        n4 = w[3]
        n5 = w[4]<<4
        
        file.write(b(n1|n0))
        file.write(b(n3|n2))
        file.write(b(n5|n4))

writewords(a['ENCODED'],0)
writewords(b['ENCODED'],1)

#print(words[0], words[0].map(lambda c: letters.index(c), letters))
