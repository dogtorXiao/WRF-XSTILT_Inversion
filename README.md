# Coupled WRF-X-STILT with Bayesian Inversion

This program is created to integrate X-STILT and OCO-3 SAM observations in the Bayesian inversion to optimize the point source CO2 emissions (ex. the power plant).

# DEMO RUN

In order to run the demo_run (the main data and figures shown in the paper "High-Resolution Modeling to Quantify CO2 Emissions from Industrial Point Sources"), please set a virtual environment with R packages by:
```
install.packages(c("reshape2", "ggplot2", "dplyr", "raster",  "ggmap", "lubridate", "patchwork"))
```
in R session.

Enter the file demo_run/xstilt_post_dealing.r, set the case index (int) and the spriorisf (float) (the ratio between the assumed prior uncertainty and the prior emission), insert your google api key.

To run, in a terminal:

```
cd demo_run
Rscript xstilt_post_dealing.r
```

The output figures can be found in demo_run/DataFigures/YYYYMMDD

# PROGRAM OPERATION

## virtual environment

1. Recommended: conda environment with python3.11 and package requirements in requirements.txt
2. Interactive GUI session is in need for plume segmentation
3. R interpreter, prerequisited packages will be automatically installed by submodule [X-STILT](https://github.com/uataq/X-STILT/), make sure the python interpreter can be called by R system() function

## data required

1. meteorological data in arl format (eg. https://www.ready.noaa.gov/data/archives/gfs0p25/, or convert the netcdf meteorological data files to arl format (https://www.ready.noaa.gov/HYSPLIT_data2arl.php#INFO))
2. radiosonde data (https://ruc.noaa.gov/raobs/)
3. ODIAC emission (https://db.cger.nies.go.jp/dataset/ODIAC/DL_odiac2020b.html)
4. OCO-3 CO2 observations (https://search.earthdata.nasa.gov/search?q=OCO3_L2_Lite_FP)
5. TROPOMI NO2 data (https://search.earthdata.nasa.gov/search?q=S5P_L2__NO2____1)

## operations
STEPS:

Download code
============
```
git clone --recursive https://github.com/dogtorXiao/WRF-XSTILT_Inversion.git
```

A. SHARED CONFIGURATIONS
============
Shared parameters setting:
    >* `key`: input a google map api key and insert into [file](https://github.com/uataq/X-STILT/blob/cea1d2e70a21241be753e841144b3393a0d2d546/insert_ggAPI.csv)
    >* `site`, `site_lon_lat`: Find the geolocation information in google maps (https://www.google.com/maps) (find the latitude and longitude, set `site`, `site_lon_lat`)
    >* `timestr`: OCO-3 overpass time in 'YYYYMMDD'
    >* `trp_path`: TROPOMI data path; `raob_path`: radiosonde data path; `tiff.path`: ODIAC data path; `met_path`: arl format meteorology data path

B. PREPARATIONS
============

B1. `FORWARD_RUN = T`
    1. Use the X-STILT forward function to get a sense of how the downwind domain looks like (usually just take a few minites)
        >* `run_forward = T`: `box.len`, `dtime.from`, `dtime.to`, `dtime.sep`, `nhrs_forward` required
    2. Plot the downwind domain, segmentation the inside pixels, and click the pixels farthest away from the point sources (up to 40) as a set of samples. Get the X-STILT backgrounds and background errors.
        >* `run_bg_xstilt = T`: `td`
    3. Segmentation the forward plume downwind domain (manually click the plume edge, interactive GUI in need):
        >* `run_seg = T`
B2. `SAMPLE_RUN = T` (optional)
    1. Release the particles at the samples to run for plenty of time with X-STILT backward function
        >* `run_sample_xstilt = T`
    2. Calculate the time period needed to run X-STILT and the average PBL height. Determine the scaling factor for the PBL height (zisf) with any observations you have (if there is no data available, skip this step)
        >* `run_PBL_nhrs_calc = T`

C. MAIN X-STILT RUN
============
`MAIN_RUN = T`
    1. Decide the standard zisf and turbulented zisfs to run X-STILT for multiple times (vertical error)
        >* `run_ver_main = T`: `zisfs` (vector, the standard and turbulent scaling factors of the PBL heights), `zisf_indx` (the index of zisfs), `nhrs_back`, `minagl`, `maxagl`
    2. The wind error running (using the radiosonde data) (transport error)
        >* `run_wind_main = T`

D. POST DATA PROCESSING
============
`POST_RUN = T`
    1. Calculate the simulated XCO2 and transport errors (With ODIAC emission inventory as the prior), merge the observed, convolved, and turbulented XCO2, plot the XCO2 and observation minus simulation difference
        >* `bg` : the CO2 background

E. INVERSION
============
`INVERSION_RUN = T`
Parameters setting:
    >* `bg`, `bg_uncert`: the CO2 background and uncertainty obtained from NO2 mask or X-STILT forward function
    >* `spriorisf`: the ratio between the prior unertainty and the prior emissions; `length_scale_priori`: prior uncertainty length scale in km; `length_scale_obs`: observation uncertainty length scale in km; `domain_opt_deg`: box area for the optimization as the prior emission vector (in degree)
    1. Extract the NO2 data within the `bg_radius` (in km), select the NO2 plume, manually click the NO2 plume (interactive GUI required), extract the OCO-3 CO2 pixels inside the NO2 plume
        >* `run_no2_dealing = T`: `buff_deg`, `bg_radius`: for NO2 plume masking
    2. Conduct the inversion (The point source is very sensitive compared to area fluxes, while the SAM mode observations provides more than 1000 pixels around the point source, most of which are easy to introduce uncertainties. Therefore, select the pixels in the inversion is crucial. Here we provided 2 methods: 
        ### only select the pixels inside the near-time TROPOMI NO2 pulmes. Before conducting the inversion, please plot the NO2 plumes and segmentation the OCO-3 pixels, calculate the background background errors
        ### select all the pixels in the downwind domain)
        >* `run_inversion = T`: `inversion_recp` (`inversion_recp = recp_fn`: inversion using all pixels in the X-STILT forward downwind domain, `inversion_recp = recp_fn_in_NO2`: inversion using only pixels in the NO2 plume mask)
