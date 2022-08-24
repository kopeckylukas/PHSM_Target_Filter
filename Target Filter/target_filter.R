######################### Libraries ###########################
library(readxl)
library(tidyverse)
library(data.table)
library(writexl)
library("xlsx")

######################### Load Data #################################
setwd("~/PHSM/Target Filter")

## Load Data - Contains: taxonomy, unique_dictionary, list of valid countries
load("data_v3.RData")

## Load Mistress Dataset
unique_dictionary <- read.csv("Data_CSV/lookup_dictionary.csv")

## Load Mistress Dataset 
mistress <- read.csv("mistress_latest.csv")

######################## Filter Targets #############################

## Check Targets function 
check_targets <- function(data_in, taxo, dictionary_un, country_list){
  
  #Set categories to be filtered
  cat_of_interrest <- c("1.4","4.1.1","4.1.2","4.2.1","4.2.2","4.3.1", "4.3.2", "4.3.3", "4.3.4",
                        "4.5.1", "4.5.2", "4.5.3", "4.5.4", "5.3", "5.5", "5.7", "5.9")
 
  #Set Up columns
  data_in$valid_targets <- NA
  data_in$invalid_targets <- NA
  
  
  #iterate through data
  for(i in 1:nrow(data_in)) { 
    
    #DISPLAY PROGRESS
    cat("\r ","Processed ",round((i / nrow(data_in))*100), "% | ",i, "/", nrow(data_in))
    
  
    
    #match row target with taxonomy
    row_code <- data_in$who_code[i]                                  #Get code from mistress
    if(!(row_code %in% cat_of_interrest)) next
    current_targets <- taxo[taxo[,1] == row_code ,2]                 #Match code with taxonomy
    #Get targets for current code
    current_targets <- na.omit(trimws(unlist(strsplit(current_targets$Target, split=","))))
    
    #Add Country list if International 
    if (row_code %in% c("5.3", "5.5", "5.7", "5.9")){
      current_targets <- c(current_targets, unlist(country_list, use.names = FALSE))
    }
    
    #Extract targets from mistress
    current_row_tar <- data_in$targeted[i]
    if(is.na(current_row_tar )) next                                     #if empty skips process
    current_row_tar <- trimws(unlist(strsplit(current_row_tar, split=",")))
    current_row_tar <- current_row_tar[current_row_tar != ""]
    
    ### VALIDATE TARGETED TO TARGETS
    validation_vector <- tolower(current_row_tar) %in% tolower(current_targets) ####
    ###
    
    
    ## Process Validated Targets
    
      #save valid targets to 'valid'
    valid <- current_row_tar[validation_vector]
    
      #PROCESS INVALID CASES
    if(FALSE %in% validation_vector){
      incor_cases <- current_row_tar[!validation_vector]
      
      #NUMERICAL 4.3.X
      if (row_code %in% c("4.3.1", "4.3.2", "4.3.3", "4.3.4")){

        reg_4.3 <- "[[:digit:]]+ indoors|[[:digit:]]+ outdoors|[[:digit:]]+%|[[:digit:]]+ households|[[:digit:]]+ funerals|[[:digit:]]+ weddings|[[:digit:]]+"
        
        mat<- regmatches(incor_cases, gregexpr(reg_4.3, incor_cases))
        mat<-lapply(mat, function(x) if(identical(x, character(0))) NA_character_ else x)
        vec_mat <- unlist(mat)
        
        val_mat <- ifelse(is.na(vec_mat), FALSE, TRUE)
        
        incor_cases <- incor_cases[!val_mat]
          
        valid <- c(valid, vec_mat[val_mat])
      
        
        }
      
      
      #DICTIONARY 
      #declares what targets are in dictionary
      in_dictionary <- c("1.4","4.1.1","4.1.2","4.2.1","4.2.2", "4.3.3", "4.3.4", "4.3.1", "4.3.2",
                         "4.5.1", "4.5.2", "4.5.3", "4.5.4", "5.3", "5.5", "5.7", "5.9")
      
      #"4.3.3", "4.3.4", "4.3.1", "4.3.2",
      
      #runs dictionary check for those targets
        if (row_code %in% in_dictionary){
        #find dictionary for current target
        dict_cat <- dictionary_category(row_code, dictionary_un)
        #
        # #retrieve dictionary
        unique_column <- c(dict_cat$unq)
        counterparts <- c(dict_cat$ctr)
        #
        # #matching dictionary add to valid
        dictionary_vector <- tolower(unique_column) %in% tolower(incor_cases)
        matching_dict <- counterparts[dictionary_vector]
        valid <- c(valid, matching_dict[!is.na(matching_dict)])
        #
       
        #
        # #non-matching dictionary add to invalid column
        incor_vector <- tolower(incor_cases) %in% tolower(unique_column)
        incor_cases <- incor_cases[!incor_vector]
      }
      
      
   
      
    #SAVE INVALID TARGETS
      if(length(incor_cases)==0){
          data_in$invalid_targets[i] <- NA #save NA if Empty
      } else {
        
        # Mitigate NA Cases
        na_mit <- "NA" %in% incor_cases
        incor_cases <- incor_cases[!na_mit]
          data_in$invalid_targets[i] <- paste(unique(incor_cases), collapse = ", ")
      }
    }else{
      data_in$invalid_targets[i] <- NA #save NA if Empty 
    }
   
    
    #SAVE VALID TARGETS
    if(length(valid)==0){
        data_in$valid_targets[i] <- NA #save NA if Empty
    } else {
      
      #Mitigate NA string values 
      na_mit <- "NA" %in% valid
      valid <- valid[!na_mit]
      valid <- unique(valid)
      valid <- valid[valid != ""]
      
      data_in$valid_targets[i] <- paste(unique(valid), collapse = ", ")
    }
    
    
    
  }
  
  
  return(data_in)
}


