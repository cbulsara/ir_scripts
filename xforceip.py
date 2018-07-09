import requests
import csv
from sys import argv
import json


script, infile, outfile = argv

url = 'https://api.xforce.ibmcloud.com/'
api = 'ipr/'

headerrow = ['ip', 'score', 'country', 'subnets']

with open (outfile, 'w') as o:
        csvwriter = csv.writer(o)
        csvwriter.writerow(headerrow)
o.close()

with open (infile) as f:
        csvFile = csv.reader(f)
        for row in csvFile:
                ip = "".join(row)
                print(url + api + ip)
                r = requests.get(url + api + ip, verify=False)
                response = json.loads(r.text)

                with open (outfile, 'a') as o:
                        csvwriter = csv.writer(o)
                        row = [response['ip'], response['score'], response['geo']['country'], response['subnets']]
                        csvwriter.writerow(row)
                o.close()
