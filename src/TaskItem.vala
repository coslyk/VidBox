
using VideoSplitter.Utils;

class VideoSplitter.TaskItem : Object {

    public double start_pos { get; set construct; }
    public double end_pos { get; set construct; }

    public TaskItem (double start_pos, double end_pos) {
        Object (start_pos: start_pos, end_pos: end_pos);
    }

    public string create_description () {
        return "%s - %s\nDuration: %s".printf (time2str (start_pos), time2str (end_pos), time2str (end_pos - start_pos));
    }
}