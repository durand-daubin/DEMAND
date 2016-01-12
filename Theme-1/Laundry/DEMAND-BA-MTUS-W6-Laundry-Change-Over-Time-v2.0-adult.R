############################################
# Data analysis for 'Laundry' paper  
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

# Codes of interest:
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
library(lattice)
library(data.table)

# set up some useful data paths
tudpath <- "~/Documents/Work/Data/MTUS/World 6/processed/"
efspath <- "~/Documents/Work/Data/Expenditure and Food Survey/processed"
sprgpath <- "~/Documents/Work/Projects/ESRC-SPRG/WP4-Micro_water/data/sprg_survey/data/safe/v6"

rpath <- "~/Documents/Work/Papers and Conferences/The Time and Timing of Demand - Laundry/results"


# Load TU data ----
# load as stata file

# _Diary as episodes ----
dfile <- paste0(tudpath, "MTUS-adult-episode-UK-only-wf.dta")
MTUSW6UKdiaryEps_DT <- as.data.table(read.dta(dfile))
setkey(MTUSW6UKdiaryEps_DT, diarypid)

# __Episodes_Fix_Dates ----
# The stata times are all loaded as POSIXct which is not all that helpful
# Need to create a proper start/end time but 2005 does not have a valid date so we are forced to impute them
# 2005 months:
# March: synthetic week = Sunday 6th -> Saturday 12th
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
       MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "March"
       & MTUSW6UKdiaryEps_DT$s_dow == "Sunday", "06/03/2005", "na"
     )
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "March"
  & MTUSW6UKdiaryEps_DT$s_dow == "Monday", "07/03/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "March"
  & MTUSW6UKdiaryEps_DT$s_dow == "Tuesday", "08/03/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "March"
  & MTUSW6UKdiaryEps_DT$s_dow == "Wednesday", "09/03/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "March"
  & MTUSW6UKdiaryEps_DT$s_dow == "Thursday", "10/03/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "March"
  & MTUSW6UKdiaryEps_DT$s_dow == "Friday", "11/03/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "March"
  & MTUSW6UKdiaryEps_DT$s_dow == "Saturday", "12/03/2005", MTUSW6UKdiaryEps_DT$date_2005
)

# June: 5th -> 11th
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "June"
  & MTUSW6UKdiaryEps_DT$s_dow == "Sunday", "05/06/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "June"
  & MTUSW6UKdiaryEps_DT$s_dow == "Monday", "06/06/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "June"
  & MTUSW6UKdiaryEps_DT$s_dow == "Tuesday", "07/06/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "June"
  & MTUSW6UKdiaryEps_DT$s_dow == "Wednesday", "08/06/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "June"
  & MTUSW6UKdiaryEps_DT$s_dow == "Thursday", "09/06/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "June"
  & MTUSW6UKdiaryEps_DT$s_dow == "Friday", "10/06/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "June"
  & MTUSW6UKdiaryEps_DT$s_dow == "Saturday", "11/06/2005", MTUSW6UKdiaryEps_DT$date_2005
)

# September: 4th -> 10th
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "September"
  & MTUSW6UKdiaryEps_DT$s_dow == "Sunday", "04/09/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "September"
  & MTUSW6UKdiaryEps_DT$s_dow == "Monday", "05/09/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "September"
  & MTUSW6UKdiaryEps_DT$s_dow == "Tuesday", "06/09/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "September"
  & MTUSW6UKdiaryEps_DT$s_dow == "Wednesday", "07/09/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "September"
  & MTUSW6UKdiaryEps_DT$s_dow == "Thursday", "08/09/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "September"
  & MTUSW6UKdiaryEps_DT$s_dow == "Friday", "09/09/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "September"
  & MTUSW6UKdiaryEps_DT$s_dow == "Saturday", "10/09/2005", MTUSW6UKdiaryEps_DT$date_2005
)

