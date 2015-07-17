############################################
# Time Use data analysis for 'Laundry' paper  
# Use MTUS World 6 time-use data (UK subset) to examine:
# - distributions of laundry in 1975 & 2005
# - changing laundry practices

# Data source: www.timeuse.org/mtus
# data already in long format (but episodes)

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
  
# clear out all old objects etc to avoid confusion
rm(list = ls()) 

# add libraries
library("lattice", "Hmisc")

# set up some useful vars
ifile_d <- c("~/Documents/Work/Data/Social Science Datatsets/MTUS/World 6/processed/MTUS-adult-episode-UK-only-wf.dta")
ifile_s <- c("~/Documents/Work/Data/Social Science Datatsets/MTUS/World 6/processed/MTUS-adult-aggregate-UK-only-wf.dta")
  
rpath <- c("~/Documents/Work/Projects/RCUK-DEMAND/Theme 1/results/MTUS")
# paste!

# Loading the data
# load as stata file
library(foreign)
# diary
MTUSW6UK_d <- read.dta(ifile_d)
# survey
MTUSW6UK_s <- read.dta(ifile_s)

# create a reduced survey frame with the few variables we need so the merge
# does not break memory
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

# create a frame to hold the various results
# NB the value of the column (x) is meaningless
laundry_fr <- aggregate(MTUSW6UK_m$year, by=list(MTUSW6UK_m$s_halfhour), FUN=mean)
names(laundry_fr) <- c("s_halfhour","junk") 
# drop junk
laundry_fr <- laundry_fr["s_halfhour"]

# there must be a simple way to do this as a loop switching p for s and all
# primary
laundry_p_tod <- aggregate(MTUSW6UK_m$laundry_p, by=list(MTUSW6UK_m$s_halfhour), FUN=sum)
names(laundry_p_tod) <- c("s_halfhour","freq") 
# each half hour as a proportion of laundry episodes
laundry_fr$p_laundry_pr <- (laundry_p_tod$freq/sum(laundry_p_tod$freq))

# secondary
laundry_s_tod <- aggregate(MTUSW6UK_m$laundry_s, by=list(MTUSW6UK_m$s_halfhour), FUN=sum)
names(laundry_s_tod) <- c("s_halfhour","freq") 
# each half hour as a proportion of laundry episodes
laundry_fr$s_laundry_pr <- (laundry_s_tod$freq/sum(laundry_s_tod$freq))

# all
laundry_all_tod <- aggregate(MTUSW6UK_m$laundry_all, by=list(MTUSW6UK_m$s_halfhour), FUN=sum)
names(laundry_all_tod) <- c("s_halfhour","freq") 
# each half hour as a proportion of laundry episodes
laundry_fr$all_laundry_pr <- (laundry_all_tod$freq/sum(laundry_all_tod$freq))

# plot with primary & secondary for all years
# direct graph to file
png(paste(rpath,"/laundry-time-of-day-all-years.png", sep=""))
plot(x = laundry_fr$s_halfhour, y = laundry_fr$p_laundry_pr,
     xlab = "Half Hour", 
     ylab = "% of laundry of that type", 
     type = "l",
     col = "red")
points(x = laundry_fr$s_halfhour, y = laundry_fr$s_laundry_pr, type = "l")
# cex = scaling factor
legend('topright',c("Primary act","Secondary act"), lty=1, col=c('red', 'black'), bty='n', cex=1)
title("% of laundry done at different times of day (all years)", cex=0.75)
dev.off()

# laundry for each year - how to loop over?
# make subsets to speed things up

MTUSW6UK_m1974 <- subset(MTUSW6UK_m,survey==1974)

laundry_tod_1974p <- aggregate(MTUSW6UK_m1974$laundry_p, by=list(MTUSW6UK_m1974$s_halfhour), FUN=sum)
names(laundry_tod_1974p) <- c("s_halfhour","freq") 
laundry_fr$laundry_p_1974_pr <- (laundry_tod_1974p$freq/sum(laundry_tod_1974p$freq))

