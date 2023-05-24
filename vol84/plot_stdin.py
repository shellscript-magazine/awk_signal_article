#! /usr/bin/env python3


# import libraries
import os
import re
import sys
import argparse
import numpy as np
import matplotlib.pyplot as plt


# parse options
parser = argparse.ArgumentParser(description=__file__)

parser.add_argument("--data", required=True, help="data column as array")
parser.add_argument("--ylim", help="y limitation as array")
parser.add_argument("--norm", action="store_true", help="normalization")

args = parser.parse_args()

lst_plot = eval(str(args.data))
lst_ylim = eval(str(args.ylim))
is_norm = args.norm


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


# initialize data list
lst_data = [0] * len(lst_plot)
for i in range(len(lst_plot)):
    lst_data[i] = []


# initialize counter
num_data = 0


# initialize colors
lst_color = ["#000000", "#ff0000", "#0000ff", "#00ff00", "#00ffff", "#ff00ff"]


# setup figure
fig = plt.figure()
ax = fig.add_subplot(1, 1, 1)


# read data from STDIN
for line in iter(sys.stdin.readline, ""):

    # split data
    data = line.strip("\n").split(",")

    # update counter
    num_data += 1

    # append data to list
    for i in range(len(lst_plot)):
        lst_data[i].append(float(data[lst_plot[i]]))


# plot figure
for i in range(len(lst_plot)):
    if is_norm:
        ax.plot((np.array(lst_data[i]) - np.min(lst_data[i])) / (np.max(lst_data[i]) - np.min(lst_data[i])), c=lst_color[i])
    else:
        ax.plot(lst_data[i], c=lst_color[i])

if lst_ylim != None:
    ax.set_ylim(lst_ylim)
plt.tight_layout()
plt.show()
