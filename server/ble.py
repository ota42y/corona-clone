#coding:utf-8
import http.server
from urllib.parse import urlparse, parse_qs

t_data = dict()
tag_number = dict()

def convName(label):
    return tag_number[label]

def addData(tag, data):
    if not tag in t_data:
        tag_number[len(tag_number)] = tag
        t_data[tag] = []
        
    t_data[tag].append(data)
    return len(t_data[tag])
    
def training(o):
    dic = parse_qs(o.query)
        
    if "data" not in dic:
        return 503, "not set data"
    if "tag" not in dic:
        return 503, "not set tag"
        
    data_list = dic["data"][0].split(",")
    data = [float(d) for d in data_list]
    
    tag = dic["tag"][0]
    num = addData(tag, data)
    
    return 200, str(num)

def deleteAll():
    t_data = dict()
    tag_number = dict()
    return 200, "delete complete"

class myHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        print("get data")
        
        o = urlparse(self.path)
        print(o)
        
        code = 503
        body = "bad url"
        print(o.path)
        if o.path == "/training":
            code, body = training(o)
        elif o.path == "/delete":
            code, body = deleteAll()
            
        self.send_response(code)
        self.send_header('Content-type','text/html')
        self.end_headers()
        self.wfile.write(body.encode('utf-8'))

if __name__ == '__main__':
    import http.server

    server_address = ("", 8080)
    simple_server = http.server.HTTPServer(server_address, myHandler)
    print("server start")
    simple_server.serve_forever()
    