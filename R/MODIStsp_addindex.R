#' MODIStsp_addindex
#' @description Function used to add a user-defined Spectral Index to the default list of computable spectral indexes
#' Execution without the GUI (i.e., to add a new index from a script) is also possible (see examples)
#' @details The function asks the user to provide the info related to the new desired Spectral Index using a GUI interface,
#' checks for correctness of provided information (e.g., correct bandnames, computable formula, etc...). If the index is legit,
#' it modifies the MODIStsp_Previous.RData file so to allow computation of the additional index within MODIStsp.
#' To remove all custom-added spectral indexes, simply delete the MODIStsp_Previous.RData file within the /Previous subfolder of the
#' folder in which the package was installed, or the alternative JSON specified by the parameter "option_jsfile".
#' The function can be run either from within the main MODIStsp GUI, or a standalone script. In the latter case, it modifies either the
#' MODIStsp_Previous.RData options file, or the options_file specified by the user, to add the new index.
#' @param option_jsfile settings (optional): full path of the JSON file containing the processing options in which the new indexes
#'  are saved (default: MODIStsp_Previous.JSON in subdir Previous).
#' @param prodopts_file settings (optional): full path of the RData file containing products description
#' (default: MODIStsp_ProdOpts.RData in subdir Previous)
#' @param selprod settings (optional): Name of the product to which the new index should be added. (Note: the index will be added to all other
#' products allowing its computation !)
#' @param selvers settings (optional): Version of the product to which the new index should be added.
#' @param gui logical value (default: TRUE): if TRUE, the GUI is opened to define the new index; otherwise use the "new_indexbandname",
#'  "new_indexfullname" and "new_indexformula" parameters to define it non-interactively.
#' @param new_indexbandname (optional if gui=TRUE): short name (acronym) of the new spectral index.
#' @param new_indexfullname (optional if gui=TRUE): extended name of the new spectral index.
#' @param new_indexformula (optional if gui=TRUE): string containing the formula of the new spectral indexes. Variables accepted to
#'  compute it are the names of the bands: b1_Red, b2_NIR, b3_Blue, b4_Green, b5_SWIR, b6_SWIR and b7_SWIR.
#' @param new_indexnodata_out (optional): nodata value to assign to the rasters containing the new index
#' @param MODIStsp_dir (optional): main folder containing MODIStsp R files (used only to launche MODSItsp from outside the package using MODIStsp_std.R)
#' @import gWidgets
#' @importFrom pacman p_load p_exists
#' @importFrom XML xmlParse xmlRoot xmlSize xmlToList
#' @importFrom stringr str_detect
#' @return NULL - the MODIStsp_Previous.RData file is modified so to allow computation of the additional index
#'
#' @author Lorenzo Busetto, phD (2014-2015) \email{busetto.l@@irea.cnr.it}
#' @author Luigi Ranghetti, phD (2015) \email{ranghetti.l@@irea.cnr.it}
#' @note License: GPL 3.0
#' @export
#'
#' @examples
#' # Run the GUI to interactively define the function
#'  \dontrun{
#'  MODIStsp_addindex()}
#'
#' # Run the GUI and save the new index in a custom RData file
#' \dontrun{
#' MODIStsp_addindex(option_jsfile = "X:/yourpath/youroptions.json")}
#'
#' # Define the new index non-interactively
#' \dontrun{
#' MODIStsp_addindex(gui = FALSE, new_indexbandname = "SSD",
#'   new_indexfullname = "Simple Stupid Difference",
#'   new_indexformula = "b2_NIR-b1_Red")}
#'
#'

