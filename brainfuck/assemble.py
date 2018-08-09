import sys
import string

def assemble(ifile, ofile):
    with open(ifile) as i, open(ofile, "w", encoding="latin-1") as o:
        while True:
            c = i.read(1)
            if not c:
                break
            if c not in string.whitespace :
                o.write("{0:02x}".format(ord(c)) + '\n')
        o.write("ff\n")

assemble("hello.bf", "hello.hex")
