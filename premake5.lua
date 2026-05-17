-- NRI (NVIDIA Render Interface) premake5 build
-- Mirrors the CMakeLists.txt structure: NRI-Shared, NRI-VK, NRI-Validation, NRI-NONE, NRI

local NRI_DIR = path.getabsolute(".")

-- Common defines shared across all NRI projects
local NRI_COMMON_DEFINES = {
	"NRI_STATIC_LIBRARY=1",
	"NRI_ENABLE_VK_SUPPORT=1",
	"NRI_ENABLE_VALIDATION_SUPPORT=1",
	"NRI_ENABLE_NONE_SUPPORT=1",
	"NRI_ENABLE_DEBUG_NAMES_AND_ANNOTATIONS=1",
	"NRI_STREAMER_THREAD_SAFE=1",
	"WIN32_LEAN_AND_MEAN",
	"NOMINMAX",
	"_CRT_SECURE_NO_WARNINGS"
}

local function NRICommonSettings()
	language "C++"
	cppdialect "C++17"
	staticruntime "off"

	targetdir ("bin/" .. outputdir .. "/%{prj.name}")
	objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

	defines(NRI_COMMON_DEFINES)

	filter "system:windows"
		systemversion "latest"
		defines {
			"VK_USE_PLATFORM_WIN32_KHR",
			-- D3D support can be enabled later
			-- "NRI_ENABLE_D3D11_SUPPORT=1",
			-- "NRI_ENABLE_D3D12_SUPPORT=1",
		}
	filter {}

	filter "system:linux"
		defines {
			"NRI_ENABLE_XLIB_SUPPORT=1"
		}
	filter {}

	filter "system:macosx"
		defines {
			"VK_USE_PLATFORM_METAL_EXT",
			"VK_ENABLE_BETA_EXTENSIONS"
		}
	filter {}

	-- Suppress warnings in vendor code
	filter "action:vs*"
		disablewarnings {
			"4100", -- unreferenced formal parameter
			"4189", -- local variable initialized but not referenced
			"4127", -- conditional expression is constant
			"4324", -- structure was padded due to alignment
			"4068", -- unknown pragma
		}
		buildoptions { "/w" } -- Suppress all warnings for vendor code
	filter {}

	filter "toolset:gcc or toolset:clang"
		buildoptions { "-w" } -- Suppress all warnings for vendor code
	filter {}
end

----------------------------------------------------------------------
-- NRI-Shared: Shared utilities used by all backends
----------------------------------------------------------------------
project "NRI-Shared"
	kind "StaticLib"
	NRICommonSettings()

	files {
		NRI_DIR .. "/Source/Shared/Shared.cpp",
		NRI_DIR .. "/Source/Shared/**.h",
		NRI_DIR .. "/Source/Shared/**.hpp",
	}

	includedirs {
		NRI_DIR .. "/Include",
		NRI_DIR .. "/Source/Shared",
	}

	-- Vulkan headers needed by SharedExternal.h -> NRIWrapperVK.h
	externalincludedirs {
		VULKAN_SDK .. "/Include",
		VULKAN_SDK .. "/include",
	}

----------------------------------------------------------------------
-- NRI-VK: Vulkan backend
-- NOTE: ImplVK.cpp is a single translation unit that #includes all .hpp files
----------------------------------------------------------------------
project "NRI-VK"
	kind "StaticLib"
	NRICommonSettings()

	files {
		NRI_DIR .. "/Source/VK/ImplVK.cpp",
		NRI_DIR .. "/Source/VK/**.h",
		NRI_DIR .. "/Source/VK/**.hpp",
	}

	-- Mark .hpp files as not compiled (they are #included by ImplVK.cpp)
	filter "files:**.hpp"
		flags { "ExcludeFromBuild" }
	filter {}

	-- Mark .h files as not compiled
	filter "files:**.h"
		flags { "ExcludeFromBuild" }
	filter {}

	includedirs {
		NRI_DIR .. "/Include",
		NRI_DIR .. "/Source/Shared",
		NRI_DIR .. "/Source/VK",
	}

	-- VMA header - NRI-specific version (newer than engine's copy)
	externalincludedirs {
		NRI_DIR .. "/External/VMA",
		VULKAN_SDK .. "/Include",
		VULKAN_SDK .. "/include",
	}

	links { "NRI-Shared" }

----------------------------------------------------------------------
-- NRI-Validation: Validation layer
-- NOTE: ImplVal.cpp is a single TU that #includes all .hpp files
----------------------------------------------------------------------
project "NRI-Validation"
	kind "StaticLib"
	NRICommonSettings()

	files {
		NRI_DIR .. "/Source/Validation/ImplVal.cpp",
		NRI_DIR .. "/Source/Validation/**.h",
		NRI_DIR .. "/Source/Validation/**.hpp",
	}

	filter "files:**.hpp"
		flags { "ExcludeFromBuild" }
	filter {}

	filter "files:**.h"
		flags { "ExcludeFromBuild" }
	filter {}

	includedirs {
		NRI_DIR .. "/Include",
		NRI_DIR .. "/Source/Shared",
		NRI_DIR .. "/Source/Validation",
	}

	externalincludedirs {
		VULKAN_SDK .. "/Include",
		VULKAN_SDK .. "/include",
	}

	links { "NRI-Shared" }

----------------------------------------------------------------------
-- NRI-NONE: Dummy/no-op backend
----------------------------------------------------------------------
project "NRI-NONE"
	kind "StaticLib"
	NRICommonSettings()

	files {
		NRI_DIR .. "/Source/NONE/ImplNONE.cpp",
	}

	includedirs {
		NRI_DIR .. "/Include",
		NRI_DIR .. "/Source/Shared",
	}

	externalincludedirs {
		VULKAN_SDK .. "/Include",
		VULKAN_SDK .. "/include",
	}

	links { "NRI-Shared" }

----------------------------------------------------------------------
-- NRI: Core library (device creation + links all backends)
----------------------------------------------------------------------
project "NRI"
	kind "StaticLib"
	NRICommonSettings()

	files {
		NRI_DIR .. "/Source/Creation/Creation.cpp",
		NRI_DIR .. "/Include/**.h",
		NRI_DIR .. "/Include/**.hlsl",
	}

	-- Don't compile header/hlsl files
	filter "files:**.h"
		flags { "ExcludeFromBuild" }
	filter {}
	filter "files:**.hlsl"
		flags { "ExcludeFromBuild" }
	filter {}

	includedirs {
		NRI_DIR .. "/Include",
		NRI_DIR .. "/Source/Shared",
	}

	externalincludedirs {
		VULKAN_SDK .. "/Include",
		VULKAN_SDK .. "/include",
	}

	links {
		"NRI-Shared",
		"NRI-VK",
		"NRI-Validation",
		"NRI-NONE",
	}
