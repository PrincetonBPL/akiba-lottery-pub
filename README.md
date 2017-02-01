# Using Lotteries To Encourage Saving: Experimental Evidence from Kenya

This is a public repository for the AKIBA Smart lottery-linked savings program evaluation. We registered a [pre-analysis plan](https://www.socialscienceregistry.org/trials/893) with the AEA RCT Registry that outlines the research question, the experiment, the data, the identification strategy, and our hypotheses. The most recent version of the paper can be found [here](https://github.com/PrincetonBPL/akiba-lottery-pub/raw/master/publication/Paper/Abraham_Akbas_Ariely_Jang_2017.pdf).

### Directories

The scripts rely on this particular structure. In the future we might just have you specify these are arguments.

+ `code`: Contains scripts for cleaning raw data and running analyses.
	- `stata`: Primary .do files, esttab tables, and .ado files required for execution.
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
+ `publication`: Contains materials for the paper, PAP, and online appendix.
+ `tables`: Contains output tables in .tex format.

### Scripts

Best practice is to run all Stata program through the master .do file.

### Data

All individual-level data has been de-identified to protect respondent privacy.

### Replication

These will be instructions for replicating the paper. Will probably add a Python script.

### Contact

Comments? Questions? Send a message to [Justin Abraham](justin.abraham@busaracenter.com "justin.abraham@busaracenter.com").
