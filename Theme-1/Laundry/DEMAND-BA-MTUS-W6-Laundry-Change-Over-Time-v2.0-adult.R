############################################
# Data analysis for 'Laundry' paper:

# Use MTUS World 6 time-use data (UK subset) to examine:
# - distributions of laundry in 1985 & 2005
# - changing laundry practice
# Data source: www.timeuse.org/mtus
# data already in long format (but episodes)

# Uses FES/EFS/LCFS to examine:
# - historical ownership of washing machines/tumble dryers
# Data source: http://discover.ukdataservice.ac.uk/series/?sn=200016 

# Uses SPRG water practices survey:
# - reported laundry practices
# Data source: http://www.sprg.ac.uk/projects-fellowships/patterns-of-water

# This work was funded by RCUK through the End User Energy Demand Centres Programme via the
# "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, gow.epsrc.ac.uk/NGBOViewGrant.aspx?GrantRef=EP/K011723/1)

#     Copyright (C) 2014  University of Southampton
#     Author: Ben Anderson (b.anderson@soton.ac.uk, @dataknut, https://github.com/dataknut)

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License 
# (http://choosealicense.com/licenses/gpl-2.0/), or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# MTUS codes of interest:
# 1983/4/7: Main/Sec21 Laundry, ironing, clothing repair
# <- 0701 Wash clothes, hang out / bring in washing
# 	0702 Iron clothes
# 	0801 Repair, upkeep of clothes
# so may over-estimate laundry

# 2005:	Main/Sec21 Laundry, ironing, clothing repair <- Pact=7 (washing clothes)

# Housekeeping ----
# clear out all old objects etc to avoid confusion
rm(list = ls()) 

# add libraries
library(foreign) # as loading stata files
library(lattice) # fancy graphs
library(ggplot) # fancy graphs II
library(data.table) # why use anything else?
library(survey) # weighted survey analysis
library(gmodels) # nice crosstabs
library(fasttime) # VERY fast time string conversion to POSIXct 
                  # but only IF the input string is in a fixed format - see http://rforge.net/doc/packages/fasttime/fastPOSIXct.html

# set up some useful data paths
tudpath <- "~/Documents/Work/Data/MTUS/World 6/processed/"
efs1985path <- "~/Documents/Work/Data/Family Expenditure Survey/1985/stata8"
sprgpath <- "~/Documents/Work/Projects/ESRC-SPRG/WP4-Micro_water/data/sprg_survey/data/safe/v6"

rpath <- "~/Documents/Work/Papers and Conferences/The Time and Timing of Demand - Laundry/results"

# define laundry for time use data
laundry <- "laundry, ironing, clothing repair"

# Generic functions ----

# Feedback function - cos I can't be bothered to keep writing it out
feedBack <- function(string) {
  print(paste0("Feedback: ", string))
}

# FES data ----
# Needed for estimates of washing machine adoption in 1985
# Load as STATA file
efs1985file <- paste0(efs1985path, "/hchars.dta")
feedBack(paste0("Loading ", efs1985file))
efs1985_DT <- as.data.table(read.dta(efs1985file))

# a108            byte   %8.0g                  no of washing machines in h/h
wmachines <- table(efs1985_DT$a108)
prop.table(wmachines)

# TU data ----

loadMtusSurvey <- function() {
  sfile <- paste0(tudpath, "MTUS-adult-aggregate-UK-only-wf.dta")
  feedBack(paste0("Loading: ", sfile))
  MTUSW6UKsurvey_DT <- as.data.table(read.dta(sfile))
  setkey(MTUSW6UKsurvey_DT, diarypid)
  
  # create a reduced survey frame with the few variables we need so the join
  # does not break memory
  # use global assignment so we can see the DT for later use
  gMTUSW6UKsurveyCore_DT <<- MTUSW6UKsurvey_DT[, .(survey, countrya, swave, diarypid, pid, empstat, urban, 
                                                 badcase, nchild, sex, age, hhtype, hhldsize, income, propwt)
                                             ]
  feedBack("Summary of gMTUSW6UKsurveyCore_DT")
  print(summary(gMTUSW6UKsurveyCore_DT)) # force print from within function
#   # save out the table for later use if needed
#   outf <- paste0(tudpath,"/gMTUSW6UKsurveyCore_DT.csv")
#   feedBack(paste0("Saving processed MTUS survey data into: ", outf))
#   write.csv(gMTUSW6UKsurveyCore_DT, 
#             file = outf,
#             na = ""
#   )
  
  feedBack("Done loading TU survey data")
} # works

