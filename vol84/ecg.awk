#! /usr/bin/gawk -f

BEGIN {
    # set sampling rate
    val_fs = 200;

    # set filter orders
    num_ord_lpf = 7;
    num_ord_hpf = 31;
    num_ord_dif = 5;
    num_ord_sma = 31;

    # define group delay
    val_gd_lpf = int((num_ord_lpf - 1) / 2) * 2;
    val_gd_hpf = int((num_ord_hpf - 1) / 2);
    val_gd_dif = int((num_ord_dif - 1) / 2);
    val_gd_sma = int((num_ord_sma - 1) / 2);

    # set length of ring buffers
    len_data = 2 * val_fs + (val_gd_lpf + val_gd_hpf + val_gd_dif + val_gd_sma);

    # initialize ring buffers
    for (i = 0; i < len_data; i++) {
        arr_data_raw[i] = 0.0;
        arr_data_lpf[i] = 0.0;
        arr_data_hpf[i] = 0.0;
        arr_data_dif[i] = 0.0;
        arr_data_sma[i] = 0.0;
        arr_data_flg[i] = 0.0;
    }

    # initialize index of ring buffers
    idx_data = 0;

    # initialize number of data
    num_data = 0;

    # set peak detection parameters
    tap_interval = 2 * 200;
    val_data_sma_max = 0;
    val_data_sma_threshold = 0;
    val_peak_rate = 0.3;
    idx_data_hpf_max = 0;
    val_data_hpf_max = 0;
    val_data_sma_curr = 0;
    val_data_sma_last = 0;
}

{
    # add number of data
    num_data++;

    # update index of ring buffers
    idx_data = num_data % len_data;

    # store input raw data
    val_data_raw = $0;
    arr_data_raw[idx_data] = val_data_raw;

    # apply low pass filter
    arr_data_lpf[idx_data] = lpf( \
            arr_data_raw, arr_data_lpf,
            idx_data, idx_data,
            num_ord_lpf,
            len_data, len_data);

    # apply high pass filter
    arr_data_hpf[idx_data] = hpf( \
            arr_data_lpf, arr_data_hpf,
            idx_data, idx_data,
            num_ord_hpf,
            len_data, len_data);

    # apply differential filter
    arr_data_dif[idx_data] = dif( \
            arr_data_hpf,
            idx_data,
            num_ord_dif,
            len_data);

    # apply squaring
    arr_data_squ[idx_data] = (arr_data_dif[idx_data])^2;

    # apply simple moving average filter
    arr_data_sma[idx_data] = sma( \
            arr_data_squ, arr_data_sma,
            idx_data, idx_data,
            num_ord_sma,
            len_data, len_data);

    # peak flag
    arr_data_flg[idx_data] = 0;

    # update threshold every interval
    if (num_data % tap_interval == 0) {
        val_data_sma_threshold = val_data_sma_max * val_peak_rate;
        val_data_sma_max = 0;
    } else {
        if (val_data_sma_max < arr_data_sma[idx_data]) {
            val_data_sma_max = arr_data_sma[idx_data];
        }
    }

    # start point to detect main peak
    val_data_sma_curr = get_buffer(arr_data_sma, idx_data - 0, len_data);
    val_data_sma_last = get_buffer(arr_data_sma, idx_data - 1, len_data);

    if (val_data_sma_curr > val_data_sma_threshold && val_data_sma_threshold >= val_data_sma_last) {
        val_data_hpf_max = 0;
        idx_data_hpf_max = 0;
        val_data_flg = 1;
    }

    # search maximum index
    if (val_data_flg == 1) {
        val_data_hpf_curr = get_buffer(arr_data_hpf, idx_data - (val_gd_dif + val_gd_sma), len_data);
        idx_data_hpf_curr = idx_data - (val_gd_dif + val_gd_sma);
        idx_data_hpf_curr = idx_data_hpf_curr >= 0 ? idx_data_hpf_curr : idx_data_hpf_curr + len_data;

        if (val_data_hpf_max < val_data_hpf_curr) {
            val_data_hpf_max = val_data_hpf_curr;
            idx_data_hpf_max = idx_data_hpf_curr;
        }
    }

    # end point to detect main peak
    if (val_data_sma_curr < val_data_sma_threshold && val_data_sma_threshold <= val_data_sma_last) {
        arr_data_flg[idx_data_hpf_max] = 1;

        # calculate peak to peak interval
        if (idx_data - idx_data_hpf_max >= 0) {
            cnt_peak_curr = num_data - (idx_data - idx_data_hpf_max);
        } else {
            cnt_peak_curr = num_data - (idx_data - idx_data_hpf_max + len_data);
        }

        cnt_rri_curr = cnt_peak_curr - cnt_peak_last;
        cnt_peak_last = cnt_peak_curr;

        val_data_flg = 0;
        val_data_hpf_max = 0;
        idx_data_hpf_max = 0;
    }

    # print results
    printf("%f,%f,%f,%f,%f,%f,%f,%f\n",
            get_buffer( \
                    arr_data_raw,
                    idx_data - (val_gd_lpf + val_gd_hpf + val_gd_dif + val_gd_sma) - 2 * val_fs,
                    len_data),
            get_buffer( \
                    arr_data_lpf,
                    idx_data - (val_gd_hpf + val_gd_dif + val_gd_sma) - 2 * val_fs,
                    len_data),
            get_buffer( \
                    arr_data_hpf,
                    idx_data - (val_gd_dif + val_gd_sma) - 2 * val_fs,
                    len_data),
            get_buffer( \
                    arr_data_dif,
                    idx_data - val_gd_sma - 2 * val_fs,
                    len_data),
            get_buffer( \
                    arr_data_squ,
                    idx_data - val_gd_sma - 2 * val_fs,
                    len_data),
            get_buffer( \
                    arr_data_sma,
                    idx_data - 2 * val_fs,
                    len_data),
            cnt_rri_curr * 0.005 * 1000,
            get_buffer( \
                    arr_data_flg,
                    idx_data - (val_gd_dif + val_gd_sma) - 2 * val_fs,
                    len_data));
}

