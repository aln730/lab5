import serial

ser = serial.Serial("COM2", 9600)

responses = {
    "n": "Negative: set if result is negative for signed number; N = msb.\r\n",
    "z": "Zero: set if result is zero.\r\n",
    "c": "Carry: set if there was a carry out of or no borrow into the msb.\r\n",
    "v": "Overflow: set if result is invalid for signed number.\r\n",
}

while True:
    ser.write(b"Type a letter for APSR glossary lookup.\r\n>")
    char = ser.read(1).decode().lower()
    ser.write((char + "\r\n").encode())
    if char in responses:
        ser.write(responses[char].encode())
