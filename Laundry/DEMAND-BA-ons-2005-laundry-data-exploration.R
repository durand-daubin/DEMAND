# Header ###########################################
# ONS Time Use 2005 data
#
# Explorations using R
#
# Script for use as part of: The Social Science of Energy Storage (PSY6018)
#
# Sheffield/Southampton Centre for Doctoral Training in Energy Storage and its Applications
# http://www.southampton.ac.uk/engineering/postgraduate/research_degrees/energy_storage_cdt.page
#
# Copyright (C) 2014  University of Southampton
# 
# Author: Ben Anderson (b.anderson@soton.ac.uk, @dataknut, https://github.com/dataknut) 
# [Energy & Climate Change, Faculty of Engineering & Environment, University of Southampton]
# 
# end header

# To do: -----------------------------------------------------------------

# Prelims -----------------------------------------------------------------

# clear out all old objects etc to avoid confusion
rm(list = ls()) 

# set time
starttime <- proc.time()

# load required packages
packagel <- c("foreign","ggplot2","plyr")
lapply(packagel, require, character.only = T)

# if this breaks/fails because they haven't been installed use
#install.packages("foreign")
#install.packages("ggplot2")
#install.packages("plyr")
# or you can use this line will load all of them from the list above
# NB - this will ask to restart R, click no
#install.packages(packagel)

# path to data & results
# You will need to have downloaded the data from Dropbox/MOLE
# You will need to change these!!

# where's the data?
dpath <- "/Users/ben/Documents/Dropbox/energy-storage-dtc/data/"
# where do you want the results to go?
rpath <- "/Users/ben/Documents/Work/Projects/Sheffield-UoS-Energy-Storage-CDT/results/"

# time axis defnition
# can't get this to work!
# halfhourlab <- "\"04:00\",\"06:00\", \"08:00\", \"10:00\", \"12:00\", \"14:00\", \"16:00\",\"18:00\",\"20:00\",\"22:00\""

# Load long form data -----------------------------------------------------------------
# Time use data in long form - this has data in 10 minute time 'slots'
# It also has a few survey variables attached to each time use slot

tu2005data <- read.csv(paste0(dpath, "UK-2005-TU-merged-long-reduced.csv"))

# Now stop to check what's in it and make sure we understand the format!
head(tu2005data)

# check values of main acts (the things people reported doing) by location
all_acts_by_location <- table("Main acts"= tu2005data$pact)
# ouptput to a csv file so we can keep for reference (useful later)
write.csv(all_acts_by_location, paste0(rpath,"all_acts_by_location-table.csv"), row.names=FALSE, na="")

# check values of months variable (so we see that seasons are represented)
table("Month"= tu2005data$t_month)

# recode month so it is easier to interpret
tu2005data$t_month[tu2005data$t_month == 2] <- "February"
tu2005data$t_month[tu2005data$t_month == 6] <- "June"
tu2005data$t_month[tu2005data$t_month == 9] <- "September"
tu2005data$t_month[tu2005data$t_month == 11] <- "November"

# check the days
table("Days"= tu2005data$s_dow)

