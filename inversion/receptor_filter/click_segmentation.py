#' selecet the pixels inside the NO2 plume domain
#' @author DogtorX

import matplotlib.pyplot as plt
import pandas as pd
import sys
import numpy as np
import threading
import matplotlib.pyplot as plt
from matplotlib.widgets import Button

NO2_plume_fig_file      = sys.argv[1]
NO2_segmentation_file     = sys.argv[2]

def close_figure(event):
    plt.close(fig)

img = plt.imread(NO2_plume_fig_file)

fig, ax = plt.subplots()
plt.subplots_adjust(bottom=0.2)

ax.imshow(img)
ax.set_title('Click the button after entering coordinates')

button_ax = plt.axes([0.81, 0.05, 0.1, 0.075])
button = Button(button_ax, 'Close')
button.on_clicked(close_figure)

plt.show(block=False)

print('please input 4 calibration coordinates, in lon1, lon2, lat1, lat2, respectively:')
numbers = []  
for i in range(4): 
    while True: 
        try:
            number = float(input(f"Enter number {i+1}: ").strip())
            numbers.append(number)
            break
        except ValueError:
            print("That's not a valid number. Please enter a float number.")

print("The lon_lat you entered are:", numbers)

plt.close(fig)

calib = []

def onclick(event):
    x = int(event.xdata)
    y = int(event.ydata)
    
    calib.append((x,y))

    print(f"Clicked pixel value: ({x},{y})")

img = plt.imread(NO2_plume_fig_file)
fig, ax = plt.subplots()
ax.imshow(img)
cid = fig.canvas.mpl_connect('button_press_event', onclick)

button_ax = plt.axes([0.81, 0.05, 0.1, 0.075])
button = Button(button_ax, 'Close')
button.on_clicked(close_figure)

plt.show()
coord = pd.DataFrame(calib, columns=['lon_x', 'lat_y'])

# for x axis, lon = a1*x+b1
a1 = (numbers[1]-numbers[0])/(coord['lon_x'][1]-coord['lon_x'][0])
b1 = numbers[0]-a1*coord['lon_x'][0]

# for y axis, lat = a2*y+b2
a2 = (numbers[3]-numbers[2])/(coord['lat_y'][3]-coord['lat_y'][2])
b2 = numbers[2]-a2*coord['lat_y'][2]

print('Coefficients:'+' '+str(a1)+' '+str(b1)+' '+str(a2)+' '+str(b2))
pixel_values = []

def onclick(event):

    x = int(event.xdata)
    y = int(event.ydata)

    pixel_values.append((x,y))
    
    print(f"Clicked pixel value: ({x},{y})")

fig, ax = plt.subplots()
ax.imshow(img)
cid = fig.canvas.mpl_connect('button_press_event', onclick)

button_ax = plt.axes([0.81, 0.05, 0.1, 0.075])
button = Button(button_ax, 'Close')
button.on_clicked(close_figure)

plt.show()
df = pd.DataFrame(pixel_values, columns=['x', 'y'])
lon = a1*df['x'] + b1
lat = a2*df['y'] + b2
lon_lat_seg = pd.DataFrame({'lon':lon, 'lat':lat})
lon_lat_seg = lon_lat_seg.iloc[:-1]

lon_lat_seg.to_csv(NO2_segmentation_file, index=False)