# November: 6th - 12th
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "November"
  & MTUSW6UKdiaryEps_DT$s_dow == "Sunday", "06/11/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "November"
  & MTUSW6UKdiaryEps_DT$s_dow == "Monday", "07/11/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "November"
  & MTUSW6UKdiaryEps_DT$s_dow == "Tuesday", "08/11/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "November"
  & MTUSW6UKdiaryEps_DT$s_dow == "Wednesday", "09/11/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "November"
  & MTUSW6UKdiaryEps_DT$s_dow == "Thursday", "10/11/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "November"
  & MTUSW6UKdiaryEps_DT$s_dow == "Friday", "11/11/2005", MTUSW6UKdiaryEps_DT$date_2005
)
MTUSW6UKdiaryEps_DT$date_2005 <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 & MTUSW6UKdiaryEps_DT$mtus_month == "November"
  & MTUSW6UKdiaryEps_DT$s_dow == "Saturday", "12/11/2005", MTUSW6UKdiaryEps_DT$date_2005
)

# 2005 dates as POSIX
MTUSW6UKdiaryEps_DT$r_date_2005 <- as.POSIXct(MTUSW6UKdiaryEps_DT$date_2005, tz = "",
                                              "%d/%m/%Y"
                                              )
# check
table(as.POSIXlt(MTUSW6UKdiaryEps_DT$r_date_2005)$wday, MTUSW6UKdiaryEps_DT$s_dow)

# others dates as POSIX
MTUSW6UKdiaryEps_DT$r_date <- as.POSIXct(MTUSW6UKdiaryEps_DT$s_date, tz = "",
                                              "%Y-%m-%d"
)
# check
table(as.POSIXlt(MTUSW6UKdiaryEps_DT$r_date)$wday, MTUSW6UKdiaryEps_DT$s_dow)

# combine the dates - why does this generate a number and not a POSIX?
MTUSW6UKdiaryEps_DT$r_date_n <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005, 
  MTUSW6UKdiaryEps_DT$r_date_2005, # if 2005
  MTUSW6UKdiaryEps_DT$r_date # if not, date already set
)

# convert to POSIX
MTUSW6UKdiaryEps_DT$r_datef <- as.POSIXct(MTUSW6UKdiaryEps_DT$r_date_n, origin = "1970-01-01")
# check matches
table(as.POSIXlt(MTUSW6UKdiaryEps_DT$r_datef)$wday, 
      MTUSW6UKdiaryEps_DT$s_dow, 
      useNA = "ifany"
      )

# set up corrected start and end timestamps
# all diaries start at 04:00 on the date given
# POSIXct works in seconds
MTUSW6UKdiaryEps_DT$r_epstart <- MTUSW6UKdiaryEps_DT$r_datef + (3*60*60)
# now add the corrected minutes up to the start of the episode
MTUSW6UKdiaryEps_DT$r_epstart <- MTUSW6UKdiaryEps_DT$r_epstart + (MTUSW6UKdiaryEps_DT$ba_startm*60)

# same for episode end
MTUSW6UKdiaryEps_DT$r_epend <- MTUSW6UKdiaryEps_DT$r_epstart + (MTUSW6UKdiaryEps_DT$end*60)

# define year (started)
MTUSW6UKdiaryEps_DT$r_year <- as.POSIXlt(MTUSW6UKdiaryEps_DT$r_date)$year

# keep the variables we need
MTUSW6UKdiaryEps_DT <- MTUSW6UKdiaryEps_DT[, .(survey, swave, hldid, persid, id, diarypid, pid, 
                                               diary, survey, r_year, badcase, sex, age, 
                                               r_epstart, r_epend, time, epnum,
                                               main, sec, inout, eloc, mtrav, child, sppart)
                                           ]

# check the distribution of episodes by time of day and year of survey
table("Hour" = as.POSIXlt(MTUSW6UKdiaryEps_DT$r_epstart)$hour,
      "Year"= as.POSIXlt(MTUSW6UKdiaryEps_DT$r_epstart)$year 
      )

# set a new year variable to be:
# 74 + 75 = drop 
# 83 + 84 + 85 = 1985
# 95 = drop
# 100 + 101 = 2001
# 105 = 2005

MTUSW6UKdiaryEps_DT$ba_survey <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 1983 | 
    MTUSW6UKdiaryEps_DT$survey == 1987 , 
  1985, # if true
  NA # if not
)

MTUSW6UKdiaryEps_DT$ba_survey <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2000 , 
  2000, # if true
  MTUSW6UKdiaryEps_DT$ba_survey # if not
)