loadMtusEpisodes <- function() {
  # Load as STATA file
  mtusfile <- paste0(tudpath, "MTUS-adult-episode-UK-only-wf.dta")
  feedBack(paste0("Loading: ", mtusfile))
  mtusEpsDT <- as.data.table(read.dta(mtusfile))
  setkey(mtusEpsDT, diarypid)
  
  feedBack("Fixing episode dates")
  # The stata times are all loaded as POSIXct which is not all that helpful
  # Need to create a proper start/end time but 2005 does not have a valid date so we are forced to impute them
  # 2005 months:
  # March: synthetic week = Sunday 6th -> Saturday 12th
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "March"
    & mtusEpsDT$s_dow == "Sunday", "06/03/2005", "na"
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "March"
    & mtusEpsDT$s_dow == "Monday", "07/03/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "March"
    & mtusEpsDT$s_dow == "Tuesday", "08/03/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "March"
    & mtusEpsDT$s_dow == "Wednesday", "09/03/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "March"
    & mtusEpsDT$s_dow == "Thursday", "10/03/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "March"
    & mtusEpsDT$s_dow == "Friday", "11/03/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "March"
    & mtusEpsDT$s_dow == "Saturday", "12/03/2005", mtusEpsDT$date_2005
  )
  
  # June: 5th -> 11th
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "June"
    & mtusEpsDT$s_dow == "Sunday", "05/06/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "June"
    & mtusEpsDT$s_dow == "Monday", "06/06/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "June"
    & mtusEpsDT$s_dow == "Tuesday", "07/06/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "June"
    & mtusEpsDT$s_dow == "Wednesday", "08/06/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "June"
    & mtusEpsDT$s_dow == "Thursday", "09/06/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "June"
    & mtusEpsDT$s_dow == "Friday", "10/06/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "June"
    & mtusEpsDT$s_dow == "Saturday", "11/06/2005", mtusEpsDT$date_2005
  )
  
  # September: 4th -> 10th
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "September"
    & mtusEpsDT$s_dow == "Sunday", "04/09/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "September"
    & mtusEpsDT$s_dow == "Monday", "05/09/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "September"
    & mtusEpsDT$s_dow == "Tuesday", "06/09/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "September"
    & mtusEpsDT$s_dow == "Wednesday", "07/09/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "September"
    & mtusEpsDT$s_dow == "Thursday", "08/09/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "September"
    & mtusEpsDT$s_dow == "Friday", "09/09/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "September"
    & mtusEpsDT$s_dow == "Saturday", "10/09/2005", mtusEpsDT$date_2005
  )
  
  # November: 6th - 12th
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "November"
    & mtusEpsDT$s_dow == "Sunday", "06/11/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "November"
    & mtusEpsDT$s_dow == "Monday", "07/11/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "November"
    & mtusEpsDT$s_dow == "Tuesday", "08/11/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "November"
    & mtusEpsDT$s_dow == "Wednesday", "09/11/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "November"
    & mtusEpsDT$s_dow == "Thursday", "10/11/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "November"
    & mtusEpsDT$s_dow == "Friday", "11/11/2005", mtusEpsDT$date_2005
  )
  mtusEpsDT$date_2005 <- ifelse(
    mtusEpsDT$survey == 2005 & mtusEpsDT$mtus_month == "November"
    & mtusEpsDT$s_dow == "Saturday", "12/11/2005", mtusEpsDT$date_2005
  )
  
  # 2005 dates as POSIX - can't use fasttime
  mtusEpsDT$r_date_2005 <- as.POSIXct(mtusEpsDT$date_2005, tz = "",
                                        "%d/%m/%Y"
    )
  # check
  table(as.POSIXlt(mtusEpsDT$r_date_2005)$wday, mtusEpsDT$s_dow)
  
  # others dates as POSIX
  mtusEpsDT$r_date <- as.POSIXct(mtusEpsDT$s_date, tz = "",
                                           "%Y-%m-%d"
  )
  # check
  table(as.POSIXlt(mtusEpsDT$r_date)$wday, mtusEpsDT$s_dow)
  
  # combine the dates - why does this generate a number and not a POSIX?
  mtusEpsDT$r_date_n <- ifelse(
    mtusEpsDT$survey == 2005, 
    mtusEpsDT$r_date_2005, # if 2005
    mtusEpsDT$r_date # if not, date already set
  )
  
  # convert to POSIX
  mtusEpsDT$r_datef <- as.POSIXct(mtusEpsDT$r_date_n, origin = "1970-01-01")
  # check matches
  table(as.POSIXlt(mtusEpsDT$r_datef)$wday, 
        mtusEpsDT$s_dow, 
        useNA = "ifany"
  )
  feedBack("Setting up corrected start and end timestamps")
  # all diaries start at 04:00 on the date given
  # POSIXct works in seconds
  mtusEpsDT$r_epstart <- mtusEpsDT$r_datef + (3*60*60)
  # now add the corrected minutes up to the start of the episode
  mtusEpsDT$r_epstart <- mtusEpsDT$r_epstart + (mtusEpsDT$ba_startm*60)
  
  # same for episode end
  mtusEpsDT$r_epend <- mtusEpsDT$r_epstart + (mtusEpsDT$end*60)
  
  # define year (started)
  mtusEpsDT$r_year <- as.POSIXlt(mtusEpsDT$r_date)$year
  
  # keep the variables we need
  mtusEpsDT <- mtusEpsDT[, .(survey, swave, hldid, persid, id, diarypid, pid, 
                                                 diary, survey, r_year, badcase, sex, age, 
                                                 r_epstart, r_epend, time, epnum,
                                                 main, sec, inout, eloc, mtrav, child, sppart)
                                             ]
  
  # check the distribution of episodes by time of day and year of survey
  table("Hour" = as.POSIXlt(mtusEpsDT$r_epstart)$hour,
        "Year"= as.POSIXlt(mtusEpsDT$r_epstart)$year 
  )
  
  # set a new year variable to be:
  # 74 + 75 = drop 
  # 83 + 84 + 85 = 1985
  # 95 = drop
  # 100 + 101 = 2001 = drop
  # 105 = 2005
  feedBack("Making filter for years of interest")
  mtusEpsDT$ba_survey <- ifelse(
    mtusEpsDT$survey == 1983 | 
      mtusEpsDT$survey == 1987 , 
    1985, # if true
    NA # if not
  )
  
  mtusEpsDT$ba_survey <- ifelse(
    mtusEpsDT$survey == 2005 , 
    2005, # if true
    mtusEpsDT$ba_survey # if not
  )
  
  # check data for analysis in this paper (1985 -> 2005)
  print(
    table(mtusEpsDT$ba_survey, 
        mtusEpsDT$survey, 
        useNA = "ifany"
    )
  )
  
  # add hour & half hour of the start of the episode
  mtusEpsDT$st_hour <- as.POSIXlt(mtusEpsDT$r_epstart)$hour
  mtusEpsDT$st_hour <- ifelse(mtusEpsDT$st_hour < 10 , 
                                        paste0("0",mtusEpsDT$st_hour), # if true - add leading 0
                                        mtusEpsDT$st_hour # if not
  )
  mtusEpsDT$st_mins <- as.POSIXlt(mtusEpsDT$r_epstart)$min
  mtusEpsDT$st_hh <- ifelse(mtusEpsDT$st_mins < 30 , 
                                      "00", # if true
                                      "30" # if not
  )
  mtusEpsDT$st_halfhour <- paste0(mtusEpsDT$st_hour, 
                                            ":",
                                            mtusEpsDT$st_hh)
  # check
  with(mtusEpsDT,
       table(st_halfhour)
  )
  
  with(mtusEpsDT, 
       table(badcase,ba_survey)
  )
  feedBack("Keeping good cases")
  # Keep only good cases for 1985 & 2005
  mtusEpsDT <- mtusEpsDT[badcase == "good case"]
  mtusEpsDT <- mtusEpsDT[ba_survey %in% c("1985","2005")]
  
  # check
  print(
    with(mtusEpsDT, 
       table(badcase,ba_survey)
    )
  )
  # only keep the vars we need - saves memory etc and use global assignment for re-use elsewhere
  gMTUSW6UKdiaryEps_DT <<- mtusEpsDT[, .(ba_survey, diarypid, main, sec, time, st_halfhour)]
  feedBack("Summary of gMTUSW6UKdiaryEps_DT:")
  print(summary(gMTUSW6UKdiaryEps_DT))
  feedBack("Finished loading & fixing episodes data")
} # works

