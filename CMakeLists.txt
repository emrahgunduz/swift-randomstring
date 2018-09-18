cmake_minimum_required(VERSION 3.12)
project(rstring)

file(GLOB_RECURSE SOURCE_FILES *.swift)

set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -std=c++11")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -std=c++11 -o3 -flto")

message("-- CMAKE_BUILD_TYPE = ${CMAKE_BUILD_TYPE}")
IF (NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE Debug ... FORCE)
ENDIF ()

if (CMAKE_BUILD_TYPE MATCHES Debug)
    set(ADDITIONAL "--configuration debug -Xswiftc -Onone -Xswiftc -DDEBUG")
else ()
    set(ADDITIONAL "--configuration release -Xswiftc -O")
endif ()

set(COMMAND "swift build ${ADDITIONAL}")

add_custom_target(rstring
        COMMAND
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/rstring
        SOURCES ${SOURCE_FILES})