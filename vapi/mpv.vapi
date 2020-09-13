[CCode (cheader_filename = "mpv/client.h,mpv/render.h,mpv/render_gl.h")]
namespace Mpv {

    [CCode (cname = "enum mpv_error", cprefix = "MPV_ERROR_")]
    public enum Error {

        SUCCESS,              // No error happened
        EVENT_QUEUE_FULL,     // The event ringbuffer is full. This means the client is choked, and can't receive any events
        NOMEM,                // Memory allocation failed
        UNINITIALIZED,        // The mpv core wasn't configured and initialized yet.
        INVALID_PARAMETER,    // Generic catch-all error if a parameter is set to an invalid or unsupported value.
        OPTION_NOT_FOUND,     // Trying to set an option that doesn't exist.
        OPTION_FORMAT,        // Trying to set an option using an unsupported MPV_FORMAT.
        OPTION_ERROR,         // Setting the option failed. Typically this happens if the provided option value could not be parsed.
        PROPERTY_NOT_FOUND,   // The accessed property doesn't exist.
        PROPERTY_FORMAT,      // Trying to set or get a property using an unsupported MPV_FORMAT.
        PROPERTY_UNAVAILABLE, // The property exists, but is not available.
        PROPERTY_ERROR,       // Error setting or getting a property.
        COMMAND,              // General error when running a command with mpv_command and similar. 
        LOADING_FAILED,       // Generic error on loading (usually used with mpv_event_end_file.error)
        AO_INIT_FAILED,       // Initializing the audio output failed
        VO_INIT_FAILED,       // Initializing the video output failed
        NOTHING_TO_PLAY,      // There was no audio or video data to play
        UNKNOWN_FORMAT,       // When trying to load the file, the file format could not be determined, or the file was too broken to open it.
        UNSUPPORTED,          // Generic error for signaling that certain system requirements are not fulfilled.
        NOT_IMPLEMENTED,      // The API function which was called is a stub only
        GENERIC               // Unspecified error
    }

    [CCode (cname = "enum mpv_format", has_type_id = false, cprefix = "MPV_FORMAT_")]
    public enum Format {

        NONE,
        STRING,
        FLAG,
        INT64,
        DOUBLE
    }

    [CCode (cname = "enum mpv_event_id", has_type_id = false, cprefix = "MPV_EVENT_")]
    public enum EventID {

        NONE,
        SHUTDOWN,
        LOG_MESSAGE,
        GET_PROPERTY_REPLY,
        SET_PROPERTY_REPLY,
        COMMAND_REPLY,
        START_FILE,
        END_FILE,
        FILE_LOADED,
        IDLE,
        TICK,
        CLIENT_MESSAGE,
        VIDEO_RECONFIG,
        AUDIO_RECONFIG,
        SEEK,
        PLAYBACK_RESTART,
        PROPERTY_CHANGE,
        QUEUE_OVERFLOW,
        HOOK,
        //depricated
        TRACKS_CHANGED,
        TRACK_SWITCHED,
        PAUSE,
        UNPAUSE,
        SCRIPT_INPUT_DISPATCH,
        METADATA_UPDATE,
        CHAPTER_CHANGE,
    }

    [CCode (cname = "enum mpv_end_file_reason", has_type_id = false, cprefix = "MPV_END_FILE_REASON_")]
    public enum EndFileReason {

        EOF,
        STOP,
        QUIT,
        ERROR,
        REDIRECT
    }

    [Compact]
    [CCode (cname = "struct mpv_event")]
    public class Event<T> {

        public Mpv.EventID event_id;
        public int error;
        public uint64 reply_userdata;
        public unowned T data;
    }

    [Compact]
    [CCode (cname = "struct mpv_event_property")]
    public class EventProperty {

        public string name;
        public Mpv.Format format;
        public void* data;
    }

    [CCode (cname = "struct mpv_event_log_message")]
    public class EventLogMessage {

        public string prefix;
        public string level;
        public string text;
    }

