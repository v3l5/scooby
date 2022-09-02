#!/bin/python3
import base64
f = open("timerangelist.txt", "a")
for i in range(0, 999):
    message = f"20220902082951{i};04/09/2022"
    message_bytes = message.encode('utf8')
    base64_bytes = base64.b64encode(message_bytes)
    base64_message = base64_bytes.decode('utf8')
    f.write(base64_message+"\n")
f.close()
