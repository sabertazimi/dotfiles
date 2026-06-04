#!/usr/bin/env python3

"""
:authors:
    - m13253
    - ZhiyuShang
"""

import argparse
import gettext
import io
import json
import logging
import math
import os
import random
import re
import ssl
import sys
import xml.etree.cElementTree as ET
import zlib
from urllib import request, error

gettext.install(
    "danmaku2ass",
    os.path.join(
        os.path.dirname(os.path.abspath(os.path.realpath(sys.argv[0] or "locale"))),
        "locale",
    ),
)


def read_comments_bilibili(f, fontsize):
    root = ET.parse(f)
    scroll_types = set("1456")
    valid_types = set("145678")
    comment_elements = root.findall("d")
    for i, comment in enumerate(comment_elements):
        try:
            p = str(comment.attrib["p"]).split(",")
            assert len(p) >= 5
            assert p[1] in valid_types
            if comment.text:
                if p[1] in scroll_types:
                    c = str(comment.text).replace("/n", "\n")
                    size = int(p[2]) * fontsize / 25.0
                    yield (
                        float(p[0]),
                        int(p[4]),
                        i,
                        c,
                        {"1": 0, "4": 2, "5": 1, "6": 3}[p[1]],
                        int(p[3]),
                        size,
                        (c.count("\n") + 1) * size,
                        calculate_length(c) * size,
                    )
                elif p[1] == "7":  # positioned comment
                    c = str(comment.text)
                    yield (
                        float(p[0]),
                        int(p[4]),
                        i,
                        c,
                        "bilipos",
                        int(p[3]),
                        int(p[2]),
                        0,
                        0,
                    )
                elif p[1] == "8":
                    pass  # ignore scripted comment
        except (AssertionError, AttributeError, IndexError, TypeError, ValueError):
            print("错误")
            continue


