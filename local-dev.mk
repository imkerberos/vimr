DISABLE_TUI := DISABLE
ENABLE_CUSTOM_UI := ENABLE

CMAKE_BUILD_TYPE := Dev

# The log level must be a number DEBUG (0), INFO (1), WARNING (2) or ERROR (3).
CMAKE_EXTRA_FLAGS += -DMIN_LOG_LEVEL=1
