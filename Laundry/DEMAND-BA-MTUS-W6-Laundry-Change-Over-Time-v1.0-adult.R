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
# diary
timeuse2005d <- read.csv("~/Documents/Work/Data/Social Science Datatsets/Time Use 2005/processed/timeusefinal_for_archive_diary_long_v2.0.csv")
# survey
timeuse2005s <- read.csv("~/Documents/Work/Data/Social Science Datatsets/Time Use 2005/processed/timeusefinal_for_archive_survey_v2.0.csv")

# merge
timeuse2005all <- merge(timeuse2005d,timeuse2005s,by="serial")

# Take a quick look at the data
head(timeuse2005)

# attach this dataset so we don't have to keep specifying the table
attach(timeuse2005)

# check the distribution of episodes by time of day and year of survey
table("Half hour"= s_faketime)

# the data has no labels (intentionally)
# 21 = laundry

# check incidence of laundry as primary & secondary act
table("Laundry as primary"= pact == 21)
table("Laundry as secondary"= sact == 21)

# create 2 new variables (columns) which are 'laundry'
timeuse2005$laundry_p[timeuse2005$pact == 21] <- 1 
timeuse2005$laundry_s[timeuse2005$sact == 21] <- 1
timeuse2005$laundry_all <- 0
timeuse2005$laundry_all[timeuse2005$laundry_p == 1 | timeuse2005$laundry_p == 1] <- 1

table(timeuse2005$laundry_all)

# check location of laundry
# lact = -1 (unknown), 1 = home, 2 = elsewhere
table("Laundry as primary"= timeuse2005$pact == 21, timeuse2005$lact)
table("Laundry as secondary"= timeuse2005$sact == 21, timeuse2005$lact)

