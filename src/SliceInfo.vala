
class VideoSplitter.SliceInfo : Object {

    public string filename { get; construct; }
    public double start_pos { get; set construct; }
    public double end_pos { get; set construct; }

    public SliceInfo (string filename, double duration) {
        Object (filename: filename, start_pos: 0, end_pos: duration);
    }
}