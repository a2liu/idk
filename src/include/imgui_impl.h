#pragma once

#ifdef __cplusplus
#define EXTERN extern "C"
#else
#define EXTERN
#endif

#define GLFW_INCLUDE_NONE
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>

EXTERN int cpp_main();

EXTERN void cpp_loop(GLFWwindow *window);
EXTERN void cpp_init(GLFWwindow *window);
EXTERN int cpp_teardown(GLFWwindow *window);