MTUSW6UKdiaryEps_DT$ba_survey <- ifelse(
  MTUSW6UKdiaryEps_DT$survey == 2005 , 
  2005, # if true
  MTUSW6UKdiaryEps_DT$ba_survey # if not
)

# check
table(MTUSW6UKdiaryEps_DT$ba_survey, 
      MTUSW6UKdiaryEps_DT$survey, 
      useNA = "ifany"
)

# add hour & half hour of the start of the episode
MTUSW6UKdiaryEps_DT$st_hour <- as.POSIXlt(MTUSW6UKdiaryEps_DT$r_epstart)$hour
MTUSW6UKdiaryEps_DT$st_hour <- ifelse(MTUSW6UKdiaryEps_DT$st_hour < 10 , 
                                      paste0("0",MTUSW6UKdiaryEps_DT$st_hour), # if true - add leading 0
                                      MTUSW6UKdiaryEps_DT$st_hour # if not
)
MTUSW6UKdiaryEps_DT$st_mins <- as.POSIXlt(MTUSW6UKdiaryEps_DT$r_epstart)$min
MTUSW6UKdiaryEps_DT$st_hh <- ifelse(MTUSW6UKdiaryEps_DT$st_mins < 30 , 
                                    "00", # if true
                                    "30" # if not
                                    )
MTUSW6UKdiaryEps_DT$st_halfhour <- paste0(MTUSW6UKdiaryEps_DT$st_hour, 
                                          ":",
                                          MTUSW6UKdiaryEps_DT$st_hh)
# check
with(MTUSW6UKdiaryEps_DT,
     table(st_halfhour)
)

with(MTUSW6UKdiaryEps_DT, 
     table(badcase,ba_survey)
)
# Keep only good cases for 1985 & 2005
MTUSW6UKdiaryEps_DT <- MTUSW6UKdiaryEps_DT[badcase == "good case"]
MTUSW6UKdiaryEps_DT <- MTUSW6UKdiaryEps_DT[ba_survey %in% c("1985","2005")]

# check
with(MTUSW6UKdiaryEps_DT, 
     table(badcase,ba_survey)
     )

# __Episodes_Analysis ----
# Laundry = code 21
laundry <- "laundry, ironing, clothing repair"
# n episodes in total per year
with(MTUSW6UKdiaryEps_DT, 
     table(ba_survey)
)
# set a laundry code
MTUSW6UKdiaryEps_DT$laundry_p <- ifelse(MTUSW6UKdiaryEps_DT$main == laundry,
                                       1, # laundry as main act
                                       0)
MTUSW6UKdiaryEps_DT$laundry_s <- ifelse(MTUSW6UKdiaryEps_DT$sec == laundry,
                                      1, # laundry as main act
                                      0)
MTUSW6UKdiaryEps_DT$laundry_all <- ifelse(MTUSW6UKdiaryEps_DT$main == laundry | MTUSW6UKdiaryEps_DT$sec == laundry,
                                        1, # laundry as either act
                                        0)
# totals
with(MTUSW6UKdiaryEps_DT,
     table(laundry_p, ba_survey))
with(MTUSW6UKdiaryEps_DT,
     table(laundry_s, ba_survey))
with(MTUSW6UKdiaryEps_DT,
     table(laundry_all, ba_survey))

# not what we want: calculates proportion from overall sum
with(MTUSW6UKdiaryEps_DT,
     prop.table(
       table(laundry_all, ba_survey)
       )
)

eps1985 <- length(MTUSW6UKdiaryEps_DT$diarypid[MTUSW6UKdiaryEps_DT$ba_survey == 1985])
epslaundry1985 <- length(MTUSW6UKdiaryEps_DT$diarypid[MTUSW6UKdiaryEps_DT$ba_survey == 1985 & MTUSW6UKdiaryEps_DT$laundry_all == 1])

print(paste0("% episodes that are laundry_all in 1985 = ", (epslaundry1985/eps1985)*100))

