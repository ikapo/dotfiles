# Image previews in Ghostty through the kitty graphics protocol.
#
# ranger's own "kitty" displayer does not work in Ghostty:
#   - ranger 1.9.4 refuses any terminal whose $TERM lacks "kitty"
#     (Ghostty sets TERM=xterm-ghostty). https://github.com/ranger/ranger/issues/3035
#   - Its start-up probe and its previews send images as files (t=f / t=t).
#     Ghostty 1.3.x fails to read those and replies "EINVAL: invalid data",
#     with ranger master too. https://github.com/ranger/ranger/issues/3203
#     https://github.com/ghostty-org/ghostty/discussions/12901
#
# This plugin replaces the "kitty" displayer only when running in Ghostty.
# It sends each preview inline as PNG data (t=d, f=100), which Ghostty
# handles, and asks the terminal not to reply (q=2), so ranger never blocks
# waiting on stdin. Elsewhere (kitty, tmux, ...) ranger's stock code runs.
# It needs Pillow in ranger's Python (Homebrew: `brew install pillow`).
#
# Once Ghostty fixes file transmission and ranger ships a release with
# Ghostty support, this file can be deleted.

from __future__ import absolute_import, division, print_function

import base64
import fcntl
import io
import os
import struct
import sys
import termios
import warnings

from ranger.ext import img_display
from ranger.ext.img_display import (
    ImageDisplayError,
    KittyImageDisplayer,
    temporarily_moved_cursor,
)


def _in_ghostty():
    return ('ghostty' in os.environ.get('TERM', '')
            or os.environ.get('TERM_PROGRAM', '') == 'ghostty') \
        and 'TMUX' not in os.environ


class GhosttyImageDisplayer(KittyImageDisplayer):
    """kitty graphics protocol with inline PNG transmission, for Ghostty."""

    # One fixed id: each new preview replaces the previous one.
    preview_id = 31337

    def _late_init(self):
        try:
            import PIL.Image  # pylint: disable=import-outside-toplevel
        except ImportError:
            raise ImageDisplayError(
                'Image previews in Ghostty require Pillow in ranger\'s Python '
                '(brew install pillow)')
        self.backend = PIL.Image

        # Cell size in pixels. winsize is (rows, cols, xpixel, ypixel).
        ret = fcntl.ioctl(sys.stdout, termios.TIOCGWINSZ,
                          struct.pack('HHHH', 0, 0, 0, 0))
        rows, cols, xpixel, ypixel = struct.unpack('HHHH', ret)
        if not (rows and cols and xpixel and ypixel):
            raise ImageDisplayError('terminal did not report its size in pixels')
        # Upstream names: pix_row = cell width, pix_col = cell height.
        self.pix_row, self.pix_col = xpixel // cols, ypixel // rows
        self.stream = True
        self.needs_late_init = False

    def _send(self, cmds, payload=b''):
        # Chunk as the protocol asks: the first chunk carries all the keys,
        # the following ones only m (more data follows) and q.
        keys = ','.join('{0}={1}'.format(k, v) for k, v in cmds.items())
        size = 4096
        first = True
        while True:
            chunk, payload = payload[:size], payload[size:]
            more = 1 if payload else 0
            if first:
                ctrl = keys + (',m={0}'.format(more) if more or chunk else '')
            else:
                ctrl = 'm={0},q=2'.format(more)
            self.stdbout.write(self.protocol_start + ctrl.encode('ascii') + b';'
                               + chunk + self.protocol_end)
            first = False
            if not more:
                break

    def draw(self, path, start_x, start_y, width, height):
        if self.needs_late_init:
            self._late_init()

        with warnings.catch_warnings():
            warnings.simplefilter('ignore', self.backend.DecompressionBombWarning)
            image = self.backend.open(path)
            image.load()

        box_w, box_h = width * self.pix_row, height * self.pix_col
        if image.width > box_w or image.height > box_h:
            scale = min(box_w / image.width, box_h / image.height)
            image = image.resize(
                (max(1, int(scale * image.width)), max(1, int(scale * image.height))),
                self.backend.LANCZOS)
        if image.mode not in ('RGB', 'RGBA'):
            image = image.convert('RGBA' if 'transparency' in image.info else 'RGB')

        png = io.BytesIO()
        image.save(png, format='png', compress_level=1)
        payload = base64.standard_b64encode(png.getvalue())

        with temporarily_moved_cursor(int(start_y), int(start_x)):
            # Drop the previous preview, then transmit and display (a=T)
            # this one inline (t=d) as PNG (f=100), without moving the
            # cursor (C=1) and without any reply from the terminal (q=2).
            self._send({'a': 'd', 'd': 'I', 'i': self.preview_id, 'q': 2})
            self._send({'a': 'T', 't': 'd', 'f': 100, 'i': self.preview_id,
                        'C': 1, 'q': 2}, payload=payload)

    def clear(self, start_x, start_y, width, height):
        # d=I also frees the image data held by the terminal.
        self._send({'a': 'd', 'd': 'I', 'i': self.preview_id, 'q': 2})
        self.stdbout.flush()
        self.fm.ui.win.redrawwin()
        self.fm.ui.win.refresh()

    def quit(self):
        if not self.needs_late_init:
            self._send({'a': 'd', 'd': 'I', 'i': self.preview_id, 'q': 2})
            self.stdbout.flush()


if _in_ghostty():
    # Keep the "kitty" name: ranger only accepts its built-in method names.
    img_display.IMAGE_DISPLAYER_REGISTRY['kitty'] = GhosttyImageDisplayer
