/* The answer codes are kept XOR-ed with 0x5a, so `strings` alone doesn't show
   them: the mission is to make the program print its code. */
#include <stdio.h>

static void reveal(const unsigned char *code, size_t length)
{
    for (size_t i = 0; i < length; i++)
        putchar(code[i] ^ 0x5a);
    putchar('\n');
}
