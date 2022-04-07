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

EXTERN bool FrameRender(ImGui_ImplVulkanH_Window *wd, ImDrawData *draw_data);
EXTERN bool FramePresent(ImGui_ImplVulkanH_Window *wd);
