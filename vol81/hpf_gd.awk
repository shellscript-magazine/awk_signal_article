#! /usr/bin/gawk -f

BEGIN {
    # define number of order
    num_ord = num_ord ? num_ord : 255;

    # define group delay
    val_gd = int((num_ord - 1) / 2);

    # define length of ring buffers
    len_data_raw = num_ord + 1;
    len_data_hpf = val_gd + 1;

    # initialize ring buffers
    for (i = 0; i < len_data_raw; i++) {
        arr_data_raw[i] = 0.0;
    }
    for (i = 0; i < len_data_hpf; i++) {
        arr_data_hpf[i] = 0.0;
    }

    # initialize index of ring buffers
    idx_data_raw = 0;
    idx_data_hpf = 0;

    # initialize number of data
    num_data_raw = 0;
}

{
    # add number of data
    num_data_raw++;

    # update index of ring buffers (write pointers)
    idx_data_raw = num_data_raw % len_data_raw;
    idx_data_hpf = num_data_raw % len_data_hpf;

    # clear number of data
    if (idx_data_raw == 0 && idx_data_hpf == 0) {
        num_data_raw = 0;
    }

    # store input raw data
    val_data_raw = $0;
    arr_data_raw[idx_data_raw] = val_data_raw;

    # apply high pass filter
    arr_data_hpf[idx_data_hpf] = hpf( \
            arr_data_raw, arr_data_hpf,
            idx_data_raw, idx_data_hpf,
            num_ord,
            len_data_raw, len_data_hpf);

    # print results
    print get_buffer(arr_data_raw, idx_data_raw - val_gd, len_data_raw), arr_data_hpf[idx_data_hpf];
}

# get value of ring buffer
function get_buffer(arr, idx, len) {
    if (idx < 0) {
        return arr[idx + len];
    }

    return arr[idx];
}

# high pass filter
function hpf(arr_x, arr_y, idx_x, idx_y, ord, len_x, len_y,       _ret, _gain) {
    _ret = 0.0;
    _gain = 1.0 / ord;

    _ret += get_buffer(arr_y, idx_y - 1, len_y);
    _ret -= _gain * get_buffer(arr_x, idx_x, len_x);
    _ret += get_buffer(arr_x, idx_x - int((ord - 1) / 2), len_x);
    _ret -= get_buffer(arr_x, idx_x - int((ord + 1) / 2), len_x);
    _ret += _gain * get_buffer(arr_x, idx_x - ord, len_x);

    return _ret;
}
