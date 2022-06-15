#! /usr/bin/gawk -f

{
    line[NR] = $0;
}

END {
    for (i = NR - 9; i <= NR; i++) {
        print line[i];
    }
}
