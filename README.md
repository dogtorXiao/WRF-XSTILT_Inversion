This program is created to integrate X-STILT and OCO-3 SAM observations in the Bayesian inversion to optimize the point source CO2 emissions (ex. the power plant). In order to run X-STILT, please convert the meteorological data files to arl format (https://www.ready.noaa.gov/HYSPLIT_data2arl.php#INFO).

STEPS:

A) PREPARATIONS
1. Find the geolocation information in google maps (https://www.google.com/maps)
2. Use the X-STILT forward function to get a sense of how the downwind domain looks like (usually just take a few minites)
3. Plot the downwind domain, segmentation the inside pixels, and click the pixels farthest away from the point sources (up to 40) as a set of samples. Get the X-STILT backgrounds and background errors.
4. Release the particles at the samples to run for plenty of time with X-STILT backward function
5. Calculate the time period needed to run X-STILT and the average PBL height. Determine the scaling factor for the PBL height (zisf) with any observations you have (if there is no data available, skip this step)

B) MAIN RUN
1. Decide the standard zisf and turbulented zisfs, and the wind error running (using the radiosonde data), to run X-STILT for multiple times (with vertical and transport error)
2. Calculate the simulated XCO2 and transport errors (With ODIAC emission inventory as the prior)

C) INVERSION
The point source is very sensitive compared to area fluxes, while the SAM mode observations provides more than 1000 pixels around the point source, most of which are easy to introduce uncertainties. Therefore, select the pixels in the inversion is crucial. Here we provided 2 methods:
    
1. only select the pixels inside the near-time TROPOMI NO2 pulmes. Before conducting the inversion, please plot the NO2 plumes and segmentation the OCO-3 pixels, calculate the background background errors
2. select all the pixels in the downwind domain

DATA REQUIRED:
1. meteorological data in arl format (eg. https://www.ready.noaa.gov/data/archives/gfs0p25/)
2. radiosonde data (https://ruc.noaa.gov/raobs/)
3. ODIAC emission (https://db.cger.nies.go.jp/dataset/ODIAC/DL_odiac2020b.html)
4. OCO-3 CO2 observations (https://search.earthdata.nasa.gov/search?q=OCO3_L2_Lite_FP)
5. TROPOMI NO2 data (https://search.earthdata.nasa.gov/search?q=S5P_L2__NO2____1)
