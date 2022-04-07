#pragma once

#ifdef __cplusplus
#include "imgui.h"
#define EXTERN extern "C"
#else
#define EXTERN extern
#endif

#include "imgui_impl_platform.h"
#include "imgui_impl_render.h"

#define GLFW_INCLUDE_NONE
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>
#include <vulkan/vulkan.h>

EXTERN VkInstance g_Instance;
EXTERN VkDebugReportCallbackEXT g_DebugReport;
EXTERN VkPhysicalDevice g_PhysicalDevice;
EXTERN VkDevice g_Device;
EXTERN uint32_t g_QueueFamily;
EXTERN VkQueue g_Queue;
EXTERN VkDescriptorPool g_DescriptorPool;
EXTERN ImGui_ImplVulkanH_Window g_MainWindowData;

EXTERN VKAPI_ATTR VkBool32 VKAPI_CALL
debug_report(VkDebugReportFlagsEXT flags, VkDebugReportObjectTypeEXT objectType,
             uint64_t object, size_t location, int32_t messageCode,
             const char *pLayerPrefix, const char *pMessage, void *pUserData);

EXTERN void SetupVulkanWindow(VkSurfaceKHR surface, int width, int height);

EXTERN void cpp_resize_swapchain(GLFWwindow *window);
EXTERN bool cpp_render(GLFWwindow *window, ImDrawData *draw_data,
                       ImVec4 clear_color);

EXTERN void cpp_init(GLFWwindow *window);
