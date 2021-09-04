!     This is part of the netCDF package. Copyright 2006-2019
!     University Corporation for Atmospheric Research/Unidata. See
!     COPYRIGHT file for conditions of use.

!     This program tests netCDF-4 variable functions from fortran.

!     $Id: f90tst_vars2.f90,v 1.7 2010/01/25 21:01:07 ed Exp $

program f90tst_vars5
  use typeSizes
  use netcdf
  implicit none
  
  ! This is the name of the data file we will create.
  character (len = *), parameter :: FILE_NAME = "f90tst_vars5.nc"

  ! We are writing 2D data, a 6 x 12 grid. 
  integer, parameter :: NDIM1 = 1
  integer, parameter :: DIM_LEN_5 = 5
  integer start(NDIM1), count(NDIM1)
  real real_data(DIM_LEN_5)
  real*8 double_data(DIM_LEN_5)

  ! We need these ids and other gunk for netcdf.
  integer :: ncid, varid1, varid2, varid3, varid4, varid5, dimids(NDIM1)
  integer :: chunksizes(NDIM1), chunksizes_in(NDIM1)
  integer :: x_dimid, y_dimid
  integer :: nvars, ngatts, ndims, unlimdimid, file_format
  integer :: x, y
  integer, parameter :: DEFLATE_LEVEL = 4
  integer (kind = EightByteInt), parameter :: TOE_SAN_VALUE = 2147483648_EightByteInt
  character (len = *), parameter :: VAR1_NAME = "Chon-Ji"
  character (len = *), parameter :: VAR2_NAME = "Tan-Gun"
  character (len = *), parameter :: VAR3_NAME = "Toe-San"
  character (len = *), parameter :: VAR4_NAME = "Won-Hyo"
  character (len = *), parameter :: VAR5_NAME = "Yul-Guk"
  integer, parameter :: CACHE_SIZE = 8, CACHE_NELEMS = 571
  integer, parameter :: CACHE_PREEMPTION = 66

  ! Information read back from the file to check correctness.
  integer :: varid1_in, varid2_in, varid3_in, varid4_in, varid5_in
  integer :: xtype_in, ndims_in, natts_in, dimids_in(NDIM1)
  character (len = nf90_max_name) :: name_in
  integer :: endianness_in, deflate_level_in
  logical :: shuffle_in, fletcher32_in, contiguous_in
  integer (kind = EightByteInt) :: toe_san_in
  integer :: cache_size_in, cache_nelems_in, cache_preemption_in
  integer :: quantize_mode_in, nsd_in
  real real_data_in(DIM_LEN_5)
  real*8 double_data_in(DIM_LEN_5)
  real real_data_expected(DIM_LEN_5)
  real*8 double_data_expected(DIM_LEN_5)

  print *, ''
  print *,'*** Testing use of quantize feature on netCDF-4 vars from Fortran 90.'

  ! Create some pretend data.
  real_data(1) = 1.11111111
  real_data(2) = 1.0
  real_data(3) = 9.99999999
  real_data(4) = 12345.67
  real_data(5) = .1234567
  double_data(1) = 1.1111111
  double_data(2) = 1.0
  double_data(3) = 9.999999999
  double_data(4) = 1234567890.12345
  double_data(5) = 1234567890

  ! Create the netCDF file. 
  call check(nf90_create(FILE_NAME, nf90_netcdf4, ncid, cache_nelems = CACHE_NELEMS, &
       cache_size = CACHE_SIZE))

  ! Define the dimension.
  call check(nf90_def_dim(ncid, "x", DIM_LEN_5, x_dimid))
  dimids =  (/ x_dimid /)

  ! Define some variables. 
  call check(nf90_def_var(ncid, VAR1_NAME, NF90_FLOAT, dimids, varid1&
       &, deflate_level = DEFLATE_LEVEL, quantize_mode =&
       & nf90_quantize_bitgroom, nsd = 3))
  call check(nf90_def_var(ncid, VAR2_NAME, NF90_DOUBLE, dimids,&
       & varid2, contiguous = .TRUE., quantize_mode =&
       & nf90_quantize_bitgroom, nsd = 3))

  ! Write the pretend data to the file.
  call check(nf90_put_var(ncid, varid1, real_data))
  call check(nf90_put_var(ncid, varid2, double_data))

  ! Close the file. 
  call check(nf90_close(ncid))

  ! What we expect to get back.
  real_data_expected(1) = 1.11084
  real_data_expected(2) = 1.000488
  real_data_expected(3) = 10
  real_data_expected(4) = 12348
  real_data_expected(5) = 0.1234436
  double_data_expected(1) = 1.11083984375
  double_data_expected(2) = 1.00048828125
  double_data_expected(3) = 10
  double_data_expected(4) = 1234698240
  double_data_expected(5) = 1234173952

  ! Reopen the file.
  call check(nf90_open(FILE_NAME, nf90_nowrite, ncid))
  
  ! Check some stuff out.
  call check(nf90_inquire(ncid, ndims, nvars, ngatts, unlimdimid, file_format))
  if (ndims /= 1 .or. nvars /= 2 .or. ngatts /= 0 .or. unlimdimid /= -1 .or. &
       file_format /= nf90_format_netcdf4) stop 2

  ! Get varids.
  call check(nf90_inq_varid(ncid, VAR1_NAME, varid1_in))
  call check(nf90_inq_varid(ncid, VAR2_NAME, varid2_in))

  ! Check variable 1.
  call check(nf90_inquire_variable(ncid, varid1_in, name_in, xtype_in, ndims_in, dimids_in, &
       natts_in, chunksizes = chunksizes_in, endianness = endianness_in, fletcher32 = fletcher32_in, &
       deflate_level = deflate_level_in, shuffle = shuffle_in, cache_size = cache_size_in, &
       cache_nelems = cache_nelems_in, cache_preemption = cache_preemption_in, &
       quantize_mode = quantize_mode_in, nsd = nsd_in))
  if (name_in .ne. VAR1_NAME .or. xtype_in .ne. NF90_FLOAT .or. ndims_in .ne. NDIM1 .or. &
       natts_in .ne. 1 .or. dimids_in(1) .ne. dimids(1)) stop 3

  ! Check variable 2.
  call check(nf90_inquire_variable(ncid, varid2_in, name_in, xtype_in, ndims_in, dimids_in, &
       natts_in, contiguous = contiguous_in, endianness = endianness_in, fletcher32 = fletcher32_in, &
       deflate_level = deflate_level_in, shuffle = shuffle_in, &
       quantize_mode = quantize_mode_in, nsd = nsd_in))
  if (name_in .ne. VAR2_NAME .or. xtype_in .ne. NF90_DOUBLE .or. ndims_in .ne. NDIM1 .or. &
       natts_in .ne. 1 .or. dimids_in(1) .ne. dimids(1)) stop 6
  if (deflate_level_in .ne. 0 .or. .not. contiguous_in .or. fletcher32_in .or. shuffle_in) stop 7

  ! ! Check the data.
  ! call check(nf90_get_var(ncid, varid1_in, data_in))
  ! do x = 1, DIM_LEN_5
  !    do y = 1, NY
  !       if (data_out(y, x) .ne. data_in(y, x)) stop 12
  !    end do
  ! end do
  ! call check(nf90_get_var(ncid, varid2_in, data_in))
  ! do x = 1, DIM_LEN_5
  !    do y = 1, NY
  !       if (data_out(y, x) .ne. data_in(y, x)) stop 13
  !    end do
  ! end do
  ! call check(nf90_get_var(ncid, varid3_in, toe_san_in))
  ! if (toe_san_in .ne. TOE_SAN_VALUE) stop 14
  ! call check(nf90_get_var(ncid, varid4_in, data_in_1d))
  ! do x = 1, DIM_LEN_5
  !    if (data_out_1d(x) .ne. data_in_1d(x)) stop 15
  ! end do
  ! call check(nf90_get_var(ncid, varid5_in, data_in))
  ! do x = 1, DIM_LEN_5
  !    do y = 1, NY
  !       if (data_out(y, x) .ne. data_in(y, x)) stop 12
  !    end do
  ! end do

  ! Close the file. 
  call check(nf90_close(ncid))

  print *,'*** SUCCESS!'

contains
!     This subroutine handles errors by printing an error message and
!     exiting with a non-zero status.
  subroutine check(errcode)
    use netcdf
    implicit none
    integer, intent(in) :: errcode
    
    if(errcode /= nf90_noerr) then
       print *, 'Error: ', trim(nf90_strerror(errcode))
       stop 2
    endif
  end subroutine check
end program f90tst_vars5