analyseMtusEpisodes <- function() {
  # Laundry = code 21
  laundry <- "laundry, ironing, clothing repair"
  # n episodes in total per year
  with(gMTUSW6UKdiaryEps_DT, 
       table(ba_survey)
  )
  # set a laundry code
  gMTUSW6UKdiaryEps_DT$laundry_p <- ifelse(gMTUSW6UKdiaryEps_DT$main == laundry,
                                          1, # laundry as main act
                                          0)
  gMTUSW6UKdiaryEps_DT$laundry_s <- ifelse(gMTUSW6UKdiaryEps_DT$sec == laundry,
                                          1, # laundry as main act
                                          0)
  gMTUSW6UKdiaryEps_DT$laundry_all <- ifelse(gMTUSW6UKdiaryEps_DT$main == laundry | gMTUSW6UKdiaryEps_DT$sec == laundry,
                                            1, # laundry as either act
                                            0)
  # totals
  with(gMTUSW6UKdiaryEps_DT,
       table(laundry_p, ba_survey))
  with(gMTUSW6UKdiaryEps_DT,
       table(laundry_s, ba_survey))
  with(gMTUSW6UKdiaryEps_DT,
       table(laundry_all, ba_survey))
  
  feedBack("# n episodes by duration - to show how recording period varies things")
  print(
    with(gMTUSW6UKdiaryEps_DT,
       xtabs(~ time + ba_survey))
  )
  feedBack("# n episodes of laundry as a primary act by duration (to show how recording period varies things)")
  print(
    with(gMTUSW6UKdiaryEps_DT,
       xtabs(laundry_p ~ time + ba_survey))
  )
  
  eps1985 <- length(gMTUSW6UKdiaryEps_DT$diarypid[gMTUSW6UKdiaryEps_DT$ba_survey == 1985]) # n episodes in 1985
  epslaundry1985 <- length(gMTUSW6UKdiaryEps_DT$diarypid[gMTUSW6UKdiaryEps_DT$ba_survey == 1985 & gMTUSW6UKdiaryEps_DT$laundry_all == 1])
  
  print(paste0("% episodes that are laundry_all in 1985 = ", (epslaundry1985/eps1985)*100))
  
  eps2005 <- length(gMTUSW6UKdiaryEps_DT$diarypid[gMTUSW6UKdiaryEps_DT$ba_survey == 2005]) # n episodes in 2005
  epslaundry2005 <- length(gMTUSW6UKdiaryEps_DT$diarypid[gMTUSW6UKdiaryEps_DT$ba_survey == 2005 & gMTUSW6UKdiaryEps_DT$laundry_all == 1])
  
  print(paste0("% episodes that are laundry_all in 2005 = ", (epslaundry2005/eps2005)*100))
  
  # work with split files - easier?
  eps_1985DT <- gMTUSW6UKdiaryEps_DT[gMTUSW6UKdiaryEps_DT$ba_survey == 1985]
  eps_2005DT <- gMTUSW6UKdiaryEps_DT[gMTUSW6UKdiaryEps_DT$ba_survey == 2005]
  
  # when do most episodes start in 1985?
  alleps_byhh1985 <- eps_1985DT[main == laundry, 
                                .(
                                  N_episodes1985 = length(st_halfhour), #n episodes starting in a given half hour
                                  Pr_episodes1985 = length(st_halfhour)/eps1985 # proportion of all episodes in that year starting...
                                ), 
                                by = .(
                                  Start = st_halfhour
                                )
                                ]
  setkey(alleps_byhh1985,Start)
  feedBack("Plotting 1985 all episodes start")
  plot(alleps_byhh1985$Pr_episodes)
  
  # and laundry episodes?
  laundryeps_byhh1985 <- eps_1985DT[main == laundry, 
                                    .(
                                      N_episodes1985 = length(st_halfhour), #n episodes starting in a given half hour
                                      Pr_episodes1985 = length(st_halfhour)/eps1985 # proportion of all episodes in that year starting...
                                    ), 
                                    by = .(
                                      Start = st_halfhour
                                    )
                                    ]
  setkey(laundryeps_byhh1985,Start)
  feedBack("Plotting 1985 laundry episodes start")
  plot(laundryeps_byhh1985$Pr_episodes)
  
  # when do most episodes start in 2005?
  alleps_byhh2005 <- eps_2005DT[, 
                                .(
                                  N_episodes2005 = length(st_halfhour), #n episodes starting in a given half hour
                                  Pr_episodes2005 = length(st_halfhour)/eps2005 # proportion of all episodes in that year starting...
                                ), 
                                by = .(
                                  Start = st_halfhour
                                )
                                ]
  setkey(alleps_byhh2005,Start)
  feedBack("Plotting 2005 all episodes start")
  plot(alleps_byhh2005$Pr_episodes)
  
  # and laundry episodes?
  laundryeps_byhh2005 <- eps_2005DT[main == laundry, 
                                    .(
                                      N_episodes2005 = length(st_halfhour), #n episodes starting in a given half hour
                                      Pr_episodes2005 = length(st_halfhour)/eps2005 # proportion of all episodes in that year starting...
                                    ), 
                                    by = .(
                                      Start = st_halfhour
                                    )
                                    ]
  setkey(laundryeps_byhh2005,Start)
  feedBack("Plotting 2005 laundry episodes start")
  plot(laundryeps_byhh2005$Pr_episodes)
  
  # join tables for ease of comparison
  # ideally these need to be weighted & need 95% CIs for proportions
  laundryeps_byhh <- laundryeps_byhh2005[laundryeps_byhh1985]
  laundryeps_byhh$diff <- laundryeps_byhh$Pr_episodes2005 - laundryeps_byhh$Pr_episodes1985
  plot(laundryeps_byhh$diff)
  
  # use ggplot to make a nice plot of 1985, 2005 & difference?
  
  outf <- paste0(rpath,"/laundryeps_byhh.csv")
  feedBack(paste0("Saving episodes results into: ", rpath))
  write.csv(laundryeps_byhh, 
            file = outf,
            na = ""
  )

  feedBack("Done analysing episode file")
} # works

