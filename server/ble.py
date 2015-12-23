#coding:utf-8
import http.server
from urllib.parse import urlparse, parse_qs

import numpy as np
from sklearn.naive_bayes import MultinomialNB, GaussianNB, BernoulliNB

t_data = dict()
tag_number = dict()

def cls(label, data, input):
    L = np.array(label)
    D = np.array(data)
    
    clf = GaussianNB()
    clf.fit(D, L) # training
    
    result = clf.predict(input)
    
    print(result)
    
    return result


def getLabel(input):
    label_list = []
    data_list = []
    
    for number, tag in tag_number.items():
        for data in t_data[tag]:
            label_list.append(number)
            data_list.append(data)
    
    return cls(label_list, data_list, input)

def analyze(o):
    dic = parse_qs(o.query)
    
    if "data" not in dic:
        return 503, "not set data"
    data_list = dic["data"][0].split(",")
    data = [float(d) for d in data_list]
    
    return 200, convName(getLabel([data])[0])
    
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
    t_data.clear()
    tag_number.clear()
    print("delete complete")
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
        elif o.path == "/analyze":
            code, body = analyze(o)
                    
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
    