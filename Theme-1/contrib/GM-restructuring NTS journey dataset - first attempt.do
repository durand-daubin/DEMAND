/*

giulio.mattioli@gmail.com

 I want to restructure the journey dataset, to transform it into a TUS format 
the datasets that I am using is a very small extract of the 2002-2010 dataset 
including only 2010 and only trips for the first 100 individuals (corresponding 
roughly to 2000 journeys)*/

*** change dropbox path to use on another computer 

use "C:\Users\Giulio\Dropbox\Aberdeen\Job\Paper 2\journey prova 2010 1-100.dta"

/* the variables of interest are 
J54 "Journey Start Time (minutes past midnight - unbanded)" (there is also banded!) 
J59 "Journey End Time (minutes past midnight - unbanded)" (there is also banded!) 
*/

/* problems: 
- there are 18 cases where start & end time is missing (over 2000, so 1%? check with whole dataset)
- how to deal with weights?
- how to deal with walking trips under 1 mile on the 7th day? 
- use journey pupose j28 or both journey purpose from and to? 
- many journeys end in the following day (j59>1440), how to deal with that
	they should be cut at midnight and the remaining fragment be assigned to the next day... sounds complicated 
	and probably there aren't many food shopping grips around midnight: if I can demonstrate this, I have a good reason not to do it! 

one obvious solution would be to delete them all 
*/

* first naif attempt would be 

* need some IDs 

* first I need a reshape 

keep h96-j3 j54 j59 j28

reshape wide j54 j59 j28, i(h96 psuid h88 i1 d1) j(j3)

renpfix j28 purp
renpfix j54 start
renpfix j59 end


set trace on

local start_1 "00:00"
local start_2 "00:10"
local start_3 "00:20"
local start_4 "00:30"
local start_5 "00:40"
local start_6 "00:50"
local start_7 "01:00"
local start_8 "01:10"
local start_9 "01:20"
local start_10 "01:30"
local start_11 "01:40"
local start_12 "01:50"
local start_13 "02:00"
local start_14 "02:10"
local start_15 "02:20"
local start_16 "02:30"
local start_17 "02:40"
local start_18 "02:50"
local start_19 "03:00"
local start_20 "03:10"
local start_21 "03:20"
local start_22 "03:30"
local start_23 "03:40"
local start_24 "03:50"
local start_25 "04:00"
local start_26 "04:10"
local start_27 "04:20"
local start_28 "04:30"
local start_29 "04:40"
local start_30 "04:50"
local start_31 "05:00"
local start_32 "05:10"
local start_33 "05:20"
local start_34 "05:30"
local start_35 "05:40"
local start_36 "05:50"
local start_37 "06:00"
local start_38 "06:10"
local start_39 "06:20"
local start_40 "06:30"
local start_41 "06:40"
local start_42 "06:50"
local start_43 "07:00"
local start_44 "07:10"
local start_45 "07:20"
local start_46 "07:30"
local start_47 "07:40"
local start_48 "07:50"
local start_49 "08:00"
local start_50 "08:10"
local start_51 "08:20"
local start_52 "08:30"
local start_53 "08:40"
local start_54 "08:50"
local start_55 "09:00"
local start_56 "09:10"
local start_57 "09:20"
local start_58 "09:30"
local start_59 "09:40"
local start_60 "09:50"
local start_61 "10:00"
local start_62 "10:10"
local start_63 "10:20"
local start_64 "10:30"
local start_65 "10:40"
local start_66 "10:50"
local start_67 "11:00"
local start_68 "11:10"
local start_69 "11:20"
local start_70 "11:30"
local start_71 "11:40"
local start_72 "11:50"
local start_73 "12:00"
local start_74 "12:10"
local start_75 "12:20"
local start_76 "12:30"
local start_77 "12:40"
local start_78 "12:50"
local start_79 "13:00"
local start_80 "13:10"
local start_81 "13:20"
local start_82 "13:30"
local start_83 "13:40"
local start_84 "13:50"
local start_85 "14:00"
local start_86 "14:10"
local start_87 "14:20"
local start_88 "14:30"
local start_89 "14:40"
local start_90 "14:50"
local start_91 "15:00"
local start_92 "15:10"
local start_93 "15:20"
local start_94 "15:30"
local start_95 "15:40"
local start_96 "15:50"
local start_97 "16:00"
local start_98 "16:10"
local start_99 "16:20"
local start_100 "16:30"
local start_101 "16:40"
local start_102 "16:50"
local start_103 "17:00"
local start_104 "17:10"
local start_105 "17:20"
local start_106 "17:30"
local start_107 "17:40"
local start_108 "17:50"
local start_109 "18:00"
local start_110 "18:10"
local start_111 "18:20"
local start_112 "18:30"
local start_113 "18:40"
local start_114 "18:50"
local start_115 "19:00"
local start_116 "19:10"
local start_117 "19:20"
local start_118 "19:30"
local start_119 "19:40"
local start_120 "19:50"
local start_121 "20:00"
local start_122 "20:10"
local start_123 "20:20"
local start_124 "20:30"
local start_125 "20:40"
local start_126 "20:50"
local start_127 "21:00"
local start_128 "21:10"
local start_129 "21:20"
local start_130 "21:30"
local start_131 "21:40"
local start_132 "21:50"
local start_133 "22:00"
local start_134 "22:10"
local start_135 "22:20"
local start_136 "22:30"
local start_137 "22:40"
local start_138 "22:50"
local start_139 "23:00"
local start_140 "23:10"
local start_141 "23:20"
local start_142 "23:30"
local start_143 "23:40"
local start_144 "23:50"

