#pragma once

#ifdef __cplusplus
#include "imgui.h"
#define EXTERN extern "C"
#else
#define EXTERN
#endif

#define GLFW_INCLUDE_NONE
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>

EXTERN void cpp_resize_swapchain(GLFWwindow *window);
EXTERN void cpp_new_frame(void);
EXTERN void cpp_loop(void);
EXTERN void cpp_render(GLFWwindow *window, ImDrawData *draw_data);

EXTERN void cpp_init(GLFWwindow *window);
EXTERN int cpp_teardown(GLFWwindow *window);
