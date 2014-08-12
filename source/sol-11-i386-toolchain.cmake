# this one is important
SET(CMAKE_SYSTEM_NAME SunOS)
#this one not so much
SET(CMAKE_SYSTEM_VERSION 5.11)
SET(CMAKE_SYSTEM_PROCESSOR i386)

# specify the cross compiler
SET(PL_TOOLS_ROOT /opt/pl-build-tools/${CMAKE_SYSTEM_PROCESSOR})
SET(CMAKE_C_COMPILER     ${PL_TOOLS_ROOT}/bin/i386-pc-solaris2.11-gcc)
SET(CMAKE_CXX_COMPILER   ${PL_TOOLS_ROOT}/bin/i386-pc-solaris2.11-g++)

# where is the target environment
SET(CMAKE_FIND_ROOT_PATH  ${PL_TOOLS_ROOT})

# search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)

# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)

SET(CMAKE_C_FLAGS "-fPIC ${CMAKE_C_FLAGS}" CACHE STRING "" FORCE)
SET(CMAKE_CXX_FLAGS "-fPIC ${CMAKE_CXX_FLAGS}" CACHE STRING "" FORCE)

SET(PL_RPATH_FLAGS "-Wl,-rpath=\"${PL_TOOLS_ROOT}/lib:${PL_TOOLS_ROOT}/lib64\"")
SET(CMAKE_EXE_LINKER_FLAGS "${PL_RPATH_FLAGS} ${CMAKE_EXE_LINKER_FLAGS}" CACHE STRING "" FORCE)
SET(CMAKE_SHARED_LINKER_FLAGS "${PL_RPATH_FLAGS} ${CMAKE_SHARED_LINKER_FLAGS}" CACHE STRING "" FORCE)

# update RPATH so our custom libraries can be found
# use, i.e. don't skip the full RPATH for the build tree
SET(CMAKE_SKIP_BUILD_RPATH  FALSE)

# when building, don't use the install RPATH already
# (but later on when installing)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")


# add the automatically determined parts of the RPATH
# which point to directories outside the build tree to the install RPATH
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
