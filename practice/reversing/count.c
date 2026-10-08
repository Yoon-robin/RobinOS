/* Mission 20: the right number is a constant in check(); objdump shows it in
   hexadecimal (cmp $0x539). Kept unstripped so the function has its name. */
#include <stdio.h>
#include <stdlib.h>
#include "reveal.h"

/* ROBIN-COUNT-1337 */
static const unsigned char code[] = {
    0x08, 0x15, 0x18, 0x13, 0x14, 0x77, 0x19, 0x15, 0x0f, 0x14, 0x0e, 0x77, 0x6b, 0x69, 0x69, 0x6d
};

__attribute__((noinline)) int check(int number)
{
    return number == 1337;
}

int main(int argc, char **argv)
{
    if (argc != 2) {
        puts("사용법: ./count 숫자");
        return 1;
    }
    if (!check(atoi(argv[1]))) {
        puts("틀렸어요.");
        return 1;
    }
    fputs("맞았어요. 코드: ", stdout);
    reveal(code, sizeof code);
    return 0;
}
