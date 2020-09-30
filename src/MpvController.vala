/* Copyright 2020 Yikun Liu <cos.lyk@gmail.com>
 *
 * This program is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see http://www.gnu.org/licenses/.
 */

class VideoSplitter.MpvController : Object {

    // Mpv properties
    [CCode (notify = false)]
    public bool pause {
        get { bool v; mpv.get_property_bool ("pause", out v); return v; }
        set { mpv.set_property_bool ("pause", ref value); }
    }

    [CCode (notify = false)]
    public double duration {
        get { double v; mpv.get_property_double ("duration", out v); return v; }
    }

    [CCode (notify = false)]
    public double playback_time { 
        get { double v; mpv.get_property_double ("playback-time", out v); return v; }
        set { mpv.set_property_double ("playback-time", ref value); }
    }

    // Mpv handles
    private Mpv.RenderContext mpv_rctx;   // Must be put ahead of mpv so that Vala destroys it first
    private Mpv.Handle mpv;

    // GLArea to render videos
    public Gtk.GLArea video_area { get; construct; }

    // Init
    public MpvController (Gtk.GLArea video_area) {
        Object (video_area: video_area);
    }

    construct {
        // Create Mpv instance
        mpv = new Mpv.Handle ();
        mpv.set_option_string ("hwdec", "auto");
        mpv.set_option_string ("keep-open", "always");
        mpv.set_option_string ("pause", "yes");
        mpv.set_option_string ("reset-on-next-file", "pause");

        mpv.observe_property (0, "pause", Mpv.Format.FLAG);
        mpv.observe_property (0, "duration", Mpv.Format.DOUBLE);
        mpv.observe_property (0, "playback-time", Mpv.Format.DOUBLE);

        mpv.request_log_messages ("info");

        if (mpv.initialize () < 0) {
            error ("Fails to initialize mpv!");
        }

        mpv.set_wakeup_callback (() => {
            Idle.add_full (Priority.HIGH_IDLE, process_mpv_events);
        });

        // Init OpenGL
        video_area.realize.connect (() => {
            video_area.make_current ();
            
            // Create render context
            Mpv.OpenGLInitParams gl_init_params = { Utils.get_proc_address };

            Mpv.RenderParam params[5];
            params[0] = { Mpv.RenderParamType.API_TYPE,            "opengl" };
            params[1] = { Mpv.RenderParamType.OPENGL_INIT_PARAMS,  &gl_init_params};
            params[2] = { Mpv.RenderParamType.WL_DISPLAY,          Utils.get_wayland_display ()};
            params[3] = { Mpv.RenderParamType.X11_DISPLAY,         Utils.get_x11_display ()};
            params[4] = { Mpv.RenderParamType.INVALID,             null };

            if (Mpv.render_context_create (out mpv_rctx, mpv, params) < 0) {
                error ("failed to initialize mpv GL context");
            }

            mpv_rctx.set_update_callback (() => {
                Idle.add_full (Priority.HIGH_IDLE, () => {
                    video_area.queue_render ();
                    return false;
                });
            });
        });

        // Render video
        video_area.render.connect ((area, ctx) => {

            // Get framebuffer
            int fbo = -1;
            Epoxy.glGetIntegerv (Epoxy.GL_FRAMEBUFFER_BINDING, out fbo);
            Mpv.OpenGLFbo opengl_fbo = { fbo, area.get_allocated_width (), area.get_allocated_height (), 0 };

            // Render
            int flip_y = 1;
            Mpv.RenderParam params[3];
            params[0].type = Mpv.RenderParamType.OPENGL_FBO;
            params[0].data = &opengl_fbo;
            params[1].type = Mpv.RenderParamType.FLIP_Y;
            params[1].data = &flip_y;
            params[2].type = Mpv.RenderParamType.INVALID;
            params[2].data = null;

            mpv_rctx.render (params);
        });
    }

    // Remove callback function
    ~MpvController () {
        mpv_rctx.set_update_callback (null);
        mpv.set_wakeup_callback (null);
    }

    // Open video
    public void open (string uri) {
        (unowned string)[] cmd = { "loadfile", uri, null };
        mpv.command_async (0, cmd);
    }


    // Next frame
    public void next_frame () {
        mpv.command_string ("frame-step");
    }


    // Previous frame
    public void previous_frame () {
        mpv.command_string ("frame-back-step");
    }


    private bool process_mpv_events () {
        while (true) {
            unowned Mpv.Event event = mpv.wait_event ();
            switch (event.event_id) {
                case Mpv.EventID.NONE:
                return false;

                case Mpv.EventID.PROPERTY_CHANGE: {
                    unowned Mpv.EventProperty prop = ((Mpv.Event<Mpv.EventProperty>) event).data;
                    if (prop.format != Mpv.Format.NONE) {
                        notify_property (prop.name);
                    }
                    break;
                }

                case Mpv.EventID.LOG_MESSAGE: {
                    unowned Mpv.EventLogMessage msg = ((Mpv.Event<Mpv.EventLogMessage>) event).data;
                    stderr.printf ("[%s] %s", msg.prefix, msg.text);
                    break;
                }

                default: continue;
            }
        }
    }
}