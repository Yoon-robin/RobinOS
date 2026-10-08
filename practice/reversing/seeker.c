/* Mission 19: the program looks for a key file and only says it found none;
   strace shows which file it tried to open. */
#include <stdio.h>
#include <stdlib.h>
#include "reveal.h"

/* ROBIN-SEEKER-FOUND */
static const unsigned char code[] = {
    0x08, 0x15, 0x18, 0x13, 0x14, 0x77, 0x09, 0x1f, 0x1f, 0x11, 0x1f, 0x08, 0x77, 0x1c, 0x15, 0x0f, 0x14, 0x1e
};

int main(void)
{
    const char *home = getenv("HOME");
    char path[512];
    FILE *key;

    if (!home)
        home = "";
    /* ~/practice/reversing/.hidden/seeker.key, put together in pieces */
    snprintf(path, sizeof path, "%s/%s%s/%s%s/%s%s", home, "practice", "/reversing", ".hid", "den", "seeker", ".key");
    key = fopen(path, "r");
    if (!key) {
        puts("열쇠 파일을 찾지 못했어요.");
        return 1;
    }
    fclose(key);
    fputs("열쇠 파일을 찾았어요. 코드: ", stdout);
    reveal(code, sizeof code);
    return 0;
}
