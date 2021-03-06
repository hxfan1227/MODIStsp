% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/MODIStsp_process.R
\name{MODIStsp_process}
\alias{MODIStsp_process}
\title{MODIStsp_process}
\usage{
MODIStsp_process(sel_prod, start_date, end_date, out_folder, out_folder_mod,
  reprocess = "Yes", delete_hdf = "No", sensor, download_server, user,
  password, https, ftps, start_x, start_y, end_x, end_y, bbox, out_format,
  compress, out_res_sel, out_res, native_res, tiled, MOD_proj_str, outproj_str,
  nodata_in, nodata_out, nodata_change, rts, datatype, bandsel, bandnames,
  indexes_bandsel, indexes_bandnames, indexes_formula, indexes_nodata_out,
  quality_bandnames, quality_bandsel, quality_bitN, quality_source,
  quality_nodata_in, full_ext, quality_nodata_out, file_prefixes,
  main_out_folder, resampling, ts_format, gui = TRUE, use_aria = TRUE)
}
\arguments{
\item{sel_prod}{string selected MODIS product}

\item{start_date}{string start_date for images download and preproc (yyyy.mm.dd)}

\item{end_date}{string end_date for images download and preproc (yyyy.mm.dd)}

\item{out_folder}{main ouput folder}

\item{out_folder_mod}{ouput folder for original HDF storage}

\item{reprocess}{string string ("Yes"/"No") If Yes, reprocess data for already existing dates (Default = 'Yes')}

\item{delete_hdf}{string ("Yes"/"No") If Yes, delete original hdf after completion}

\item{sensor}{string ("Terra" or "Aqua" or "Both")}

\item{download_server}{service used to download MODIS tiles, one of: 'http', 'ftp', NA.}

\item{user}{Username for http download (https://urs.earthdata.nasa.gov/home)}

\item{password}{Password for http download (https://urs.earthdata.nasa.gov/home)}

\item{https}{hash https site for download of hdf of selected product}

\item{ftps}{hash ftps site for download of hdf of selected product}

\item{start_x}{int start horiz. tile}

\item{start_y}{int start vertical. tile}

\item{end_x}{int end horiz. tile}

\item{end_y}{int end vertical. tile}

\item{bbox}{array output bounding box (xmin, xmax, ymin, ymax ) in out proj coords}

\item{out_format}{string output raster format (ENVI or GTiff)}

\item{compress}{string compression for GTiff outputs (None, LZW, DEFLATE)}

\item{out_res_sel}{string "Native" or "Resampled"}

\item{out_res}{float Output resolution (in output projection measurement unit)}

\item{native_res}{float Native resolution of MODIS product}

\item{tiled}{0/1 1 = tiled product; 0 = nontiled product (resolution 0.05 deg)}

\item{MOD_proj_str}{string proj4 string for MODIS product native projection (? Check ! for product in geographic !)}

\item{outproj_str}{string proj4 string of selected output projection}

\item{nodata_in}{array Original nodata for MODIS bands}

\item{nodata_out}{Target nodata for MODIS bands}

\item{nodata_change}{string (Yes/No) if Yes, nodata are set to nodata_out in output rasters}

\item{rts}{string ("Yes"/"No") If Yes, create rts time series}

\item{datatype}{string array datatypes of MODIS bands}

\item{bandsel}{array of lenght equal to number of original modis layers. set to 1 for bands to be processed}

\item{bandnames}{array of Abbreviated Names of MODIS bands}

\item{indexes_bandsel}{array of lenght equal to number of available spectral indexes, set to  1 for indexes to be processed}

\item{indexes_bandnames}{array of Abbreviated Names of MODIS indexes}

\item{indexes_formula}{array of indexes formulas}

\item{indexes_nodata_out}{Nodata values for indexes}

\item{quality_bandnames}{array of  Names of MODIS quality indicators}

\item{quality_bandsel}{array of lenght equal to number of available quality indicators, set to  1 for indicators to be processed}

\item{quality_bitN}{list of strings with number of entries equal to number of quality indicators. each entry caontains position of bits corresponding to a QI (e.g., 0-1)}

\item{quality_source}{list of strings which connects each quality indicator to its source aggregated quality assurance layer}

\item{quality_nodata_in}{Always 255}

\item{full_ext}{string ("Full_Ext" or "Resized")}

\item{quality_nodata_out}{Always 255}

\item{file_prefixes}{output file prefix according to selelected product (e.g., MOD13Q1)}

\item{main_out_folder}{Suffix to add to the overall out_folder to create the out dir for the product (corresponds to an abbreviation of the selected product)}

\item{resampling}{string resampling method (near, bilinear, etc.)}

\item{ts_format}{string format of virtual files (None, ENVI Meta Files, GDAL vrt files, ENVI and GDAL)}

\item{gui}{logical indicates if processing was called within the GUI environment or not. If not, direct processing messages to the log}

\item{use_aria}{logical if TRUE, then aria2c is used to accelerate download (if available !)}
}
\description{
main function of MODIStsp tool. Takes as input processing parameters specified by the user using MODIStsp_GUI and saved in
MODIStsp_Previous.json (Interactive use), or a user specified JSON file (batch use) (See MODIStsp_main for details ) and performs all required
processing.
}
\details{
After retrieving the input processing options, the function accesses lpdaac htttp archive to determine the list of dates
to be processed. It then perform all required processing steps on each date (download, reprojection, resize, mosaicing, indexes computation,
quality indicators computation), and finally performs virtual files creation. Checks are done in order to not re-download already existing HDF
images, and not reprocess already processed dates (if the user didn'specify that)
}
\note{
Thanks Tomislav Hengl and Babak Naimi, whose scripts made the starting point for development of this function ( http://r-gis.net/?q=ModisDownload ; .
http://spatial-analyst.net/wiki/index.php?title=Download_and_resampling_of_MODIS_images)

License: GPL 3.0
}
\author{
Lorenzo Busetto, phD (2014-2015) \email{busetto.l@irea.cnr.it}

Luigi Ranghetti, phD (2015) \email{ranghetti.l@irea.cnr.it}
}