loadMtusSampled <- function() {
  
  # This was created in STATA - will port to R at some point
  sampledmtus <- paste0(tudpath, "MTUS-adult-episode-UK-only-wf-10min-samples-long-v1.0.dta")
  feedBack(paste0("Loading: ", sampledmtus))
  mtusSampDT <- as.data.table(read.dta(sampledmtus))
  setkey(mtusSampDT, diarypid)
  
  feedBack("Fixing sampled dates")
  # re-run date & time re-formatting as before
  feedBack("Fixing sampled dates: March")
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "March"
    & mtusSampDT$s_dow == "Sunday", "2005-March-06", "na"
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "March"
    & mtusSampDT$s_dow == "Monday", "2005-March-07", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "March"
    & mtusSampDT$s_dow == "Tuesday", "2005-March-08", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "March"
    & mtusSampDT$s_dow == "Wednesday", "2005-March-09", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "March"
    & mtusSampDT$s_dow == "Thursday", "2005-March-10", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "March"
    & mtusSampDT$s_dow == "Friday", "2005-March-11", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "March"
    & mtusSampDT$s_dow == "Saturday", "2005-March-12", mtusSampDT$date_2005
  )
  feedBack("Fixing sampled dates: June")
  # June: 5th -> 11th
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "June"
    & mtusSampDT$s_dow == "Sunday", "2005-June-05", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "June"
    & mtusSampDT$s_dow == "Monday", "2005-June-06", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "June"
    & mtusSampDT$s_dow == "Tuesday", "2005-June-07", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "June"
    & mtusSampDT$s_dow == "Wednesday", "2005-June-08", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "June"
    & mtusSampDT$s_dow == "Thursday", "2005-June-09", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "June"
    & mtusSampDT$s_dow == "Friday", "2005-June-10", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "June"
    & mtusSampDT$s_dow == "Saturday", "2005-June-11", mtusSampDT$date_2005
  )
  feedBack("Fixing sampled dates: September")
  # September: 4th -> 10th
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "September"
    & mtusSampDT$s_dow == "Sunday", "2005-September-04", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "September"
    & mtusSampDT$s_dow == "Monday", "2005-September-05", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "September"
    & mtusSampDT$s_dow == "Tuesday", "2005-September-06", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "September"
    & mtusSampDT$s_dow == "Wednesday", "2005-September-07", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "September"
    & mtusSampDT$s_dow == "Thursday", "2005-September-08", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "September"
    & mtusSampDT$s_dow == "Friday", "2005-September-09", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "September"
    & mtusSampDT$s_dow == "Saturday", "2005-September-10", mtusSampDT$date_2005
  )
  feedBack("Fixing sampled dates: November")
  # November: 6th - 12th
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "November"
    & mtusSampDT$s_dow == "Sunday", "2005-November-06", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "November"
    & mtusSampDT$s_dow == "Monday", "2005-November-07", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "November"
    & mtusSampDT$s_dow == "Tuesday", "2005-November-08", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "November"
    & mtusSampDT$s_dow == "Wednesday", "2005-November-09", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "November"
    & mtusSampDT$s_dow == "Thursday", "2005-November-10", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "November"
    & mtusSampDT$s_dow == "Friday", "2005-November-11", mtusSampDT$date_2005
  )
  mtusSampDT$date_2005 <- ifelse(
    mtusSampDT$survey == 2005 & mtusSampDT$mtus_month == "November"
    & mtusSampDT$s_dow == "Saturday", "2005-November-12", mtusSampDT$date_2005
  )
  
  feedBack("Set up character hours/mins/secs so POSIXct recognises them")
  mtusSampDT$start_hour <- as.POSIXlt(mtusSampDT$s_starttime)$hour
  mtusSampDT$start_hour <- ifelse(mtusSampDT$start_hour < 10,
                                               paste0("0",mtusSampDT$start_hour), # < 10
                                               mtusSampDT$start_hour # not < 10
  )
  mtusSampDT$start_min <- as.POSIXlt(mtusSampDT$s_starttime)$min
  mtusSampDT$start_min <- ifelse(mtusSampDT$start_min < 10,
                                              paste0("0",mtusSampDT$start_min), # < 10
                                              mtusSampDT$start_min # not < 10
  )
  table(mtusSampDT$start_hour,mtusSampDT$start_min)
  mtusSampDT$start_sec <- "00"
  
  feedBack("Construct start times")
  # if 2005 -> use 2005 dates & character times
  mtusSampDT$start_2005 <- ifelse(mtusSampDT$survey == 2005,
                                               paste0(mtusSampDT$date_2005," ",
                                                      mtusSampDT$start_hour, ":",
                                                      mtusSampDT$start_min, ":",
                                                      mtusSampDT$start_sec),
                                               NA
  )
  
  head(mtusSampDT$start_2005)
  tail(mtusSampDT$start_2005)
  
  # construct other start times in almost the same way but using MTUS date
  mtusSampDT$start_other <- ifelse(mtusSampDT$survey != 2005,
                                                paste0(mtusSampDT$mtus_year,"-",
                                                       mtusSampDT$mtus_month,"-",
                                                       mtusSampDT$mtus_cday, " ",
                                                       mtusSampDT$start_hour, ":",
                                                       mtusSampDT$start_min, ":",
                                                       mtusSampDT$start_sec),
                                                NA
  )
  
  head(mtusSampDT$start_other)
  tail(mtusSampDT$start_other)
  
  # combine the dates - why does this generate a number and not a POSIX?
  mtusSampDT$r_start_temp <- ifelse(
    mtusSampDT$survey == 2005, 
    mtusSampDT$start_2005, # if 2005
    mtusSampDT$start_other # if not
  )
  
  head(mtusSampDT$r_start_temp)
  tail(mtusSampDT$r_start_temp)
  
  feedBack("Convert start time to POSIXct")
  # mtus_month is full name and we set the 2005 date to the same form
  mtusSampDT$r_start <- as.POSIXct(mtusSampDT$r_start_temp, tz = "",
                                                "%Y-%B-%d %H:%M:%S"
  )
  # check
  head(mtusSampDT$r_start)
  tail(mtusSampDT$r_start)
  
  # define month and day of the week (started)
  mtusSampDT$r_month <- as.POSIXlt(mtusSampDT$r_start)$mon # 0 = Jan
  mtusSampDT$r_dow <- as.POSIXlt(mtusSampDT$r_start)$wday # 0 = Sunday
  # add labels to dow
  mtusSampDT$r_dow <- factor(mtusSampDT$r_dow,
                                levels = c(0,1,2,3,4,5,6),
                                labels = c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
                                )
  
  feedBack("Check days of the week")
  print(
    xtabs(~ mtusSampDT$r_dow + mtusSampDT$s_dow
    )
  )
  
  # define hour & mins (started)
  mtusSampDT$r_hour <- as.POSIXlt(mtusSampDT$r_start)$hour
  mtusSampDT$r_min <- as.POSIXlt(mtusSampDT$r_start)$min
  mtusSampDT$r_halfhour 
  
  # set a new year variable to be:
  # 74 + 75 = drop 
  # 83 + 84 + 85 = 1985
  # 95 = drop
  # 100 + 101 = 2001 = drop
  # 105 = 2005
  feedBack("Create survey year filter")
  mtusSampDT$ba_survey <- ifelse(
    mtusSampDT$survey == 1983 | 
      mtusSampDT$survey == 1987 , 
    1985, # if true
    NA # if not
  )
  
  mtusSampDT$ba_survey <- ifelse(
    mtusSampDT$survey == 2005 , 
    2005, # if true
    mtusSampDT$ba_survey # if not
  )
  
  feedBack("Check data for this paper (1985 -> 2005)")
  print(
    table(mtusSampDT$ba_survey, 
        mtusSampDT$survey, 
        useNA = "ifany"
    )
  )
  
  # add hour & half hour to each sampled record
  
  mtusSampDT$st_hour <- as.POSIXlt(mtusSampDT$s_starttime)$hour
  mtusSampDT$st_hour <- ifelse(mtusSampDT$st_hour < 10 , 
                                            paste0("0",mtusSampDT$st_hour), # if true - add leading 0
                                            mtusSampDT$st_hour # if not
  )
  mtusSampDT$st_mins <- as.POSIXlt(mtusSampDT$s_starttime)$min
  mtusSampDT$st_hh <- ifelse(mtusSampDT$st_mins < 30 , 
                                          "00", # if true
                                          "30" # if not
  )
  mtusSampDT$st_halfhour <- paste0(mtusSampDT$st_hour, 
                                                ":",
                                                mtusSampDT$st_hh)
  # check
  with(mtusSampDT,
       table(st_halfhour)
  )
  feedBack("Make global table keeping the variables we need")
  gMTUSW6UKdiarySampled_DT <<- mtusSampDT[, .(hldid, diarypid, pid, 
                               diary, ba_survey,
                               r_start, r_month, r_dow, st_halfhour, 
                               pact, sact, eloc, mtrav)
                           ]
  feedBack("Summary of gMTUSW6UKdiarySampled_DT:")
  print(
    summary(gMTUSW6UKdiarySampled_DT)
  )
} # works

