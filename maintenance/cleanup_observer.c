#include <stdio.h>

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

static void (*driver_cleanup)(void);
static char log_path[4096];

static void append_event(const char *event) {
    FILE *stream = fopen(log_path, "a");
    if (stream) {
        fputs(event, stream);
        fclose(stream);
    }
}

EXPORT void set_cleanup(void *cleanup, const char *path) {
    driver_cleanup = (void (*)(void))cleanup;
    snprintf(log_path, sizeof(log_path), "%s", path);
}

EXPORT void observed_cleanup(void) {
    driver_cleanup();
    append_event("DRIVER_CLEANUP_COMPLETED\n");
}

EXPORT void observed_client(void) {
    append_event("CLIENT_FINALIZED\n");
}
