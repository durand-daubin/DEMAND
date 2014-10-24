############################################
# Time Use data analysis for 'Laundry' paper  
# Use MTUS World 6 time-use data (UK subset) to examine:
# - distributions of laundry in 1975 & 2005
# - changing laundry practices

# data already in long format (but episodes)

# b.anderson@soton.ac.uk
# (c) University of Southampton

# This work was funded by RCUK through the End User Energy Demand Centres Programme via the
# "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, gow.epsrc.ac.uk/NGBOViewGrant.aspx?GrantRef=EP/K011723/1)
# Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license applies
# http://creativecommons.org/licenses/by-nc/4.0/
  
# clear out all old objects etc to avoid confusion
rm(list = ls()) 

# Loading the data
# load as stata file
library(foreign)
# diary
MTUSW6UK_d <- read.dta("~/Documents/Work/Data/Social Science Datatsets/MTUS/World 6/processed/MTUS-adult-episode-UK-only-wf.dta")
# survey
MTUSW6UK_s <- read.dta("~/Documents/Work/Data/Social Science Datatsets/MTUS/World 6/processed/MTUS-adult-aggregate-UK-only-wf.dta")
# create a reduced survey frame with the few variables we need
MTUSW6UK_s_redvars <- c("diarypid", "empstat", "urban")
MTUSW6UK_s_red <- MTUSW6UK_s[MTUSW6UK_s_redvars]

# merge
MTUSW6UK_m <- merge(MTUSW6UK_d,MTUSW6UK_s_red,by="diarypid")

# Take a quick look at the data
head(MTUSW6UK_m)

# Check what's in it?
names(MTUSW6UK_m)

# check the distribution of episodes by time of day and year of survey
# NB: stata has already set the date to 1960! We need to re-format to half hours!
table("Half hour"= MTUSW6UK_m$s_halfhour)

# 21 = "laundry, ironing, clothing repair"
# We've imported from stata so we'll have to use the value label not the value
# Could have imported as csv and then applied labels... might be easier

# check incidence of laundry as primary & secondary act
table("Laundry as primary"= MTUSW6UK_m$main == "laundry, ironing, clothing repair")
table("Laundry as secondary"= MTUSW6UK_m$sec == "laundry, ironing, clothing repair")

# create 2 new variables (columns) which are 'laundry'
MTUSW6UK_m$laundry_p <- 0
MTUSW6UK_m$laundry_p[MTUSW6UK_m$main == "laundry, ironing, clothing repair"] <- 1 

MTUSW6UK_m$laundry_s <- 0
MTUSW6UK_m$laundry_s[MTUSW6UK_m$sec == "laundry, ironing, clothing repair"] <- 1 

MTUSW6UK_m$laundry_all <- 0
MTUSW6UK_m$laundry_all[MTUSW6UK_m$laundry_p == 1 | MTUSW6UK_m$laundry_s == 1] <- 1

table(MTUSW6UK_m$laundry_all)

# check location of laundry
# lact = -1 (unknown), 1 = home, 2 = elsewhere
table("Laundry as primary"= MTUSW6UK_m$laundry_p == 1, MTUSW6UK_m$eloc)
table("Laundry as secondary"= MTUSW6UK_m$laundry_s == 1, MTUSW6UK_m$eloc)

laundry_all_tod <- table("All laundry" = MTUSW6UK_m$laundry_all == 1, MTUSW6UK_m$s_halfhour)
plot(laundry_all_tod)