analyseMtusSampled <- function() {
  feedBack("Join survey to sampled data")
  MTUSW6UKjoinedSampled_DT <- gMTUSW6UKdiarySampled_DT[gMTUSW6UKsurveyCore_DT]
  
  with(MTUSW6UKjoinedSampled_DT[], 
       table(badcase,ba_survey)
  )
  
  # Keep only good cases for 1985 & 2005
  MTUSW6UKjoinedSampled_DT <- MTUSW6UKjoinedSampled_DT[badcase == "good case"]
  MTUSW6UKjoinedSampled_DT <- MTUSW6UKjoinedSampled_DT[ba_survey %in% c("1985","2005")]
  
  # check
  with(MTUSW6UKjoinedSampled_DT, 
       table(badcase,ba_survey)
  )
  # looks like we only had the good cases in the sampled file anyway
  
  # set laundry vars
  feedBack("Set a laundry flag")
  MTUSW6UKjoinedSampled_DT$laundry_p <- ifelse(MTUSW6UKjoinedSampled_DT$pact == laundry,
                                               1, # laundry as main act
                                               0)
  MTUSW6UKjoinedSampled_DT$laundry_s <- ifelse(MTUSW6UKjoinedSampled_DT$sact == laundry,
                                               1, # laundry as sec act
                                               0)
  MTUSW6UKjoinedSampled_DT$laundry_any <- ifelse(MTUSW6UKjoinedSampled_DT$pact == laundry | MTUSW6UKjoinedSampled_DT$sact == laundry,
                                                 1, # laundry as either act
                                                 0)
  # totals
  feedBack("Number of 10 min obs of laundry as primary act")
  print(
    with(MTUSW6UKjoinedSampled_DT,
       table(laundry_p, ba_survey))
  )
  feedBack("Number of 10 min obs of laundry as secondary act")
  print(
    with(MTUSW6UKjoinedSampled_DT,
       table(laundry_s, ba_survey))
  )
  feedBack("Number of 10 min obs of laundry as any act")
  print(
    with(MTUSW6UKjoinedSampled_DT,
       table(laundry_any, ba_survey))
  )

  feedBack("Creating a derived data table to enable us to count laundry obs within half hours (as above)")
  feedBack("AND set an indicator for at least 1 laundry obs")
  # First count the number of obs for all half hours - should be 3!
  bylist <- quote(list(st_halfhour, diarypid, ba_survey, r_month, r_dow))
  MTUSW6UK_halfhours_DT <- MTUSW6UKjoinedSampled_DT[, 
                                                    .(
                                                      N_obs = length(pact) # number of 10 min samples (should be 3!)
                                                    ), 
                                                    by = eval(bylist)
                                                    ]
  
  head(MTUSW6UK_halfhours_DT) # check
  tail(MTUSW6UK_halfhours_DT) # check
  xtabs(~ MTUSW6UK_halfhours_DT$ba_survey + MTUSW6UK_halfhours_DT$N_obs) # number of half hours by number of obs in the half hour
  #summary(MTUSW6UK_halfhours_DT)
  keyCols <- c("ba_survey", "diarypid", "r_month", "r_dow", "st_halfhour") # -> easy to repeat
  setkeyv(MTUSW6UK_halfhours_DT, keyCols)
  
  # derived data table to count obs of laundry as primary act within half hours
  MTUSW6UK_halfhours_laundryp_DT <- MTUSW6UKjoinedSampled_DT[laundry_p == 1, 
                                                             .(
                                                               N_obs_laundry_p = length(laundry_p) # number of 10 min samples with laundry recorded in half hour
                                                             ), 
                                                             by = eval(bylist)
                                                             ]
  head(MTUSW6UK_halfhours_laundryp_DT) # check
  xtabs(~ MTUSW6UK_halfhours_laundryp_DT$ba_survey + MTUSW6UK_halfhours_laundryp_DT$N_obs_laundry_p) # number of half hours
  setkeyv(MTUSW6UK_halfhours_laundryp_DT, keyCols)
  
  
  # derived data table to count obs of laundry as secondary act within half hours
  MTUSW6UK_halfhours_laundrys_DT <- MTUSW6UKjoinedSampled_DT[laundry_s == 1, 
                                                             .(
                                                               N_obs_laundry_s = length(laundry_s) # number of 10 min samples with laundry recorded in half hour
                                                             ), 
                                                             by = eval(bylist)
                                                             ]
  head(MTUSW6UK_halfhours_laundrys_DT) # check
  xtabs(~ MTUSW6UK_halfhours_laundrys_DT$ba_survey + MTUSW6UK_halfhours_laundrys_DT$N_obs_laundry_s) # number of half hours
  setkeyv(MTUSW6UK_halfhours_laundrys_DT, keyCols)
  
  # derived data table to count obs of laundry as secondary act within half hours
  MTUSW6UK_halfhours_laundryany_DT <- MTUSW6UKjoinedSampled_DT[laundry_any == 1, 
                                                             .(
                                                               N_obs_laundry_any = length(laundry_any) # number of 10 min samples with laundry recorded in half hour
                                                             ), 
                                                             by = eval(bylist)
                                                             ]
  head(MTUSW6UK_halfhours_laundryany_DT) # check
  xtabs(~ MTUSW6UK_halfhours_laundryany_DT$ba_survey + MTUSW6UK_halfhours_laundryany_DT$N_obs_laundry_any) # number of half hours
  setkeyv(MTUSW6UK_halfhours_laundryany_DT, keyCols)
  
  # join them using merge so we can keep all
  MTUSW6UK_halfhours_laundry_DT <- merge(MTUSW6UK_halfhours_laundryp_DT, MTUSW6UK_halfhours_laundrys_DT, all = TRUE)
  MTUSW6UK_halfhours_laundry_DT <- merge(MTUSW6UK_halfhours_laundry_DT, MTUSW6UK_halfhours_laundryany_DT, all = TRUE)
  
  head(MTUSW6UK_halfhours_laundry_DT)
  summary(MTUSW6UK_halfhours_laundry_DT)
  feedBack("Number of observations of laundry per year")
  table(MTUSW6UK_halfhours_laundry_DT$ba_survey, MTUSW6UK_halfhours_laundry_DT$N_obs_laundry_p)
  
  # join to the complete half-hour data using merge so we can keep all
  MTUSW6UK_halfhours_DT <- merge(MTUSW6UK_halfhours_DT, MTUSW6UK_halfhours_laundry_DT, all = TRUE)
  
  head(MTUSW6UK_halfhours_DT)
  head(MTUSW6UK_halfhours_DT[MTUSW6UK_halfhours_DT$N_obs_laundry_any == 1]) # check
  
  # set an indicator if any laundry was recorded
  MTUSW6UK_halfhours_DT$anylaundry_p <- ifelse(
    MTUSW6UK_halfhours_DT$N_obs_laundry_p > 0, 1, "NA"
  )
  
  MTUSW6UK_halfhours_DT$anylaundry_s <- ifelse(
    MTUSW6UK_halfhours_DT$N_obs_laundry_s > 0, 1, "NA"
  )
  
  MTUSW6UK_halfhours_DT$anylaundry_any <- ifelse(
    MTUSW6UK_halfhours_DT$N_obs_laundry_p == 1 |  MTUSW6UK_halfhours_DT$N_obs_laundry_s == 1, 1, "NA"
  )
  head(MTUSW6UK_halfhours_DT[MTUSW6UK_halfhours_DT$anylaundry_any == 1]) # check
  summary(MTUSW6UK_halfhours_DT)
  
  feedBack("How many half hours have several obs of laundry as primary act?")
  print(
    xtabs( ~ MTUSW6UK_halfhours_DT$ba_survey + MTUSW6UK_halfhours_DT$N_obs_laundry_p)
  )  
  feedBack("How many half hours have any obs of laundry as primary act?")
  print(
    xtabs( ~ MTUSW6UK_halfhours_DT$ba_survey + MTUSW6UK_halfhours_DT$anylaundry_p)
  )
  
  # now do that comparison by half hour to see if it changes the shape much
  feedBack("Distribution of halfhours with given number (1-3) obs of laundry as primary act?")
  
  print(
    ftable(MTUSW6UK_halfhours_DT$st_halfhour, MTUSW6UK_halfhours_DT$ba_survey, MTUSW6UK_halfhours_DT$N_obs_laundry_p, 
           col.vars= c(2, 3), # arrange with half hours as rows and frequencies per survey year as cols
           exclude = NULL # keep NAs so we can calculate as % of all half hours
           )
  ) 

  # this is a long form table of the same data, would need re-casting 
  MtusHalfhourSummaryLaundryp <- MTUSW6UK_halfhours_DT[, .(N_hh_lp = length(N_obs_laundry_p)), by = .(Half_hour = st_halfhour, Freq = N_obs_laundry_p, Year = ba_survey)]
  
  print(
    ftable(MTUSW6UK_halfhours_DT$st_halfhour, MTUSW6UK_halfhours_DT$ba_survey, MTUSW6UK_halfhours_DT$anylaundry_p, 
           col.vars= c(2, 3), # arrange with half hours as rows and frequencies per survey year as cols
           exclude = NULL # keep NAs so we can calculate as % of all half hours
    )
  ) 
  # this is a long form table of the same data, would need re-casting 
  MtusHalfhourSummaryLaundryanyp <- MTUSW6UK_halfhours_DT[, .(N_hh_lp = length(anylaundry_p)), by = .(Half_hour = st_halfhour, Freq = N_obs_laundry_p, Year = ba_survey)]
  
  # the above analysis confirms that the 'any laundry' indicator masks the difference between short duration laundry acts and longer ones
  # Longer duration acts are more common and seem to have a different distribution - perhaps this is different components of the practice?
  # But NB - 1985 = 2 * 15  min slots per half hour, 2005 = 3 * 10 minutes (as per sampling method)
  
  # So from here on we use anylaundry_p as we are not sure about reporting of secondary acts and we only care about the timing of laundry
  # not the duration of acts at particular times (although it might be interesting for a methodological study)
  
  # switch to survey analysis from now on
  # add weights etc from survey data
  setkey(MTUSW6UK_halfhours_DT, diarypid)
  # merge half hour level data with core survey vars
  gMTUSW6UKhalfhours_DT <<- MTUSW6UK_halfhours_DT[gMTUSW6UKsurveyCore_DT]
  feedBack("Check what merged")
  print(
    table(gMTUSW6UKhalfhours_DT$ba_survey, gMTUSW6UKhalfhours_DT$survey, exclude = NULL)
  )
  feedBack("The NAs are either no diary/survey data in the years of interest or are not in the years of interest so drop the lot")
  gMTUSW6UKhalfhours_DT <- na.omit(gMTUSW6UKhalfhours_DT, cols="ba_survey")
  feedBack("Check again")
  print(
    table(gMTUSW6UKhalfhours_DT$ba_survey, gMTUSW6UKhalfhours_DT$survey, exclude = NULL)
  )
  
  feedBack("Done analysing sampled file")
} # works

