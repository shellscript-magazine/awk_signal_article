#! /usr/bin/gawk -f

BEGIN {
    # define number of order
    num_ord = num_ord ? num_ord : 7;

    # define group delay
    val_gd = int((num_ord - 1) / 2);

    # define length of ring buffers
    len_data_raw = num_ord + 1;
    len_data_lpf = val_gd + 1;

    # initialize ring buffers
    for (i = 0; i < len_data_raw; i++) {
        arr_data_raw[i] = 0.0;
    }
    for (i = 0; i < len_data_lpf; i++) {
        arr_data_lpf[i] = 0.0;
    }

    # initialize index of ring buffers
    idx_data_raw = 0;
    idx_data_lpf = 0;

    # initialize number of data
    num_data_raw = 0;
}

{
    # add number of data
    num_data_raw++;

    # update index of ring buffers (write pointers)
    idx_data_raw = num_data_raw % len_data_raw;
    idx_data_lpf = num_data_raw % len_data_lpf;

    # clear number of data
    if (idx_data_raw == 0 && idx_data_lpf == 0) {
        num_data_raw = 0;
    }

    # store input raw data
    val_data_raw = $0;
    arr_data_raw[idx_data_raw] = val_data_raw;

    # apply low pass filter
    arr_data_lpf[idx_data_lpf] = lpf( \
            arr_data_raw, arr_data_lpf,
            idx_data_raw, idx_data_lpf,
            num_ord,
            len_data_raw, len_data_lpf);

    # print results
    print get_buffer(arr_data_raw, idx_data_raw - val_gd, len_data_raw), arr_data_lpf[idx_data_lpf];
}

# get value of ring buffer
function get_buffer(arr, idx, len) {
    if (idx < 0) {
        return arr[idx + len];
    }

    return arr[idx];
}

# low pass filter
function lpf(arr_x, arr_y, idx_x, idx_y, ord, len_x, len_y,   _ret, _gain) {
    _ret = 0.0;
    _gain = 1.0 / ord;

    _ret += get_buffer(arr_y, idx_y - 1, len_y);
    _ret += _gain * get_buffer(arr_x, idx_x, len_x);
    _ret -= _gain * get_buffer(arr_x, idx_x - ord, len_x);

    return _ret;
}