    [CCode (cname = "struct mpv_event_end_file")]
    public class EventEndFile {

        public Mpv.EndFileReason reason;
        public Mpv.Error error;
    }

    [Compact]
    [CCode (cname = "mpv_handle", has_type_id = false, cprefix = "mpv_", free_function = "mpv_terminate_destroy")]
    public class Handle {

        [CCode (cname = "mpv_create")]
        public Handle ();
        public Mpv.Error initialize ();
        
        public Mpv.Error set_option_string (string name, string data);

        public Mpv.Error command ([CCode (array_length = false)] string[]? args = null);
        public Mpv.Error command_string (string args);
        public Mpv.Error command_async (uint64 reply_userdata, [CCode (array_length = false)] string[]? args = null);

        public Mpv.Error set_property_string (string name, string data);
        [CCode (cname = "mpv_set_property")]
        public Mpv.Error set_property_bool (string name, ref bool data, [CCode (pos = 1.5)] Mpv.Format format = Mpv.Format.FLAG);
        [CCode (cname = "mpv_set_property")]
        public Mpv.Error set_property_int64 (string name, ref int64 data, [CCode (pos = 1.5)] Mpv.Format format = Mpv.Format.INT64);
        [CCode (cname = "mpv_set_property")]
        public Mpv.Error set_property_double (string name, ref double data, [CCode (pos = 1.5)] Mpv.Format format = Mpv.Format.DOUBLE);

        [CCode (simple_generics = true, has_target = false)]
        public Mpv.Error get_property<T> (string name, Mpv.Format format, out T data);

        public Mpv.Error observe_property (uint64 reply_userdata, string name, Mpv.Format format);
        public Mpv.Error request_event (EventID event, bool enable);
        public Mpv.Error request_log_messages (string min_level);

        public unowned Event wait_event (double timeout = 0);
        public void wakeup ();
        public void set_wakeup_callback (CallBack? callback);
    }

    [CCode (cname = "cb", has_target = true)]
    public delegate void CallBack ();
    

    // Render API
    [CCode (cname = "enum mpv_render_param_type", has_type_id = false, cprefix = "MPV_RENDER_PARAM_")]
    public enum RenderParamType {

        INVALID,
        API_TYPE,
        OPENGL_INIT_PARAMS,
        OPENGL_FBO,
        FLIP_Y,
        DEPTH,
        X11_DISPLAY,
        WL_DISPLAY
    }

    [CCode (cname = "struct mpv_render_param", has_destroy_function = false)]
    public struct RenderParam {

        public RenderParamType type;
        public void* data;
    }

    [CCode (cname = "mpv_render_context_create")]
    Mpv.Error render_context_create (out RenderContext res, Handle mpv, [CCode (array_length = false)] RenderParam[] params);

    [CCode (cname = "mpv_render_update_fn", has_target = true)]
    public delegate void RenderUpdateCallback ();
    
    [Compact]
    [CCode (cname = "mpv_render_context", cprefix = "mpv_render_context_", free_function = "mpv_render_context_free")]
    public class RenderContext {

        public Mpv.Error set_parameter (RenderParam param);
        public Mpv.Error render ([CCode (array_length = false)] RenderParam[] params);
        public uint64 update ();
        public void set_update_callback (RenderUpdateCallback? callback);
        public void report_swap ();
    }

    // OpenGL
    [CCode (cname = "get_proc_address", has_target = true, instance_pos = 0.1)]
    public delegate void* GetProcAddressCallback (string name);

    [CCode (cname = "struct mpv_opengl_init_params", has_destroy_function = false)]
    public struct OpenGLInitParams {

        [CCode (delegate_target_cname = "get_proc_address_ctx")]
        public unowned GetProcAddressCallback get_proc_address;
    }

    [CCode (cname = "struct mpv_opengl_fbo")]
    public struct OpenGLFbo {
        
        public int fbo;
        public int w;
        public int h;
        public int internal_format;
    }
}