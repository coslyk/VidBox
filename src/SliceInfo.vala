
class VideoSplitter.SliceInfo : Object {

    public double start_pos { get; set construct; }
    public double end_pos { get; set construct; }

    public SliceInfo (double duration) {
        Object (start_pos: 0, end_pos: duration);
    }
}