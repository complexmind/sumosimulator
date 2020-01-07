#!/usr/bin/python

from __future__ import print_function

import os, sys


import optparse
from proton import Message
from proton.handlers import MessagingHandler
from proton.reactor import Container

class SendHandler(MessagingHandler):
    def __init__(self, conn_url, address, message_body):
        super(SendHandler, self).__init__()

        self.conn_url = conn_url
        self.address = address
        self.message_body = message_body

    def on_start(self, event):
        conn = event.container.connect(self.conn_url)
        event.container.create_sender(conn, self.address)

    def on_sendable(self, event):
        message = Message(self.message_body)
        event.sender.send(message)
        event.sender.close()
        event.connection.close()
#        print("SENT: Sent message: ".format(self.message_body))

try:
    conn_url = os.path.join('amqp://', os.environ['AMQ_BROKER_SERVICE_HOST'])
    address = os.environ['AMQ_DESPATCH_ADDRESS']
    message_body = 'Start simulation'

except ValueError:
    sys.exit("Usage: send.py <connection-url> <address> <message-body>")

handler = SendHandler(conn_url, address, message_body)
container = Container(handler)
container.run()

print("Scenario queued...")
