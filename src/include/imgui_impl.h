#pragma once

#ifdef __cplusplus
#include "imgui.h"
#define EXTERN extern "C"
#else
#define EXTERN extern
#endif

#define GLFW_INCLUDE_NONE
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>
#include <vulkan/vulkan.h>

EXTERN VkInstance g_Instance;
EXTERN VkDebugReportCallbackEXT g_DebugReport;

EXTERN VKAPI_ATTR VkBool32 VKAPI_CALL
debug_report(VkDebugReportFlagsEXT flags, VkDebugReportObjectTypeEXT objectType,
             uint64_t object, size_t location, int32_t messageCode,
             const char *pLayerPrefix, const char *pMessage, void *pUserData);

EXTERN void cpp_SetupVulkan(const char **extensions, uint32_t extensions_count);
EXTERN void cpp_resize_swapchain(GLFWwindow *window);
EXTERN bool cpp_render(GLFWwindow *window, ImDrawData *draw_data,
                       ImVec4 clear_color);

EXTERN void cpp_init(GLFWwindow *window);
EXTERN int cpp_teardown(GLFWwindow *window);
