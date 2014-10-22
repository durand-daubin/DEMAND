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

# Loading the data: Ensure R is in the right working directory (spatial-microsim-book)
timeuse2005 <- read.csv("~/Documents/Work/Data/Social Science Datatsets/Time Use 2005/processed/timeusefinal_for_archive_diary_long_v2.0.csv")

# Take a quick look at the data
head(timeuse2005)

# attach this dataset so we don;t have to keep specifying the table
attach(timeuse2005)

# the data has no labels (intentionally)
# 21 = laundry

# check incidence of laundry as primary & secondary act
table("Laundry as primary"= pact == 21)
table("Laundry as secondary"= sact == 21)

# create a new variable (column) which is 'any_laundry'

# check location of laundry
# lact = -1 (unknown), 1 = home, 2 = elsewhere
table("Laundry as primary"= pact == 21, lact)
table("Laundry as secondary"= sact == 21, lact)

