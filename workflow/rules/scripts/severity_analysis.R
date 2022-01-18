source("workflow/rules/scripts/utilities.R") #Loads libraries, reads in metadata, functions
library(lubridate)

#List of 1517 CDI sample ids in the cohort
cdi_samples <- metadata %>% 
  filter(group == "case") %>% 
  pull(sample)

#~2500 samples have not had complete clinical data pulled from DataDirect by the Data office.
#For these samples Alieysa pulled the CREAT & WBC values for me from DataDirect.
#She excluded samples that came from outsited UM (no clinical data for patients linked to that sample)
#Also, not all the MRNs she uploaded had values attached to them. For these, samples it is possible that the Data Office will be able to pull the values.

#Read in .csvs from Alieysa's DataDirect pull & relabel/merge----
#Read in serum creatinine values & clean up data frame
creat <- read_csv("data/raw/max_creat.csv") %>% 
  rename(creat = VALUE,
         sample = SAMPLE_ID,
         creat_date = COLLECTION_DATE) %>% #Rename columns
  select(-RESULT_CODE) #Drop column after including this value in other column names

#Read in white blood cell count values & clean up data frame
#Measured in K/ul (1000 cells/uL or thousands per microliter)
wbc <- read_csv("data/raw/max_wbc.csv") %>% 
  rename(wbc = VALUE, 
         sample = SAMPLE_ID,
         wbc_date = COLLECTION_DATE) %>% 
  select(-RESULT_CODE)

#Join creatinine & wbc lab values from DataDirect together
lab_values <- creat %>% 
  full_join(wbc, by = c("sample", "Date.of.Stool.Sample.Collection")) %>% 
  rename(stool_collection_date = Date.of.Stool.Sample.Collection) %>% #rename
  mutate(creat_date = mdy(creat_date), #Transform variable types of columns
         wbc_date = mdy(wbc_date),
         stool_collection_date = mdy(stool_collection_date)) %>% 
  #Select only columns needed to determine severity (These are peak values within 48 hours of stool sampl collection)
  select(sample, creat, wbc, stool_collection_date)

#Check r21_fullcohort_edited on box to get the stool sample collection date for samples we already have clinical data for.
r21_metadata_box <- read_csv("data/raw/r21_fullcohort_edited_deidentified.csv") %>%
  rename(stool_collection_date = Date.of.Stool.Sample.Collection) %>% 
  select(sample, stool_collection_date)
#1493 Case, 24 missing
#2377 Control, 49 missing
#3870 total
#73 samples missing from this list. Likely samples from outside UM (clinical lab is a regional lab). Will never have clinical data for these samples.

#Check stool sample collection date column against the column currenlty listed for metadata 
#Read in lab values for ~1500 samples that the Data Office already pulled clinical data for----
do_lab_values <- read_csv("data/raw/HPI-1878 Lab.csv") %>% 
  #Select columns needed
  select(SAMPLE_ID, LAB_COLLECT_DTTM, RESULT_TEST_CODE, RESULT_VALUE, UNITS) %>% 
  rename(sample = SAMPLE_ID,
         COLLECTION_DATE = LAB_COLLECT_DTTM,
         RESULT_CODE = RESULT_TEST_CODE,
         VALUE = RESULT_VALUE) %>% 
  filter(RESULT_CODE %in% c("CREAT", "WBC")) %>% 
  left_join(r21_metadata_box, by = "sample") %>% 
  mutate(COLLECTION_DATE = mdy_hm(COLLECTION_DATE, tz = "EST"), #Transform character columns into dates
         stool_collection_date = mdy(stool_collection_date),
         VALUE = as.double(VALUE)) %>% #Transform character column into double
  #Figure out time between when lab value was collected and when stool sample was collected (Units= hours)
  mutate(time_from_stool_collection = difftime(stool_collection_date, COLLECTION_DATE, units = "hours")) %>% 
  #select lab values taken within 48 hours of sample collection
  filter(time_from_stool_collection <= 48 & time_from_stool_collection >= -48) %>% 
  group_by(sample, RESULT_CODE) %>% #Group by sample and type of lab test
  mutate(peak_value = max(VALUE)) %>% #Figure out peak_value for each sample
  filter(VALUE == peak_value) %>% #Select just the peak_value rows for each sample 
  distinct(sample, stool_collection_date, RESULT_CODE, peak_value) %>% #Some samples had multiple peak values (same reading multiple times)
  pivot_wider(id_cols = c(sample, stool_collection_date), names_from = RESULT_CODE, values_from = c(peak_value)) %>% 
  #Renmae columns to match the other lab_values dataframe
  rename(creat = CREAT,
         wbc = WBC)

#Combine DataDirect and DataOffice derived lab value data frames
all_lab_values <- lab_values %>% 
  add_row(do_lab_values) %>% 
  left_join(metadata, by = "sample")

#Classify severe CDIs based on IDSA severity criteria
cdi_lab_values <- all_lab_values %>% 
  filter(group == "case") %>% #1159/1517 cases with data
  mutate(idsa_severity = case_when(wbc >= 15 | creat > 1.5 ~ "yes",
                                   TRUE ~ "no")) %>% 
  select(sample, idsa_severity)

#Write out idsa_severity results----
cdi_lab_values %>% 
  write_csv(path = "data/process/case_idsa_severity.csv") 

#Number of severe and non severe CDIs:
cdi_severity_n <- cdi_lab_values %>% 
  select(creat, wbc, idsa_severity) %>% 
  group_by(idsa_severity) %>% 
  tally
#691 Not severe CDIs
#468 severe CDIs

#IDSA Color Scheme
#Define color scheme----
color_scheme <- c("#91bfdb", "#d73027") 
legend_idsa <- c("no", "yes")
legend_labels <- c("Not Severe", "IDSA Severe")

#Plot number of severe and not severe CDIs
idsa_count <- cdi_lab_values %>% 
    ggplot(aes(x=idsa_severity, color = idsa_severity, fill = idsa_severity))+
    geom_bar(show.legend = FALSE) +
    labs(title=NULL, 
         x=NULL)+
    scale_colour_manual(name=NULL,
                        values=color_scheme,
                        breaks=legend_idsa,
                        labels=legend_labels)+
    scale_fill_manual(name=NULL,
                        values=color_scheme,
                        breaks=legend_idsa,
                        labels=legend_labels)+
    scale_x_discrete(label = c("Not Severe", "IDSA Severe"))+
    theme_classic()+
    theme(legend.position = "bottom",
          text = element_text(size = 19),# Change font size for entire plot
          axis.text.x = element_text(angle = 45, hjust = 1), #Angle axis labels
          axis.title.y = element_text(size = 17)) 

#Save tally of severity status
plot_grid(idsa_count)+
  ggsave("results/figures/idsa_severe_n.png", height = 5, width = 4.5)