MODIStsp_addindex <- function(option_jsfile=NA, prodopts_file=NA, selprod = NA, selvers = NA, gui=TRUE, new_indexbandname="", new_indexfullname="",
                              new_indexformula="", new_indexnodata_out = "32767", MODIStsp_dir = NA) {

  # Initialization and retrieval of parameters ----
  if (gui) {
    if (!p_exists("gWidgetsRGtk2", local = TRUE)) {
      #inst_gw <- utils::winDialog("Library 'gWidgetsRgtk2' is not installed. It is required to run MODIStsp ! \n \n Do you want to install it now ?", type = "yesno")
      message("Library 'gWidgetsRgtk2' is not installed. It is required to run MODIStsp!
              \n\nDo you want to install it now?", type = " y / n")
      inst_gw <- readline()
      if (inst_gw == "y") {
        p_load("gWidgetsRGtk2")
      } else {
        stop("MODIStsp can not work in Interactive mode withouth gWidgetsRGtk2 ! Exiting !")
      }

    }
    # requireNamespace("gWidgetsRGtk2")
    options("guiToolkit" = "RGtk2")
  }

  if (is.na(MODIStsp_dir)) {
    MODIStsp_dir <- system.file(package = "MODIStsp")
  }
  previous_dir <- file.path(MODIStsp_dir,"Previous")
  previous_jsfile <- ifelse(is.na(option_jsfile), file.path(previous_dir, "MODIStsp_Previous.json"), option_jsfile)
  general_opts <- RJSONIO::fromJSON(previous_jsfile)

  # Restore MODIS products if existing, otherwise retrieve data from xml file ----
  prod_opt_list <- get(load(prodopts_file))
  n_products <- length(prod_opt_list) #how many product available ? = elements in root

  # Valid names for reflectance bands
  refbands_names <- c("b1_Red","b2_NIR","b3_Blue","b4_Green","b5_SWIR","b6_SWIR", "b7_SWIR")

  # Names of bands available for product selected
  avail_prodbands <- prod_opt_list[[selprod]][[selvers]]$bandnames

  # reflectence bands available for product selected
  match_refbands <- avail_prodbands[match(refbands_names, avail_prodbands)]
  avail_refbands <- match_refbands[!is.na(match_refbands)]
  # Function to check for errors in formula ----
  # (it is called from GUI when "Add" button is chosen, or when function starts in non-interactive mode
  check_formula_errors <- function(new_indexbandname, new_indexfullname, new_indexformula,
                                   n_products, prod_opt_list, refbands_names) {

    catch_err <- 0 # error 0: no errors

    # Check that both the name, the fullname and the formula fields are not null
    if (new_indexbandname == "" | new_indexfullname == "" | new_indexformula == "") {
      catch_err <- 3 # error 3: parameters blank
    }

    # Look for valid band names in index formula
    req_bands <- c(str_detect(new_indexformula,"b1_Red"),
                   str_detect(new_indexformula,"b2_NIR"),
                   str_detect(new_indexformula,"b3_Blue"),
                   str_detect(new_indexformula,"b4_Green"),
                   str_detect(new_indexformula,"b5_SWIR"),
                   str_detect(new_indexformula,"b6_SWIR"),
                   str_detect(new_indexformula,"b7_SWIR"))

    # Create dummy varaibles named as the required bands, assign random values to the
    # them, and then verify if formula is copmputable by evaluate/parse and check for errors

    if (req_bands[1] == TRUE) {b1_Red   <- 5 }
    if (req_bands[2] == TRUE) {b2_NIR   <- 6 }
    if (req_bands[3] == TRUE) {b3_Blue  <- 7 }
    if (req_bands[4] == TRUE) {b4_Green <- 8 }
    if (req_bands[5] == TRUE) {b5_SWIR  <- 9 }
    if (req_bands[6] == TRUE) {b6_SWIR  <- 15}
    if (req_bands[7] == TRUE) {b7_SWIR  <- 25}

    if (max(req_bands == 1)) {
      try_parse <- try(eval(parse(text = new_indexformula)), silent = TRUE)
      if (class(try_parse) == "try-error") {
        catch_err <- 1
      }
    } else {
      catch_err <- 1
    } # error 1: error in the formula

    ## generate the list of all the index names
    all_indexes_bandnames <- all_indexes_fullnames <- NA
    for (prod in names(prod_opt_list)) {  # cycle on available products
      for (vers in names(prod_opt_list[[prod]])) {  # cycle on available product versions
        all_indexes_bandnames <- c(all_indexes_bandnames, as.list(prod_opt_list[[prod]][[vers]])$indexes_bandnames)
        all_indexes_fullnames <- c(all_indexes_fullnames, as.list(prod_opt_list[[prod]][[vers]])$indexes_fullnames)
        if (!is.null(general_opts$custom_indexes[[prod]][[vers]])) {
          all_indexes_bandnames <- c(all_indexes_bandnames, as.list(general_opts$custom_indexes[[prod]][[vers]])$indexes_bandnames)
          all_indexes_fullnames <- c(all_indexes_fullnames, as.list(general_opts$custom_indexes[[prod]][[vers]])$indexes_fullnames)
        }
      }
    }
    all_indexes_bandnames <- unique(all_indexes_bandnames)
    all_indexes_fullnames <- unique(all_indexes_fullnames)

    # verify that the index name and fullname is not already present
    if ((new_indexbandname %in% all_indexes_bandnames | new_indexfullname %in% all_indexes_fullnames) & catch_err == 0) {
      catch_err <- 2 # error 2: index name or fullname already present
    }
    # verify that the index is computable for the selected product
    if (catch_err == 0) {
      if (is.na(max(match(refbands_names[req_bands], avail_refbands)))) { # see if any of the bands required for the new index are NOT available for the product
        catch_err <- 1  # error 1 again: index is ok, but not computable for the currently selected product so we don't save it !
      }
    }

    attr(catch_err,"req_bands") <- req_bands
    return(catch_err)

  } # end of check_formula_errors()

  # Function to add the formula in previous file ----
  # (it is called if no errors are detected)
  save_formula <- function(refbands_names, req_bands, new_indexbandname, new_indexfullname,
                           new_indexformula, new_indexnodata_out, general_opts, prod_opt_list, previous_jsfile) {

    # initialise list of custom indexes, if it does not exist yet
    if (is.null(general_opts$custom_indexes)) {
      general_opts$custom_indexes <- list()
      
      for (prod in names(prod_opt_list)) {
        general_opts$custom_indexes[[prod]] <- list()
        
        for (vers in names(prod_opt_list[[prod]])) {
          general_opts$custom_indexes[[prod]][[vers]] <- list()
          general_opts$custom_indexes[[prod]][[vers]]$indexes_bandnames <-
            general_opts$custom_indexes[[prod]][[vers]]$indexes_fullnames <-
              general_opts$custom_indexes[[prod]][[vers]]$indexes_formulas <-
               general_opts$custom_indexes[[prod]][[vers]]$indexes_nodata_out <-
                 character(0)
        }
      }
    }

    for (prod in names(prod_opt_list)) {  # cycle on available products
      for (vers in names(prod_opt_list[[prod]])) {  # cycle on available product versions

        # check if bands required for index computation are available for the product
        check <- 0
        for (reqband in refbands_names[req_bands]) {
          if (reqband %in% prod_opt_list[[prod]][[vers]]$bandnames) {
            check <- check + 1
          }
        } #End Cycle on reqband

        # if all required bands are available in product, add the new index to the indexes list for the product in the previous_opts file.
        # in this way, at next execution, the new index should be available. Moreover, loading and use of old RData options files
        # won't be broken if an index is added later than their creation.
        n_req_bands <- sum(req_bands)
        if (n_req_bands == check ) {
          tmp_indexes_bandnames <- c(as.list(general_opts$custom_indexes[[prod]][[vers]])$indexes_bandnames,new_indexbandname)
          tmp_indexes_fullnames <- c(as.list(general_opts$custom_indexes[[prod]][[vers]])$indexes_fullnames,new_indexfullname)
          tmp_indexes_formulas <- c(as.list(general_opts$custom_indexes[[prod]][[vers]])$indexes_formulas,new_indexformula)
          tmp_indexes_nodata_out <- c(as.list(general_opts$custom_indexes[[prod]][[vers]])$indexes_nodata_out,new_indexnodata_out)

          general_opts$custom_indexes[[prod]][[vers]] <- list("indexes_bandnames"  = tmp_indexes_bandnames,
                                                              "indexes_fullnames"  = tmp_indexes_fullnames,
                                                              "indexes_formulas"   = tmp_indexes_formulas,
                                                              "indexes_nodata_out" = tmp_indexes_nodata_out)
          rm(tmp_indexes_bandnames,tmp_indexes_fullnames,tmp_indexes_formulas,tmp_indexes_nodata_out)
        }
      }
    }  #End Cycle on products

    # Save the products list and the chars of the products in previous file
    write(RJSONIO::toJSON(general_opts),previous_jsfile)

    return(general_opts)

  } # end of save_formula()


  # GUI Initialization -----
  if (gui) {

    main_win <- gbasicdialog(title = "Insert the new Spectral Index information and formula", parent = NULL, do.buttons = FALSE,
                             visible = TRUE, spacing = 10, handler = function(h,...) {# If "Start" pressed, retrieve selected values and save in previous file
                             })

    main_group <- ggroup(container = main_win, horizontal = FALSE, expand = TRUE)

    indexbandname_group <- ggroup(container = main_group, horizontal = T, expand = TRUE)
    indexbandname_label <- glabel(text = "Spectral Index Acronym (e.g., SR)", markup = TRUE, container = indexbandname_group)
    size(indexbandname_label) <- c(500,20)
    font(indexbandname_label) <- list(family = "sans", size = 10 , weight = "bold")
    sel_indexbandname <- gedit(text = new_indexbandname, label = "Please Insert a valid Proj4 string        ",
                               container = indexbandname_group, size = 800, horizontal = TRUE)

    indexbandfullname_group <- ggroup(container = main_group, horizontal = TRUE, expand = TRUE)
    indexbandfullname_label <- glabel(text = "Spectral Index Full Name (e.g., Simple Ratio (b2_NIR/b1_Red))", markup = TRUE,
                                      container = indexbandfullname_group)
    size(indexbandfullname_label) <- c(500,20)
    font(indexbandfullname_label) <- list(family = "sans", size = 10 , weight = "bold")

    sel_indexbandfullname <- gedit(text = new_indexfullname, container = indexbandfullname_group, size = 800, horizontal = TRUE)

    indexformula_group <- ggroup(container = main_group, horizontal = TRUE, expand = TRUE)
    indexformula_label <- glabel(text = "Spectral Index Formula (e.g., (b2_NIR/b1_Red) )", markup = TRUE,
                                 container = indexformula_group)
    size(indexformula_label) <- c(500,20)
    font(indexformula_label) <- list(family = "sans", size = 10 , weight = "bold")
    sel_indexformula <- gedit(text = new_indexformula, container = indexformula_group, size = 800, horizontal = TRUE)

    # help_lab <- glabel(text = paste0("Valid band names for this product: ", paste(avail_refbands,collapse = ", ")), container = main_group, size = 800, horizontal = TRUE)
    # font(help_lab)  <- list(family = "sans", style = "italic", size = 8)
    #

    # Button for testing the new index
    but_group <- ggroup(container = main_group, horizontal = TRUE)

    set_but <- gbutton(text = "---  Set New Index  ---", container = but_group, handler = function(h,...) {# If "Start" pressed, retrieve selected values and save in previous file

      new_indexbandname <- svalue(sel_indexbandname)
      new_indexfullname <- svalue(sel_indexbandfullname)
      new_indexformula  <- svalue(sel_indexformula)
      # Check if formual is good. If so, add it in the options file ----
      # for products for which the formula is computable (i.e., they have the required bands)
      
      catch_err <- check_formula_errors(new_indexbandname = new_indexbandname, 
                                        new_indexfullname = new_indexfullname, 
                                        new_indexformula = new_indexformula,
                                        n_products = n_products, 
                                        prod_opt_list = prod_opt_list, 
                                        refbands_names = refbands_names)
      
      if (catch_err == 0) {
        
        save_formula(refbands_names = refbands_names, 
                     req_bands = attr(catch_err,"req_bands"),
                     new_indexbandname = new_indexbandname, 
                     new_indexfullname = new_indexfullname, 
                     new_indexformula = new_indexformula,
                     new_indexnodata_out = new_indexnodata_out, 
                     general_opts = if (exists("general_opts")) general_opts else NULL,
                     prod_opt_list = prod_opt_list, 
                     previous_jsfile = previous_jsfile)
      } 
      # Issue error warnings if something went wrong !!!!

      switch(as.character(catch_err),
             "0" = svalue(notes_lab) <- format("The new Spectral Index was correctly added! To use it, click 'DONE', then \nre-open the 'Select Processing Layer' Window.", justify = "centre"),
             "1" = svalue(notes_lab) <- format(paste0("ERROR ! The Formula of the new Index is not computable. Please check it !\nValid Band Names are: ", paste(avail_refbands,collapse = ", "),"."), justify = "centre"),
             "2" = svalue(notes_lab) <- format("ERROR ! The Index Acronym and/or its full name are already present.\n Please specify different ones.", justify = "centre"),
             "3" = svalue(notes_lab) <- format("ERROR ! Please provide valid values for the Index Acronym, its fullname and the Formula.", justify = "centre"))
      # font(notes_lab) <- list(family = "sans", style = "italic", size = 9, color = 'blue')
      ifelse(as.character(catch_err) == "0", font(notes_lab) <- list(family = "sans", size = 9, weight = 'bold'),
             font(notes_lab) <- list(family = "sans", size = 9, weight = 'bold', color = 'red', style = "italic"))
    })

    size(set_but) <- list(width = 500)
    font(set_but) <- list(family = "sans", size = 10 , color = "red", weight = "bold")
    addSpace(main_group, 3)
    notes_frame <- gframe(text = "--- Hints ---", pos = 0.5, container = main_group, horizontal = TRUE, expand = TRUE)
    notes_group <- ggroup(container = notes_frame,  expand = TRUE, horizontal = FALSE)
    notes_lab   <- glabel(text = format(paste0("Valid band names are: ", paste(avail_refbands,collapse = ", ")), justify = "centre"),
                          container = notes_group, horizontal = TRUE, editable = FALSE)
    size(notes_lab) <- c(600,35)
    font(notes_lab)  <- list(family = "sans",  size = 9, weight = 'bold')


    addSpring(but_group)
    finish_but <- gbutton(text = "Done !", container = but_group, handler = function(h,...) {

      dispose(main_win)
      gmessage("ReOpen the 'Select Layers' window to use the new index(es)", title = "Done !")
      return(TRUE)
    }
    )
    font(finish_but)  <- list(family = "sans",  weight = "bold")
    visible(main_win, set = TRUE)

    # end of gui actions ----
    # Actions on non-interactive execution
  } else {

    # Check if formual is good. If so, add it in the options file ----
    # for products for which the formula is computable (i.e., they have the required bands)
    catch_err <- check_formula_errors(new_indexbandname = new_indexbandname, new_indexfullname = new_indexfullname, new_indexformula = new_indexformula,
                                      n_products = n_products, prod_opt_list = prod_opt_list, refbands_names = refbands_names)
    if (catch_err == 0) {

      save_formula(refbands_names = refbands_names, req_bands = attr(catch_err,"req_bands"),
                   new_indexbandname = new_indexbandname, new_indexfullname = new_indexfullname, new_indexformula = new_indexformula,
                   new_indexnodata_out = new_indexnodata_out, general_opts = if (exists("general_opts")) general_opts else NULL,
                   prod_opt_list = prod_opt_list, previous_jsfile = previous_jsfile)
      message("The new Index was correctly added! It will be available from the next running of MODIStsp().")
    } else if (catch_err == 1) {
      stop(paste0("The formula of the new index is not computable for this product. Please check it (Valid band names or this product are: ",paste(avail_refbands,collapse = ", "),"."))
    } else if (catch_err == 2) {
      stop("The index acronym and/or the full name are already present; please specify different ones.")
    } else if (catch_err == 3 ) {
      stop("Some parameters are still blank; please provide valid values for the index name, the index fullname and the formula.")
    }

  } # end of non-gui actions

}
