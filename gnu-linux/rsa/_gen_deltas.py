#!/usr/bin/env python3

import csv
import sys
from datetime import datetime
import os

# column names vary in some tables. For example, some time tables use 'created_at', while others
# use 'create_date', but these two columns essentially represent the same thing.
# Each column is assosciated with an exhaustive list of the names that the column could take.
# Add new entries to the lists as needed if new. If 
ENTITY_COL_NAME = ["entity"]
UUID_COL_NAME = ["uuid"]
CREATE_DATE_COL_NAME = ["created_at", "create_date"]
ESSENTIAL_COLS = [UUID_COL_NAME, ENTITY_COL_NAME, CREATE_DATE_COL_NAME]

DATE_FORMAT_MILLIS = '%Y-%m-%d %H:%M:%S.%f'
DATE_FORMAT_NO_MILLIS = '%Y-%m-%d %H:%M:%S'
HIGHEST_DELTA_COUNT = 5

show_plot = False
save_plot = False
while sys.argv[1].startswith("-"):
  if sys.argv[1] == "--show-plot" or sys.argv[1] == "-p":
    show_plot = True
    sys.argv = sys.argv[1:]
  if sys.argv[1] == "--save-plot" or sys.argv[1] == "-s":
    save_plot = True
    sys.argv = sys.argv[1:]

file1 = sys.argv[1]
file2 = sys.argv[2]
delta_file = sys.argv[3]

def parse_datetime(dt_str):
  fmt = DATE_FORMAT_MILLIS
  if '.' not in dt_str:
    fmt = DATE_FORMAT_NO_MILLIS
  if dt_str[-1] == '.':
    dt_str = dt_str[:-1]
    fmt = DATE_FORMAT_NO_MILLIS
  return datetime.strptime(dt_str, fmt)

def create_col_name_dict(header):
  col_name_dict = dict()
  for idx, column_name in enumerate(header):
    col_name_dict[column_name] = idx
  return col_name_dict

def ensure_cols_exist(header, col_names, file_name):
  for col_name_list in col_names:
    found = False
    for col_name in col_name_list:
      if col_name in header:
        found = True
        break
    assert found == True, "'" + str(col_name_list) + "'" + " column(s) not found in file " + str(file_name) + ". Available columns are " + str(header)

def get_col_index(row, col_name_list):
  for col_name in col_name_list:
    if col_name in row:
      return row[col_name]


def generate_plot(entries, plot_title):
  xvalues = [x[2] for x in entries]
  yvalues = [int(float(x[4])) for x in entries]

  fig = plt.figure()
  plt.subplots_adjust(bottom=0.34, top=0.82)
  ax1 = fig.add_subplot(111)
  ax1.set_title(plot_title)
  ax2 = ax1.twiny()
  
  xfmt = md.DateFormatter('%Y-%m-%d %H:%M')
  Axis.set_major_formatter(ax1.xaxis, xfmt)
  ax1.plot(xvalues, yvalues)
  ax1.set_xlabel("Timestamp")
  ax1.set_ylabel("Delta (seconds)")
  ax1.tick_params(labelrotation=70)
  max_y = max(yvalues)
  y_ticks = [int(i/10)*10 for i in range(0, max_y, int(max_y/5))]
  y_ticks[-1] = max_y
  ax1.set_yticks(y_ticks)
  
  num_entries = len(entries) 
  ax2.set_xlim(ax1.get_xlim())
  count_ticks = [(int(v/1000)*1000 if i < 10 else int(v))
          for i, v in enumerate(range(0, num_entries, int(num_entries/10)))]
  count_ticks[-1] = num_entries
  ax2.set_xticks(count_ticks)
  ax2.tick_params(labelrotation=25)
  ax2.set_xlabel("Count")

##### MAIN

file1_col_name_dict = dict()
file2_col_name_dict = dict()
file2_entry_dict = dict()
diff_entry_list = []

