#list all the files
temp = list.files(pattern = "CLBP*")

df <- NULL
for(i in 1:length(temp)){
  df[[i]] <- readxl::read_excel(temp[i], 
                                col_types = c(rep("guess", 5), 
                                              "numeric", "numeric", 
                                              rep("guess", 5)))
}


df <- tibble::as_tibble(data.table::rbindlist(df))

openxlsx::write.xlsx(df, file = "Imputed_Fitbit_by_Minute.xlsx")
