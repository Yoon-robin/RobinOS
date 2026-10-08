/* Mission 17: the password sits in the program as plain text (strings finds it). */
#include <stdio.h>
#include <string.h>
#include "reveal.h"

static const char password[] = "robin-sesame-2026";
/* ROBIN-VAULT-OPEN */
static const unsigned char code[] = {
    0x08, 0x15, 0x18, 0x13, 0x14, 0x77, 0x0c, 0x1b, 0x0f, 0x16, 0x0e, 0x77, 0x15, 0x0a, 0x1f, 0x14
};

int main(void)
{
    char line[128];

    fputs("금고 비밀번호: ", stdout);
    fflush(stdout);
    if (!fgets(line, sizeof line, stdin))
        return 1;
    line[strcspn(line, "\r\n")] = '\0';
    if (strcmp(line, password) != 0) {
        puts("비밀번호가 틀렸어요.");
        return 1;
    }
    fputs("금고가 열렸어요. 코드: ", stdout);
    reveal(code, sizeof code);
    return 0;
}
