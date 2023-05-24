#! /usr/bin/gawk -f

BEGIN {
    # define number of order
    num_ord = num_ord ? num_ord : 31;

    # define length of ring buffers
    len_data_raw = num_ord + 1;
    len_data_dif = 1;

    # initialize ring buffers
    for (i = 0; i < len_data_raw; i++) {
        arr_data_raw[i] = 0.0;
    }
    for (i = 0; i < len_data_dif; i++) {
        arr_data_dif[i] = 0.0;
    }

    # initialize index of ring buffers
    idx_data_raw = 0;
    idx_data_dif = 0;

    # initialize number of data
    num_data_raw = 0;
}

{
    # add number of data
    num_data_raw++;

    # update index of ring buffers (write pointers)
    idx_data_raw = num_data_raw % len_data_raw;
    idx_data_dif = num_data_raw % len_data_dif;

    # clear number of data
    if (idx_data_raw == 0 && idx_data_dif == 0) {
        num_data_raw = 0;
    }

    # store input raw data
    val_data_raw = $0;
    arr_data_raw[idx_data_raw] = val_data_raw;

    # apply differential filter
    arr_data_dif[idx_data_dif] = dif(arr_data_raw, idx_data_raw, num_ord, len_data_raw);

    # print results
    print arr_data_dif[idx_data_dif];
}

# get value of ring buffer
function get_buffer(arr, idx, len) {
    if (idx < 0) {
        return arr[idx + len];
    }

    return arr[idx];
}

# differential filter
function dif(arr_x, idx_x, ord, len_x,      _ret, _half, i) {
    _ret = 0.0;
    _half = int((ord - 1) / 2);

    for (i = 0; i < ord; i++) {
        _ret += (_half - i) * get_buffer(arr_x, idx_x - i, len_x);
    }

    return _ret;
}
