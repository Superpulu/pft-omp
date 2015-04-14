PROGRAM pft_omp

use omp_lib

IMPLICIT NONE

! variable declarations

real,dimension(8) :: wtime
real,dimension(:),allocatable :: lat, lon, gplant, height, leafN, LMA

integer,dimension(:),allocatable :: Cfol, Cwood, capac
integer :: i,id,status,num_lines, nyears

character(len=1) :: pft_var
character(len=5) :: scenario
character(len=100) :: plotID,threadID,header,line,latchar,lonchar,Cfolchar,Cwoodchar,capacchar,gplantchar,heightchar,leafNchar,LMAchar
character(len=300) :: exec ! longer character variable, as it contains call to R script
character(len=5),dimension(5) :: scenarios ! = (/ "R/","C_A2/","C_B2/","E_A2/","E_B2/" /)
character(len=100),dimension(:),allocatable :: driver, species

! main code

! climate scenario runs
scenarios = (/ "   R/","C_A2/","C_B2/","E_A2/","E_B2/" /)

! Choose settings for runs and write to file
pft_var  = "T" ! either "T" or "F", not "TRUE" or "FALSE", are PFTs spatially variable?
scenario = scenarios(5) ! choose scenario from vector above
nyears   = 108 ! number of years to run

! write above choices to run control file
open(unit=1,file="run_control.csv", status="unknown")
write(1,'(A1,A)') pft_var,","
write(1,'(A5,A)') scenario,","
write(1,'(I3,A)') nyears,","
close(unit=1)

! Compile SPA
CALL system('./compile.sh')

! First initialize the system_clock
wtime = OMP_get_wtime()

! open and read content of file containing plot coordinates, driver names, and species
open(unit=11, file="/home/osus/PFT/SPA/input/plots.csv", status="old")
read(unit=11, fmt=*) header ! read header out of the way
status = 0 ; num_lines = 0

! count number of lines in plots.csv file (= number of study sites)
do 
   read(unit=11, fmt=*, iostat=status) line
   if ( status .ne. 0. ) exit
   num_lines = num_lines + 1
enddo

! allocate variable dimensions as a function of number of study sites
allocate( lat( num_lines ) , &
          lon( num_lines ) , &
       driver( num_lines ) , &
      species( num_lines ) , &
         Cfol( num_lines ) , &
        Cwood( num_lines ) , &
        capac( num_lines ) , &
       gplant( num_lines ) , &
       height( num_lines ) , &
        leafN( num_lines ) , &
          LMA( num_lines ) )
          
! rewind plots file for reading data
rewind(11)

read(unit=11, fmt=*) header ! read header out of the way

! read the data line by line into corresponding variables
do i = 1 , num_lines
   read(11,fmt=*) lat(i),lon(i),driver(i),species(i),Cfol(i),Cwood(i),capac(i),gplant(i),height(i),leafN(i),LMA(i) 
enddo

WRITE(*,*)

! all plot coordinates, driver names, and species have now been read into their corresponding variables
! parallel section of code starts here

!$OMP PARALLEL &
!$OMP PRIVATE ( i , id , plotID , threadID , exec , latchar , lonchar , Cfolchar, Cwoodchar , capacchar,gplantchar,heightchar,leafNchar,LMAchar)
!$OMP DO SCHEDULE( GUIDED ) ! or DYNAMIC

DO i=1,num_lines

  ! get thread number
  id = omp_get_thread_num ( )
  WRITE ( *, * ) ' Thread ', id, ' has started iteration ', i
  ! read values of thread id, latitude, longitude, foliar and wood carbon into character 
  ! variables that will form part of call to R script
  WRITE(plotID,'(i10)')i
  WRITE(threadID,'(i10)') id
  WRITE(latchar,'(f16.13)')lat(i)
  WRITE(lonchar,'(f16.13)')lon(i)
  WRITE(Cfolchar,'(i10)')Cfol(i)
  WRITE(Cwoodchar,'(i10)')Cwood(i)
  WRITE(capacchar,'(i10)')capac(i)
  WRITE(gplantchar,'(f4.1)')gplant(i)
  WRITE(heightchar,'(f5.2)')height(i)
  WRITE(leafNchar,'(f4.2)')leafN(i)
  WRITE(LMAchar,'(f5.1)')LMA(i)
  ! exec = the call to R script update_config.R: will update config file for SPA runs with correct info on lat/lon and driver path
  exec = TRIM("R --vanilla --slave --args")//" "//TRIM(latchar)//" "//TRIM(lonchar)//" "//TRIM(driver(i))//" "//TRIM(species(i))//" "//TRIM(threadID)//" "//TRIM(plotID)//" "//TRIM(Cfolchar)//" "//TRIM(Cwoodchar)//" "//TRIM(capacchar)//" "//TRIM(gplantchar)//" "//TRIM(heightchar)//" "//TRIM(leafNchar)//" "//TRIM(LMAchar)//" "//TRIM("<update_config.R")
  CALL system(exec)

  IF (id == 0) CALL system('./spa input/t0/t0.config')
  IF (id == 1) CALL system('./spa input/t1/t1.config')
  IF (id == 2) CALL system('./spa input/t2/t2.config')
  IF (id == 3) CALL system('./spa input/t3/t3.config')
  IF (id == 4) CALL system('./spa input/t4/t4.config')
  IF (id == 5) CALL system('./spa input/t5/t5.config')
  IF (id == 6) CALL system('./spa input/t6/t6.config')
  IF (id == 7) CALL system('./spa input/t7/t7.config')
  write ( *, * ) ' Thread ', id, ' has finished iteration ', i
  
ENDDO ! end of loop over sites
  
!$OMP END DO
!$OMP END PARALLEL

! end of parallel code section

! call R script to read model output and create statistical summary files
CALL system('R --vanilla < ../scripts/create_output_files.R')

! calculate total compution time
wtime = OMP_get_wtime() - wtime
WRITE(*,*) wtime(1)

END PROGRAM pft_omp
