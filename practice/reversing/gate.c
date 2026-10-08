/* Mission 18: the key is put together while the program runs, so strings
   doesn't show it, but ltrace sees it go into strcmp. */
#include <stdio.h>
#include <string.h>
#include "reveal.h"

/* ROBIN-GATE-PASS */
static const unsigned char code[] = {
    0x08, 0x15, 0x18, 0x13, 0x14, 0x77, 0x1d, 0x1b, 0x0e, 0x1f, 0x77, 0x0a, 0x1b, 0x09, 0x09
};

int main(int argc, char **argv)
{
    /* "open-sesame-7" backwards, one character at a time (volatile, so the
       compiler can't turn it back into one plain string) */
    const volatile char backwards[] = { '7', '-', 'e', 'm', 'a', 's', 'e', 's', '-', 'n', 'e', 'p', 'o' };
    char key[sizeof backwards + 1];

    for (size_t i = 0; i < sizeof backwards; i++)
        key[i] = backwards[sizeof backwards - 1 - i];
    key[sizeof backwards] = '\0';

    if (argc != 2) {
        puts("사용법: ./gate 열쇠");
        return 1;
    }
    if (strcmp(argv[1], key) != 0) {
        puts("문이 열리지 않아요.");
        return 1;
    }
    fputs("문이 열렸어요. 코드: ", stdout);
    reveal(code, sizeof code);
    return 0;
}
