#' visualize the SAM mode pixels with the point source (black star)
#' click the sample pixels, with maximum of 40
#' @authoor DogtorX

# import matplotlib
# # matplotlib.use('Qt5Agg')
import sys
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.widgets import Button

OCO3_data_file   = sys.argv[1]
site_lon         = float(sys.argv[2])
site_lat         = float(sys.argv[3])
sample_demo_file = sys.argv[4]

df = pd.read_csv(OCO3_data_file)
sample_df = pd.DataFrame(columns=['lat', 'lon', 'obs'])

def close_figure(event):
    plt.close(fig)

def onclick(event):
    x, y = event.xdata, event.ydata
    threshold = 0.01

    clicked_points = df[(df['lon'] - x)**2 + (df['lat'] - y)**2 <= threshold**2]
    
    if not clicked_points.empty:
        global sample_df
        sample_df = pd.concat([sample_df, clicked_points])
        
        print("Added points!")
        print(sample_df)
    else:
        print("No nearby points found!")

fig, ax = plt.subplots()
sc = ax.scatter(df['lon'], df['lat'], c=df['obs'])
ax.scatter(site_lon, site_lat, marker='*', color='black')

button_ax = plt.axes([0.81, 0.05, 0.1, 0.075])
button = Button(button_ax, 'Close')
button.on_clicked(close_figure)

cid = fig.canvas.mpl_connect('button_press_event', onclick)

plt.xlabel('lon')
plt.ylabel('lat')
plt.show()

sample_df.rename(columns={'lat': 'lati', 'lon': 'long'}, inplace=True)
if len(sample_df) > 40:
    sample_df = sample_df.loc[0:40]
sample_df[['lati', 'long']].to_csv(sample_demo_file, index=False)