def write_comment_bilibili_positioned(f, c, width, height, style_id):
    bili_player_size = (672, 438)  # Bilibili player version 2014
    zoom_factor = get_zoom_factor(bili_player_size, (width, height))

    def get_position(input_pos, is_height):
        is_height = int(is_height)  # True -> 1
        if isinstance(input_pos, int):
            return zoom_factor[0] * input_pos + zoom_factor[is_height + 1]
        elif isinstance(input_pos, float):
            if input_pos > 1:
                return zoom_factor[0] * input_pos + zoom_factor[is_height + 1]
            else:
                return (
                    bili_player_size[is_height] * zoom_factor[0] * input_pos
                    + zoom_factor[is_height + 1]
                )
        else:
            try:
                input_pos = int(input_pos)
            except ValueError:
                input_pos = float(input_pos)
            return get_position(input_pos, is_height)

    try:
        comment_args = SafeList(json.loads(c[3]))
        text = ass_escape(str(comment_args[4]).replace("/n", "\n"))
        from_x = comment_args.get(0, 0)
        from_y = comment_args.get(1, 0)
        to_x = comment_args.get(7, from_x)
        to_y = comment_args.get(8, from_y)
        from_x = get_position(from_x, False)
        from_y = get_position(from_y, True)
        to_x = get_position(to_x, False)
        to_y = get_position(to_y, True)
        alpha = SafeList(str(comment_args.get(2, "1")).split("-"))
        from_alpha = float(alpha.get(0, 1))
        to_alpha = float(alpha.get(1, from_alpha))
        from_alpha = 255 - round(from_alpha * 255)
        to_alpha = 255 - round(to_alpha * 255)
        rotate_z = int(comment_args.get(5, 0))
        rotate_y = int(comment_args.get(6, 0))
        lifetime = float(comment_args.get(3, 4500))
        duration = int(comment_args.get(9, lifetime * 1000))
        delay = int(comment_args.get(10, 0))
        font_face = comment_args.get(12)
        is_border = comment_args.get(11, "true")
        from_rotarg = convert_flash_rotation(
            rotate_y, rotate_z, from_x, from_y, width, height
        )
        to_rotarg = convert_flash_rotation(
            rotate_y, rotate_z, to_x, to_y, width, height
        )
        styles = ["\\org(%d, %d)" % (width / 2, height / 2)]
        if from_rotarg[0:2] is to_rotarg[0:2]:
            styles.append("\\pos(%.0f, %.0f)" % (from_rotarg[0:2]))
        else:
            styles.append(
                "\\move(%.0f, %.0f, %.0f, %.0f, %.0f, %.0f)"
                % (from_rotarg[0:2] + to_rotarg[0:2] + (delay, delay + duration))
            )
        styles.append(
            "\\frx%.0f\\fry%.0f\\frz%.0f\\fscx%.0f\\fscy%.0f" % (from_rotarg[2:7])
        )
        if (from_x, from_y) != (to_x, to_y):
            styles.append("\\t(%d, %d, " % (delay, delay + duration))
            styles.append(
                "\\frx%.0f\\fry%.0f\\frz%.0f\\fscx%.0f\\fscy%.0f" % (to_rotarg[2:7])
            )
            styles.append(")")
        if font_face:
            styles.append("\\fn%s" % ass_escape(font_face))
        styles.append("\\fs%.0f" % (c[6] * zoom_factor[0]))
        if c[5] != 0xFFFFFF:
            styles.append("\\c&H%s&" % convert_color(c[5]))
            if c[5] == 0x000000:
                styles.append("\\3c&HFFFFFF&")
        if from_alpha == to_alpha:
            styles.append("\\alpha&H%02X" % from_alpha)
        elif (from_alpha, to_alpha) == (255, 0):
            styles.append("\\fad(%.0f,0)" % (lifetime * 1000))
        elif (from_alpha, to_alpha) == (0, 255):
            styles.append("\\fad(0, %.0f)" % (lifetime * 1000))
        else:
            styles.append(
                "\\fade(%(from_alpha)d, %(to_alpha)d, %(to_alpha)d, 0, %(end_time).0f, %(end_time).0f, %(end_time).0f)"
                % {
                    "from_alpha": from_alpha,
                    "to_alpha": to_alpha,
                    "end_time": lifetime * 1000,
                }
            )
        if is_border == "false":
            styles.append("\\bord0")
        f.write(
            "Dialogue: -1,%(start)s,%(end)s,%(style_id)s,,0,0,0,,{%(styles)s}%(text)s\n"
            % {
                "start": convert_timestamp(c[0]),
                "end": convert_timestamp(c[0] + lifetime),
                "styles": "".join(styles),
                "text": text,
                "style_id": style_id,
            }
        )
    except (IndexError, ValueError):
        try:
            logging.warning(_("Invalid comment: %r") % c[3])
        except IndexError:
            logging.warning(_("Invalid comment: %r") % c)


# Result: (f, dx, dy)
# To convert: NewX = f*x+dx, NewY = f*y+dy
def get_zoom_factor(source_size, target_size):
    try:
        if (source_size, target_size) == get_zoom_factor.cached_size:
            return get_zoom_factor.cached_result
    except AttributeError:
        pass
    get_zoom_factor.cached_size = (source_size, target_size)
    try:
        source_aspect = source_size[0] / source_size[1]
        target_aspect = target_size[0] / target_size[1]
        if target_aspect < source_aspect:  # narrower
            scale_factor = target_size[0] / source_size[0]
            get_zoom_factor.cached_result = (
                scale_factor,
                0,
                (target_size[1] - target_size[0] / source_aspect) / 2,
            )
        elif target_aspect > source_aspect:  # wider
            scale_factor = target_size[1] / source_size[1]
            get_zoom_factor.cached_result = (
                scale_factor,
                (target_size[0] - target_size[1] * source_aspect) / 2,
                0,
            )
        else:
            get_zoom_factor.cached_result = (target_size[0] / source_size[0], 0, 0)
        return get_zoom_factor.cached_result
    except ZeroDivisionError:
        get_zoom_factor.cached_result = (1, 0, 0)
        return get_zoom_factor.cached_result


