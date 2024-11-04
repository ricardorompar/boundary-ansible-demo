'''
This script is used to generate the inventory file for Ansible by authenticating to Boundary
Prerequisites: 
- A Boundary cluster 
- A Boundary target with an alias and an associated host catalog (this example assumes multiple hosts in the same target)

Expected output: an Ansible inventory file with the corresponding ports for each Boundary connection.
'''

import os
import json
import subprocess
from threading import Thread
import signal
import sys
import time

connect_procs = []

#Create the inventory file and update the first line:
with open("inventory.ini", "w") as inventory:
    inventory.write("[mygroup]\n")

class Boundary_Connection(Thread):
    # Each Boundary connection is a subprocess so a multithreaded app is needed
    # I'm using the threading module here to run multiple Boundary connections at once. One for each host in the target
    def __init__(self, target_alias, item):
        super().__init__()
        self.target_alias = target_alias
        self.item = item

    def run(self):
        print(f"Establishing connection with host {self.item['id']}...")
        cmd = f"boundary connect -target-id={self.target_alias} -host-id={self.item['id']} -format=json"
        connect_proc = subprocess.Popen(cmd, shell=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        connect_procs.append(connect_proc)


def authenticate_boundary() -> None:
    # This function is only needed if you haven't already logged in to Boundary
    # NOTE: you need to have set the following environment variables:
    # - BOUNDARY_AUTHENTICATE_PASSWORD_PASSWORD
    # - BOUNDARY_AUTHENTICATE_PASSWORD_LOGIN_NAME
    # - BOUNDARY_ADDR: the URL of your Boundary cluster
    os.system("boundary authenticate password -password='env://BOUNDARY_AUTHENTICATE_PASSWORD_PASSWORD'")

def get_boundary_hosts(target_alias) -> dict:
    # assuming the only information we have is the alias of the target from boundary:
    # we'll get the required host IDs from there:
    host_catalog_id = os.popen(f"boundary targets read -id {target_alias} -format=json")
    #the catalog id is in item > host_sources > first element > host_catalog_id
    host_catalog_id = json.loads(host_catalog_id.read())['item']["host_sources"][0]["host_catalog_id"]
    #we'll get the hosts from the host catalog:
    hosts = os.popen(f"boundary hosts list -host-catalog-id={host_catalog_id} -format=json")
    return json.loads(hosts.read())

def connect_boundary(target_alias: str, hosts: dict) -> None: 
    #This function receives a list of objects as an input (hosts information)
    #It connects to each Boundary host in the target  
    connections = []
    for item in hosts['items']:
        # populate the list of objects
        connections.append(Boundary_Connection(target_alias, item))

    for connection in connections:
        try:
            #attempt to connect to the target:
            connection.start()
        except Exception as e:
            print(f"Unable to connect to host {connection.item['id']}. \nError:", e)
            return
    
    #stay until terminated:
    connected_loop()
    return

def make_inventory() -> list:
    # This function reads the output (stdout) of each subprocess. 
    # This is needed because of the blocking nature of each "boundary connect"
    time.sleep(3)
    mygroup = []
    for index, process in enumerate(connect_procs):
        while True:
            output = json.loads(process.stdout.readline())
            if output: #once the output is detected
                mygroup.append({"ip":output["address"], "port":output["port"]})
                #Write new line to inventory file:
                with open("inventory.ini", "a+") as inventory:
                    line = f"server{index} ansible_host={output["address"]} ansible_port={output["port"]}"
                    inventory.write(f"{line}\n")
                break # move on to the next server
    return mygroup

def connected_loop() -> None:
    # When this process is killed (gracefully, SIGINT) the connection to each Boundary host is terminated gracefully
    mygroup = make_inventory()
    msg = "Hosts: "
    for host in mygroup:
        msg+=f"{host["ip"]}:{host["port"]}  "

    elapsed = 0
    while True:
        print(f"Connection to target open for {elapsed} second(s)")
        print(msg)
        print("Press CTRL+C to terminate connections.")
        elapsed+=1
        time.sleep(1)
        os.system("clear")

def signal_handler(signum, frame):
    print(f"Exiting connections.")
    for index, process in enumerate(connect_procs):
        print(f"Terminating connection with host {index}...")
        process.terminate()
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    # Comment out this line if you've already authenticated to Boundary in the current session:
    authenticate_boundary()

    # When executing this script use the alias in the command line. For example: python3 generate-inventory.py alias
    try: 
        target_alias = sys.argv[1] #alias name should be the second argument in the command line
    except:
        print("Boundary target alias not found")
        print("Please provide target alias to establish a connection")
        sys.exit(0)

    hosts = get_boundary_hosts(target_alias)
    hosts_info = connect_boundary(target_alias, hosts)