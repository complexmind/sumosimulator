#!/usr/bin/python

from __future__ import print_function

import os, sys
import xml.etree.ElementTree as ET

if 'SUMO_HOME' in os.environ:
    tools = os.path.join(os.environ['SUMO_HOME'], 'tools')
    sys.path.append(tools)
else:
    sys.exit("Please declare environment variable 'SUMO_HOME'")

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

import traci
import traci.constants as tc

traci.start(["sumo", "-c", "/data/scenarios/surrey1/scenario.sumocfg", "--tripinfo-output", "/tmp/tripinfo.xml", "--no-warnings", "true"]) 

while traci.simulation.getMinExpectedNumber() > 0:
    traci.simulationStep()

traci.close()

root = ET.parse('/tmp/tripinfo.xml').getroot()

for tripinfo in root.findall("./tripinfo[@id=\"4\"]"):
    message_body=ET.tostring(tripinfo)

print("Simulation complete...")
#print(message_body)

conn_url = os.path.join('amqp://', os.environ['AMQ_BROKER_SERVICE_HOST'])
address = os.environ['AMQ_RESPONSE_ADDRESS']

handler = SendHandler(conn_url, address, message_body)
container = Container(handler)
container.run()

