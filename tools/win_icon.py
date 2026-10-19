#!/usr/bin/env python3
"""v39: заменить иконку Godot в экспортированном Symphony.exe на icon.svg игры — без rcedit и wine.

В шаблоне Windows уже есть 6 иконок (16, 32, 48, 64, 128 — BMP, 256 — PNG). Перезаписываем их на месте
тем же форматом и размером (для BMP размер данных совпадает байт в байт, PNG 256 должен быть не больше старого),
поэтому файл не сдвигается и встроенный .pck остаётся на месте.

  python3 tools/win_icon.py ../build/windows/Symphony.exe /tmp/icon256.png
"""
import io, struct, sys
import pefile
from PIL import Image


def dib(img):
    w, h = img.size
    px = img.convert("RGBA").transpose(Image.FLIP_TOP_BOTTOM).tobytes("raw", "BGRA")
    mask_row = ((w + 31) // 32) * 4
    hdr = struct.pack("<IiiHHIIiiII", 40, w, h * 2, 1, 32, 0, len(px) + mask_row * h, 0, 0, 0, 0)
    return hdr + px + b"\0" * (mask_row * h)


def main(exe, png):
    src = Image.open(png).convert("RGBA")
    pe = pefile.PE(exe)
    data = bytearray(open(exe, "rb").read())
    icons = {}
    group = None
    for t in pe.DIRECTORY_ENTRY_RESOURCE.entries:
        if t.id == 3:
            for e in t.directory.entries:
                for l in e.directory.entries:
                    icons[e.id] = l.data.struct
        elif t.id == 14:
            for e in t.directory.entries:
                for l in e.directory.entries:
                    group = l.data.struct
    goff = pe.get_offset_from_rva(group.OffsetToData)
    _, _, n = struct.unpack_from("<HHH", data, goff)
    for i in range(n):
        eo = goff + 6 + i * 14
        w, h, cc, rs, planes, bits, size, rid = struct.unpack_from("<BBBBHHIH", data, eo)
        w = w or 256
        st = icons[rid]
        off = pe.get_offset_from_rva(st.OffsetToData)
        old = bytes(data[off:off + st.Size])
        img = src.resize((w, w), Image.LANCZOS)
        if old[:8] == b"\x89PNG\r\n\x1a\n":
            buf = io.BytesIO(); img.save(buf, "PNG", optimize=True); new = buf.getvalue()
        else:
            new = dib(img)
        if len(new) > st.Size:
            sys.exit("иконка %dx%d не помещается: %d > %d байт" % (w, w, len(new), st.Size))
        data[off:off + st.Size] = new + b"\0" * (st.Size - len(new))
        # новый размер данных — в записи ресурса и в каталоге группы иконок
        struct.pack_into("<I", data, st.get_file_offset() + 4, len(new))
        struct.pack_into("<I", data, eo + 8, len(new))
        print("иконка %dx%d: %d байт (было %d)" % (w, w, len(new), st.Size))
    open(exe, "wb").write(data)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
