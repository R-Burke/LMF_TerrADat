#Get LMF and TerrADat Ecological Site Id field in same format

#You'll need:

library(RODBC) 
library(dplyr) 

#LMF Ecological Site Ids do not have R or F in front... so we need to fix some things

#Read in full csv of ecological site ids from EDIT

#Connect to TerrADat and LMF using SQL
#Connect to TerrADat

conn <- odbcConnect("DataBaseName") #AIM Database name, see tutorial on working with AIM data on BLM computer

TerrADat <- sqlQuery(conn, 'SELECT * FROM .......TerrADat;') #omitted file path here, see tutorial

#Connect to LMF
LMF <- sqlQuery(conn, 'SELECT * FROM .......LMF;')  #omitted file path here, see tutorial

#Read in full Ecological Site Id table from EDIT

EDIT <- read.csv(file = "EDIT_public_ecological_site_list.csv")

#Add a new column with R or F dropped
EDIT[["EcoSiteId_Stripped"]] <- gsub(EDIT[["new_es_symbol"]], 
                                     pattern = "^[RF]", replacement = "")

#Check to see if unique
ecosite_lut <- unique(EDIT[,c("new_es_symbol" , "EcoSiteId_Stripped")])

any(table(ecosite_lut[["EcoSiteId_Stripped"]]) > 1)

#Pull out the repeat ids (fortunatley there are only 15 and none of them occur in the LMF dataset)

trouble_ids <- names(table(ecosite_lut[["EcoSiteId_Stripped"]]))[table(ecosite_lut[["EcoSiteId_Stripped"]]) > 1]

#Drop the repeat ids 
ecosite_lut_drop_bad <- ecosite_lut %>% filter(!EcoSiteId_Stripped == trouble_ids)

#Add a new field called EcologicalSiteId that has the dropped R and F
EcoSites_Update <- ecosite_lut_drop_bad %>% mutate(EcologicalSiteId = EcoSiteId_Stripped)

#Merge the dataframe with the full EcologicalSiteId and dropped R/F Id with the LMF
LMF_EcoSite <- merge(LMF , EcoSites_Update, by = "EcologicalSiteId")

#Drop the EcologicalSiteId value that we added earlier
LMF_EcoSite <- LMF_EcoSite %>% dplyr::select(-EcologicalSiteId) 

#Rename Ecological SIte Id to the full Ecological Site Id code (= new_es_symbol)
LMF_EcoSite <- LMF_EcoSite %>% dplyr::rename(EcologicalSiteId = new_es_symbol)

#Drop ecological site id that doesn't have R or F
LMF_EcoSite <- LMF_EcoSite %>% dplyr::select(-EcoSiteId_Stripped)

#Bind LMF and TerrADat
#Make sure same number of columns and same names
TerrADat[setdiff(names(LMF_EcoSite) , names(TerrADat))] <- NA
LMF_EcoSite[setdiff(names(TerrADat), names(LMF_EcoSite))] <- NA
TDat_LMF <- rbind(TerrADat , LMF_EcoSite)