laundry_tod_1974s <- aggregate(MTUSW6UK_m1974$laundry_s, by=list(MTUSW6UK_m1974$s_halfhour), FUN=sum)
names(laundry_tod_1974s) <- c("s_halfhour","freq") 
laundry_fr$laundry_s_1974_pr <- (laundry_tod_1974s$freq/sum(laundry_tod_1974s$freq))

laundry_tod_1974all <- aggregate(MTUSW6UK_m1974$laundry_s, by=list(MTUSW6UK_m1974$s_halfhour), FUN=sum)
names(laundry_tod_1974all) <- c("s_halfhour","freq") 
laundry_fr$laundry_all_1974_pr <- (laundry_tod_1974all$freq/sum(laundry_tod_1974all$freq))


MTUSW6UK_m2005 <- subset(MTUSW6UK_m,survey==2005)

laundry_tod_2005p <- aggregate(MTUSW6UK_m2005$laundry_p, by=list(MTUSW6UK_m2005$s_halfhour), FUN=sum)
names(laundry_tod_2005p) <- c("s_halfhour","freq") 
laundry_fr$laundry_p_2005_pr <- (laundry_tod_2005p$freq/sum(laundry_tod_2005p$freq))

laundry_tod_2005s <- aggregate(MTUSW6UK_m2005$laundry_s, by=list(MTUSW6UK_m2005$s_halfhour), FUN=sum)
names(laundry_tod_2005s) <- c("s_halfhour","freq") 
laundry_fr$laundry_s_2005_pr <- (laundry_tod_2005s$freq/sum(laundry_tod_2005s$freq))

laundry_tod_2005all <- aggregate(MTUSW6UK_m2005$laundry_all, by=list(MTUSW6UK_m2005$s_halfhour), FUN=sum)
names(laundry_tod_2005all) <- c("s_halfhour","freq") 
laundry_fr$laundry_all_2005_pr <- (laundry_tod_2005all$freq/sum(laundry_tod_2005all$freq))

# now compare laundry for 1974 & 2005
# must be a simple way to loop over these
# direct graph to file
# primary episodes
png(paste(rpath,"/laundry-time-of-day-1974-2005-primary.png", sep=""))
plot(x = laundry_fr$s_halfhour, y = laundry_fr$laundry_p_1974_pr,
     xlab = "Half Hour", 
     ylab = "Proportion of laundry of that type", 
     pch = 1,
     col = "red")
points(x = laundry_fr$s_halfhour, y = laundry_fr$laundry_p_2005_pr, col = "blue", pch=2)
# cex = scaling factor
legend('topright',c("Primary act 1974","Primary act 2005"), 
      col=c('red', 'blue'), pch=c(1,2), cex=1)
title("% of laundry done at different times of day (1974-2005)", cex=0.75)
dev.off()

# secondary episodes
png(paste(rpath,"/laundry-time-of-day-1974-2005-secondary.png", sep=""))
plot(x = laundry_fr$s_halfhour, y = laundry_fr$laundry_s_1974_pr,
     xlab = "Half Hour", 
     ylab = "Proportion of laundry of that type", 
     pch = 1,
     col = "red")
points(x = laundry_fr$s_halfhour, y = laundry_fr$laundry_s_2005_pr, col = "blue", pch = 2)
# cex = scaling factor
legend('topright',c("Secondary act 1974","Secondary act 2005"), 
       col=c('red','blue'), pch=c(1,2), cex=1)
title("% of laundry done at different times of day (1974-2005)", cex=0.75)
dev.off()

# all laundry episodes
png(paste(rpath,"/laundry-time-of-day-1974-2005-all.png", sep=""))
plot(x = laundry_fr$s_halfhour, y = laundry_fr$laundry_all_1974_pr,
     xlab = "Half Hour", 
     ylab = "Proportion of laundry of that type", 
     pch = 1,
     col = "red")
points(x = laundry_fr$s_halfhour, y = laundry_fr$laundry_all_2005_pr, col = "blue", pch = 2)
# cex = scaling factor
legend('topright',c("All laundry 1974","All laundry 2005"), 
       col=c('red','blue'), pch=c(1,2), cex=1)
title("% of laundry done at different times of day (1974-2005)", cex=0.75)
dev.off()