dictionary_category <- function (who_code, dictionary_un){
  
  if(who_code == "1.4"){
    dictionary_un <- dictionary_un[,1:2]
  } else if(who_code == "4.1.1"){
    dictionary_un <- dictionary_un[,3:4]
  } else if(who_code == "4.1.2"){
    dictionary_un <- dictionary_un[,5:6]
  } else if(who_code == "4.2.1"){
    dictionary_un <- dictionary_un[,7:8]
  } else if(who_code == "4.2.2"){
    dictionary_un <- dictionary_un[,9:10]
  } else if(who_code == "4.5.1"){
    dictionary_un <- dictionary_un[,11:12]
  } else if(who_code == "4.5.2"){
    dictionary_un <- dictionary_un[,13:14]
  } else if(who_code == "4.5.3"){
    dictionary_un <- dictionary_un[,15:16]
  } else if(who_code == "4.5.4"){
    dictionary_un <- dictionary_un[,17:18]
  } else if(who_code == "5.3"){
    dictionary_un <- dictionary_un[,19:20]
  } else if(who_code == "5.5"){
    dictionary_un <- dictionary_un[,21:22]
  } else if(who_code == "5.7"){
    dictionary_un <- dictionary_un[,23:24]
  } else if(who_code == "5.9"){
    dictionary_un <- dictionary_un[,25:26]
  } else if(who_code == "4.3.4"){
    dictionary_un <- dictionary_un[,27:28]
  } else if(who_code == "4.3.3"){
    dictionary_un <- dictionary_un[,29:30]
  } else if(who_code == "4.3.1"){
    dictionary_un <- dictionary_un[,31:32]
  } else if(who_code == "4.3.2"){
    dictionary_un <- dictionary_un[,33:34]
  } 
  
  dictionary_un <- dictionary_un[!is.na(dictionary_un[,1]),]
  names(dictionary_un)[1] <- "unq"
  names(dictionary_un)[2] <- "ctr"
  
  return(dictionary_un)
}





###################################### Clean Data ##############################################

#Filter data
processed_data <- check_targets(mistress, taxonomy, unique_dictionary, valid_countries)



#Check for new invalid
  
checking <- processed_data %>% select(who_id, country_territory_area, who_code, targeted,valid_targets,invalid_targets)

#Retrieve check file
c <- checking %>% drop_na(invalid_targets)   %>% arrange(who_code)
new.unique <- c[!duplicated(c[,c('who_code','invalid_targets')]),c(3,6)]
write.csv(new.unique, "new_targets_23082022.csv" , row.names = FALSE, na="")




#Save data
processed2 <- processed_data
processed2$targeted <- processed2$valid_targets

write.csv(processed2, "mistress_processed_23082022.csv" , row.names = FALSE, na="")




############ Transfer process  ##############
# copy targets prcess 

transfer_data <- processed_data

transfer_data$valid_targets <- ifelse(!is.na(transfer_data$invalid_targets), paste(transfer_data$valid_targets, transfer_data$invalid_targets, sep=", "), transfer_data$valid_targets)
  


processed_data2 <- transfer_data


processed_data2$old_targeted <- processed_data2$targeted
processed_data2$targeted <- ifelse(is.na(processed_data2$valid_targets), processed_data2$targeted, processed_data2$valid_targets)




write.csv(processed_data2, "mistress_transfered_13082022.csv" , row.names = FALSE, na="")


