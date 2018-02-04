# Using Lotteries To Encourage Saving: Experimental Evidence from Kenya
_Justin Abraham, Merve Akbas, Dan Ariely, and Chaning Jang_

This is a public repository for "Using Lotteries To Encourage Saving: Experimental Evidence from Kenya". We registered a [pre-analysis plan](https://www.socialscienceregistry.org/trials/893) with the AEA RCT Registry that outlines the research question, the experiment, the data, the identification strategy, and our hypotheses. The most recent version of the paper can be found [here](https://github.com/PrincetonBPL/akiba-lottery-pub/raw/master/publication/Paper/Abraham_Akbas_Ariely_Jang_2017.pdf).

### Replication

Releases typically contain the data, source code, survey instruments, and a summary of the research design. Simply run `akiba_master.do` to reproduce tables and figures presented in the manuscript and appendix. These will be output in `tables/` and `figures/`, respectively. Experimental data was collected using Z-Tree. Results published in the manuscript were analyzed using Stata 13.1.

### Directories

The scripts rely on this particular structure. In the future we might just have you specify these are arguments.

+ `code`: Contains source code for cleaning raw data and running analyses.
	- `ado`: Contains canned scripts used in data manipulation, analysis, and publishing.
	- `do`: Primary .do files, esttab tables, and .ado files required for execution.
	- `php`: Scripts for acquiring raw data.
	- `ztree`: .ztt files used in the lab study.
+ `data`: Contains data in various formats.
	- `clean`: Cleaned and merged datasets in wide and long .dta format.
	- `lab`: Raw Z-Tree subject tables from the lab study.
	- `ledger`: Transaction data from SMS savings.
	- `lottery`: Data on lottery results.
	- `pilot`: Pilot study.
	- `questionnaires`: Endline questionnaire, Akiba post-survey, and enrollment data.
+ `documents`: Contains surveys, lab protocols, applications, IRB, and notes.
+ `figures`: Contains output graphs and figures.
+ `presentation`: Contains slides for presentation.
+ `publication`: Contains materials for the manuscript, analysis plan, and online appendix.
+ `tables`: Contains output tables in .tex format.

### Data

All individual-level data has been de-identified to protect respondent privacy.

### Contact

The corresponding author is [Justin Abraham](jabraham@ucsd.edu "jabraham@ucsd.edu").
