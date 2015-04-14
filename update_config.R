# script to read in SPA config file, modify its contents on lat/lon and driver
# filename, and then write back to input location

library("stringr")
scenarios      = c("R","CGCM2_A2","CGCM2_B2","ECHAM4_A2","ECHAM4_B2")
scenarios.abbr = c("R/","C_A2/"    ,"C_B2/"    ,"E_A2/"     ,"E_B2/"     )

###############################################################################

# read number of years, scenario, and whether PFTs are spatially variable from file
run_control = read.csv("~/PFT/SPA/run_control.csv", header=F,as.is=T)
pft_var = run_control$V1[1]
scenario = str_trim(run_control$V1[2])
nyears = as.numeric(run_control$V1[3])

###############################################################################

base.path = paste("/mnt/data/", scenario, sep="")
out.path = ifelse(pft_var,paste(base.path,"var/",sep=""),paste(base.path,"con/",sep=""))

# input from fortran call: lat, lon, driver, species, threadID:
  # thread ID is used to manipulate appropriate config file, loop iteration
  # for opening/reading appropriate lat/long information and driver file

lat = as.numeric(commandArgs()[5])
lon = as.numeric(commandArgs()[6])
driver = as.character(commandArgs()[7])
species = as.character(commandArgs()[8])
threadID = as.integer(commandArgs()[9])
plotID = as.integer(commandArgs()[10])
Cfol = as.numeric(commandArgs()[11])
Clab = Cfol * 0.5
Croot = Cfol * 0.6
if (species=="Fagus_sylvatica") Clab = 0.
Cwood = as.numeric(commandArgs()[12])
capac = as.numeric(commandArgs()[13])
gplant = as.numeric(commandArgs()[14])
height = as.numeric(commandArgs()[15])
leafN = as.numeric(commandArgs()[16])
LMA = as.numeric(commandArgs()[17])

species_abbr = unlist(strsplit(species, "_"))
species_abbr[1] = strtrim(species_abbr[1],1)
species_abbr[2] = strtrim(species_abbr[2],3)
species_abbr = paste(species_abbr[1],species_abbr[2],sep="")
species_sub = which(species_abbr==c("Fsyl","Phal","Pnig","Psyl","Punc","Qhum","Qile"))

config_name = paste("t", threadID, ".config", sep="")
config_path = paste("~/PFT/SPA/input/t", threadID, "/", config_name, sep="")
config = read.table(config_path, sep="\n", fill=FALSE, 
                    blank=FALSE, strip.white=T, comment="", as.is=TRUE)

# update number of years to run
year_row = which(strtrim(config[,1],15) == "number_of_years")
year_old = config[year_row,1]
year_new = nyears
foo = strsplit(year_old,split=" ")
foo[[1]][6] = year_new
config[year_row,1] = paste(foo[[1]], collapse=" ")
