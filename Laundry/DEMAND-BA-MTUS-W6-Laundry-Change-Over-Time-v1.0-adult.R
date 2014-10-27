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

# set up some useful vars
ifile_d <- c("~/Documents/Work/Data/Social Science Datatsets/MTUS/World 6/processed/MTUS-adult-episode-UK-only-wf.dta")
ifile_s <- c("~/Documents/Work/Data/Social Science Datatsets/MTUS/World 6/processed/MTUS-adult-aggregate-UK-only-wf.dta")
  
rpath <- "How to set this as a string to be concatenated with a file name?"

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
  
# primary
laundry_p_tod <- aggregate(MTUSW6UK_m$laundry_p, by=list(MTUSW6UK_m$s_halfhour), FUN=sum)
names(laundry_p_tod) <- c("s_halfhour","p_laundry_freq") 
# how many laundry episodes are there?
lpsum <-sum(laundry_p_tod$p_laundry_freq)
laundry_fr$p_laundry_pc <- (laundry_p_tod$p_laundry_freq/lpsum) * 100

# secondary
laundry_s_tod <- aggregate(MTUSW6UK_m$laundry_s, by=list(MTUSW6UK_m$s_halfhour), FUN=sum)
names(laundry_s_tod) <- c("s_halfhour","s_laundry_freq") 
lssum <-sum(laundry_s_tod$s_laundry_freq)
laundry_fr$s_laundry_pc <- (laundry_s_tod$s_laundry_freq/lssum) * 100

# all
laundry_all_tod <- aggregate(MTUSW6UK_m$laundry_all, by=list(MTUSW6UK_m$s_halfhour), FUN=sum)
names(laundry_all_tod) <- c("s_halfhour","all_laundry_freq") 
lasum <-sum(laundry_all_tod$all_laundry_freq)
laundry_fr$all_laundry_pc <- (laundry_all_tod$all_laundry_freq/lasum) * 100

# I want a line plot here with primary & secndary...
plot(laundry_fr)

# check time of day for laundry for each year
for(s in c(1974,2005)) {
  laundry_all_todtemp <- aggregate(MTUSW6UK_m$laundry_all[survey==s], by=list(MTUSW6UK_m$s_halfhour[survey==s]), FUN=sum)
  # fix variable names
  names(laundry_all_todtemp) <- c("s_halfhour","freq") 
  # add up number of laundry episodes in each survey
  lsum <-sum(laundry_all_todtemp$freq)
  
  # % laundry done in any gven half hour in this year
  # how to get s to assign the year to the column name??
  laundry_all_tod$laundry_pc_s <- (laundry_all_tod$freq/lsum) * 100
  
  # direct graph to file
  png("/Users/ben/Documents/Work/Projects/RCUK-DEMAND/Theme 1/results/MTUS/laundry-time-of-day-s.jpg")
  plot(laundry_all_tod$s_halfhour, xlab = "Half hour (s)", laundry_all_tod$laundry_pc, ylab = "% laundry done")
  title("% of laundry done at different times of day (s)")
  dev.off()
}

