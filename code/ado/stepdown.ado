*! version 12jul2017 by JA to allow p = 1
*stepdown reg (hap1 sat1) treat spillover if ~purecontrol, options(r cluster(village)) iter(100)
program define stepdown, rclass
	gettoken cmd 0 : 0
	gettoken depvars 0 : 0, parse("(") match(par)
	syntax varlist [if] [in] [aweight], ITER(integer) [OPTions(string)] [TYPE(string)] [CONTROLstems(string)]
	gettoken treat varlist : varlist

	local weights "[`weight' `exp']"

	dis "depvars: `depvars'; treat: `treat'; varlist: `varlist'; weights: `weights'; options: `options'; iter: `iter'; controlstems: `controlstems'"

quietly {
if "`iter'" == "" {
	local iter 100
	dis "Number of iterations not specified; `iter' assumed."
	}

if "`type'" == "" {
	local type "fwer"
	dis "FWER or FDR not specified; default to FWER."
	}

set seed 1073741823

* generate variables to store actual and simulated t-stats/p-vals
local counter = 1
tempvar varname tstat act_pval tstatsim pvalsim pvals

gen str20 `varname' = ""
gen float `tstat' = .
gen float `act_pval' = .
gen float `tstatsim' = .
gen float `pvalsim' = .
gen float `pvals' = .

foreach x of varlist `depvars' {

	local controlvars ""
    if "`controlstems'"~="" {
		foreach stem in `controlstems' {
			local controlvars "`controlvars' `x'`stem'"
		}
	}
	di "`cmd' `x' `treat' `varlist' `controlvars' `if' `in' `weights', `options'"
	    `cmd' `x' `treat' `varlist' `controlvars' `if' `in' `weights', `options'

    replace `tstat' = abs(_b[`treat']/_se[`treat']) in `counter'
    replace `act_pval' = 2*ttail(e(N),abs(`tstat')) in `counter'
    replace `varname' = "`x'" in `counter'
    local `x'_ct_0 = 0
    local counter = `counter' + 1
}

sum `treat'
local cutoff = `r(mean)'

local numvars = `counter' - 1
dis "numvars: `numvars'"

* sort the p-vals by the actual (observed) p-vals (this will reorder some of the obs, but that shouldn't matter)
tempvar porder
gen `porder' = _n in 1/`numvars'
gsort `act_pval'

* generate the variable that will contain the simulated (placebo) treatments
tempvar simtreatment simtreatment_uni
gen byte `simtreatment' = .
gen float `simtreatment_uni' = .
local count = 1

} // quietly

* run 10,000 iterations of the simulation, record results in p-val storage counters
while `count' <= `iter' {
	dis "`count'/`iter'"
quietly {
	* in this section we assign the placebo treatments and run regressions using the placebo treatments
	replace `simtreatment_uni' = uniform()
	replace `simtreatment' = (`simtreatment_uni'<=`cutoff')
	replace `tstatsim' = .
	replace `pvalsim' = .
	foreach lhsvar of numlist 1/`numvars' {
	    local depvar = `varname'[`lhsvar']
		local controlvars ""
    	if "`controlstems'"~="" {
			foreach x in `controlstems' {
				local controlvars "`controlvars' `depvar'`x'"
			}
		}

		cap {
			`cmd' `depvar' `simtreatment' `varlist' `controlvars' `if' `in' `weights', `options'
			replace `tstatsim' = abs(_b[`simtreatment']/_se[`simtreatment']) in `lhsvar'
		    replace `pvalsim' = 2*ttail(e(N),abs(`tstatsim')) in `lhsvar'
		}
		if _rc {
			replace `pvalsim' = 1 in `lhsvar'
		}
    }
	* in this section we perform the "step down" procedure that replaces simulated p-vals with the minimum of the set of simulated p-vals associated with outcomes that had actual p-vals greater than or equal to the one being replaced.  For each outcome, we keep count of how many times the ultimate simulated p-val is less than the actual observed p-val.
    local countdown `numvars'
    while `countdown' >= 1 {
        replace `pvalsim' = min(`pvalsim',`pvalsim'[_n+1]) in `countdown'
        local depvar = `varname'[`countdown']
        if `pvalsim'[`countdown'] <= `act_pval'[`countdown'] {
            local `depvar'_ct_0 = ``depvar'_ct_0' + 1
            dis "Counter `depvar': ``depvar'_ct_0'"
            }
        local countdown = `countdown' - 1
    	}
    local count = `count' + 1
	} // quietly
} // iterations

quietly {
foreach lhsvar of numlist 1/`numvars' {
	local thisdepvar =`varname'[`lhsvar']
    replace `pvals' = max(round(``thisdepvar'_ct_0'/`iter',.001), `pvals'[`lhsvar'-1]) in `lhsvar'
    }

tempname pvalmatrix ordermatrix combmatrix finalmatrix
mkmat `pvals', matrix(`pvalmatrix')
matrix `pvalmatrix' = `pvalmatrix'[1..`numvars',1]'

mkmat `porder', matrix(`ordermatrix')
matrix `ordermatrix' = `ordermatrix'[1..`numvars',1]'
mat def `combmatrix' = (`ordermatrix' \ `pvalmatrix')'
mata : st_matrix("`combmatrix'", sort(st_matrix("`combmatrix'"), 1))
matrix `finalmatrix' = `combmatrix'[1..`numvars',2]'

*return matrix pvalordered = `pvalmatrix'
*return matrix order = `ordermatrix'
return matrix p = `finalmatrix'

cap drop `tstatsim' `pvalsim' `simtreatment'*
} //quietly

end
exit
