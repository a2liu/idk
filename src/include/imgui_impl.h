#pragma once

#ifdef __cplusplus
#define EXTERN extern "C"
#else
#define EXTERN
#endif

#define GLFW_INCLUDE_NONE
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>

EXTERN void main_loop(GLFWwindow *window);
EXTERN int cpp_main();

EXTERN int cpp_init();
EXTERN int cpp_teardown(GLFWwindow *window);