analyseMtusSampledSvy <- function() {
  # set survey data
  # tell survey that the diarypids are the ids (they repeat)
  svygMTUSW6UK_halfhours <<- svydesign(ids = ~diarypid, weight = ~propwt, data = gMTUSW6UKhalfhours_DT) # does not produce a data table
  
  # fix the indicator to be 1 or 0
  svygMTUSW6UK_halfhours$variables$anylaundry_p <- ifelse(
    is.na(svygMTUSW6UK_halfhours$variables$anylaundry_p), 0, # set to 0 if missing
    svygMTUSW6UK_halfhours$variables$anylaundry_p)
  
  # how many half hours do we have?
  all_hhs <- svytable(~ba_survey, # the row * columns we want (produces long form)
        svygMTUSW6UK_halfhours, # the data in survey form
        )
  print(
    all_hhs # table
  )
  # get the mean % of half hours with any laundry as a primary act (and SE)
  pcAnylp <- svyby(~anylaundry_p, # the variable to do the stats on
                    ~ba_survey, # the row * columns we want (produces long form)
                    svygMTUSW6UK_halfhours, # the data
                    svymean, # the stats function(s)
                    #na.rm = TRUE,
                    keep.var = TRUE)
  print(
    pcAnylp # table
    )
  print(
    confint(pcAnylp) # with confidence intervals
    )
  # get the mean % of half hours with any laundry as a secondary act (and SE)
  pcAnyls <- svyby(~anylaundry_s, # the variable to do the stats on
                   ~ba_survey, # the row * columns we want (produces long form)
                   svygMTUSW6UK_halfhours, # the data
                   svymean, # the stats function(s)
                   keep.var = TRUE)
  print(
    pcAnyls # table
  )
  print(
    confint(pcAnyls) # with confidence intervals
  )
  
  # get the mean % of half hours with any laundry as a primary act (and SE) over 24 hours
  pcAnyl_hh <- svyby(~anylaundry_p, # the variable to do the stats on
                 ~st_halfhour + ba_survey, # the row * columns we want (produces long form)
                 svygMTUSW6UK_halfhours, # the data
                 svymean, # the stats function(s)
                 keep.var = TRUE)
  #ftable(pcAnyl_hh) # flat table fails
  
  feedBack("Done analysing sampled file using survey methods")
}


# Run to here to reload functions

# Controller ----
loadMtusSurvey()

loadMtusEpisodes()
analyseMtusEpisodes()

loadMtusSampled()
analyseMtusSampled()

analyseMtusSampledSvy()