# Calculation is based on https://github.com/jabbany/CommentCoreLibrary/issues/5#issuecomment-40087282
#                     and https://github.com/m13253/danmaku2ass/issues/7#issuecomment-41489422
# ASS FOV = width*4/3.0
# But Flash FOV = width/math.tan(100*math.pi/360.0)/2 will be used instead
# Result: (transX, transY, rotX, rotY, rotZ, scaleX, scaleY)
def convert_flash_rotation(rot_y, rot_z, x, y, width, height):
    def wrap_angle(deg):
        return 180 - ((180 - deg) % 360)

    rot_y = wrap_angle(rot_y)
    rot_z = wrap_angle(rot_z)
    if rot_y in (90, -90):
        rot_y -= 1
    if rot_y == 0 or rot_z == 0:
        out_x = 0
        out_y = -rot_y  # Positive value means clockwise in Flash
        out_z = -rot_z
        rot_y *= math.pi / 180.0
        rot_z *= math.pi / 180.0
    else:
        rot_y *= math.pi / 180.0
        rot_z *= math.pi / 180.0
        out_y = (
            math.atan2(-math.sin(rot_y) * math.cos(rot_z), math.cos(rot_y))
            * 180
            / math.pi
        )
        out_z = (
            math.atan2(-math.cos(rot_y) * math.sin(rot_z), math.cos(rot_z))
            * 180
            / math.pi
        )
        out_x = math.asin(math.sin(rot_y) * math.sin(rot_z)) * 180 / math.pi
    tr_x = (
        (x * math.cos(rot_z) + y * math.sin(rot_z)) / math.cos(rot_y)
        + (1 - math.cos(rot_z) / math.cos(rot_y)) * width / 2
        - math.sin(rot_z) / math.cos(rot_y) * height / 2
    )
    tr_y = (
        y * math.cos(rot_z)
        - x * math.sin(rot_z)
        + math.sin(rot_z) * width / 2
        + (1 - math.cos(rot_z)) * height / 2
    )
    tr_z = (tr_x - width / 2) * math.sin(rot_y)
    fov = width * math.tan(2 * math.pi / 9.0) / 2
    try:
        scale_xy = fov / (fov + tr_z)
    except ZeroDivisionError:
        logging.error("Rotation makes object behind the camera: tr_z == %.0f" % tr_z)
        scale_xy = 1
    tr_x = (tr_x - width / 2) * scale_xy + width / 2
    tr_y = (tr_y - height / 2) * scale_xy + height / 2
    if scale_xy < 0:
        scale_xy = -scale_xy
        out_x += 180
        out_y += 180
        logging.error(
            "Rotation makes object behind the camera: tr_z == %.0f < %.0f" % (tr_z, fov)
        )
    return (
        tr_x,
        tr_y,
        wrap_angle(out_x),
        wrap_angle(out_y),
        wrap_angle(out_z),
        scale_xy * 100,
        scale_xy * 100,
    )


def process_comments(
    comments,
    f,
    width,
    height,
    bottom_reserved,
    font_face,
    fontsize,
    alpha,
    duration_marquee,
    duration_still,
    filters_regex,
    reduced,
    progress_callback,
):
    style_id = "Danmaku2ASS_%04x" % random.randint(0, 0xFFFF)
    write_ass_head(f, width, height, font_face, fontsize, alpha, style_id)
    rows = [[None] * (height - bottom_reserved + 1) for _ in range(4)]
    for idx, comment in enumerate(comments):
        if progress_callback and idx % 1000 == 0:
            progress_callback(idx, len(comments))
        if isinstance(comment[4], int):
            skip = False
            for filter_regex in filters_regex:
                if filter_regex and filter_regex.search(comment[3]):
                    skip = True
                    break
            if skip:
                continue
            row_max = height - bottom_reserved - comment[7]
            for row in range(int(row_max)):
                free_rows = test_free_rows(
                    rows,
                    comment,
                    row,
                    width,
                    height,
                    bottom_reserved,
                    duration_marquee,
                    duration_still,
                )
                if free_rows >= comment[7]:
                    mark_comment_row(rows, comment, row)
                    write_comment(
                        f,
                        comment,
                        row,
                        width,
                        height,
                        bottom_reserved,
                        fontsize,
                        duration_marquee,
                        duration_still,
                        style_id,
                    )
                    break
            else:
                if not reduced:
                    row = find_alternative_row(rows, comment, height, bottom_reserved)
                    mark_comment_row(rows, comment, row)
                    write_comment(
                        f,
                        comment,
                        row,
                        width,
                        height,
                        bottom_reserved,
                        fontsize,
                        duration_marquee,
                        duration_still,
                        style_id,
                    )
        elif comment[4] == "bilipos":
            write_comment_bilibili_positioned(f, comment, width, height, style_id)
        elif comment[4] == "acfunpos":
            write_comment_acfun_positioned(f, comment, width, height, style_id)
        else:
            logging.warning(_("Invalid comment: %r") % comment[3])
    if progress_callback:
        progress_callback(len(comments), len(comments))


