#! /usr/bin/gawk -f

BEGIN {
    len = 10;
}

{
    idx = NR % 10;
    buf[idx] = $0;
}

END {
    for (i = 9; i >= 0; i--) {
        print get_buf(buf, idx - i, len);
    }
}

function get_buf(buf, idx, len) {
    if (idx < 0) {
        return buf[idx + len];
    } else {
        return buf[idx];
    }
}
