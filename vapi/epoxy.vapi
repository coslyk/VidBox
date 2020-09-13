
[CCode (cheader_filename = "epoxy/gl.h,epoxy/glx.h,epoxy/egl.h")]
namespace Epoxy {

    [CCode (cname = "GL_FRAMEBUFFER_BINDING")]
    public const uint GL_FRAMEBUFFER_BINDING;

    void* eglGetProcAddress (string procname);
    void* glXGetProcAddressARB (string procname);
    void glGetIntegerv(uint pname, out int data);
}