eps2005 <- length(MTUSW6UKdiaryEps_DT$diarypid[MTUSW6UKdiaryEps_DT$ba_survey == 2005])
epslaundry2005 <- length(MTUSW6UKdiaryEps_DT$diarypid[MTUSW6UKdiaryEps_DT$ba_survey == 2005 & MTUSW6UKdiaryEps_DT$laundry_all == 1])

print(paste0("% episodes that are laundry_all in 2005 = ", (epslaundry2005/eps2005)*100))

# work with split files - easier?
eps_1985DT <- MTUSW6UKdiaryEps_DT[MTUSW6UKdiaryEps_DT$ba_survey == 1985]
eps_2005DT <- MTUSW6UKdiaryEps_DT[MTUSW6UKdiaryEps_DT$ba_survey == 2005]

laundryeps_byhh1985 <- eps_1985DT[main == laundry, 
                                       .(
                                         N_episodes1985 = length(st_halfhour), # number of clamp records per day
                                         Pr_episodes1985 = length(st_halfhour)/eps1985 # number of clamp records per day
                                       ), 
                                       by = .(
                                         Start = st_halfhour
                                       )
                                       ]
setkey(laundryeps_byhh1985,Start)
plot(laundryeps_byhh1985$Pr_episodes)

laundryeps_byhh2005 <- eps_2005DT[main == laundry, 
                                  .(
                                    N_episodes2005 = length(st_halfhour), # number of clamp records per day
                                    Pr_episodes2005 = length(st_halfhour)/eps2005 # number of clamp records per day
                                  ), 
                                  by = .(
                                    Start = st_halfhour
                                  )
                                  ]
setkey(laundryeps_byhh2005,Start)
plot(laundryeps_byhh2005$Pr_episodes)

# join tables for ease of comparison
# ideally these need to be weighted & need 95% CIs for proportions
laundryeps_byhh <- laundryeps_byhh2005[laundryeps_byhh1985]
laundryeps_byhh$diff <- laundryeps_byhh$Pr_episodes2005 - laundryeps_byhh$Pr_episodes1985
plot(laundryeps_byhh$diff)

# use ggplot to make a nice plot of 1985, 2005 & difference

# save out the table for use in excel if needed
outf <- paste0(rpath,"/laundryeps_byhh.csv")
print(paste0("Look for the file in: ", rpath))
write.csv(laundryeps_byhh, 
          file = outf,
          na = ""
)

# _Diary as sampled file ----
dfile <- paste0(tudpath, "MTUS-adult-episode-UK-only-wf-10min-samples-long-v1.0.dta")
MTUSW6UKdiarySampled_DT <- as.data.table(read.dta(dfile))
setkey(MTUSW6UKdiarySampled_DT, diarypid)

# __Sampled_Fix_Dates ----
# re-run date & time re-formatting as before
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "March"
  & MTUSW6UKdiarySampled_DT$s_dow == "Sunday", "2005-March-06", "na"
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "March"
  & MTUSW6UKdiarySampled_DT$s_dow == "Monday", "2005-March-07", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "March"
  & MTUSW6UKdiarySampled_DT$s_dow == "Tuesday", "2005-March-08", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "March"
  & MTUSW6UKdiarySampled_DT$s_dow == "Wednesday", "2005-March-09", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "March"
  & MTUSW6UKdiarySampled_DT$s_dow == "Thursday", "2005-March-10", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "March"
  & MTUSW6UKdiarySampled_DT$s_dow == "Friday", "2005-March-11", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "March"
  & MTUSW6UKdiarySampled_DT$s_dow == "Saturday", "2005-March-12", MTUSW6UKdiarySampled_DT$date_2005
)

# June: 5th -> 11th
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "June"
  & MTUSW6UKdiarySampled_DT$s_dow == "Sunday", "2005-June-05", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "June"
  & MTUSW6UKdiarySampled_DT$s_dow == "Monday", "2005-June-06", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "June"
  & MTUSW6UKdiarySampled_DT$s_dow == "Tuesday", "2005-June-07", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "June"
  & MTUSW6UKdiarySampled_DT$s_dow == "Wednesday", "2005-June-08", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "June"
  & MTUSW6UKdiarySampled_DT$s_dow == "Thursday", "2005-June-09", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "June"
  & MTUSW6UKdiarySampled_DT$s_dow == "Friday", "2005-June-10", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "June"
  & MTUSW6UKdiarySampled_DT$s_dow == "Saturday", "2005-June-11", MTUSW6UKdiarySampled_DT$date_2005
)

