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

using VideoSplitter.Utils;

class VideoSplitter.SplitterItem : Object {

    public double start_pos { get; set construct; }
    public double end_pos { get; set construct; }

    public SplitterItem (double start_pos, double end_pos) {
        Object (start_pos: start_pos, end_pos: end_pos);
    }

    public string create_description () {
        return _("%s - %s\nDuration: %s").printf (time2str (start_pos), time2str (end_pos), time2str (end_pos - start_pos));
    }
}