local end_1 "00:10"
local end_2 "00:20"
local end_3 "00:30"
local end_4 "00:40"
local end_5 "00:50"
local end_6 "01:00"
local end_7 "01:10"
local end_8 "01:20"
local end_9 "01:30"
local end_10 "01:40"
local end_11 "01:50"
local end_12 "02:00"
local end_13 "02:10"
local end_14 "02:20"
local end_15 "02:30"
local end_16 "02:40"
local end_17 "02:50"
local end_18 "03:00"
local end_19 "03:10"
local end_20 "03:20"
local end_21 "03:30"
local end_22 "03:40"
local end_23 "03:50"
local end_24 "04:00"
local end_25 "04:10"
local end_26 "04:20"
local end_27 "04:30"
local end_28 "04:40"
local end_29 "04:50"
local end_30 "05:00"
local end_31 "05:10"
local end_32 "05:20"
local end_33 "05:30"
local end_34 "05:40"
local end_35 "05:50"
local end_36 "06:00"
local end_37 "06:10"
local end_38 "06:20"
local end_39 "06:30"
local end_40 "06:40"
local end_41 "06:50"
local end_42 "07:00"
local end_43 "07:10"
local end_44 "07:20"
local end_45 "07:30"
local end_46 "07:40"
local end_47 "07:50"
local end_48 "08:00"
local end_49 "08:10"
local end_50 "08:20"
local end_51 "08:30"
local end_52 "08:40"
local end_53 "08:50"
local end_54 "09:00"
local end_55 "09:10"
local end_56 "09:20"
local end_57 "09:30"
local end_58 "09:40"
local end_59 "09:50"
local end_60 "10:00"
local end_61 "10:10"
local end_62 "10:20"
local end_63 "10:30"
local end_64 "10:40"
local end_65 "10:50"
local end_66 "11:00"
local end_67 "11:10"
local end_68 "11:20"
local end_69 "11:30"
local end_70 "11:40"
local end_71 "11:50"
local end_72 "12:00"
local end_73 "12:10"
local end_74 "12:20"
local end_75 "12:30"
local end_76 "12:40"
local end_77 "12:50"
local end_78 "13:00"
local end_79 "13:10"
local end_80 "13:20"
local end_81 "13:30"
local end_82 "13:40"
local end_83 "13:50"
local end_84 "14:00"
local end_85 "14:10"
local end_86 "14:20"
local end_87 "14:30"
local end_88 "14:40"
local end_89 "14:50"
local end_90 "15:00"
local end_91 "15:10"
local end_92 "15:20"
local end_93 "15:30"
local end_94 "15:40"
local end_95 "15:50"
local end_96 "16:00"
local end_97 "16:10"
local end_98 "16:20"
local end_99 "16:30"
local end_100 "16:40"
local end_101 "16:50"
local end_102 "17:00"
local end_103 "17:10"
local end_104 "17:20"
local end_105 "17:30"
local end_106 "17:40"
local end_107 "17:50"
local end_108 "18:00"
local end_109 "18:10"
local end_110 "18:20"
local end_111 "18:30"
local end_112 "18:40"
local end_113 "18:50"
local end_114 "19:00"
local end_115 "19:10"
local end_116 "19:20"
local end_117 "19:30"
local end_118 "19:40"
local end_119 "19:50"
local end_120 "20:00"
local end_121 "20:10"
local end_122 "20:20"
local end_123 "20:30"
local end_124 "20:40"
local end_125 "20:50"
local end_126 "21:00"
local end_127 "21:10"
local end_128 "21:20"
local end_129 "21:30"
local end_130 "21:40"
local end_131 "21:50"
local end_132 "22:00"
local end_133 "22:10"
local end_134 "22:20"
local end_135 "22:30"
local end_136 "22:40"
local end_137 "22:50"
local end_138 "23:00"
local end_139 "23:10"
local end_140 "23:20"
local end_141 "23:30"
local end_142 "23:40"
local end_143 "23:50"
local end_144 "00:00"