# September: 4th -> 10th
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "September"
  & MTUSW6UKdiarySampled_DT$s_dow == "Sunday", "2005-September-04", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "September"
  & MTUSW6UKdiarySampled_DT$s_dow == "Monday", "2005-September-05", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "September"
  & MTUSW6UKdiarySampled_DT$s_dow == "Tuesday", "2005-September-06", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "September"
  & MTUSW6UKdiarySampled_DT$s_dow == "Wednesday", "2005-September-07", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "September"
  & MTUSW6UKdiarySampled_DT$s_dow == "Thursday", "2005-September-08", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "September"
  & MTUSW6UKdiarySampled_DT$s_dow == "Friday", "2005-September-09", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "September"
  & MTUSW6UKdiarySampled_DT$s_dow == "Saturday", "2005-September-10", MTUSW6UKdiarySampled_DT$date_2005
)

# November: 6th - 12th
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "November"
  & MTUSW6UKdiarySampled_DT$s_dow == "Sunday", "2005-November-06", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "November"
  & MTUSW6UKdiarySampled_DT$s_dow == "Monday", "2005-November-07", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "November"
  & MTUSW6UKdiarySampled_DT$s_dow == "Tuesday", "2005-November-08", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "November"
  & MTUSW6UKdiarySampled_DT$s_dow == "Wednesday", "2005-November-09", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "November"
  & MTUSW6UKdiarySampled_DT$s_dow == "Thursday", "2005-November-10", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "November"
  & MTUSW6UKdiarySampled_DT$s_dow == "Friday", "2005-November-11", MTUSW6UKdiarySampled_DT$date_2005
)
MTUSW6UKdiarySampled_DT$date_2005 <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 & MTUSW6UKdiarySampled_DT$mtus_month == "November"
  & MTUSW6UKdiarySampled_DT$s_dow == "Saturday", "2005-November-12", MTUSW6UKdiarySampled_DT$date_2005
)

# set up character hours/mins/secs so POSIXct recognises them.
MTUSW6UKdiarySampled_DT$start_hour <- as.POSIXlt(MTUSW6UKdiarySampled_DT$s_starttime)$hour
MTUSW6UKdiarySampled_DT$start_hour <- ifelse(MTUSW6UKdiarySampled_DT$start_hour < 10,
                                             paste0("0",MTUSW6UKdiarySampled_DT$start_hour), # < 10
                                             MTUSW6UKdiarySampled_DT$start_hour # not < 10
                                             )
MTUSW6UKdiarySampled_DT$start_min <- as.POSIXlt(MTUSW6UKdiarySampled_DT$s_starttime)$min
MTUSW6UKdiarySampled_DT$start_min <- ifelse(MTUSW6UKdiarySampled_DT$start_min < 10,
                                             paste0("0",MTUSW6UKdiarySampled_DT$start_min), # < 10
                                             MTUSW6UKdiarySampled_DT$start_min # not < 10
)
table(MTUSW6UKdiarySampled_DT$start_hour,MTUSW6UKdiarySampled_DT$start_min)
MTUSW6UKdiarySampled_DT$start_sec <- "00"

# if 2005 -> use 2005 dates & character times
MTUSW6UKdiarySampled_DT$start_2005 <- ifelse(MTUSW6UKdiarySampled_DT$survey == 2005,
                                             paste0(MTUSW6UKdiarySampled_DT$date_2005," ",
                                             MTUSW6UKdiarySampled_DT$start_hour, ":",
                                             MTUSW6UKdiarySampled_DT$start_min, ":",
                                             MTUSW6UKdiarySampled_DT$start_sec),
                                             NA
)

head(MTUSW6UKdiarySampled_DT$start_2005)
tail(MTUSW6UKdiarySampled_DT$start_2005)

