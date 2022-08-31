#! /usr/bin/env python3


# import libraries
import argparse
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal


# parse options
parser = argparse.ArgumentParser(description=__file__)

parser.add_argument("--fs", required=True, help="sampling frequency")
parser.add_argument("--b", required=True, help="b coefficients")
parser.add_argument("--a", required=True, help="a coefficients")

args = parser.parse_args()

val_fs = float(args.fs)
arr_b = eval(str(args.b))
arr_a = eval(str(args.a))


# set matplotlib parameters
plt.rcParams["lines.linewidth"] = 1.5
plt.rcParams["figure.dpi"] = 100
plt.rcParams["grid.color"] = "888888"
plt.rcParams["grid.linestyle"] = "--"
plt.rcParams["axes.grid.which"] = "both"
plt.rcParams["axes.grid.axis"] = "both"
plt.rcParams["axes.grid"] = "True"
plt.rcParams["figure.facecolor"] = "white"
plt.rcParams["xtick.direction"] = "in"
plt.rcParams["ytick.direction"] = "in"
plt.rcParams["xtick.major.width"] = 2.0
plt.rcParams["ytick.major.width"] = 2.0
plt.rcParams["font.size"] = 12
plt.rcParams["axes.linewidth"] = 1.0


# calculate filter characteristics
w, h = signal.freqz(arr_b, arr_a)


# calculate axis
arr_freq = w / (2 * np.pi) * val_fs
arr_amp = 20 * np.log10(np.abs(h))


# plot amplitude
fig = plt.figure()
ax = fig.add_subplot(1, 1, 1)
ax.plot(arr_freq, arr_amp, linestyle="-", color="#000000", linewidth=2)
ax.set_xlabel("Frequency [Hz]")
ax.set_ylabel("Amplitude [dB]")
ax.set_xscale("log")
plt.tight_layout()
plt.show()
