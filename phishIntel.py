import requests
import xml.dom.minidom
import argparse

def initArgParser():
    parser = argparse.ArgumentParser()
    parser.add_argument("-kF", "--keyfile", default='keyfile.txt', required = True, help="Provide path to a text file that contains 3 lines: URLVoid API Key, URLVoid API ID, and SCMachine API Key.")
    parser.add_argument("-f", "--fileprefix", required = True, help="File prefix. Use INC# if applicable.")
    parser.add_argument("-v", "--verbose", default='FALSE', help="Verbose mode.")
    parser.add_argument("-u", "--url", required = True, help="URL")

    return parser.parse_args()

def getKeys(path):
    f = open(path, 'r')
    keys = {'urlVoidKey': f.readline().rstrip(), 'urlVoidID': f.readline().rstrip(), 'scMachineKey': f.readline().rstrip()}
    print keys

    print keys['urlVoidKey']

    return keys

def urlVoid(api_key, api_id, url, out):
    #api_key = '2e4086a69c53d0f9120bf280729ba10bc5a7dc0a'
    #api_id = 'api1000'
    #url = 'google.com'
    preamble = 'http://api.urlvoid.com'
    filename = out + "_urlvoid.xml"
    request = preamble + '/' + api_id + '/' + api_key + '/' + 'host' + '/' + url
    
    print api_key
    print api_id
    print url
    print preamble
    print request

    r = requests.get(request)

    print r.status_code
    
    x = xml.dom.minidom.parseString(r.content)

    print x.toprettyxml(indent = "   ")
    
    with open (filename, 'wb') as f:
        f.write(x.toprettyxml(indent = "   "))

    

def getLinkInfo(url, out):
    preamble = 'http://www.getlinkinfo.com/info?link='
    #url = 'google.com'
    filename = out + "_linkInfo.html"
    
    request = preamble + url

    print preamble
    print url
    print request

    r = requests.get(request)

    print r.status_code

    with open (filename, 'wb') as f:
        f.write(r.content)

def screenPrintMachine(api_key, url, out):
    preamble = 'http://api.screenshotmachine.com/?'
    #api_key = 'f427b9'
    dimension = '1024xfull'
    format = 'png'
    cacheLimit = '1'
    #url = 'www.google.com'
    filename = out + "_scmachine.png"

    request = preamble + 'key=' + api_key + '&' + 'dimension=' + dimension + '&' + 'format=' + format + '&' + 'cacheLimit=' + cacheLimit + '&' + 'url=' + url

    print preamble
    print api_key
    print dimension
    print format
    print cacheLimit
    print url
    print request


    r = requests.get(request)

    print r.status_code

    with open(filename, 'wb') as f:
        f.write(r.content)

def main():
    args = initArgParser()

    keys = getKeys(args.keyfile)

    urlVoid(keys['urlVoidKey'], keys['urlVoidID'], args.url, args.fileprefix)
    getLinkInfo(args.url, args.fileprefix)
    screenPrintMachine(keys['scMachineKey'], args.url, args.fileprefix)


if __name__ == "__main__":
    main()