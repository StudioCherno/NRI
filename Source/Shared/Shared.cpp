// © 2021 NVIDIA Corporation

#include "SharedExternal.h"

#if NRI_ENABLE_VK_SUPPORT
// Pull in the X11 "Window" typedef before "using namesapce nri" so it stays unambiguous with nri::Window.
#include <vulkan/vulkan.h>
#endif

#include "HelperInterface.h"
#include "ImguiInterface.h"
#include "StreamerInterface.h"
#include "UpscalerInterface.h"

using namespace nri;

#include "HelperInterface.hpp"
#include "ImguiInterface.hpp"
#include "StreamerInterface.hpp"
#include "UpscalerInterface.hpp"

#include "SharedExternal.hpp"
#include "SharedLibrary.hpp"
