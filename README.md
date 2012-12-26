wiki-fooling
============

Fooling around with Wikipedia

# Build Instructions

## Flex

```
flex markup.flex
gcc lex.yy.c -lfl
./a.out Toronto.wiki
```