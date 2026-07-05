/*==============================================================================
PROJECT:    Factors Associated with Low Birthweight in Zambia
DATA:       2024 Zambia Demographic and Health Survey (ZDHS), n = 3,761
AUTHOR:     Chipo [Surname]
SOFTWARE:   Stata 17

PURPOSE:
This do-file identifies maternal, socioeconomic, and healthcare-access factors
associated with low birthweight (LBW), defined as birthweight < 2,500g.

WORKFLOW:
    1. Descriptive statistics (Table 1)
    2. Bivariate association tests, method chosen per variable type:
         - Chi-square:      categorical vs. categorical
         - Cuzick's nptrend: ordinal exposure vs. binary outcome
         - Rank-sum / t-test: continuous exposure vs. binary outcome
         - Normality checked (Shapiro-Wilk, histograms, kernel density)
           before choosing parametric vs. non-parametric test
    3. Unadjusted logistic regression (crude odds ratios) per variable
    4. Backward stepwise multivariable logistic regression to the final
       parsimonious model

NOTE ON DATA ACCESS:
ZDHS microdata is subject to DHS Program data-use restrictions and is not
redistributed in this repository. Variable names below match the cleaned
extract used for this analysis.
==============================================================================*/

describe

*-----------------------------------------------------------------------------
* 1. DESCRIPTIVE STATISTICS
*-----------------------------------------------------------------------------

** Outcome: Low birthweight
tab lbw
label define lbw1 1 "yes" 0 "no"
label values lbw lbw1

** Residence
tab residence
tab residence lbw, chi2 row col exp

** Maternal education (ordinal -> trend test)
tab maternal_education lbw, row col
nptrend lbw, group(maternal_education) cuzick

** Wealth status (ordinal -> trend test)
tab wealth_status lbw, row col
nptrend lbw, group(wealth_status) cuzick

** Number of children (continuous)
summ children, detail
bysort lbw: summarize children, detail
hist children, norm
kdensity children, norm
ranksum children, by(lbw)          // non-normal distribution -> rank-sum

** Maternal employment
tab maternal_employment
tab maternal_employment lbw, col row exp chi2

** Sex of child
tab sex_of_child
tab sex_of_child lbw, col row exp chi2

** Maternal age (continuous)
summ maternal_age_cont, detail
bysort lbw: summ maternal_age_cont, detail
hist maternal_age_cont, norm
swilk maternal_age_cont            // normality check
graph box maternal_age_cont, by(lbw)
kdensity maternal_age_cont, norm
ranksum maternal_age_cont, by(lbw) // non-normal -> rank-sum

** Marital status
tab marital_status lbw, row col
tab marital_status lbw, col row exp chi2

** Maternal BMI (ordinal -> trend test)
tab maternal_BMI lbw, row col
nptrend lbw, group(maternal_BMI) cuzick

** ANC visits (continuous)
summ ANC_visits_cont, detail
bysort lbw: summ ANC_visits_cont, detail
hist ANC_visits_cont, norm
graph box ANC_visits_cont, by(lbw)
kdensity ANC_visits_cont, norm
ttest ANC_visits_cont, by(lbw)     // approx. normal -> t-test

*-----------------------------------------------------------------------------
* 2. UNADJUSTED (CRUDE) LOGISTIC REGRESSION
*-----------------------------------------------------------------------------

glm lbw residence, family(binomial) link(logit) eform
glm lbw maternal_education, family(binomial) link(logit) eform
glm lbw wealth_status, family(binomial) link(logit) eform
glm lbw children, family(binomial) link(logit) eform
xi: glm lbw i.maternal_employment, family(binomial) link(logit) eform
xi: glm lbw i.sex_of_child, family(binomial) link(logit) eform
glm lbw maternal_age_cont, family(binomial) link(logit) eform
glm lbw marital_status, family(binomial) link(logit) eform
glm lbw maternal_BMI, family(binomial) link(logit) eform
glm lbw ANC_visits_cont, family(binomial) link(logit) eform

*-----------------------------------------------------------------------------
* 3. BACKWARD STEPWISE MULTIVARIABLE REGRESSION
*    Non-significant variables removed one at a time, starting with the
*    variable carrying the weakest evidence of association.
*-----------------------------------------------------------------------------

** Full model (all 10 candidate variables)
glm lbw residence maternal_education wealth_status children ///
    maternal_employment sex_of_child maternal_age_cont marital_status ///
    maternal_BMI ANC_visits_cont, family(binomial) link(logit) eform

** Removed: maternal age
glm lbw residence maternal_education wealth_status children ///
    maternal_employment sex_of_child marital_status maternal_BMI ///
    ANC_visits_cont, family(binomial) link(logit) eform

** Removed: maternal BMI
glm lbw residence maternal_education wealth_status children ///
    maternal_employment sex_of_child marital_status ANC_visits_cont, ///
    family(binomial) link(logit) eform

** Removed: maternal education
glm lbw residence wealth_status children maternal_employment ///
    sex_of_child marital_status ANC_visits_cont, family(binomial) link(logit) eform

** Removed: wealth status
glm lbw residence children maternal_employment sex_of_child ///
    marital_status ANC_visits_cont, family(binomial) link(logit) eform

** Removed: marital status
glm lbw residence children maternal_employment sex_of_child ///
    ANC_visits_cont, family(binomial) link(logit) eform

** Removed: residence
glm lbw children maternal_employment sex_of_child ANC_visits_cont, ///
    family(binomial) link(logit) eform

*-----------------------------------------------------------------------------
* 4. FINAL MODEL
*    Retained: number of children, maternal employment, sex of child,
*    number of ANC visits — all significant at p < 0.05
*-----------------------------------------------------------------------------

xi: glm lbw children i.maternal_employment i.sex_of_child ANC_visits_cont, ///
    family(binomial) link(logit) eform
