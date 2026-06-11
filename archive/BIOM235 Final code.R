library(dplyr)
library(tidyverse)
library(readxl)
library(tidyr)
library(polyglotr)
library(table1)
library(labelled)
library(openxlsx)
library(tableone)
library(summarytools)
library(ggplot2)
library(nhanesA)
library(purrr)
library(writexl)

##Downloading the dataset from NHANES/CDC 

raw_demo <- nhanes('P_DEMO')

raw_insurance<- nhanes('P_HIQ')

raw_diabetes<-nhanes('P_DIQ')

raw_BMI<-nhanes('P_BMX')

raw_smoke<-nhanes('P_SMQ')

raw_health<-nhanes('P_HUQ')

##Combine the three datasets

combined_list <- list(raw_demo, raw_insurance, raw_diabetes, raw_BMI, raw_smoke, raw_health)

combined_raw <- combined_list %>% reduce(full_join, by = "SEQN")


############ Filtering for the final dataset

#Excluding those with reported diabetes (DIQ010), 20+ years old and are pregnant (RIDEXPRG)

over20_df<-filter(combined_raw, RIDAGEYR >=20)

diabetes_df<-filter(over20_df, DIQ010 != "Yes"| is.na(DIQ010))

pregnant_df<-filter(diabetes_df, RIDEXPRG != "Yes, positive lab pregnancy test or self-reported pregnant at exam"| is.na(RIDEXPRG))


#filtering for those who answered responded to the insurance status (HIQ011)

combined_insurance_df<-filter(pregnant_df, HIQ011== "Yes" | HIQ011== "No") 

#filtering for those who answered responded to blood screening question(DIQ180)

diabetes_insurance_df<-filter(combined_insurance_df, DIQ180== "Yes" | DIQ180== "No")

#Creating final dataset: Selecting for columns associated with the exposure, outcome, confounders and prognostic variables

final_DF <- select(diabetes_insurance_df, SEQN,RIDAGEYR, DMDBORN4, SIALANG, INDFMPIR, RIDRETH1, DMDEDUC2, SMQ020, BMXBMI, DIQ160, HUQ010)


##exporting the data

setwd("C:/Users/ajmil/OneDrive/Data")

write_xlsx(final_DF, "BIOM235_dataset_AM.xlsx")








