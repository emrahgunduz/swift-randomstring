# Random String

This tool generates a given number of random strings. It has the capability to load
a previous list for uniqueness. Length and the contents of the string can be set to
alphanumeric values _(in ranges of a-z,A-Z,0-9)_ or UTF8 can be used.

### USAGE:
`rstring <option(s)>`
### Options:
##### `-h` `--help`
Prints a help screen, similar to this readme.

##### `-l` `--length`
_Optional_. Length of the generated string. Default value is `8`.

##### `-c` `--count`
_Optional_. Count of the unique numbers you want to generate at the end. This does not include 
the number of items already loaded via a file if requested. Default value is `100`.

##### `-s` `--set`
_Optional_. Content of the random strings will be generated from this character set. 
Simply define all the charactes you need into one single word. The characters will 
be made unique, if already is not. Default value is `ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789`

##### `-o` `--out`
_Optional_. A file to write the generated codes to. Every code is written as a single 
line. If a file is not defined, output will be dumped to a file in `/tmp/random-*.txt` folder.

##### `-f` `--file` 
_Optional_. Loads a file containing a simple list of  already existing randomized 
string. Every single line in file is used as a unique string. Longer than defined 
length  strings will be truncated.