# get value of ring buffer
function get_buffer(arr, idx, len) {
    if (idx < 0) {
        return arr[idx + len];
    }

    return arr[idx];
}

# low pass filter
function lpf(arr_x, arr_y, idx_x, idx_y, ord, len_x, len_y,     _ret, _gain) {
    _ret = 0.0;
    _gain = 1.0 / (ord * ord);

    _ret += 2.0 * get_buffer(arr_y, idx_y - 1, len_y);
    _ret -= 1.0 * get_buffer(arr_y, idx_y - 2, len_y);
    _ret += 1.0 * _gain * arr_x[idx_x];
    _ret -= 2.0 * _gain * get_buffer(arr_x, idx_x - ord, len_x);
    _ret += 1.0 * _gain * get_buffer(arr_x, idx_x - 2 * ord, len_x);

    return _ret;
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

# differential filter
function dif(arr_x, idx_x, ord, len_x,      _ret, _hal, _gain, i) {
    _ret = 0.0;
    _half = int((ord - 1) / 2);

    _gain = 0.0;
    for (i = 0; i < ord; i++) {
        _gain += (_half - i)^2;
    }

    for (i = 0; i < ord; i++) {
        _ret += (_half - i) * get_buffer(arr_x, idx_x - i, len_x);
    }

    return _ret / _gain;
}

# simple moving average filter
function sma(arr_x, arr_y, idx_x, idx_y, ord, len_x, len_y,   _ret, _gain) {
    _ret = 0.0;
    _gain = 1.0 / ord;

    _ret += get_buffer(arr_y, idx_y - 1, len_y);
    _ret += _gain * get_buffer(arr_x, idx_x, len_x);
    _ret -= _gain * get_buffer(arr_x, idx_x - ord, len_x);

    return _ret;
}

