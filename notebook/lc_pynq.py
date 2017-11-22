from pynq import MMIO
from pynq.overlays.lightcube import LightCubeOverlay
import time
from flask import Flask
from flask_socketio import SocketIO
from ipywidgets import Button, HBox, VBox
from lc_const import *

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'


class LightCube(object):
    def __init__(self):
        LightCubeOverlay("lightcube.bit")
        self.ip = MMIO(0X43C00000, 0X10000)
        self.bram = MMIO(0X40000000, 0X2000)
        self.socketio = SocketIO(app)
        self.clear()
        self.func_group = {
            'Scan Left and Right': self.lr_scan,
            'Scan Front and Back': self.fb_scan,
            'Scan Top and Bottom': self.tb_scan,
            'Roll X': self.roll_x, 'Roll Y': self.roll_y, 'Roll Z': self.roll_z,
            'Hollow Cubes': self.cube_h, 'Solid Cubes': self.cube_s,
            'Falling Rain': self.rain_down, 'Rising Rain': self.rain_up,
            'Hollow Spinner': self.spinner_0, 'Solid Spinner': self.spinner_1,
            'Curved Spinner': self.spinner_c,
            'Sandglass': self.sandglass_b,
            'Blink': self.blink_b, 'All On': self.on,
            'Show On-board Demo': self.show_board_demo,
            'Control from Web': self.read_py_ctrl
        }

    def start(self):
        self.ip.write(ADDR, 0X00)
        self.ip.write(MODE, 0X01)

    def change_mode(self, mode):
        self.ip.write(MODE, mode)
        self.non()

    def run(self, timeout=0.2):
        self.socketio.emit('run', self.get_xyz())
        start = time.time()
        while True:
            while not self.ip.read(DONE):
                pass
            for i in range(64):
                self.bram.write(0X4 * i, self.arr[63 - i])
            self.ip.write(RUN, 0X01)
            self.ip.write(RUN, 0X00)
            if timeout + start - time.time() <= 0:
                break

    def clear(self):
        self.arr = [0X00] * 64

    def get_xyz(self):
        x1, y1, z1 = [], [], []
        x2, y2, z2 = [], [], []
        for z in range(8):
            for x in range(8):
                for y in range(8):
                    if self.arr[8 * z + x] & (0X01 << y):
                        x1.append(x)
                        y1.append(y)
                        z1.append(7 - z)
                    else:
                        x2.append(x)
                        y2.append(y)
                        z2.append(7 - z)
        return {
            'x1': x1, 'y1': y1, 'z1': z1,
            'x2': x2, 'y2': y2, 'z2': z2
        }

    def toggle_xyz(self, x, y, z):
        val = self.arr[8 * z + x] & (0X01 << y)
        if val:
            self.arr[8 * z + x] &= ~(0x01 << y)
        else:
            self.arr[8 * z + x] |= 0x01 << y

    def display_ctrls(self):
        words = [
            'Scan Left and Right',
            'Scan Front and Back',
            'Scan Top and Bottom',
            'Roll X', 'Roll Y', 'Roll Z',
            'Hollow Cubes', 'Solid Cubes',
            'Falling Rain', 'Rising Rain',
            'Hollow Spinner', 'Solid Spinner', 'Curved Spinner',
            'Sandglass', 'Blink', 'All On',
            'Control from Web', 'Show On-board Demo'
        ]
        show = [False] * len(words)
        items = [Button(description=words[i], disabled=show[i],
                        button_style='', tooltip=words[i])
                 for i in range(len(words))]
        for i in range(len(words)):
            items[i].on_click(self.func_group[words[i]])
        scan_box_0 = HBox([items[0], items[1], items[2]])
        scan_box_1 = HBox([items[3], items[4], items[5]])
        scan_box_2 = HBox([items[6], items[7]])
        scan_box_3 = HBox([items[8], items[9]])
        scan_box_4 = HBox([items[10], items[11], items[12]])
        scan_box_5 = HBox([items[13], items[14], items[15]])
        scan_box_6 = VBox([items[16], items[17]])
        return HBox([
            VBox([scan_box_0, scan_box_1, scan_box_2,
                  scan_box_3, scan_box_4, scan_box_5]),
            VBox([scan_box_6])])

    def read_py_ctrl(self, b):
        self.change_mode(1)

    def show_board_demo(self, b):
        self.change_mode(0)

    def lr_scan(self, b):
        for i in range(5):
            self.l2r_scan()
            self.r2l_scan()
        self.non()

    def lr_scan_web(self):
        for i in range(5):
            self.l2r_scan()
            self.r2l_scan()
        self.non()

    def fb_scan(self, b):
        for i in range(5):
            self.f2b_scan()
            self.b2f_scan()
        self.non()

    def tb_scan(self, b):
        for i in range(5):
            self.u2d_scan()
            self.d2u_scan()
        self.non()

    def roll_x(self, b):
        self.xcw(2)
        self.xacw(2)
        self.xcw(2)
        self.xacw(2)
        self.xcw(2)
        self.non()

    def roll_y(self, b):
        self.ycw(2)
        self.yacw(2)
        self.ycw(2)
        self.yacw(2)
        self.ycw(2)
        self.non()

    def roll_z(self, b):
        self.zcw(2)
        self.zacw(2)
        self.zcw(2)
        self.zacw(2)
        self.zcw(2)
        self.non()

    def cube_h(self, b):
        for i in range(2):
            self.cube(0, 0)
            self.cube(0, 1)
            self.cube(0, 3)
            self.cube(0, 2)
        self.non()

    def cube_s(self, b):
        for i in range(2):
            self.cube(1, 0)
            self.cube(1, 1)
            self.cube(1, 3)
            self.cube(1, 2)
        self.non()

    def rain_down(self, b):
        self.rain(0, 10)
        self.non()

    def rain_up(self, b):
        self.rain(1, 10)
        self.non()

    def spinner_0(self, b):
        self.spinner(0, 0)
        self.spinner(0, 1)
        self.non()

    def spinner_1(self, b):
        self.spinner(1, 0)
        self.spinner(1, 1)
        self.non()

    def spinner_c(self, b):
        self.curved_spinner(0)
        self.curved_spinner(1)
        self.non()

    def sandglass_b(self, b):
        self.sandglass()
        self.non()

    def blink_b(self, b):
        self.blink(20)
        self.non()

    def on(self, b):
        self.all(10)
        self.non()

    def test(self, mode):
        self.clear()
        if mode:
            for i in range(64):
                self.arr[i] = TEST_1[i]
        else:
            for i in range(64):
                self.arr[i] = TEST_0[i]
        self.run()

    def all(self, nums=10):
        self.arr = [0XFF] * 64
        for num in range(nums - 1, -1, -1):
            self.run()

    def non(self, nums=10):
        self.clear()
        for num in range(nums - 1, -1, -1):
            self.run()

    def blink(self, nums=10):
        for num in range(nums - 1, -1, -1):
            self.arr = [0XFF] * 64
            self.run(0.2)
            self.arr = [0X00] * 64
            self.run(0.2)

    def floor_fill(self):
        self.clear()
        self.run()
        for z in range(8):
            for x in range(8):
                self.arr[z * 8 + x] = 0XFF
                self.run()
        for z in range(8):
            for x in range(8):
                self.arr[z * 8 + x] = 0X00
                self.run()

    def l2r_scan(self):
        self.clear()
        for z in range(8):
            self.arr[z * 8] = 0XFF
        self.run()
        for x in range(1, 8):
            for z in range(8):
                self.arr[z * 8 + x] = 0XFF
                self.arr[z * 8 + x - 1] = 0X00
            self.run()

    def r2l_scan(self):
        self.clear()
        for z in range(8):
            self.arr[z * 8 + 7] = 0XFF
        self.run()
        for x in range(6, -1, -1):
            for z in range(8):
                self.arr[z * 8 + x] = 0XFF
                self.arr[z * 8 + x + 1] = 0X00
            self.run()

    def f2b_scan(self):
        self.clear()
        for i in range(64):
            self.arr[i] = 0X01
        self.run()
        for y in range(7):
            for i in range(64):
                self.arr[i] <<= 1
            self.run()

    def b2f_scan(self):
        self.clear()
        for i in range(64):
            self.arr[i] = 0X80
        self.run()
        for y in range(7):
            for i in range(0, 64):
                self.arr[i] >>= 1
            self.run()

    def u2d_scan(self):
        self.clear()
        for x in range(8):
            self.arr[x] = 0XFF
        self.run()
        for z in range(1, 8):
            for x in range(8):
                self.arr[z * 8 + x] = 0XFF
                self.arr[(z - 1) * 8 + x] = 0X00
            self.run()

    def d2u_scan(self):
        self.clear()
        for x in range(8):
            self.arr[7 * 8 + x] = 0XFF
        self.run()
        for z in range(6, -1, -1):
            for x in range(8):
                self.arr[z * 8 + x] = 0XFF
                self.arr[(z + 1) * 8 + x] = 0X00
            self.run()

    def xcw(self, nums=10):
        self.clear()
        for i in range(8):
            self.arr[7 * 8 + i] = 0XFF
        self.run()
        for num in range(nums - 1, -1, -1):
            for i in range(28):
                if i < 7:
                    for k in range(8):
                        self.arr[(6 - i) * 8 + k] |= 0X01
                        self.arr[7 * 8 + k] >>= 0X01
                elif i < 14:
                    for k in range(8):
                        self.arr[k] |= 0X01 << (i - 6)
                        self.arr[(14 - i) * 8 + k] = 0X00
                elif i < 21:
                    for k in range(8):
                        self.arr[(i - 13) * 8 + k] = 0X80
                        self.arr[k] <<= 0X01
                elif i < 28:
                    for k in range(8):
                        self.arr[7 * 8 + k] |= 0X80 >> (i - 20)
                        self.arr[(i - 21) * 8 + k] = 0X00
                self.run()

    def xacw(self, nums=10):
        self.clear()
        for i in range(0, 8):
            self.arr[7 * 8 + i] = 0XFF
        self.run()
        for num in range(nums - 1, -1, -1):
            for i in range(28):
                if i < 7:
                    for k in range(0, 8):
                        self.arr[(6 - i) * 8 + k] |= 0X80
                        self.arr[7 * 8 + k] <<= 0X01
                elif i < 14:
                    for k in range(8):
                        self.arr[k] |= 0X80 >> (i - 6)
                        self.arr[(14 - i) * 8 + k] = 0X00
                elif i < 21:
                    for k in range(8):
                        self.arr[(i - 13) * 8 + k] = 0X01
                        self.arr[k] >>= 0X01
                elif i < 28:
                    for k in range(8):
                        self.arr[7 * 8 + k] |= 0X01 << (i - 20)
                        self.arr[(i - 21) * 8 + k] = 0X00
                self.run()

    def ycw(self, nums=10):
        self.clear()
        for i in range(0, 8):
            self.arr[i * 8] = 0XFF
        self.run()
        for num in range(nums - 1, -1, -1):
            for i in range(0, 28):
                if i < 7:
                    for k in range(8):
                        self.arr[(7 - i) * 8] = 0X00
                        self.arr[i + 1] = 0XFF
                elif i < 14:
                    for k in range(8):
                        self.arr[i - 7] = 0X00
                        self.arr[(i - 6) * 8 + 7] = 0XFF
                elif i < 21:
                    for k in range(8):
                        self.arr[(i - 14) * 8 + 7] = 0X00
                        self.arr[7 * 8 + (20 - i)] = 0XFF
                elif i < 28:
                    for k in range(8):
                        self.arr[7 * 8 + (28 - i)] = 0X00
                        self.arr[(27 - i) * 8] = 0XFF
                self.run()

    def yacw(self, nums=10):
        self.clear()
        for i in range(8):
            self.arr[i * 8] = 0XFF
        self.run()
        for num in range(nums - 1, -1, -1):
            for i in range(28):
                if i < 7:
                    for k in range(8):
                        self.arr[i * 8] = 0X00
                        self.arr[7 * 8 + (i + 1)] = 0XFF
                elif i < 14:
                    for k in range(8):
                        self.arr[7 * 8 + (i - 7)] = 0X00
                        self.arr[(13 - i) * 8 + 7] = 0XFF
                elif i < 21:
                    for k in range(8):
                        self.arr[(21 - i) * 8 + 7] = 0X00
                        self.arr[20 - i] = 0XFF
                elif i < 28:
                    for k in range(8):
                        self.arr[28 - i] = 0X00
                        self.arr[(i - 20) * 8] = 0XFF
                self.run()

    def zcw(self, nums=10):
        self.clear()
        for i in range(0, 64):
            self.arr[i] = 0X80
        self.run()
        for num in range(nums - 1, -1, -1):
            for i in range(28):
                if i < 7:
                    for k in range(8):
                        self.arr[k * 8 + 7] |= (0X80 >> (i + 1))
                        self.arr[k * 8 + i] = 0X00
                elif i < 14:
                    for k in range(8):
                        self.arr[k * 8 + 13 - i] = 0X01
                        self.arr[k * 8 + 7] >>= 0X01
                elif i < 21:
                    for k in range(8):
                        self.arr[k * 8 + 21 - i] = 0X00
                        self.arr[k * 8] |= (0x01 << (i - 13))
                elif i < 28:
                    for k in range(8):
                        self.arr[k * 8 + i - 20] = 0X80
                        self.arr[k * 8] <<= 0X01
                self.run()

    def zacw(self, nums=10):
        self.clear()
        for i in range(64):
            self.arr[i] = 0x80
        self.run()
        for num in range(nums - 1, -1, -1):
            for i in range(28):
                if i < 7:
                    for k in range(8):
                        self.arr[k * 8] |= (0X80 >> (i + 1))
                        self.arr[k * 8 + 7 - i] = 0X00
                elif i < 14:
                    for k in range(8):
                        self.arr[k * 8 + i - 6] = 0X01
                        self.arr[k * 8] >>= 0X01
                elif i < 21:
                    for k in range(8):
                        self.arr[k * 8 + i - 14] = 0X00
                        self.arr[k * 8 + 7] |= (0x01 << (i - 13))
                elif i < 28:
                    for k in range(8):
                        self.arr[k * 8 + 27 - i] = 0X80
                        self.arr[k * 8 + 7] <<= 0X01
                self.run()

    def move(self, kind, direction, length):
        if kind == 0:
            if direction == 1:
                for z in range(8):
                    for x in range(7, length - 1, -1):
                        self.arr[z * 8 + x] = self.arr[z * 8 + (x - length)]
                    for x in range(0, length):
                        self.arr[z * 8 + x] = 0
            else:
                for z in range(8):
                    for x in range(length, 8):
                        self.arr[z * 8 + (x - length)] = self.arr[z * 8 + x]
                    for x in range(8 - length, 8):
                        self.arr[z * 8 + x] = 0
        elif kind == 1:
            if direction == 1:
                for i in range(64):
                    self.arr[i] <<= length
            else:
                for i in range(64):
                    self.arr[i] >>= length
        else:
            if direction == 1:
                for x in range(8):
                    for z in range(7, length - 1, -1):
                        self.arr[z * 8 + x] = self.arr[(z - length) * 8 + x]
                    for z in range(0, length):
                        self.arr[z * 8 + x] = 0
            else:
                for x in range(8):
                    for z in range(length, 8):
                        self.arr[(z - length) * 8 + x] = self.arr[z * 8 + x]
                    for z in range(8 - length, 8):
                        self.arr[z * 8 + x] = 0

    def cube_0(self, n):
        self.clear()
        j = 0XFF >> (8 - n)
        self.arr[0] = j
        self.arr[n - 1] = j
        self.arr[(n - 1) * 8] = j
        self.arr[(n - 1) * 8 + n - 1] = j
        for i in range(n):
            j = 0X01 | (0x01 << (n - 1))
            self.arr[i * 8] |= j
            self.arr[i * 8 + n - 1] |= j
            self.arr[i] |= j
            self.arr[(n - 1) * 8 + i] |= j

    def cube_1(self, n):
        for z in range(8):
            for x in range(8):
                if z < n and x < n:
                    self.arr[z * 8 + x] = 0XFF >> (8 - n)
                else:
                    self.arr[z * 8 + x] = 0X00

    def cube(self, empty, kind):
        self.clear()
        for i in range(1, 9):
            if empty == 0:
                self.cube_0(i)
            else:
                self.cube_1(i)
            if kind == 0:
                pass
            elif kind == 1:
                self.move(0, 1, 8 - i)
            elif kind == 2:
                self.move(2, 1, 8 - i)
            else:
                self.move(0, 1, 8 - i)
                self.move(2, 1, 8 - i)
            self.run()
        for i in range(7, -1, -1):
            if empty == 0:
                self.cube_0(i)
            else:
                self.cube_1(i)
            if kind == 0:
                self.move(0, 1, 8 - i)
            elif kind == 1:
                self.move(0, 1, 8 - i)
                self.move(2, 1, 8 - i)
            elif kind == 2:
                pass
            else:
                self.move(2, 1, 8 - i)
            self.run()

    def rain(self, menu, nums=10):
        self.clear()
        if (menu == 1):
            for x in range(0, 8):
                self.arr[56 + x] = TAB_RAIN[x]
            self.run()
            for z in range(1, 8):
                self.move(2, 0, 1)
                for x in range(0, 8):
                    self.arr[56 + x] = TAB_RAIN[z * 8 + x]
                self.run()
            for num in range(nums - 1, -1, -1):
                for z in range(0, 8):
                    self.move(2, 0, 1)
                    for x in range(0, 8):
                        self.arr[56 + x] = TAB_RAIN[z * 8 + x]
                    self.run()
        else:
            for x in range(0, 8):
                self.arr[x] = TAB_RAIN[x]
            self.run()
            for z in range(1, 8):
                self.move(2, 1, 1)
                for x in range(0, 8):
                    self.arr[x] = TAB_RAIN[z * 8 + x]
                self.run()
            for num in range(nums - 1, -1, -1):
                for z in range(0, 8):
                    self.move(2, 1, 1)
                    for x in range(0, 8):
                        self.arr[x] = TAB_RAIN[z * 8 + x]
                    self.run()

    def up(self, nums=10):
        self.clear()
        for num in range(nums - 1, -1, -1):
            for x in range(0, 8):
                self.arr[56 + x] = 0XFF
            self.run()
            for z in range(1, 8):
                self.move(2, 0, 1)
                for x in range(0, 8):
                    self.arr[56 + x] = 0XFF
                self.run()
            for z in range(0, 8):
                if num == 0 & z == 7:
                    continue
                self.move(2, 0, 1)
                self.run()
        for z in range(0, 7):
            self.move(2, 1, 1)
            self.run()

    def spinner(self, kind, cw, nums=10):
        self.clear()
        for num in range(nums - 1, -1, -1):
            if cw == 1:
                for i in range(13, -1, -1):
                    for z in range(8):
                        for x in range(8):
                            if x > 1 and x < 6 and z > 1 and z < 6 and kind != 1:
                                self.arr[z * 8 + x] = \
                                    TAB_SPINNER_0[i * 8 + x] & 0XC3
                            else:
                                self.arr[z * 8 + x] = \
                                    TAB_SPINNER_0[i * 8 + x]
                    self.run()
            else:
                for i in range(14):
                    for z in range(8):
                        for x in range(8):
                            if x > 1 and x < 6 and z > 1 and z < 6 and kind != 1:
                                self.arr[z * 8 + x] = \
                                    TAB_SPINNER_0[i * 8 + x] & 0XC3
                            else:
                                self.arr[z * 8 + x] = \
                                    TAB_SPINNER_0[i * 8 + x]
                    self.run()

    def curved_spinner(self, cw, nums=10):
        self.clear()
        for z in range(8):
            for x in range(8):
                self.arr[z * 8 + x] = TAB_SPINNER_0[x]
        self.run()
        for num in range(nums - 1, -1, -1):
            if cw == 1:
                for i in range(13, -1, -1):
                    self.move(2, 1, 1)
                    for x in range(8):
                        self.arr[x] = TAB_SPINNER_0[i * 8 + x]
                    self.run()
            else:
                for i in range(13):
                    self.move(2, 1, 1)
                    for x in range(8):
                        self.arr[x] = TAB_SPINNER_0[i * 8 + x]
                    self.run()
        for i in range(7):
            self.move(2, 1, 1)
            for x in range(8):
                self.arr[x] = TAB_SPINNER_0[x]
            self.run()

    def sandglass(self):
        self.clear()
        for i in range(128):
            self.arr[TAB_0_0[i]] = 0X01 << TAB_0_1[i]
            self.run()
            self.arr[TAB_0_0[i]] = 0
        for i in range(128):
            self.arr[TAB_1_0[i]] |= 0X01 << TAB_0_1[i]
            if i >= 8:
                self.arr[TAB_1_0[i - 8]] ^= 0X01 << TAB_0_1[i - 8]
        self.arr[7] |= 0X01
        self.arr[0] = 0X01
        self.run()
        for i in range(128):
            if i < 8:
                self.arr[8 - i] = 0X00
            self.arr[TAB_0_0[i]] |= 0X01 << TAB_0_1[i]
            self.run()
        self.run()
        for i in range(128):
            self.arr[TAB_1_0[i]] ^= 0X01 << TAB_0_1[i]