def test_free_rows(
    rows, c, row, width, height, bottom_reserved, duration_marquee, duration_still
):
    res = 0
    row_max = height - bottom_reserved
    target_row = None
    if c[4] in (1, 2):
        while row < row_max and res < c[7]:
            if target_row != rows[c[4]][row]:
                target_row = rows[c[4]][row]
                if target_row and target_row[0] + duration_still > c[0]:
                    break
            row += 1
            res += 1
    else:
        try:
            threshold_time = c[0] - duration_marquee * (1 - width / (c[8] + width))
        except ZeroDivisionError:
            threshold_time = c[0] - duration_marquee
        while row < row_max and res < c[7]:
            if target_row != rows[c[4]][row]:
                target_row = rows[c[4]][row]
                try:
                    if target_row and (
                        target_row[0] > threshold_time
                        or target_row[0]
                        + target_row[8] * duration_marquee / (target_row[8] + width)
                        > c[0]
                    ):
                        break
                except ZeroDivisionError:
                    pass
            row += 1
            res += 1
    return res


def find_alternative_row(rows, c, height, bottom_reserved):
    res = 0
    for row in range(height - bottom_reserved - math.ceil(c[7])):
        if not rows[c[4]][row]:
            return row
        elif rows[c[4]][row][0] < rows[c[4]][res][0]:
            res = row
    return res


def mark_comment_row(rows, c, row):
    try:
        for i in range(row, row + math.ceil(c[7])):
            rows[c[4]][i] = c
    except IndexError:
        pass