# index the values in one of the files for a quicker lookup
with open(file2, newline='') as csvfile:
  file_reader = csv.reader(csvfile, delimiter=',')
  header = next(file_reader, None)
  ensure_cols_exist(header, ESSENTIAL_COLS, file2)

  file2_col_name_dict = create_col_name_dict(header)  
  uuid_index = get_col_index(file2_col_name_dict, UUID_COL_NAME)
  for row in file_reader:
    uuid = row[uuid_index]
    file2_entry_dict[uuid] = row

highest_deltas = []

# read one file and generate the deltas using the values read from the other 
with open(file1, newline='') as csvfile:
  file1_reader = csv.reader(csvfile, delimiter=',')
  header = next(file1_reader, None)
  ensure_cols_exist(header, ESSENTIAL_COLS, file1)
  file1_col_name_dict = create_col_name_dict(header) 

  file1_uuid_index = get_col_index(file1_col_name_dict, UUID_COL_NAME)
  file1_entity_index = get_col_index(file1_col_name_dict, ENTITY_COL_NAME)
  file1_create_date_index = get_col_index(file1_col_name_dict, CREATE_DATE_COL_NAME)
  file2_create_date_index = get_col_index(file2_col_name_dict, CREATE_DATE_COL_NAME)

  for row1 in file1_reader:
    table_name = row1[file1_entity_index]
    row1_uuid = row1[file1_uuid_index]
    if row1_uuid not in file2_entry_dict:
      print("WARNING: record with UUID " + row1_uuid + " has no matching entry in other file, skipping")
      continue
    row2 = file2_entry_dict[row1_uuid]
    row2_time_str = row2[file2_create_date_index][:-1]
    row1_time_str = row1[file1_create_date_index][:-1]
    row1_date_time = parse_datetime(row1_time_str)
    row2_date_time = parse_datetime(row2_time_str)
    if row1_date_time > row2_date_time:
      diff = row1_date_time - row2_date_time
    else:
      diff = row2_date_time - row1_date_time
    diff_seconds = str(diff.seconds) + '.' + str(diff.microseconds)
    diff_entry_list.append((table_name, row1_uuid, row1_date_time, row2_date_time, diff_seconds))

    # update highest deltas
    diff_float = float(diff_seconds)
    if len(highest_deltas) < HIGHEST_DELTA_COUNT:
        highest_deltas.append(diff_float)
    else:
        min_delta = min(highest_deltas)
        if diff_float > min_delta:
            highest_deltas.remove(min_delta)
            highest_deltas.append(diff_float)

diff_entry_list = sorted(diff_entry_list, key = lambda d1: d1[2])
deltas = [float(entry[4]) for entry in diff_entry_list]
metrics = [
  "average (seconds): " + str(round(sum(deltas)/len(deltas), 2)),
  "max_delta (seconds): " + str(max(deltas)),
  "highest_deltas (seconds): " + str(sorted(highest_deltas, reverse=True))
]

# write to delta csv file
with open(delta_file, 'w', newline='') as csvfile:
  writer = csv.writer(csvfile, delimiter=',')
  writer.writerow(("Table", "UUID", "Creation Date (Active)", "Creation Date (Warm)", "Delta (In Seconds)"))
  for delta_entry in diff_entry_list:
    writer.writerow(delta_entry)

filepath_no_ext = os.path.splitext(delta_file)[0]
plot_title = os.path.basename(filepath_no_ext)
metrics_file = filepath_no_ext + "_metrics.txt"

# write to metrics file
with open(metrics_file, 'w') as metrics_file:
  for metric in metrics:
    metrics_file.write(metric + '\n')

# save/show plot
if show_plot or save_plot:
  import matplotlib.pyplot as plt
  import matplotlib.dates as md
  from matplotlib.axis import Axis

  generate_plot(diff_entry_list[1:], plot_title)
  plt.savefig(filepath_no_ext + "_plot.png", bbox_inches='tight', dpi=600)
  if show_plot: 
    if os.fork():
      pass
    else:
      plt.show()
