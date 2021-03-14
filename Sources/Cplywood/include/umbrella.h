#ifndef c_plywood_DEFINED
#define c_plywood_DEFINED
#include <termios.h>

#include <EGL/egl.h>
#include <EGL/eglext.h>

#include <GLES2/gl2.h>

#include "gr_context.h"
#include "sk_types.h"

#define MIN(a,b) (((a)<(b))?(a):(b))

// All of our C tricks and hacks belong here.
// Hopefully, we can keep this file as small as possible.

void *plywood_skia_egl_get(void *ctx, const char name[]) {
    return eglGetProcAddress(name);
};

const gr_glinterface_t* plywood_gles_interface(void *ctx) {
    return gr_glinterface_assemble_gles_interface(ctx, plywood_skia_egl_get);
}

typedef struct {
    uint32_t buffer;
} plywood_gl_info_t;

// https://github.com/google/skia/blob/master/tools/sk_app/android/GLWindowContext_android.cpp
plywood_gl_info_t plywood_get_gl_info(EGLDisplay display) {
    GLint buffer;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &buffer);

    plywood_gl_info_t info = {
        .buffer = (uint32_t) buffer
    };

    return info;
}

void plywood_gl_init() {
    glClearStencil(0);
    glClearColor(0, 0, 0, 0);
    glStencilMask(0xffffffff);
    glClear(GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
}

#endif