foreach s of numlist 1/144 {
	
	gen fstrip`s'=0
	lab var fstrip`s' "Food shopping trip between `start_`s'' and `end_`s''" 
	
	foreach t of numlist 0/14  {
		
		* the max number of trips on a diary day IN THIS SAMPLE is 15 (the first is counted as 0)
		* (this should be changed accordingly when using other samples)
		
		* four possible matching cases 
		* (invariant validity conditions are in the second line)
		
		* 1) fs journey begins before and ends during the slot
		replace fstrip`s'=1 if purp`t'==4 & start`t'<(`s'-1)*10 & end`t'>(`s'-1)*10 & end`t'<=((`s'-1)*10+10) ///
		& start`t'>=0 & start`t'<1440 & end`t'>0 
		
		* 2) fs journey begins and ends during the slot
		replace fstrip`s'=1 if purp`t'==4 & start`t'>=(`s'-1)*10 & start`t'<((`s'-1)*10+10) & end`t'>(`s'-1)*10 & end`t'<=((`s'-1)*10+10) ///
		& start`t'>=0 & start`t'<1440 & end`t'>0 
		
		* 3) fs journey begins during the slot and ends after
		replace fstrip`s'=1 if purp`t'==4 & start`t'>=(`s'-1)*10  & start`t'<((`s'-1)*10+10) & end`t'>((`s'-1)*10+10) ///
		& start`t'>=0 & start`t'<1440 & end`t'>0 
		
		* 4) fs journey begins before the slot and ends after
		replace fstrip`s'=1 if purp`t'==4 & start`t'<(`s'-1)*10  & end`t'>((`s'-1)*10+10) ///
		& start`t'>=0 & start`t'<1440 & end`t'>0 
			
	}
}

*** it seems to work fine 
*** need to find some kind of check 

egen fsday=rowtotal(fstrip*)

*** and then browse and do manual check 

*** + compare with results for this indicator 

egen fsday_t=anycount(purp*), values(4)

*** episodes appear lagged of 1 time slot1 - but this is ok since slot 1: 0-10, slot 2: 10-20, etc. 

*** it works fine, but problems listed above need to be resolved 

