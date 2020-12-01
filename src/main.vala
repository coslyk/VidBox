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

namespace VidBox {

    public static int main (string[] args) {

        // Fix i18n in AppImage
        unowned string program_path = Utils.get_program_path ();
        if (program_path.has_suffix ("/bin/" + Build.APP_ID)) {
            string dirname = program_path.replace ("/bin/" + Build.APP_ID, "/share/locale");
            Intl.bindtextdomain (Build.APP_ID, dirname);
        }
        Intl.textdomain (Build.APP_ID);

        // Needed by mpv
        Environment.set_variable ("LC_NUMERIC", "C", true);
        Intl.setlocale (LocaleCategory.NUMERIC, "C");

        var app = new Application ();
        return app.run (args);
    }
}