# construct other start times in almost the same way but using MTUS date
MTUSW6UKdiarySampled_DT$start_other <- ifelse(MTUSW6UKdiarySampled_DT$survey != 2005,
                                              paste0(MTUSW6UKdiarySampled_DT$mtus_year,"-",
                                              MTUSW6UKdiarySampled_DT$mtus_month,"-",
                                              MTUSW6UKdiarySampled_DT$mtus_cday, " ",
                                              MTUSW6UKdiarySampled_DT$start_hour, ":",
                                              MTUSW6UKdiarySampled_DT$start_min, ":",
                                              MTUSW6UKdiarySampled_DT$start_sec),
                                              NA
                                            )

head(MTUSW6UKdiarySampled_DT$start_other)
tail(MTUSW6UKdiarySampled_DT$start_other)

# combine the dates - why does this generate a number and not a POSIX?
MTUSW6UKdiarySampled_DT$r_start_temp <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005, 
  MTUSW6UKdiarySampled_DT$start_2005, # if 2005
  MTUSW6UKdiarySampled_DT$start_other # if not
)

head(MTUSW6UKdiarySampled_DT$r_start_temp)
tail(MTUSW6UKdiarySampled_DT$r_start_temp)

# convert to POSIX
# mtus_month is full name and we set the 2005 date to the same form
MTUSW6UKdiarySampled_DT$r_start <- as.POSIXct(MTUSW6UKdiarySampled_DT$r_start_temp, tz = "",
                                              "%Y-%B-%d %H:%M:%S"
)
# check
head(MTUSW6UKdiarySampled_DT$r_start)
tail(MTUSW6UKdiarySampled_DT$r_start)

table(as.POSIXlt(MTUSW6UKdiarySampled_DT$r_start)$wday, 
      MTUSW6UKdiarySampled_DT$s_dow,
      useNA = "ifany"
      )

# define year & month (started)
MTUSW6UKdiarySampled_DT$r_hour <- as.POSIXlt(MTUSW6UKdiarySampled_DT$r_start)$hour
MTUSW6UKdiarySampled_DT$r_min <- as.POSIXlt(MTUSW6UKdiarySampled_DT$r_start)$min
MTUSW6UKdiarySampled_DT$r_halfhour 

# keep the variables we need
MTUSW6UKdiarySampled_DT <- MTUSW6UKdiarySampled_DT[, .(hldid, diarypid, pid, 
                                               diary, survey, r_year, r_month, r_dom
                                               r_start, r_halfhour, 
                                               pact, sact, eloc, mtrav)
                                           ]


# set a new year variable to be:
# 74 + 75 = drop 
# 83 + 84 + 85 = 1985
# 95 = drop
# 100 + 101 = 2001
# 105 = 2005

MTUSW6UKdiarySampled_DT$ba_survey <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 1983 | 
    MTUSW6UKdiarySampled_DT$survey == 1987 , 
  1985, # if true
  NA # if not
)

MTUSW6UKdiarySampled_DT$ba_survey <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2000 , 
  2000, # if true
  MTUSW6UKdiarySampled_DT$ba_survey # if not
)

MTUSW6UKdiarySampled_DT$ba_survey <- ifelse(
  MTUSW6UKdiarySampled_DT$survey == 2005 , 
  2005, # if true
  MTUSW6UKdiarySampled_DT$ba_survey # if not
)

# check
table(MTUSW6UKdiarySampled_DT$ba_survey, 
      MTUSW6UKdiarySampled_DT$survey, 
      useNA = "ifany"
)

# _Survey data ----
sfile <- paste0(tudpath, "MTUS-adult-aggregate-UK-only-wf.dta")
MTUSW6UKsurvey_DT <- as.data.table(read.dta(sfile))
setkey(MTUSW6UKsurvey_DT, diarypid)

# create a reduced survey frame with the few variables we need so the join
# does not break memory
MTUSW6UKsurveyCore_DT <- MTUSW6UKsurvey_DT[, .(diarypid, pid, empstat, urban, 
                                               badcase, nchild, sex, age)
                                           ]

# join survey to episodes
MTUSW6UKjoinedEps_DT <- MTUSW6UKdiaryEps_DT[MTUSW6UKsurveyCore_DT]

# join survey to samples
MTUSW6UKjoinedSampled_DT <- MTUSW6UKdiarySampled_DT[MTUSW6UKsurveyCore_DT]