# Out of order!
# set the order of the dow factor
tu2005data$s_dow <- factor(tu2005data$s_dow, 
  levels = c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"))

# recheck
table("Days"= tu2005data$s_dow)

# Test: Sleep -----------------------------------------------------------------
tu2005data$sleep_all <- 0
# set to 1 for any sleep (primary or secondary act)
tu2005data$sleep_all[tu2005data$pact == "sleeping" | tu2005data$sact == "sleeping"] <- 1 

# create the summary table for sleep
sleeping <- ddply(tu2005data, c("s_dow", "s_halfhour"), summarise, pc=100*mean(sleep_all))

ylabt <- "sleeping"
# create the plot as an object
sleep_plot <- ggplot(sleeping, aes(x=s_halfhour, y=pc, colour=s_dow, group=s_dow)) + geom_line()
# draw the plot with some options to make it look pretty
sleep_plot + xlab("Time of Day") + 
  ylab(paste("% reporting", ylabt)) + 
  labs(colour="Day of the week") +
  scale_x_discrete(breaks=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30"),
                   labels=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30")) +
  theme(axis.text.x = element_text(angle=90, hjust=1, vjust=1))
# does that look about right?

# save the plot
ggsave(paste0(rpath,"sleep_tod_plot.pdf"), width=12, height=8, unit="cm", dpi=300) 

# Test: all acts -----------------------------------------------------------------
# add a dummy variable we can count
tu2005data$count <- 1
# create a table which counts the occurences of 'pact' in each 10 minute slot
all_acts <- ddply(tu2005data, c("s_starttime","pact"), summarise, count=sum(count))

# draw an unintelligible line graph using the table
all_acts_lplot <- ggplot(all_acts, aes(x=s_starttime, y=count, colour=pact, group=pact)) + geom_line()
all_acts_lplot + xlab("Time of Day") + ylab("N reporting") + 
  labs(colour="Activity") +
  scale_x_discrete(breaks=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30"),
                   labels=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30")) +
  theme(axis.text.x = element_text(angle=90, hjust=1, vjust=1)) +
  theme(legend.position="right")
# save the plot
ggsave(paste0(rpath,"all_acts_tod_lineplot.pdf"), width=12, height=8, unit="cm", dpi=300) 

# and an unintelligible stacked chart
all_acts_stplot <- ggplot(all_acts, aes(x=s_starttime, y=count, fill=pact, group=pact)) + geom_area()
all_acts_stplot + xlab("Time of Day") + ylab("N reporting") + 
  labs(fill="Activity") +
  scale_x_discrete(breaks=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30"),
                   labels=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30")) +
  theme(axis.text.x = element_text(angle=90, hjust=1, vjust=1)) +
  theme(legend.position="right")
# save the plot
ggsave(paste0(rpath,"all_acts_tod_stackedplot.pdf"), width=12, height=8, unit="cm", dpi=300) 

# What we really want to do is to create a new column with primary acts where travel is collapsed to 1
# Something like:
#tu2005data$pact_n <- tu2005data$pact
#tu2005data$pact_n[charmatch("travel", tu2005data$pact ) !=1] <- "travel"

# Practices: Laundry -----------------------------------------------------------------
# Interesting of itself but we also want to try to compare the results with the HES data
# set our y axis label
ylabt <- "laundry"
tu2005data$laundry_all <- 0
# we're interested in laundry at home (for now!)
tu2005data$laundry_all[tu2005data$pact == "washing clothes" & 
                         tu2005data$lact != "elsewhere" |
                         tu2005data$sact == "washing clothes" & 
                         tu2005data$lact != "elsewhere"] <- 1 

# make the table
laundry <- ddply(tu2005data, c("s_dow", "s_halfhour"), summarise, pc=100*mean(laundry_all))
# plot it
laundry_plot <- ggplot(laundry, aes(x=s_halfhour, y=pc, colour=s_dow, group=s_dow)) + geom_line()
laundry_plot + xlab("Time of Day") + 
  ylab(paste("% reporting", ylabt)) + 
  labs(colour="Day of the week") +
  scale_x_discrete(breaks=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30"),
                   labels=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30")) +
  theme(axis.text.x = element_text(angle=90, hjust=1, vjust=1))
# save the plot
ggsave(paste0(rpath,"laundry_tod_dow_plot.pdf"), width=12, height=8, unit="cm", dpi=300)

# try a contour plot/heat map to make day of the week easier to see
laundry_hmplot <- ggplot(laundry, aes(x=s_halfhour, y=s_dow, fill=pc))
laundry_hmplot + geom_raster() + xlab("Time of Day") + 
  ylab("Day of week") +
  labs(fill=paste("% reporting", ylabt)) +
  theme(legend.position="bottom") +
  scale_x_discrete(breaks=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30"),
                   labels=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30")) +
  theme(axis.text.x = element_text(angle=90, hjust=1, vjust=1))
# save the plot
ggsave(paste0(rpath,"laundry_tod_dow_hmplot.pdf"), width=12, height=8, unit="cm", dpi=300)

# now try by age group to analyse differences
laundry_age <- ddply(tu2005data, c("agegrp", "s_halfhour"), summarise, pc=100*mean(laundry_all))
laundry_plot <- ggplot(laundry_age, aes(x=s_halfhour, y=pc, colour=agegrp, group=agegrp)) + geom_line()
laundry_plot + xlab("Time of Day") + 
  ylab(paste("% reporting", ylabt)) + 
  labs(colour="Age group") +
  scale_x_discrete(breaks=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30"),
                   labels=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30")) +
  theme(axis.text.x = element_text(angle=90, hjust=1, vjust=1))
# save the plot
ggsave(paste0(rpath,"laundry_tod_by_age_plot.pdf"), width=12, height=8, unit="cm", dpi=300)

# working status
laundry_wrk <- ddply(tu2005data, c("wrking", "s_halfhour", "s_dow"), summarise, pc=100*mean(laundry_all))
laundry_plot <- ggplot(laundry_wrk, aes(x=s_halfhour, y=pc, colour=wrking, group=wrking)) + geom_line()
laundry_plot + xlab("Time of Day") + 
  ylab(paste("% reporting", ylabt)) + 
  labs(colour="Working status") +
  scale_x_discrete(breaks=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30"),
                   labels=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30")) +
  theme(axis.text.x = element_text(angle=90, hjust=1, vjust=1)) +
  facet_wrap( ~ s_dow) +
  theme(legend.position=c(0.5,0.2))
# save the plot
ggsave(paste0(rpath,"laundry_tod_by_working_plot.pdf"), width=12, height=8, unit="cm", dpi=300)

# To compare with the HES data on 'washing/drying' we need to create a table by weekend ('holiday') vs weekday
# And it needs to have 10 minute time slots as the HES data is in 10 minute chunks
tu2005data$weekend <- "Weekday"
tu2005data$weekend[tu2005data$s_dow == "Saturday" | tu2005data$s_dow == "Sunday"] <- "Weekend"
# check
table(tu2005data$s_dow,tu2005data$weekend)

laundry_hes <- ddply(tu2005data, c("weekend", "s_starttime"), summarise, pc=100*mean(laundry_all))
laundry_hes_plot <- ggplot(laundry_hes, aes(x=s_starttime, y=pc, colour=weekend, group=weekend)) + geom_line()
laundry_hes_plot + xlab("Time of Day") + 
  ylab(paste("% reporting", ylabt)) + 
  labs(colour="Weekday/Weekend") +
  scale_x_discrete(breaks=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30"),
                   labels=c("00:00","04:00","08:00","12:00","16:00","20:00","23:30")) +
  theme(axis.text.x = element_text(angle=90, hjust=1, vjust=1))
ggsave(paste0(rpath,"laundry_tod_hes_plot.pdf"), width=12, height=8, unit="cm", dpi=300)

# to get the data on the same graph as the HES results we need to export the table we made
# -> csv with blank cells where na
# NB this is long form - we could switch it to wide form to make it easier
write.csv(laundry_hes, paste0(rpath,"laundry_tod_hes_compare_data.csv"), row.names=FALSE, na="")

print("Done!")
# stop clock - how long did that take?
proc.time() - starttime