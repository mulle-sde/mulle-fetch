cmake_minimum_required (VERSION 3.0)

project( mulle-fetch VERSION 4.1.2 LANGUAGES NONE)

#
# Primarily used for packaging on Linux
#
# Debian:
#
# ```
# mkdir package
# cd package
# cmake ..
# cpack -G DEB
# ```
#

execute_process( COMMAND ./mulle-fetch version
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_FETCH_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_FETCH_VERSION is ${MULLE_FETCH_VERSION} according to mulle-fetch")


set( PROJECT_VERSION "${MULLE_FETCH_VERSION}")


set( SCRIPTS
mulle-fetch
)


file( GLOB LIBRARY_SCRIPTS
   "src/*.sh"
)


file( GLOB PLUGIN_SCRIPTS
   "src/plugins/*.sh"
)




INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")


#
# future: install into libexec/mulle-fetch/${MULLE_FETCH_VERSION}
#         allows multiple versions to co-exist (does it really ?)
#
INSTALL( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-fetch")

INSTALL( FILES ${PLUGIN_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-fetch/plugins")


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
