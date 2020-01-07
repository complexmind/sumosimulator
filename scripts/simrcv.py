#!/usr/bin/python

from __future__ import print_function

import sys, os

from proton.handlers import MessagingHandler
from proton.reactor import Container

class ReceiveHandler(MessagingHandler):
    def __init__(self, conn_url, address, desired):
        super(ReceiveHandler, self).__init__()

        self.conn_url = conn_url
        self.address = address
        self.desired = desired
        self.received = 0

    def on_start(self, event):
        conn = event.container.connect(self.conn_url)
        event.container.create_receiver(conn, self.address)

#    def on_link_opened(self, event):
#        print("RECEIVE: Created receiver for source address '{0}'".format(self.address))
#        sys.stdout.flush()

    def on_message(self, event):
        message = event.message

        print("Received result...")
        print(message.body)
        sys.stdout.flush()

        self.received += 1

        if self.received == self.desired:
            event.receiver.close()
            event.connection.close()

def main():
    try:
        conn_url = os.path.join('amqp://', os.environ['AMQ_BROKER_SERVICE_HOST'])
        address = os.environ['AMQ_RESPONSE_ADDRESS']
    except ValueError:
        sys.exit("Usage: receive.py CONNECTION-URL ADDRESS [MESSAGE-COUNT]")

    while True:
        handler = ReceiveHandler(conn_url, address, 1)
        container = Container(handler)
        container.run()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
