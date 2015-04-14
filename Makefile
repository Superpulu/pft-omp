###### NETCDF SETUP #######

NCFLAGS=-I$(NC_INC_DIR) -L$(NC_LIB_DIR) -L$(LAPACK_LIB_DIR) -L$(BLAS_LIB_DIR) -lnetcdff -lnetcdf -llapack -lblas -fopenmp

###############################

###### Compiler choice #####
#
# to use the gnu compiler..
#
FC = gfortran
#for normal...
#FCFLAGS = -cpp -ffree-line-length-none $(NCFLAGS)
#for debugging...
FCFLAGS = -fopenmp -cpp -fbounds-check -fimplicit-none -ffree-line-length-none -frange-check -ftree-vectorizer-verbose=0 -ggdb -O0 -Wall $(NCFLAGS) -std=f2003 -pedantic -fall-intrinsics
#for profiling...FCFLAGS = -cpp -p -g -ffree-line-length-none $(NCFLAGS)
#
# to use the intel compiler...
#
#FC = ifort
#for normal......
#FCFLAGS = -fpp -vec-report=0 $(NCFLAGS)
#for debugging...FCFLAGS = -fpp -check all -debug-parameters all -ftrapuv -g -fpe0 -implicitnone -O0 -p -stand f03 -traceback -vec-report=0 $(NCFLAGS) 
#for profiling...FCFLAGS = -fpp -p -g $(NCFLAGS)
#
##############################

parallelize_SOURCES = parallelize.f90

parallelize:	$(parallelize_SOURCES:%.f90=%.o)
	$(FC) -i-dynamic $(NCFLAGS) -o $@ $^

clean:
	rm -f *.mod *.o parallelize *~

%.o:	%.f90
	$(FC) $(FCFLAGS) -c $< -o $@