def write_ass_head(f, width, height, font_face, fontsize, alpha, style_id):
    f.write(
        """[Script Info]
; Script generated by Danmaku2ASS
; https://github.com/m13253/danmaku2ass
Script Updated By: Danmaku2ASS (https://github.com/m13253/danmaku2ass)
ScriptType: v4.00+
PlayResX: %(width)d
PlayResY: %(height)d
Aspect Ratio: %(width)d:%(height)d
Collisions: Normal
WrapStyle: 2
ScaledBorderAndShadow: yes
YCbCr Matrix: TV.601
[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: %(style_id)s, %(font_face)s, %(fontsize).0f, &H%(alpha)02XFFFFFF, &H%(alpha)02XFFFFFF, &H%(alpha)02X000000, &H%(alpha)02X000000, 1, 0, 0, 0, 100, 100, 0.00, 0.00, 1, %(outline).0f, 0, 7, 0, 0, 0, 0
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
        % {
            "width": width,
            "height": height,
            "font_face": font_face,
            "fontsize": fontsize,
            "alpha": 255 - round(alpha * 255),
            "outline": max(fontsize / 25.0, 1),
            "style_id": style_id,
        }
    )


def write_comment(
    f,
    c,
    row,
    width,
    height,
    bottom_reserved,
    fontsize,
    duration_marquee,
    duration_still,
    style_id,
):
    text = ass_escape(c[3])
    styles = []
    if c[4] == 1:
        styles.append(
            "\\an8\\pos(%(half_width)d, %(row)d)"
            % {"half_width": width / 2, "row": row}
        )
        duration = duration_still
    elif c[4] == 2:
        styles.append(
            "\\an2\\pos(%(half_width)d, %(row)d)"
            % {
                "half_width": width / 2,
                "row": convert_type2(row, height, bottom_reserved),
            }
        )
        duration = duration_still
    elif c[4] == 3:
        styles.append(
            "\\move(%(neg_len)d, %(row)d, %(width)d, %(row)d)"
            % {"width": width, "row": row, "neg_len": -math.ceil(c[8])}
        )
        duration = duration_marquee
    else:
        styles.append(
            "\\move(%(width)d, %(row)d, %(neg_len)d, %(row)d)"
            % {"width": width, "row": row, "neg_len": -math.ceil(c[8])}
        )
        duration = duration_marquee
    if not (-1 < c[6] - fontsize < 1):
        styles.append("\\fs%.0f" % c[6])
    if c[5] != 0xFFFFFF:
        styles.append("\\c&H%s&" % convert_color(c[5]))
        if c[5] == 0x000000:
            styles.append("\\3c&HFFFFFF&")
    f.write(
        "Dialogue: 2,%(start)s,%(end)s,%(style_id)s,,0000,0000,0000,,{%(styles)s}%(text)s\n"
        % {
            "start": convert_timestamp(c[0]),
            "end": convert_timestamp(c[0] + duration),
            "styles": "".join(styles),
            "text": text,
            "style_id": style_id,
        }
    )


def ass_escape(s):
    def replace_leading_space(s):
        stripped = s.strip(" ")
        s_len = len(s)
        if s_len == len(stripped):
            return s
        left_len = s_len - len(s.lstrip(" "))
        right_len = s_len - len(s.rstrip(" "))
        return "".join((" " * left_len, stripped, " " * right_len))

    return "\\N".join(
        (
            replace_leading_space(i) or " "
            for i in str(s)
            .replace("\\", "\\\\")
            .replace("{", "\\{")
            .replace("}", "\\}")
            .split("\n")
        )
    )


def calculate_length(s):
    return max(map(len, s.split("\n")))


def convert_timestamp(timestamp):
    timestamp = round(timestamp * 100.0)
    hour, minute = divmod(timestamp, 360000)
    minute, second = divmod(minute, 6000)
    second, centsecond = divmod(second, 100)
    return f"{int(hour)}:{int(minute):02}:{int(second):02}.{int(centsecond):02}"


def convert_color(rgb, width=1280, height=576):
    if rgb == 0x000000:
        return "000000"
    elif rgb == 0xFFFFFF:
        return "FFFFFF"
    r = (rgb >> 16) & 0xFF
    g = (rgb >> 8) & 0xFF
    b = rgb & 0xFF
    if width < 1280 and height < 576:
        return "%02X%02X%02X" % (b, g, r)
    else:  # VobSub always uses BT.601 colorspace, convert to BT.709

        def clip_byte(x):
            return 255 if x > 255 else 0 if x < 0 else round(x)

        return "%02X%02X%02X" % (
            clip_byte(
                r * 0.00956384088080656
                + g * 0.03217254540203729
                + b * 0.95826361371715607
            ),
            clip_byte(
                r * -0.10493933142075390
                + g * 1.17231478191855154
                + b * -0.06737545049779757
            ),
            clip_byte(
                r * 0.91348912373987645
                + g * 0.07858536372532510
                + b * 0.00792551253479842
            ),
        )


def convert_type2(row, height, bottom_reserved):
    return height - bottom_reserved - row


def convert_to_file(filename_or_file, *args, **kwargs):
    if isinstance(filename_or_file, bytes):
        filename_or_file = filename_or_file.decode("utf-8", "replace")
    if isinstance(filename_or_file, str):
        return open(filename_or_file, *args, **kwargs)
    return filename_or_file


def filter_bad_chars(f):
    s = f.read()
    s = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", "�", s)
    return io.StringIO(s)


class SafeList(list):
    def get(self, index, default=None):
        try:
            return self[index]
        except IndexError:
            return default


def export(func):
    global __all__
    try:
        __all__.append(func.__name__)
    except NameError:
        __all__ = [func.__name__]
    return func


def get_comments(cid, font_size=25):
    try:
        response = request.urlopen(
            request.Request(
                url=f"https://comment.bilibili.com/{cid[0]}.xml",
                headers={
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0",
                    "Referer": "https://www.bilibili.com",
                },
            ),
            context=ssl.create_default_context(),
        )
        data = str(zlib.decompress(response.read(), -zlib.MAX_WBITS), "utf-8")
        response.close()
    except error.HTTPError as e:
        print(f"HTTP Error occurred: {e}")
        if e.code == 412:
            print("412 Precondition Failed: 服务器上的资源不满足请求中的前提条件。")
        sys.exit(1)
    comments = []
    str_io = io.StringIO(data)
    comments.extend(read_comments_bilibili(filter_bad_chars(str_io), font_size))
    comments.sort(key=lambda ele: ele[0])
    return comments


def write_to_file(
    comments,
    directory,
    stage_width,
    stage_height,
    reserve_blank=0,
    font_face=_("(FONT) sans-serif")[7:],
    font_size=25.0,
    text_opacity=1.0,
    duration_marquee=5.0,
    duration_still=5.0,
    comment_filter=None,
    comment_filters_file=None,
    is_reduce_comments=False,
    progress_callback=None,
):
    filters_regex = []

    if comment_filter or comment_filters_file:
        comment_filters = [comment_filter] if comment_filter else []
        if comment_filters_file:
            with open(comment_filters_file, "r", encoding="utf-8") as f:
                comment_filters.extend(line.strip() for line in f)

        for filt in comment_filters:
            if filt:
                try:
                    filters_regex.append(re.compile(filt))
                except re.error:
                    raise ValueError(_("Invalid regular expression: %s") % filt)

    ass_path = os.path.join(directory, "bilibili.ass")

    with open(ass_path, "w", encoding="utf-8", errors="replace") as fo:
        process_comments(
            comments,
            fo,
            stage_width,
            stage_height,
            reserve_blank,
            font_face,
            font_size,
            text_opacity,
            duration_marquee,
            duration_still,
            filters_regex,
            is_reduce_comments,
            progress_callback,
        )


def main():
    logging.basicConfig(format="%(levelname)s: %(message)s")
    parser = argparse.ArgumentParser()
    # 下载弹幕的文件夹
    parser.add_argument(
        "-d",
        "--directory",
        type=str,
        help="Choose where to download sub by default: current directory",
        default="./",
    )
    # 屏幕画面大小
    parser.add_argument(
        "-s",
        "--size",
        metavar=_("WIDTHxHEIGHT"),
        help=_("Stage size in pixels"),
        type=str,
        default="1920x1080",
    )
    # 弹幕字体
    parser.add_argument(
        "-fn",
        "--font",
        metavar=_("FONT"),
        help=_("Specify font face [default: %s]") % _("(FONT) sans-serif")[7:],
        default=_("(FONT) sans-serif")[7:],
    )
    # 弹幕字体大小
    parser.add_argument(
        "-fs",
        "--fontsize",
        metavar=_("SIZE"),
        help=_("Default font size [default: %s]") % 25,
        type=float,
        default=37.0,
    )
    # 弹幕不透明度
    parser.add_argument(
        "-a",
        "--alpha",
        metavar=_("ALPHA"),
        help=_("Text opacity"),
        type=float,
        default=0.95,
    )
    # 滚动弹幕显示的持续时间
    parser.add_argument(
        "-dm",
        "--duration-marquee",
        metavar=_("SECONDS"),
        help=_("Duration of scrolling comment display [default: %s]") % 5,
        type=float,
        default=10.0,
    )
    # 静止弹幕显示的持续时间
    parser.add_argument(
        "-ds",
        "--duration-still",
        metavar=_("SECONDS"),
        help=_("Duration of still comment display [default: %s]") % 5,
        type=float,
        default=5.0,
    )
    # 正则表达式过滤评论
    parser.add_argument(
        "-fl", "--filter", help=_("Regular expression to filter comments")
    )
    parser.add_argument(
        "-flf",
        "--filter-file",
        help=_("Regular expressions from file (one line one regex) to filter comments"),
    )
    # 保留底部多少高度的空白区域
    parser.add_argument(
        "-p",
        "--protect",
        metavar=_("HEIGHT"),
        help=_("Reserve blank on the bottom of the stage"),
        type=int,
        default=0,
    )
    # 当屏幕满时减少弹幕数
    parser.add_argument(
        "-r",
        "--reduce",
        action="store_true",
        help=_("Reduce the amount of comments if stage is full"),
    )
    # 弹幕文件
    parser.add_argument(
        "cid", metavar=_("CID"), nargs="+", help=_("Video cid to download comments")
    )
    args = parser.parse_args()
    try:
        width, height = str(args.size).split("x", 1)
        width = int(width)
        height = int(height)
    except ValueError:
        raise ValueError(_("Invalid stage size: %r") % args.size)
    comments = get_comments(args.cid, args.fontsize)
    write_to_file(
        comments,
        args.directory,
        width,
        height,
        args.protect,
        args.font,
        args.fontsize,
        args.alpha,
        args.duration_marquee,
        args.duration_still,
        args.filter,
        args.filter_file,
        args.reduce,
    )


if __name__ == "__main__":
    main()
